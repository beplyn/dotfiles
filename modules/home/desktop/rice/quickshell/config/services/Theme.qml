pragma Singleton
import QtQuick
import Quickshell

// palette from the generated Stylix.qml; never use literal colors
Singleton {
    id: root

    readonly property color background: Stylix.background
    readonly property color mantle: Stylix.mantle
    readonly property color surface: Stylix.surface
    readonly property color muted: Stylix.muted
    readonly property color subtext: Stylix.subtext
    readonly property color foreground: Stylix.foreground
    readonly property color bright: Stylix.bright
    readonly property color red: Stylix.red
    readonly property color orange: Stylix.orange
    readonly property color yellow: Stylix.yellow
    readonly property color green: Stylix.green
    readonly property color cyan: Stylix.cyan
    readonly property color blue: Stylix.blue
    readonly property color accent: Stylix.accent

    readonly property string font: Stylix.monoFont
    readonly property real fontSize: Stylix.fontSize
    readonly property real popupFontSize: Stylix.popupFontSize

    readonly property int radius: Stylix.radius
    // sharp, architectural: controls and bars are barely rounded
    readonly property int innerRadius: 2
    readonly property int radiusSm: 2
    readonly property real glass: Stylix.opacity
    // Panels float this far from the screen edges and from waybar,
    // matching Hyprland's window gaps.
    readonly property int gap: Stylix.gap
    // spacing between items, and padding inside surfaces
    readonly property int gapXs: 4
    readonly property int gapSm: 8
    readonly property int gapMd: 12
    readonly property int gapLg: 16
    readonly property int gapXl: 24
    readonly property int gapXxl: 48
    readonly property int padXs: 6
    readonly property int padSm: 10
    readonly property int padMd: 14
    readonly property int padLg: 20
    readonly property int pad: padMd
    // from the screen edges, matching Hyprland's window gap
    readonly property int screenMargin: gap

    // Nerd Font glyph sizes, relative to popupFontSize
    readonly property int iconSm: popupFontSize + 1
    readonly property int iconMd: popupFontSize + 4
    readonly property int iconLg: popupFontSize + 8
    readonly property int iconXl: popupFontSize + 14
    // fixed glyph width, so icons don't shift the text beside them
    readonly property int iconBox: 24

    // shulker: shows the power-profile tile.
    readonly property bool laptop: Stylix.laptop

    // the calendar folder Events reads and writes (calendar.nix)
    readonly property string calendarDb: Stylix.calendarDb

    // the recoloured wallpapers (quickshell/wallpaper.nix)
    readonly property string wallpapers: Stylix.wallpapers

    readonly property var bin: Stylix.bin
    readonly property var signals: Stylix.signals
    // [{ name, binds: [{ key, title }] }], titled binds by section
    readonly property var hotkeys: Stylix.hotkeys

    // hakuspace eases everything with cubic-bezier(0, 0.5, 0.35, 1).
    readonly property var easing: [0, 0.5, 0.35, 1, 1, 1]
    readonly property int quick: 120
    readonly property int fast: 180
    readonly property int slow: 420
    // stat ring sweep; progress bars glide between polls
    readonly property int ring: 600
    readonly property int progress: 1000

    // tabular figures for clocks, percentages and counters
    readonly property var numeric: ({ "tnum": 1 })

    // One flat surface for every panel, popup and the OSD: base00 nearly
    // opaque, an accent hairline, no nested boxes.
    readonly property real surfaceOpacity: 0.94
    readonly property color cardColor: alpha(background, surfaceOpacity)
    readonly property color cardBorder: alpha(accent, 0.55)
    // no recessed wells; sections are separated by dividers, not boxes
    readonly property color well: "transparent"
    readonly property color idleBorder: surface
    readonly property color hover: alpha(foreground, 0.05)

    // Active = base0D: a faint tint and a hairline, never a solid fill.
    readonly property color activeColor: blue
    readonly property color activeTint: alpha(blue, 0.14)

    // hairlines everywhere; strong for selected and focused edges
    readonly property int borderWidth: 1
    readonly property int borderWidthStrong: 2
    readonly property color borderColor: cardBorder
    // slider and progress bars: flat, thin, no knob
    readonly property int trackHeight: 2
    readonly property int dotSize: 4

    // section headers: small, uppercase, tracked
    readonly property int micro: popupFontSize - 3
    readonly property real tracking: 1.2

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
