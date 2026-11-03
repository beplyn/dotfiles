import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// sway's and mango's stand-in for niri's hotkey overlay: the titled binds
// from their binds.nix, by section. Any key or click closes it, as in niri.
PanelWindow {
    id: root

    readonly property bool open: Panels.current === "hotkeys"

    // keysyms as niri prints them
    readonly property var names: ({
        Mod4: "Super",
        space: "Space",
        Return: "Enter",
        bracketleft: "[",
        bracketright: "]",
        minus: "-",
        equal: "=",
        slash: "/",
        grave: "`",
        comma: ",",
        period: "."
    })

    function keys(combo) {
        return combo.split("+").map(k => names[k] ?? (k.length === 1 ? k.toUpperCase() : k))
    }

    // Sections into two columns, each to the shorter one, flattened into
    // grid cells: a header spanning both, then keys and title per bind.
    readonly property var columns: {
        const cols = [[], []]
        const rows = [0, 0]
        for (const s of Theme.hotkeys[Wm.currentCompositor] ?? []) {
            const c = rows[1] < rows[0] ? 1 : 0
            rows[c] += s.binds.length + 1
            cols[c].push({ kind: "header", text: s.name })
            for (const b of s.binds) {
                cols[c].push({ kind: "keys", keys: keys(b.key) })
                cols[c].push({ kind: "title", text: b.title })
            }
        }
        return cols.filter(c => c.length > 0)
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

    WlrLayershell.namespace: "haku-hotkeys"
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

        // Modifiers alone stay, so Mod+/ can toggle it shut.
        focus: root.open
        Keys.onPressed: e => {
            if ([Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Meta, Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt].includes(e.key)) return
            Panels.close()
            e.accepted = true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: content.implicitWidth + Theme.pad * 4
            height: content.implicitHeight + Theme.pad * 4
            radius: Theme.radius
            color: Theme.cardColor
            border.color: Theme.cardBorder
            border.width: 1

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.94
            Behavior on opacity {
                NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
            }

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                spacing: 18

                Text {
                    text: "Important Hotkeys"
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 6
                    font.bold: true
                }

                RowLayout {
                    spacing: 40

                    Repeater {
                        model: root.columns

                        GridLayout {
                            id: column
                            required property var modelData
                            Layout.alignment: Qt.AlignTop
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 6

                            Repeater {
                                model: column.modelData

                                Loader {
                                    id: cell
                                    required property var modelData
                                    required property int index
                                    readonly property bool header: modelData.kind === "header"

                                    Layout.columnSpan: header ? 2 : 1
                                    Layout.alignment: modelData.kind === "keys" ? Qt.AlignRight | Qt.AlignVCenter : Qt.AlignLeft | Qt.AlignVCenter
                                    Layout.topMargin: header && index > 0 ? 12 : 0
                                    sourceComponent: header ? headerCell : modelData.kind === "keys" ? keysCell : titleCell

                                    Component {
                                        id: headerCell
                                        Text {
                                            text: cell.modelData.text
                                            color: Theme.accent
                                            font.family: Theme.font
                                            font.pointSize: Theme.popupFontSize - 1
                                            font.bold: true
                                        }
                                    }

                                    Component {
                                        id: titleCell
                                        Text {
                                            text: cell.modelData.text
                                            color: Theme.foreground
                                            font.family: Theme.font
                                            font.pointSize: Theme.popupFontSize
                                        }
                                    }

                                    Component {
                                        id: keysCell
                                        Row {
                                            spacing: 4

                                            Repeater {
                                                model: cell.modelData.keys

                                                // key cap
                                                Rectangle {
                                                    required property string modelData
                                                    implicitWidth: Math.max(cap.implicitWidth + 12, implicitHeight)
                                                    implicitHeight: cap.implicitHeight + 6
                                                    radius: 6
                                                    color: Theme.well
                                                    border.color: Theme.cardBorder
                                                    border.width: 1

                                                    Text {
                                                        id: cap
                                                        anchors.centerIn: parent
                                                        text: parent.modelData
                                                        color: Theme.subtext
                                                        font.family: Theme.font
                                                        font.pointSize: Theme.popupFontSize - 2
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Any key to close"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 1
                }
            }
        }
    }
}
