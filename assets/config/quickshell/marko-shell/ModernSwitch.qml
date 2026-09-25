import QtQuick

// Compact switch with a bright thumb, blue active track and dark inactive track.
Item {
    id: control

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 42
    implicitHeight: 24
    opacity: enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? Theme.blue : Theme.controlOff
        border.width: 1
        border.color: control.checked ? Theme.blue : Theme.border

        Behavior on color {
            ColorAnimation { duration: Theme.motionDuration }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.motionDuration }
        }
    }

    Rectangle {
        width: 18
        height: 18
        radius: width / 2
        y: 3
        x: control.checked ? control.width - width - 3 : 3
        color: Theme.controlThumb

        Behavior on x {
            NumberAnimation {
                duration: Theme.motionDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: control.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled(!control.checked)
    }
}
