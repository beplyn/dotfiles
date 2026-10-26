import QtQuick
import QtQuick.Layouts
import qs.services

// Quick-settings toggle: glyph, title and a status line, filled with the
// accent while active. The mouse event is passed on for right clicks.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    signal clicked(var mouse)

    implicitHeight: 58
    radius: Theme.innerRadius
    color: active ? Theme.accent : mouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.well
    scale: mouse.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.fast }
    }
    Behavior on scale {
        NumberAnimation { duration: 120 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12

        Text {
            text: root.icon
            color: root.active ? Theme.base : Theme.accent
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.active ? Theme.base : Theme.text
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: root.active ? Theme.alpha(Theme.base, 0.75) : Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 1
            }
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
