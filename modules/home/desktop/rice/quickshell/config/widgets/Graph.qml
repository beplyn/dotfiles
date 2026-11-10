import QtQuick
import qs.services

// Line graph of `values` in [min, max]; `length` samples fill the width from
// the right. A null value is a gap: the line and fill break around it.
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
        ctx.strokeStyle = Theme.alpha(Theme.muted, 0.35)
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

        // runs of consecutive values, each drawn on its own; a lone point
        // gets a dot
        const runs = []
        let run = null
        for (let i = 0; i < n; i++) {
            if (values[i] === null || values[i] === undefined) {
                run = null
            } else {
                if (!run) runs.push(run = [])
                run.push(i)
            }
        }

        const fill = ctx.createLinearGradient(0, 0, 0, h)
        fill.addColorStop(0, Theme.alpha(color, 0.35))
        fill.addColorStop(1, Theme.alpha(color, 0.02))
        ctx.lineJoin = "round"
        ctx.lineWidth = 2
        ctx.strokeStyle = color
        ctx.fillStyle = fill

        for (const r of runs) {
            const x = i => x0 + i * step
            if (r.length === 1) {
                ctx.beginPath()
                ctx.arc(x(r[0]), y(values[r[0]]), 2, 0, 2 * Math.PI)
                ctx.fillStyle = color
                ctx.fill()
                ctx.fillStyle = fill
                continue
            }
            ctx.beginPath()
            ctx.moveTo(x(r[0]), y(values[r[0]]))
            for (const i of r.slice(1)) ctx.lineTo(x(i), y(values[i]))
            ctx.stroke()

            ctx.lineTo(x(r[r.length - 1]), h)
            ctx.lineTo(x(r[0]), h)
            ctx.closePath()
            ctx.fill()
        }
    }
}
