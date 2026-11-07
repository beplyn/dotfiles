pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Stay awake: a logind idle lock held while active, which hypridle honours
// on every compositor, so neither the lock nor the screen-off timeouts fire.
// Gone with the shell, as waybar's idle_inhibitor was with the bar.
Singleton {
    id: root

    property bool active: false

    function toggle() {
        active = !active
    }

    Process {
        running: root.active
        command: [Theme.bin.systemdInhibit, "--what=idle", "--who=Quickshell", "--why=Stay awake", "--mode=block", Theme.bin.sleep, "infinity"]
        // the lock went away by itself (e.g. killed): show it
        onExited: root.active = false
    }

    IpcHandler {
        target: "awake"
        function toggle(): void { root.toggle() }
        function status(): string { return root.active ? "on" : "off" }
    }
}
