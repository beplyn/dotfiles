import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs.services
import qs.widgets

// Quick settings, dropped from waybar's cog and status pills: session
// header, toggle tiles, sliders and launch shortcuts.
Panel {
    id: root

    name: "control"
    align: Qt.AlignRight
    cardWidth: 400

    property bool sessionOpen: false

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    // Connected first, then strongest; hidden SSIDs dropped.
    readonly property var wifiNetworks: !wifi ? [] : wifi.networks.values
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
        .slice(0, 8)
    // Network list stays folded so it doesn't push the sliders off screen.
    property bool networksOpen: false
    // The secured network waiting for a password, if any.
    property var pskTarget: null
    property string wifiError: ""
    onPskTargetChanged: wifiError = ""

    // Scan only while the list is on screen.
    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: root.open && root.networksOpen && Networking.wifiEnabled
        when: root.wifi !== null
    }
    onOpenChanged: {
        sessionOpen = false
        networksOpen = false
        pskTarget = null
    }
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: Bluetooth.devices.values.filter(d => d.connected)

    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]

    component Heading: Text {
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    // --- header: who, how long, lock / power ------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            implicitWidth: 42
            implicitHeight: 42
            radius: 21
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: Icons.logo
                color: Theme.background
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 6
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: Quickshell.env("USER") ?? ""
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 2
                font.bold: true
            }
            Text {
                text: Icons.uptime + "  up " + Stats.uptime
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 1
            }
        }

        IconButton {
            icon: Icons.lock
            onClicked: {
                Panels.close()
                Session.lock()
            }
        }
        IconButton {
            icon: Icons.power
            tint: Theme.red
            filled: root.sessionOpen
            onClicked: root.sessionOpen = !root.sessionOpen
        }
    }

    // Revealed by the power button, so a stray click can't shut down.
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.sessionOpen ? session.implicitHeight : 0
        Layout.topMargin: root.sessionOpen ? 0 : -12
        clip: true
        opacity: root.sessionOpen ? 1 : 0

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.fast }
        }

        RowLayout {
            id: session
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { icon: Icons.exit, label: "Log out", act: () => Session.logout() },
                    { icon: Icons.reboot, label: "Reboot", act: () => Session.reboot() },
                    { icon: Icons.power, label: "Shut down", act: () => Session.poweroff() }
                ]
                IconButton {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: modelData.icon
                    label: modelData.label
                    tint: Theme.red
                    onClicked: {
                        Panels.close()
                        modelData.act()
                    }
                }
            }
        }
    }

    // --- toggles -------------------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Tile {
            Layout.fillWidth: true
            visible: root.wifi !== null
            icon: Networking.wifiEnabled ? Icons.wifi : Icons.wifiOff
            title: "Wi-Fi"
            subtitle: !Networking.wifiEnabled ? "Off" : root.wifiNetwork?.name ?? "Not connected"
            active: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        Tile {
            Layout.fillWidth: true
            visible: root.wired !== null
            readonly property bool connected: root.wired?.connected ?? false
            icon: Icons.ethernet
            title: "Ethernet"
            subtitle: !(root.wired?.hasLink ?? false) ? "Cable unplugged"
                : !connected ? "Disconnected"
                : root.wired.linkSpeed > 0 ? root.wired.linkSpeed + " Mb/s"
                : "Connected"
            active: connected
            onClicked: {
                if (connected) root.wired.disconnect()
                else root.wired.network?.connect()
            }
        }
        Tile {
            Layout.fillWidth: true
            visible: root.adapter !== null
            readonly property bool powered: root.adapter?.enabled ?? false
            icon: powered ? Icons.bluetooth : Icons.bluetoothOff
            title: "Bluetooth"
            subtitle: !powered ? "Off"
                : root.btDevices.length === 0 ? "On"
                : root.btDevices[0].name + (root.btDevices.length > 1 ? " +" + (root.btDevices.length - 1) : "")
            active: powered
            onClicked: root.adapter.enabled = !powered
        }
        Tile {
            Layout.fillWidth: true
            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
            title: "Do not disturb"
            subtitle: Notifs.dnd ? "On" : "Off"
            active: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        Tile {
            Layout.fillWidth: true
            icon: Audio.micMuted ? Icons.micOff : Icons.mic
            title: "Microphone"
            subtitle: Audio.micMuted ? "Muted" : "Live"
            active: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }
        Tile {
            Layout.fillWidth: true
            icon: Icons.record
            title: "Screen record"
            subtitle: Recorder.recording ? Recorder.elapsed : "Off"
            active: Recorder.recording
            onClicked: {
                Panels.close()
                Recorder.toggle()
            }
        }
        Tile {
            Layout.fillWidth: true
            visible: Theme.laptop
            readonly property var profile: PowerProfiles.profile
            icon: profile === PowerProfile.Performance ? Icons.performance
                : profile === PowerProfile.PowerSaver ? Icons.powerSaver
                : Icons.balanced
            title: "Power"
            subtitle: PowerProfile.toString(profile)
            active: profile !== PowerProfile.Balanced
            onClicked: PowerProfiles.profile = root.profiles[(root.profiles.indexOf(profile) + 1) % root.profiles.length]
        }
    }

    // --- wi-fi networks ------------------------------------------------------
    Surface {
        Layout.fillWidth: true
        visible: root.wifi !== null && Networking.wifiEnabled
        spacing: 2

        // Click to fold the list open.
        Item {
            Layout.fillWidth: true
            implicitHeight: networksHeader.implicitHeight

            RowLayout {
                id: networksHeader
                anchors.fill: parent

                Heading {
                    Layout.fillWidth: true
                    text: "Wi-Fi networks"
                }
                Text {
                    text: root.networksOpen ? Icons.chevronUp : Icons.chevronDown
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.networksOpen = !root.networksOpen
                    root.pskTarget = null
                }
            }
        }

        Text {
            visible: root.networksOpen && root.wifiNetworks.length === 0
            Layout.topMargin: 4
            text: "Scanning…"
            color: Theme.subtext
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 1
        }

        Repeater {
            model: root.networksOpen ? root.wifiNetworks : []

            ColumnLayout {
                id: entry
                required property var modelData
                readonly property bool secured: modelData.security !== WifiSecurityType.Open
                    && modelData.security !== WifiSecurityType.Owe
                readonly property bool asking: root.pskTarget === modelData

                Layout.fillWidth: true
                spacing: 4

                Connections {
                    target: entry.modelData
                    function onConnectionFailed(reason) {
                        root.wifiError = entry.modelData.name + ": " + ConnectionFailReason.toString(reason)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.innerRadius - 2
                    color: row.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.fast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Text {
                            text: Icons.level(Icons.wifiLevels, entry.modelData.signalStrength * 100)
                            color: entry.modelData.connected ? Theme.accent : Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize + 2
                        }
                        Text {
                            Layout.fillWidth: true
                            text: entry.modelData.name
                            elide: Text.ElideRight
                            color: entry.modelData.connected ? Theme.accent : Theme.foreground
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize
                            font.bold: entry.modelData.connected
                        }
                        Text {
                            text: entry.modelData.stateChanging ? "…"
                                : entry.modelData.connected ? Icons.check
                                : entry.modelData.known ? "Saved"
                                : entry.secured ? Icons.lock : ""
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize - 1
                        }
                    }

                    MouseArea {
                        id: row
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const n = entry.modelData
                            root.wifiError = ""
                            if (n.connected) n.disconnect()
                            else if (n.known || !entry.secured) n.connect()
                            else root.pskTarget = entry.asking ? null : n
                        }
                    }
                }

                // Password prompt for a new secured network.
                Rectangle {
                    Layout.fillWidth: true
                    visible: entry.asking
                    implicitHeight: 34
                    radius: Theme.innerRadius - 2
                    color: Theme.alpha(Theme.background, 0.6)
                    border.color: psk.activeFocus ? Theme.accent : Theme.surface
                    border.width: 1

                    TextInput {
                        id: psk
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize
                        clip: true
                        focus: entry.asking
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                        onAccepted: {
                            if (text === "") return
                            entry.modelData.connectWithPsk(text)
                            root.pskTarget = null
                        }
                        Keys.onEscapePressed: root.pskTarget = null

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: psk.text === ""
                            text: "Password, then Enter"
                            color: Theme.muted
                            font: psk.font
                        }
                    }
                }
            }
        }

        Text {
            visible: root.wifiError !== ""
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: root.wifiError
            wrapMode: Text.Wrap
            color: Theme.red
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 1
        }
    }

    // --- sliders -------------------------------------------------------------
    Surface {
        Layout.fillWidth: true
        spacing: 6

        Heading { text: "Sound" }

        Slider {
            Layout.fillWidth: true
            icon: Audio.muted ? Icons.muted : Icons.level(Icons.volume, Audio.percent)
            value: Audio.volume
            dimmed: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        Slider {
            Layout.fillWidth: true
            visible: Audio.source !== null
            icon: Audio.micMuted ? Icons.micOff : Icons.mic
            value: Audio.micVolume
            dimmed: Audio.micMuted
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
        }

        Heading {
            visible: Brightness.available
            Layout.topMargin: 4
            text: "Display"
        }

        Slider {
            Layout.fillWidth: true
            visible: Brightness.available
            icon: Icons.level(Icons.backlight, Brightness.percent)
            value: Brightness.percent / 100
            onMoved: v => Brightness.set(v * 100)
        }
    }

    // --- shortcuts -----------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        IconButton {
            Layout.fillWidth: true
            icon: Icons.wallpaper
            label: "Wallpaper"
            onClicked: {
                Panels.close()
                Session.wallpaper()
            }
        }
        IconButton {
            icon: Icons.shuffle
            onClicked: Session.randomWallpaper()
        }
        IconButton {
            Layout.fillWidth: true
            icon: Icons.mixer
            label: "Mixer"
            onClicked: {
                Panels.close()
                Session.mixer()
            }
        }
    }
}
