import QtQuick
import QtQuick.Layouts
import qs.services

// Square glyph button, optionally with a label beside the glyph.
// `tint` colors the hover and the `filled` state (e.g. red for power).
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color tint: Theme.activeColor
    property bool filled: false
    property int size: 36
    signal clicked(var mouse)

    readonly property bool hovered: mouse.containsMouse
    readonly property bool lit: filled || hovered
    readonly property color fg: lit ? tint : Theme.foreground

    implicitWidth: label === "" ? size : row.implicitWidth + Theme.gapXl
    implicitHeight: size
    radius: Theme.innerRadius
    color: lit ? Theme.alpha(tint, 0.14) : "transparent"
    border.width: Theme.borderWidth
    border.color: lit ? tint : Theme.idleBorder
    scale: mouse.pressed ? 0.98 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.fast }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.fast }
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.quick }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.gapSm

        Text {
            text: root.icon
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: Theme.iconBox
            color: root.fg
            font.family: Theme.font
            font.pointSize: Theme.iconMd
        }
        Text {
            visible: root.label !== ""
            text: root.label
            color: root.fg
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize
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
