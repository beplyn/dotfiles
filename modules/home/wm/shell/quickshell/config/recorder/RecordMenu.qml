import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Replaces hakuspace's rofi record picker: choose a mode, then a
// microphone for "mic-system". Arrows/Enter to pick, Escape to cancel.
PanelWindow {
    id: root

    screen: Quickshell.screens[0] ?? null
    visible: Recorder.menuOpen
    implicitWidth: 380
    implicitHeight: box.implicitHeight
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "haku-record-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property bool pickingSource: false
    property int current: 0
    readonly property var entries: pickingSource
        ? Recorder.sources.map(s => ({ label: s }))
        : Recorder.modes

    onVisibleChanged: {
        pickingSource = false
        current = 0
    }

    function choose(i) {
        if (i < 0 || i >= entries.length) return
        if (pickingSource) {
            Recorder.start("mic-system", entries[i].label)
        } else if (entries[i].id === "mic-system") {
            pickingSource = true
            current = 0
        } else {
            Recorder.start(entries[i].id, "")
        }
    }

    Rectangle {
        id: box
        width: parent.width
        implicitHeight: col.implicitHeight + 24
        radius: Theme.radius
        color: Theme.alpha(Theme.background, 0.92)
        border.color: Theme.alpha(Theme.accent, 0.5)

        focus: true
        Keys.onEscapePressed: Recorder.menuOpen = false
        Keys.onUpPressed: root.current = (root.current - 1 + root.entries.length) % root.entries.length
        Keys.onDownPressed: root.current = (root.current + 1) % root.entries.length
        Keys.onReturnPressed: root.choose(root.current)
        Keys.onEnterPressed: root.choose(root.current)

        Column {
            id: col
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 4

            Text {
                text: root.pickingSource ? "Select mic/source:" : "Select mode:"
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
                bottomPadding: 6
            }

            Text {
                visible: root.pickingSource && root.entries.length === 0
                text: "No microphone found"
                color: Theme.red
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
            }

            Repeater {
                model: root.entries

                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.current

                    width: col.width
                    height: label.implicitHeight + 16
                    radius: 8
                    color: selected ? Theme.accent : "transparent"

                    Text {
                        id: label
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        width: parent.width - 24
                        elide: Text.ElideMiddle
                        text: modelData.label
                        color: parent.selected ? Theme.background : Theme.accent
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 2
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = index
                        onClicked: root.choose(index)
                    }
                }
            }
        }
    }
}
