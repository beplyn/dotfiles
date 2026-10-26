import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services

// Circular gauge: an arc filled to `value` (0..1) around a readout.
ColumnLayout {
    id: root

    property real value: 0
    property string text: ""
    property string icon: ""
    property string label: ""
    property color color: Theme.accent

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown {
        NumberAnimation { duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
    }

    spacing: 6

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 78
        implicitHeight: 78

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.alpha(Theme.surface, 0.9)
                strokeWidth: 7
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 39
                    centerY: 39
                    radiusX: 34
                    radiusY: 34
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.color
                strokeWidth: 7
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 39
                    centerY: 39
                    radiusX: 34
                    radiusY: 34
                    startAngle: -90
                    sweepAngle: 360 * root.shown
                }
            }
        }

        Column {
            anchors.centerIn: parent

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icon
                color: root.color
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.text
                color: Theme.text
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
                font.bold: true
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
    }
}
