import QtQuick
import Quickshell

// Non-focus-stealing tooltip anchored below a bar item, with the same gap and
// motion language as the regular popovers.
PopupWindow {
    id: root

    property var anchorItem: null
    required property var anchorWindow
    property string text: ""
    property bool requestedVisible: false
    readonly property bool shouldShow: requestedVisible && Popover.current === null
    property real revealProgress: 0
    readonly property real bodyWidth: Math.min(440, label.implicitWidth + 24)
    readonly property real bodyHeight: label.implicitHeight + 16

    implicitWidth: bodyWidth + Theme.sdfPadding * 2
    implicitHeight: bodyHeight * Theme.motionMaxProgress + Theme.popupGap + Theme.sdfEdgePadding
    color: "transparent"
    grabFocus: false

    anchor.window: anchorWindow
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    anchor.onAnchoring: {
        if (!root.anchorItem || !root.anchorWindow) return
        var point = root.anchorItem.mapToItem(root.anchorWindow.contentItem,
            root.anchorItem.width / 2, root.anchorItem.height)
        // Constrain the entire shader surface, not just its body. Its bar
        // half-plane is opaque even in the horizontal shoulder padding.
        // Stay past the bar's rounded corners so that plane meets a flat edge.
        var inset = Theme.barRadius + Theme.sdfEdgePadding
        var maxX = Math.max(inset, root.anchorWindow.width - root.width - inset)
        anchor.rect.x = Math.round(Math.max(inset, Math.min(maxX,
            point.x - root.width / 2)))
        anchor.rect.y = Math.round(point.y)
    }

    Connections {
        target: root.anchorWindow
        function onWidthChanged() { root.anchor.updateAnchor() }
    }

    onShouldShowChanged: {
        if (shouldShow) {
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
            if (!root.shouldShow) return
            root.visible = true
            Qt.callLater(function() {
                if (root.visible && root.shouldShow) root.revealProgress = 1
            })
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.popupSettleDuration
        onTriggered: root.visible = false
    }

    Behavior on revealProgress {
        id: revealBehavior
        enabled: false
        NumberAnimation {
            id: revealAnimation
            duration: revealBehavior.targetValue > 0 ? Theme.motionDuration : Theme.motionCloseDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: revealBehavior.targetValue > 0 && Theme.motionOvershoot
                ? Theme.motionCurve : Theme.motionCloseCurve
            onRunningChanged: {
                if (!running && root.visible && !root.shouldShow
                        && root.revealProgress <= 0.01) {
                    hideTimer.stop()
                    root.visible = false
                }
            }
        }
    }

    onVisibleChanged: {
        revealBehavior.enabled = visible
        if (!visible) {
            revealProgress = 0
            revealAnimation.complete()
        }
    }

    SdfPopupBackground {
        id: background
        anchors.fill: parent
        bodyHeight: root.bodyHeight
        revealProgress: root.revealProgress
    }

    Item {
        anchors.top: parent.top
        anchors.topMargin: Theme.popupGap
        anchors.horizontalCenter: parent.horizontalCenter
        width: background.animatedBodyWidth
        height: Math.max(0, background.bodyBottom - Theme.popupGap)
        clip: true

        Item {
            x: (parent.width - width) / 2
            width: root.bodyWidth
            height: root.bodyHeight
            y: (1 - background.progress) * -12

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
}
