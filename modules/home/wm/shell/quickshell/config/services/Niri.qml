pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Workspace model fed by `niri msg -j event-stream`, adapted from
// hakuspace's Hikai NiriBackend.
Singleton {
    id: root

    property var workspaces: []
    property var windows: ({})

    readonly property string focusedOutput: workspaces.find(ws => ws.is_focused)?.output ?? ""

    // Workspaces on one output, ordered as niri shows them.
    function workspacesOn(output) {
        return workspaces
            .filter(ws => ws.output === output)
            .sort((a, b) => a.idx - b.idx)
    }

    function windowCount(workspaceId) {
        let n = 0
        for (const id in windows)
            if (windows[id].workspace_id === workspaceId) n++
        return n
    }

    function action(...args) {
        Quickshell.execDetached([Theme.bin.niri, "msg", "action", ...args])
    }

    // Indices are output-local, so focus the output first.
    function focus(ws) {
        Quickshell.execDetached(["sh", "-c",
            '"$0" msg action focus-monitor "$1" && "$0" msg action focus-workspace "$2"',
            Theme.bin.niri, ws.output, String(ws.idx)])
    }

    function patch(id, fields) {
        workspaces = workspaces.map(ws => ws.id === id ? Object.assign({}, ws, fields) : ws)
    }

    function handle(event) {
        if (event.WorkspacesChanged) {
            workspaces = event.WorkspacesChanged.workspaces
        } else if (event.WorkspaceActivated) {
            const ev = event.WorkspaceActivated
            const target = workspaces.find(ws => ws.id === ev.id)
            if (!target) return
            workspaces = workspaces.map(ws => {
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
        } else if (event.WindowOpenedOrChanged) {
            const w = event.WindowOpenedOrChanged.window
            const map = Object.assign({}, windows)
            map[w.id] = w
            windows = map
        } else if (event.WindowClosed) {
            const map = Object.assign({}, windows)
            delete map[event.WindowClosed.id]
            windows = map
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
