#!/usr/bin/env nix-shell
#! nix-shell -i python3
#! nix-shell -p "python3.withPackages (ps: [ ps.typer ps.questionary ps.rich ])" openssh cacert nix

import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parent
SSH_DIR = ROOT / "private-config" / "ssh"
QQ_SOURCE = ROOT / "config" / "qq-source.json"

QQ_CONFIG_URLS = [
    "https://im.qq.com/proxy/domain/cdn-go.cn/qq-web/im.qq.com_new/latest/rainbow/pcConfig.json",
    "https://cdn-go.cn/qq-web/im.qq.com_new/latest/rainbow/pcConfig.json",
]

QQ_SIGN_URL = (
    "https://im.qq.com/http2rpc/gotrpc/noauth/"
    "trpc.qqntv2.urlsign.UrlSign/GetSign"
)

HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://im.qq.com/",
}


def write_file(path, content):
    """Replace a configuration file after writing its complete content."""
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            delete=False,
        ) as handle:
            temporary = Path(handle.name)
            handle.write(content)

        temporary.chmod(0o644)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def ensure_ssh_config():
    """Create local SSH configuration without overwriting existing files."""
    if not (ROOT / "private-config" / "host.nix").is_file():
        raise OSError("Initialize private-config/ first: python3 cli.py private init")
    SSH_DIR.mkdir(parents=True, exist_ok=True)

    defaults = {
        "settings.json": json.dumps(
            {"enable": False, "user": ""},
            indent=2,
        ) + "\n",
        "authorized_keys": "# Import client public keys using ./cli.py\n",
    }

    for name, content in defaults.items():
        path = SSH_DIR / name
        if not path.exists():
            write_file(path, content)


def request_json(url, data=None):
    headers = dict(HEADERS)

    if data is not None:
        headers["Content-Type"] = "application/json"
        headers["x-oidb"] = (
            '{"uint32_command":"0x9b8e","uint32_service_type":1}'
        )

    request = urllib.request.Request(
        url,
        data=None if data is None else json.dumps(data).encode(),
        headers=headers,
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def normalize_qq_url(url):
    """Validate the official x86_64 AppImage URL and remove its signature."""
    parsed = urllib.parse.urlsplit(url)

    if (
        parsed.scheme != "https"
        or parsed.hostname not in {
            "qqdl.gtimg.cn",
            "dldir1.qq.com",
            "dldir1v6.qq.com",
        }
        or parsed.username
        or parsed.password
        or parsed.port not in (None, 443)
    ):
        raise ValueError("Expected an official QQ HTTPS download URL.")

    filename = Path(parsed.path).name
    if not re.fullmatch(
        r"QQ_[0-9.]+_[0-9]+_x86_64_[0-9]+\.AppImage",
        filename,
    ):
        raise ValueError("Expected an x86_64 QQ AppImage.")

    return urllib.parse.urlunsplit(
        (parsed.scheme, parsed.netloc, parsed.path, "", "")
    )


def latest_qq_source():
    errors = []

    for config_url in QQ_CONFIG_URLS:
        try:
            linux = request_json(config_url)["Linux"]
            url = normalize_qq_url(linux["x64DownloadUrl"]["appimage"])
            filename = Path(urllib.parse.urlsplit(url).path).name

            return {
                "version": filename.split("_")[1],
                "url": url,
            }
        except (OSError, ValueError, KeyError, TypeError) as exc:
            errors.append(str(exc))

    raise ValueError(
        "Cannot read the official QQ release configuration: "
        + "; ".join(errors)
    )


def signed_qq_url(url):
    url = normalize_qq_url(url)

    # Older releases use direct download hosts.
    if urllib.parse.urlsplit(url).hostname != "qqdl.gtimg.cn":
        return url

    response = request_json(QQ_SIGN_URL, {"url": url})

    if not isinstance(response, dict) or response.get("retcode") != 0:
        raise ValueError("QQ GetSign failed.")

    signed = response.get("url")
    if signed is None and isinstance(response.get("data"), dict):
        signed = response["data"].get("url")

    if not isinstance(signed, str) or normalize_qq_url(signed) != url:
        raise ValueError("QQ GetSign returned an unexpected URL.")

    return signed


def fetch_qq(url, destination):
    """Download the AppImage and return its flat SHA-256 in SRI format."""
    temporary = None

    try:
        request = urllib.request.Request(
            signed_qq_url(url),
            headers=HEADERS,
        )
        digest = hashlib.sha256()

        with urllib.request.urlopen(request, timeout=60) as response:
            # Use the build temporary directory, not a sibling of $out.
            with tempfile.NamedTemporaryFile(delete=False) as handle:
                temporary = Path(handle.name)

                header = response.read(12)
                if (
                    header[:4] != b"\x7fELF"
                    or header[8:11] not in (b"AI\x01", b"AI\x02")
                ):
                    raise ValueError("The download is not an AppImage.")

                handle.write(header)
                digest.update(header)

                while chunk := response.read(1024 * 1024):
                    handle.write(chunk)
                    digest.update(chunk)

        shutil.move(str(temporary), str(destination))
        return "sha256-" + base64.b64encode(digest.digest()).decode()
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


# Internal Nix build entry point: no interactive Python dependencies needed.
if __name__ == "__main__" and sys.argv[1:2] == ["--fetch-qq"]:
    if len(sys.argv) != 4:
        sys.exit("Usage: python3 cli.py --fetch-qq URL OUTPUT")

    try:
        print(fetch_qq(sys.argv[2], Path(sys.argv[3])))
    except (OSError, ValueError, TypeError) as exc:
        sys.exit(f"QQ download failed: {exc}")

    sys.exit(0)


# Private-repository commands and the QQ builder need no UI dependencies.
if __name__ == "__main__" and sys.argv[1:2] == ["private"]:
    from scripts.private_config import main
    sys.exit(main(ROOT, sys.argv[2:]))

import questionary
from rich.console import Console
from rich.panel import Panel
import typer

app = typer.Typer()
console = Console()

# All available actions with descriptions
TASKS = [
    {
        "name": "build-dev",
        "desc": "Build with the local private-config/ and keep flake.lock unchanged.",
    },
    {
        "name": "switch-dev",
        "desc": "Build and activate with the local private-config/.",
    },
    {
        "name": "build-prod",
        "desc": "Build using the repository inputs pinned in flake.lock.",
    },
    {
        "name": "switch-prod",
        "desc": "Build and activate using the repository inputs pinned in flake.lock.",
    },
    {"name": "private-init", "desc": "Initialize private-config/ from the public template."},
    {"name": "private-switch", "desc": "Switch the private-config repository and lock its input."},
    {"name": "private-status", "desc": "Check the private-config repository and input mapping."},
    {"name": "private-edit-host", "desc": "Edit private-config/host.nix using EDITOR."},
    {"name": "private-import-hardware", "desc": "Import the current /etc/nixos hardware file."},
    {
        "name": "configure-ssh",
        "desc": "Import public keys for one account, using IPv4 only.",
    },
    {
        "name": "disable-ssh",
        "desc": "Disable SSH in the configuration.",
    },
    {
        "name": "update-qq",
        "desc": "Update the official QQ AppImage version and hash.",
    },
    {
        "name": "exit",
        "desc": "Exit the CLI tool.",
    },
]


def run_nixos_rebuild(action, development):
    """Build or activate NixOS with local or locked private configuration."""
    environment = "dev" if development else "prod"
    console.print(Panel.fit(
        f"[cyan]Running NixOS {action} ({environment})[/cyan]"
    ))

    try:
        from scripts.private_config import flake_ref, require_repo, require_prod_lock

        command = [
            "sudo",
            "nixos-rebuild",
            action,
            "--flake",
            flake_ref(ROOT) + "#default",
        ]

        if http_proxy := os.environ.get("HTTP_PROXY"):
            command.insert(1, f"HTTP_PROXY={http_proxy}")

        if https_proxy := os.environ.get("HTTPS_PROXY"):
            command.insert(1, f"HTTPS_PROXY={https_proxy}")

        if development:
            private_config = ROOT / "private-config"
            require_repo(private_config)
            command.extend([
                "--override-input",
                "private-config",
                "path:" + str(private_config),
                "--no-write-lock-file",
            ])
        else:
            require_prod_lock(ROOT)
            command.append("--no-update-lock-file")

        subprocess.run(command, cwd=ROOT, check=True)
        console.print(
            f"[green]NixOS {action} ({environment}) completed.[/green]"
        )
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        console.print(
            f"NixOS {action} ({environment}) failed: {exc}",
            style="red",
            markup=False,
        )


def read_public_keys(path):
    content = path.read_text(encoding="utf-8")

    if "PRIVATE KEY" in content:
        raise ValueError("Select a public key file, not a private key.")

    keys = [
        line.strip()
        for line in content.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]

    if not keys:
        raise ValueError("The public key file is empty.")

    for key in keys:
        if not re.match(r"^(ssh-|ecdsa-|sk-)\S+\s+\S+", key):
            raise ValueError("Expected an OpenSSH public key.")

        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8"
        ) as handle:
            handle.write(key + "\n")
            handle.flush()

            result = subprocess.run(
                ["ssh-keygen", "-l", "-f", handle.name],
                capture_output=True,
                text=True,
            )

            if result.returncode:
                raise ValueError("Invalid OpenSSH public key.")

    return "\n".join(dict.fromkeys(keys)) + "\n"


def run_configure_ssh():
    """Import public keys and configure one existing account."""
    console.print(Panel.fit(
        "[cyan]Configure SSH: public keys, one account, IPv4 port 22[/cyan]"
    ))

    try:
        ensure_ssh_config()
        settings_path = SSH_DIR / "settings.json"
        settings = json.loads(settings_path.read_text(encoding="utf-8"))

        user = questionary.text(
            "Existing NixOS account:",
            default=settings["user"],
        ).ask()

        if user is None:
            return

        user = user.strip()
        if user == "root" or not re.fullmatch(r"[a-z_][a-z0-9_-]*", user):
            raise ValueError("Enter a normal account name, not root.")

        source = questionary.path(
            "Client public key file (.pub):"
        ).ask()

        if not source:
            return

        keys = read_public_keys(Path(source).expanduser())

        write_file(SSH_DIR / "authorized_keys", keys)
        write_file(
            settings_path,
            json.dumps({"enable": True, "user": user}, indent=2) + "\n",
        )

        console.print("[green]SSH configuration saved.[/green]")
        console.print("Rebuild NixOS to apply the configuration.")
    except (OSError, ValueError, KeyError) as exc:
        console.print(
            f"SSH configuration failed: {exc}",
            style="red",
            markup=False,
        )


def run_disable_ssh():
    """Disable SSH while keeping the imported public keys."""
    console.print(Panel.fit("[cyan]Disabling SSH[/cyan]"))

    try:
        ensure_ssh_config()
        path = SSH_DIR / "settings.json"
        settings = json.loads(path.read_text(encoding="utf-8"))
        settings["enable"] = False

        write_file(path, json.dumps(settings, indent=2) + "\n")

        console.print("[green]SSH disabled in configuration.[/green]")
        console.print("Rebuild NixOS to apply the configuration.")
    except (OSError, ValueError) as exc:
        console.print(
            f"SSH configuration failed: {exc}",
            style="red",
            markup=False,
        )


def run_update_qq():
    """Download the latest AppImage and update its pinned source."""
    console.print(Panel.fit("[cyan]Updating QQ[/cyan]"))

    try:
        source = latest_qq_source()
        console.print(f"Latest version: {source['version']}")
        console.print("Downloading AppImage and calculating SHA-256...")

        with tempfile.TemporaryDirectory(prefix="qq-update-") as directory:
            filename = Path(
                urllib.parse.urlsplit(source["url"]).path
            ).name
            image = Path(directory) / filename

            source["hash"] = fetch_qq(source["url"], image)

            # Reuse this download during the next Nix build.
            subprocess.run(
                ["nix-store", "--add-fixed", "sha256", str(image)],
                check=True,
            )

            write_file(
                QQ_SOURCE,
                json.dumps(source, indent=2) + "\n",
            )

        console.print("[green]QQ source updated successfully.[/green]")
        console.print("Rebuild NixOS to apply the update.")
    except (
        OSError,
        ValueError,
        TypeError,
        subprocess.CalledProcessError,
    ) as exc:
        console.print(
            f"QQ update failed: {exc}",
            style="red",
            markup=False,
        )


def main_menu():
    """Main loop for interactive selection and task execution."""
    while True:
        options = [
            questionary.Choice(
                title=f"{task['name']} - {task['desc']}",
                value=task["name"],
            ) for task in TASKS
        ]

        selected = questionary.select(
            "Choose a task to perform:",
            choices=options,
        ).ask()

        if selected is None or selected == "exit":
            console.print("[bold blue]Bye.[/bold blue]")
            break

        confirm = questionary.confirm(
            f"Proceed with `{selected}`?"
        ).ask()

        if confirm:
            if selected in {
                "build-dev",
                "switch-dev",
                "build-prod",
                "switch-prod",
            }:
                action, environment = selected.split("-", 1)
                run_nixos_rebuild(action, environment == "dev")
            elif selected.startswith("private-"):
                from scripts.private_config import main as private_main
                command = selected.removeprefix("private-")
                arguments = [command]
                if command == "switch":
                    url = questionary.text("Private Git repository URL:").ask()
                    if not url:
                        continue
                    arguments.append(url)
                private_main(ROOT, arguments)
            elif selected == "configure-ssh":
                run_configure_ssh()
            elif selected == "disable-ssh":
                run_disable_ssh()
            elif selected == "update-qq":
                run_update_qq()
        else:
            console.print(
                "[yellow]Cancelled. Returning to menu.[/yellow]"
            )


@app.command()
def interactive():
    """Start the interactive CLI."""
    console.print(
        "[bold green]Welcome to the project's CLI Tool![/bold green]"
    )

    main_menu()


if __name__ == "__main__":
    app()
