import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// The picked day's events from vcal (services/Events.qml). A click on one
// edits it in place; + adds one; the terminal button opens the day in the
// TUI.
ColumnLayout {
    id: root

    required property date day
    // Back to the list whenever this goes false (the dashboard closing).
    property bool active: true

    // undefined: the list; null: a new event; a row: editing that one
    property var editing: undefined
    readonly property bool isEditing: editing !== undefined
    readonly property var events: Events.on(day)

    function close() {
        editing = undefined
    }

    onDayChanged: close()
    onActiveChanged: if (!active) close()

    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: Events.key(root.day) === Events.key(Events.today) ? "Today" : Qt.formatDate(root.day, "dddd d MMMM")
            color: Theme.foreground
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 1
            font.bold: true
            elide: Text.ElideRight
        }
        IconButton {
            size: 28
            icon: Icons.terminal
            onClicked: Events.openTui(root.day)
        }
        IconButton {
            size: 28
            icon: Icons.plus
            tint: Theme.green
            filled: root.editing === null
            onClicked: root.editing = root.editing === null ? undefined : null
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Events.error !== "" && !root.isEditing
        text: Events.error
        color: Theme.red
        wrapMode: Text.Wrap
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
    }

    EventEditor {
        Layout.fillWidth: true
        visible: root.isEditing
        day: root.day
        event: root.editing ?? null
        open: root.isEditing
        onClosed: root.close()
    }

    Text {
        visible: !root.isEditing && root.events.length === 0
        text: Events.loaded ? "Nothing planned" : "Loading…"
        color: Theme.muted
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize
    }

    ListView {
        id: list
        Layout.fillWidth: true
        visible: !root.isEditing && root.events.length > 0
        implicitHeight: Math.min(contentHeight, 220)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.events

        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property var e: modelData
            readonly property bool past: Events.state(e) === "past" || Events.state(e) === "cancelled"

            width: list.width
            implicitHeight: line.implicitHeight + 10
            radius: Theme.innerRadius
            color: hover.hovered ? Theme.alpha(Theme.foreground, 0.08) : "transparent"

            Behavior on color {
                ColorAnimation { duration: Theme.fast }
            }

            RowLayout {
                id: line
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.fillHeight: true
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                    radius: 2
                    color: Events.color(row.e)
                }
                Text {
                    Layout.preferredWidth: 54
                    text: row.e.all_day ? "all day" : Qt.formatTime(new Date(row.e.start_ts * 1000), "HH:mm")
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 1
                }
                Text {
                    Layout.fillWidth: true
                    text: row.e.title
                    color: row.past ? Theme.muted : Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                    font.strikeout: row.e.status === "cancelled"
                    elide: Text.ElideRight
                }
                Text {
                    visible: row.e.recurring
                    text: Icons.repeat
                    color: Theme.blue
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 1
                }
                Text {
                    visible: (row.e.category ?? "") !== ""
                    text: row.e.category ?? ""
                    color: Theme.blue
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 2
                }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.editing = row.e
            }
        }
    }
}
