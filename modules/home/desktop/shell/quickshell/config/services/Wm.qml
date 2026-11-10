pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland behind one interface, from Quickshell.Hyprland; nothing else in
// the shell talks to its IPC. Workspaces, the active window's title, the
// focused output, and the windows behind the overview (overview/Overview.qml).
Singleton {
    id: root

    // [{ id, idx, name, output, isFocused, isActive, isUrgent }], by output
    // then idx; special workspaces (the scratchpad) have negative ids
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

    function workspacesOn(output) {
        return workspaces.filter(ws => ws.output === output)
    }

    // For the overview: [{ address, title, appId, workspace, x, y, width,
    // height, floating, focused, toplevel }] in global logical pixels;
    // toplevel is the Wayland handle a ScreencopyView captures. Geometry is
    // from `j/clients`, so only as fresh as the last refresh.
    readonly property var windows: Hyprland.toplevels.values
        .filter(t => (t.workspace?.id ?? 0) > 0 && t.lastIpcObject?.at !== undefined)
        .map(t => {
            const ipc = t.lastIpcObject
            return {
                address: address(t.address),
                title: t.title,
                appId: ipc.class ?? "",
                workspace: t.workspace.id,
                x: ipc.at[0],
                y: ipc.at[1],
                width: ipc.size?.[0] ?? 0,
                height: ipc.size?.[1] ?? 0,
                floating: ipc.floating ?? false,
                focused: t.activated,
                toplevel: t.wayland
            }
        })

    // while on, geometry follows every window event
    property bool tracking: false

    function trackWindows(on) {
        tracking = on
        if (on) Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland
        enabled: root.tracking
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode", "fullscreen"].includes(event.name))
                Hyprland.refreshToplevels()
        }
    }

    // Hyprland's address: selector wants the 0x Quickshell drops
    function address(a) {
        return a.startsWith("0x") ? a : "0x" + a
    }

    // activate() speaks the Lua config's dispatch; an empty workspace has
    // no object to activate, so that one goes by id
    function focusWorkspace(id) {
        const ws = Hyprland.workspaces.values.find(ws => ws.id === id)
        if (ws) ws.activate()
        else Hyprland.dispatch(`hl.dsp.focus({ workspace = "${id}", on_current_monitor = true })`)
    }

    function focusWindow(addr) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`)
    }

    // the window alone; focus stays where it is
    function moveWindow(addr, id) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${addr}" })`)
    }

    function quit() {
        Hyprland.dispatch("hl.dsp.exit()")
    }
}
