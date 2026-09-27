pragma Singleton
import QtQuick

QtObject {
    property var current: null

    function toggle(pop) {
        if (!pop) return
        if (current === pop && (pop.opening || pop.expanded)) {
            closeAll()
            return
        }
        // Release the previous native popup grab before opening another panel.
        if (current && current !== pop) current.closePopup(true)
        current = pop
        pop.openPopup()
    }

    function closeAll() {
        if (!current) return
        var pop = current
        current = null
        pop.closePopup(true)
    }
}
