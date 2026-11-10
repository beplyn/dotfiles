import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services

// Mod+W: the theme's recoloured wallpapers (~/.cache/wallpapers, from
// quickshell/wallpaper.nix) on a carousel, the picked one crossfading in
// full behind it. h/l, the arrows, Tab or the wheel cycle, Enter or a click
// on the middle one sets it, R lands on a random one, Escape closes.
PanelWindow {
    id: root

    readonly property bool open: Panels.current === "wallpapers"
    readonly property string thumbs: Theme.wallpapers + "/thumbs"

    // the one showing, so the carousel opens on it
    property string current: ""

    function fileAt(i) {
        return i >= 0 && i < folder.count ? folder.get(i, "fileName") : ""
    }

    function label(file) {
        const stem = file.replace(/\.[^.]*$/, "")
        return stem === "stylix" ? "palette" : stem.replace(/^wallhaven-/, "")
    }

    function step(by) {
        if (folder.count === 0) return
        view.currentIndex = (view.currentIndex + by + folder.count) % folder.count
    }

    function apply() {
        const file = fileAt(view.currentIndex)
        if (file === "") return
        Quickshell.execDetached([Theme.bin.wallpaper, "set", Theme.wallpapers + "/" + file])
        current = file
        Panels.close()
    }

    function land() {
        const i = Array.from({ length: folder.count }, (_, i) => i).find(i => fileAt(i) === current)
        if (i !== undefined) view.positionViewAtIndex(i, PathView.Center)
        view.currentIndex = i ?? 0
        preview.show(fileAt(view.currentIndex))
    }

    onOpenChanged: {
        if (!open) return
        // seen before the answer comes back; land() moves on from there
        land()
        which.running = true
    }

    FolderListModel {
        id: folder
        folder: "file://" + root.thumbs
        nameFilters: ["*.jpg"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: if (root.open) root.land()
    }

    Process {
        id: which
        command: [Theme.bin.wallpaper, "current"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.current = text.trim().split("/").pop()
                if (root.open) root.land()
            }
        }
    }

    screen: Panels.screen
    visible: open || backdrop.opacity > 0
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: -1
    color: "transparent"

    WlrLayershell.namespace: "haku-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: root.open ? backdrop : null
    }

    Item {
        id: backdrop
        anchors.fill: parent
        opacity: root.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }

        focus: root.open
        Keys.onPressed: e => {
            const k = e.key
            if (k === Qt.Key_Escape) Panels.close()
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.apply()
            else if (k === Qt.Key_H || k === Qt.Key_Left || k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab) root.step(-1)
            else if (k === Qt.Key_L || k === Qt.Key_Right || k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_Tab) root.step(1)
            else if (k === Qt.Key_R && folder.count > 1)
                root.step(1 + Math.floor(Math.random() * (folder.count - 1)))
            else return
            e.accepted = true
        }

        // the picked one in full, crossfading between two images
        Item {
            id: preview
            anchors.fill: parent

            property Image shown: null
            property Image pending: null

            function show(file) {
                if (file === "") return
                const next = shown === a ? b : a
                const src = "file://" + Theme.wallpapers + "/" + file
                if (shown && shown.source.toString() === src) return
                pending = next
                if (next.source.toString() === src && next.status === Image.Ready) shown = next
                else next.source = src
            }

            // a burst of steps loads only where it stops
            Timer {
                id: settle
                interval: 110
                onTriggered: preview.show(root.fileAt(view.currentIndex))
            }

            Image {
                id: a
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize: Qt.size(root.width, root.height)
                opacity: preview.shown === a ? 1 : 0
                scale: preview.shown === a ? 1 : 1.04
                onStatusChanged: if (status === Image.Ready && preview.pending === a) preview.shown = a
                Behavior on opacity {
                    NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: Theme.slow * 2; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                }
            }

            Image {
                id: b
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize: Qt.size(root.width, root.height)
                opacity: preview.shown === b ? 1 : 0
                scale: preview.shown === b ? 1 : 1.04
                onStatusChanged: if (status === Image.Ready && preview.pending === b) preview.shown = b
                Behavior on opacity {
                    NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: Theme.slow * 2; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                }
            }
        }

        // darker towards the carousel, so it reads over any picture
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(Theme.background, 0.15) }
                GradientStop { position: 0.55; color: Theme.alpha(Theme.background, 0.35) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.background, 0.85) }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        WheelHandler {
            target: null
            onWheel: e => root.step(e.angleDelta.y < 0 || e.angleDelta.x < 0 ? 1 : -1)
        }

        Item {
            id: strip

            readonly property real thumbWidth: Math.min(root.width * 0.2, 640)
            readonly property real thumbHeight: thumbWidth * 9 / 16

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.height * 0.08
            height: thumbHeight + info.height + Theme.gap * 4

            // rises in after the backdrop
            opacity: root.open ? 1 : 0
            transform: Translate {
                y: root.open ? 0 : 60
                Behavior on y {
                    NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic }
            }

            PathView {
                id: view

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: strip.thumbHeight + Theme.gap * 2

                model: folder
                pathItemCount: Math.min(5, folder.count)
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: Theme.slow
                snapMode: PathView.SnapToItem
                // keys, the wheel and clicks drive it, not flicks
                interactive: false

                onCurrentIndexChanged: if (root.open) settle.restart()

                path: Path {
                    startX: 0
                    startY: view.height / 2

                    PathAttribute { name: "itemScale"; value: 0.6 }
                    PathAttribute { name: "itemOpacity"; value: 0 }
                    PathAttribute { name: "itemZ"; value: 0 }
                    PathLine { x: view.width / 2; y: view.height / 2 }
                    PathAttribute { name: "itemScale"; value: 1 }
                    PathAttribute { name: "itemOpacity"; value: 1 }
                    PathAttribute { name: "itemZ"; value: 10 }
                    PathLine { x: view.width; y: view.height / 2 }
                    PathAttribute { name: "itemScale"; value: 0.6 }
                    PathAttribute { name: "itemOpacity"; value: 0 }
                    PathAttribute { name: "itemZ"; value: 0 }
                }

                delegate: Item {
                    id: card

                    required property int index
                    required property string fileName
                    readonly property bool middle: PathView.isCurrentItem
                    readonly property bool showing: fileName === root.current

                    width: strip.thumbWidth
                    height: strip.thumbHeight
                    scale: PathView.itemScale ?? 1
                    opacity: PathView.itemOpacity ?? 1
                    z: PathView.itemZ ?? 0

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: Theme.well
                        border.width: card.middle ? 3 : 1
                        border.color: card.middle ? Theme.accent : Theme.cardBorder

                        Behavior on border.color {
                            ColorAnimation { duration: Theme.fast }
                        }

                        Image {
                            anchors.fill: parent
                            source: "file://" + root.thumbs + "/" + card.fileName
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(640, 360)
                            // the sides sit back in the dark
                            opacity: card.middle ? 1 : 0.7
                            Behavior on opacity {
                                NumberAnimation { duration: Theme.fast }
                            }
                        }
                    }

                    // the one on screen now
                    Rectangle {
                        visible: card.showing
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.accent
                        border.width: 2
                        border.color: Theme.alpha(Theme.background, 0.7)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.middle) root.apply()
                            else view.currentIndex = card.index
                        }
                    }
                }
            }

            Column {
                id: info
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: view.bottom
                anchors.topMargin: Theme.gap
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: folder.count === 0 ? "no wallpapers in " + Theme.wallpapers
                        : root.label(root.fileAt(view.currentIndex))
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 2
                    font.bold: true
                    style: Text.Outline
                    styleColor: Theme.alpha(Theme.background, 0.5)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: folder.count > 0
                    text: (view.currentIndex + 1) + " / " + folder.count + "    ←→ pick · enter set · r random · esc"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.fontSize
                }
            }
        }
    }
}
