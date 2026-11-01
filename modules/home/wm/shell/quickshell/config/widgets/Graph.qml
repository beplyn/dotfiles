import QtQuick
import qs.services

// Line graph of `values` in [min, max]; `length` samples fill the width from the right.
Canvas {
    id: root

    property var values: []
    property real min: 0
    property real max: 100
    property int length: values.length
    property color color: Theme.accent

    implicitHeight: 140

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        const w = width, h = height
        const pad = 2

        // Quarter gridlines.
        ctx.strokeStyle = Theme.alpha(Theme.overlay, 0.35)
        ctx.lineWidth = 1
        ctx.setLineDash([3, 4])
        for (let i = 1; i < 4; i++) {
            const y = Math.round(h * i / 4) + 0.5
            ctx.beginPath()
            ctx.moveTo(0, y)
            ctx.lineTo(w, y)
            ctx.stroke()
        }
        ctx.setLineDash([])

        const n = values.length
        if (n < 2) return

        const step = w / Math.max(1, length - 1)
        const x0 = w - (n - 1) * step
        const span = Math.max(1e-6, max - min)
        const y = v => pad + (h - pad * 2) * (1 - Math.max(0, Math.min(1, (v - min) / span)))

        ctx.beginPath()
        ctx.moveTo(x0, y(values[0]))
        for (let i = 1; i < n; i++) ctx.lineTo(x0 + i * step, y(values[i]))

        ctx.lineJoin = "round"
        ctx.lineWidth = 2
        ctx.strokeStyle = color
        ctx.stroke()

        ctx.lineTo(w, h)
        ctx.lineTo(x0, h)
        ctx.closePath()
        const fill = ctx.createLinearGradient(0, 0, 0, h)
        fill.addColorStop(0, Theme.alpha(color, 0.35))
        fill.addColorStop(1, Theme.alpha(color, 0.02))
        ctx.fillStyle = fill
        ctx.fill()
    }
}
