import QtQuick
import qs.services

// hakuspace's pill workspaces: the active one stretches to 40px, empty
// ones fade to 20%. One row per output, like niri itself.
Row {
    id: root

    required property string output
    readonly property var list: Niri.workspacesOn(output)

    spacing: 6
    leftPadding: 10
    rightPadding: 10

    // Bound to a count, not the array, so delegates (and their width
    // animations) survive niri's frequent workspace updates.
    Repeater {
        model: root.list.length

        Rectangle {
            id: pill
            required property int index
            readonly property var ws: root.list[index]
            readonly property bool active: ws?.is_active ?? false
            readonly property bool empty: Niri.windowCount(ws?.id) === 0

            anchors.verticalCenter: parent.verticalCenter
            width: active ? 40 : (hover.containsMouse ? 35 : 20)
            height: 12
            radius: 4
            color: ws?.is_urgent ? Theme.red : Theme.accent
            opacity: active ? 1 : (empty ? 0.2 : 0.6)

            Behavior on width {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easing
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focus(pill.ws)
            }
        }
    }

    WheelHandler {
        onWheel: e => Niri.action(e.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down")
    }
}
