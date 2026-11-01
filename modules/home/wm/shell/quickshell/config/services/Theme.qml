pragma Singleton
import QtQuick
import Quickshell

// The palette (themes.palette) from the generated Stylix.qml; components never use a literal color.
Singleton {
    id: root

    readonly property color base: Stylix.base00
    readonly property color mantle: Stylix.base01
    readonly property color surface: Stylix.base02
    readonly property color overlay: Stylix.base03
    readonly property color subtext: Stylix.base04
    readonly property color text: Stylix.base05
    readonly property color bright: Stylix.base06
    readonly property color red: Stylix.base08
    readonly property color orange: Stylix.base09
    readonly property color yellow: Stylix.base0A
    readonly property color green: Stylix.base0B
    readonly property color cyan: Stylix.base0C
    readonly property color blue: Stylix.base0D
    readonly property color accent: Stylix.base0E

    readonly property string font: Stylix.monoFont
    readonly property real fontSize: Stylix.fontSize
    readonly property real popupFontSize: Stylix.popupFontSize

    readonly property int radius: Stylix.radius
    readonly property int innerRadius: radius - 4
    readonly property real glass: Stylix.opacity
    // Panels float this far from the screen edges and from waybar,
    // matching niri's window gaps.
    readonly property int gap: Stylix.gap
    readonly property int pad: 14

    // compass: shows the power-profile tile.
    readonly property bool laptop: Stylix.laptop

    readonly property var bin: Stylix.bin
    readonly property var signals: Stylix.signals

    // hakuspace eases everything with cubic-bezier(0, 0.5, 0.35, 1).
    readonly property var easing: [0, 0.5, 0.35, 1, 1, 1]
    readonly property int fast: 180
    readonly property int slow: 420

    // Card look shared by every panel and the OSD.
    readonly property color cardColor: alpha(base, glass)
    readonly property color cardBorder: alpha(surface, 0.9)
    readonly property color well: alpha(surface, 0.45)

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    // For untrusted strings shown in StyledText labels.
    function plain(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    // Make waybar re-run a custom module fed by Quickshell over IPC.
    function signalBar(n) {
        Quickshell.execDetached([bin.pkill, "--signal", "RTMIN+" + n, "waybar"])
    }
}
