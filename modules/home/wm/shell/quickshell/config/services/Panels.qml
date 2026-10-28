pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Which panel is open: "control", "dashboard", "notifications", one of
// the monitors ("cpu", "memory", "temperature") or "".
// One at a time, so opening one closes the other. Waybar and the niri
// binds drive it with `qs -c haku ipc call panels toggle <name>`.
Singleton {
    id: root

    property string current: ""

    // The output niri has focused, for surfaces that follow focus (OSD).
    readonly property ShellScreen focusedScreen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0] ?? null

    // Pinned when a panel opens, so it doesn't jump outputs while open.
    property ShellScreen screen: focusedScreen

    function open(name) {
        screen = focusedScreen
        current = name
    }

    function close() {
        current = ""
    }

    function toggle(name) {
        if (current === name) close()
        else open(name)
    }

    IpcHandler {
        target: "panels"
        function toggle(name: string): void { root.toggle(name) }
        function open(name: string): void { root.open(name) }
        function close(): void { root.close() }
    }
}
