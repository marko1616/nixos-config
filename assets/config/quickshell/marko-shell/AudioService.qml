pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

// Native PipeWire notifications replace polling. wpctl supplies an exit status
// and an ordered readback: PwNodeAudio setters expose no server-write completion.
Item {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.ready && sink.audio !== null
    property int volume: 0
    property bool muted: false
    property string errorText: ""

    // Only the latest unsent absolute value is retained. A single Process owns
    // all reads/writes; exec() is never called while another command is active.
    property int revision: 0
    property int queuedVolume: -1
    property int queuedMute: -1
    property bool queryNeeded: false
    property string operation: ""
    property int operationRevision: 0
    property var operationSink: null

    PwObjectTracker { objects: [root.sink] }
    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumesChanged() { root.refresh() }
        function onMutedChanged() { root.refresh() }
    }

    onSinkChanged: resetEndpoint()
    onAvailableChanged: resetEndpoint()

    function resetEndpoint() {
        // Never carry an old output's pending commands to a newly selected sink.
        revision++
        queuedVolume = -1
        queuedMute = -1
        volume = 0
        muted = false
        errorText = ""
        queryNeeded = available
        Qt.callLater(pump)
    }

    function refresh() {
        if (!available) return
        queryNeeded = true
        Qt.callLater(pump)
    }

    function toggleMute() {
        if (!available) return
        revision++
        muted = !muted
        queuedMute = muted ? 1 : 0
        errorText = ""
        queryNeeded = true
        Qt.callLater(pump)
    }

    function stepUp() { setVolume(volume + 1) }
    function stepDown() { setVolume(volume - 1) }

    function setVolume(value) {
        if (!available || !isFinite(value)) return
        revision++
        volume = Math.max(0, Math.min(100, Math.round(value)))
        queuedVolume = volume
        errorText = ""
        queryNeeded = true
        Qt.callLater(pump)
    }

    function pump() {
        if (!available || operation !== "" || worker.running) return
        var command
        var endpoint = String(sink.id)
        if (queuedVolume >= 0) {
            operation = "volume"
            command = ["wpctl", "set-volume", endpoint, queuedVolume + "%", "-l", "1.0"]
            queuedVolume = -1
        } else if (queuedMute >= 0) {
            operation = "mute"
            command = ["wpctl", "set-mute", endpoint, String(queuedMute)]
            queuedMute = -1
        } else if (queryNeeded) {
            operation = "query"
            queryNeeded = false
            command = ["wpctl", "get-volume", endpoint]
        } else {
            return
        }
        operationRevision = revision
        operationSink = sink
        watchdog.restart()
        worker.exec(command)
    }

    function finish(success, output) {
        if (operation === "") return
        watchdog.stop()
        var current = operationRevision === revision && operationSink === sink
        if (current) {
            if (!success) {
                errorText = "Audio command failed; check the output device and wpctl."
                // Recover from failed writes with a read, but never retry a failed
                // read indefinitely. New input/native notifications can retry.
                if (operation !== "query") queryNeeded = true
            } else if (operation === "query") {
                var match = output.match(/Volume:\s*([0-9.]+)/)
                var actual = match ? Number(match[1]) : NaN
                if (isFinite(actual)) {
                    volume = Math.round(actual * 100)
                    muted = /MUTED/.test(output)
                } else {
                    errorText = "Cannot read the output volume."
                }
            }
        }
        operation = ""
        operationSink = null
        Qt.callLater(pump)
    }

    Process {
        id: worker
        stdout: StdioCollector { id: output }
        onExited: function(exitCode, exitStatus) {
            root.finish(exitCode === 0 && exitStatus === 0, output.text)
        }
        // FailedToStart emits runningChanged but no exited in QuickShell 0.3.0.
        onRunningChanged: {
            if (!running && root.operation !== "") root.finish(false, "")
        }
    }
    Timer {
        id: watchdog
        interval: 5000
        onTriggered: {
            // Kill first; wait for exited before admitting the next operation.
            // A hung read must not block adjustments forever.
            if (worker.running) worker.signal(9)
            else root.finish(false, "")
        }
    }
}
