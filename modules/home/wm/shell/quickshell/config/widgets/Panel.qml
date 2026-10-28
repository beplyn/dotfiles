import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// One floating card dropped from waybar. The window covers the output
// (below waybar's exclusive zone) only to catch clicks outside the card;
// those, and Escape, close it. niri blurs exactly the card through
// ext-background-effect. The window stays mapped until the card has
// faded out, and takes no input while it does.
PanelWindow {
    id: root

    // Key in Panels.current.
    required property string name
    // Where the card hangs from waybar: Qt.AlignLeft, AlignHCenter or AlignRight.
    property int align: Qt.AlignRight
    property int cardWidth: 400
    property alias spacing: body.spacing
    default property alias content: body.data

    readonly property bool open: Panels.current === name

    screen: Panels.screen
    visible: open || card.opacity > 0
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "haku-" + name
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: root.open ? catcher : null
    }
    BackgroundEffect.blurRegion: Region {
        item: root.open ? card : null
        radius: Theme.radius
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        onClicked: Panels.close()
    }

    Rectangle {
        id: card

        x: root.align === Qt.AlignLeft ? Theme.gap
            : root.align === Qt.AlignRight ? parent.width - width - Theme.gap
            : Math.round((parent.width - width) / 2)
        y: Theme.gap + (root.open ? 0 : -16)
        width: root.cardWidth
        height: Math.min(body.implicitHeight + Theme.pad * 2, parent.height - Theme.gap * 2)

        radius: Theme.radius
        color: Theme.cardColor
        border.color: Theme.cardBorder
        border.width: 1
        clip: true

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.98
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
        }
        Behavior on height {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }

        focus: root.open
        Keys.onEscapePressed: Panels.close()

        // Keeps clicks on the card from reaching the catcher.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: 12
        }
    }
}
