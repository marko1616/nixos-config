import QtQuick
import Quickshell

// Interactive panels are Qt::Popup windows from their first map. Tooltips use
// HoverTooltip instead; changing grabFocus on an already mapped window is too late.
PopupWindow {
    id: root
    default property alias contentData: contents.data
    property var anchorItem: null
    readonly property var nativeParent: anchorItem ? anchorItem.Window.window : null
    property int popHeight: Theme.popupMaxHeight
    property bool barHovered: false
    property bool opening: false
    property bool parentFrameStarted: false
    property bool closingForLeave: false
    // A grabbed PopupWindow emits a synthetic leave on its parent bar when it
    // maps. Hold the clicked anchor until the pointer reaches another known
    // surface so that synthetic leave cannot immediately close the panel.
    property bool anchorHoverHeld: false
    property bool expanded: false
    property real revealProgress: expanded ? 1 : 0

    implicitWidth: Theme.popupWidth + Theme.sdfPadding * 2
    // The popup surface reaches back across the visual gap to the bar. Keep the
    // card inset so its appearance and content geometry remain unchanged.
    implicitHeight: popHeight + Theme.popupGap
    color: "transparent"
    grabFocus: true

    Behavior on revealProgress {
        SpringAnimation {
            spring: 5.0
            damping: 0.35
            mass: 1.0
            epsilon: 0.01
            onRunningChanged: {
                if (!running && !root.expanded && root.visible && !root.opening) {
                    closeTimer.stop()
                    root.visible = false
                }
            }
        }
    }

    function openPopup() {
        anchorHoverHeld = true
        closeTimer.stop()
        closingForLeave = false
        if (visible) {
            expanded = true
            return
        }
        // Popover.current enables OnDemand on the bar. Wait for its surface
        // commit before mapping the popup; otherwise Niri sees the old None
        // permission and grants only a pointer grab, leaving typing in the app.
        opening = true
        parentFrameStarted = false
        if (nativeParent) nativeParent.update()
        else showPopup()
    }

    function showPopup() {
        opening = false
        expanded = false
        visible = true
        Qt.callLater(function() {
            if (!root.visible) return
            root.expanded = true
            contents.forceActiveFocus()
        })
    }

    function closePopup(immediate) {
        opening = false
        closingForLeave = false
        anchorHoverHeld = false
        closeTimer.stop()
        expanded = false
        if (immediate) visible = false
        else if (visible) closeTimer.restart()
    }

    Connections {
        target: root.nativeParent
        enabled: root.opening
        // Ignore a previously queued swap: it may predate the permission change.
        function onAfterAnimating() { root.parentFrameStarted = true }
        function onFrameSwapped() {
            if (root.opening && root.parentFrameStarted && Popover.current === root) root.showPopup()
        }
    }

    Timer {
        id: closeTimer
        // SpringAnimation has no fixed duration; this is a conservative unmap
        // deadline after the visible damped motion has settled.
        interval: Theme.popupSettleDuration
        onTriggered: root.visible = false
    }

    Timer {
        interval: Theme.popupLeaveDelay
        running: root.visible && root.expanded && !root.anchorHoverHeld
            && !root.barHovered && !popupPointer.hovered
        onTriggered: {
            root.closePopup()
            root.closingForLeave = true
        }
    }

    function cancelLeaveClose() {
        if (closingForLeave && visible && (barHovered || popupPointer.hovered)) {
            closeTimer.stop()
            closingForLeave = false
            expanded = true
        }
    }
    onBarHoveredChanged: {
        // If the bar starts reporting hover again on a different item, the
        // synthetic-leave hold is no longer needed.
        if (anchorHoverHeld && barHovered && anchorItem && !anchorItem.hovered)
            anchorHoverHeld = false
        cancelLeaveClose()
    }

    onAnchorItemChanged: {
        if (anchorItem) {
            anchor.item = anchorItem
            anchor.edges = Edges.Bottom
            anchor.gravity = Edges.Bottom
            anchor.adjustment = PopupAdjustment.Slide | PopupAdjustment.Flip
            anchor.margins.bottom = 0
        }
    }

    onVisibleChanged: {
        if (!visible) {
            opening = false
            closingForLeave = false
            anchorHoverHeld = false
            closeTimer.stop()
            expanded = false
            if (Popover.current === root) Popover.current = null
        }
    }

    Item {
        anchors.fill: parent
        // Track the whole popup surface, including the transparent strip between
        // the bar and card, so crossing the seam does not start leave-close.
        HoverHandler {
            id: popupPointer
            blocking: false
            onHoveredChanged: {
                if (hovered) root.anchorHoverHeld = false
                root.cancelLeaveClose()
            }
        }

        SdfPopupBackground {
            anchors.fill: parent
            revealProgress: root.revealProgress
        }

        Item {
            id: contentReveal
            anchors.top: parent.top
            anchors.topMargin: Theme.popupGap
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.popupWidth
            height: root.popHeight * Math.max(0, Math.min(1, root.revealProgress))
            clip: true

            FocusScope {
                id: contents
                width: parent.width
                height: root.popHeight
                y: (1 - root.revealProgress) * -8
                focus: true
                Keys.onEscapePressed: function(event) {
                    root.closePopup()
                    event.accepted = true
                }
            }
        }
    }
}
