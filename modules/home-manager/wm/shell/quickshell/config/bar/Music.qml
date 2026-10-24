import QtQuick
import Quickshell.Io
import qs.services
import qs.widgets

// group/music: "[ 󰝚 ]" drawer revealing a cava visualizer and the mpris
// title. cava only runs while the drawer is open and something plays.
Drawer {
    id: root

    readonly property var player: Session.player
    readonly property var bars: ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    property string spectrum: ""

    icon: "[ " + Icons.music + " ]"
    tooltip: "Music visualizer"
    solidHead: false
    revealLeft: false

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        visible: cava.running && root.spectrum !== ""
        text: root.spectrum
        hoverWidth: 0
    }

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.player !== null
        readonly property string title: {
            const t = root.player?.trackTitle ?? ""
            return Theme.plain(t.length > 25 ? t.slice(0, 24) + "…" : t)
        }
        text: root.player?.isPlaying ? Icons.playing + " / " + title : Icons.paused + " / <i>" + title + "</i>"
        tooltip: Theme.plain((root.player?.trackArtist ?? "") + (root.player?.trackAlbum ? " — " + root.player.trackAlbum : ""))
        onClicked: m => {
            if (m.button === Qt.RightButton) root.player?.next()
            else if (m.button === Qt.MiddleButton) root.player?.previous()
            else root.player?.togglePlaying()
        }
        onScrolled: step => step > 0 ? root.player?.next() : root.player?.previous()
    }

    Process {
        id: cava
        running: root.expanded && (root.player?.isPlaying ?? false)
        command: [Theme.bin.cava, "-p", Theme.bin.cavaConfig]
        stdout: SplitParser {
            onRead: line => {
                root.spectrum = line.split(";")
                    .filter(v => v !== "")
                    .map(v => root.bars[Math.min(7, Number(v))])
                    .join("")
            }
        }
        onRunningChanged: if (!running) root.spectrum = ""
    }
}
