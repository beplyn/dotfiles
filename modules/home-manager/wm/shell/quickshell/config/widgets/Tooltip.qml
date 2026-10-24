import QtQuick
import Quickshell
import qs.services

// Waybar-style tooltip under `target` after a short hover delay.
PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool show: false

    anchor.item: target
    anchor.rect.y: target.height + 6
    anchor.rect.x: target.width / 2
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Bottom

    visible: delay.ready && show && text !== ""
    color: "transparent"
    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight

    onShowChanged: {
        delay.ready = false
        if (show) delay.restart()
    }

    Timer {
        id: delay
        property bool ready: false
        interval: 500
        onTriggered: ready = true
    }

    Rectangle {
        id: box
        implicitWidth: label.implicitWidth + 20
        implicitHeight: label.implicitHeight + 16
        radius: Theme.radius
        color: Theme.base
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.accent
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize
            textFormat: Text.StyledText
        }
    }
}
