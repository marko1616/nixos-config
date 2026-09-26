"""Private host repository management; standard-library-only CLI helpers."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
from urllib.parse import urlsplit

REQUIRED = ('host.nix', 'hardware-configuration.nix',
            'ssh/settings.json', 'ssh/authorized_keys')
INPUT_PATTERN = re.compile(
    r'(private-config\s*=\s*\{\s*# Managed by cli\.py private switch\. No credentials in this URL\.\s*url\s*=\s*)"[^"\n]*"')


def run(args, cwd, capture=False):
    return subprocess.run(args, cwd=cwd, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None)


def git(directory, *args, capture=False):
    return run(['git', '-C', str(directory), *args], directory, capture)


def flake_ref(root):
    return 'git+file://' + root.as_posix() + '?submodules=1'


def validate(directory):
    if directory.is_symlink():
        raise ValueError('private-config/ must not be a symlink.')
    for name in REQUIRED:
        p = directory / name
        if not p.is_file() or p.is_symlink() or not p.resolve().is_relative_to(directory.resolve()):
            raise ValueError(f'Missing or unsafe configuration file: {name}')
    settings = json.loads((directory / 'ssh/settings.json').read_text())
    if type(settings.get('enable')) is not bool or not isinstance(settings.get('user'), str):
        raise ValueError('SSH settings require a boolean enable and a string user.')
    keys = (directory / 'ssh/authorized_keys').read_text()
    if 'PRIVATE KEY' in keys:
        raise ValueError('authorized_keys contains a private key.')
    if settings['enable'] and not any(x.strip() and not x.lstrip().startswith('#') for x in keys.splitlines()):
        raise ValueError('SSH is enabled but no public keys are configured.')


def require_repo(directory, clean=False):
    if directory.is_symlink() or not (directory / '.git').exists():
        raise ValueError('Expected an independent Git repository in private-config/.')
    validate(directory)
    if clean and git(directory, 'status', '--porcelain', '--untracked-files=all', capture=True).stdout.strip():
        raise ValueError('private-config/ has uncommitted changes. Commit or save them before switching.')


def normalize_url(value):
    if value.startswith('git+'):
        value = value[4:]
    if re.fullmatch(r'git@[A-Za-z0-9.-]+:[A-Za-z0-9_./-]+', value):
        host, path = value[4:].split(':', 1)
        value = f'ssh://git@{host}/{path}'
    parsed = urlsplit(value)
    if (parsed.scheme not in ('ssh', 'https') or not parsed.hostname
            or not re.fullmatch(r'[A-Za-z0-9.-]+', parsed.hostname)
            or parsed.query or parsed.fragment or parsed.password
            or (parsed.scheme == 'https' and parsed.username)
            or (parsed.scheme == 'ssh' and parsed.username not in (None, 'git'))
            or not re.fullmatch(r'/[A-Za-z0-9_./-]+', parsed.path)):
        raise ValueError('Use a credential-free HTTPS or SSH repository URL (no query or fragment).')
    return value.rstrip('/')


def input_url(root):
    match = INPUT_PATTERN.search((root / 'flake.nix').read_text())
    if not match:
        raise ValueError('Cannot locate the managed private-config URL in flake.nix.')
    return re.search(r'"([^"\n]*)"$', match.group(0)).group(1)


def set_input(root, url):
    p = root / 'flake.nix'
    text, count = INPUT_PATTERN.subn(lambda m: m.group(1) + json.dumps(url), p.read_text())
    if count != 1:
        raise ValueError('Expected exactly one managed private-config URL.')
    p.write_text(text)


def init(root):
    private = root / 'private-config'
    if private.exists() or private.is_symlink():
        raise ValueError('private-config/ already exists; it will not be overwritten.')
    shutil.copytree(root / 'templates/private-config', private)
    git(private, 'init', '-b', 'main')
    print('Created private-config/. Edit host.nix and import hardware before building.')
    if (root / 'config/ssh').exists():
        print('Legacy SSH files found. Use ./cli.py private import-ssh --from-dir config/ssh.')


def status(root):
    directory = root / 'private-config'
    print('Flake input:', input_url(root))
    require_repo(directory)
    result = subprocess.run(['git', '-C', str(directory), 'remote', 'get-url', 'origin'],
                            capture_output=True, text=True)
    remote = result.stdout.strip()
    # Do not print credential-bearing remote URLs.
    try:
        normalized = normalize_url(remote)
    except ValueError:
        normalized = '(unset or unsupported; inspect Git configuration locally)'
    print('Local origin:', normalized)
    git(directory, 'status', '--short')
    if normalized.startswith(('https:', 'ssh:')):
        try:
            matches = normalize_url(input_url(root)).removesuffix('.git') == normalized.removesuffix('.git')
        except ValueError:
            matches = False
        if not matches:
            print('NOTICE: local origin and Flake input differ; normal rebuild does not use this working tree.')


def locked_private_revision(root):
    """Resolve the root input edge; node names need not equal input names."""
    lock = json.loads((root / 'flake.lock').read_text())
    nodes = lock['nodes']
    edge = nodes[lock['root']]['inputs']['private-config']
    if not isinstance(edge, str):
        raise ValueError('private-config must be a direct locked Git input.')
    locked = nodes[edge]['locked']
    revision = locked.get('rev', '')
    if locked.get('type') != 'git' or not re.fullmatch(r'[0-9a-fA-F]{40}', revision):
        raise ValueError('private-config must resolve to a full Git revision.')
    return revision.lower()


def require_prod_lock(root):
    """A lock on disk is insufficient if the Git flake omits it."""
    lock = root / 'flake.lock'
    if lock.is_symlink() or not lock.is_file():
        raise ValueError('prod requires a reviewed flake.lock; update inputs explicitly first.')
    git(root, 'ls-files', '--error-unmatch', '--', 'flake.lock', capture=True)
    data = json.loads(lock.read_text())
    if not isinstance(data, dict) or not isinstance(data.get('nodes'), dict):
        raise ValueError('Invalid flake.lock; review and regenerate it explicitly.')
    # Nix validates the complete graph and refuses changes via --no-update-lock-file.


def switch(root, url):
    url = normalize_url(url)
    directory = root / 'private-config'
    if directory.exists() or directory.is_symlink():
        require_repo(directory, clean=True)
    # The caller explicitly selected switch. Never push, commit, or activate.
    source = root / 'flake.nix'
    lock = root / 'flake.lock'
    old_source = source.read_bytes()
    old_lock = lock.read_bytes() if lock.exists() else None
    backup = None
    moved = False
    with tempfile.TemporaryDirectory(prefix='.private-switch-', dir=root) as staging:
        candidate = Path(staging) / 'repo'
        run(['git', 'clone', '--', url, str(candidate)], root)
        require_repo(candidate)
        try:
            set_input(root, 'git+' + url)
            # Resolve/authenticate the remote and lock it before replacing local files.
            run(['nix', 'flake', 'update', '--flake', flake_ref(root), 'private-config'], root)
            revision = locked_private_revision(root)
            # The branch may have advanced between clone and lock resolution.
            # Fetch exactly the locked commit, never resolve the branch again.
            present = subprocess.run(
                ['git', '-C', str(candidate), 'cat-file', '-e', revision + '^{commit}'],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            ).returncode == 0
            if not present:
                git(candidate, 'fetch', 'origin', revision)
            git(candidate, 'checkout', '--detach', revision)
            actual = git(candidate, 'rev-parse', 'HEAD', capture=True).stdout.strip()
            if actual != revision:
                raise ValueError('Candidate HEAD does not match the private lock revision.')
            require_repo(candidate, clean=True)
            if directory.exists():
                suffix = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
                backup = root / ('.private-backup-' + suffix)
                directory.rename(backup)
            candidate.rename(directory)
            moved = True
        except BaseException:
            source.write_bytes(old_source)
            if old_lock is None:
                lock.unlink(missing_ok=True)
            else:
                lock.write_bytes(old_lock)
            if backup and backup.exists() and not directory.exists():
                backup.rename(directory)
            raise
    if moved:
        print('Switched private-config/ to the locked revision (detached HEAD). Review flake.nix and flake.lock.')
        if backup:
            print('Previous repository retained at', backup.name)
        print('Create or switch to a branch before continuing development.')
        print('No commits, pushes or system activation were performed.')


def import_hardware(root, source, replace):
    directory = root / 'private-config'
    require_repo(directory)
    destination = directory / 'hardware-configuration.nix'
    if source.resolve() == destination.resolve():
        raise ValueError('Source and destination are the same file.')
    if not source.is_file():
        raise ValueError('Hardware source file does not exist.')
    old = destination.read_text()
    if 'PRIVATE_CONFIG_HARDWARE_PLACEHOLDER' not in old and not replace:
        raise ValueError('Hardware configuration already exists; use --replace after reviewing it.')
    if replace:
        shutil.copy2(destination, destination.with_suffix('.nix.bak'))
    shutil.copyfile(source, destination)
    print('Imported hardware. Check relative imports, disks and mount options before building.')


def import_ssh(root, source, replace):
    directory = root / 'private-config'
    require_repo(directory)
    if source.resolve() == (directory / 'ssh').resolve():
        raise ValueError('Source and destination are the same directory.')
    settings = json.loads((source / 'settings.json').read_text())
    keys = (source / 'authorized_keys').read_text()
    if type(settings.get('enable')) is not bool or not isinstance(settings.get('user'), str):
        raise ValueError('Invalid SSH settings.')
    if 'PRIVATE KEY' in keys:
        raise ValueError('Refusing to import a private key.')
    old = json.loads((directory / 'ssh/settings.json').read_text())
    old_keys = (directory / 'ssh/authorized_keys').read_text()
    if not replace and (old.get('enable') or any(s.strip() and not s.lstrip().startswith('#') for s in old_keys.splitlines())):
        raise ValueError('Existing SSH configuration would be replaced; use --replace after review.')
    if settings['enable'] and not any(s.strip() and not s.lstrip().startswith('#') for s in keys.splitlines()):
        raise ValueError('SSH is enabled but keys are empty.')
    for name in ('settings.json', 'authorized_keys'):
        target = directory / 'ssh' / name
        if replace:
            shutil.copy2(target, target.with_name(name + '.bak'))
        shutil.copyfile(source / name, target)
    print('Imported SSH settings locally. Nothing was uploaded.')


def edit_host(root):
    require_repo(root / 'private-config')
    editor = shlex.split(os.environ.get('EDITOR', 'nvim'))
    if not editor:
        raise ValueError('EDITOR is empty.')
    run(editor + [str(root / 'private-config/host.nix')], root)


def main(root, argv):
    parser = argparse.ArgumentParser(prog='cli.py private')
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('init', help='Copy the public template into an independent private-config/ repository')
    sub.add_parser('status', help='Show Git state and check the input/origin mapping')
    p = sub.add_parser('switch', help='Clone a repository and transactionally update the Flake input')
    p.add_argument('url')
    p = sub.add_parser('import-hardware')
    p.add_argument('--source', type=Path, default=Path('/etc/nixos/hardware-configuration.nix'))
    p.add_argument('--replace', action='store_true')
    p = sub.add_parser('import-ssh')
    p.add_argument('--from-dir', type=Path, required=True)
    p.add_argument('--replace', action='store_true')
    sub.add_parser('edit-host', help='Open private-config/host.nix using EDITOR')
    args = parser.parse_args(argv)
    root = Path(root).resolve()
    try:
        if args.command == 'init': init(root)
        elif args.command == 'status': status(root)
        elif args.command == 'switch': switch(root, args.url)
        elif args.command == 'import-hardware': import_hardware(root, args.source, args.replace)
        elif args.command == 'import-ssh': import_ssh(root, args.from_dir, args.replace)
        elif args.command == 'edit-host': edit_host(root)
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print(f'Private configuration operation failed: {exc}', file=__import__('sys').stderr)
        return 1
