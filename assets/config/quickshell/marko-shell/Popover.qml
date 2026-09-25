pragma Singleton
import QtQuick

// Coordinates popover windows so only one is open at a time.
//
// A plain QtObject has no default property, so this file cannot hold a Timer of
// its own. The leave countdown lives in the open popup instead, and this singleton
// only tracks pointer state and asks the current popup to re-evaluate.
QtObject {
    property var current: null

    // Pointer tracking. Popups never take a pointer grab, so "the pointer left the
    // bar and the popup" replaces clicking outside as the dismissal signal.
    property string barHoverScreen: ""
    property var hoveredPopup: null

    function setBarHover(screenName, hovered) {
        if (hovered) {
            barHoverScreen = screenName
        } else {
            if (barHoverScreen !== screenName) return
            barHoverScreen = ""
        }
        recheckHover()
    }

    function setPopupHover(pop, hovered) {
        if (hovered) {
            hoveredPopup = pop
        } else {
            if (hoveredPopup !== pop) return
            hoveredPopup = null
        }
        recheckHover()
    }

    function recheckHover() {
        if (current && current.recheckLeave) current.recheckLeave()
    }

    function toggle(pop) {
        if (!pop) return
        if (current === pop) {
            current = null
            if (pop.closePopup) pop.closePopup()
            else pop.visible = false
        } else {
            // Popups do not grab focus, so the outgoing one can animate out.
            if (current) current.closePopup()
            current = pop
            if (pop.openPopup) pop.openPopup()
            else pop.visible = true
            recheckHover()
        }
    }

    function closeAll() {
        if (!current) return
        var pop = current
        current = null
        if (pop.closePopup) pop.closePopup()
        else pop.visible = false
    }
}
