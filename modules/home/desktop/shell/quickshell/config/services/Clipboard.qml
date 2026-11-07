pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// cliphist through `clipboard` (shell/clipboard): the history wl-paste keeps
// and the pins, a cliphist db of their own. Both load when the panel opens;
// deletes show at once, the reload after each edit confirms them.
Singleton {
    id: root

    // [{ store, id, preview, kind, ... }], newest first
    property var history: []
    property var pinned: []

    // previews of the pins, to mark pinned entries in the history
    readonly property var pinnedPreviews: {
        const m = {}
        for (const e of pinned) m[e.preview] = e.id
        return m
    }

    function isPinned(entry) {
        return entry.store === "pinned" || pinnedPreviews[entry.preview] !== undefined
    }

    // What an entry looks like from its preview; images carry their size.
    function classify(preview) {
        const img = preview.match(/^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/)
        if (img) return { kind: "image", size: img[1], ext: img[2], width: +img[3], height: +img[4] }
        if (/^\[\[ binary data .* \]\]$/.test(preview)) return { kind: "binary" }
        if (/^#(?:[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(preview)) return { kind: "color" }
        if (/^(?:https?|ftp|file):\/\/\S+$/i.test(preview)) return { kind: "link" }
        if (/^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i.test(preview)) return { kind: "email" }
        if (/^(?:~|\.{1,2})?\/\S*$/.test(preview)) return { kind: "path" }
        if (/^[-+]?\d[\d.,_ ]*$/.test(preview)) return { kind: "number" }
        if (/[{};]|=>|::|^\$ |^\s*(?:import|from|const|let|def|fn|function|class|#include)\b/.test(preview)) return { kind: "code" }
        return { kind: "text" }
    }

    function parse(store, text) {
        const out = []
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab < 0) continue
            const preview = line.slice(tab + 1)
            out.push(Object.assign({ store: store, id: line.slice(0, tab), key: store + "/" + line.slice(0, tab), preview: preview }, classify(preview)))
        }
        return out
    }

    function refresh() {
        listHistory.running = true
        listPinned.running = true
    }

    function copy(entry) {
        run(["copy", entry.store, entry.id].concat(entry.kind === "image" ? ["image/" + entry.ext] : []))
    }

    function remove(entry) {
        drop(entry)
        run(["delete", entry.store, entry.id])
    }

    function togglePin(entry) {
        const pin = entry.store === "pinned" ? entry.id : pinnedPreviews[entry.preview]
        if (pin !== undefined) {
            pinned = pinned.filter(e => e.id !== pin)
            run(["delete", "pinned", pin])
        } else {
            run(["pin", entry.store, entry.id])
        }
    }

    function wipe(store) {
        if (store === "pinned") pinned = []
        else history = []
        run(["wipe", store])
    }

    function drop(entry) {
        if (entry.store === "pinned") pinned = pinned.filter(e => e.id !== entry.id)
        else history = history.filter(e => e.id !== entry.id)
    }

    // One `clipboard` call at a time, in order, then a reload.
    property var queue: []

    function run(args) {
        queue = queue.concat([args])
        next()
    }

    function next() {
        if (action.running || queue.length === 0) return
        action.command = [Theme.bin.clipboard].concat(queue[0])
        queue = queue.slice(1)
        action.running = true
    }

    Process {
        id: action
        onExited: {
            if (root.queue.length > 0) Qt.callLater(root.next)
            else root.refresh()
        }
    }

    Process {
        id: listHistory
        command: [Theme.bin.clipboard, "list", "history"]
        stdout: StdioCollector {
            onStreamFinished: root.history = root.parse("history", text)
        }
    }

    Process {
        id: listPinned
        command: [Theme.bin.clipboard, "list", "pinned"]
        stdout: StdioCollector {
            onStreamFinished: root.pinned = root.parse("pinned", text)
        }
    }
}
