pragma Singleton
import QtQuick

QtObject {
    property var current: null

    function toggle(pop) {
        if (!pop) return
        if (current === pop) {
            if (!pop.closing && (pop.opening || pop.expanded)) pop.closePopup()
            return
        }
        // Unmap the previous overlay before opening a different panel.
        if (current && current !== pop) current.closePopup(true)
        current = pop
        pop.openPopup()
    }

    function closeAll() {
        if (!current) return
        var pop = current
        pop.closePopup()
    }
}
