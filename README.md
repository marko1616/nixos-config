# NixOS Configuration

[ English | [中文](README_zh.md) ]

My personal NixOS configuration and desktop environment.

## Features

### Desktop Environment

* **Niri** — Wayland compositor
* **SDDM** — Display manager
* **Waybar** — Status bar
* **Fuzzel** — Application launcher
* **Kitty** — Terminal emulator
* **Tokyo Night** — Main color theme

### Tools

* **Zsh** + **Oh My Zsh** — Shell
* **Neovim** — Text editor
* **btop** — System monitor
* **Git** — Version control
* **Home Manager** — User environment management

### Other

* Custom application configurations
* Personal wallpapers and desktop assets
* Custom Nix packages

## Structure

```text
.
├── assets/
│   └── config/
├── desktop/
├── marko1616-home/
├── configuration.nix
├── hardware-configuration.nix
├── README.md
└── README_zh.md
```

### `assets/`

Application configuration files and personal assets.

### `desktop/`

Desktop environment related Nix configuration.

### `marko1616-home/`

Home Manager configuration.

### `configuration.nix`

Main NixOS configuration.

## Notes

This is a personal configuration and is not intended to be a general-purpose NixOS template.

Some configuration is specific to my machine and environment.

### QQ

The QQ package requires the QQ AppImage to be obtained and added manually because the binary is not included in this repository.

See `marko1616-home/qq.nix` for the package configuration.

## License

Personal configuration. Use at your own discretion.

