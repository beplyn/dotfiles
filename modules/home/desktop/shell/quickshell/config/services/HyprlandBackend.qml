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

    // For the overview: [{ address, title, appId, workspace, x, y, width,
    // height, floating, focused, toplevel }] in global logical pixels;
    // toplevel is the Wayland handle a ScreencopyView captures. Geometry is
    // from `j/clients`, so only as fresh as the last refreshWindows().
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

    // while set, geometry follows every window event
    property bool trackWindows: false

    function refreshWindows() {
        Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland
        enabled: root.trackWindows
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode", "fullscreen"].includes(event.name))
                root.refreshWindows()
        }
    }

    // Hyprland's address: selector wants the 0x Quickshell drops
    function address(a) {
        return a.startsWith("0x") ? a : "0x" + a
    }

    function dispatch(lua, legacy) {
        Hyprland.dispatch(Hyprland.usingLua ? lua : legacy)
    }

    // activate() speaks the Lua config's dispatch; an empty workspace has
    // no object to activate, so that one goes by id
    function focusWorkspace(id) {
        const ws = Hyprland.workspaces.values.find(ws => ws.id === id)
        if (ws) ws.activate()
        else dispatch(`hl.dsp.focus({ workspace = "${id}", on_current_monitor = true })`, `workspace ${id}`)
    }

    function focusWindow(addr) {
        dispatch(`hl.dsp.focus({ window = "address:${addr}" })`, `focuswindow address:${addr}`)
    }

    // the window alone; focus stays where it is
    function moveWindow(addr, id) {
        dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${addr}" })`,
            `movetoworkspacesilent ${id},address:${addr}`)
    }

    function quit() {
        dispatch("hl.dsp.exit()", "exit")
    }
}
