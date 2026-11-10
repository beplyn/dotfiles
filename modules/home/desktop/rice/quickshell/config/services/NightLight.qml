pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Warm screen through hyprsunset, whose own schedule and Mod+Alt+N change
// it too, so its temperature is read back while the control center is open.
Singleton {
    id: root

    // hyprsunset's evening temperature (hyprland/services.nix)
    readonly property int temperature: 4000
    // hyprsunset's no-op; `identity` would keep reporting the last temperature
    readonly property int neutral: 6000

    property bool active: false
    Component.onCompleted: query.running = true

    function toggle() {
        active = !active
        Quickshell.execDetached([Theme.bin.hyprctl, "hyprsunset", "temperature", String(active ? temperature : neutral)])
    }

    Process {
        id: query
        command: [Theme.bin.hyprctl, "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = Number(text.trim())
                if (t > 0) root.active = t < root.neutral
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: Panels.current === "control"
        onTriggered: query.running = true
    }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle() }
        function status(): string { return root.active ? "on" : "off" }
    }
}
