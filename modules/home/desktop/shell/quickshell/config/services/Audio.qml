pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property int percent: Math.round(volume * 100)

    // Pipewire only fills in audio state for bound nodes.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }

    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function step(delta) {
        setVolume(volume + delta)
    }

    function setMicVolume(v) {
        if (source?.audio) {
            source.audio.muted = false
            source.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    function toggleMicMute() {
        if (source?.audio) source.audio.muted = !source.audio.muted
    }
}
