# Rime U/V modes (Flypy, Fcitx5)

English | [中文](rime-uv_zh.md)

`programs.markoInput.enable` provides Fcitx5 + Rime with Flypy double pinyin by default. `Shift+U` enters U mode and `Shift+V` enters V mode. See also the [shortcut summary](shortcuts.md).

## Input behavior

| Input | Result |
| --- | --- |
| Normal | Flypy double pinyin; lowercase `u` and `v` still work as ordinary Flypy keys |
| `Shift+U` + `hspnz` | Stroke lookup (horizontal, vertical, left-falling, right-falling, turning); for example `Uhspn` → 木 |
| `Shift+U` + double-pinyin component code | Component lookup; for example `Umumu` → 林 |
| `Shift+U` + `udw` / `uxh` / `uts` / `ubd` / `usx` / `ujh` / `uzm` | Units / sequence symbols / special symbols / punctuation / mathematics / geometry / letters |
| `Shift+V` | Numbers, dates, times and formulas; `UC` + Unicode code point, `GB` + GB18030 code |
| `Esc` | Leave the mode without changing the selected schema |

Within U/V mode, `Space` or `Enter` commits the selected candidate, `Ctrl+Enter` commits the raw input, and `Esc` cancels. Candidate selection by `1…7` applies to **U mode**; in V mode digits are part of the expression. The complete active-key summary is in [shortcuts](shortcuts.md).

## Implementation map

- `desktop/rime.nix` — module and enable switch. Its input-method group is an initial default, not a replacement for an existing user profile. System activation does not delete or rewrite a user's Rime directory; redeploy from the Fcitx5 Rime menu to update compiled data.
- `desktop/rime-data.nix` — assembles the pinned `assets/rime-ice` Git submodule, revision-pinned rime-stroke data, and `assets/rime/`. Schemas are compiled and required artifacts checked during the build.
- `assets/rime/marko-input.schema.yaml` — patches the Flypy schema with the U/V processing chain.
- `assets/rime/marko-input-radical.schema.yaml` and `marko-input-stroke.schema.yaml` — separate prisms that do not rewrite other installed schemas.
- `assets/rime/lua/marko_uv_*.lua` — processor, segmentor, translator and filter entry points; `lua/marko_uv/` contains V-mode and symbol helpers.
- `scripts/build_rime_uv_data.py` — generates `symbols.lua` and `gb_data.lua` from pinned upstream files during the build. Runtime use does not fetch network data.

## Known constraints

- `lua_translator` receives a **const** `Segment` (`LuaType<rime::Segment const&>`). Assigning to `seg` causes a binding error and aborts translation, so the translator does not write to it. Mode prompts are disabled: setting `seg.prompt` only in a mutable segment filter inserts the prompt into preedit.
- Stroke and component lookups share the `uv` tag. Exact matches come first; remaining candidates are merged in rotation.
- The GB18030 table uses a pinned WHATWG Encoding revision and is not byte-for-byte derived from Microsoft's implementation.

## First use and updates

After building and switching through the `./cli.py` menu, log out and back in so Fcitx5 loads the new plugin and shared data. An existing personal Fcitx5 profile takes precedence over the system's default input-method group: add Rime to that group in Fcitx5 Configuration and select the `marko-input` schema. Then choose **Deploy** from Fcitx5's Rime menu to refresh the compiled cache in the current user's actual data directory, including a non-default `XDG_DATA_HOME`.

Repeat Deploy in a new session after each data-package update. A system switch neither restarts a running Fcitx5 process nor clears any user's `build/`, learning dictionary, or `sync/`.

## Validation and rollback

The implementation notes report 86 engine-level assertions against real librime, covering stroke/component lookups, seven symbol groups, paging and numeric selection, V-mode forms, invalid input, Escape, caret editing, keypad, ASCII pass-through and ordinary Flypy. `rime_deployer --build` is the build gate.

To return to the earlier configuration, set `programs.markoInput.enable = false;` and remove the `desktop/rime.nix` import.
