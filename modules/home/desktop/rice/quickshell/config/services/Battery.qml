pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// The laptop battery from UPower, and its charge over the last hours: a
// sample a minute, kept in the shell's state dir so restarts and reboots
// don't lose it. UPower's own history is root-only and resets with its
// device id, so it isn't used.
Singleton {
    id: root

    // null without a laptop battery; the rest then stays at its defaults
    readonly property var device: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    readonly property bool present: device !== null
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property int state: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    // wear: full capacity against design, 0..100
    readonly property bool healthSupported: (device?.healthPercentage ?? 0) > 0
    readonly property int health: Math.round(device?.healthPercentage ?? 0)
    // watts in or out, Wh now and when full
    readonly property real rate: Math.abs(device?.changeRate ?? 0)
    readonly property real energy: device?.energy ?? 0
    readonly property real capacity: device?.energyCapacity ?? 0

    readonly property string status: full ? "Fully charged"
        : charging ? (device?.timeToFull > 0 ? "Full in " + duration(device.timeToFull) : "Charging")
        : device?.timeToEmpty > 0 ? duration(device.timeToEmpty) + " left"
        : "On battery"

    // "3 h 12 min", "45 min"
    function duration(seconds) {
        const m = Math.round(seconds / 60)
        const h = Math.floor(m / 60)
        return h > 0 ? h + " h " + (m % 60) + " min" : m + " min"
    }

    // --- history ---------------------------------------------------------
    readonly property int hours: 6
    // the graph's resolution: one point per bucket, the latest sample in it
    readonly property int bucketSeconds: 120
    readonly property int bucketCount: hours * 3600 / bucketSeconds

    // [[unix seconds, percent, charging]], oldest first
    property var samples: []
    property bool loaded: false

    // percent per bucket, oldest first; null where the laptop was off or
    // the shell wasn't running
    readonly property var history: {
        const now = clock.now
        const out = new Array(bucketCount).fill(null)
        for (const [t, v] of samples) {
            const i = bucketCount - 1 - Math.floor((now - t) / bucketSeconds)
            if (i >= 0 && i < bucketCount) out[i] = v
        }
        return out
    }

    function sample() {
        if (!present || !loaded || !(device?.ready ?? false)) return
        const now = Math.floor(Date.now() / 1000)
        const cutoff = now - hours * 3600
        const kept = samples.filter(s => s[0] >= cutoff)
        // a fresh reading within half a minute replaces the last one
        if (kept.length && now - kept[kept.length - 1][0] < 30) kept.pop()
        kept.push([now, percent, charging])
        samples = kept
        clock.now = now
        store.setText(JSON.stringify({ samples: kept }))
    }

    QtObject {
        id: clock
        property int now: Math.floor(Date.now() / 1000)
    }

    Timer {
        interval: 60000
        running: root.present && root.loaded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }
    // and right away when the level or charger changes
    onPercentChanged: sample()
    onChargingChanged: sample()

    FileView {
        id: store
        path: Quickshell.statePath("battery-history.json")
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                root.samples = JSON.parse(text()).samples ?? []
            } catch (e) {
                root.samples = []
            }
            root.loaded = true
        }
        // first run: nothing yet
        onLoadFailed: root.loaded = true
    }
}
