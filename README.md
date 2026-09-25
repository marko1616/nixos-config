# NixOS Configuration

[ English | [中文](README_zh.md) ]

My personal NixOS configuration and desktop environment, using a traditional non-flake configuration with Home Manager.

## Features

### Desktop Environment

* **Niri** — Wayland compositor
* **SDDM** — Display manager with a custom theme and avatar
* **Waybar** — Status bar
* **Wofi** — Application launcher
* **Kitty** — Terminal emulator
* **Mako** — Notifications
* **Tokyo Night** — Main color theme

### Tools

* **Zsh + Oh My Zsh** — Shell with the `fino` theme
* **Neovim** — Editor with plugin submodules
* **LLVM / Clang** — C/C++ toolchain
* **Python** — Development environment
* **btop** — System monitor
* **Git** — Version control
* **Home Manager** — User environment management
* **QQ** — AppImage package with a source updater
* **OpenSSH** — Optional public-key-only access for one account

## Structure

```text
.
├── assets/                     # Shared dotfiles and desktop assets
│   ├── avatars/                # User avatars
│   ├── config/                 # Application dotfiles
│   ├── login-background/       # SDDM background images
│   ├── plugins/
│   │   └── nvim/               # Neovim plugin submodules
│   └── wallpapers/             # Desktop wallpapers
├── config/                     # Local custom configuration
│   └── ssh/                    # Created by CLI; ignored by Git
│       ├── authorized_keys     # Imported client public keys
│       └── settings.json       # SSH account and enable flag
├── desktop/                    # Desktop environment modules
│   ├── niri.nix                # Niri configuration
│   ├── sddm-avatars.nix         # SDDM avatars
│   └── sddm-theme.nix           # SDDM theme
├── marko1616-home/              # Home Manager configuration
│   ├── home.nix                # User configuration entry point
│   ├── qq.nix                  # QQ AppImage package
│   ├── qq-source.json          # Pinned QQ version, URL and hash
│   └── ...                     # Shell, editor and development tools
├── services/
│   └── ssh.nix                 # SSH service module
├── cli.py                      # Interactive SSH configuration and QQ updater
├── configuration.nix           # Main NixOS configuration
├── README.md                   # English documentation
└── README_zh.md                # Chinese documentation
```

`assets/config/` holds dotfiles; `config/` holds local custom configuration.

## Setup

This is a personal configuration. Review the username, hostname, hardware settings and paths before applying it to another machine.

Clone with shallow submodules:

```bash
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/marko1616/nixos-config.git
cd nixos-config
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive --depth 1
```

### Configuration CLI

```bash
./cli.py
```

The `nix-shell` shebang provides Python and the required dependencies automatically. No separate `shell.nix` or manual Python package installation is needed. If the executable bit is missing, run `chmod +x cli.py` once.

Select a task, confirm it, and return to the menu when it finishes:

| Task | Action |
| --- | --- |
| `configure-ssh` | Choose an existing normal account and import a client public key file |
| `disable-ssh` | Disable SSH in the configuration while retaining the public keys |
| `update-qq` | Download the latest official x86_64 QQ AppImage and update its pinned version and SHA-256 |
| `exit` | Exit the tool |

### SSH

The CLI automatically creates `config/ssh/settings.json` and `config/ssh/authorized_keys` on first launch without overwriting existing files. SSH starts disabled.

Import a client `.pub` file, or a file containing one public key per line. Reconfiguration replaces the previously imported keys. The selected account must already exist in the NixOS configuration.

When enabled, SSH listens on **`0.0.0.0:22` only** and allows public-key authentication for the selected account. Root login, password authentication, keyboard-interactive authentication and IPv6 listening are disabled. Home-directory `authorized_keys` files are not read.

### QQ

`marko1616-home/qq.nix` reads the version, permanent download URL and SHA-256 from `marko1616-home/qq-source.json`.

Builds automatically obtain a fresh download signature when required. `update-qq` downloads the complete AppImage, calculates its hash and imports it into the Nix store for reuse during the next build. Expiring signed URLs are not saved. The package currently targets x86_64.

### Apply

**Before each use of this configuration, including the first setup, run `./cli.py` and select `update-qq` to refresh the QQ version and hash before rebuilding.**

The CLI edits configuration files; it does not rebuild the system.

Keep your machine's `/etc/nixos/hardware-configuration.nix`. From the repository root, after running the CLI, copy the configuration **including all of `assets/` and the Git-ignored `config/ssh/` directory**:

```bash
sudo cp -a configuration.nix cli.py desktop services marko1616-home assets config /etc/nixos/
sudo nixos-rebuild switch
```

Skip copying if the repository is already managed in `/etc/nixos`. Repeat the copy and rebuild after changing SSH settings or updating QQ. Keep your current SSH session open until a new connection succeeds when applying SSH changes remotely.

