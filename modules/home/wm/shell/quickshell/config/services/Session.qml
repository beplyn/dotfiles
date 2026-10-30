pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Session actions and the followed media player, shared by the panels.
Singleton {
    id: root

    // The player the dashboard follows: playing first.
    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        return players.find(p => p.isPlaying) ?? players[0] ?? null
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    function mixer() { Quickshell.execDetached([Theme.bin.mixer]) }
    function wallpaper() { Quickshell.execDetached([Theme.bin.wallpaper]) }
    function randomWallpaper() { Quickshell.execDetached([Theme.bin.wallpaper, "--random"]) }
    function lock() { run(Theme.bin.lock) }
    function logout() { Niri.action("quit", "--skip-confirmation") }
    function suspend() { Quickshell.execDetached([Theme.bin.systemctl, "suspend"]) }
    function reboot() { Quickshell.execDetached([Theme.bin.systemctl, "reboot"]) }
    function poweroff() { Quickshell.execDetached([Theme.bin.systemctl, "poweroff"]) }
}
