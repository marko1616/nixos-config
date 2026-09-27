import QtQuick
import QtQuick.Templates as T

// Same metrics and palette as TextButton/ModernSwitch, independent of Qt style.
T.TextField {
    id: control
    implicitWidth: 160
    implicitHeight: 32
    leftPadding: 10
    rightPadding: 10
    topPadding: 6
    bottomPadding: 6
    verticalAlignment: TextInput.AlignVCenter
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.fg
    placeholderText: "Password"
    placeholderTextColor: Theme.border
    selectionColor: Theme.blue
    selectedTextColor: Theme.popupBg
    echoMode: TextInput.Password
    selectByMouse: true
    activeFocusOnTab: true
    inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
    Accessible.name: "Wi-Fi password"

    // Templates do not supply a placeholder item. Match the input's content
    // rectangle and alignment without placing a pointer handler over the field.
    Text {
        x: control.leftPadding
        y: control.topPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.height - control.topPadding - control.bottomPadding
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        radius: Theme.radius - 2
        color: control.activeFocus ? Theme.moduleBg : Theme.controlOff
        border.width: 0
    }
}
