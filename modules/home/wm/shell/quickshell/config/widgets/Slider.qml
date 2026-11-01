import QtQuick
import QtQuick.Layouts
import qs.services

// 0..1 slider row: clickable glyph (e.g. mute), track, percentage.
// Drag, click or scroll on the track to move it.
RowLayout {
    id: root

    property string icon: ""
    property real value: 0
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked

    readonly property real clamped: Math.max(0, Math.min(1, value))

    spacing: 10

    Text {
        Layout.preferredWidth: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        color: root.dimmed ? Theme.muted : Theme.accent
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize + 4

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Theme.alpha(Theme.surface, 0.9)

            Rectangle {
                width: Math.max(height, track.width * root.clamped)
                height: parent.height
                radius: parent.radius
                color: root.dimmed ? Theme.muted : Theme.accent

                Behavior on width {
                    enabled: !drag.pressed
                    NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            x: track.width * root.clamped - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: drag.pressed || drag.containsMouse ? 16 : 12
            height: width
            radius: width / 2
            color: Theme.bright
            border.color: root.dimmed ? Theme.muted : Theme.accent
            border.width: 2

            Behavior on width {
                NumberAnimation { duration: 120 }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function update(x) {
                root.moved(Math.max(0, Math.min(1, x / track.width)))
            }
            onPressed: m => update(m.x)
            onPositionChanged: m => { if (pressed) update(m.x) }
            onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Text {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.clamped * 100) + "%"
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize
    }
}
