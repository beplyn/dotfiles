import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets

// Clipboard history and pins (Mod+V), on cliphist, with vim keys: it opens in
// normal mode (j/k, y, p, dd, D), / searches, ? or the (i) tab lists them all.
Panel {
    id: root

    name: "clipboard"
    align: Qt.AlignHCenter
    cardWidth: 800
    spacing: 12

    property string tab: "history"
    // the (i) tab: every key, over the list
    property bool showKeys: false
    property int current: 0
    // D waits for its second press.
    property bool armed: false
    // the first key of gg and dd, as vim's showcmd
    property string pending: ""

    readonly property bool searching: search.activeFocus

    readonly property var kinds: ({
        text: { icon: Icons.text, label: "Text", tint: Theme.subtext },
        code: { icon: Icons.code, label: "Code", tint: Theme.green },
        link: { icon: Icons.link, label: "Link", tint: Theme.blue },
        email: { icon: Icons.email, label: "Email", tint: Theme.cyan },
        path: { icon: Icons.folder, label: "Path", tint: Theme.yellow },
        number: { icon: Icons.number, label: "Number", tint: Theme.orange },
        color: { icon: Icons.palette, label: "Color", tint: Theme.accent },
        image: { icon: Icons.image, label: "Image", tint: Theme.cyan },
        binary: { icon: Icons.file, label: "File", tint: Theme.muted }
    })

    // The (i) tab, and the footer's picks from it.
    readonly property var keymap: [
        { name: "Move", binds: [
            { keys: ["j", "k"], title: "Down / up (or arrows)" },
            { keys: ["gg", "G"], title: "First / last" },
            { keys: ["Ctrl+d", "Ctrl+u"], title: "Half a page down / up" },
            { keys: ["h", "l"], title: "History / pinned" },
            { keys: ["Tab"], title: "The other tab" }
        ] },
        { name: "Entry", binds: [
            { keys: ["y", "Enter"], title: "Copy and close" },
            { keys: ["p"], title: "Pin / unpin" },
            { keys: ["dd", "x"], title: "Delete" },
            { keys: ["D"], title: "Clear the tab (twice)" }
        ] },
        { name: "Search", binds: [
            { keys: ["/"], title: "Search" },
            { keys: ["Enter"], title: "Keep the filter" },
            { keys: ["Esc"], title: "Drop the filter" },
            { keys: ["Ctrl+j", "Ctrl+k"], title: "Move while typing" }
        ] },
        { name: "Panel", binds: [
            { keys: ["?"], title: "These keys" },
            { keys: ["q", "Esc"], title: "Close" }
        ] }
    ]

    readonly property var source: tab === "pinned" ? Clipboard.pinned : Clipboard.history
    readonly property var terms: search.text.toLowerCase().split(/\s+/).filter(t => t !== "")
    // every word somewhere in the preview or the kind ("image", "link")
    readonly property var entries: source.filter(e => {
        const hay = (e.preview + " " + kinds[e.kind].label).toLowerCase()
        return terms.every(t => hay.includes(t))
    })
    readonly property var selected: entries.length > 0 ? entries[Math.min(current, entries.length - 1)] : null

    function select(i) {
        current = Math.max(0, Math.min(i, entries.length - 1))
    }

    function setTab(name) {
        showKeys = false
        if (tab === name) return
        tab = name
        current = 0
    }

    function toNormal() {
        normalKeys.forceActiveFocus()
    }

    function copy(entry) {
        if (!entry || entry.kind === "binary") return
        Clipboard.copy(entry)
        Panels.close()
    }

    function removeSelected() {
        if (selected) Clipboard.remove(selected)
    }

    function clearAll() {
        if (source.length === 0) return
        if (!armed) {
            armed = true
            return
        }
        armed = false
        Clipboard.wipe(tab)
    }

    readonly property var modifierKeys: [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R]

    function normalKey(e) {
        if (modifierKeys.includes(e.key)) return
        const ctrl = e.modifiers & Qt.ControlModifier
        const t = e.text
        const prefix = pending
        const half = Math.max(1, Math.floor(list.height / 64 / 2))
        pending = ""
        if (t !== "D") armed = false

        if (showKeys) {
            if (t === "h") setTab("history")
            else if (t === "l") setTab("pinned")
            else if (t === "q" && !ctrl) Panels.close()
            else if (t === "?" || e.key === Qt.Key_Escape || e.key === Qt.Key_Tab) showKeys = false
            e.accepted = true
            return
        }

        if (ctrl && e.key === Qt.Key_D) select(current + half)
        else if (ctrl && e.key === Qt.Key_U) select(current - half)
        else if (ctrl) return
        else if (t === "j" || e.key === Qt.Key_Down) select(current + 1)
        else if (t === "k" || e.key === Qt.Key_Up) select(current - 1)
        else if (t === "g") {
            if (prefix === "g") select(0)
            else pending = "g"
        }
        else if (t === "G" || e.key === Qt.Key_End) select(entries.length - 1)
        else if (e.key === Qt.Key_Home) select(0)
        else if (t === "h") setTab("history")
        else if (t === "l") setTab("pinned")
        else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) setTab(tab === "history" ? "pinned" : "history")
        else if (t === "y" || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) copy(selected)
        else if (t === "p") {
            if (selected) Clipboard.togglePin(selected)
        }
        else if (t === "d") {
            if (prefix === "d") removeSelected()
            else pending = "d"
        }
        else if (t === "x" || e.key === Qt.Key_Delete) removeSelected()
        else if (t === "D") clearAll()
        else if (t === "/") search.forceActiveFocus()
        else if (t === "?") showKeys = true
        else if (t === "q") Panels.close()
        else if (e.key === Qt.Key_Escape) {
            if (search.text !== "") search.text = ""
            else Panels.close()
        }
        else return
        e.accepted = true
    }

    // "1 char", "4 lines"
    function plural(n, word) {
        return n + " " + word + (n === 1 ? "" : "s")
    }

    // CSS hex (#rgb, #rgba, #rrggbb, #rrggbbaa); Qt reads 8 digits as #aarrggbb.
    function hexColor(hex) {
        let h = hex.slice(1)
        if (h.length <= 4) h = h.split("").map(c => c + c).join("")
        const n = i => parseInt(h.slice(i, i + 2), 16) / 255
        return Qt.rgba(n(0), n(2), n(4), h.length === 8 ? n(6) : 1)
    }

    onEntriesChanged: if (current >= entries.length) current = Math.max(0, entries.length - 1)
    onCurrentChanged: list.positionViewAtIndex(current, ListView.Contain)
    onTabChanged: armed = false
    onPendingChanged: if (pending !== "") pendingReset.restart()

    onOpenChanged: {
        if (!open) return
        Clipboard.refresh()
        tab = "history"
        showKeys = false
        current = 0
        armed = false
        pending = ""
        search.text = ""
        Qt.callLater(toNormal)
    }

    // a lone g or d is dropped after a second, as vim's timeoutlen
    Timer {
        id: pendingReset
        interval: 1000
        onTriggered: root.pending = ""
    }

    // --- detail: the whole text, or the decoded image ----------------------
    readonly property string selectedKey: selected ? selected.key : ""
    property string detail: ""
    property string detailKey: ""
    readonly property bool detailReady: selectedKey !== "" && detailKey === selectedKey

    onSelectedKeyChanged: detailDelay.restart()

    // skipped while the selection runs past under a held key
    Timer {
        id: detailDelay
        interval: 60
        onTriggered: {
            const e = root.selected
            if (!e || ["color", "binary"].includes(e.kind) || detailProc.running) return
            detailProc.key = root.selectedKey
            detailProc.command = e.kind === "image"
                ? [Theme.bin.clipboard, "thumb", e.store, e.id, e.ext]
                : [Theme.bin.clipboard, "text", e.store, e.id]
            detailProc.running = true
        }
    }

    Process {
        id: detailProc
        property string key: ""
        stdout: StdioCollector {
            onStreamFinished: {
                root.detail = text
                root.detailKey = detailProc.key
                if (detailProc.key !== root.selectedKey) detailDelay.restart()
            }
        }
    }

    component Caption: Text {
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
        elide: Text.ElideRight
    }

    // A key cap, as in the hotkey overlay.
    component Cap: Rectangle {
        property alias text: capText.text
        implicitWidth: Math.max(capText.implicitWidth + 12, implicitHeight)
        implicitHeight: capText.implicitHeight + 6
        radius: 6
        color: Theme.well
        border.color: Theme.cardBorder
        border.width: 1

        Text {
            id: capText
            anchors.centerIn: parent
            color: Theme.subtext
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 2
            font.bold: true
        }
    }

    // caps for each key, with a slash between alternatives
    component KeyCaps: Row {
        id: keyRow
        property var keys: []
        spacing: 4

        Repeater {
            model: keyRow.keys

            Row {
                required property string modelData
                required property int index
                spacing: 4

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: parent.index > 0
                    text: "/"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 2
                }
                Cap {
                    text: parent.modelData
                }
            }
        }
    }

    component Hint: Row {
        id: hint
        property var keys: []
        property string label: ""
        spacing: 6

        KeyCaps {
            keys: hint.keys
        }
        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: hint.label
        }
    }

    // --- header: title, tabs, clear --------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            implicitWidth: 42
            implicitHeight: 42
            radius: 21
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: Icons.clipboard
                color: Theme.background
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 5
            }
        }

        ColumnLayout {
            spacing: 0

            Text {
                text: "Clipboard"
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 4
                font.bold: true
            }
            Caption {
                text: Clipboard.history.length + (Clipboard.history.length === 1 ? " entry" : " entries") + "  ·  " + Clipboard.pinned.length + " pinned"
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // History | Pinned | (i), the highlight sliding between them
        Rectangle {
            id: tabs
            readonly property var items: [
                { key: "history", icon: Icons.history, label: "History", count: Clipboard.history.length, width: 132 },
                { key: "pinned", icon: Icons.pin, label: "Pinned", count: Clipboard.pinned.length, width: 132 },
                { key: "keys", icon: Icons.info, label: "", count: -1, width: 40 }
            ]
            readonly property int active: root.showKeys ? 2 : root.tab === "pinned" ? 1 : 0

            implicitWidth: items.reduce((w, t) => w + t.width, 0) + 8
            implicitHeight: 38
            radius: Theme.innerRadius
            color: Theme.well

            Rectangle {
                x: 4 + tabs.items.slice(0, tabs.active).reduce((w, t) => w + t.width, 0)
                y: 4
                width: tabs.items[tabs.active].width
                height: parent.height - 8
                radius: Math.max(0, Theme.innerRadius - 3)
                color: Theme.accent

                Behavior on x {
                    NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                }
                Behavior on width {
                    NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
                }
            }

            Row {
                x: 4
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: tabs.items

                    Item {
                        id: tabItem
                        required property var modelData
                        required property int index
                        readonly property bool active: tabs.active === index
                        readonly property color fg: active ? Theme.background : tabMouse.containsMouse ? Theme.foreground : Theme.subtext

                        width: modelData.width
                        height: 30

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabItem.modelData.icon
                                color: tabItem.fg
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize + 1
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tabItem.modelData.label !== ""
                                text: tabItem.modelData.label
                                color: tabItem.fg
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize
                                font.bold: true
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tabItem.modelData.count >= 0
                                implicitWidth: Math.max(countText.implicitWidth + 10, implicitHeight)
                                implicitHeight: countText.implicitHeight + 2
                                radius: height / 2
                                color: tabItem.active ? Theme.alpha(Theme.background, 0.25) : Theme.alpha(Theme.surface, 0.8)

                                Text {
                                    id: countText
                                    anchors.centerIn: parent
                                    text: tabItem.modelData.count
                                    color: tabItem.fg
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 3
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (tabItem.modelData.key === "keys") root.showKeys = !root.showKeys
                                else root.setTab(tabItem.modelData.key)
                                root.toNormal()
                            }
                        }
                    }
                }
            }
        }

        IconButton {
            icon: Icons.clearAll
            label: root.armed ? "Clear all?" : ""
            tint: Theme.red
            filled: root.armed
            enabled: root.source.length > 0 && !root.showKeys
            opacity: enabled ? 1 : 0.4
            onClicked: {
                root.clearAll()
                root.toNormal()
            }
        }
    }

    // --- mode and search ---------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.innerRadius
        color: Theme.alpha(Theme.background, 0.6)
        border.color: root.searching ? Theme.green : Theme.surface
        border.width: 1

        Behavior on border.color {
            ColorAnimation { duration: Theme.fast }
        }

        // normal mode's keys land here
        Item {
            id: normalKeys
            Keys.onPressed: e => root.normalKey(e)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 12
            spacing: 10

            // vim's mode in the statusline
            Rectangle {
                implicitWidth: modeText.implicitWidth + 16
                implicitHeight: 28
                radius: Math.max(0, Theme.innerRadius - 4)
                color: root.searching ? Theme.green : Theme.accent

                Behavior on color {
                    ColorAnimation { duration: Theme.fast }
                }

                Text {
                    id: modeText
                    anchors.centerIn: parent
                    text: root.searching ? "SEARCH" : "NORMAL"
                    color: Theme.background
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 2
                    font.bold: true
                    font.letterSpacing: 1
                }
            }

            Text {
                text: root.searching || search.text !== "" ? "/" : Icons.search
                color: root.searching ? Theme.green : Theme.muted
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
                font.bold: true
            }

            TextInput {
                id: search
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.foreground
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
                clip: true
                onTextChanged: root.current = 0
                onActiveFocusChanged: if (activeFocus) root.showKeys = false

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: root.searching ? "Type to filter, Enter keeps it, Esc drops it" : "Press / to search, ? for keys"
                    color: Theme.muted
                    font: search.font
                }

                Keys.onPressed: e => {
                    const ctrl = e.modifiers & Qt.ControlModifier
                    if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) root.select(root.current + 1)
                    else if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) root.select(root.current - 1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.toNormal()
                    else if (e.key === Qt.Key_Escape) {
                        search.text = ""
                        root.toNormal()
                    }
                    else return
                    e.accepted = true
                }
            }

            // showcmd: the waiting g or d
            Text {
                visible: root.pending !== ""
                text: root.pending
                color: Theme.accent
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
                font.bold: true
            }

            Caption {
                visible: root.terms.length > 0
                text: root.entries.length + " / " + root.source.length
            }
        }
    }

    // --- list and preview, or the keys --------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 440

        RowLayout {
            anchors.fill: parent
            spacing: 12
            visible: !root.showKeys

            ListView {
                id: list
                Layout.preferredWidth: 410
                Layout.fillHeight: true
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.current
                highlightFollowsCurrentItem: false
                model: ScriptModel {
                    values: root.entries
                    objectProp: "key"
                }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property var kind: root.kinds[modelData.kind]
                    readonly property bool selected: index === root.current
                    readonly property bool pinned: Clipboard.isPinned(modelData)
                    readonly property bool hovered: rowMouse.containsMouse || pinButton.hovered || deleteButton.hovered

                    width: ListView.view.width
                    height: 60
                    radius: Theme.innerRadius
                    color: selected ? Theme.alpha(Theme.accent, 0.16)
                        : hovered ? Theme.alpha(Theme.surface, 0.5)
                        : "transparent"
                    border.width: 1
                    border.color: selected ? Theme.alpha(Theme.accent, 0.55) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.fast }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copy(row.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        // kind glyph, the color itself, or the image
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: Math.max(0, Theme.innerRadius - 2)
                            color: row.modelData.kind === "color" ? root.hexColor(row.modelData.preview) : Theme.alpha(row.kind.tint, 0.14)
                            border.width: row.modelData.kind === "color" ? 1 : 0
                            border.color: Theme.cardBorder
                            clip: true

                            Text {
                                anchors.centerIn: parent
                                visible: row.modelData.kind !== "color" && thumb.status !== Image.Ready
                                text: row.kind.icon
                                color: row.kind.tint
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize + 5
                            }

                            Image {
                                id: thumb
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 88
                                sourceSize.height: 88
                                asynchronous: true
                                cache: false
                            }

                            Process {
                                running: row.modelData.kind === "image"
                                command: [Theme.bin.clipboard, "thumb", row.modelData.store, row.modelData.id, row.modelData.ext ?? "png"]
                                stdout: StdioCollector {
                                    onStreamFinished: if (text.trim() !== "") thumb.source = "file://" + text.trim()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.kind === "image" ? row.modelData.ext.toUpperCase() + " image"
                                    : row.modelData.kind === "binary" ? "Binary data"
                                    : row.modelData.preview
                                textFormat: Text.PlainText
                                color: Theme.foreground
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Row {
                                spacing: 6

                                Text {
                                    text: row.kind.label
                                    color: row.kind.tint
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                    font.bold: true
                                }
                                Text {
                                    visible: row.modelData.kind === "image"
                                    text: "· " + row.modelData.width + "×" + row.modelData.height + " · " + row.modelData.size
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                }
                                Text {
                                    visible: row.pinned && root.tab === "history"
                                    text: Icons.pin
                                    color: Theme.yellow
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                }
                            }
                        }

                        IconButton {
                            id: pinButton
                            visible: row.hovered || row.selected
                            size: 30
                            icon: row.pinned ? Icons.pinOff : Icons.pinOutline
                            tint: Theme.yellow
                            onClicked: {
                                Clipboard.togglePin(row.modelData)
                                root.toNormal()
                            }
                        }
                        IconButton {
                            id: deleteButton
                            visible: row.hovered || row.selected
                            size: 30
                            icon: Icons.trash
                            tint: Theme.red
                            onClicked: {
                                Clipboard.remove(row.modelData)
                                root.toNormal()
                            }
                        }
                    }
                }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: Theme.fast; easing.type: Easing.OutCubic }
                }

                // empty tab, or nothing matches
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: root.entries.length === 0
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.terms.length > 0 ? Icons.search : root.tab === "pinned" ? Icons.pinOutline : Icons.clipboardEmpty
                        color: Theme.muted
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 18
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.terms.length > 0 ? "Nothing matches"
                            : root.tab === "pinned" ? "Nothing pinned" : "Clipboard is empty"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 1
                        font.bold: true
                    }
                    Caption {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.terms.length > 0 ? "Esc drops the filter"
                            : root.tab === "pinned" ? "p on an entry keeps it here"
                            : "Anything you copy shows up here"
                        color: Theme.muted
                    }
                }
            }

            // the selected entry in full
            Rectangle {
                id: preview
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.innerRadius
                color: Theme.well
                clip: true

                readonly property var entry: root.selected
                readonly property var kind: entry ? root.kinds[entry.kind] : root.kinds.text

                Caption {
                    anchors.centerIn: parent
                    visible: !preview.entry
                    text: "Nothing selected"
                    color: Theme.muted
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: !!preview.entry
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            implicitWidth: chip.implicitWidth + 16
                            implicitHeight: chip.implicitHeight + 6
                            radius: height / 2
                            color: Theme.alpha(chip.color, 0.15)

                            Text {
                                id: chip
                                anchors.centerIn: parent
                                text: preview.kind.icon + "  " + preview.kind.label
                                color: preview.kind.tint
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize - 1
                                font.bold: true
                            }
                        }

                        Text {
                            visible: !!preview.entry && Clipboard.isPinned(preview.entry)
                            text: Icons.pin + " Pinned"
                            color: Theme.yellow
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize - 1
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Caption {
                            color: Theme.muted
                            text: {
                                const e = preview.entry
                                if (!e) return ""
                                if (e.kind === "image") return e.width + "×" + e.height + "  ·  " + e.size
                                if (e.kind === "color" || e.kind === "binary" || !root.detailReady) return ""
                                const chars = root.detail.length >= 20000 ? "20000+ chars" : root.plural(root.detail.length, "char")
                                return chars + "  ·  " + root.plural(root.detail.split("\n").length, "line")
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.cardBorder
                    }

                    // image
                    Image {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: preview.entry?.kind === "image"
                        source: preview.entry?.kind === "image" && root.detailReady ? "file://" + root.detail.trim() : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        smooth: true
                        mipmap: true
                    }

                    // color: a big swatch and its values
                    ColumnLayout {
                        id: swatch
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: preview.entry?.kind === "color"
                        spacing: 12

                        readonly property color value: preview.entry?.kind === "color" ? root.hexColor(preview.entry.preview) : "transparent"

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.innerRadius
                            color: swatch.value
                            border.color: Theme.cardBorder
                            border.width: 1
                        }
                        Text {
                            text: preview.entry?.preview ?? ""
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize + 6
                            font.bold: true
                        }
                        Caption {
                            readonly property color c: swatch.value
                            text: "rgb(" + Math.round(c.r * 255) + ", " + Math.round(c.g * 255) + ", " + Math.round(c.b * 255)
                                + (c.a < 1 ? ", " + c.a.toFixed(2) : "") + ")"
                        }
                    }

                    // text and the rest
                    Flickable {
                        id: textView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !!preview.entry && !["image", "color"].includes(preview.entry.kind)
                        contentHeight: fullText.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: fullText
                            width: textView.width
                            text: {
                                const e = preview.entry
                                if (!e) return ""
                                if (e.kind === "binary") return e.preview
                                return root.detailReady ? root.detail : e.preview
                            }
                            onTextChanged: textView.contentY = 0
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAnywhere
                            color: preview.entry?.kind === "link" ? Theme.blue : Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize
                            lineHeight: 1.15
                        }
                    }
                }
            }
        }

        // the (i) tab: every key, by section, in two columns
        Rectangle {
            anchors.fill: parent
            visible: root.showKeys
            radius: Theme.innerRadius
            color: Theme.well

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    spacing: 10

                    Text {
                        text: Icons.keyboard
                        color: Theme.accent
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 8
                    }
                    ColumnLayout {
                        spacing: 0

                        Text {
                            text: "Keys"
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize + 3
                            font.bold: true
                        }
                        Caption {
                            text: "Vim style: it opens in normal mode, / to type a search"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 32

                    Repeater {
                        model: [root.keymap.slice(0, 2), root.keymap.slice(2)]

                        ColumnLayout {
                            id: keyColumn
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 14

                            Repeater {
                                model: keyColumn.modelData

                                ColumnLayout {
                                    id: section
                                    required property var modelData
                                    spacing: 7

                                    Text {
                                        text: section.modelData.name
                                        color: Theme.accent
                                        font.family: Theme.font
                                        font.pointSize: Theme.popupFontSize - 1
                                        font.bold: true
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }

                                    Repeater {
                                        model: section.modelData.binds

                                        RowLayout {
                                            id: bind
                                            required property var modelData
                                            spacing: 12

                                            KeyCaps {
                                                Layout.preferredWidth: 140
                                                keys: bind.modelData.keys
                                            }
                                            Text {
                                                text: bind.modelData.title
                                                color: Theme.foreground
                                                font.family: Theme.font
                                                font.pointSize: Theme.popupFontSize
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- footer: the main keys, or the D waiting for its second press -------
    Item {
        Layout.fillWidth: true
        implicitHeight: hints.implicitHeight

        Row {
            id: hints
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            visible: !root.armed && !root.showKeys

            Hint { keys: ["j", "k"]; label: "Move" }
            Hint { keys: ["y"]; label: "Copy" }
            Hint { keys: ["p"]; label: root.selected && Clipboard.isPinned(root.selected) ? "Unpin" : "Pin" }
            Hint { keys: ["dd"]; label: "Delete" }
            Hint { keys: ["h", "l"]; label: "Tabs" }
            Hint { keys: ["/"]; label: "Search" }
            Hint { keys: ["?"]; label: "All keys" }
            Hint { keys: ["q"]; label: "Close" }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            visible: root.showKeys

            Hint { keys: ["?", "Esc"]; label: "Back to the list" }
            Hint { keys: ["q"]; label: "Close" }
        }

        Caption {
            anchors.centerIn: parent
            visible: root.armed
            text: "D again to clear " + (root.tab === "pinned" ? "every pin" : "the history") + "  ·  any other key cancels"
            color: Theme.red
            font.bold: true
        }
    }
}
