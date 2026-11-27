pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light on a sunset ramp, through hyprsunset. From 5 minutes before sunset
// the warmth climbs from neutral to `warmest` over 3 hours, holds there, and
// goes back to neutral at sunrise.
// Scrolling the tile sets `warmest`; clicking it turns the schedule off or on.
Singleton {
    id: root

    // hyprsunset's no-op; `identity` would keep reporting the last temperature
    readonly property int neutral: 6000

    // Budapest, for the sunset time (timezone Europe/Budapest, modules/nixos/base/locale.nix)
    readonly property real latitude: 47.4979
    readonly property real longitude: 19.0402

    readonly property int rampLeadMs: 5 * 60 * 1000
    readonly property int rampMs: 3 * 60 * 60 * 1000
    readonly property int minWarmest: 1500
    readonly property int maxWarmest: 5000
    readonly property int step: 100

    property bool enabled: true
    // the coolest the ramp reaches after sunset (lower = warmer)
    property int warmest: 3000

    // what hyprsunset is set to right now
    property int temperature: neutral
    property string sunsetText: ""
    property int applied: -1

    function sunset(date) { return solarEvent(date, -1) }
    function sunrise(date) { return solarEvent(date, 1) }

    // NOAA's simplified solar formulas, a minute or so out; sign 1 is sunrise, -1 sunset
    function solarEvent(date, sign) {
        const r = Math.PI / 180
        const dayStart = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
        const doy = (dayStart - Date.UTC(date.getFullYear(), 0, 0)) / 86400000
        const g = 2 * Math.PI / 365 * (doy - 1)
        const eqtime = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g)
            - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g))
        const decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g)
            - 0.006758 * Math.cos(2 * g) + 0.000907 * Math.sin(2 * g)
            - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g)
        const lat = latitude * r
        const ha = Math.acos(Math.cos(90.833 * r) / (Math.cos(lat) * Math.cos(decl))
            - Math.tan(lat) * Math.tan(decl)) / r
        const utcMinutes = 720 - 4 * (longitude + sign * ha) - eqtime
        return new Date(dayStart + utcMinutes * 60000)
    }

    // warm from the evening ramp until sunrise, neutral through the day
    function temperatureAt(date) {
        const t = date.getTime()
        const from = sunset(date).getTime() - rampLeadMs
        if (t >= from) return ramp(t - from)
        const yesterday = new Date(t - 86400000)
        const nightFrom = sunset(yesterday).getTime() - rampLeadMs
        if (t >= nightFrom && t < sunrise(date).getTime()) return ramp(t - nightFrom)
        return neutral
    }

    function ramp(elapsed) {
        const frac = Math.min(1, elapsed / (rampLeadMs + rampMs))
        return Math.round(neutral + (warmest - neutral) * frac)
    }

    function apply() {
        const now = new Date()
        const t = enabled ? temperatureAt(now) : neutral
        temperature = t
        sunsetText = Qt.formatTime(sunset(now), "HH:mm")
        if (t === applied) return
        applied = t
        Quickshell.execDetached([Theme.bin.hyprctl, "hyprsunset", "temperature", String(t)])
    }

    function toggle() {
        enabled = !enabled
    }

    // wheel up: warmer, down: cooler
    function nudge(direction) {
        warmest = Math.max(minWarmest, Math.min(maxWarmest, warmest - direction * step))
    }

    onEnabledChanged: apply()
    onWarmestChanged: apply()

    // the ramp moves a little every minute; hyprsunset gets a command only on change
    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.apply()
    }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle() }
        function status(): string { return root.enabled ? root.temperature + "K" : "off" }
    }
}
