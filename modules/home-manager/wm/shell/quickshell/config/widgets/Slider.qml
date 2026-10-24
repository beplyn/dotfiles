import QtQuick
import qs.services

// Labelled 0..1 slider for the control center's volume/backlight rows.
Item {
    id: root

    property string label: ""
    property real value: 0
    signal moved(real value)
    signal labelClicked

    implicitHeight: 36

    Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        text: root.label
        color: Theme.accent
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize + 4

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.labelClicked()
        }
    }

    Rectangle {
        id: track
        anchors.left: icon.right
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.surface

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }

        Rectangle {
            x: track.width * Math.max(0, Math.min(1, root.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: Theme.text
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor
            function update(x) {
                root.moved(Math.max(0, Math.min(1, (x - 10) / track.width)))
            }
            onPressed: m => update(m.x)
            onPositionChanged: m => { if (pressed) update(m.x) }
            onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
