import QtQuick
import Quickshell

// Shared anchored popup, normally dismissed on pointer departure.
PopupWindow {
    id: root
    default property alias contentData: surface.data
    property var anchorItem: null
    property int popHeight: Theme.popupMaxHeight
    property bool expanded: false

    implicitWidth: Theme.popupWidth
    implicitHeight: popHeight
    color: "transparent"
    // A grabbed popup is unmapped by the compositor before the close animation can
    // run, so popups only take a grab while they actually need keyboard input.
    property bool needsKeyboard: false
    property bool remapping: false
    grabFocus: Theme.popupGrabFocus || needsKeyboard
    property real revealProgress: expanded ? 1 : 0

    Behavior on revealProgress {
        NumberAnimation {
            duration: Theme.motionDuration
            easing.type: Easing.OutCubic
        }
    }

    function openPopup() {
        closeTimer.stop()
        leaveTimer.stop()
        expanded = false
        visible = true
        Qt.callLater(function() { root.expanded = true })
    }

    function closePopup() {
        if (!visible) return
        leaveTimer.stop()
        expanded = false
        closeTimer.restart()
    }

    // Quickshell only applies grabFocus when the popup is shown again, so a popup
    // that starts needing the keyboard has to be remapped.
    function remap() {
        if (!visible) return
        closeTimer.stop()
        remapping = true
        visible = false
        Qt.callLater(function() {
            root.remapping = false
            if (Popover.current === root) root.openPopup()
        })
    }

    Timer {
        id: closeTimer
        interval: Theme.motionDuration
        onTriggered: root.visible = false
    }

    // Hover dismissal. The pointer may sit on the bar, on this popup, or on
    // neither; only the last case starts the countdown.
    Timer {
        id: leaveTimer
        interval: Theme.popupLeaveDelay
        onTriggered: {
            if (!root.visible) return
            if (Popover.barHoverScreen !== "" || Popover.hoveredPopup === root) return
            root.closePopup()
        }
    }

    // Called by the Popover singleton whenever the tracked pointer state changes.
    function recheckLeave() {
        if (!visible || Popover.barHoverScreen !== "" || Popover.hoveredPopup === root) {
            leaveTimer.stop()
        } else {
            leaveTimer.restart()
        }
    }

    onAnchorItemChanged: {
        if (anchorItem) {
            anchor.item = anchorItem
            anchor.edges = Edges.Bottom
            anchor.gravity = Edges.Bottom
            anchor.adjustment = PopupAdjustment.Slide | PopupAdjustment.Flip
            // PopupAnchor removes positive margins from the anchor rectangle; a
            // negative bottom margin extends it downward and creates the gap.
            anchor.margins.bottom = -Theme.popupGap
        }
    }

    onVisibleChanged: {
        if (!visible) {
            leaveTimer.stop()
            Popover.setPopupHover(root, false)
            expanded = false
            if (!remapping && Popover.current === root) Popover.current = null
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.popupBg
        border.width: Theme.borderWidth
        border.color: Theme.border
        opacity: root.revealProgress
        scale: 0.96 + root.revealProgress * 0.04
        transformOrigin: Item.TopRight
        transform: Translate { y: (1 - root.revealProgress) * -8 }

        // The popup closes when the pointer leaves it, so it has to know whether
        // the pointer is inside.
        HoverHandler {
            id: popupPointer
            onHoveredChanged: Popover.setPopupHover(root, hovered)
        }
    }
}
