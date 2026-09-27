import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "WifiData.js" as WifiData

// Wi-Fi management popover, anchored below the network pill.
PopoverBase {
    id: root
    popHeight: 420
    property string errorText: ""
    property var accessPointsByDevice: Object.create(null)
    property int apGeneration: 0
    property int apOperationGeneration: 0
    property bool apBusy: false
    property bool apRefreshQueued: false
    property var apDevices: []
    property int apDeviceIndex: 0
    property var apPending: Object.create(null)
    property string apDevice: ""
    property string promptKey: ""

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

    function requestConnect(network) {
        if (WifiConnection.busy || network.stateChanging) return
        errorText = ""
        if (!network.known && acceptsPsk(network)) {
            promptKey = WifiData.networkKey(network)
            return
        }
        promptKey = ""
        WifiConnection.connectNetwork(network)
    }

    function submitPassword(network, password) {
        if (WifiConnection.busy || network.stateChanging || !WifiData.validPassword(password)) return
        errorText = ""
        WifiConnection.connectNetwork(network, password)
        promptKey = ""
    }

    Connections {
        target: WifiConnection
        function onFinished(key, success, message, needsPassword) {
            root.requestApInfo(true)
            if (!root.visible) return
            root.errorText = message
            if (!needsPassword || !Networking.wifiEnabled) return
            var devices = Networking.devices.values
            for (var i = 0; i < devices.length; i++) {
                if (devices[i].type !== DeviceType.Wifi) continue
                var networks = devices[i].networks.values
                for (var j = 0; j < networks.length; j++) {
                    var network = networks[j]
                    if (WifiData.networkKey(network) !== key || network.connected) continue
                    if (root.acceptsPsk(network)) root.promptKey = key
                    else root.errorText = "Configure this authentication method in Advanced settings."
                }
            }
        }
    }

    function requestApInfo(invalidate) {
        if (invalidate) {
            apGeneration++
            accessPointsByDevice = Object.create(null)
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
            accessPointsByDevice = apPending
            apBusy = false
            Qt.callLater(pumpApInfo)
            return
        }
        apDevice = apDevices[apDeviceIndex]
        // QuickShell owns scanning; read NetworkManager's current cache only.
        apInfo.command = ["nmcli", "--terse", "--escape", "no", "--colors", "no",
                          "--fields", "IN-USE,SSID-HEX,BSSID,SIGNAL",
                          "device", "wifi", "list", "ifname", apDevice, "--rescan", "no"]
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
        if (success) apPending[apDevice] = WifiData.parseAccessPoints(output)
        apDeviceIndex++
        Qt.callLater(startNextApInfo)
    }

    Connections {
        target: root
        function onVisibleChanged() {
            root.requestApInfo(true)
            if (!root.visible) {
                root.promptKey = ""
                root.errorText = ""
            }
        }
    }
    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            root.requestApInfo(true)
            if (!Networking.wifiEnabled) root.promptKey = ""
        }
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
            root.accessPointsByDevice = Object.create(null)
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
            id: networkList
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
                required property int index
                readonly property string networkKey: WifiData.networkKey(modelData)
                readonly property bool showPsk: root.promptKey === networkKey
                readonly property bool connecting: WifiConnection.busy && WifiConnection.targetKey === networkKey

                onShowPskChanged: {
                    if (!showPsk) {
                        pskField.clear()
                        pskField.focus = false
                    } else {
                        Qt.callLater(function() {
                            if (!networkRow.showPsk || !root.visible) return
                            networkList.positionViewAtIndex(networkRow.index, ListView.Contain)
                            pskField.forceActiveFocus(Qt.OtherFocusReason)
                        })
                    }
                }

                width: ListView.view.width
                height: col.implicitHeight + 16
                radius: Theme.radius - 2
                color: modelData.connected ? Theme.moduleBg : "transparent"

                Connections {
                    target: networkRow.modelData
                    function onConnectedChanged() {
                        root.requestApInfo(true)
                        if (networkRow.modelData.connected && networkRow.showPsk) root.promptKey = ""
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
                                text: WifiData.apLabel(modelData, root.accessPointsByDevice)
                                color: Theme.border
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                                elide: Text.ElideRight
                            }
                        }
                        TextButton {
                            objectName: "connect-" + networkRow.index
                            visible: !modelData.connected && !networkRow.showPsk
                            enabled: Networking.wifiEnabled && !WifiConnection.busy && !modelData.stateChanging
                            text: networkRow.connecting || modelData.stateChanging ? "Connecting…" : "Connect"
                            onClicked: root.requestConnect(modelData)
                        }
                        TextButton {
                            visible: modelData.connected
                            enabled: !WifiConnection.busy && !modelData.stateChanging
                            text: "Disconnect"
                            onClicked: modelData.disconnect()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: showPsk
                        spacing: 8
                        PasswordField {
                            id: pskField
                            objectName: "password-" + networkRow.index
                            Layout.fillWidth: true
                            enabled: !WifiConnection.busy && !modelData.stateChanging
                            onAccepted: root.submitPassword(modelData, text)
                        }
                        TextButton {
                            objectName: "submit-" + networkRow.index
                            text: "Connect"
                            enabled: !WifiConnection.busy && !modelData.stateChanging
                                     && WifiData.validPassword(pskField.text)
                            onClicked: root.submitPassword(modelData, pskField.text)
                        }
                        TextButton {
                            text: "Cancel"
                            onClicked: {
                                root.promptKey = ""
                                root.errorText = ""
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
