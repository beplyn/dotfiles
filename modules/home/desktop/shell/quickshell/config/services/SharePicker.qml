pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// xdph's screen share picker (share-picker.sh): it opens the picker over IPC
// with a fifo, and the choice goes back down the fifo in xdph's own syntax,
// "screen:<output>" or "window:<handle>", "r" in front to hand out a restore
// token. An empty answer is a cancel.
Singleton {
    id: root

    property string fifo: ""
    readonly property bool pending: fifo !== ""
    // remember the choice: the app may restore it without asking next time
    property bool remember: false

    // [{ handle, appId, title, toplevel }] from XDPH_WINDOW_SHARING_LIST,
    // "handle[HC>]class[HT>]title[HE>]address[HA>]" per window; the address
    // finds the window again for its preview
    property var windows: []

    function parse(list) {
        return list.split("[HA>]").filter(e => e !== "").map(e => {
            const [handle, rest] = e.split("[HC>]")
            const [appId, rest2] = (rest ?? "").split("[HT>]")
            const [title, address] = (rest2 ?? "").split("[HE>]")
            const addr = Number(address)
            return {
                handle: handle,
                appId: appId ?? "",
                title: title ?? "",
                toplevel: Hyprland.toplevels.values.find(t => parseInt(t.address, 16) === addr)?.wayland ?? null
            }
        })
    }

    function open(path, list) {
        // a new request replaces one left hanging
        if (pending) answer("")
        windows = parse(list)
        remember = false
        fifo = path
        Panels.open("share")
    }

    function answer(selection) {
        if (!pending) return
        reply.text = selection === "" ? "" : (remember ? "r" : "") + "/" + selection
        reply.command = [Theme.bin.tee, fifo]
        reply.running = true
        fifo = ""
        if (Panels.current === "share") Panels.close()
    }

    function shareScreen(name) { answer("screen:" + name) }
    function shareWindow(handle) { answer("window:" + handle) }

    // closing the panel any other way (click outside, Escape) cancels
    Connections {
        target: Panels
        function onCurrentChanged() {
            if (Panels.current !== "share" && root.pending) root.answer("")
        }
    }

    Process {
        id: reply
        property string text: ""
        stdinEnabled: true
        onStarted: {
            write(text + "\n")
            stdinEnabled = false
        }
        onExited: stdinEnabled = true
    }

    IpcHandler {
        target: "sharepicker"
        function pick(fifo: string, windows: string): void { root.open(fifo, windows) }
    }
}
