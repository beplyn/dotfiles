pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The launcher's apps, from the .desktop files Quickshell reads, with the pins
// and how often each was launched kept in launcher.json. Launches go through
// `systemd-run --scope`, so apps outlive a quickshell restart.
Singleton {
    id: root

    // ids, in pin order
    property var pins: []
    // id -> launches, for the order with no search
    property var counts: ({})
    property bool loaded: false

    // [{ key, kind: "app", entry, name, ... }], most launched first
    readonly property var apps: {
        const out = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            out.push({
                key: "app/" + e.id,
                kind: "app",
                id: e.id,
                entry: e,
                name: e.name,
                generic: e.genericName,
                comment: e.comment,
                icon: e.icon,
                // the words a search looks through, lowercased once
                hay: [e.name, e.genericName, e.comment, e.id].concat(Array.from(e.keywords), Array.from(e.categories)).join(" ").toLowerCase()
            })
        }
        return out.sort((a, b) => (counts[b.id] ?? 0) - (counts[a.id] ?? 0) || a.name.localeCompare(b.name))
    }

    readonly property var pinned: pins.map(id => apps.find(a => a.id === id)).filter(a => a !== undefined)

    function isPinned(app) {
        return pins.includes(app.id)
    }

    function togglePin(app) {
        pins = isPinned(app) ? pins.filter(id => id !== app.id) : pins.concat([app.id])
        save()
    }

    // an app or one of its actions, in a terminal when it asks for one
    function launch(app, action) {
        const e = app.entry
        let cmd = Array.from((action ?? e).command)
        if (cmd.length === 0) return
        if (e.runInTerminal) cmd = [Theme.bin.terminal, "start", "--"].concat(cmd)
        if (e.workingDirectory !== "") cmd = [Theme.bin.env, "-C", e.workingDirectory].concat(cmd)
        spawn(cmd)
        const c = Object.assign({}, counts)
        c[app.id] = (c[app.id] ?? 0) + 1
        counts = c
        save()
    }

    // a line for the shell, from the Run row
    function run(line) {
        spawn(["sh", "-c", line])
    }

    function web(query) {
        spawn([Theme.bin.xdgOpen, "https://www.google.com/search?q=" + encodeURIComponent(query)])
    }

    function copy(text) {
        Quickshell.execDetached([Theme.bin.wlCopy, "--", text])
    }

    function spawn(cmd) {
        Quickshell.execDetached([Theme.bin.systemdRun, "--user", "--scope", "--collect", "--quiet", "--"].concat(cmd))
    }

    function save() {
        if (loaded) store.setText(JSON.stringify({ pins: pins, counts: counts }))
    }

    FileView {
        id: store
        path: Quickshell.statePath("launcher.json")
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text())
                root.pins = data.pins ?? []
                root.counts = data.counts ?? {}
            } catch (e) {}
            root.loaded = true
        }
        // first run: nothing yet
        onLoadFailed: root.loaded = true
    }
}
