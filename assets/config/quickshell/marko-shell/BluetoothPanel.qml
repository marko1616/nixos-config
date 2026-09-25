import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Bluetooth management popover, anchored below the bluetooth pill.
PopoverBase {
    id: root
    popHeight: 420

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Bluetooth"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            ModernSwitch {
                id: btSwitch
                enabled: Bluetooth.defaultAdapter !== null
                checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                onToggled: function(nextChecked) {
                    if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = nextChecked
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: Bluetooth.defaultAdapter
                ? Bluetooth.defaultAdapter.name + (Bluetooth.defaultAdapter.enabled ? " · Powered" : " · Powered off")
                : "No Bluetooth adapter"
            color: Theme.border
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Scanning"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
            Item { Layout.fillWidth: true }
            ModernSwitch {
                id: scanSwitch
                enabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false
                onToggled: function(nextChecked) {
                    if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.discovering = nextChecked
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: ScriptModel {
                values: {
                    if (!Bluetooth.defaultAdapter) return []
                    var devs = Bluetooth.defaultAdapter.devices.values
                    return [...devs].sort(function(a, b) {
                        if (a.connected !== b.connected) return b.connected - a.connected
                        if (a.paired !== b.paired) return b.paired - a.paired
                        return (a.name || a.deviceName) < (b.name || b.deviceName) ? -1 : 1
                    })
                }
            }
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 48
                radius: Theme.radius - 2
                color: modelData.connected ? Theme.moduleBg : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.deviceName || modelData.address
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: (modelData.pairing ? "Pairing…"
                                  : (modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Not paired")))
                                  + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                                  + " · " + modelData.address
                            color: Theme.border
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                        }
                    }
                    TextButton {
                        enabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                        text: modelData.pairing ? "Cancel"
                            : (modelData.paired
                                ? (modelData.connected ? "Disconnect" : "Connect")
                                : "Pair")
                        textColor: modelData.pairing ? Theme.yellow
                                 : (modelData.connected ? Theme.red : Theme.blue)
                        onClicked: {
                            if (modelData.pairing) modelData.cancelPair()
                            else if (!modelData.paired) modelData.pair()
                            else if (modelData.connected) modelData.disconnect()
                            else modelData.connect()
                        }
                    }
                }
            }
        }
    }

}
