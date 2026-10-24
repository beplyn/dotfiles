pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Launchers and session actions shared by the bar and control center.
Singleton {
    id: root

    property bool idleInhibited: false

    // The player the bar and control center follow: playing first.
    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        return players.find(p => p.isPlaying) ?? players[0] ?? null
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    function launcher() { Quickshell.execDetached([Theme.bin.launcher]) }
    function mixer() { Quickshell.execDetached([Theme.bin.mixer]) }
    function wallpaper() { Quickshell.execDetached([Theme.bin.wallpaper]) }
    function randomWallpaper() { Quickshell.execDetached([Theme.bin.wallpaper, "--random"]) }
    function lock() { run(Theme.bin.lock) }
    function logout() { Niri.action("quit", "--skip-confirmation") }
    function reboot() { Quickshell.execDetached([Theme.bin.systemctl, "reboot"]) }
    function poweroff() { Quickshell.execDetached([Theme.bin.systemctl, "poweroff"]) }
}
