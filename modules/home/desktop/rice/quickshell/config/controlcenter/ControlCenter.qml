import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Widgets
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

    // Quickshell only does PSK, so enterprise (username) networks go through nmcli.
    Process {
        id: eapJoin
        property string ssid: ""
        stderr: StdioCollector { id: eapErr }
        onExited: code => {
            if (code !== 0)
                root.wifiError = ssid + ": " + (eapErr.text.trim().split("\n").pop() || "authentication failed")
        }
    }
    function joinEap(network, identity, password) {
        wifiError = ""
        eapJoin.ssid = network.name
        eapJoin.environment = { EAP_IDENTITY: identity, EAP_PASSWORD: password }
        eapJoin.command = [Theme.bin.eapConnect, network.name]
        eapJoin.running = true
    }

    onOpenChanged: {
        sessionOpen = false
        networksOpen = false
        pskTarget = null
        btOpen = false
    }
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: Bluetooth.devices.values.filter(d => d.connected)
    // Connected, then paired, then by name; unnamed beacons dropped.
    readonly property var btList: !adapter ? [] : adapter.devices.values
        .filter(d => d.deviceName !== "" || d.paired)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
        .slice(0, 8)
    property bool btOpen: false
    property string btError: ""

    // Pair() leaves the link up, so Quickshell's connect() refuses the device
    // as already connected; BlueZ's Connect still brings up the audio profiles.
    function btConnect(d) {
        if (d.connected) Quickshell.execDetached([Theme.bin.bluetoothctl, "connect", d.address])
        else d.connect()
    }

    // Discover only while the list is on screen.
    Binding {
        target: root.adapter
        property: "discovering"
        value: root.open && root.btOpen && (root.adapter?.enabled ?? false)
        when: root.adapter !== null
    }

    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]

    component Heading: Text {
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    // One line of the wi-fi credential prompt.
    component Field: Rectangle {
        property alias input: field
        property alias hint: hintText.text
        property alias echoMode: field.echoMode
        signal accepted()
        signal escaped()

        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.innerRadius - 2
        color: Theme.alpha(Theme.background, 0.6)
        border.color: field.activeFocus ? Theme.accent : Theme.surface
        border.width: 1

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.foreground
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize
            clip: true
            onVisibleChanged: if (visible) text = ""
            onAccepted: parent.accepted()
            Keys.onEscapePressed: parent.escaped()

            Text {
                id: hintText
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text === ""
                color: Theme.muted
                font: field.font
            }
        }
    }

    // --- header: who, how long, lock / power ------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // ~/.pfp as rendered by lock.nix's pfp; the logo until it loads
        ClippingRectangle {
            implicitWidth: 42
            implicitHeight: 42
            radius: 21
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                visible: pfp.status !== Image.Ready
                text: Icons.logo
                color: Theme.background
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 6
            }

            Image {
                id: pfp
                anchors.fill: parent
                source: "file://" + (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/pfp.png"
                sourceSize: Qt.size(84, 84)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
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
            icon: NightLight.active ? Icons.nightLight : Icons.daylight
            title: "Night light"
            subtitle: NightLight.active ? NightLight.temperature + " K" : "Off"
            active: NightLight.active
            onClicked: NightLight.toggle()
        }
        Tile {
            Layout.fillWidth: true
            icon: Awake.active ? Icons.awake : Icons.idle
            title: "Stay awake"
            subtitle: Awake.active ? "On" : "Off"
            active: Awake.active
            onClicked: Awake.toggle()
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
            // ScriptModel keeps rows (and a half-typed password) across scan updates.
            model: ScriptModel {
                values: root.networksOpen ? root.wifiNetworks : []
            }

            ColumnLayout {
                id: entry
                required property var modelData
                readonly property bool secured: modelData.security !== WifiSecurityType.Open
                    && modelData.security !== WifiSecurityType.Owe
                // 802.1X: wants a username as well as a password.
                readonly property bool enterprise: modelData.security === WifiSecurityType.Wpa2Eap
                    || modelData.security === WifiSecurityType.WpaEap
                readonly property bool joining: eapJoin.running && eapJoin.ssid === modelData.name
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
                            text: entry.modelData.stateChanging || entry.joining ? "…"
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
                            if (entry.joining) return
                            root.wifiError = ""
                            if (n.connected) n.disconnect()
                            else if (n.known || !entry.secured) n.connect()
                            else root.pskTarget = entry.asking ? null : n
                        }
                    }
                }

                // Credential prompt for a new secured network; enterprise ones get a username first.
                function submit() {
                    const pass = psk.input.text
                    if (pass === "") return
                    if (entry.enterprise) {
                        const user = identity.input.text
                        if (user === "") { identity.input.forceActiveFocus(); return }
                        root.joinEap(entry.modelData, user, pass)
                    } else {
                        entry.modelData.connectWithPsk(pass)
                    }
                    root.pskTarget = null
                }

                onAskingChanged: if (asking) Qt.callLater(() => (enterprise ? identity : psk).input.forceActiveFocus())

                Field {
                    id: identity
                    visible: entry.asking && entry.enterprise
                    hint: "Username, then Enter"
                    onAccepted: if (input.text !== "") psk.input.forceActiveFocus()
                    onEscaped: root.pskTarget = null
                }
                Field {
                    id: psk
                    visible: entry.asking
                    echoMode: TextInput.Password
                    hint: "Password, then Enter"
                    onAccepted: entry.submit()
                    onEscaped: root.pskTarget = null
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

    // --- bluetooth devices --------------------------------------------------
    Surface {
        Layout.fillWidth: true
        visible: root.adapter?.enabled ?? false
        spacing: 2

        Item {
            Layout.fillWidth: true
            implicitHeight: btHeader.implicitHeight

            RowLayout {
                id: btHeader
                anchors.fill: parent

                Heading {
                    Layout.fillWidth: true
                    text: "Bluetooth devices"
                }
                Text {
                    text: root.btOpen ? Icons.chevronUp : Icons.chevronDown
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.btOpen = !root.btOpen
                    root.btError = ""
                }
            }
        }

        Text {
            visible: root.btOpen && root.btList.length === 0
            Layout.topMargin: 4
            text: "Searching…"
            color: Theme.subtext
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize - 1
        }

        Repeater {
            model: ScriptModel {
                values: root.btOpen ? root.btList : []
            }

            Rectangle {
                id: btEntry
                required property var modelData
                readonly property bool busy: modelData.pairing
                    || modelData.state === BluetoothDeviceState.Connecting
                    || modelData.state === BluetoothDeviceState.Disconnecting
                // Set when we paired it, so it connects once pairing lands.
                property bool connectAfterPair: false

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.innerRadius - 2
                color: btRow.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.fast }
                }

                Connections {
                    target: btEntry.modelData
                    function onPairedChanged() {
                        if (!btEntry.connectAfterPair || !btEntry.modelData.paired) return
                        btEntry.connectAfterPair = false
                        btEntry.modelData.trusted = true
                        root.btConnect(btEntry.modelData)
                    }
                    function onPairingChanged() {
                        if (!btEntry.modelData.pairing && btEntry.connectAfterPair && !btEntry.modelData.paired) {
                            btEntry.connectAfterPair = false
                            root.btError = btEntry.modelData.name + ": pairing failed"
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        text: Icons.btDevice(btEntry.modelData.icon)
                        color: btEntry.modelData.connected ? Theme.accent : Theme.foreground
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize + 2
                    }
                    Text {
                        Layout.fillWidth: true
                        text: btEntry.modelData.name
                        elide: Text.ElideRight
                        color: btEntry.modelData.connected ? Theme.accent : Theme.foreground
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize
                        font.bold: btEntry.modelData.connected
                    }
                    Text {
                        text: btEntry.busy ? "…"
                            : btEntry.modelData.connected
                                ? (btEntry.modelData.batteryAvailable ? Math.round(btEntry.modelData.battery * 100) + "%  " : "") + Icons.check
                            : btEntry.modelData.paired ? "Paired"
                            : ""
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize - 1
                    }
                }

                // Left: connect / disconnect (pairing new devices first). Right: forget.
                MouseArea {
                    id: btRow
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        const d = btEntry.modelData
                        root.btError = ""
                        if (m.button === Qt.RightButton) {
                            if (d.paired) d.forget()
                            return
                        }
                        if (d.pairing) d.cancelPair()
                        else if (btEntry.busy) return
                        else if (d.connected && !d.paired) {
                            // linked without a bond: no audio, so pair it now
                            btEntry.connectAfterPair = true
                            d.pair()
                        }
                        else if (d.connected) d.disconnect()
                        else if (d.paired) d.connect()
                        else {
                            btEntry.connectAfterPair = true
                            d.pair()
                        }
                    }
                }
            }
        }

        Text {
            visible: root.btError !== ""
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: root.btError
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
