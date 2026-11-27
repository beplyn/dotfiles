import QtQuick
import QtQuick.Layouts
import qs.services

// quick-settings toggle: hairline when idle, a faint blue tint when active
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    signal clicked(var mouse)
    // +1 for wheel up, -1 for wheel down
    signal scrolled(int direction)

    implicitHeight: 58
    radius: Theme.innerRadius
    color: active ? Theme.activeTint : mouse.containsMouse ? Theme.hover : "transparent"
    border.width: Theme.borderWidth
    border.color: active ? Theme.activeColor : Theme.idleBorder
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
        anchors.fill: parent
        anchors.leftMargin: Theme.padMd
        anchors.rightMargin: Theme.padSm
        spacing: Theme.gapMd

        Text {
            text: root.icon
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: Theme.iconBox
            color: root.active ? Theme.activeColor : Theme.foreground
            font.family: Theme.font
            font.pointSize: Theme.iconMd
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.active ? Theme.activeColor : Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Theme.subtext
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
        onWheel: w => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
