import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.widgets

// MPRIS player over a cava spectrum (cava only runs while open and playing).
Rectangle {
    id: root

    // Whether the dashboard is showing; gates cava and the position poll.
    property bool active: false

    readonly property var player: Session.player
    readonly property bool playing: player?.isPlaying ?? false
    property var spectrum: []

    implicitHeight: 128
    radius: Theme.innerRadius
    color: Theme.well
    clip: true

    function time(secs) {
        const s = Math.max(0, Math.floor(secs))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // --- spectrum ----------------------------------------------------------
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        opacity: 0.18

        Repeater {
            model: root.spectrum.length

            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: root.width / root.spectrum.length
                height: root.height * (root.spectrum[index] ?? 0) / 7
                color: Theme.accent
                radius: 2

                Behavior on height {
                    NumberAnimation { duration: 60 }
                }
            }
        }
    }

    Process {
        id: cava
        running: root.active && root.playing
        command: [Theme.bin.cava, "-p", Theme.bin.cavaConfig]
        stdout: SplitParser {
            onRead: line => root.spectrum = line.split(";").filter(v => v !== "").map(Number)
        }
        onRunningChanged: if (!running) root.spectrum = []
    }

    // MPRIS doesn't push position updates; ask for them while visible.
    Timer {
        running: root.active && root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    // --- nothing playing -----------------------------------------------------
    Text {
        anchors.centerIn: parent
        visible: root.player === null
        text: Icons.music + "  Nothing playing"
        color: Theme.overlay
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize + 1
    }

    // --- player --------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14
        visible: root.player !== null

        ClippingRectangle {
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            radius: Theme.innerRadius - 2
            color: Theme.surface

            Text {
                anchors.centerIn: parent
                text: Icons.music
                color: Theme.overlay
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 14
            }

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Unknown track"
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 2
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist || root.player?.identity || ""
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
            }

            Item { Layout.fillHeight: true }

            // Progress; click to seek where the player allows it.
            Item {
                Layout.fillWidth: true
                implicitHeight: 12
                visible: root.player?.lengthSupported ?? false

                Rectangle {
                    id: progress
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.alpha(Theme.surface, 0.9)

                    Rectangle {
                        width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent

                        Behavior on width {
                            NumberAnimation { duration: 1000 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canSeek ?? false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: m => root.player.position = m.x / width * root.player.length
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    visible: root.player?.lengthSupported ?? false
                    text: root.time(root.player?.position ?? 0) + " / " + root.time(root.player?.length ?? 0)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 1
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    size: 32
                    icon: Icons.previous
                    onClicked: root.player?.previous()
                }
                IconButton {
                    size: 32
                    icon: root.playing ? Icons.pause : Icons.play
                    filled: true
                    onClicked: root.player?.togglePlaying()
                }
                IconButton {
                    size: 32
                    icon: Icons.next
                    onClicked: root.player?.next()
                }
            }
        }
    }
}
