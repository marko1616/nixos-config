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
    property bool expanded: false
    property real revealProgress: expanded ? 1 : 0

    implicitWidth: Theme.popupWidth
    // The popup surface reaches back across the visual gap to the bar. Keep the
    // card inset so its appearance and content geometry remain unchanged.
    implicitHeight: popHeight + Theme.popupGap
    color: "transparent"
    grabFocus: true

    Behavior on revealProgress {
        NumberAnimation {
            duration: Theme.motionDuration
            easing.type: Easing.OutCubic
        }
    }

    function openPopup() {
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
        interval: Theme.motionDuration
        onTriggered: root.visible = false
    }

    Timer {
        interval: Theme.popupLeaveDelay
        running: root.visible && root.expanded && !root.barHovered && !popupPointer.hovered
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
    onBarHoveredChanged: cancelLeaveClose()

    onAnchorItemChanged: {
        if (anchorItem) {
            anchor.item = anchorItem
            anchor.edges = Edges.Bottom
            anchor.gravity = Edges.Bottom
            anchor.adjustment = PopupAdjustment.Slide | PopupAdjustment.Flip
            // The popup's transparent hover bridge occupies this gap; the
            // visible card itself is inset by the same amount below.
            anchor.margins.bottom = 0
        }
    }

    onVisibleChanged: {
        if (!visible) {
            opening = false
            closingForLeave = false
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
            onHoveredChanged: root.cancelLeaveClose()
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Theme.popupGap
            radius: Theme.radius
            color: Theme.popupBg
            border.width: Theme.borderWidth
            border.color: Theme.border
            opacity: root.revealProgress
            scale: 0.96 + root.revealProgress * 0.04
            transformOrigin: Item.TopRight
            transform: Translate { y: (1 - root.revealProgress) * -8 }

            FocusScope {
                id: contents
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: function(event) {
                    root.closePopup()
                    event.accepted = true
                }
            }
        }
    }
}
