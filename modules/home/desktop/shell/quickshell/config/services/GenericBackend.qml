import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.WindowManager

// Wm's backend for any other compositor, over Wayland protocols:
// ext-workspace for workspaces, foreign-toplevel for the active window.
// Either list stays empty where the compositor lacks the protocol.
// Loaded by Wm only; use Wm instead.
Scope {
    id: root

    readonly property var active: ToplevelManager.activeToplevel

    readonly property var workspaces: WindowManager.windowsets
        .filter(ws => ws.shouldDisplay)
        .map((ws, i) => {
            const output = ws.projection?.screens[0]?.name ?? ""
            return {
                id: ws.id,
                idx: ws.coordinates[0] ?? i,
                name: ws.name,
                output: output,
                isFocused: ws.active && output === focusedOutput,
                isActive: ws.active,
                isUrgent: ws.urgent
            }
        })
        .sort((a, b) => a.output.localeCompare(b.output) || a.idx - b.idx)
    readonly property string activeWindowTitle: active?.title ?? ""
    // no protocol for output focus; the active window's output stands in
    readonly property string focusedOutput: active?.screens[0]?.name ?? ""

    function focusWorkspace(id) {
        const ws = WindowManager.windowsets.find(ws => ws.id === id)
        if (ws?.canActivate) ws.activate()
    }

    // the graphical session, even from this user service
    function quit() {
        Quickshell.execDetached([Theme.bin.loginctl, "terminate-session", "auto"])
    }
}
