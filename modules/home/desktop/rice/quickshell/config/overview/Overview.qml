import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services

// Mod+Tab, in place of hyprtasking's grid: this monitor's ten Hyprland
// workspaces (hyprsplit's, workspaces.lua) with their windows drawn to scale
// from Hyprland's own geometry, live through hyprland-toplevel-export. Click a window to focus
// it, a workspace to go there; drag a window onto another to send it.
// hjkl, the arrows or the wheel pick, 1-0 jump, Enter goes, Escape or
// Mod+Tab closes. Tiles ripple in from the active one; hovering names a window.
PanelWindow {
    id: root

    readonly property bool open: Panels.current === "overview"
    readonly property int columns: 5
    readonly property int count: 10

    // this screen's Hyprland monitor; hyprsplit gives monitor i the ids
    // (i-1)*10+1 .. i*10
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property int active: Math.max(1, monitor?.activeWorkspace?.id ?? 1)
    readonly property int base: Math.floor((active - 1) / count) * count

    // the tile the keys move; starts on the active workspace
    property int selected: 0

    // [{ address, title, appId, workspace, x, y, width, height, floating,
    // focused, toplevel }] in global logical pixels; toplevel is the Wayland
    // handle a ScreencopyView captures. Geometry is from `j/clients`, so it
    // is refreshed on open and on every window event while open.
    readonly property var windows: Hyprland.toplevels.values
        // special workspaces (the scratchpad) have negative ids
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

    Connections {
        target: Hyprland
        enabled: root.open
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode", "fullscreen"].includes(event.name))
                Hyprland.refreshToplevels()
        }
    }

    onOpenChanged: {
        if (!open) return
        Hyprland.refreshToplevels()
        selected = active - base - 1
    }

    // Hyprland's address: selector wants the 0x Quickshell drops
    function address(a) {
        return a.startsWith("0x") ? a : "0x" + a
    }

    // activate() speaks the Lua config's dispatch; an empty workspace has
    // no object to activate, so that one goes by id
    function go(index) {
        const id = base + index + 1
        const ws = Hyprland.workspaces.values.find(ws => ws.id === id)
        if (ws) ws.activate()
        else Hyprland.dispatch(`hl.dsp.focus({ workspace = "${id}", on_current_monitor = true })`)
        Panels.close()
    }

    function focusWindow(addr) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`)
        Panels.close()
    }

    // the window alone; focus stays where it is
    function moveWindow(addr, id) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${addr}" })`)
    }

    function pick(index) {
        selected = Math.max(0, Math.min(count - 1, index))
    }

    function appIcon(appId) {
        const icon = DesktopEntries.heuristicLookup(appId)?.icon ?? ""
        if (icon === "") return ""
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, true)
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

    WlrLayershell.namespace: "haku-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: root.open ? backdrop : null
    }
    BackgroundEffect.blurRegion: Region {
        item: root.open ? backdrop : null
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.55)
        opacity: root.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }

        focus: root.open
        Keys.onPressed: e => {
            const k = e.key
            if (k === Qt.Key_Escape) Panels.close()
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.go(root.selected)
            else if (k === Qt.Key_H || k === Qt.Key_Left) root.pick(root.selected - 1)
            else if (k === Qt.Key_L || k === Qt.Key_Right) root.pick(root.selected + 1)
            else if (k === Qt.Key_K || k === Qt.Key_Up) root.pick(root.selected - root.columns)
            else if (k === Qt.Key_J || k === Qt.Key_Down) root.pick(root.selected + root.columns)
            else if (k === Qt.Key_Tab) root.pick((root.selected + 1) % root.count)
            else if (k === Qt.Key_Backtab) root.pick((root.selected + root.count - 1) % root.count)
            else if (k >= Qt.Key_1 && k <= Qt.Key_9) root.go(k - Qt.Key_1)
            else if (k === Qt.Key_0) root.go(9)
            else return
            e.accepted = true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        // the wheel walks the tiles like Tab, over them too
        WheelHandler {
            target: null
            onWheel: e => root.pick((root.selected + (e.angleDelta.y < 0 ? 1 : root.count - 1)) % root.count)
        }

        GridLayout {
            id: grid

            // the largest tiles, at the monitor's aspect, that fit 85% of it
            readonly property real aspect: root.width / Math.max(1, root.height)
            readonly property int rows: Math.ceil(root.count / root.columns)
            readonly property int spacing: Theme.gap * 3
            readonly property real tileWidth: Math.min(
                (root.width * 0.85 - spacing * (root.columns - 1)) / root.columns,
                (root.height * 0.85 - spacing * (rows - 1)) / rows * aspect)
            readonly property real tileHeight: tileWidth / aspect
            readonly property real ratio: tileWidth / Math.max(1, root.width)

            anchors.centerIn: parent
            columns: root.columns
            columnSpacing: spacing
            rowSpacing: spacing

            Repeater {
                id: tiles
                model: root.count

                Rectangle {
                    id: tile

                    required property int index
                    readonly property int workspace: root.base + index + 1
                    readonly property bool current: workspace === root.active
                    readonly property bool dropTarget: drag.containsDrag && drag.drag.source?.workspace !== workspace
                    readonly property var windows: root.windows
                        .filter(w => w.workspace === workspace)
                        // tiled first, floating on top; the focused one last
                        .sort((a, b) => (a.floating - b.floating) || (a.focused - b.focused))
                    readonly property bool picked: index === root.selected
                    // the window under the pointer, named at the bottom
                    property string hovered: ""

                    // tiles ripple in from the active workspace
                    property bool shown: false
                    Timer {
                        id: stagger
                        interval: {
                            const from = root.active - root.base - 1
                            const steps = Math.abs(Math.floor(tile.index / root.columns) - Math.floor(from / root.columns))
                                + Math.abs(tile.index % root.columns - from % root.columns)
                            return 1 + steps * 35
                        }
                        onTriggered: tile.shown = true
                    }
                    Connections {
                        target: root
                        function onOpenChanged() {
                            if (root.open) stagger.restart()
                            else {
                                stagger.stop()
                                tile.shown = false
                                tile.hovered = ""
                            }
                        }
                    }

                    Layout.preferredWidth: grid.tileWidth
                    Layout.preferredHeight: grid.tileHeight
                    radius: Theme.radius
                    color: picked ? Theme.alpha(Theme.surface, Math.min(1, Theme.glass + 0.15)) : Theme.cardColor
                    border.width: current || picked || dropTarget ? 2 : 1
                    border.color: dropTarget ? Theme.green
                        : picked ? Theme.accent
                        : current ? Theme.subtext
                        : Theme.cardBorder
                    clip: true

                    // the picked one lifts above its neighbours
                    z: picked ? 1 : 0
                    opacity: shown ? 1 : 0
                    scale: !shown ? 0.88 : picked ? 1.035 : 1
                    transform: Translate {
                        y: tile.shown ? 0 : 28
                        Behavior on y {
                            NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.fast }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.fast }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = tile.index
                        onClicked: root.go(tile.index)
                    }

                    DropArea {
                        id: drag
                        anchors.fill: parent
                        keys: ["haku-window"]
                        onDropped: e => {
                            const w = e.source.window
                            if (w && w.workspace !== tile.workspace) root.moveWindow(w.address, tile.workspace)
                        }
                    }

                    Repeater {
                        model: tile.windows

                        Item {
                            id: win

                            required property var modelData
                            readonly property var window: modelData
                            readonly property int workspace: modelData.workspace
                            readonly property real homeX: (modelData.x - (root.screen?.x ?? 0)) * grid.ratio
                            readonly property real homeY: (modelData.y - (root.screen?.y ?? 0)) * grid.ratio

                            x: homeX
                            y: homeY
                            width: Math.max(8, modelData.width * grid.ratio)
                            height: Math.max(8, modelData.height * grid.ratio)
                            z: grab.drag.active ? 10 : 0
                            // picked up, it lifts off the tile
                            scale: grab.drag.active ? 1.08 : 1
                            opacity: grab.drag.active ? 0.9 : 1
                            Behavior on scale {
                                NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                            }

                            Drag.active: grab.drag.active
                            Drag.keys: ["haku-window"]
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            // out of the tile's clip while it travels
                            states: State {
                                when: grab.drag.active
                                ParentChange {
                                    target: win
                                    parent: backdrop
                                }
                            }

                            Rectangle {
                                id: frame
                                anchors.fill: parent
                                radius: Theme.innerRadius
                                color: Theme.well
                                border.width: 1
                                border.width: grab.containsMouse ? 2 : 1
                                border.color: grab.containsMouse || win.modelData.focused ? Theme.accent : Theme.cardBorder
                                clip: true

                                Behavior on border.color {
                                    ColorAnimation { duration: Theme.fast }
                                }

                                ScreencopyView {
                                    id: shot
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    captureSource: root.open ? win.modelData.toplevel : null
                                    live: root.open
                                    constraintSize: Qt.size(width, height)
                                }

                                // until (or unless) the capture has a frame
                                Image {
                                    anchors.centerIn: parent
                                    visible: !shot.hasContent
                                    width: Math.min(parent.width, parent.height) * 0.45
                                    height: width
                                    sourceSize: Qt.size(width, height)
                                    source: root.appIcon(win.modelData.appId)
                                    asynchronous: true
                                }
                            }

                            MouseArea {
                                id: grab
                                anchors.fill: parent
                                drag.target: win
                                drag.threshold: 6
                                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                onEntered: {
                                    root.selected = tile.index
                                    tile.hovered = win.modelData.title
                                }
                                onExited: if (tile.hovered === win.modelData.title) tile.hovered = ""
                                hoverEnabled: true
                                onClicked: root.focusWindow(win.modelData.address)
                                onReleased: {
                                    if (!drag.active) return
                                    win.Drag.drop()
                                    win.x = Qt.binding(() => win.homeX)
                                    win.y = Qt.binding(() => win.homeY)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        text: String((tile.index + 1) % 10)
                        color: tile.current ? Theme.accent : Theme.subtext
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize
                        font.bold: true
                        style: Text.Outline
                        styleColor: Theme.alpha(Theme.background, 0.6)
                    }

                    // nothing here: the number, faint, in the middle
                    Text {
                        anchors.centerIn: parent
                        visible: tile.windows.length === 0
                        text: String((tile.index + 1) % 10)
                        color: Theme.alpha(tile.picked ? Theme.accent : Theme.subtext, 0.35)
                        font.family: Theme.font
                        font.pixelSize: tile.height * 0.32
                        font.bold: true
                    }

                    // the hovered window's title
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        width: Math.min(parent.width - 16, title.implicitWidth + 20)
                        height: title.implicitHeight + 8
                        radius: height / 2
                        color: Theme.alpha(Theme.background, 0.8)
                        opacity: tile.hovered !== "" ? 1 : 0
                        visible: opacity > 0
                        z: 5

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                        }

                        Text {
                            id: title
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.parent.width - 36)
                            text: tile.hovered
                            elide: Text.ElideRight
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.fontSize
                        }
                    }
                }
            }
        }
    }
}
