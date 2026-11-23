import QtQuick
import QtQuick.Layouts
import qs.services

// 0..1 slider row: clickable glyph (e.g. mute), hairline track, percentage.
// Drag, click or scroll on the track to move it.
RowLayout {
    id: root

    property string icon: ""
    property real value: 0
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked

    readonly property real clamped: Math.max(0, Math.min(1, value))

    spacing: Theme.padSm

    Text {
        Layout.preferredWidth: Theme.iconBox
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        verticalAlignment: Text.AlignVCenter
        color: root.dimmed ? Theme.muted : Theme.foreground
        font.family: Theme.font
        font.pointSize: Theme.iconMd

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: Theme.gapXl

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Theme.trackHeight
            color: Theme.surface

            Rectangle {
                width: track.width * root.clamped
                height: parent.height
                color: root.dimmed ? Theme.muted : Theme.activeColor

                Behavior on width {
                    enabled: !drag.pressed
                    NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                }
            }
        }

        // a single tick marks the value; no knob
        Rectangle {
            x: track.width * root.clamped - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.trackHeight
            height: drag.pressed || drag.containsMouse ? Theme.gapMd + Theme.gapXs : Theme.gapMd
            color: root.dimmed ? Theme.muted : Theme.foreground

            Behavior on height {
                NumberAnimation { duration: Theme.quick }
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
        Layout.preferredWidth: Theme.gapXl + Theme.gapMd + Theme.gapXs
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.clamped * 100) + "%"
        color: Theme.subtext
        font.family: Theme.font
        font.features: Theme.numeric
        font.pointSize: Theme.popupFontSize
    }
}
