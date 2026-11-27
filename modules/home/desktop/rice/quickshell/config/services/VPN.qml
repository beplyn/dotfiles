pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The wg0 NetworkManager profile (modules/nixos/services/wireguard.nix, networkManager),
// toggled from the control centre. Hidden when the host has no such profile.
Singleton {
    id: root

    readonly property string profile: "wg0"
    property bool available: false
    property bool active: false

    Component.onCompleted: query.running = true

    function toggle() {
        if (!available) return
        Quickshell.execDetached([Theme.bin.nmcli, "connection", active ? "down" : "up", profile])
        active = !active
        recheck.restart()
    }

    // `nmcli -t -f NAME,TYPE,STATE connection show` lines look like `wg0:wireguard:activated`
    Process {
        id: query
        command: [Theme.bin.nmcli, "-t", "-f", "NAME,TYPE,STATE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const row = text.split("\n")
                    .map(l => l.split(":"))
                    .find(f => f[0] === root.profile && f[1] === "wireguard")
                root.available = row !== undefined
                root.active = row !== undefined && row[2] === "activated"
            }
        }
    }

    // NetworkManager takes a moment to settle after up/down
    Timer {
        id: recheck
        interval: 2000
        onTriggered: query.running = true
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: query.running = true
    }

    IpcHandler {
        target: "vpn"
        function toggle(): void { root.toggle() }
        function status(): string { return root.active ? "on" : "off" }
    }
}
