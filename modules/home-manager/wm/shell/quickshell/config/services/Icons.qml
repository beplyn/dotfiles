pragma Singleton
import QtQuick
import Quickshell

// Nerd Font glyphs from hakuspace's waybar and swaync configs, kept as
// codepoints so editors and diffs can't mangle them.
Singleton {
    function g(...cps) {
        return String.fromCodePoint(...cps)
    }

    // bar
    readonly property string logo: g(0xF0BAF)
    readonly property string music: g(0xF075A)
    readonly property string playing: g(0xF0F4)
    readonly property string paused: g(0xF04C)
    readonly property string monitor: g(0xF0D9, 0xF0E4)
    readonly property string settings: g(0xF0D9, 0xE690)
    readonly property string cpu: g(0xF2DB)
    readonly property string memory: g(0xEFC5)
    readonly property string temperature: g(0xF2C9)
    readonly property string recording: g(0xEBA7)
    readonly property var backlight: [0xE38D, 0xE3D3, 0xE3D1, 0xE3CF, 0xE3CE, 0xE3CD, 0xE3CA, 0xE3C8, 0xE39B].map(c => g(c))
    readonly property var battery: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079].map(c => g(c))
    readonly property var charging: [0xF089F, 0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D, 0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085].map(c => g(c))
    readonly property string plugged: g(0xF1E6)
    readonly property string performance: g(0xF0E7)
    readonly property string balanced: g(0xF24E)
    readonly property string powerSaver: g(0xF06C)
    readonly property var volume: [0xF026, 0xF027, 0xF028].map(c => g(c))
    readonly property string muted: g(0xF075F)
    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string dnd: g(0xF1F6)
    readonly property string dot: g(0xF444)

    // control center
    readonly property string speaker: g(0xF028)
    readonly property string brightness: g(0xF05A8)
    readonly property string wifi: g(0xF05A9)
    readonly property string bluetooth: g(0xF00AF)
    readonly property string mic: g(0xF036C)
    readonly property string micOff: g(0xF036D)
    readonly property string idle: g(0xF04B3)
    readonly property string record: g(0xF044A)
    readonly property string wallpaper: g(0xF03E)
    readonly property string power: g(0xF0906)
    readonly property string reboot: g(0xF0453)
    readonly property string lock: g(0xF456)
    readonly property string exit: g(0xF08B)
    readonly property string powerMode: g(0xF14DE)
    readonly property string noSound: g(0xF050A)

    // Picks the entry of `icons` matching a 0..100 level.
    function level(icons, pct) {
        const i = Math.round(Math.max(0, Math.min(100, pct)) / 100 * (icons.length - 1))
        return icons[i]
    }
}
