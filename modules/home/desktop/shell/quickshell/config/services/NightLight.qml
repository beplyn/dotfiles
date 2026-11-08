pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Warm screen. On Hyprland it drives hyprsunset, whose own schedule and
// Mod+Alt+N change it too, so its temperature is read back while the
// control center is open. Elsewhere a held gammastep, gone with the shell.
Singleton {
    id: root

    // hyprsunset's evening temperature (hyprland/services.nix)
    readonly property int temperature: 4000
    // hyprsunset's no-op; `identity` would keep reporting the last temperature
    readonly property int neutral: 6000
    readonly property bool hyprland: Wm.currentCompositor === "hyprland"

    property bool hyprActive: false
    property bool gammaActive: false
    readonly property bool active: hyprland ? hyprActive : gammaActive
    onHyprlandChanged: if (hyprland) query.running = true

    function toggle() {
        if (!hyprland) {
            gammaActive = !gammaActive
            return
        }
        hyprActive = !hyprActive
        Quickshell.execDetached([Theme.bin.hyprctl, "hyprsunset", "temperature", String(hyprActive ? temperature : neutral)])
    }

    Process {
        id: query
        command: [Theme.bin.hyprctl, "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = Number(text.trim())
                if (t > 0) root.hyprActive = t < root.neutral
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.hyprland && Panels.current === "control"
        onTriggered: query.running = true
    }

    Process {
        running: root.gammaActive && !root.hyprland
        command: [Theme.bin.gammastep, "-m", "wayland", "-P", "-O", String(root.temperature)]
        // gave up (e.g. no gamma control): show it
        onExited: root.gammaActive = false
    }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle() }
        function status(): string { return root.active ? "on" : "off" }
    }
}
