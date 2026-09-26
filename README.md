# NixOS configuration

English | [中文](README_zh.md)

A Niri desktop and Home Manager configuration with Flake inputs. Machine settings live in a separate private Git repository checked out at `private-config/`.

## Desktop

Niri, SDDM / Pixie, QuickShell (marko-shell bar), Wofi, Kitty and Mako with Tokyo Night colors.

The bar is the QuickShell configuration in `assets/config/quickshell/marko-shell/`, installed to `~/.config/quickshell/marko-shell`.

The workspace indicator marks urgency with an orange dot. Connected Wi-Fi rows show the BSSID reported by the kernel association through the installed `iw` utility; the SSID from the same association must match the QuickShell row, so nearby APs with the same name cannot be mislabelled. Disconnected rows do not infer an AP address. Legacy Waybar, bzmenu and networkmanager_dmenu are no longer installed by this configuration.

The skinned Qt controls support keyboard input when the popup has keyboard focus. Default hover-dismiss popups remain grab-free; `Theme.popupGrabFocus` is the existing opt-in fallback, with compositor-driven outside-click dismissal.

## Tools

Zsh / Oh My Zsh, Neovim, LLVM / Clang, Python, btop, QQ and optional public-key SSH.

Neovim plugins are pinned submodules deployed read-only; Tree-sitter parsers and queries are installed to the writable Neovim data `site` directory. Use `:TSInstall` for required languages and explicitly run `:TSUpdate` after updating the Tree-sitter plugin. Startup does not install or update parsers.

## Structure

```text
flake.nix                   # System entry point
flake.lock                  # Generate and commit during initial migration
configuration.nix           # Shared system settings
cli.py                      # Interactive CLI and QQ download entry point
scripts/private_config.py   # Private repository management
private-config/             # Independent repository, ignored by the public repo
  host.nix                  # Host, accounts, kernel and stateVersion settings
  hardware-configuration.nix # Machine hardware, UUIDs and mounts
  ssh/                      # SSH settings and client public keys
templates/private-config/   # Public template without real machine information
config/qq-source.json       # Pinned QQ version and hash
desktop/                    # System desktop modules
services/                   # System service modules
marko1616-home/             # Shared Home Manager modules
assets/                     # Dotfiles, images and plugin submodules
```

## Setup

```bash
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/marko1616/nixos-config.git
cd nixos-config
flake_ref="git+file://$PWD?submodules=1"
nix flake lock "$flake_ref"
./cli.py private init
./cli.py private import-hardware
./cli.py private edit-host
./cli.py
```

Review the username, hostname, boot loader and both stateVersion values in `private-config/host.nix`. The template deliberately prevents building a bootable system until the real hardware configuration is supplied.

Use `update-qq` before applying updates when a newer upstream release is needed; do not update when reproducing or rolling back a pinned version. The source metadata is `config/qq-source.json`.

## Private configuration

```bash
./cli.py private switch \
  git@github.com:YOUR_ACCOUNT/private-config.git
./cli.py private status
```

Switching refuses uncommitted local changes, checks out the candidate at the exact private revision resolved by the new lock (detached HEAD), validates it, retains the old directory as a backup, and restores the input/lock on failure. Create a development branch before making new commits in that checkout. Private-repository commands never commit, push or activate the system; the interactive `switch-dev` and `switch-prod` actions do activate it. Remote input URLs and revisions remain visible in the public lock file. Do not put private keys or passwords in Flake sources.

## Build and activate

Open the interactive menu with `./cli.py`, select one of these four actions, then confirm. These are menu entries, not subcommands such as `./cli.py build-dev`.

| Action | Private configuration source | Effect |
| --- | --- | --- |
| `build-dev` | Local `private-config/`, including uncommitted changes | Build only |
| `switch-dev` | Same as above | Build and immediately activate |
| `build-prod` | Input declared in `flake.nix` and pinned in `flake.lock` | Build only |
| `switch-prod` | Same as above | Build and immediately activate |

All four invoke `sudo nixos-rebuild`, target `default`, and use the current local public Git working tree with submodules. `prod` **does not fetch the public repository's latest HEAD**, nor update the private revision automatically. If the input still points to the template, prod uses that template and hits its protective assertions. Prod requires a reviewed, Git-indexed `flake.lock` and uses `--no-update-lock-file`: missing or mismatched locks fail instead of being silently refreshed.

`dev` overrides the private input with the local directory and adds `--no-write-lock-file`; prod does not override inputs. New public configuration files must be in the Git index to be included in the Git flake. `private build-local` has been removed; use the interactive `build-dev` entry instead (it invokes sudo).

Equivalent manual build workflow:

Test local configuration without updating the lock:

```bash
sudo nixos-rebuild build --flake "$flake_ref#default" \
  --override-input private-config "path:$PWD/private-config" --no-write-lock-file
```

After committing and pushing private changes, use the locked remote input:

```bash
nix flake update --flake "$flake_ref" private-config
sudo nixos-rebuild build --flake "$flake_ref#default" --no-update-lock-file
sudo nixos-rebuild test --flake "$flake_ref#default" --no-update-lock-file
sudo nixos-rebuild switch --flake "$flake_ref#default" --no-update-lock-file
```

Check SSH and desktop behavior before rebooting to verify the kernel and SDDM. No copy into `/etc/nixos` is needed.
