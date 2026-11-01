import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Dropped from waybar's clock: the time,
// a calendar, the media player and system load.
Panel {
    id: root

    name: "dashboard"
    align: Qt.AlignHCenter
    cardWidth: 700
    spacing: 14

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // --- header ----------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        ColumnLayout {
            spacing: -2

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 20
                font.bold: true
            }
            Text {
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Theme.accent
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 2
            }
        }

        Item { Layout.fillWidth: true }

        ColumnLayout {
            Layout.alignment: Qt.AlignBottom
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignRight
                text: (Quickshell.env("USER") ?? "") + "@" + Stats.hostname
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
            }
            Text {
                Layout.alignment: Qt.AlignRight
                text: Icons.uptime + "  up " + Stats.uptime
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
            }
        }
    }

    // --- body --------------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Surface {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 300
            padding: 14

            Calendar {
                Layout.fillWidth: true
                today: clock.date
                // Back to the current month whenever the dashboard opens.
                resetOn: root.open
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            MediaPlayer {
                Layout.fillWidth: true
                active: root.open
            }

            Surface {
                Layout.fillWidth: true
                padding: 14

                RowLayout {
                    Layout.fillWidth: true

                    StatRing {
                        Layout.fillWidth: true
                        icon: Icons.cpu
                        label: "CPU"
                        value: Stats.cpu / 100
                        text: Stats.cpu + "%"
                        color: Stats.cpu >= 90 ? Theme.red : Stats.cpu >= 70 ? Theme.yellow : Theme.blue
                    }
                    StatRing {
                        Layout.fillWidth: true
                        icon: Icons.memory
                        label: Stats.memUsedGiB.toFixed(1) + " GiB"
                        value: Stats.memory / 100
                        text: Stats.memory + "%"
                        color: Stats.memory >= 90 ? Theme.red : Stats.memory >= 75 ? Theme.yellow : Theme.cyan
                    }
                    StatRing {
                        Layout.fillWidth: true
                        visible: Stats.hasTemperature
                        icon: Icons.temperature
                        label: "Temp"
                        // 30–100 °C mapped onto the ring.
                        value: (Stats.temperature - 30) / 70
                        text: Stats.temperature + "°"
                        color: Stats.temperature >= 85 ? Theme.red : Theme.orange
                    }
                }
            }
        }
    }
}
