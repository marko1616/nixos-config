# Animated lockscreen

English | [中文](lockscreen_zh.md)

## Operation and failure behavior

`Super+Alt+L` runs `marko-lock`. Enter the current user's password and press Enter. Escape clears the field; it never unlocks. This is the sole configured locker. There is no second lock implementation or takeover hotkey.

The launcher serializes concurrent requests with flock. It starts an independent QuickShell 0.3.2 instance on first use; the instance remains resident after unlocking, without video surfaces. Cold startup allows up to 15 seconds for the daemon to load QML, then up to five seconds for its IPC readiness response. Startup failure reports the daemon's exit status and recent QuickShell logs. Once ready, it captures the pre-lock desktop per output with `grim`, then calls `lock.engage` and checks the compositor's `secure` acknowledgement. Captures live in the user's private `XDG_RUNTIME_DIR/marko-lock-capture` and are removed after unlocking; a later launch also clears stale files. A failed capture falls back to an opaque theme color without preventing a secure lock. If acknowledgement does not arrive within three seconds, the command prints an error and exits nonzero. It does not claim that the session is locked. **Do not leave the machine assuming that a failed lock command succeeded.** If Niri had already locked it, Niri keeps its locked background on locker failure.

If the locker dies and Niri shows its locked background, press `Super+Alt+L` again: this binding is allowed while locked, and the launcher can start a new instance. This follows [Niri's recovery guidance](https://github.com/niri-wm/niri/wiki/FAQ#how-do-i-recover-from-a-dead-screen-locker--from-a-red-screen). A still-running but unresponsive instance or a compositor failure may require recovery from a TTY; the hotkey is not a guarantee. Keep a working TTY login before deploying this change. Do not force-unlock to work around an authentication error.

New public files must be in the Git index for the Git-backed flake. Use the interactive `./cli.py` menu: `build-dev`, then `switch-dev`; log out and back in to use the new daemon code. The lock command itself needs no sudo. No new private file is required, but **remove the obsolete `colors.swaylock` object** from existing `private-config/theme/settings.json` before evaluating this revision; the companion private patch covers the previously delivered color object.

## Colors

Lockscreen colors have their **own semantic roles** in `theme/colors.nix` under `lockscreen`. Set private overrides in `private-config/theme/settings.json` under `colors.lockscreen`, for example `"colors": {"lockscreen": {"cardBackground": "#28363B", "inputSelection": "#ACD4E8"}}`. Unspecified lockscreen roles use the public defaults; changing a `colors.quickshell` bar role no longer changes the lockscreen. `theme/default.nix` generates `LockColors.qml`, which Home Manager installs into the locker's QML configuration. Do not edit the generated QML in the Nix store. `Theme.qml` is still shared only for motion, font and geometry tokens. The video/image background uses the configured wallpaper; `surfaceBackground` is the opaque fallback color.

## Components and boundaries

The lock surface is an opaque `WlSessionLockSurface` on every output. The entry animation and PAM begin only after compositor-confirmed `secure`. One shared `PamContext` uses `/etc/pam.d/marko-lock` and the current process user. Passwords never enter CLI arguments or IPC. Only `PamResult.Success` begins the exit animation; the session lock is released only when it finishes. Another lock request during exit cancels release and requires authentication again. Media errors, Escape, and ordinary authentication failures never unlock. Repeated Enter does not send duplicate responses.

The lock uses the existing private wallpaper and QuickShell theme; no extra private settings are introduced. The security surface remains fullscreen and opaque. The entry now has three distinct Overview-like stages over 780 ms: the frozen desktop zooms from 100% to 70%; the two 70%-scale tiles scroll horizontally, separated by a 32-pixel gap; then the lock scene zooms from 70% to 100%. Each stage eases independently. PAM success reverses all three stages over 690 ms, reusing the **entry** snapshot. Only after the reverse animation does the compositor release the lock and cut directly to the live Niri desktop. A real desktop cannot be exposed behind the lock surface while locked, so the last handoff is not guaranteed seamless. Per-output screenshots are sequential, not atomic, and not guaranteed to be the exact last pre-lock frame. If capture fails, the launcher warns on stderr and the opaque fallback remains; it cannot show a real desktop zoom-out on that output.

Qt Multimedia decodes the video separately from mpvpaper, so lock/unlock handoff can jump in phase. Each display has a player and may add decoding load. Media failure falls back to the static image or an opaque theme color without blocking authentication. The existing swayidle policy remains unchanged; this change adds no idle timeout or suspend hook.

## Target-machine acceptance

The offscreen suite uses the real QML view/controller but a **mock PAM adapter**; it cannot prove real authentication or Wayland security. It also decodes a synthetic 64×48, 20-frame MPEG-4 fixture, with no user media. Verify on the target:

| Test | Expected result |
| --- | --- |
| Correct/wrong password; repeated Enter | Only real PAM success unlocks; one response per prompt |
| Escape, outside click, initial focus | Lock stays active; focus/input follows UI behavior |
| Lock request during exit | Exit cancels and authentication restarts |
| PAM unavailable or attempt limit | Lock stays active; use UI retry when offered, otherwise TTY recovery |
| Missing media or unsupported codec | Opaque background; authentication UI usable |
| Capture failure or changed output name | Opaque theme fallback; authentication and secure lock still work |
| Entry, exit, unlock boundary | 780 ms zoom-out → scroll → zoom-in; 690 ms reverse, then a cut to the live desktop |
| Multiple outputs, hotplug, scaling | Every output covered; input usable after changing focus |
| DPMS and suspend/resume while locked | No desktop exposure; authentication still works |
| QuickShell startup/secure-ack failure | Command exits nonzero; it does not report a successful lock |
| Locker dies after locking | Niri retains locked background; same hotkey starts a fresh instance |

References: [session-lock protocol](https://wayland.app/protocols/ext-session-lock-v1), [QuickShell lock API](https://quickshell.org/docs/v0.3.2/types/Quickshell.Wayland/WlSessionLock/), [PAM API](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Pam/PamContext/), [Niri IPC](https://github.com/niri-wm/niri/wiki/IPC), [Niri recovery](https://github.com/niri-wm/niri/wiki/FAQ#how-do-i-recover-from-a-dead-screen-locker--from-a-red-screen).
