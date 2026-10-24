pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// First backlight device; `available` stays false on desktops without one.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int current: 0
    readonly property bool available: device !== "" && max > 0
    readonly property int percent: available ? Math.round(100 * current / max) : 0

    function set(pct) {
        const p = Math.max(1, Math.min(100, Math.round(pct)))
        current = Math.round(max * p / 100)
        Quickshell.execDetached([Theme.bin.brightnessctl, "-d", device, "set", p + "%"])
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
                if (f.length < 5) return
                root.device = f[0]
                root.current = Number(f[2])
                root.max = Number(f[4])
            }
        }
    }

    // sysfs doesn't emit change events, so poll; keybinds change it too.
    FileView {
        id: level
        path: root.available ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        onLoaded: root.current = Number(text())
    }

    Timer {
        interval: 1000
        running: root.available
        repeat: true
        onTriggered: level.reload()
    }
}
