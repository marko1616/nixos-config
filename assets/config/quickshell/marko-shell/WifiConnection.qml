pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "WifiData.js" as WifiData

// One activation across all bars/screens. Closing a popup does not unregister
// its secret agent halfway through an activation.
Scope {
    id: root
    property bool busy: false
    property string targetKey: ""
    property string payload: ""
    signal finished(string key, bool success, string message, bool needsPassword)

    function keyMgmt(network) {
        if (network.security === WifiSecurityType.Sae) return "sae"
        if (network.security === WifiSecurityType.WpaPsk
                || network.security === WifiSecurityType.Wpa2Psk) return "wpa-psk"
        if (network.security === WifiSecurityType.Open) return "open"
        if (network.security === WifiSecurityType.Owe) return "owe"
        return null
    }

    function connectNetwork(network, password) {
        if (busy || network.connected || network.stateChanging) return
        var key = WifiData.networkKey(network)
        var request = {
            ssid: network.name,
            device: network.device ? network.device.name : "",
            profile: WifiData.profileUuid(network),
            keyMgmt: keyMgmt(network),
            psk: password === undefined ? null : password
        }
        targetKey = key
        payload = JSON.stringify(request)
        busy = true
        connector.stdinEnabled = true
        watchdog.restart()
        connector.running = true
    }

    function complete(code, output) {
        if (!busy) return
        watchdog.stop()
        killWatchdog.stop()
        payload = ""
        var result = { ok: false, reason: "unavailable" }
        try {
            if (code === 0) result = JSON.parse(output)
        } catch (error) {}
        var messages = {
            secrets: "Password required or rejected. Please try again.",
            advanced: "Configure this authentication method in Advanced settings.",
            "not-found": "This network is no longer in range. Wait for a new scan and try again.",
            permission: "NetworkManager did not authorize this connection.",
            timeout: "Connection timed out. Check the password and signal, then try again.",
            cancelled: "Connection cancelled.",
            "profile-changed": "The saved network changed. Reopen the Wi-Fi panel and try again.",
            "invalid-request": "Invalid Wi-Fi settings or password.",
            failed: "Connection failed. Check the password and signal, then try again.",
            unavailable: "Wi-Fi helper unavailable. Rebuild the configuration and restart the shell."
        }
        var key = targetKey
        targetKey = ""
        busy = false
        var message = result.ok ? (result.warning ? "Connected, but automatic reconnection could not be enabled." : "")
                                : (messages[result.reason] || messages.failed)
        finished(key, result.ok === true, message,
                 !result.ok && (result.reason === "secrets" || result.reason === "failed"
                                || result.reason === "timeout" || result.reason === "invalid-request"))
    }

    Process {
        id: connector
        command: ["marko-wifi-connect"]
        stdout: StdioCollector { id: resultOutput }
        stderr: StdioCollector {}
        onStarted: {
            connector.write(root.payload)
            root.payload = ""
            connector.stdinEnabled = false
        }
        onExited: function(code, status) { root.complete(status === 0 ? code : -1, resultOutput.text) }
        onRunningChanged: {
            if (!running) Qt.callLater(function() {
                if (root.busy && !connector.running) root.complete(-1, "")
            })
        }
    }
    Timer {
        id: watchdog
        interval: 65000
        onTriggered: {
            // SIGTERM lets the helper deactivate its own attempt before exiting.
            connector.running = false
            killWatchdog.restart()
        }
    }
    Timer {
        id: killWatchdog
        interval: 15000
        onTriggered: if (connector.running) connector.signal(9)
    }
}
