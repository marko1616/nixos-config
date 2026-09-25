pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory usage. A short interval keeps per-CPU hover details responsive.
Item {
    property real cpuUsage: 0
    property real memUsage: 0
    property var cpuCoreUsages: []

    property real memTotalKiB: 0
    property real memAvailableKiB: 0
    property real memUsedKiB: 0
    property real memFileCacheKiB: 0
    property real memBuffersKiB: 0
    property real memReclaimableKiB: 0
    property real swapTotalKiB: 0
    property real swapUsedKiB: 0

    property real prevIdle: 0
    property real prevTotal: 0
    property var prevCoreIdle: []
    property var prevCoreTotal: []

    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: refresh()
    }

    function refresh() {
        statFile.reload()
        statFile.waitForJob()
        var stat = statFile.text()
        var lines = stat.split("\n")
        var nextCoreUsage = []
        var nextCoreIdle = []
        var nextCoreTotal = []
        for (var i = 0; i < lines.length; i++) {
            if (!/^cpu(?:\d+)?\s/.test(lines[i])) continue
            var parts = lines[i].trim().split(/\s+/)
            var idle = parseInt(parts[4], 10) + parseInt(parts[5], 10) // idle + iowait
            var total = 0
            // guest/guest_nice are already included in user/nice.
            // Sum user through steal, excluding those duplicate guest fields.
            for (var k = 1; k < Math.min(parts.length, 9); k++) total += parseInt(parts[k], 10)

            if (parts[0] === "cpu") {
                if (prevTotal > 0) {
                    var dTotal = total - prevTotal
                    var dIdle = idle - prevIdle
                    cpuUsage = dTotal > 0 ? Math.max(0, Math.min(100, (dTotal - dIdle) / dTotal * 100)) : 0
                }
                prevIdle = idle
                prevTotal = total
            } else {
                var core = parseInt(parts[0].substring(3), 10)
                var previousTotal = prevCoreTotal[core] || 0
                var previousIdle = prevCoreIdle[core] || 0
                var coreDelta = total - previousTotal
                var coreIdleDelta = idle - previousIdle
                nextCoreUsage[core] = previousTotal > 0 && coreDelta > 0
                    ? Math.max(0, Math.min(100, (coreDelta - coreIdleDelta) / coreDelta * 100))
                    : (cpuCoreUsages[core] || 0)
                nextCoreIdle[core] = idle
                nextCoreTotal[core] = total
            }
        }
        cpuCoreUsages = nextCoreUsage
        prevCoreIdle = nextCoreIdle
        prevCoreTotal = nextCoreTotal

        memFile.reload()
        memFile.waitForJob()
        var mem = memFile.text()
        var values = ({})
        var mlines = mem.split("\n")
        for (var m = 0; m < mlines.length; m++) {
            var match = mlines[m].match(/^([^:]+):\s+(\d+)/)
            if (match) values[match[1]] = parseInt(match[2], 10)
        }
        memTotalKiB = values.MemTotal || 0
        memAvailableKiB = values.MemAvailable || 0
        memUsedKiB = Math.max(0, memTotalKiB - memAvailableKiB)
        memBuffersKiB = values.Buffers || 0
        memReclaimableKiB = values.SReclaimable || 0
        memFileCacheKiB = Math.max(0, (values.Cached || 0) + memReclaimableKiB - (values.Shmem || 0))
        swapTotalKiB = values.SwapTotal || 0
        swapUsedKiB = Math.max(0, swapTotalKiB - (values.SwapFree || 0))
        if (memTotalKiB > 0) memUsage = memUsedKiB / memTotalKiB * 100
    }

    Component.onCompleted: refresh()
}
