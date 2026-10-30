pragma Singleton
import QtQuick
import Quickshell

// Nerd Font glyphs, kept as codepoints so editors and diffs can't mangle
// them. Waybar's glyphs are picked the same way in waybar/default.nix.
Singleton {
    function g(...cps) {
        return String.fromCodePoint(...cps)
    }

    readonly property string logo: g(0xF313)

    // media
    readonly property string music: g(0xF075A)
    readonly property string play: g(0xF040A)
    readonly property string pause: g(0xF03E4)
    readonly property string previous: g(0xF04AE)
    readonly property string next: g(0xF04AD)

    // system
    readonly property string cpu: g(0xF2DB)
    readonly property string memory: g(0xEFC5)
    readonly property string temperature: g(0xF2C9)
    readonly property string uptime: g(0xF0150)
    readonly property var backlight: [0xE38D, 0xE3D3, 0xE3D1, 0xE3CF, 0xE3CE, 0xE3CD, 0xE3CA, 0xE3C8, 0xE39B].map(c => g(c))
    readonly property string performance: g(0xF0E7)
    readonly property string balanced: g(0xF24E)
    readonly property string powerSaver: g(0xF06C)

    // audio
    readonly property var volume: [0xF026, 0xF027, 0xF028].map(c => g(c))
    readonly property string muted: g(0xF075F)
    readonly property string speaker: g(0xF028)
    readonly property string mic: g(0xF036C)
    readonly property string micOff: g(0xF036D)
    readonly property string noSound: g(0xF050A)
    readonly property string mixer: g(0xF062E)

    // notifications
    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string dnd: g(0xF1F6)

    // control center
    readonly property string brightness: g(0xF05A8)
    readonly property string wifi: g(0xF05A9)
    readonly property string wifiOff: g(0xF05AA)
    readonly property string bluetooth: g(0xF00AF)
    readonly property string bluetoothOff: g(0xF00B2)
    readonly property string record: g(0xF044A)
    readonly property string wallpaper: g(0xF03E)
    readonly property string shuffle: g(0xF049D)
    readonly property string power: g(0xF0906)
    readonly property string reboot: g(0xF0453)
    readonly property string lock: g(0xF033E)
    readonly property string exit: g(0xF0343)
    readonly property string sleep: g(0xF0904)
    readonly property string chevronLeft: g(0xF0141)
    readonly property string chevronRight: g(0xF0142)
    readonly property string ethernet: g(0xF0200)
    readonly property var wifiLevels: [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928].map(c => g(c))
    readonly property string check: g(0xF012C)

    // Picks the entry of `icons` matching a 0..100 level.
    function level(icons, pct) {
        const i = Math.round(Math.max(0, Math.min(100, pct)) / 100 * (icons.length - 1))
        return icons[i]
    }
}
