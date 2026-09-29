import QtQuick
import Quickshell
import Quickshell.Wayland

// A full-screen, click-through-above-the-bar overlay can observe real pointer
// departure without mistaking the focus transition on map for a bar leave.
// The card and its dismiss area also share one keyboard-capable window.
PanelWindow {
    id: root
    default property alias contentData: contents.data
    property var anchorItem: null
    property var anchorWindow: null
    property int popHeight: Theme.popupMaxHeight
    property bool barHovered: false
    property bool opening: false
    property bool closing: false
    property bool expanded: false
    property bool leaveArmed: false
    property real cardX: 0
    property real revealProgress: expanded ? 1 : 0

    visible: false
    screen: anchorWindow ? anchorWindow.screen : null
    color: "transparent"
    // A zero exclusive zone still respects the bar's reserved space and shifts
    // this full-screen overlay down by one bar height. Ignore it instead.
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "marko-shell-popover"

    // Painting may overlap the bottom of the bar, but pointer input there must
    // still reach the bar. All below-bar clicks belong to this overlay.
    mask: Region {
        width: root.width
        height: Theme.barMargin + Theme.barHeight
        intersection: Intersection.Xor
    }

    Behavior on revealProgress {
        id: revealBehavior
        // Set synchronously on visibility changes before resetting the target.
        enabled: false
        NumberAnimation {
            id: revealAnimation
            // targetValue is updated before Behavior starts the animation.
            duration: revealBehavior.targetValue > 0 ? Theme.motionDuration : Theme.motionCloseDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: revealBehavior.targetValue > 0 && Theme.motionOvershoot
                ? Theme.motionCurve : Theme.motionCloseCurve
            onRunningChanged: {
                if (!running && root.closing && root.visible
                        && root.revealProgress <= 0.01) {
                    closeTimer.stop()
                    root.visible = false
                }
            }
        }
    }

    function updatePosition() {
        if (!anchorItem || !anchorWindow) return
        var center = anchorItem.mapToItem(anchorWindow.contentItem,
                                          anchorItem.width / 2, 0).x
        var inset = Theme.sdfPadding + Theme.barMargin + 8
        var minX = inset
        var maxX = Math.max(minX, width - Theme.popupWidth - inset)
        cardX = Math.max(minX, Math.min(maxX, center - Theme.popupWidth / 2))
    }

    function openPopup() {
        closeTimer.stop()
        opening = true
        closing = false
        expanded = false
        leaveArmed = false
        updatePosition()
        visible = true
        Qt.callLater(function() {
            if (!root.visible || root.closing) return
            root.updatePosition()
            root.opening = false
            root.expanded = true
            contents.forceActiveFocus()
        })
    }

    function closePopup(immediate) {
        opening = false
        if (immediate) {
            visible = false
            return
        }
        if (!visible || closing) return
        closing = true
        expanded = false
        closeTimer.restart()
    }

    onWidthChanged: { if (visible) updatePosition() }
    onVisibleChanged: {
        revealBehavior.enabled = visible
        if (!visible) {
            closeTimer.stop()
            opening = false
            closing = false
            expanded = false
            revealAnimation.complete()
            leaveArmed = false
            if (Popover.current === root) Popover.current = null
        }
    }

    Timer {
        id: closeTimer
        // Normally unmap on animation completion; this is a longer failsafe.
        interval: Theme.popupSettleDuration
        onTriggered: root.visible = false
    }

    Timer {
        interval: Theme.popupLeaveDelay
        running: root.visible && root.expanded && root.leaveArmed
            && !root.barHovered && !popupPointer.hovered && !root.closing
        onTriggered: root.closePopup()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPositionChanged: root.leaveArmed = true
        // The outside click is consumed, as it was by the grabbed PopupWindow,
        // but now it can play the same exit animation.
        onClicked: root.closePopup()
    }

    Item {
        id: cardSurface
        x: root.cardX - Theme.sdfPadding
        y: Theme.barMargin + Theme.barHeight - Theme.sdfBarOverlap
        width: Theme.popupWidth + Theme.sdfPadding * 2
        height: root.popHeight * Theme.motionMaxProgress + Theme.popupGap + Theme.sdfEdgePadding

        SdfPopupBackground {
            id: background
            anchors.fill: parent
            bodyHeight: root.popHeight
            revealProgress: root.revealProgress
        }

        Item {
            id: hitSurface
            x: (parent.width - width) / 2
            width: background.animatedBodyWidth
            height: Math.max(0, background.bodyBottom)

            HoverHandler {
                id: popupPointer
                blocking: false
                onHoveredChanged: { if (hovered) root.leaveArmed = true }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: function(mouse) { mouse.accepted = true }
            }

            Item {
                id: contentReveal
                y: Theme.popupGap
                width: parent.width
                height: Math.max(0, parent.height - y)
                clip: true

                FocusScope {
                    id: contents
                    x: (parent.width - width) / 2
                    width: Theme.popupWidth
                    height: root.popHeight
                    y: (1 - background.progress) * -24
                    focus: true
                    enabled: !root.closing
                    Keys.onEscapePressed: function(event) {
                        root.closePopup()
                        event.accepted = true
                    }
                }
            }
        }
    }
}
