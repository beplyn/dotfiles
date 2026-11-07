import QtQuick
import Quickshell
import Quickshell.Io

// Wm's niri backend, fed by `niri msg -j event-stream`, adapted from
// hakuspace's Hikai NiriBackend. Loaded by Wm only; use Wm instead.
Scope {
    id: root

    // niri's own workspace and window objects, kept as the stream sends them.
    property var rawWorkspaces: []
    property var windows: ({})
    property var focusedWindowId: null

    readonly property var workspaces: rawWorkspaces
        .map(ws => ({
            id: ws.id,
            idx: ws.idx,
            name: ws.name ?? "",
            output: ws.output ?? "",
            isFocused: ws.is_focused,
            isActive: ws.is_active,
            isUrgent: ws.is_urgent ?? false
        }))
        .sort((a, b) => a.output.localeCompare(b.output) || a.idx - b.idx)
    readonly property string activeWindowTitle: windows[focusedWindowId]?.title ?? ""
    readonly property string focusedOutput: rawWorkspaces.find(ws => ws.is_focused)?.output ?? ""

    function action(...args) {
        Quickshell.execDetached([Theme.bin.niri, "msg", "action", ...args])
    }

    // focus-workspace takes an output-local index, so focus the output first.
    function focusWorkspace(id) {
        const ws = rawWorkspaces.find(ws => ws.id === id)
        if (!ws) return
        Quickshell.execDetached(["sh", "-c",
            '"$0" msg action focus-monitor "$1" && "$0" msg action focus-workspace "$2"',
            Theme.bin.niri, ws.output, String(ws.idx)])
    }

    function quit() {
        action("quit", "--skip-confirmation")
    }

    function patch(id, fields) {
        rawWorkspaces = rawWorkspaces.map(ws => ws.id === id ? Object.assign({}, ws, fields) : ws)
    }

    function handle(event) {
        if (event.WorkspacesChanged) {
            rawWorkspaces = event.WorkspacesChanged.workspaces
        } else if (event.WorkspaceActivated) {
            const ev = event.WorkspaceActivated
            const target = rawWorkspaces.find(ws => ws.id === ev.id)
            if (!target) return
            rawWorkspaces = rawWorkspaces.map(ws => {
                const next = Object.assign({}, ws)
                if (ws.output === target.output) next.is_active = ws.id === ev.id
                if (ev.focused) next.is_focused = ws.id === ev.id
                return next
            })
        } else if (event.WorkspaceUrgencyChanged) {
            patch(event.WorkspaceUrgencyChanged.id, { is_urgent: event.WorkspaceUrgencyChanged.urgent })
        } else if (event.WorkspaceActiveWindowChanged) {
            const ev = event.WorkspaceActiveWindowChanged
            patch(ev.workspace_id, { active_window_id: ev.active_window_id })
        } else if (event.WindowsChanged) {
            const map = {}
            for (const w of event.WindowsChanged.windows) map[w.id] = w
            windows = map
            focusedWindowId = event.WindowsChanged.windows.find(w => w.is_focused)?.id ?? null
        } else if (event.WindowOpenedOrChanged) {
            const w = event.WindowOpenedOrChanged.window
            const map = Object.assign({}, windows)
            map[w.id] = w
            windows = map
            if (w.is_focused) focusedWindowId = w.id
        } else if (event.WindowClosed) {
            const map = Object.assign({}, windows)
            delete map[event.WindowClosed.id]
            windows = map
            if (focusedWindowId === event.WindowClosed.id) focusedWindowId = null
        } else if (event.WindowFocusChanged) {
            focusedWindowId = event.WindowFocusChanged.id ?? null
        }
    }

    Process {
        id: stream
        running: true
        command: [Theme.bin.niri, "msg", "-j", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handle(JSON.parse(line))
                } catch (e) {}
            }
        }
        // Reconnect if niri restarts or the stream drops.
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: stream.running = true
    }
}
