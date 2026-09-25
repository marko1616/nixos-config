pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Default sink volume / mute, driven by wpctl to match the existing niri keybinds.
Item {
    property int volume: 0
    property bool muted: false
    property int pendingVolume: 0

    function parseVolume(line) {
        var m = line.match(/Volume:\s*([0-9.]+)/)
        if (m) volume = Math.round(parseFloat(m[1]) * 100)
        muted = /MUTED/.test(line)
    }

    function refresh() {
        query.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    }

    function toggleMute() {
        mute.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        settle.restart()
    }

    function stepUp() {
        vol.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+", "-l", "1.0"])
        settle.restart()
    }

    function stepDown() {
        vol.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
        settle.restart()
    }

    function setVolume(value) {
        pendingVolume = Math.max(0, Math.min(100, Math.round(value)))
        volume = pendingVolume
        volumeDebounce.restart()
    }

    Process {
        id: query
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: function(data) { parseVolume(data) }
        }
    }
    Process { id: vol; command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@"] }
    Process { id: mute; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }

    Timer { id: settle; interval: 250; onTriggered: refresh() }
    Timer {
        id: volumeDebounce
        interval: 40
        onTriggered: {
            vol.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pendingVolume + "%", "-l", "1.0"])
            settle.restart()
        }
    }
    Timer { id: poll; interval: 3000; repeat: true; running: true; onTriggered: refresh() }

    Component.onCompleted: refresh()
}
