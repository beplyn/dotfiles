pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// cpu / memory / temperature, read straight from procfs and sysfs every
// 2s like hakuspace's monitor_module.
Singleton {
    id: root

    property int cpu: 0
    property int memory: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property int temperature: 0

    property var lastCpu: null

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload()
            meminfo.reload()
            if (root.hasTemperature) thermal.reload()
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4]
            const total = f.reduce((a, b) => a + b, 0)
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total
                if (dt > 0) root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / dt))
            }
            root.lastCpu = { idle, total }
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => Number((text().match(new RegExp("^" + key + ":\\s+(\\d+)", "m")) || [0, 0])[1])
            const total = kb("MemTotal")
            const used = total - kb("MemAvailable")
            root.memTotalGiB = total / 1048576
            root.memUsedGiB = used / 1048576
            root.memory = total > 0 ? Math.round(100 * used / total) : 0
        }
    }

    // A CPU hwmon sensor if there is one, else the first thermal zone.
    property string sensor: ""
    readonly property bool hasTemperature: sensor !== ""

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do echo \"$(cat \"$d/name\") $d/temp1_input\"; done 2>/dev/null; ls /sys/class/thermal/thermal_zone*/temp 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l !== "")
                const cpu = lines.find(l => /^(coretemp|k10temp|zenpower|cpu_thermal) /.test(l))
                const zone = lines.find(l => l.startsWith("/sys/class/thermal/"))
                root.sensor = cpu ? cpu.split(" ")[1] : (zone ?? "")
            }
        }
    }

    FileView {
        id: thermal
        path: root.sensor
        onLoaded: root.temperature = Math.round(Number(text()) / 1000)
    }
}
