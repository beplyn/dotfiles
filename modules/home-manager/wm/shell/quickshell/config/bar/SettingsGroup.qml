import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.widgets

// group/settings: backlight, volume, battery and power profile.
Drawer {
    icon: Icons.settings
    tooltip: "Click to show settings"

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        visible: Brightness.available
        text: Icons.level(Icons.backlight, Brightness.percent) + " " + Brightness.percent + "%"
        tooltip: "Brightness: " + Brightness.percent + "%"
        onScrolled: step => Brightness.step(step)
    }

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.muted ? Icons.muted + " " : Icons.level(Icons.volume, Audio.percent) + " " + Audio.percent + "%"
        tooltip: "Volume: " + Audio.percent + "%"
        onClicked: m => m.button === Qt.RightButton ? Session.mixer() : Audio.toggleMute()
        onScrolled: step => Audio.step(step * 0.05)
    }

    Pill {
        id: battery
        readonly property var dev: UPower.displayDevice
        readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
        readonly property bool charging: dev?.state === UPowerDeviceState.Charging
        readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged

        anchors.verticalCenter: parent.verticalCenter
        visible: dev?.isLaptopBattery ?? false
        text: (full && !UPower.onBattery ? Icons.plugged : Icons.level(charging ? Icons.charging : Icons.battery, pct)) + " " + pct + "%"
        fg: charging ? Theme.accent : pct <= 15 ? Theme.red : pct <= 30 ? Theme.yellow : Theme.accent
        tooltip: {
            const secs = charging ? dev?.timeToFull : dev?.timeToEmpty
            const time = secs > 0 ? Math.floor(secs / 3600) + "h " + Math.floor(secs % 3600 / 60) + "m " + (charging ? "to full" : "left") : ""
            return "Battery: " + pct + "%\nPower: " + (dev?.changeRate ?? 0).toFixed(1) + "W" + (time ? "\n" + time : "")
        }
    }

    // Click cycles profiles like waybar's power-profiles-daemon module.
    Pill {
        readonly property var order: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        anchors.verticalCenter: parent.verticalCenter
        text: PowerProfiles.profile === PowerProfile.Performance ? Icons.performance
            : PowerProfiles.profile === PowerProfile.PowerSaver ? Icons.powerSaver
            : Icons.balanced
        tooltip: "Power profile: " + PowerProfile.toString(PowerProfiles.profile)
        onClicked: PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length]
    }
}
