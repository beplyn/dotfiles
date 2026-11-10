import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Apps, sums, shell lines and web searches (Mod+Space), the clipboard panel's
// look and vim keys. Unlike it, it opens typing: Esc drops to normal mode
// (j/k, Enter, p, 1-9), / or i types again, ? or the (i) tab lists every key.
// With nothing typed it is only the search bar.
Panel {
    id: root

    name: "launcher"
    align: Qt.AlignHCenter
    cardWidth: 800
    spacing: 12

    property string tab: "apps"
    // the (i) tab: every key, over the list
    property bool showKeys: false
    property int current: 0
    // the first key of gg, as vim's showcmd
    property string pending: ""

    readonly property bool searching: search.activeFocus
    // nothing typed: only the search bar, until l or ? asks for more
    readonly property bool minimal: query === "" && tab === "apps" && !showKeys

    readonly property var kinds: ({
        app: { icon: Icons.apps, label: "App", tint: Theme.accent },
        calc: { icon: Icons.calculator, label: "Calc", tint: Theme.green },
        run: { icon: Icons.terminal, label: "Run", tint: Theme.yellow },
        web: { icon: Icons.web, label: "Web", tint: Theme.blue }
    })

    // The (i) tab, and the footer's picks from it.
    readonly property var keymap: [
        { name: "Move", binds: [
            { keys: ["j", "k"], title: "Down / up (or arrows)" },
            { keys: ["gg", "G"], title: "First / last" },
            { keys: ["Ctrl+d", "Ctrl+u"], title: "Half a page down / up" },
            { keys: ["h", "l"], title: "Apps / pinned" },
            { keys: ["Tab"], title: "The other tab" }
        ] },
        { name: "Entry", binds: [
            { keys: ["y", "Enter"], title: "Launch and close" },
            { keys: ["1-9"], title: "An app's action" },
            { keys: ["p"], title: "Pin / unpin" }
        ] },
        { name: "Search", binds: [
            { keys: ["/", "i"], title: "Search" },
            { keys: ["Enter"], title: "Launch the selection" },
            { keys: ["Esc"], title: "Normal mode, then drop the filter" },
            { keys: ["Ctrl+j", "Ctrl+k"], title: "Move while typing" },
            { keys: ["1+2"], title: "A sum: Enter copies it" }
        ] },
        { name: "Panel", binds: [
            { keys: ["?"], title: "These keys" },
            { keys: ["q", "Esc"], title: "Close" }
        ] }
    ]

    readonly property var source: tab === "pinned" ? Launcher.pinned : Launcher.apps
    readonly property string query: search.text.trim()
    readonly property var terms: query.toLowerCase().split(/\s+/).filter(t => t !== "")

    // "2*(3+4)" -> 14; null for anything that isn't a plain sum
    readonly property var sum: {
        if (!/^[\d\s.+\-*/%^()]+$/.test(query) || !/\d/.test(query) || !/[+\-*/%^]/.test(query)) return null
        try {
            const r = Function("return (" + query.replace(/\^/g, "**") + ")")()
            return typeof r === "number" && isFinite(r) ? String(Number(r.toPrecision(12))) : null
        } catch (e) {
            return null
        }
    }

    // How well an app's name fits the search: lower is better.
    function rank(app) {
        const n = app.name.toLowerCase()
        const q = terms.join(" ")
        if (n === q) return 0
        if (n.startsWith(q)) return 1
        if (n.split(/[\s\-_.]+/).some(w => w.startsWith(terms[0]))) return 2
        if (n.includes(terms[0])) return 3
        return 4
    }

    // every word somewhere in the app; on the apps tab a sum, then the
    // matches, then the line to run and the web search
    readonly property var entries: {
        if (terms.length === 0) return source
        const apps = source.filter(a => terms.every(t => a.hay.includes(t)))
            .map(a => ({ app: a, rank: rank(a) }))
            .sort((a, b) => a.rank - b.rank)
            .map(m => m.app)
        if (tab === "pinned") return apps
        const out = []
        if (sum !== null) out.push({ key: "calc", kind: "calc", name: sum, input: query })
        return out.concat(apps, [
            { key: "run", kind: "run", name: query },
            { key: "web", kind: "web", name: query }
        ])
    }
    readonly property var selected: entries.length > 0 ? entries[Math.min(current, entries.length - 1)] : null
    readonly property var actions: selected?.kind === "app" ? Array.from(selected.entry.actions) : []

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

    function activate(entry, action) {
        if (!entry || minimal) return
        if (entry.kind === "app") Launcher.launch(entry, action)
        else if (entry.kind === "calc") Launcher.copy(entry.name)
        else if (entry.kind === "run") Launcher.run(entry.name)
        else if (entry.kind === "web") Launcher.web(entry.name)
        Panels.close()
    }

    function togglePin(entry) {
        if (entry?.kind === "app") Launcher.togglePin(entry)
    }

    function iconSource(icon) {
        if (!icon) return ""
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, true)
    }

    readonly property var modifierKeys: [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R]

    function normalKey(e) {
        if (modifierKeys.includes(e.key)) return
        const ctrl = e.modifiers & Qt.ControlModifier
        const t = e.text
        const prefix = pending
        const half = Math.max(1, Math.floor(list.height / 64 / 2))
        pending = ""

        if (showKeys) {
            if (t === "h") setTab("apps")
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
        else if (t === "h") setTab("apps")
        else if (t === "l") setTab("pinned")
        else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) setTab(tab === "apps" ? "pinned" : "apps")
        else if (t === "y" || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) activate(selected)
        else if (/^[1-9]$/.test(t)) {
            if (+t <= actions.length) activate(selected, actions[+t - 1])
        }
        else if (t === "p") togglePin(selected)
        else if (t === "/" || t === "i") search.forceActiveFocus()
        else if (t === "?") showKeys = true
        else if (t === "q") Panels.close()
        else if (e.key === Qt.Key_Escape) {
            if (search.text !== "") search.text = ""
            else Panels.close()
        }
        else return
        e.accepted = true
    }

    onEntriesChanged: if (current >= entries.length) current = Math.max(0, entries.length - 1)
    onCurrentChanged: list.positionViewAtIndex(current, ListView.Contain)
    onPendingChanged: if (pending !== "") pendingReset.restart()

    onOpenChanged: {
        if (!open) return
        tab = "apps"
        showKeys = false
        current = 0
        pending = ""
        search.text = ""
        Qt.callLater(() => search.forceActiveFocus())
    }

    // a lone g is dropped after a second, as vim's timeoutlen
    Timer {
        id: pendingReset
        interval: 1000
        onTriggered: root.pending = ""
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

    // An app's icon from the theme, or the kind's glyph when it has none.
    component Glyph: Rectangle {
        id: glyph
        property var entry: null
        property int glyphSize: Theme.popupFontSize + 5
        readonly property var kind: entry ? root.kinds[entry.kind] : root.kinds.app

        radius: Math.max(0, Theme.innerRadius - 2)
        color: icon.status === Image.Ready ? "transparent" : Theme.alpha(kind.tint, 0.14)

        Text {
            anchors.centerIn: parent
            visible: icon.status !== Image.Ready
            text: glyph.kind.icon
            color: glyph.kind.tint
            font.family: Theme.font
            font.pointSize: glyph.glyphSize
        }

        Image {
            id: icon
            anchors.fill: parent
            anchors.margins: 4
            source: glyph.entry?.kind === "app" ? root.iconSource(glyph.entry.icon) : ""
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    // --- header: title, tabs ----------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        visible: !root.minimal
        spacing: 12

        Rectangle {
            implicitWidth: 42
            implicitHeight: 42
            radius: 21
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: Icons.apps
                color: Theme.background
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 5
            }
        }

        ColumnLayout {
            spacing: 0

            Text {
                text: "Launcher"
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 4
                font.bold: true
            }
            Caption {
                text: Launcher.apps.length + (Launcher.apps.length === 1 ? " app" : " apps") + "  ·  " + Launcher.pinned.length + " pinned"
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Apps | Pinned | (i), the highlight sliding between them
        Rectangle {
            id: tabs
            readonly property var items: [
                { key: "apps", icon: Icons.apps, label: "Apps", count: Launcher.apps.length, width: 132 },
                { key: "pinned", icon: Icons.pin, label: "Pinned", count: Launcher.pinned.length, width: 132 },
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
                    text: root.searching ? "An app, a sum or a command; Esc for normal mode" : "Press / to search, ? for keys"
                    color: Theme.muted
                    font: search.font
                }

                Keys.onPressed: e => {
                    const ctrl = e.modifiers & Qt.ControlModifier
                    if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) root.select(root.current + 1)
                    else if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) root.select(root.current - 1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.activate(root.selected)
                    else if (e.key === Qt.Key_Escape) root.toNormal()
                    else return
                    e.accepted = true
                }
            }

            // showcmd: the waiting g
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
                text: root.entries.filter(e => e.kind === "app").length + " / " + root.source.length
            }
        }
    }

    // --- list and preview, or the keys --------------------------------------
    Item {
        Layout.fillWidth: true
        visible: !root.minimal
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
                    readonly property bool isApp: modelData.kind === "app"
                    readonly property bool selected: index === root.current
                    readonly property bool pinned: isApp && Launcher.isPinned(modelData)
                    readonly property bool hovered: rowMouse.containsMouse || pinButton.hovered

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
                        onClicked: root.activate(row.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Glyph {
                            implicitWidth: 44
                            implicitHeight: 44
                            entry: row.modelData
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.kind === "calc" ? "= " + row.modelData.name
                                    : row.modelData.kind === "run" ? "$ " + row.modelData.name
                                    : row.modelData.kind === "web" ? "Search “" + row.modelData.name + "”"
                                    : row.modelData.name
                                textFormat: Text.PlainText
                                color: Theme.foreground
                                font.family: Theme.font
                                font.pointSize: Theme.popupFontSize
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: row.kind.label
                                    color: row.kind.tint
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    readonly property string detail: row.modelData.kind === "calc" ? row.modelData.input
                                        : row.modelData.kind === "run" ? "in sh"
                                        : row.modelData.kind === "web" ? "Google"
                                        : row.modelData.generic || row.modelData.comment
                                    visible: detail !== ""
                                    text: "· " + detail
                                    textFormat: Text.PlainText
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: row.pinned && root.tab === "apps"
                                    text: Icons.pin
                                    color: Theme.yellow
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize - 2
                                }
                            }
                        }

                        IconButton {
                            id: pinButton
                            visible: row.isApp && (row.hovered || row.selected)
                            size: 30
                            icon: row.pinned ? Icons.pinOff : Icons.pinOutline
                            tint: Theme.yellow
                            onClicked: {
                                Launcher.togglePin(row.modelData)
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

                // no pins, or nothing pinned matches
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: root.entries.length === 0
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.terms.length > 0 ? Icons.search : root.tab === "pinned" ? Icons.pinOutline : Icons.apps
                        color: Theme.muted
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 18
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.terms.length > 0 ? "Nothing matches"
                            : root.tab === "pinned" ? "Nothing pinned" : "No apps found"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 1
                        font.bold: true
                    }
                    Caption {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.terms.length > 0 ? "Esc twice drops the filter"
                            : root.tab === "pinned" ? "p on an app keeps it here"
                            : "No .desktop files on XDG_DATA_DIRS"
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
                readonly property var kind: entry ? root.kinds[entry.kind] : root.kinds.app
                readonly property bool isApp: entry?.kind === "app"

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
                            visible: preview.isApp && Launcher.isPinned(preview.entry)
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
                                if (!preview.isApp) return ""
                                const n = Launcher.counts[preview.entry.id] ?? 0
                                return n === 0 ? "Never launched" : "Launched " + n + (n === 1 ? " time" : " times")
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.cardBorder
                    }

                    // app: icon, name, what it is, the command and its actions
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: preview.isApp
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Glyph {
                                implicitWidth: 64
                                implicitHeight: 64
                                glyphSize: Theme.popupFontSize + 16
                                entry: preview.isApp ? preview.entry : null
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: preview.entry?.name ?? ""
                                    textFormat: Text.PlainText
                                    color: Theme.foreground
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize + 4
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Caption {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: preview.isApp ? preview.entry.generic : ""
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: preview.isApp ? preview.entry.comment : ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize
                            lineHeight: 1.15
                        }

                        Text {
                            Layout.fillWidth: true
                            text: preview.isApp ? preview.entry.entry.execString : ""
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize - 1
                        }

                        // the .desktop actions, on 1-9
                        Repeater {
                            model: root.actions.slice(0, 9)

                            RowLayout {
                                id: actionRow
                                required property var modelData
                                required property int index
                                spacing: 10

                                Cap {
                                    text: actionRow.index + 1
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: actionRow.modelData.name
                                    textFormat: Text.PlainText
                                    color: actionMouse.containsMouse ? Theme.accent : Theme.foreground
                                    font.family: Theme.font
                                    font.pointSize: Theme.popupFontSize
                                    elide: Text.ElideRight

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activate(preview.entry, actionRow.modelData)
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // calc, run, web: the input and what Enter does with it
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !!preview.entry && !preview.isApp
                        spacing: 12

                        Caption {
                            Layout.fillWidth: true
                            visible: preview.entry?.kind === "calc"
                            text: preview.entry?.input ?? ""
                            textFormat: Text.PlainText
                            font.pointSize: Theme.popupFontSize + 2
                        }
                        Text {
                            Layout.fillWidth: true
                            text: preview.entry?.kind === "calc" ? "= " + preview.entry.name : preview.entry?.name ?? ""
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAnywhere
                            color: preview.entry?.kind === "calc" ? Theme.green : preview.entry?.kind === "web" ? Theme.blue : Theme.foreground
                            font.family: Theme.font
                            font.pointSize: preview.entry?.kind === "calc" ? Theme.popupFontSize + 10 : Theme.popupFontSize + 2
                            font.bold: true
                        }
                        Caption {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: Theme.muted
                            text: preview.entry?.kind === "calc" ? "Enter copies the result"
                                : preview.entry?.kind === "run" ? "Enter runs it in sh, on its own"
                                : "Enter opens a Google search in the browser"
                        }

                        Item {
                            Layout.fillHeight: true
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
                            text: "Vim style: it opens typing, Esc for normal mode"
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

    // --- footer: the main keys of the mode it's in -------------------------
    Item {
        Layout.fillWidth: true
        visible: !root.minimal
        implicitHeight: hints.implicitHeight

        Row {
            id: hints
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            visible: !root.showKeys && !root.searching

            Hint { keys: ["j", "k"]; label: "Move" }
            Hint { keys: ["Enter"]; label: "Launch" }
            Hint { keys: ["1-9"]; label: "Actions" }
            Hint { keys: ["p"]; label: root.selected && root.selected.kind === "app" && Launcher.isPinned(root.selected) ? "Unpin" : "Pin" }
            Hint { keys: ["h", "l"]; label: "Tabs" }
            Hint { keys: ["/"]; label: "Search" }
            Hint { keys: ["?"]; label: "All keys" }
            Hint { keys: ["q"]; label: "Close" }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            visible: !root.showKeys && root.searching

            Hint { keys: ["Ctrl+j", "Ctrl+k"]; label: "Move" }
            Hint { keys: ["Enter"]; label: "Launch" }
            Hint { keys: ["Esc"]; label: "Normal mode" }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            visible: root.showKeys

            Hint { keys: ["?", "Esc"]; label: "Back to the list" }
            Hint { keys: ["q"]; label: "Close" }
        }
    }
}
