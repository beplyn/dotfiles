import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// Add or change one event through vcal (services/Events.qml). Times take
// whatever vcal reads: "2026-11-10 14:00", "tomorrow 9:00", "+2h"; the end
// can be left empty for the default length. Edits send only what changed.
// For a repeating event, "This one" changes the one occurrence; "All"
// changes the series, but not its times, which belong to the TUI.
ColumnLayout {
    id: root

    required property date day
    // null for a new event, else the row being edited
    property var event: null
    // Loads the fields each time this turns true.
    property bool open: false
    signal closed()

    readonly property bool isNew: event === null
    readonly property bool recurring: !isNew && event.recurring
    // For a repeating event: change every occurrence instead of this one.
    property bool series: false
    readonly property bool timesLocked: recurring && series

    property bool allDay: false
    property bool busy: false
    property bool confirmDelete: false
    property string error: ""
    // field values as loaded, to send only the changes
    property var initial: ({})

    function stamp(ts) {
        return Qt.formatDateTime(new Date(ts * 1000), "yyyy-MM-dd HH:mm")
    }

    function load() {
        series = false
        busy = false
        confirmDelete = false
        error = ""
        const e = event
        let v
        if (e === null) {
            // the next whole hour today, nine o'clock on other days
            const now = new Date()
            const start = Events.key(day) === Events.key(now)
                ? new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours() + 1)
                : new Date(day.getFullYear(), day.getMonth(), day.getDate(), 9)
            v = { title: "", allDay: false, start: Qt.formatDateTime(start, "yyyy-MM-dd HH:mm"), end: "", category: "", location: "", description: "", rrule: "" }
        } else if (e.all_day) {
            // vcal prints an exclusive end date; the field takes the last day
            const last = Events.addDays(Events.parseDate(e.end), -1)
            v = { title: e.title, allDay: true, start: e.start, end: Events.key(last), category: e.category ?? "", location: e.location ?? "", description: e.description, rrule: "" }
        } else {
            v = { title: e.title, allDay: false, start: stamp(e.start_ts), end: stamp(e.end_ts), category: e.category ?? "", location: e.location ?? "", description: e.description, rrule: "" }
        }
        initial = v
        allDay = v.allDay
        titleField.text = v.title
        startField.text = v.start
        endField.text = v.end
        categoryField.text = v.category
        locationField.text = v.location
        notesField.text = v.description
        repeatField.text = v.rrule
        Qt.callLater(() => titleField.input.forceActiveFocus())
    }

    onOpenChanged: if (open) load()
    onEventChanged: if (open) load()

    function toggleAllDay() {
        allDay = !allDay
        // keep the date, drop or add the time
        if (allDay) {
            startField.text = startField.text.slice(0, 10)
            endField.text = endField.text === "" ? "" : endField.text.slice(0, 10)
        } else {
            startField.text = startField.text.slice(0, 10) + " 09:00"
            endField.text = ""
        }
    }

    function finish(ok, message) {
        busy = false
        if (ok) closed()
        else error = message
    }

    function save() {
        if (busy) return
        if (titleField.text.trim() === "") {
            error = "A title, please"
            return
        }
        const v = {
            title: titleField.text, allDay: allDay, start: startField.text.trim(), end: endField.text.trim(),
            category: categoryField.text, location: locationField.text, description: notesField.text, rrule: repeatField.text.trim()
        }
        busy = true
        error = ""
        if (isNew) {
            Events.add(v, finish)
            return
        }
        const f = {}
        for (const k of ["title", "category", "location", "description"])
            if (v[k] !== initial[k]) f[k] = v[k]
        if (!timesLocked) {
            // switching all-day needs both ends restated
            const switched = v.allDay !== initial.allDay
            if (switched) f.allDay = v.allDay
            if (switched || v.start !== initial.start) f.start = v.start
            if (switched || v.end !== initial.end) f.end = v.end
        }
        if ((!recurring || series) && v.rrule !== initial.rrule) f.rrule = v.rrule
        if (Object.keys(f).length === 0) {
            finish(true, "")
            return
        }
        Events.edit(event, f, recurring && !series ? event.occurrence : null, finish)
    }

    function remove() {
        busy = true
        Events.remove(event, recurring && !series ? event.occurrence : null, finish)
    }

    spacing: 6

    // --- which occurrences -------------------------------------------------
    RowLayout {
        visible: root.recurring
        spacing: 6

        Text {
            text: Icons.repeat + "  Repeats:"
            color: Theme.subtext
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 1
        }
        IconButton {
            size: 26
            label: "This one"
            filled: !root.series
            onClicked: root.series = false
        }
        IconButton {
            size: 26
            label: "All"
            filled: root.series
            onClicked: root.series = true
        }
    }

    Field {
        id: titleField
        label: "Title"
        placeholder: "What"
    }
    RowLayout {
        Layout.fillWidth: true
        visible: !root.timesLocked
        spacing: 6

        Text {
            Layout.preferredWidth: 64
            text: "All day"
            color: Theme.subtext
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 1
        }
        IconButton {
            size: 24
            icon: root.allDay ? Icons.check : ""
            filled: root.allDay
            enabled: !root.recurring || root.series
            opacity: enabled ? 1 : 0.4
            onClicked: root.toggleAllDay()
        }
        Item { Layout.fillWidth: true }
    }
    Field {
        id: startField
        visible: !root.timesLocked
        label: root.allDay ? "First day" : "Start"
        placeholder: root.allDay ? "2026-11-10" : "2026-11-10 14:00, tomorrow 9:00"
    }
    Field {
        id: endField
        visible: !root.timesLocked
        label: root.allDay ? "Last day" : "End"
        placeholder: root.allDay ? "same day" : "default length"
    }
    Text {
        Layout.fillWidth: true
        visible: root.timesLocked
        text: "The series' times are changed in the terminal calendar."
        color: Theme.muted
        wrapMode: Text.Wrap
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
    }
    Field {
        id: categoryField
        label: "Category"
        placeholder: "work, holiday…"
    }
    Field {
        id: locationField
        label: "Where"
    }
    Field {
        id: notesField
        label: "Notes"
    }
    Field {
        id: repeatField
        visible: root.isNew || (!root.recurring) || root.series
        label: "Repeat"
        placeholder: root.recurring ? "keep the rule" : "FREQ=WEEKLY;BYDAY=MO"
    }

    Text {
        Layout.fillWidth: true
        visible: root.error !== ""
        text: root.error
        color: Theme.red
        wrapMode: Text.Wrap
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
    }

    // --- actions ---------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 6

        IconButton {
            visible: !root.isNew && !root.confirmDelete
            size: 30
            icon: Icons.trash
            tint: Theme.red
            onClicked: root.confirmDelete = true
        }
        IconButton {
            visible: root.confirmDelete
            size: 30
            label: root.recurring && !root.series ? "Delete this one" : root.recurring ? "Delete all" : "Delete"
            tint: Theme.red
            filled: true
            onClicked: root.remove()
        }
        IconButton {
            visible: root.confirmDelete
            size: 30
            label: "Keep"
            onClicked: root.confirmDelete = false
        }
        Item { Layout.fillWidth: true }
        IconButton {
            size: 30
            icon: Icons.close
            onClicked: root.closed()
        }
        IconButton {
            size: 30
            icon: Icons.check
            tint: Theme.green
            filled: true
            opacity: root.busy ? 0.5 : 1
            onClicked: root.save()
        }
    }

    // A labelled line of text; Enter saves, Escape leaves without saving.
    component Field: RowLayout {
        id: field
        property alias text: input.text
        property alias input: input
        property string label: ""
        property string placeholder: ""

        Layout.fillWidth: true
        spacing: 6

        Text {
            Layout.preferredWidth: 64
            text: field.label
            color: input.activeFocus ? Theme.accent : Theme.subtext
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 1
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: input.implicitHeight + 10
            radius: Theme.innerRadius
            color: Theme.well
            border.width: 1
            border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.6) : "transparent"

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.foreground
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
                clip: true
                activeFocusOnTab: true
                selectByMouse: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: field.placeholder
                    color: Theme.muted
                    font: input.font
                }

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.save()
                    else if (e.key === Qt.Key_Escape) root.closed()
                    else return
                    e.accepted = true
                }
            }
        }
    }
}
