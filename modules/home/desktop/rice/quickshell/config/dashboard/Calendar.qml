import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.widgets

// Month grid with ISO week numbers and today's week picked out. Arrows
// or scrolling slide between months; the title or the today button
// goes back to the current one. Dots under a day count its events (vcal,
// services/Events.qml); a click picks the day for the agenda, a double
// click opens it in the terminal calendar.
ColumnLayout {
    id: root

    required property date today
    // Each change back to true returns to the current month.
    property bool resetOn: false
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    // The day the agenda below shows.
    property date selected: Events.midnight(today)

    // First of the six rows on screen; Events loads those 42 days.
    readonly property date gridFirst: {
        const f = new Date(month.getFullYear(), month.getMonth(), 1)
        f.setDate(f.getDate() - column(f))
        return f
    }
    onGridFirstChanged: Events.show(gridFirst, Events.addDays(gridFirst, 42))
    Component.onCompleted: Events.show(gridFirst, Events.addDays(gridFirst, 42))

    readonly property int cellSize: 32
    readonly property bool onThisMonth: month.getFullYear() === today.getFullYear()
        && month.getMonth() === today.getMonth()

    // Monday (or the locale's first day) of today's week, at midnight.
    readonly property date weekStart: {
        const d = new Date(today.getFullYear(), today.getMonth(), today.getDate())
        d.setDate(d.getDate() - column(d))
        return d
    }
    readonly property int todayWeek: {
        // ISO 8601: the week holding the year's first Thursday is week 1.
        const t = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 3 - (today.getDay() + 6) % 7)
        const jan4 = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t - jan4) / 864e5 - 3 + (jan4.getDay() + 6) % 7) / 7)
    }
    // Whether today's week is one of the six rows on screen.
    readonly property bool showsTodayWeek: {
        const first = new Date(month.getFullYear(), month.getMonth(), 1)
        first.setDate(first.getDate() - column(first))
        const rows = Math.round((weekStart - first) / 864e5) / 7
        return rows >= 0 && rows < 6
    }

    // Where a date sits in the week, 0 being the locale's first day.
    function column(d) {
        return (d.getDay() - grid.locale.firstDayOfWeek + 7) % 7
    }

    function inTodayWeek(y, m, d) {
        const days = Math.round((new Date(y, m, d) - weekStart) / 864e5)
        return days >= 0 && days < 7
    }

    // Months queue up here while the slide plays, so fast scrolling
    // lands on the right month instead of dropping steps.
    property date pending: month
    property int direction: 1

    function shift(n) {
        pending = new Date(pending.getFullYear(), pending.getMonth() + n, 1)
        direction = n > 0 ? 1 : -1
        slide.restart()
    }

    function reset() {
        slide.stop()
        body.opacity = 1
        offset.x = 0
        month = pending = new Date(today.getFullYear(), today.getMonth(), 1)
        selected = Events.midnight(today)
    }

    function goToday() {
        if (onThisMonth)
            return
        const current = new Date(today.getFullYear(), today.getMonth(), 1)
        shift((current.getFullYear() - pending.getFullYear()) * 12 + current.getMonth() - pending.getMonth())
    }

    onResetOnChanged: if (resetOn) reset()

    spacing: 10

    SequentialAnimation {
        id: slide

        ParallelAnimation {
            NumberAnimation { target: body; property: "opacity"; to: 0; duration: 90 }
            NumberAnimation { target: offset; property: "x"; to: -root.direction * 18; duration: 90 }
        }
        ScriptAction {
            script: {
                root.month = root.pending
                offset.x = root.direction * 18
            }
        }
        ParallelAnimation {
            NumberAnimation { target: body; property: "opacity"; to: 1; duration: Theme.fast }
            NumberAnimation {
                target: offset; property: "x"; to: 0; duration: Theme.slow
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing
            }
        }
    }

    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }

    // --- title -------------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Item {
            Layout.fillWidth: true
            implicitHeight: title.implicitHeight

            Row {
                id: title
                spacing: 8

                Text {
                    id: monthName
                    text: Qt.formatDate(root.month, "MMMM")
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 3
                    font.bold: true
                }
                Text {
                    anchors.baseline: monthName.baseline
                    text: root.month.getFullYear()
                    color: Theme.accent
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                }
            }

            MouseArea {
                anchors.fill: title
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goToday()
            }
        }

        IconButton {
            size: 28
            icon: Icons.today
            tint: Theme.accent
            // Only there to come back from another month.
            opacity: root.onThisMonth ? 0 : 1
            visible: opacity > 0
            onClicked: root.goToday()

            Behavior on opacity {
                NumberAnimation { duration: Theme.fast }
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

    // --- grid --------------------------------------------------------------
    GridLayout {
        id: body

        Layout.fillWidth: true
        columns: 2
        columnSpacing: 6
        rowSpacing: 6
        transform: Translate { id: offset }

        Item { implicitWidth: 1 }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale
            delegate: Text {
                required property int day
                required property string narrowName
                text: narrowName
                horizontalAlignment: Text.AlignHCenter
                // Weekends in the accent, like their dates below.
                color: day === Qt.Saturday || day % 7 === 0 ? Theme.accent : Theme.subtext
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
            spacing: 0
            delegate: Text {
                required property int weekNumber
                readonly property bool current: root.showsTodayWeek && weekNumber === root.todayWeek
                height: root.cellSize
                text: weekNumber
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                color: current ? Theme.accent : Theme.muted
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 2
                font.bold: current
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            // MonthGrid doesn't size itself from its delegates; without
            // this the layout squashes every row to nothing.
            Layout.preferredHeight: root.cellSize * 6
            month: root.month.getMonth()
            year: root.month.getFullYear()
            locale: Qt.locale()
            spacing: 0

            delegate: Item {
                id: cell
                required property var model
                readonly property bool isToday: model.today
                readonly property bool inMonth: model.month === grid.month
                readonly property int weekday: root.column(new Date(model.year, model.month, model.day))
                readonly property bool weekend: model.date.getDay() === 0 || model.date.getDay() === 6
                readonly property bool thisWeek: root.inTodayWeek(model.year, model.month, model.day)
                readonly property bool past: root.onThisMonth && new Date(model.year, model.month, model.day + 1) <= root.today
                readonly property bool isSelected: Events.key(model.date) === Events.key(root.selected)
                readonly property var events: Events.on(model.date)

                implicitHeight: root.cellSize

                // Today's week as one continuous band across the row.
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    visible: cell.thisWeek
                    color: Theme.alpha(Theme.accent, 0.12)
                    topLeftRadius: cell.weekday === 0 ? height / 2 : 0
                    bottomLeftRadius: topLeftRadius
                    topRightRadius: cell.weekday === 6 ? height / 2 : 0
                    bottomRightRadius: topRightRadius
                }

                // Soft halo, then the filled disc.
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellSize
                    height: width
                    radius: width / 2
                    visible: cell.isToday
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.alpha(Theme.accent, 0.35)
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellSize - 6
                    height: width
                    radius: width / 2
                    color: cell.isToday ? Theme.accent
                        : hover.hovered ? Theme.alpha(Theme.foreground, 0.1)
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.fast }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.model.day
                    color: cell.isToday ? Theme.background
                        : cell.weekend ? Theme.accent
                        : Theme.foreground
                    opacity: !cell.inMonth ? 0.25 : cell.past && !cell.thisWeek ? 0.55 : 1
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                    font.bold: cell.isToday
                }

                // The picked day, when it isn't today (today has its disc).
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellSize - 4
                    height: width
                    radius: width / 2
                    visible: cell.isSelected && !cell.isToday
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.accent
                }

                // One dot per event, up to three, in the event's colour.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    spacing: 2
                    opacity: cell.inMonth ? 1 : 0.35

                    Repeater {
                        model: cell.events.slice(0, 3)
                        delegate: Rectangle {
                            required property var modelData
                            width: 4
                            height: 4
                            radius: 2
                            color: Events.color(modelData)
                        }
                    }
                }

                HoverHandler {
                    id: hover
                }

                TapHandler {
                    onTapped: root.selected = Events.midnight(cell.model.date)
                    onDoubleTapped: Events.openTui(cell.model.date)
                }
            }
        }
    }
}
