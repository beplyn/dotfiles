import QtQuick
import qs.services
import qs.widgets

// group/monitor: cpu, memory and temperature behind a drawer.
Drawer {
    icon: Icons.monitor
    tooltip: "Click to show monitor stats"

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        idle: Theme.alpha(Theme.surface, 0.6)
        padding: 12
        text: Stats.cpu + "% " + Icons.cpu
        fg: Stats.cpu >= 90 ? Theme.red : Stats.cpu >= 70 ? Theme.yellow : Theme.accent
    }

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        idle: Theme.alpha(Theme.surface, 0.6)
        padding: 12
        text: Stats.memory + "% " + Icons.memory
        tooltip: Stats.memUsedGiB.toFixed(1) + " / " + Stats.memTotalGiB.toFixed(1) + " GiB used"
        fg: Stats.memory >= 90 ? Theme.red : Stats.memory >= 75 ? Theme.yellow : Theme.accent
    }

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        visible: Stats.hasTemperature
        idle: Theme.alpha(Theme.surface, 0.6)
        padding: 12
        text: Stats.temperature + "°C " + Icons.temperature
        fg: Stats.temperature >= 85 ? Theme.red : Theme.accent
    }
}
