import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Top-right popup stack. A popup leaves the stack when its timeout runs
// out (paused while hovered) but stays in the control center.
PanelWindow {
    id: root

    screen: Quickshell.screens[0] ?? null
    visible: Notifs.popups.length > 0
    anchors {
        top: true
        right: true
    }
    margins {
        top: 6
        right: 6
    }
    implicitWidth: 420
    implicitHeight: stack.implicitHeight
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "haku-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        width: parent.width
        spacing: 6

        Repeater {
            // ScriptModel keeps existing cards (and their timers) when one is added.
            model: ScriptModel {
                values: Notifs.popups.slice(0, 5)
            }

            Card {
                id: card
                required property var modelData
                notif: modelData
                popup: true
                width: stack.width

                Timer {
                    interval: Notifs.timeoutFor(card.notif)
                    running: interval > 0 && !card.hovered
                    onTriggered: Notifs.hidePopup(card.notif.id)
                }
            }
        }
    }
}
