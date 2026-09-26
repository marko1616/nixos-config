pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Interval CPU averages and a memory snapshot; no blocking reads on the UI thread.
Item {
    id: root
    property real cpuUsage: 0
    property real memUsage: 0
    property bool cpuReady: false
    property bool memReady: false
    property string cpuError: ""
    property string memError: ""
    property var cpuCoreUsages: []
    property var previousCpu: ({})
    property real cpuUpdatedAt: 0
    property real memUpdatedAt: 0
    property real memTotalKiB: 0
    property real memAvailableKiB: 0
    property real memUsedKiB: 0
    property real memPageCacheKiB: 0
    property real memBuffersKiB: 0
    property real memReclaimableKiB: 0
    property real swapTotalKiB: 0
    property real swapUsedKiB: 0

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
        onLoadFailed: root.invalidateCpu("CPU sample unavailable")
    }
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root.parseMemory(text())
        onLoadFailed: { root.memReady = false; root.memError = "Memory sample unavailable" }
    }
    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    function refresh() {
        var now = Date.now()
        if (cpuUpdatedAt > 0 && now - cpuUpdatedAt > 10000) invalidateCpu("CPU sample expired")
        if (memUpdatedAt > 0 && now - memUpdatedAt > 10000) {
            memReady = false
            memError = "Memory sample expired"
        }
        statFile.reload()
        memFile.reload()
    }

    function invalidateCpu(message) {
        cpuReady = false
        cpuError = message
        previousCpu = ({})
        cpuCoreUsages = []
    }

    function cpuDelta(current, previous) {
        if (!previous) return null
        var total = 0, idle = 0
        for (var i = 0; i < current.length; i++) {
            var delta = current[i] - previous[i]
            // Includes iowait rollback and counter resets: establish a new baseline.
            if (delta < 0) return null
            total += delta
            if (i === 3 || i === 4) idle += delta
        }
        return total > 0 ? Math.max(0, Math.min(100, (total - idle) / total * 100)) : null
    }

    function parseStat(stat) {
        var samples = ({})
        var lines = stat.split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (!/^cpu(?:\d+)?\s/.test(lines[i])) continue
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length < 9 || samples[parts[0]]) { invalidateCpu("Invalid CPU sample"); return }
            var counters = []
            // user..steal only: guest and guest_nice are already included.
            for (var k = 1; k <= 8; k++) {
                if (!/^\d+$/.test(parts[k]) || !Number.isSafeInteger(Number(parts[k]))) {
                    invalidateCpu("Invalid CPU sample")
                    return
                }
                counters.push(Number(parts[k]))
            }
            samples[parts[0]] = counters
        }
        if (!samples.cpu) { invalidateCpu("CPU sample unavailable"); return }
        var usage = cpuDelta(samples.cpu, previousCpu.cpu)
        cpuReady = usage !== null
        cpuError = ""
        if (cpuReady) cpuUsage = usage
        var cores = []
        for (var key in samples) {
            if (key === "cpu") continue
            cores[Number(key.substring(3))] = cpuDelta(samples[key], previousCpu[key])
        }
        cpuCoreUsages = cores
        previousCpu = samples
        cpuUpdatedAt = Date.now()
    }

    function parseMemory(mem) {
        var values = Object.create(null)
        var lines = mem.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/^([^:]+):\s+(\d+)\s+kB\s*$/)
            if (match) values[match[1]] = Number(match[2])
        }
        var total = values.MemTotal, available = values.MemAvailable
        var swapTotal = values.SwapTotal || 0, swapFree = values.SwapFree || 0
        if (!Number.isSafeInteger(total) || total <= 0 || !Number.isSafeInteger(available)
                || available > total || swapFree > swapTotal) {
            memReady = false
            memError = "Invalid memory sample"
            return
        }
        memTotalKiB = total
        memAvailableKiB = available
        memUsedKiB = total - available
        // Non-shared page cache and reclaimable slab are displayed separately.
        memPageCacheKiB = Math.max(0, (values.Cached || 0) - (values.Shmem || 0))
        memBuffersKiB = values.Buffers || 0
        memReclaimableKiB = values.SReclaimable || 0
        swapTotalKiB = swapTotal
        swapUsedKiB = swapTotal - swapFree
        memUsage = memUsedKiB / total * 100
        memReady = true
        memError = ""
        memUpdatedAt = Date.now()
    }
}
