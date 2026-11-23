import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Dropped from waybar's clock: the time, a calendar with the picked
// day's events (vcal), the media player and system load.
Panel {
    id: root

    name: "dashboard"
    align: Qt.AlignHCenter
    cardWidth: 700
    spacing: Theme.padMd

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // --- header ----------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.gapXs
        Layout.rightMargin: Theme.gapXs

        ColumnLayout {
            spacing: -Theme.gapXs / 2

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.foreground
                font.family: Theme.font
                font.features: Theme.numeric
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
            spacing: Theme.gapXs

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
        spacing: Theme.gapMd

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 300
            spacing: Theme.gapMd

            Surface {
                Layout.fillWidth: true
                padding: Theme.padMd

                Calendar {
                    id: calendar
                    Layout.fillWidth: true
                    today: clock.date
                    // Back to the current month whenever the dashboard opens.
                    resetOn: root.open
                }
            }

            Surface {
                Layout.fillWidth: true
                padding: Theme.gapMd

                Agenda {
                    Layout.fillWidth: true
                    day: calendar.selected
                    active: root.open
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Theme.gapMd

            MediaPlayer {
                Layout.fillWidth: true
                active: root.open
            }

            Surface {
                Layout.fillWidth: true
                padding: Theme.padMd

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
