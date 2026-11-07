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
    // empty to full, as waybar's battery pill
    readonly property var battery: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079].map(c => g(c))
    readonly property string batteryCharging: g(0xF0084)
    readonly property string batteryHealth: g(0xF120F)
    readonly property string awake: g(0xF0176)
    readonly property string idle: g(0xF04B2)

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
    readonly property string chevronDown: g(0xF0140)
    readonly property string chevronUp: g(0xF0143)
    readonly property string ethernet: g(0xF0200)
    readonly property var wifiLevels: [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928].map(c => g(c))
    readonly property string check: g(0xF012C)

    // launcher
    readonly property string apps: g(0xF003B)
    readonly property string calculator: g(0xF00EC)
    readonly property string terminal: g(0xF018D)
    readonly property string web: g(0xF059F)

    // clipboard
    readonly property string clipboard: g(0xF0A38)
    readonly property string clipboardEmpty: g(0xF161B)
    readonly property string pin: g(0xF0403)
    readonly property string pinOutline: g(0xF0931)
    readonly property string pinOff: g(0xF0930)
    readonly property string trash: g(0xF09E7)
    readonly property string clearAll: g(0xF05E9)
    readonly property string search: g(0xF0349)
    readonly property string close: g(0xF0156)
    readonly property string history: g(0xF02DA)
    readonly property string text: g(0xF09AA)
    readonly property string image: g(0xF0976)
    readonly property string link: g(0xF0337)
    readonly property string palette: g(0xF03D8)
    readonly property string folder: g(0xF024B)
    readonly property string email: g(0xF01F0)
    readonly property string code: g(0xF0169)
    readonly property string number: g(0xF03A0)
    readonly property string file: g(0xF0224)
    readonly property string info: g(0xF02FD)
    readonly property string keyboard: g(0xF097B)

    // Picks the entry of `icons` matching a 0..100 level.
    function level(icons, pct) {
        const i = Math.round(Math.max(0, Math.min(100, pct)) / 100 * (icons.length - 1))
        return icons[i]
    }
}
