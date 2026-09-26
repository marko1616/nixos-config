import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi management popover, anchored below the network pill.
PopoverBase {
    id: root
    popHeight: 420
    property string errorText: ""
    property var connectedApByDevice: Object.create(null)
    property int apGeneration: 0
    property int apOperationGeneration: 0
    property bool apBusy: false
    property bool apRefreshQueued: false
    property var apDevices: []
    property int apDeviceIndex: 0
    property var apPending: Object.create(null)
    property string apDevice: ""
    // The password field needs real keyboard input, which an ungrabbed popup does
    // not receive, so the popup takes the grab back while a prompt is visible.
    property bool pskActive: false
    needsKeyboard: pskActive

    onPskActiveChanged: {
        if (pskActive) remap()
    }

    // The network list alone does not enable active Wi-Fi scanning.
    // Only the visible popup owns these bindings; hiding it restores prior values.
    Variants {
        model: Networking.devices.values.filter(function(device) {
            return device.type === DeviceType.Wifi
        })
        delegate: Binding {
            required property var modelData
            target: modelData
            property: "scannerEnabled"
            value: true
            when: root.visible && Networking.wifiEnabled
        }
    }

    function acceptsPsk(network) {
        return network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae
    }

    function decodeIwSsid(value) {
        var encoded = ""
        for (var i = 0; i < value.length; i++) {
            var code = value.charCodeAt(i)
            if (value[i] === "\\") {
                if (i + 3 >= value.length || value[i + 1] !== "x"
                        || !/^[0-9a-fA-F]{2}$/.test(value.slice(i + 2, i + 4))) return null
                encoded += "%" + value.slice(i + 2, i + 4)
                i += 3
            } else {
                if (code > 0x7f) return null
                var hex = code.toString(16)
                encoded += "%" + (hex.length === 1 ? "0" : "") + hex
            }
        }
        try {
            return decodeURIComponent(encoded)
        } catch (error) {
            return null
        }
    }

    function parseLinkSnapshot(device, output) {
        var bssid = ""
        var ssid = ""
        var disconnected = false
        var lines = output.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].replace(/\r$/, "")
            if (!line) continue
            if (/^\s*Not connected\.$/.test(line)) {
                disconnected = true
                continue
            }
            var connected = line.match(/^\s*Connected to ((?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}) \(on ([^)]+)\)$/)
            if (connected) {
                if (connected[2] !== device || bssid) return null
                bssid = connected[1]
                continue
            }
            var ssidLine = line.match(/^\s*SSID: (.*)$/)
            if (ssidLine) {
                if (ssid) return null
                ssid = decodeIwSsid(ssidLine[1])
                if (ssid === null) return null
            }
        }
        if (disconnected) return bssid || ssid ? null : ({ connected: false })
        if (!bssid || !ssid) return null
        return { connected: true, bssid: bssid, ssid: ssid }
    }

    function apLabel(network) {
        if (!network.connected) return ""
        var device = network.device ? network.device.name : ""
        var entry = connectedApByDevice[device]
        var bssid = entry && entry.ssid === network.name ? entry.bssid : ""
        return "BSSID · " + (bssid || "Unavailable")
    }

    function requestApInfo(invalidate) {
        if (invalidate) {
            apGeneration++
            connectedApByDevice = Object.create(null)
        }
        apRefreshQueued = root.visible && Networking.wifiEnabled
        Qt.callLater(pumpApInfo)
    }

    function pumpApInfo() {
        if (apBusy || apInfo.running || !apRefreshQueued) return
        if (!root.visible || !Networking.wifiEnabled) { apRefreshQueued = false; return }
        apRefreshQueued = false
        apOperationGeneration = apGeneration
        apDevices = Networking.devices.values.filter(function(device) {
            return device.type === DeviceType.Wifi && device.name
        }).map(function(device) { return device.name })
        apDeviceIndex = 0
        apPending = Object.create(null)
        apBusy = true
        startNextApInfo()
    }

    function startNextApInfo() {
        if (!apBusy) return
        if (apOperationGeneration !== apGeneration || !root.visible || !Networking.wifiEnabled) {
            apBusy = false
            Qt.callLater(pumpApInfo)
            return
        }
        if (apDeviceIndex >= apDevices.length) {
            connectedApByDevice = apPending
            apBusy = false
            Qt.callLater(pumpApInfo)
            return
        }
        apDevice = apDevices[apDeviceIndex]
        apInfo.command = ["iw", "dev", apDevice, "link"]
        apWatchdog.restart()
        apInfo.running = true
    }

    function finishApInfo(success, output) {
        if (!apBusy) return
        apWatchdog.stop()
        apKillWatchdog.stop()
        if (apOperationGeneration !== apGeneration || !root.visible || !Networking.wifiEnabled) {
            apBusy = false
            Qt.callLater(pumpApInfo)
            return
        }
        var snapshot = success ? parseLinkSnapshot(apDevice, output) : null
        if (snapshot && snapshot.connected) {
            apPending[apDevice] = { ssid: snapshot.ssid, bssid: snapshot.bssid }
        }
        apDeviceIndex++
        Qt.callLater(startNextApInfo)
    }

    Connections {
        target: root
        function onVisibleChanged() { root.requestApInfo(true) }
    }
    Connections {
        target: Networking
        function onWifiEnabledChanged() { root.requestApInfo(true) }
    }

    Process {
        id: apInfo
        command: []
        environment: ({ "LC_ALL": "C" })
        stdout: StdioCollector { id: apOutput }
        onExited: function(code, status) { root.finishApInfo(code === 0 && status === 0, apOutput.text) }
        onRunningChanged: {
            if (!running) Qt.callLater(function() {
                if (root.apBusy && !apInfo.running) root.finishApInfo(false, "")
            })
        }
    }
    Timer {
        id: apWatchdog
        interval: 5000
        onTriggered: {
            root.apGeneration++
            root.connectedApByDevice = Object.create(null)
            root.apRefreshQueued = root.visible && Networking.wifiEnabled
            apInfo.running = false
            apKillWatchdog.restart()
        }
    }
    Timer {
        id: apKillWatchdog
        interval: 1000
        onTriggered: {
            if (apInfo.running) apInfo.signal(9)
        }
    }
    Timer {
        interval: 10000
        repeat: true
        running: root.visible && Networking.wifiEnabled
        onTriggered: root.requestApInfo(false)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Wi-Fi"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            ModernSwitch {
                id: wifiSwitch
                Accessible.name: "Wi-Fi"
                backendChecked: Networking.wifiEnabled
                enabled: Networking.wifiHardwareEnabled
                onToggleRequested: function(nextChecked) { Networking.wifiEnabled = nextChecked }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.errorText !== ""
            text: root.errorText
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            visible: Networking.connectivity === NetworkConnectivity.Portal
                     || Networking.connectivity === NetworkConnectivity.Limited
            text: Networking.connectivity === NetworkConnectivity.Portal
                  ? "Captive portal: sign-in required"
                  : "Limited connectivity"
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.Wrap
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: ScriptModel {
                values: {
                    var out = []
                    var ds = Networking.devices.values
                    for (var i = 0; i < ds.length; i++) {
                        var d = ds[i]
                        if (d.type !== DeviceType.Wifi) continue
                        var nets = d.networks.values
                        for (var j = 0; j < nets.length; j++) out.push(nets[j])
                    }
                    out.sort(function(a, b) {
                        if (a.connected !== b.connected) return b.connected - a.connected
                        if (a.known !== b.known) return b.known - a.known
                        return b.signalStrength - a.signalStrength
                    })
                    return out
                }
            }
            delegate: Rectangle {
                id: networkRow
                required property var modelData
                property bool showPsk: false

                width: ListView.view.width
                height: col.implicitHeight + 16
                radius: Theme.radius - 2
                color: modelData.connected ? Theme.moduleBg : "transparent"

                Connections {
                    target: networkRow.modelData
                    function onConnectedChanged() { root.requestApInfo(true) }
                    function onConnectionFailed(reason) {
                        networkRow.showPsk = reason === ConnectionFailReason.NoSecrets
                                             && root.acceptsPsk(networkRow.modelData)
                        root.errorText = networkRow.showPsk
                            ? "Password required or rejected. Please try again."
                            : (reason === ConnectionFailReason.NoSecrets
                                ? "Configure this authentication method in Advanced settings."
                                : "Connection failed: " + ConnectionFailReason.toString(reason))
                        root.pskActive = networkRow.showPsk
                    }
                }

                Connections {
                    target: root
                    function onVisibleChanged() {
                        if (!root.visible && !root.remapping) {
                            networkRow.showPsk = false
                            root.pskActive = false
                            pskField.clear()
                        }
                    }
                }

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: Theme.wifiIcon
                            color: Theme.cyan
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: (modelData.connected ? "Connected · "
                                      : (modelData.known ? "Saved · " : ""))
                                      + WifiSecurityType.toString(modelData.security)
                                      + " · Signal " + Math.round(modelData.signalStrength * 100) + "%"
                                color: Theme.border
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: modelData.connected
                                text: root.apLabel(modelData)
                                color: Theme.border
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                                elide: Text.ElideRight
                            }
                        }
                        TextButton {
                            visible: !modelData.connected
                            text: "Connect"
                            onClicked: {
                                root.errorText = ""
                                showPsk = false
                                root.pskActive = false
                                modelData.connect()
                            }
                        }
                        TextButton {
                            visible: modelData.connected
                            text: "Disconnect"
                            onClicked: modelData.disconnect()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: showPsk
                        spacing: 8
                        TextField {
                            id: pskField
                            Layout.fillWidth: true
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                        }
                        TextButton {
                            text: "Connect"
                            onClicked: {
                                root.errorText = ""
                                modelData.connectWithPsk(pskField.text)
                                pskField.clear()
                                showPsk = false
                                root.pskActive = false
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            TextButton {
                text: "Advanced settings"
                onClicked: {
                    Popover.closeAll()
                    Quickshell.execDetached(["nm-connection-editor"])
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

}
