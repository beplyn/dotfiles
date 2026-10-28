pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Front end for the `record` script (wl-screenrec). Recordings started
// here are owned by `session`; ones started elsewhere are picked up by
// polling `record status`.
Singleton {
    id: root

    readonly property bool recording: session.running || external
    property bool external: false
    property string elapsed: "00:00"
    property bool menuOpen: false
    property var sources: []

    readonly property var modes: [
        { id: "system-audio", label: Icons.record + "  Only sound" },
        { id: "mic-system", label: Icons.mic + "  Microphone and sound" },
        { id: "no-audio", label: Icons.noSound + "  No sound" }
    ]

    function start(mode, source) {
        if (recording) return
        menuOpen = false
        const args = [Theme.bin.record, "start", mode]
        if (source) args.push("--source", source)
        session.command = args
        seconds = 0
        elapsed = "00:00"
        session.running = true
    }

    function stop() {
        Quickshell.execDetached([Theme.bin.record, "stop"])
    }

    // Like hakuspace's record.sh with no args: stop, else open the picker.
    function toggle() {
        if (recording) stop()
        else openMenu()
    }

    function openMenu() {
        listSources.running = true
        menuOpen = true
    }

    property int seconds: 0

    // Waybar's custom/recorder shows the timer; re-run its `status` on change.
    onRecordingChanged: Theme.signalBar(Theme.signals.recorder)
    onElapsedChanged: Theme.signalBar(Theme.signals.recorder)

    Process {
        id: session
        onExited: root.elapsed = "00:00"
    }

    Timer {
        interval: 1000
        repeat: true
        running: session.running
        onTriggered: {
            root.seconds++
            const pad = n => String(n).padStart(2, "0")
            root.elapsed = pad(Math.floor(root.seconds / 60)) + ":" + pad(root.seconds % 60)
        }
    }

    Process {
        id: status
        running: true
        command: [Theme.bin.record, "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text)
                    root.external = s.recording && !session.running
                    if (root.external && s.elapsed) root.elapsed = s.elapsed
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.external
        onTriggered: status.running = true
    }

    Process {
        id: listSources
        command: [Theme.bin.record, "list-sources", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sources = JSON.parse(text).map(s => s.id)
                } catch (e) {
                    root.sources = []
                }
            }
        }
    }

    IpcHandler {
        target: "recorder"
        function toggle(): void { root.toggle() }
        function stop(): void { root.stop() }
        function start(mode: string): void { root.start(mode, "") }

        // JSON for waybar's custom/recorder; empty text hides the module.
        function status(): string {
            return JSON.stringify(root.recording ? { text: root.elapsed, class: "recording" } : { text: "" })
        }
    }
}
