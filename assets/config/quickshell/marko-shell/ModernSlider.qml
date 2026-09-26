import QtQuick
import QtQuick.Templates as T

// Backend-controlled slider: native drag/keys, exactly one step per wheel event.
T.Slider {
    id: control
    property real backendValue: 0
    signal valueRequested(real nextValue)
    from: 0
    to: 100
    stepSize: 1
    snapMode: T.Slider.SnapAlways
    value: Math.max(from, Math.min(to, backendValue))
    onMoved: {
        valueRequested(value)
        value = Qt.binding(function() { return Math.max(control.from, Math.min(control.to, control.backendValue)) })
    }
    implicitWidth: 160
    implicitHeight: 28
    leftPadding: 0
    rightPadding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    wheelEnabled: false
    opacity: enabled ? 1 : 0.45

    background: Rectangle {
        x: control.leftPadding + control.implicitHandleWidth / 2
        y: (control.height - height) / 2
        width: control.availableWidth - control.implicitHandleWidth
        height: 6
        radius: 3
        color: Theme.controlOff
        Rectangle {
            x: control.mirrored ? parent.width - width : 0
            width: control.position * parent.width
            height: parent.height
            radius: 3
            color: Theme.yellow
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: (control.height - height) / 2
        implicitWidth: 18
        implicitHeight: 18
        radius: 9
        color: Theme.controlThumb
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.blue
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            if (wheel.angleDelta.y === 0) { wheel.accepted = false; return }
            var step = wheel.angleDelta.y > 0 ? control.stepSize : -control.stepSize
            control.valueRequested(Math.max(control.from, Math.min(control.to, control.backendValue + step)))
            wheel.accepted = true
        }
    }
}
