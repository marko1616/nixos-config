//@ pragma ShellId marko-lock
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    // Reloading a lock state machine is not a supported configuration update.
    // Log out/in after rebuilding; never hot-reload while holding a lock.
    settings.watchFiles: false

    LockController { id: lockState }

    Process {
        id: cleanCapture
        command: [Quickshell.env("MARKO_LOCK_CLEANUP_BIN"), "-rf", "--",
                  Quickshell.env("MARKO_LOCK_CAPTURE_DIR")]
    }

    IpcHandler {
        target: "lock"
        function engage(): void { lockState.engage(); }
        function isSecure(): bool { return sessionLock.secure; }
        function isReady(): bool {
            return !sessionLock.secure && !lockState.requested && !cleanCapture.running;
        }
        // Deliberately no unlock IPC, writable lock property, or password IPC.
    }

    WlSessionLock {
        id: sessionLock
        locked: lockState.requested
        onSecureChanged: {
            if (secure) lockState.secured();
            else {
                lockState.lockLost();
                cleanCapture.running = true;
            }
        }
        surface: WlSessionLockSurface {
            id: lockSurface
            // Force an opaque background even if the user palette has alpha.
            color: Qt.rgba(LockColors.surfaceBackground.r, LockColors.surfaceBackground.g, LockColors.surfaceBackground.b, 1)
            LockView {
                anchors.fill: parent
                controller: lockState
                wallpaperPath: Quickshell.env("MARKO_LOCK_WALLPAPER")
                fallbackPath: Quickshell.env("MARKO_LOCK_FALLBACK")
                snapshotPath: lockState.requested && lockSurface.screen && lockSurface.screen.name
                    ? Quickshell.env("MARKO_LOCK_CAPTURE_DIR") + "/"
                      + lockSurface.screen.name + ".png"
                    : ""
            }
        }
    }
}
