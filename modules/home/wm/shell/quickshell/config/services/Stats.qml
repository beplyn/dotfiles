pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// cpu / memory / temperature / uptime from procfs and sysfs every 2s;
// two minutes of history for the graphs.
Singleton {
    id: root

    property int cpu: 0
    property int cores: 0
    property string load: ""
    property int memory: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real swapUsedGiB: 0
    property real swapTotalGiB: 0
    property int temperature: 0
    property string uptime: ""
    readonly property string hostname: hostFile.text().trim()

    readonly property int interval: 2000
    readonly property int historyLength: 60
    property var cpuHistory: []
    property var memHistory: []
    property var tempHistory: []

    // A new array each time, so bindings on the history update.
    function push(list, v) {
        const a = list.concat([v])
        return a.length > historyLength ? a.slice(a.length - historyLength) : a
    }

    property var lastCpu: null

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload()
            meminfo.reload()
            loadavg.reload()
            uptimeFile.reload()
            if (root.hasTemperature) thermal.reload()
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const lines = text().split("\n")
            const f = lines[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4]
            const total = f.reduce((a, b) => a + b, 0)
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total
                if (dt > 0) root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / dt))
                root.cpuHistory = root.push(root.cpuHistory, root.cpu)
            }
            root.lastCpu = { idle, total }
            root.cores = lines.filter(l => /^cpu\d/.test(l)).length
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
            root.swapTotalGiB = kb("SwapTotal") / 1048576
            root.swapUsedGiB = (kb("SwapTotal") - kb("SwapFree")) / 1048576
            root.memHistory = root.push(root.memHistory, root.memory)
        }
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().split(" ").slice(0, 3).join("  ")
    }

    FileView {
        id: hostFile
        path: "/proc/sys/kernel/hostname"
        blockLoading: true
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const mins = Math.floor(Number(text().split(" ")[0]) / 60)
            const d = Math.floor(mins / 1440), h = Math.floor(mins % 1440 / 60), m = mins % 60
            root.uptime = (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m"
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
        onLoaded: {
            root.temperature = Math.round(Number(text()) / 1000)
            root.tempHistory = root.push(root.tempHistory, root.temperature)
        }
    }
}
