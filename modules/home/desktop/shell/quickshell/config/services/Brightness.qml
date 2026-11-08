pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// First backlight device, or else every monitor speaking DDC/CI, all set to
// the same level; `available` stays false when there is neither.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int current: 0
    // i2c buses of the monitors ddcutil found, when there is no backlight
    property var buses: []
    // a level is known; the OSD skips the first one
    property bool ready: false
    readonly property bool ddc: device === "" && buses.length > 0
    readonly property bool available: (device !== "" || ddc) && max > 0
    readonly property int percent: available ? Math.round(100 * current / max) : 0

    function set(pct) {
        if (!available) return
        const p = Math.max(1, Math.min(100, Math.round(pct)))
        current = Math.round(max * p / 100)
        if (ddc) ddcSet.restart()
        else Quickshell.execDetached([Theme.bin.brightnessctl, "-d", device, "set", p + "%"])
    }

    function step(delta) {
        set(percent + delta)
    }

    // brightnessctl -m: device,class,current,percent,max
    Process {
        running: true
        command: [Theme.bin.brightnessctl, "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length < 5) {
                    ddcDetect.running = true
                    return
                }
                root.device = f[0]
                root.current = Number(f[2])
                root.max = Number(f[4])
                root.ready = true
            }
        }
    }

    // sysfs doesn't emit change events, so poll; keybinds change it too.
    FileView {
        id: level
        path: root.available && !root.ddc ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        onLoaded: root.current = Number(text())
    }

    Timer {
        interval: 1000
        running: root.available && !root.ddc
        repeat: true
        onTriggered: level.reload()
    }

    // --- DDC/CI: the slider drives every external monitor ------------------
    // A round trip takes a few hundred ms, so reads happen once and writes
    // are coalesced while the slider moves.

    Process {
        id: ddcDetect
        command: [Theme.bin.ddcutil, "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.buses = text.split("\n")
                    .map(l => l.match(/I2C bus:\s*\/dev\/i2c-(\d+)/))
                    .filter(m => m !== null)
                    .map(m => m[1])
                if (root.buses.length > 0) ddcGet.running = true
            }
        }
    }

    // --brief: "VCP 10 C <current> <max>"; the first monitor's scale is
    // used for all of them
    Process {
        id: ddcGet
        command: [Theme.bin.ddcutil, "--bus", root.buses[0] ?? "", "getvcp", "10", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/)
                if (f.length < 5 || Number(f[4]) <= 0) return
                root.max = Number(f[4])
                root.current = Number(f[3])
                root.ready = true
            }
        }
    }

    // one monitor at a time, the newest level only
    property var queue: []
    Timer {
        id: ddcSet
        interval: 150
        onTriggered: {
            root.queue = root.buses.map(bus => ({ bus: bus, value: root.current }))
            if (!ddcWrite.running) ddcWrite.next()
        }
    }

    Process {
        id: ddcWrite
        function next() {
            if (root.queue.length === 0) return
            const job = root.queue[0]
            root.queue = root.queue.slice(1)
            command = [Theme.bin.ddcutil, "--bus", job.bus, "--noverify", "setvcp", "10", String(job.value)]
            running = true
        }
        onExited: next()
    }
}
