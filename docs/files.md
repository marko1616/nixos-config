# Files and deployment

English | [中文](files_zh.md)

This is a map of the repository's entry points and files, not an instruction to copy files manually. For setup and the `./cli.py` menu, see the [README](../README.md). For the active key bindings, see [shortcuts](shortcuts.md).

## Configuration path

| Source | Role |
| --- | --- |
| `flake.nix` | Declares pinned inputs and the `nixosConfigurations.default` entry. It imports `configuration.nix` and `host.nix` from the private input. |
| `flake.lock` | Pins resolved input revisions; generate and review it before a production build. |
| `configuration.nix` | Shared NixOS settings and imports for `desktop/` and `services/`. |
| `desktop/` | Niri, SDDM, Rime and desktop data modules. |
| `marko1616-home/home.nix` | Shared Home Manager entry; imports the desktop, shell, editor and other user modules. |
| `services/` | Optional system services, including SSH and WireGuard, driven by private settings. |
| `templates/private-config/` | Public bootstrap template. `./cli.py private init` copies it into the separate `private-config/` repository. |
| `scripts/private_config.py` | Implements private-repository management behind `./cli.py`. |
| `config/qq-source.json` | Version and hash metadata used by the QQ packaging workflow. |

`private-config/` holds real host settings and is ignored by the public repository. Hardware configuration, identifiers and site-specific service settings belong there; private keys and passwords must not enter either Flake source. The public `assets/` directory contains dotfiles, images and pinned submodules, not live user state.

## Assets and installed locations

These mappings come from `marko1616-home/desktop-environment.nix`, `marko1616-home/nvim.nix`, and related Home Manager modules:

| Repository source | Installed user location or use |
| --- | --- |
| `assets/config/niri/config.kdl` | `~/.config/niri/config.kdl`; Niri layout, rules and key bindings |
| `assets/config/quickshell/marko-shell/` | `~/.config/quickshell/marko-shell/`; shader compiled during the Home Manager build |
| `assets/config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `assets/config/wofi/{config,style.css}` | `~/.config/wofi/` |
| `assets/config/mako/config` | `~/.config/mako/config` |
| `assets/config/fcitx5/marko-shell/` | `~/.local/share/fcitx5/themes/marko-shell/`, plus the system Fcitx theme package |
| `assets/config/nvim/` | `~/.config/nvim/` |
| `assets/plugins/nvim/` | `~/.local/share/nvim/plugins/`; pinned plugin submodules |
| `assets/config/zsh/greeting.*` | `~/.config/zsh/` |
| `assets/config/btop/btop.conf` | `~/.config/btop/btop.conf` |
| `assets/wallpapers/148557481_p1.jpg` | `~/.local/share/wallpapers/desktop.png` |

`desktop/rime-data.nix` builds a Rime data package from `assets/rime/`, the `assets/rime-ice` submodule and pinned upstream sources. `desktop/rime.nix` adds that package to Fcitx5 when `programs.markoInput.enable` is true. The data is not installed by copying `assets/rime/` into the user's home. See [Rime U/V modes](rime-uv.md) for activation and redeployment.

## Editing and applying changes

Edit the repository source, not the Home Manager-managed link under `~/.config`. For a new public file referenced by a Git-backed Flake, add it to the Git index before building; an untracked file can be omitted from the Flake source. Open `./cli.py` and choose `build-dev` or `switch-dev` for the local private checkout, or `build-prod` / `switch-prod` for the locked remote private input. Those names are menu entries, **not** `./cli.py` subcommands. A system switch does not automatically restart every running desktop application; follow component-specific notes such as [Rime redeployment](rime-uv.md).
