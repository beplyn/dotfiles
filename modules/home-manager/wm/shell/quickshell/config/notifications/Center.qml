import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs.services
import qs.widgets

// Control center, after hakuspace's swaync config: title, mpris,
// buttons grid, power menus, volume, backlight, dnd, notifications.
PanelWindow {
    id: root

    screen: Quickshell.screens[0] ?? null
    visible: Notifs.centerOpen
    anchors {
        top: true
        right: true
        bottom: true
    }
    margins {
        top: 6
        bottom: 6
    }
    implicitWidth: 450
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "haku-control-center"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property string menu: ""

    onVisibleChanged: menu = ""

    component Button: Rectangle {
        id: btn
        property string text: ""
        property bool active: false
        property bool bold: true
        signal clicked(var mouse)

        implicitHeight: 44
        implicitWidth: label.implicitWidth + 24
        radius: 10
        color: active ? Theme.accent : (mouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.6))
        Behavior on color { ColorAnimation { duration: 200 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: btn.text
            color: btn.active ? Theme.base : Theme.accent
            font.family: Theme.font
            font.pointSize: Theme.popupFontSize + 3
            font.bold: btn.bold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: m => btn.clicked(m)
        }
    }

    component Label: Text {
        color: Theme.accent
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize + 1
        font.bold: true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.base, 0.8)
        topLeftRadius: 30
        bottomLeftRadius: 30
        border.color: Theme.alpha(Theme.overlay, 0.4)

        focus: true
        Keys.onEscapePressed: Notifs.centerOpen = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 14
            anchors.rightMargin: 20
            spacing: 12

            // --- title -----------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                Label {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.pointSize: Theme.popupFontSize + 5
                }

                Button {
                    text: "Clear All"
                    implicitHeight: 32
                    onClicked: Notifs.clearAll()
                }
            }

            // --- mpris (autohide) ------------------------------------------
            Rectangle {
                readonly property var player: Session.player
                Layout.fillWidth: true
                visible: player !== null
                implicitHeight: 84
                radius: 12
                color: Theme.alpha(Theme.surface, 0.5)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    ClippingRectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 8
                        color: Theme.surface
                        Image {
                            anchors.fill: parent
                            source: Session.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: Session.player?.trackTitle ?? ""
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Session.player?.trackArtist ?? ""
                            elide: Text.ElideRight
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize
                        }
                    }

                    Repeater {
                        model: [
                            { icon: "󰒮", act: () => Session.player?.previous() },
                            { icon: Session.player?.isPlaying ? "󰏤" : "󰐊", act: () => Session.player?.togglePlaying() },
                            { icon: "󰒭", act: () => Session.player?.next() }
                        ]
                        Button {
                            required property var modelData
                            implicitWidth: 36
                            implicitHeight: 36
                            text: modelData.icon
                            onClicked: modelData.act()
                        }
                    }
                }
            }

            // --- buttons grid ----------------------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 8
                columnSpacing: 8

                Button {
                    Layout.fillWidth: true
                    text: Icons.wifi
                    active: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                Button {
                    Layout.fillWidth: true
                    text: Icons.bluetooth
                    active: Bluetooth.defaultAdapter?.enabled ?? false
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
                Button {
                    Layout.fillWidth: true
                    text: Icons.muted
                    active: Audio.muted
                    onClicked: Audio.toggleMute()
                }
                Button {
                    Layout.fillWidth: true
                    text: Audio.micMuted ? Icons.micOff : Icons.mic
                    active: Audio.micMuted
                    onClicked: Audio.toggleMicMute()
                }
                Button {
                    Layout.fillWidth: true
                    text: Icons.idle
                    active: Session.idleInhibited
                    onClicked: Session.idleInhibited = !Session.idleInhibited
                }
                Button {
                    Layout.fillWidth: true
                    text: Icons.record
                    active: Recorder.recording
                    onClicked: {
                        Notifs.centerOpen = false
                        Recorder.toggle()
                    }
                }
                // Left click opens waypaper, right click picks a random one.
                Button {
                    Layout.fillWidth: true
                    text: Icons.wallpaper
                    onClicked: m => {
                        Notifs.centerOpen = false
                        m.button === Qt.RightButton ? Session.randomWallpaper() : Session.wallpaper()
                    }
                }
                Button {
                    Layout.fillWidth: true
                    text: Icons.dnd
                    active: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
            }

            // --- menubar: power / power mode -------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 8
                    Button {
                        text: Icons.power
                        active: root.menu === "power"
                        onClicked: root.menu = root.menu === "power" ? "" : "power"
                    }
                    Button {
                        text: Icons.powerMode
                        active: root.menu === "profile"
                        onClicked: root.menu = root.menu === "profile" ? "" : "profile"
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    visible: root.menu === "power"
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6
                    Repeater {
                        model: [
                            { text: Icons.reboot + "   Reboot", act: () => Session.reboot() },
                            { text: Icons.lock + "   Lock", act: () => Session.lock() },
                            { text: Icons.exit + "   Exit", act: () => Session.logout() },
                            { text: Icons.power + "   Shut down", act: () => Session.poweroff() }
                        ]
                        Button {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 36
                            active: true
                            text: modelData.text
                            onClicked: {
                                Notifs.centerOpen = false
                                modelData.act()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.menu === "profile"
                    spacing: 6
                    Repeater {
                        model: [
                            { text: "Performance", profile: PowerProfile.Performance },
                            { text: "Balanced", profile: PowerProfile.Balanced },
                            { text: "Power-saver", profile: PowerProfile.PowerSaver }
                        ]
                        Button {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 36
                            text: modelData.text
                            active: PowerProfiles.profile === modelData.profile
                            onClicked: PowerProfiles.profile = modelData.profile
                        }
                    }
                }
            }

            // --- sliders ---------------------------------------------------
            Slider {
                Layout.fillWidth: true
                label: Audio.muted ? Icons.muted : Icons.speaker
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
                onLabelClicked: Audio.toggleMute()
            }

            Slider {
                Layout.fillWidth: true
                visible: Brightness.available
                label: Icons.brightness
                value: Brightness.percent / 100
                onMoved: v => Brightness.set(v * 100)
            }

            // --- dnd -------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: "Do Not Disturb"
                }
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: 12
                    color: Notifs.dnd ? Theme.accent : Theme.surface
                    Rectangle {
                        x: Notifs.dnd ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: Notifs.dnd ? Theme.base : Theme.text
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
            }

            // --- notifications ---------------------------------------------
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: ScriptModel {
                    values: Notifs.list
                }
                delegate: Card {
                    required property var modelData
                    notif: modelData
                    width: ListView.view.width
                }

                Text {
                    anchors.centerIn: parent
                    visible: Notifs.count === 0
                    text: "No notifications"
                    color: Theme.overlay
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 1
                }
            }
        }
    }
}
