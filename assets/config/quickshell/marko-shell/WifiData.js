// SSID-HEX preserves colons, backslashes, whitespace and UTF-8 in SSIDs.
// BSSID has a fixed, explicitly parsed shape; --escape no is intentional.
function parseAccessPoints(output) {
    var networks = Object.create(null)
    var lines = output.split("\n")
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].replace(/\r$/, "")
        if (!line) continue
        var match = line.match(/^(\*| |):((?:[0-9a-fA-F]{2}){1,32}):((?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}):(\d{1,3})$/)
        if (!match || Number(match[4]) > 100) continue
        var ssid
        try {
            ssid = decodeURIComponent(match[2].replace(/../g, "%$&"))
        } catch (error) {
            continue
        }
        var entry = { bssid: match[3].toUpperCase(), active: match[1] === "*", signal: Number(match[4]) }
        if (!networks[ssid]) networks[ssid] = []
        var points = networks[ssid]
        var duplicate = points.some(function(ap) { return ap.bssid === entry.bssid })
        if (!duplicate) points.push(entry)
    }
    Object.keys(networks).forEach(function(ssid) {
        networks[ssid].sort(function(a, b) {
            return b.signal - a.signal || a.bssid.localeCompare(b.bssid)
        })
    })
    return networks
}

function apLabel(network, byDevice) {
    var device = network.device ? network.device.name : ""
    var points = byDevice[device] && byDevice[device][network.name] || []
    if (network.connected) {
        var active = points.filter(function(ap) { return ap.active })
        return "BSSID · " + (active.length === 1 ? active[0].bssid : "Unavailable")
    }
    if (points.length === 0) return "BSSID · Not in scan results"
    if (points.length === 1) return "BSSID · " + points[0].bssid
    return "BSSID (strongest) · " + points[0].bssid + " · +" + (points.length - 1)
}

function networkKey(network) {
    return JSON.stringify([network.device ? network.device.name : "", network.name])
}

function profileUuid(network) {
    var profiles = network.nmSettings || []
    var selected = null
    var timestamp = -1
    for (var i = 0; i < profiles.length; i++) {
        var settings = profiles[i].read()
        var current = settings.connection ? Number(settings.connection.timestamp || 0) : 0
        if (current > timestamp) {
            timestamp = current
            selected = profiles[i]
        }
    }
    return selected ? selected.uuid : ""
}

function validPassword(value) {
    // NetworkManager validates the security-specific rules. Spaces are significant.
    return value.length > 0 && !/[\x00-\x1f\x7f]/.test(value)
}
