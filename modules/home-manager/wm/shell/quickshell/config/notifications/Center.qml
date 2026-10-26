import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Notification history, dropped from waybar's bell (right click there
// toggles do not disturb). Quick settings live in the control center.
Panel {
    id: root

    name: "notifications"
    align: Qt.AlignRight
    cardWidth: 420

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Theme.text
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 4
            font.bold: true
        }

        IconButton {
            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
            filled: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        IconButton {
            label: "Clear all"
            visible: Notifs.count > 0
            onClicked: Notifs.clearAll()
        }
    }

    ListView {
        Layout.fillWidth: true
        // Grow with the list, then scroll.
        Layout.preferredHeight: Notifs.count === 0 ? 120 : Math.min(contentHeight, 560)
        clip: true
        spacing: 6
        model: ScriptModel {
            values: Notifs.list
        }
        delegate: Card {
            required property var modelData
            notif: modelData
            width: ListView.view.width
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.fast; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            visible: Notifs.count === 0
            text: Icons.bell + "  All caught up"
            color: Theme.overlay
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 1
        }
    }
}
