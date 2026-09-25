import QtQuick

// Borderless text action. A subtle hover/press wash keeps it discoverable without
// bringing the platform Qt Controls style into the popup.
Rectangle {
    id: control

    property alias text: label.text
    property color textColor: Theme.blue
    signal clicked()

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 32
    radius: implicitHeight / 2
    color: pointer.pressed ? Qt.rgba(0.48, 0.64, 0.97, 0.20)
         : pointer.containsMouse ? Qt.rgba(0.48, 0.64, 0.97, 0.10)
         : "transparent"
    opacity: enabled ? 1 : 0.45

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: control.textColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: control.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
