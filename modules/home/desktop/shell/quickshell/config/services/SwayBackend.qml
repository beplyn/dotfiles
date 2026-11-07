import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3

// Wm's sway backend: workspaces and outputs from Quickshell.I3, the window
// title from window events. Loaded by Wm only; use Wm instead.
Scope {
    id: root

    property string title: ""

    readonly property var workspaces: I3.workspaces.values
        .map(ws => ({
            id: ws.id,
            idx: ws.number,
            name: ws.name,
            output: ws.monitor?.name ?? "",
            isFocused: ws.focused,
            isActive: ws.active,
            isUrgent: ws.urgent
        }))
        .sort((a, b) => a.output.localeCompare(b.output) || a.idx - b.idx)
    readonly property string activeWindowTitle: title
    readonly property string focusedOutput: I3.focusedMonitor?.name ?? ""

    // workspaces are addressed by name; a JSON string is a quoted sway string.
    function focusWorkspace(id) {
        const ws = I3.workspaces.values.find(ws => ws.id === id)
        if (ws) I3.dispatch(`workspace ${JSON.stringify(ws.name)}`)
    }

    function quit() {
        I3.dispatch("exit")
    }

    function focusedNode(node) {
        if (node.focused && (node.type === "con" || node.type === "floating_con")) return node
        for (const child of [...(node.nodes ?? []), ...(node.floating_nodes ?? [])]) {
            const found = focusedNode(child)
            if (found) return found
        }
        return null
    }

    I3IpcListener {
        subscriptions: ["window", "workspace"]
        onIpcEvent: event => {
            let data
            try {
                data = JSON.parse(event.data)
            } catch (e) {
                return
            }
            if (event.type === "window") {
                const con = data.container
                if (data.change === "focus" || (data.change === "title" && con.focused)) root.title = con.name ?? ""
                else if (data.change === "close" && con.focused) root.title = ""
            } else if (event.type === "workspace" && data.change === "focus") {
                // a focused workspace with windows sends its own window focus event
                if ((data.current?.focus ?? []).length === 0) root.title = ""
            }
        }
    }

    // The title as it stands when the shell starts.
    Process {
        running: true
        command: [Theme.bin.swaymsg, "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.title = root.focusedNode(JSON.parse(text))?.name ?? ""
                } catch (e) {}
            }
        }
    }
}
