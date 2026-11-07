import QtQuick
import QtQuick.Layouts
import qs.dashboard
import qs.services
import qs.widgets

// Dropped from waybar's battery pill: the charge and wear as gauges, then
// how the charge went over the last hours.
Panel {
    id: root

    name: "battery"
    align: Qt.AlignRight
    cardWidth: 420

    readonly property color levelColor: Battery.charging || Battery.full ? Theme.cyan
        : Battery.percent <= 15 ? Theme.red
        : Battery.percent <= 30 ? Theme.yellow
        : Theme.green

    readonly property var known: Battery.history.filter(v => v !== null)

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
            color: Theme.alpha(root.levelColor, 0.18)

            Text {
                anchors.centerIn: parent
                text: Battery.charging ? Icons.batteryCharging : Icons.level(Icons.battery, Battery.percent)
                color: root.levelColor
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 6
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Battery"
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 2
                font.bold: true
            }
            Label {
                text: Battery.status
            }
        }

        Text {
            text: Battery.percent + "%"
            color: root.levelColor
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 10
            font.bold: true
        }
    }

    // --- gauges ------------------------------------------------------------
    Surface {
        Layout.fillWidth: true
        padding: 14

        // two rings centred, rather than spread like the dashboard's three
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 56

            StatRing {
                icon: Battery.charging ? Icons.batteryCharging : Icons.level(Icons.battery, Battery.percent)
                label: "Charge"
                value: Battery.percent / 100
                text: Battery.percent + "%"
                color: root.levelColor
            }
            StatRing {
                visible: Battery.healthSupported
                icon: Icons.batteryHealth
                label: "Health"
                value: Battery.health / 100
                text: Battery.health + "%"
                color: Battery.health < 50 ? Theme.red : Battery.health < 80 ? Theme.yellow : Theme.green
            }
        }
    }

    // --- history -----------------------------------------------------------
    Surface {
        Layout.fillWidth: true
        padding: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                id: axis
                Layout.fillHeight: true
                spacing: 0

                Label { text: "100%" }
                Item { Layout.fillHeight: true }
                Label { text: "0%" }
            }

            Graph {
                Layout.fillWidth: true
                values: Battery.history
                length: Battery.bucketCount
                color: root.levelColor
            }
        }
        // time under the graph only, clear of the percent axis
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: axis.width + 8
            Label { text: Battery.hours + " h ago" }
            Item { Layout.fillWidth: true }
            Label { text: "now" }
        }

        Label {
            visible: root.known.length < 2
            Layout.alignment: Qt.AlignHCenter
            text: "Recording; the graph fills in over the next minutes"
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
                { label: Battery.charging ? "Charging at" : "Drawing", value: Battery.rate.toFixed(1) + " W" },
                { label: "Energy", value: Battery.energy.toFixed(1) + " / " + Battery.capacity.toFixed(1) + " Wh" },
                { label: "Lowest, " + Battery.hours + " h", value: root.known.length ? Math.min(...root.known) + "%" : "–" },
                { label: "Highest, " + Battery.hours + " h", value: root.known.length ? Math.max(...root.known) + "%" : "–" }
            ]

            Surface {
                required property var modelData
                Layout.fillWidth: true
                spacing: 2

                Label { text: modelData.label }
                Text {
                    text: modelData.value
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 1
                    font.bold: true
                }
            }
        }
    }
}
