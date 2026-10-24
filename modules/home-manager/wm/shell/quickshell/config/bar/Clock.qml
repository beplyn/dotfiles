import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.widgets

// Clock with waybar's format-alt on click and its month calendar on
// right click (scroll shifts the month, like calendar.on-scroll).
Pill {
    id: root

    property bool alt: false

    text: Qt.formatDateTime(clock.date, alt ? " dddd, dd MMMM yyyy " : " HH:mm, dd MMMM yyyy ")
    hoverWidth: 0
    padding: hovered ? 28 : 10

    onClicked: m => {
        if (m.button === Qt.RightButton) calendar.visible = !calendar.visible
        else alt = !alt
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PopupWindow {
        id: calendar

        property date month: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

        onVisibleChanged: if (visible) month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

        anchor.item: root
        anchor.rect.x: root.width / 2
        anchor.rect.y: root.height + 6
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom
        color: "transparent"
        implicitWidth: box.implicitWidth
        implicitHeight: box.implicitHeight

        Rectangle {
            id: box
            implicitWidth: col.implicitWidth + 28
            implicitHeight: col.implicitHeight + 24
            radius: Theme.radius
            color: Theme.base
            border.color: Theme.alpha(Theme.accent, 0.4)

            WheelHandler {
                onWheel: e => {
                    const m = calendar.month
                    calendar.month = new Date(m.getFullYear(), m.getMonth() + (e.angleDelta.y > 0 ? -1 : 1), 1)
                }
            }

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(calendar.month, "yyyy MMMM")
                    color: Theme.accent
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 3
                    font.bold: true
                }

                Row {
                    spacing: 6

                    Column {
                        DayOfWeekRow {
                            width: grid.width
                            locale: grid.locale
                            delegate: Text {
                                required property string shortName
                                text: shortName
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.yellow
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize
                                font.bold: true
                            }
                        }

                        MonthGrid {
                            id: grid
                            month: calendar.month.getMonth()
                            year: calendar.month.getFullYear()
                            locale: Qt.locale()
                            delegate: Text {
                                required property var model
                                readonly property bool today: model.today
                                text: model.day
                                horizontalAlignment: Text.AlignHCenter
                                opacity: model.month === grid.month ? 1 : 0.3
                                color: today ? Theme.red : Theme.text
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize
                                font.bold: true
                                font.underline: today
                            }
                        }
                    }

                    WeekNumberColumn {
                        height: grid.height
                        anchors.bottom: parent.bottom
                        month: grid.month
                        year: grid.year
                        locale: grid.locale
                        delegate: Text {
                            required property int weekNumber
                            text: "W" + weekNumber
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.cyan
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
