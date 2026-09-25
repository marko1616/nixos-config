import QtQuick
import QtQuick.Layouts

// Volume control popover. The slider and the bar pill both accept wheel input.
PopoverBase {
    id: root
    popHeight: 132

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Volume"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: AudioService.volume + "%"
                color: Theme.yellow
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        Item {
            id: slider
            Layout.fillWidth: true
            implicitHeight: 28

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: height / 2
                color: Theme.controlOff
            }

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * AudioService.volume / 100
                height: 6
                radius: height / 2
                color: Theme.yellow
            }

            Rectangle {
                width: 18
                height: 18
                radius: width / 2
                y: (parent.height - height) / 2
                x: Math.max(0, Math.min(parent.width - width,
                    parent.width * AudioService.volume / 100 - width / 2))
                color: Theme.controlThumb

                Behavior on x {
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateVolume(mouse) {
                    AudioService.setVolume(mouse.x / width * 100)
                }

                onPressed: function(mouse) { updateVolume(mouse) }
                onPositionChanged: function(mouse) {
                    if (pressed) updateVolume(mouse)
                }
                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0) AudioService.stepUp()
                    else if (wheel.angleDelta.y < 0) AudioService.stepDown()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            TextButton {
                text: AudioService.muted ? "Unmute" : "Mute"
                textColor: AudioService.muted ? Theme.blue : Theme.red
                onClicked: AudioService.toggleMute()
            }
            Item { Layout.fillWidth: true }
        }
    }
}
