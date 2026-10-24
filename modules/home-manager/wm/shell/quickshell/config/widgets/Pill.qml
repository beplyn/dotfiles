import QtQuick
import qs.services

// One waybar module from hakuspace's "top" style: accent text that flips
// to accent-on-base and widens on hover. `solid` is the inverted look of
// the logo and drawer heads.
Rectangle {
    id: root

    property string text: ""
    property string tooltip: ""
    property bool solid: false
    property color fg: Theme.accent
    property color idle: "transparent"
    property int padding: 10
    // Width the module grows to while hovered (waybar's hover min-width).
    property int hoverWidth: solid ? 40 : 50

    readonly property bool hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal scrolled(int step)

    implicitHeight: Theme.barHeight - 10
    implicitWidth: Math.max(label.implicitWidth + padding * 2, hovered ? hoverWidth : 20)
    radius: solid ? 4 : Theme.pillRadius
    color: solid ? (hovered ? Theme.base : Theme.accent) : (hovered ? Theme.accent : idle)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 600
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easing
        }
    }
    Behavior on color {
        ColorAnimation { duration: 250 }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        textFormat: Text.StyledText
        color: root.solid
            ? (root.hovered ? Theme.accent : Theme.base)
            : (root.hovered ? Theme.base : root.fg)
        font.family: Theme.font
        font.pointSize: Theme.fontSize
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
        onWheel: w => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }

    Tooltip {
        target: root
        text: root.tooltip
        show: root.hovered
    }
}
