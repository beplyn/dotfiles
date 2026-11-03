pragma Singleton
import QtQuick
import Quickshell

// The running compositor behind one interface; nothing else in the shell
// talks to WM IPC. A backend (NiriBackend.qml, SwayBackend.qml) provides
// workspaces, activeWindowTitle, focusedOutput, focusWorkspace(id) and
// quit(); adding one is a check in currentCompositor and a Loader below.
Singleton {
    id: root

    // niri first: niri-session unsets its socket on exit, sway's doesn't.
    readonly property string currentCompositor: {
        if (Quickshell.env("NIRI_SOCKET")) return "niri"
        if (Quickshell.env("SWAYSOCK")) return "sway"
        const desktops = String(Quickshell.env("XDG_CURRENT_DESKTOP") ?? "").toLowerCase().split(":")
        if (desktops.includes("niri")) return "niri"
        if (desktops.includes("sway")) return "sway"
        return "fallback"
    }

    // null under the fallback, which leaves everything empty.
    readonly property var backend: niri.item ?? sway.item

    // [{ id, idx, name, output, isFocused, isActive, isUrgent }], by output then idx.
    readonly property var workspaces: backend?.workspaces ?? []
    readonly property string activeWindowTitle: backend?.activeWindowTitle ?? ""
    readonly property string focusedOutput: backend?.focusedOutput ?? ""

    function workspacesOn(output) {
        return workspaces.filter(ws => ws.output === output)
    }

    function focusWorkspace(id) { backend?.focusWorkspace(id) }
    function quit() { backend?.quit() }

    // Loader, not LazyLoader: that one waits for a reload, which this
    // lazily created singleton can miss.
    Loader {
        id: niri
        active: root.currentCompositor === "niri"
        sourceComponent: NiriBackend {}
    }

    Loader {
        id: sway
        active: root.currentCompositor === "sway"
        sourceComponent: SwayBackend {}
    }
}
