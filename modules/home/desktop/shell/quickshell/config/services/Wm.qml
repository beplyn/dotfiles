pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the shell asks of Hyprland outside the overview, which talks to
// Quickshell.Hyprland itself (overview/Overview.qml).
Singleton {
    id: root

    // for surfaces that follow focus (Panels.focusedScreen)
    readonly property string focusedOutput: Hyprland.focusedMonitor?.name ?? ""

    function quit() {
        Hyprland.dispatch("hl.dsp.exit()")
    }
}
