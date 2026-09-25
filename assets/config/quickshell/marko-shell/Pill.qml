import QtQuick

// Rounded module capsule matching the existing Waybar style.
Rectangle {
    id: pill
    property string icon: ""
    property string label: ""
    property color accent: Theme.fg
    readonly property bool hovered: pointer.containsMouse

    signal leftClicked()
    signal rightClicked()
    signal scrolledUp()
    signal scrolledDown()

    height: Theme.barHeight - 8
    implicitWidth: Math.max(contentRow.implicitWidth + 24, 32)
    radius: Theme.radius
    color: Theme.moduleBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: pill.icon !== ""
            text: pill.icon
            color: pill.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
        Text {
            visible: pill.label !== ""
            text: pill.label
            color: pill.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) pill.leftClicked()
            else if (mouse.button === Qt.RightButton) pill.rightClicked()
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) pill.scrolledUp()
            else if (wheel.angleDelta.y < 0) pill.scrolledDown()
        }
    }
}
