import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// Power profile switcher, anchored below the power pill.
PopoverBase {
    id: root
    popHeight: PowerProfiles.hasPerformanceProfile ? 162 : 122

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        Text {
            text: "Power profile"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        Repeater {
            model: PowerProfiles.hasPerformanceProfile
                   ? [ "performance", "balanced", "power-saver" ]
                   : [ "balanced", "power-saver" ]
            delegate: Rectangle {
                id: profileRow
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.maximumHeight: 36
                radius: Theme.radius - 2
                color: PowerProfiles.profile === profileEnum(modelData) ? Theme.moduleBg
                     : profileMouse.containsMouse ? Qt.rgba(0.48, 0.64, 0.97, 0.10)
                     : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8
                    Text {
                        text: profileIcon(modelData)
                        color: Theme.purple
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        text: profileLabel(modelData)
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                }

                MouseArea {
                    id: profileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerProfiles.profile = profileEnum(modelData)
                }
            }
        }
    }

    function profileEnum(name) {
        if (name === "performance") return PowerProfile.Performance
        if (name === "power-saver") return PowerProfile.PowerSaver
        return PowerProfile.Balanced
    }
    function profileIcon(name) {
        if (name === "performance") return Theme.powerPerfIcon
        if (name === "power-saver") return Theme.powerSaverIcon
        return Theme.powerBalancedIcon
    }
    function profileLabel(name) {
        if (name === "performance") return "Performance"
        if (name === "power-saver") return "Power Saver"
        return "Balanced"
    }
}
