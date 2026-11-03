pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The running compositor behind one interface; nothing else in the shell
// talks to WM IPC. A backend (NiriBackend.qml, SwayBackend.qml, or
// GenericBackend.qml over Wayland protocols) provides workspaces,
// activeWindowTitle, focusedOutput, focusWorkspace(id) and quit(); adding
// one is a case in `wm name` and a Loader below.
Singleton {
    id: root

    // from `wm name`, as the scripts see it; empty until it answers
    property string currentCompositor: ""

    readonly property var backend: niri.item ?? sway.item ?? generic.item

    // [{ id, idx, name, output, isFocused, isActive, isUrgent }], by output then idx.
    readonly property var workspaces: backend?.workspaces ?? []
    readonly property string activeWindowTitle: backend?.activeWindowTitle ?? ""
    readonly property string focusedOutput: backend?.focusedOutput ?? ""

    function workspacesOn(output) {
        return workspaces.filter(ws => ws.output === output)
    }

    function focusWorkspace(id) { backend?.focusWorkspace(id) }
    function quit() { backend?.quit() }

    Process {
        running: true
        command: [Theme.bin.wm, "name"]
        stdout: StdioCollector {
            onStreamFinished: root.currentCompositor = text.trim() || "generic"
        }
    }

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

    Loader {
        id: generic
        active: root.currentCompositor !== "" && !niri.active && !sway.active
        sourceComponent: GenericBackend {}
    }
}
