import QtQuick
import Quickshell
import Quickshell.Hyprland

// Wm's Hyprland backend: workspaces, outputs and the window title from
// Quickshell.Hyprland. Loaded by Wm only; use Wm instead.
Scope {
    id: root

    // special workspaces (the scratchpad) have negative ids
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0)
        .map(ws => ({
            id: ws.id,
            idx: ws.id,
            name: ws.name,
            output: ws.monitor?.name ?? "",
            isFocused: ws.focused,
            isActive: ws.active,
            isUrgent: ws.urgent
        }))
        .sort((a, b) => a.output.localeCompare(b.output) || a.idx - b.idx)
    readonly property string activeWindowTitle: Hyprland.activeToplevel?.title ?? ""
    readonly property string focusedOutput: Hyprland.focusedMonitor?.name ?? ""

    // activate() speaks the Lua config's dispatch
    function focusWorkspace(id) {
        Hyprland.workspaces.values.find(ws => ws.id === id)?.activate()
    }

    function quit() {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit")
    }
}
