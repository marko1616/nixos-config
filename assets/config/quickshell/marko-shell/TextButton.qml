import QtQuick
import QtQuick.Templates as T

// Native button focus/accessibility with the existing borderless skin.
T.Button {
    id: control
    property color textColor: Theme.textButtonDefaultText
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 32
    leftPadding: 8
    rightPadding: 8
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45
    background: Rectangle {
        radius: height / 2
        color: control.down ? Theme.textButtonPressedBackground
             : control.hovered || control.visualFocus ? Theme.textButtonHoverBackground
             : Theme.textButtonIdleBackground
        border.width: control.visualFocus ? 1 : 0
        border.color: Theme.textButtonFocusBorder
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    contentItem: Text {
        text: control.text
        color: control.textColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
