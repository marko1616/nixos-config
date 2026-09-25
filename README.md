# NixOS configuration

English | [中文](README_zh.md)

A Niri desktop and Home Manager configuration with Flake inputs. Machine settings live in a separate private Git repository checked out at `private/`.

## Desktop

Niri, SDDM / Pixie, QuickShell (marko-shell bar), Wofi, Kitty and Mako with Tokyo Night colors.

The bar is the QuickShell configuration in `assets/config/quickshell/marko-shell/`, installed to `~/.config/quickshell/marko-shell`.

## Tools

Zsh / Oh My Zsh, Neovim, LLVM / Clang, Python, btop, QQ and optional public-key SSH.

## Structure

```text
flake.nix                   # System entry point and CLI development environment
flake.lock                  # Generate and commit during initial migration
configuration.nix           # Shared system settings
cli.py                      # Interactive CLI and QQ download entry point
private_config.py           # Private repository management
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

Review the username, hostname, boot loader and both stateVersion values in `private/host.nix`. The template deliberately prevents building a bootable system until the real hardware configuration is supplied.

Use `update-qq` before applying updates when a newer upstream release is needed; do not update when reproducing or rolling back a pinned version. The source metadata is `config/qq-source.json`.

## Private configuration

```bash
./cli.py private switch \
  git@github.com:YOUR_ACCOUNT/private-config.git
./cli.py private status
```

Switching refuses uncommitted local changes, retains the old directory as a backup, and restores the input/lock on failure. The CLI never commits, pushes or activates the system. Remote input URLs and revisions remain visible in the public lock file. Do not put private keys or passwords in Flake sources.

## Build

Test local configuration without updating the lock:

```bash
sudo nixos-rebuild build --flake "$flake_ref#default" \
  --override-input private-config "path:$PWD/private-config" --no-write-lock-file
```

After committing and pushing private changes, use the locked remote input:

```bash
nix flake update --flake "$flake_ref" private-config
sudo nixos-rebuild build --flake "$flake_ref#default"
sudo nixos-rebuild test --flake "$flake_ref#default"
sudo nixos-rebuild switch --flake "$flake_ref#default"
```

Check SSH and desktop behavior before rebooting to verify the kernel and SDDM. No copy into `/etc/nixos` is needed.
