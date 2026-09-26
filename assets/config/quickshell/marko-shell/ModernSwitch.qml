import QtQuick
import QtQuick.Templates as T

// Native switch interaction with a controlled backend value and local skin.
T.Switch {
    id: control
    property bool backendChecked: false
    signal toggleRequested(bool nextChecked)
    checked: backendChecked
    onToggled: {
        toggleRequested(checked)
        // Retain the backend binding even when a request is rejected/no-op.
        checked = Qt.binding(function() { return control.backendChecked })
    }
    implicitWidth: 42
    implicitHeight: 24
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45

    indicator: Rectangle {
        width: control.width
        height: control.height
        radius: height / 2
        color: control.checked ? Theme.blue : Theme.controlOff
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Theme.fg : (control.checked ? Theme.blue : Theme.border)
        Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: (parent.height - height) / 2
            x: 3 + control.visualPosition * (parent.width - width - 6)
            color: Theme.controlThumb
            Behavior on x {
                enabled: !control.down
                NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
            }
        }
    }
}
