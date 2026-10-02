"""Interactive lock maintenance using Nix's native lock/update commands."""
import difflib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from scripts.private_config import flake_ref, git


def read_lock(path):
    if path.is_symlink() or (path.exists() and not path.is_file()):
        raise ValueError('flake.lock must be a regular file, not a symlink.')
    return path.read_bytes() if path.exists() else None


def validate_lock(content):
    data = json.loads(content)
    if not isinstance(data, dict) or not isinstance(data.get('nodes'), dict):
        raise ValueError('Invalid flake.lock: expected a nodes map.')
    if data.get('root') not in data['nodes']:
        raise ValueError('Invalid flake.lock: missing root node.')


def lock_diff(before, after, before_label, after_label):
    return ''.join(difflib.unified_diff(
        (before or b'').decode().splitlines(keepends=True),
        (after or b'').decode().splitlines(keepends=True),
        fromfile=before_label, tofile=after_label,
    ))


def declared_inputs(root):
    # Import only the declaration; do not evaluate outputs or resolve inputs.
    expression = ('builtins.attrNames (import (builtins.toPath '
                  + json.dumps(str(root / 'flake.nix')) + ')).inputs')
    result = subprocess.run(
        ['nix', 'eval', '--impure', '--json', '--expr', expression],
        cwd=root, check=True, stdout=subprocess.PIPE, text=True,
    )
    return json.loads(result.stdout)


def generate_lock(root, operation, before, selected=None):
    if before is not None:
        validate_lock(before)
    if operation == 'init':
        command = ['nix', 'flake', 'lock', flake_ref(root)]
    elif operation in ('one', 'all'):
        command = ['nix', 'flake', 'update', '--flake', flake_ref(root)]
        if operation == 'one':
            if not selected or selected.startswith('-'):
                raise ValueError('Select an input first.')
            command.append(selected)
    else:
        raise ValueError('Unknown lock operation.')
    with tempfile.TemporaryDirectory(prefix='flake-lock-') as directory:
        candidate = Path(directory) / 'candidate.lock'
        command += ['--output-lock-file', str(candidate)]
        if before is not None:
            reference = Path(directory) / 'reference.lock'
            reference.write_bytes(before)
            command += ['--reference-lock-file', str(reference)]
        # Nix writes only the candidate, without touching the real Git index.
        subprocess.run(command, cwd=root, check=True)
        content = candidate.read_bytes()
        validate_lock(content)
        return content


def save_lock(root, before, after):
    path = root / 'flake.lock'
    if read_lock(path) != before:
        raise ValueError('flake.lock changed during review; refusing to overwrite it.')
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=root, delete=False) as handle:
            temporary = Path(handle.name)
            handle.write(after)
        temporary.chmod(path.stat().st_mode & 0o777 if path.exists() else 0o644)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def review_lock(root, content, console):
    baseline = subprocess.run(
        ['git', 'show', 'HEAD:flake.lock'], cwd=root,
        capture_output=True, check=False,
    )
    console.print(lock_diff(
        baseline.stdout if baseline.returncode == 0 else None,
        content, 'HEAD/flake.lock', 'reviewed/flake.lock',
    ) or 'No changes relative to HEAD.', markup=False, highlight=False)
    console.print('Existing staged changes:', markup=False)
    console.print(git(root, 'diff', '--cached', '--no-ext-diff',
                      '--no-textconv', '--', 'flake.lock', capture=True).stdout
                  or '(none)', markup=False, highlight=False)


def run_menu(root, console):
    import questionary

    choices = [
        questionary.Choice('Initialize / complete lock (keep valid pins)', 'init'),
        questionary.Choice('Update one input', 'one'),
        questionary.Choice('Update all inputs', 'all'),
        questionary.Choice('Review current lock changes / stage', 'view'),
        questionary.Choice('Back', 'back'),
    ]
    try:
        operation = questionary.select('Flake lock:', choices=choices).ask()
        if operation in (None, 'back'):
            return
        path = root / 'flake.lock'
        before = read_lock(path)
        if operation == 'view':
            if before is None:
                console.print('No flake.lock. Choose Initialize / complete lock first.')
                return
            review_lock(root, before, console)
            after = before
        else:
            selected = None
            if operation == 'one':
                names = declared_inputs(root)
                if not names:
                    raise ValueError('No declared inputs to update.')
                selected = questionary.select('Input to update:', choices=names).ask()
                if selected is None:
                    return
            scope = {'init': 'missing or outdated lock entries (keep valid pins)',
                     'one': selected, 'all': 'ALL inputs'}[operation]
            console.print(f'Scope: {scope}. Uses declared inputs, not the dev override.',
                          markup=False)
            if not questionary.confirm('Generate candidate lock?', default=False).ask():
                return
            after = generate_lock(root, operation, before, selected)
            console.print(lock_diff(before, after, 'before/flake.lock', 'candidate/flake.lock')
                          or 'Lock content unchanged.', markup=False, highlight=False)
            review_lock(root, after, console)
            decision = questionary.select('After reviewing the diff:', choices=[
                questionary.Choice('Discard candidate / return', 'discard'),
                questionary.Choice('Save without staging', 'save'),
                questionary.Choice('Save and stage entire flake.lock (replace its staged version)', 'stage'),
            ]).ask()
            if decision not in ('save', 'stage'):
                return
            save_lock(root, before, after)
            if decision == 'save':
                console.print('Saved, not staged. Review / stage from flake-lock before prod.')
                return
        if operation == 'view':
            validate_lock(after)
            if not questionary.confirm(
                'Stage the entire current flake.lock (replace its staged version)?',
                default=False,
            ).ask():
                return
        if read_lock(path) != after:
            raise ValueError('flake.lock changed during review; not staging it.')
        try:
            git(root, 'add', '--', 'flake.lock')
        except (OSError, subprocess.CalledProcessError):
            console.print('Lock remains saved; staging failed. Review / stage again later.')
            raise
        console.print('Staged ONLY flake.lock. No commit, push, build or activation performed.')
    except KeyboardInterrupt:
        console.print('Cancelled. Any explicitly saved lock is retained.')
    except (OSError, ValueError, TypeError, subprocess.CalledProcessError) as exc:
        console.print(f'Flake lock operation failed: {exc}', style='red', markup=False)
