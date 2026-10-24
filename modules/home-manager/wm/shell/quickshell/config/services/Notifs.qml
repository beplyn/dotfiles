pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon replacing swaync. Every notification stays in the
// center until dismissed; popups are just the subset still on screen.
Singleton {
    id: root

    property bool dnd: false
    property bool centerOpen: false
    property var popupIds: []
    property var arrived: ({})
    property real now: Date.now()

    // Relative timestamp, like swaync's relative-timestamps.
    function age(id) {
        const t = arrived[id]
        if (t === undefined) return ""
        const mins = Math.floor((now - t) / 60000)
        if (mins < 1) return "now"
        if (mins < 60) return mins + "m"
        if (mins < 1440) return Math.floor(mins / 60) + "h"
        return Math.floor(mins / 1440) + "d"
    }

    Timer {
        interval: 30000
        running: root.count > 0
        repeat: true
        onTriggered: root.now = Date.now()
    }

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length
    readonly property var popups: list.filter(n => popupIds.includes(n.id))

    // hakuspace's swaync timeouts: 4s normal, 2s low, critical stays.
    function timeoutFor(n) {
        if (n.urgency === NotificationUrgency.Critical) return 0
        if (n.expireTimeout > 0) return n.expireTimeout
        return n.urgency === NotificationUrgency.Low ? 2000 : 4000
    }

    function hidePopup(id) {
        popupIds = popupIds.filter(p => p !== id)
    }

    function clearAll() {
        for (const n of list.slice()) n.dismiss()
        popupIds = []
    }

    function toggleCenter() {
        centerOpen = !centerOpen
        if (centerOpen) popupIds = []
    }

    // Default action if the sender offered one, else just close it.
    function activate(n) {
        const def = n.actions.find(a => a.identifier === "default")
        if (def) def.invoke()
        else n.dismiss()
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false

        onNotification: n => {
            const id = n.id
            n.tracked = true
            root.now = Date.now()
            root.arrived = Object.assign({}, root.arrived, { [id]: root.now })
            if (!root.dnd && !root.centerOpen && !root.popupIds.includes(id))
                root.popupIds = root.popupIds.concat([id])
            n.closed.connect(() => root.hidePopup(id))
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggleCenter() }
        function open(): void { root.centerOpen = true; root.popupIds = [] }
        function close(): void { root.centerOpen = false }
        function toggleDnd(): void { root.dnd = !root.dnd }
        function clear(): void { root.clearAll() }
    }
}
