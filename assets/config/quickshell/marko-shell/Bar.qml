import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray

// Top bar replacing Waybar. One instance per screen.
PanelWindow {
    id: bar
    required property var modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusiveZone: Theme.barHeight
    screen: modelData

    property var now: new Date()
    Timer { interval: 15000; repeat: true; running: true; onTriggered: bar.now = new Date() }

    property string networkLabel: {
        var ds = Networking.devices.values
        for (var i = 0; i < ds.length; i++) {
            var d = ds[i]
            if (d.type === DeviceType.Wifi) {
                var nets = d.networks.values
                for (var j = 0; j < nets.length; j++) if (nets[j].connected) return nets[j].name
            }
        }
        for (var k = 0; k < ds.length; k++) {
            var w = ds[k]
            if (w.type === DeviceType.Wired && w.connected) return w.name
        }
        return "Disconnected"
    }

    property string bluetoothLabel: {
        var a = Bluetooth.defaultAdapter
        if (!a || !a.enabled) return "Off"
        var devs = a.devices.values
        for (var i = 0; i < devs.length; i++) if (devs[i].connected) return devs[i].name
        return "On"
    }

    property var bat: UPower.displayDevice
    property real batPct: (bat && bat.isPresent) ? bat.percentage * 100 : 0
    property bool batCharging: bat && (bat.state === UPowerDeviceState.Charging
                                || bat.state === UPowerDeviceState.FullyCharged
                                || bat.state === UPowerDeviceState.PendingCharge)

    property var profile: PowerProfiles.profile

    // True while the pointer is somewhere over the bar. A popup is dismissed once
    // the pointer has left both the bar and the popup itself.
    readonly property bool pointerOnBar: barPointer.hovered
        || cpuPill.hovered || memPill.hovered || clockPill.hovered
        || networkPill.hovered || bluetoothPill.hovered || audioPill.hovered
        || batteryPill.hovered || powerPill.hovered

    onPointerOnBarChanged: Popover.setBarHover(bar.screen ? bar.screen.name : "", pointerOnBar)

    function batteryIcon(pct, charging) {
        if (charging) return Theme.batteryChargingIcon
        if (pct >= 90) return Theme.batteryIcons[4]
        if (pct >= 65) return Theme.batteryIcons[3]
        if (pct >= 40) return Theme.batteryIcons[2]
        if (pct >= 20) return Theme.batteryIcons[1]
        return Theme.batteryIcons[0]
    }
    function batteryColor(pct) {
        if (pct <= 20) return Theme.red
        if (pct <= 30) return Theme.yellow
        return Theme.green
    }
    function formatDuration(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "Estimating…"
        var minutes = Math.max(1, Math.round(seconds / 60))
        var hours = Math.floor(minutes / 60)
        var remainder = minutes % 60
        if (hours === 0) return minutes + " min"
        if (remainder === 0) return hours + " h"
        return hours + " h " + remainder + " min"
    }
    function batteryEstimateText() {
        if (!bat || !bat.isPresent) return ""
        if (bat.state === UPowerDeviceState.FullyCharged) return "Fully charged"
        if (batCharging) {
            return bat.timeToFull > 0 ? "Full in " + formatDuration(bat.timeToFull)
                                      : "Estimating time to full…"
        }
        return bat.timeToEmpty > 0 ? formatDuration(bat.timeToEmpty) + " remaining"
                                   : "Estimating remaining time…"
    }
    function cpuDetailsText() {
        var values = SystemStats.cpuCoreUsages
        if (!values || values.length === 0) return "Per-CPU usage\nCollecting samples…"
        var lines = ["Per-CPU usage"]
        var row = []
        for (var i = 0; i < values.length; i++) {
            row.push("CPU" + i + " " + Math.round(values[i]) + "%")
            if (row.length === 4 || i === values.length - 1) {
                lines.push(row.join("    "))
                row = []
            }
        }
        return lines.join("\n")
    }
    function formatKiB(kib) {
        if (!isFinite(kib) || kib <= 0) return "0 MiB"
        if (kib >= 1024 * 1024) return (kib / (1024 * 1024)).toFixed(1) + " GiB"
        return Math.round(kib / 1024) + " MiB"
    }
    function memoryDetailsText() {
        var lines = ["Memory details"]
        lines.push("Used " + formatKiB(SystemStats.memUsedKiB)
            + " / " + formatKiB(SystemStats.memTotalKiB))
        lines.push("Available " + formatKiB(SystemStats.memAvailableKiB))
        lines.push("File cache " + formatKiB(SystemStats.memFileCacheKiB))
        lines.push("Buffers " + formatKiB(SystemStats.memBuffersKiB)
            + " · Reclaimable " + formatKiB(SystemStats.memReclaimableKiB))
        lines.push("Swap " + formatKiB(SystemStats.swapUsedKiB)
            + " / " + formatKiB(SystemStats.swapTotalKiB))
        return lines.join("\n")
    }
    function audioIcon() {
        if (AudioService.muted || AudioService.volume === 0) return Theme.audioMutedIcon
        if (AudioService.volume < 50) return Theme.audioLowIcon
        return Theme.audioHighIcon
    }
    function powerIcon() {
        if (profile === PowerProfile.Performance) return Theme.powerPerfIcon
        if (profile === PowerProfile.PowerSaver) return Theme.powerSaverIcon
        return Theme.powerBalancedIcon
    }
    function powerLabel() {
        if (profile === PowerProfile.Performance) return "Performance"
        if (profile === PowerProfile.PowerSaver) return "Power Saver"
        return "Balanced"
    }

    // Clicking the bar's empty area dismisses an open popup, like the dismiss
    // surface below the bar does for the rest of the screen.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (Popover.current !== null) Popover.closeAll()
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        // Pointer tracking for hover dismissal. Declared in the container so that
        // hovering any module below still counts as being on the bar.
        HoverHandler {
            id: barPointer
        }

        // ---- LEFT ----
        Row {
            id: leftRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Workspaces
            Rectangle {
                id: wsPill
                height: Theme.barHeight - 8
                implicitWidth: Math.max(wsRow.implicitWidth + 16, 32)
                radius: Theme.radius
                color: Theme.moduleBg
                border.width: Theme.borderWidth
                border.color: Theme.border

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 6
                    Repeater {
                        model: ScriptModel {
                            values: {
                                var name = bar.screen ? bar.screen.name : ""
                                return NiriService.workspaces.filter(function(w) { return w.output === name })
                            }
                        }
                        delegate: Text {
                            required property var modelData
                            text: modelData.focused || modelData.active ? Theme.workspaceActiveIcon : Theme.workspaceDefaultIcon
                            color: modelData.focused ? Theme.blue
                                 : (modelData.active ? Theme.fg : Theme.border)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            MouseArea {
                                anchors.fill: parent
                                onClicked: NiriService.focusWorkspace(modelData.id)
                            }
                        }
                    }
                }
            }

            Pill { id: cpuPill; icon: Theme.cpuIcon; label: Math.round(SystemStats.cpuUsage) + "%"; accent: Theme.blue }
            Pill { id: memPill; icon: Theme.memoryIcon; label: Math.round(SystemStats.memUsage) + "%"; accent: Theme.purple }

            Rectangle {
                id: trayPill
                height: Theme.barHeight - 8
                radius: Theme.radius
                color: Theme.moduleBg
                border.width: Theme.borderWidth
                border.color: Theme.border
                implicitWidth: Math.max(trayRow.implicitWidth + 16, 32)
                visible: SystemTray.items.values.length > 0

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: SystemTray.items
                        delegate: Image {
                            required property var modelData
                            source: modelData.icon
                            width: 18
                            height: 18
                            fillMode: Image.PreserveAspectFit
                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }
            }
        }

        // ---- CENTER ----
        Pill {
            id: clockPill
            anchors.centerIn: parent
            icon: Theme.clockIcon
            label: Qt.formatDateTime(bar.now, "hh:mm MM/dd/yy")
            accent: Theme.orange
        }

        // ---- RIGHT ----
        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Pill {
                id: networkPill
                icon: Theme.wifiIcon
                label: bar.networkLabel
                accent: Theme.cyan
                onLeftClicked: Popover.toggle(networkPopup)
            }
            Pill {
                id: bluetoothPill
                icon: Theme.bluetoothIcon
                label: bar.bluetoothLabel
                accent: Theme.blue
                onLeftClicked: Popover.toggle(bluetoothPopup)
            }
            Pill {
                id: audioPill
                icon: bar.audioIcon()
                label: AudioService.volume + "%"
                accent: Theme.yellow
                onLeftClicked: Popover.toggle(audioPopup)
                onRightClicked: AudioService.toggleMute()
                onScrolledUp: AudioService.stepUp()
                onScrolledDown: AudioService.stepDown()
            }
            Pill {
                id: batteryPill
                visible: bar.bat && bar.bat.isPresent
                icon: bar.batteryIcon(bar.batPct, bar.batCharging)
                label: Math.round(bar.batPct) + "%"
                accent: bar.batteryColor(bar.batPct)
            }
            Pill {
                id: powerPill
                icon: bar.powerIcon()
                label: bar.powerLabel()
                accent: Theme.purple
                onLeftClicked: Popover.toggle(powerPopup)
            }
        }
    }

    NetworkPanel { id: networkPopup; anchorItem: networkPill }
    BluetoothPanel { id: bluetoothPopup; anchorItem: bluetoothPill }
    AudioPanel { id: audioPopup; anchorItem: audioPill }
    PowerPanel { id: powerPopup; anchorItem: powerPill }
    HoverTooltip {
        anchorItem: cpuPill
        requestedVisible: cpuPill.hovered
        text: bar.cpuDetailsText()
    }
    HoverTooltip {
        anchorItem: memPill
        requestedVisible: memPill.hovered
        text: bar.memoryDetailsText()
    }
    HoverTooltip {
        anchorItem: batteryPill
        requestedVisible: batteryPill.visible && batteryPill.hovered
        text: bar.batteryEstimateText()
    }
}
