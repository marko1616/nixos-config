import QtQuick
import Quickshell

// Non-focus-stealing tooltip anchored below a bar item, with the same gap and
// motion language as the regular popovers.
PopupWindow {
    id: root

    property var anchorItem: null
    property string text: ""
    property bool requestedVisible: false
    property real revealProgress: 0

    implicitWidth: Math.min(440, label.implicitWidth + 24)
    implicitHeight: label.implicitHeight + 16
    color: "transparent"
    grabFocus: false

    onAnchorItemChanged: {
        if (anchorItem) {
            anchor.item = anchorItem
            anchor.edges = Edges.Bottom
            anchor.gravity = Edges.Bottom
            anchor.adjustment = PopupAdjustment.Slide | PopupAdjustment.Flip
            anchor.margins.bottom = -Theme.popupGap
        }
    }

    onRequestedVisibleChanged: {
        if (requestedVisible) {
            hideTimer.stop()
            showTimer.restart()
        } else {
            showTimer.stop()
            if (visible) {
                revealProgress = 0
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: showTimer
        interval: 400
        onTriggered: {
            root.visible = true
            Qt.callLater(function() { root.revealProgress = 1 })
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.motionDuration
        onTriggered: root.visible = false
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: Theme.motionDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius - 2
        color: Theme.popupBg
        border.width: Theme.borderWidth
        border.color: Theme.border
        opacity: root.revealProgress
        scale: 0.96 + root.revealProgress * 0.04
        transformOrigin: Item.TopRight
        transform: Translate { y: (1 - root.revealProgress) * -6 }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            lineHeight: 1.15
        }
    }
}
