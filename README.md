# NixOS configuration

English | [中文](README_zh.md)

A Niri desktop and Home Manager configuration with Flake inputs. Machine settings live in a separate private Git repository checked out at `private-config/`.

## Desktop

Niri, SDDM / Pixie, QuickShell (marko-shell bar), Wofi, Kitty and Mako with Tokyo Night colors.

The default Tokyo Night colors live in `theme/colors.nix`. Each application and semantic role has its own key even when values match. `theme/default.nix` generates the QuickShell and Neovim color modules and renders configuration-only targets (Niri, Wofi, Mako, Kitty, Fcitx5 and btop) from `.in` templates. To override colors without editing the public defaults, create `private-config/theme/settings.json` from the template and set `enable` to `true`; `colors` is a partial nested override using the same role names as `theme/colors.nix`, for example `"colors": {"quickshell": {"barBackground": "#28363B"}}`. Missing roles retain the defaults; disabling or removing the file restores them. Neovim also accepts advanced `colors.neovim.palette` entries, which are forwarded to Tokyo Night. Unknown roles, non-color values and invalid color syntax fail evaluation. Existing private-config checkouts must add and stage the new `theme/settings.json` themselves; `private init` only copies templates when creating a checkout. Use the `./cli.py` `build-dev` / `switch-dev` menu items to test and activate. Do not edit generated files in the Nix store.

mpvpaper displays the bundled single-image wallpaper by default; the private-config template has `"enable": false` and an empty `path`. To select another image or an MP4, edit `private-config/wallpaper/settings.json`: set `enable` to `true` and choose `path`. Relative paths are resolved from the **private-config root**: `"path": "wallpaper/picture.jpg"` selects `private-config/wallpaper/picture.jpg`, and `"path": "wallpaper/desktop.mp4"` selects an MP4 there. Absolute paths also work, for example `"path": "/home/<USER>/Videos/desktop.mp4"`; `~` is not expanded and `..` is not allowed in relative paths. Media tracked inside private-config enters the Nix store with that flake input, while an absolute path outside the repository is read at runtime without copying the media into the store. If the configured file is missing when Niri starts, the bundled image is used. Apply the configuration through the `build-dev` / `switch-dev` menu items and log in again. Existing private-config checkouts need the new `wallpaper/settings.json` file copied from `templates/private-config/`; `private init` copies the template only when creating a new checkout. Stage new private files in the private repository before `build-dev`, because Git-backed flake inputs omit untracked files.

The bar is the QuickShell configuration in `assets/config/quickshell/marko-shell/`, installed to `~/.config/quickshell/marko-shell`.

Fcitx5's Classic UI candidate panel is rendered from the templates in `assets/config/fcitx5/marko-shell/` and used by system default. Home Manager also links it into `~/.local/share/fcitx5/themes/marko-shell/`, so the theme remains discoverable even if Fcitx was not launched through the bundled wrapper. Its Tokyo Night colors and rounded SVG backgrounds match the bar. An existing `~/.config/fcitx5/conf/classicui.conf` takes precedence over the system default: in Fcitx5 Configuration → Addons → Classic User Interface, select **Marko Shell** for Theme (and Dark Theme if following the system color scheme). If the theme is absent after activation, log out and back in before checking again. Classic UI themes do not animate the candidate panel; the QuickShell popup animation does not apply to Fcitx5.
The Rime input method ships as scheme `marko-input`: Flypy double pinyin by default, `Shift+U` for stroke and component lookup plus the symbol categories `udw`, `uxh`, `uts`, `ubd`, `usx`, `ujh` and `uzm`, and `Shift+V` for Chinese numbers, dates, times and formulas, along with Unicode code points (`UC`) and GB18030 codes (`GB`). Set `programs.markoInput.enable = false;` to turn it off. Upstream sources are pinned by revision and the schemas are compiled during the build; activation does not touch user Rime data. After switching, log out and back in, then choose Rime's Deploy action to refresh the per-user cache. See [Rime U/V modes](docs/rime-uv.md).

The workspace indicator marks urgency with an orange dot. Wi-Fi rows read BSSIDs from NetworkManager's cached scan results, so disconnected networks show the strongest visible access point as well as the number of additional matches. The active association is only shown when the scan identifies exactly one active BSSID for that device and SSID. Password entry uses the shell's own NetworkManager activation helper, so clicking Connect does not open a second system password dialog. Legacy Waybar, bzmenu and networkmanager_dmenu are no longer installed by this configuration.

Interactive panels use a keyboard-capable transparent overlay. Its input mask lets pointer events reach the bar while observing movement and outside clicks below it. Leaving both the bar and panel for 500 ms starts a one-way exit animation; moving back after exit begins does not reverse it. Outside clicks are consumed and animate the close; Escape also closes the panel. The bar and panel share a brighter base color and a thin outline following their fused SDF contour. Adjust `popupLeaveDelay` in `Theme.qml` to change the delay. The borderless password field vertically centres its text, placeholder and caret. Tooltips remain non-interactive and do not take keyboard focus.

The animated locker uses a separate QuickShell 0.3.2 instance with Qt Multimedia and the system PAM service. `Super+Alt+L` locks; it reuses the private wallpaper and motion tokens, with independent lockscreen colors in `theme/colors.nix` and optional `colors.lockscreen` private overrides. Stage new files, use the `build-dev` / `switch-dev` menu items in `./cli.py`, then log out/in; locking needs no sudo. The daemon starts on first use and remains resident after unlock. If secure acknowledgement does not arrive, the command reports failure rather than claiming success; Niri retains its locked background if an active locker exits abnormally. See [lockscreen architecture and acceptance](docs/lockscreen.md) for recovery. No idle/suspend policy is added. Video playback is independent of mpvpaper, so handoff can jump in phase.

## Tools

Zsh / Oh My Zsh, Neovim, LLVM / Clang, Python, btop, QQ and optional public-key SSH.

Neovim plugins are pinned submodules deployed read-only; Tree-sitter parsers and queries are installed to the writable Neovim data `site` directory. Use `:TSInstall` for required languages and explicitly run `:TSUpdate` after updating the Tree-sitter plugin. Startup does not install or update parsers.

## Structure

For a navigable file/deployment map and the active shortcuts, start at the [documentation index](docs/README.md).

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
theme/                      # Unified colors and build-time renderers
assets/                     # Dotfiles, images and plugin submodules
```

## Setup

```bash
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/marko1616/nixos-config.git
cd nixos-config
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

## Lock file menu

Open `./cli.py` → `flake-lock` (a menu entry, not a subcommand): initialize / complete a lock while keeping valid pins, update one declared input, update all inputs, or review / stage the current lock. Use initialize / complete for first-time setup. Updates use the inputs declared in `flake.nix`, without the dev override; updating `private-config` does not change its local checkout.

Nix writes a temporary candidate first. Review the before/after and HEAD diffs, then discard it, save without staging, or save and stage **only the entire `flake.lock`** (replacing its previous staged version). Other staged files are untouched. Generation failure or cancellation before saving leaves the original lock and index unchanged; a staging failure retains the saved lock for retry. No sudo, commit, push, build or activation occurs. The existing strict prod lock checks remain in place.

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

After committing and pushing private changes, choose `flake-lock` → update one input → `private-config`, review and stage the result, then choose `build-prod` or `switch-prod`.

Check SSH and desktop behavior before rebooting to verify the kernel and SDDM. No copy into `/etc/nixos` is needed.
