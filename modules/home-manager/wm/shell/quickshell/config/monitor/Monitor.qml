import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// One stat's history, dropped from its waybar pill: the reading now, a
// two-minute graph, and a row of details. shell.qml makes one per stat.
Panel {
    id: root

    align: Qt.AlignRight
    cardWidth: 420

    property string icon: ""
    property string title: ""
    // The current reading, e.g. "42%".
    property string reading: ""
    property color color: Theme.accent
    property var values: []
    property real min: 0
    property real max: 100
    // Suffix for the graph's axis labels and the avg / peak details.
    property string unit: "%"
    // Extra { label, value } pairs after avg and peak.
    property var details: []

    readonly property real average: values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0
    readonly property real peak: values.length ? Math.max(...values) : 0

    component Label: Text {
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
    }

    // --- header ----------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            implicitWidth: 42
            implicitHeight: 42
            radius: Theme.innerRadius
            color: Theme.alpha(root.color, 0.18)

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.color
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 6
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 2
                font.bold: true
            }
            Label {
                text: "Last " + Math.round(Stats.historyLength * Stats.interval / 60000) + " minutes"
            }
        }

        Text {
            text: root.reading
            color: root.color
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 10
            font.bold: true
        }
    }

    // --- graph -------------------------------------------------------------
    Surface {
        Layout.fillWidth: true
        padding: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 0

                Label { text: root.max + root.unit }
                Item { Layout.fillHeight: true }
                Label { text: root.min + root.unit }
            }

            Graph {
                Layout.fillWidth: true
                values: root.values
                min: root.min
                max: root.max
                length: Stats.historyLength
                color: root.color
            }
        }
    }

    // --- details -----------------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: [
                { label: "Average", value: Math.round(root.average) + root.unit },
                { label: "Peak", value: Math.round(root.peak) + root.unit }
            ].concat(root.details)

            Surface {
                required property var modelData
                Layout.fillWidth: true
                spacing: 2

                Label { text: modelData.label }
                Text {
                    text: modelData.value
                    color: Theme.text
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 1
                    font.bold: true
                }
            }
        }
    }
}
