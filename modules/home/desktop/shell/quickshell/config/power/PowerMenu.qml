import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Session menu: arrows/Tab move, Enter or a letter picks, Escape cancels.
// Log out, reboot and shut down ask twice.
PanelWindow {
    id: root

    readonly property bool open: Panels.current === "power"

    property int current: 0
    // Index waiting for its second press, or -1.
    property int armed: -1

    readonly property var actions: [
        { key: "L", icon: Icons.lock, label: "Lock", verb: "lock", tint: Theme.accent, confirm: false, act: () => Session.lock() },
        { key: "S", icon: Icons.sleep, label: "Sleep", verb: "sleep", tint: Theme.blue, confirm: false, act: () => Session.suspend() },
        { key: "E", icon: Icons.exit, label: "Log out", verb: "log out", tint: Theme.yellow, confirm: true, act: () => Session.logout() },
        { key: "R", icon: Icons.reboot, label: "Reboot", verb: "reboot", tint: Theme.orange, confirm: true, act: () => Session.reboot() },
        { key: "P", icon: Icons.power, label: "Shut down", verb: "shut down", tint: Theme.red, confirm: true, act: () => Session.poweroff() }
    ]

    function select(i) {
        current = (i + actions.length) % actions.length
        if (armed !== current) armed = -1
    }

    function choose(i) {
        select(i)
        const a = actions[i]
        if (a.confirm && armed !== i) {
            armed = i
            return
        }
        Panels.close()
        a.act()
    }

    onOpenChanged: {
        current = 0
        armed = -1
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

    WlrLayershell.namespace: "haku-power"
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
        Keys.onEscapePressed: Panels.close()
        Keys.onLeftPressed: root.select(root.current - 1)
        Keys.onRightPressed: root.select(root.current + 1)
        Keys.onTabPressed: root.select(root.current + 1)
        Keys.onBacktabPressed: root.select(root.current - 1)
        Keys.onReturnPressed: root.choose(root.current)
        Keys.onEnterPressed: root.choose(root.current)
        Keys.onSpacePressed: root.choose(root.current)
        Keys.onPressed: e => {
            const i = root.actions.findIndex(a => a.key === e.text.toUpperCase())
            if (i < 0) return
            root.choose(i)
            e.accepted = true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 28

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.94
            Behavior on opacity {
                NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
            }

            // --- header ---------------------------------------------------
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Goodbye, " + (Quickshell.env("USER") ?? "")
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 10
                    font.bold: true
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Icons.uptime + "  up " + Stats.uptime
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                }
            }

            // --- actions --------------------------------------------------
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool selected: root.current === index
                        readonly property bool isArmed: root.armed === index
                        readonly property color tint: modelData.tint

                        implicitWidth: 132
                        implicitHeight: 148
                        radius: Theme.radius
                        color: isArmed ? tint
                            : selected ? Theme.alpha(tint, 0.18)
                            : Theme.cardColor
                        border.width: selected ? 2 : 1
                        border.color: selected ? tint : Theme.cardBorder
                        scale: mouse.pressed ? 0.96 : selected ? 1.04 : 1

                        Behavior on color {
                            ColorAnimation { duration: Theme.fast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Theme.fast }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            // glyph in a soft disc
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 64
                                implicitHeight: 64
                                radius: 32
                                color: tile.isArmed ? Theme.alpha(Theme.background, 0.2)
                                    : Theme.alpha(tile.tint, tile.selected ? 0.25 : 0.12)

                                Behavior on color {
                                    ColorAnimation { duration: Theme.fast }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: tile.modelData.icon
                                    color: tile.isArmed ? Theme.background : tile.tint
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize + 14
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.isArmed ? "Confirm?" : tile.modelData.label
                                color: tile.isArmed ? Theme.background : Theme.foreground
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize + 1
                                font.bold: true
                            }

                            // key hint
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 22
                                implicitHeight: 20
                                radius: 6
                                color: tile.isArmed ? Theme.alpha(Theme.background, 0.2) : Theme.well

                                Text {
                                    anchors.centerIn: parent
                                    text: tile.modelData.key
                                    color: tile.isArmed ? Theme.background : Theme.subtext
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.select(tile.index)
                            onClicked: root.choose(tile.index)
                        }
                    }
                }
            }

            // --- hint -----------------------------------------------------
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.armed >= 0
                    ? "Press again to " + root.actions[root.armed].verb + "  ·  Esc to cancel"
                    : "←/→ select  ·  Enter or letter to pick  ·  Esc to cancel"
                color: root.armed >= 0 ? root.actions[root.armed].tint : Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 1
            }
        }
    }
}
