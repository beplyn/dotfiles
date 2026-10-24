import QtQuick
import qs.services

// Waybar group drawer with click-to-reveal: a head pill that slides its
// children out beside it. `revealLeft` mirrors transition-left-to-right.
Item {
    id: root

    property string icon: ""
    property string tooltip: ""
    property bool solidHead: true
    property bool revealLeft: true
    property bool expanded: false
    default property alias content: inner.data

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        layoutDirection: root.revealLeft ? Qt.RightToLeft : Qt.LeftToRight
        spacing: 2

        Pill {
            id: head
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            tooltip: root.tooltip
            solid: root.solidHead
            onClicked: root.expanded = !root.expanded
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            height: head.height
            width: root.expanded ? inner.implicitWidth : 0
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 1000
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easing
                }
            }

            Row {
                id: inner
                anchors.verticalCenter: parent.verticalCenter
                x: root.revealLeft ? parent.width - implicitWidth : 0
                spacing: 2
            }
        }
    }
}
