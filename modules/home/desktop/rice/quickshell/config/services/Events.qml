pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Events from vcal, the terminal calendar (calendar.nix), on the database
// it shares with the TUI. `vcal query --format json` covers the days the
// dashboard shows; it re-runs when `events.db.changed` moves (vcal touches
// it on every write, wherever from) and when the day rolls over. Writes go
// through `vcal add / edit / rm`, one at a time, then a reload.
Singleton {
    id: root

    readonly property string db: Theme.calendarDb
    readonly property string bin: Theme.bin.vcal

    // Days the dashboard asked for, [first, last); today is always added.
    property date first: addDays(today, -7)
    property date last: addDays(today, 35)

    // Occurrences as vcal prints them: { id, occurrence, title, description,
    // category, location, all_day, start, end, start_ts, end_ts, status,
    // recurring, modified }. All-day rows carry dates, `end` exclusive.
    property var events: []
    property bool loaded: false
    // vcal's last complaint, for the agenda; "" when all is well
    property string error: ""

    property date today: midnight(new Date())
    readonly property date now: clock.date

    // "yyyy-MM-dd" -> that day's rows, all-day first
    readonly property var byDay: {
        const m = {}
        for (const e of events) {
            let d, end
            if (e.all_day) {
                d = parseDate(e.start)
                end = parseDate(e.end)
            } else {
                d = midnight(new Date(e.start_ts * 1000))
                // a zero-length event still belongs to its day
                end = new Date(Math.max(e.end_ts, e.start_ts + 1) * 1000)
            }
            for (let i = 0; d < end && i < 62; i++) {
                const k = key(d)
                if (!m[k]) m[k] = []
                m[k].push(e)
                d = addDays(d, 1)
            }
        }
        for (const k in m)
            m[k].sort((a, b) => (b.all_day - a.all_day) || (a.start_ts - b.start_ts))
        return m
    }

    function on(date) {
        return byDay[key(date)] ?? []
    }

    readonly property var todayAgenda: on(today)

    // --- dates -----------------------------------------------------------

    function key(d) {
        return Qt.formatDate(d, "yyyy-MM-dd")
    }

    function midnight(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate())
    }

    function addDays(d, n) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n)
    }

    // "2026-11-10" in local time (Date parses bare ISO dates as UTC)
    function parseDate(s) {
        const p = s.split("-")
        return new Date(+p[0], +p[1] - 1, +p[2])
    }

    // How a row should look: "cancelled", "past", "soon" (within the hour),
    // "tentative" or "event".
    function state(e) {
        const t = now.getTime() / 1000
        if (e.status === "cancelled") return "cancelled"
        if (e.end_ts <= t) return "past"
        if (!e.all_day && e.start_ts > t && e.start_ts - t <= 3600) return "soon"
        if (e.status === "tentative") return "tentative"
        return "event"
    }

    function color(e) {
        switch (state(e)) {
        case "cancelled": return Theme.red
        case "past": return Theme.muted
        case "soon": return Theme.orange
        case "tentative": return Theme.yellow
        default: return Theme.green
        }
    }

    // --- reading -----------------------------------------------------------

    // The dashboard's grid moved: query those days.
    function show(from, to) {
        const a = midnight(from), b = midnight(to)
        if (a.getTime() === first.getTime() && b.getTime() === last.getTime()) return
        first = a
        last = b
        refresh()
    }

    property bool again: false

    function refresh() {
        if (bin === "" || db === "") return
        if (query.running) {
            again = true
            return
        }
        const from = first < today ? first : today
        const to = last > addDays(today, 1) ? last : addDays(today, 1)
        query.command = [bin, "--db", db, "query", "--from", key(from), "--to", key(addDays(to, -1)), "--format", "json"]
        query.running = true
    }

    // vcal's message without its "vcal: " prefix, last line first
    function complaint(err, code) {
        const lines = err.trim().split("\n").filter(l => l !== "" && !l.includes("wrote the default config"))
        const last = lines.length > 0 ? lines[lines.length - 1].replace(/^vcal: /, "") : ""
        return last !== "" ? last : "vcal exited with " + code
    }

    Call {
        id: query
        onDone: (code, out, err) => {
            if (code === 0) {
                // stdout only: notes on stderr never reach the parser
                try {
                    root.events = JSON.parse(out)
                    root.error = ""
                } catch (e) {
                    root.error = "couldn't read vcal's output"
                }
            } else {
                root.error = root.complaint(err, code)
            }
            root.loaded = true
            // the first query creates the sentinel; start following it
            if (!root.watching) sentinel.reload()
            if (root.again) {
                root.again = false
                root.refresh()
            }
        }
    }

    // --- writing -----------------------------------------------------------

    // Flags for the fields given; `--flag=value` so a leading "-" stays text.
    function flags(f) {
        const a = []
        const opt = (name, v) => { if (v !== undefined) a.push("--" + name + "=" + v) }
        opt("title", f.title)
        opt("start", f.start)
        if (f.end !== undefined && f.end !== "") {
            // "45m", "1h30m" or a bare number of minutes: a length, not a time
            if (/^(\d+[smhdw])+$|^\d+$/.test(f.end)) a.push("--duration=" + f.end)
            else a.push("--end=" + f.end)
        }
        opt("category", f.category)
        opt("location", f.location)
        opt("description", f.description)
        opt("rrule", f.rrule)
        return a
    }

    // f: { title, start, end, allDay, category, location, description, rrule }
    // done(ok, message) when vcal has answered.
    function add(f, done) {
        const a = ["add"].concat(flags(f))
        if (f.allDay) a.push("--all-day")
        // an empty rule means a single event; vcal reads "" as no rule anyway
        run(a, done)
    }

    // Only the fields in f change. `occurrence` (from the row) limits the
    // change to that one occurrence; leave it out for the whole series.
    function edit(e, f, occurrence, done) {
        const a = ["edit", e.id].concat(flags(f))
        if (occurrence !== undefined && occurrence !== null) a.push("--occurrence=" + occurrence)
        else if (f.allDay === true) a.push("--all-day")
        else if (f.allDay === false) a.push("--timed")
        run(a, done)
    }

    function remove(e, occurrence, done) {
        const a = ["rm", e.id]
        if (occurrence !== undefined && occurrence !== null) a.push("--occurrence=" + occurrence)
        run(a, done)
    }

    // The TUI on that day, in a terminal (calendar.nix builds the argv).
    function openTui(date) {
        Quickshell.execDetached(Theme.calendarOpen.concat(["--date", key(date)]))
    }

    // One vcal call at a time, in order.
    property var queue: []

    function run(args, done) {
        queue = queue.concat([{ args: [bin, "--db", db].concat(args), done: done }])
        next()
    }

    property var current: null

    function next() {
        if (action.running || queue.length === 0) return
        current = queue[0]
        queue = queue.slice(1)
        action.command = current.args
        action.running = true
    }

    Call {
        id: action
        onDone: (code, out, err) => {
            const job = root.current
            root.current = null
            const ok = code === 0
            const message = ok ? "" : root.complaint(err, code)
            if (!ok) root.error = message
            if (job && job.done) job.done(ok, message)
            if (root.queue.length > 0) Qt.callLater(root.next)
            else root.refresh()
        }
    }

    // --- following changes -------------------------------------------------

    property bool watching: false

    FileView {
        id: sentinel
        path: root.db === "" ? "" : root.db + ".changed"
        watchChanges: true
        printErrors: false
        onLoaded: root.watching = true
        // not there until vcal first opens the database; the next query retries
        onLoadFailed: root.watching = false
        onFileChanged: {
            reload()
            debounce.restart()
        }
    }

    // a burst of writes (an import, a batch move) is one reload
    Timer {
        id: debounce
        interval: 150
        onTriggered: root.refresh()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: {
            const t = root.midnight(date)
            if (t.getTime() !== root.today.getTime()) {
                root.today = t
                root.refresh()
            }
        }
    }

    Component.onCompleted: refresh()

    // A Process that reports once stdout, stderr and the exit code are all
    // in, whatever order they arrive.
    component Call: Process {
        id: call

        signal done(int code, string out, string err)

        property int code: -1
        property int seen: 0

        function finish() {
            if (++seen < 3) return
            seen = 0
            done(code, out.text, err.text)
        }

        onStarted: seen = 0
        stdout: StdioCollector {
            id: out
            onStreamFinished: call.finish()
        }
        stderr: StdioCollector {
            id: err
            onStreamFinished: call.finish()
        }
        onExited: exitCode => {
            call.code = exitCode
            call.finish()
        }
    }
}
