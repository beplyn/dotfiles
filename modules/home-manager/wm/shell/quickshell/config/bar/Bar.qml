import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.widgets

// hakuspace's "top" waybar layout:
//   logo · workspaces · music  |  recorder · clock  |  monitor · settings · tray · notifications
PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.alpha(Theme.base, 0.7)

    WlrLayershell.namespace: "haku-bar"
    WlrLayershell.layer: WlrLayer.Top

    IdleInhibitor {
        window: bar
        enabled: Session.idleInhibited
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            solid: true
            text: Icons.logo
            tooltip: "Have a nice day!"
            onClicked: Session.launcher()
        }

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
            output: bar.screen?.name ?? ""
        }

        Music {
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 2

        RecorderChip {
            anchors.verticalCenter: parent.verticalCenter
        }

        Clock {
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Monitor {
            anchors.verticalCenter: parent.verticalCenter
        }

        SettingsGroup {
            anchors.verticalCenter: parent.verticalCenter
        }

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            window: bar
        }

        // custom/notification, with swaync-client's click / right-click.
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            readonly property string badge: Notifs.count > 0 ? "<sup><font color='" + Theme.red + "'>" + Icons.dot + "</font></sup>" : ""
            text: (Notifs.dnd ? (Notifs.count > 0 ? Icons.bellOff : Icons.dnd) : Icons.bell) + badge
            tooltip: Notifs.count + " notification" + (Notifs.count === 1 ? "" : "s") + (Notifs.dnd ? " · do not disturb" : "")
            onClicked: m => m.button === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : Notifs.toggleCenter()
        }
    }
}
