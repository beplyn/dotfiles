import QtQuick
import QtQuick.Layouts
import qs.services

// Square glyph button, optionally with a label beside the glyph.
// `tint` colors the hover and the `filled` state (e.g. red for power).
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color tint: Theme.accent
    property bool filled: false
    property int size: 36
    signal clicked(var mouse)

    readonly property bool hovered: mouse.containsMouse
    readonly property color fg: filled ? Theme.base : hovered ? tint : Theme.text

    implicitWidth: label === "" ? size : row.implicitWidth + 24
    implicitHeight: size
    radius: Theme.innerRadius
    color: filled ? tint : hovered ? Theme.alpha(tint, 0.2) : Theme.well
    scale: mouse.pressed ? 0.95 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.fast }
    }
    Behavior on scale {
        NumberAnimation { duration: 120 }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.icon
            color: root.fg
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 3
        }
        Text {
            visible: root.label !== ""
            text: root.label
            color: root.fg
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize
            font.bold: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
    }
}
