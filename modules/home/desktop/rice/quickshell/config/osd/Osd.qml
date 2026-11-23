import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Volume / brightness capsule on any change; click-through, quiet while the
// control center is open.
PanelWindow {
    id: root

    property string kind: "volume"
    property bool shown: false
    // Startup and sink switches report changes too; wait for things to settle.
    property bool armed: false

    readonly property real value: kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : Brightness.percent / 100
    readonly property string icon: kind === "volume"
        ? (Audio.muted ? Icons.muted : Icons.level(Icons.volume, Audio.percent))
        : Icons.level(Icons.backlight, Brightness.percent)

    function show(k) {
        if (!armed || Panels.current === "control") return
        kind = k
        shown = true
        hide.restart()
    }

    screen: Panels.focusedScreen
    visible: shown || capsule.opacity > 0
    anchors.bottom: true
    margins.bottom: 64
    implicitWidth: 320
    implicitHeight: 52
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "haku-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region {}
    BackgroundEffect.blurRegion: Region {
        item: root.shown ? capsule : null
        radius: capsule.radius
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.shown = false
    }

    Timer {
        running: true
        interval: 2000
        onTriggered: root.armed = true
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume") }
        function onMutedChanged() { root.show("volume") }
    }

    Connections {
        target: Brightness
        function onPercentChanged() { if (Brightness.ready) root.show("brightness") }
    }

    Rectangle {
        id: capsule

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.shown ? 0 : 12
        width: parent.width
        height: parent.height
        radius: height / 2
        color: Theme.cardColor
        border.color: Theme.cardBorder
        border.width: Theme.borderWidth
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easing }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.padLg
            anchors.rightMargin: Theme.padLg
            spacing: Theme.padMd

            Text {
                Layout.preferredWidth: Theme.iconBox
                horizontalAlignment: Text.AlignHCenter
                text: root.icon
                verticalAlignment: Text.AlignVCenter
                color: Theme.accent
                font.family: Theme.font
                font.pointSize: Theme.iconMd
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: Theme.radiusSm
                color: Theme.alpha(Theme.surface, 0.9)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.value * 100) + "%"
                color: Theme.foreground
                font.family: Theme.font
                font.features: Theme.numeric
                font.pointSize: Theme.popupFontSize
                font.bold: true
            }
        }
    }
}
