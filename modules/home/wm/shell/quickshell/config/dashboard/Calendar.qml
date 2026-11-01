import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.widgets

// Month grid with ISO week numbers. Arrows or scrolling change the
// month; clicking the title goes back to today.
ColumnLayout {
    id: root

    required property date today
    // Each change back to true returns to the current month.
    property bool resetOn: false
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)

    function shift(n) {
        month = new Date(month.getFullYear(), month.getMonth() + n, 1)
    }

    function reset() {
        month = new Date(today.getFullYear(), today.getMonth(), 1)
    }

    onResetOnChanged: if (resetOn) reset()

    spacing: 8

    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.month, "MMMM yyyy")
            color: Theme.foreground
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 2
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.reset()
            }
        }

        IconButton {
            size: 28
            icon: Icons.chevronLeft
            onClicked: root.shift(-1)
        }
        IconButton {
            size: 28
            icon: Icons.chevronRight
            onClicked: root.shift(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 4
        rowSpacing: 4

        Item { implicitWidth: 1 }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale
            delegate: Text {
                required property string narrowName
                text: narrowName
                horizontalAlignment: Text.AlignHCenter
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 1
                font.bold: true
            }
        }

        WeekNumberColumn {
            Layout.fillHeight: true
            month: grid.month
            year: grid.year
            locale: grid.locale
            delegate: Text {
                required property int weekNumber
                text: weekNumber
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                color: Theme.muted
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 2
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            month: root.month.getMonth()
            year: root.month.getFullYear()
            locale: Qt.locale()
            spacing: 2

            delegate: Item {
                id: day
                required property var model
                readonly property bool isToday: model.today
                readonly property bool inMonth: model.month === grid.month

                implicitHeight: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: day.isToday ? Theme.accent : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: day.model.day
                    color: day.isToday ? Theme.background : Theme.foreground
                    opacity: day.inMonth ? 1 : 0.3
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                    font.bold: day.isToday
                }
            }
        }
    }
}
