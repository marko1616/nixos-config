import QtQuick
import Quickshell.Services.Pam

QtObject {
    id: root
    // Only this controller writes the lock request. UI views have no unlock API.
    property bool requested: false
    property bool secure: false
    property bool authenticated: false
    property string phase: "idle"
    // 0..1: zoom out, 1..2: scroll, 2..3: zoom in.
    property real reveal: 0
    readonly property int entryDuration: 780
    readonly property int exitDuration: 690
    property string status: ""
    property bool statusError: false
    property bool waiting: false
    property bool blocked: false
    readonly property bool canRespond: secure && !authenticated && !waiting
        && pam.active && pam.responseRequired && !blocked
    readonly property bool responseVisible: pam.responseVisible
    readonly property bool canRetry: secure && !authenticated && !pam.active && !blocked
    signal clearInput()
    signal focusInput()

    function engage() {
        if (secure && authenticated && phase === "closing") {
            // A new lock request during the exit must cancel that pending release.
            transition.stop();
            authenticated = false;
            phase = "ready";
            reveal = 3;
            beginAuthentication();
            return;
        }
        if (requested || secure) return;
        transition.stop();
        retry.stop();
        pam.abort();
        authenticated = false;
        blocked = false;
        waiting = false;
        reveal = 0;
        status = "Locking…";
        statusError = false;
        phase = "locking";
        clearInput();
        requested = true;
    }

    function secured() {
        if (!requested || secure) return;
        secure = true;
        phase = "opening";
        transition.from = 0;
        transition.to = 3;
        transition.duration = entryDuration;
        transition.start();
        beginAuthentication();
    }

    function beginAuthentication() {
        if (!secure || authenticated || pam.active || blocked) return;
        retry.stop();
        clearInput();
        waiting = true;
        status = "Waiting for authentication…";
        statusError = false;
        if (!pam.start()) {
            waiting = false;
            status = "Authentication unavailable. Retry, or recover from a TTY.";
            statusError = true;
        }
    }

    function respond(value) {
        if (!canRespond) return;
        waiting = true;
        status = "Verifying…";
        statusError = false;
        // The value is sent only to PAM, never via a process, IPC or a log.
        pam.respond(value);
        clearInput();
    }

    function acceptAuthentication() {
        if (!secure || !requested || authenticated) return;
        authenticated = true;
        waiting = false;
        retry.stop();
        clearInput();
        phase = "closing";
        transition.stop();
        transition.from = reveal;
        transition.to = 0;
        transition.duration = Math.max(100, exitDuration * reveal / 3);
        transition.start();
    }

    function finishTransition() {
        if (phase === "opening") {
            phase = "ready";
        } else if (phase === "closing" && authenticated && secure) {
            // The one and only normal release path: PAM success + animation end.
            phase = "unlocking";
            requested = false;
        }
    }

    function lockLost() {
        // Also handles compositor rejection/loss. It must not authenticate anyone.
        secure = false;
        transition.stop();
        retry.stop();
        pam.abort();
        clearInput();
        authenticated = false;
        waiting = false;
        requested = false;
        reveal = 0;
        phase = "idle";
    }

    property NumberAnimation transition: NumberAnimation {
        target: root
        property: "reveal"
        // LockView eases each of the three geometric stages separately.
        easing.type: Easing.Linear
        onFinished: root.finishTransition()
    }
    property Timer retry: Timer {
        interval: 1000
        onTriggered: root.beginAuthentication()
    }
    property PamContext pam: PamContext {
        config: "marko-lock"
        // Unset user means the current process user, not a QML/IPC-supplied name.
        onPamMessage: {
            if (!root.secure || root.authenticated) return;
            root.status = message;
            root.statusError = messageIsError;
            root.waiting = !responseRequired;
            root.clearInput();
            if (responseRequired) root.focusInput();
        }
        onCompleted: result => {
            if (!root.secure || root.authenticated) return;
            root.waiting = false;
            root.clearInput();
            if (result === PamResult.Success) {
                root.acceptAuthentication();
            } else {
                root.statusError = true;
                if (result === PamResult.Failed) {
                    root.status = "Authentication failed. Try again.";
                    retry.restart();
                } else if (result === PamResult.MaxTries) {
                    root.blocked = true;
                    root.status = "Authentication attempt limit reached. Recover from a TTY.";
                } else {
                    root.status = "Authentication unavailable. Retry, or recover from a TTY.";
                }
            }
        }
    }
}
