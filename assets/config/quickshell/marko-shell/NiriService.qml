pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Niri workspace state via the event stream; updates in real time, no polling.
Item {
    id: root
    property var workspaces: []
    property bool available: false

    function handleLine(line) {
        var ev = null
        try { ev = JSON.parse(line) } catch (e) { return }
        if (!ev) return

        if (ev.WorkspacesChanged && Array.isArray(ev.WorkspacesChanged.workspaces)) {
            workspaces = ev.WorkspacesChanged.workspaces.map(function(w) {
                return {
                    id: w.id, idx: w.idx, name: w.name, output: w.output,
                    active: w.is_active, focused: w.is_focused, urgent: w.is_urgent
                }
            })
            available = true
        } else if (available && ev.WorkspaceActivated) {
            applyActivated(ev.WorkspaceActivated.id, ev.WorkspaceActivated.focused)
        } else if (available && ev.WorkspaceUrgencyChanged) {
            applyUrgency(ev.WorkspaceUrgencyChanged.id, ev.WorkspaceUrgencyChanged.urgent)
        }
    }

    function applyActivated(id, focused) {
        var output = null
        var found = false
        for (var i = 0; i < workspaces.length; i++) {
            if (workspaces[i].id === id) { output = workspaces[i].output; found = true; break }
        }
        if (!found) return
        var out = []
        for (var j = 0; j < workspaces.length; j++) {
            var w = workspaces[j]
            var active = w.active, f = w.focused
            if (w.id === id) { active = true; if (focused) f = true }
            else {
                if (w.output === output) active = false
                if (focused) f = false
            }
            out.push({
                id: w.id, idx: w.idx, name: w.name, output: w.output,
                active: active, focused: f, urgent: w.urgent
            })
        }
        workspaces = out
    }

    function applyUrgency(id, urgent) {
        var out = []
        for (var j = 0; j < workspaces.length; j++) {
            var w = workspaces[j]
            out.push({
                id: w.id, idx: w.idx, name: w.name, output: w.output,
                active: w.active, focused: w.focused,
                urgent: (w.id === id ? urgent : w.urgent)
            })
        }
        workspaces = out
    }

    function markDisconnected() {
        available = false
        workspaces = []
    }

    function focusWorkspace(id) {
        if (!available || !workspaces.some(function(w) { return w.id === id })) return
        var socketPath = Quickshell.env("NIRI_SOCKET")
        if (!socketPath) {
            console.warn("Cannot focus workspace: NIRI_SOCKET is not set")
            return
        }
        // niri 26.04 has the JSON IPC action, but not the raw-request CLI command.
        // Use the stable workspace ID, which remains unambiguous across outputs.
        var socket = focusSocketComponent.createObject(root, {
            path: socketPath,
            request: JSON.stringify({Action: {FocusWorkspace: {reference: {Id: id}}}})
        })
        if (socket) socket.connected = true
    }

    Component {
        id: focusSocketComponent
        Socket {
            id: requestSocket
            required property string request

            onConnectionStateChanged: {
                if (connected) {
                    write(request + "\n")
                    flush()
                }
            }
            parser: SplitParser {
                onRead: function(data) {
                    try {
                        var reply = JSON.parse(data)
                        if (reply.Err) console.warn("Niri focus failed:", reply.Err)
                    } catch (error) {
                        console.warn("Invalid reply from niri:", error)
                    }
                    requestSocket.connected = false
                    requestSocket.destroy()
                }
            }
            onError: function(error) {
                console.warn("Niri focus socket error:", error)
                requestSocket.destroy()
            }
            property Timer timeout: Timer {
                interval: 5000
                running: true
                onTriggered: {
                    console.warn("Niri focus request timed out")
                    requestSocket.destroy()
                }
            }
        }
    }

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: function(data) { handleLine(data) }
        }
        onRunningChanged: {
            if (!running) {
                root.markDisconnected()
                restart.start()
            }
        }
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: { stream.running = true }
    }
}
