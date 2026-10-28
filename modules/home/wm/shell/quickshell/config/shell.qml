//@ pragma UseQApplication
import Quickshell
import qs.controlcenter
import qs.dashboard
import qs.monitor
import qs.notifications
import qs.osd
import qs.recorder
import qs.services

// The interactive layer over waybar. Every surface here is hidden until
// waybar, a niri bind or an event opens it.
ShellRoot {
    ControlCenter {}
    Dashboard {}
    Center {}
    Popups {}
    Osd {}
    RecordMenu {}

    // One per waybar hardware pill.
    Monitor {
        name: "cpu"
        icon: Icons.cpu
        title: "Processor"
        reading: Stats.cpu + "%"
        color: Theme.blue
        values: Stats.cpuHistory
        details: [
            { label: "Load (1, 5, 15 min)", value: Stats.load },
            { label: "Threads", value: String(Stats.cores) }
        ]
    }
    Monitor {
        name: "memory"
        icon: Icons.memory
        title: "Memory"
        reading: Stats.memory + "%"
        color: Theme.cyan
        values: Stats.memHistory
        details: [
            { label: "Used", value: Stats.memUsedGiB.toFixed(1) + " / " + Stats.memTotalGiB.toFixed(1) + " GiB" },
            { label: "Swap", value: Stats.swapTotalGiB > 0 ? Stats.swapUsedGiB.toFixed(1) + " / " + Stats.swapTotalGiB.toFixed(1) + " GiB" : "None" }
        ]
    }
    Monitor {
        name: "temperature"
        icon: Icons.temperature
        title: "Temperature"
        reading: Stats.temperature + "°"
        color: Theme.orange
        values: Stats.tempHistory
        min: 30
        max: 100
        unit: "°"
    }
}
