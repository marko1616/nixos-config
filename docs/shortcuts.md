# Default shortcuts in this repository

English | [中文](shortcuts_zh.md)

These are **active bindings in the checked-in configuration**, not a list of all Niri, Neovim or Fcitx defaults. Niri's source of truth is [`assets/config/niri/config.kdl`](../assets/config/niri/config.kdl) under `binds`. `Mod` means Super in a normal Niri TTY session (Alt in its winit backend); `Ctrl` and `Shift` are separate modifiers. `Mod+Shift+/` opens Niri's on-screen hotkey overlay. Lines commented out in the KDL are not active.

## Niri: launch and session

| Keys | Action |
| --- | --- |
| `Mod+T` / `Mod+D` | Open Kitty / Wofi |
| `Super+Alt+L` | Lock with swaylock |
| `Mod+O` | Toggle overview |
| `Mod+Q` | Close focused window |
| `Mod+Shift+E` or `Ctrl+Alt+Delete` | Quit Niri, with confirmation |
| `Mod+Shift+P` | Power off monitors until the next input |
| `Mod+Escape` | Toggle shortcut inhibition; escape hatch for remote-control applications |

## Niri: focus and move

| Keys | Action |
| --- | --- |
| `Mod+Left/Right` or `Mod+H/L` | Focus adjacent column |
| `Mod+Up/Down` or `Mod+K/J` | Focus window above/below |
| Add `Ctrl` to those direction keys | Move the focused column left/right, or window up/down |
| `Mod+Home/End`; add `Ctrl` | Focus first/last column; move column to first/last |
| `Mod+Shift+direction` or `Mod+Shift+H/J/K/L` | Focus adjacent monitor |
| Add `Ctrl` to the preceding monitor bindings | Move column to adjacent monitor |
| `Mod+Page_Up/Page_Down` or `Mod+I/U` | Focus workspace up/down |
| Add `Ctrl` to those workspace bindings | Move column to workspace up/down |
| `Mod+Shift+Page_Up/Page_Down` or `Mod+Shift+I/U` | Reorder the workspace up/down |
| `Mod+1…9`; add `Ctrl` | Focus numbered workspace; move column there |

Niri workspaces are dynamic: requesting an index beyond the existing workspaces selects the bottommost empty workspace. `Mod+wheel` also changes workspaces; `Mod+Ctrl+wheel` moves a column between them. Horizontal wheel or `Mod+Shift+vertical wheel` changes focused column; add `Ctrl` to move that column.

## Niri: layout and display

| Keys | Action |
| --- | --- |
| `Mod+[` / `Mod+]` | Consume or expel a window toward the left/right column |
| `Mod+,` / `Mod+.` | Consume from right into the focused column / expel its bottom window |
| `Mod+R` / `Mod+Shift+R` | Cycle preset column widths forward/backward |
| `Mod+Ctrl+Shift+R` / `Mod+Ctrl+R` | Cycle preset window heights / reset height |
| `Mod+F` / `Mod+Shift+F` | Maximize column / fullscreen window |
| `Mod+M` / `Mod+Ctrl+F` | Maximize window to screen edges / expand column to available width |
| `Mod+C` / `Mod+Ctrl+C` | Center focused column / visible columns |
| `Mod+-` / `Mod+=` | Change column width by −10% / +10% |
| `Mod+Shift+-` / `Mod+Shift+=` | Change window height by −10% / +10% |
| `Mod+V` / `Mod+Shift+V` | Toggle floating / switch focus between floating and tiling |
| `Mod+W` | Toggle tabbed column display |
| `Print` or `Super+Shift+S` | Interactive screenshot |
| `Ctrl+Print` / `Alt+Print` | Screenshot the screen / focused window |

Media keys `XF86AudioRaiseVolume` and `XF86AudioLowerVolume` change volume by 10%; mute and mic-mute keys toggle their respective channels. `XF86AudioPlay/Stop/Prev/Next` control MPRIS playback; `XF86MonBrightnessUp/Down` adjust backlight by 10%. These bindings are defined in the same Niri file.

## Other configured keys

| Context | Keys | Action |
| --- | --- | --- |
| Neovim normal or visual mode | `<leader>f` | Format buffer or selection asynchronously via Conform, falling back to LSP; defined in [`keymaps.lua`](../assets/config/nvim/lua/config/keymaps.lua). The repo does not set `mapleader`, so the effective leader follows Neovim's setting unless you override it. |
| QuickShell interactive panel | `Esc` | Close the open panel; defined in [`PopoverBase.qml`](../assets/config/quickshell/marko-shell/PopoverBase.qml). |
| Rime `marko-input` | `Shift+U` / `Shift+V` | Enter stroke/component/symbol mode / number/date/time/formula/code mode. Plain lowercase `u` and `v` remain Flypy input. |
| Rime U/V mode | `Esc` or `Ctrl+Backspace` | Cancel; `Backspace` edits and cancels when only the mode marker remains. |
| Rime U/V mode | `Space` / `Enter`; `Ctrl+Enter` | Commit selected candidate / commit raw input. |
| Rime U/V mode | `Up/Down`, `Page Up/Down` | Move selection or page. |
| Rime U mode | `1…7` | Select a candidate on the current page; in V mode, unmodified digits are expression input. |
| Rime U/V mode | `Ctrl+1…7` | Select a candidate on the current page. |

Rime details and examples are in [Rime U/V modes](rime-uv.md). No Fcitx global input-method toggle is set here; that shortcut depends on the user's Fcitx profile.
