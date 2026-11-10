import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.widgets

// What to share, for xdph: every output and window as a live preview.
// Click one to share it; Escape or a click outside shares nothing.
Panel {
    id: root

    name: "share"
    align: Qt.AlignHCenter
    cardWidth: 760
    spacing: 14

    component Heading: Text {
        color: Theme.subtext
        font.family: Theme.font
        font.pointSize: Theme.popupFontSize - 1
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    // A preview card: live capture on top, glyph or app icon and a caption below.
    component Choice: Rectangle {
        id: choice

        property var source: null
        property string glyph: ""
        property string iconSource: ""
        property string caption: ""
        property string detail: ""
        signal picked()

        readonly property bool hovered: mouse.containsMouse

        implicitHeight: preview.height + captionRow.implicitHeight + 24
        radius: Theme.innerRadius
        color: hovered ? Theme.alpha(Theme.accent, 0.14) : Theme.well
        border.color: hovered ? Theme.accent : "transparent"
        border.width: 2
        scale: mouse.pressed ? 0.97 : hovered ? 1.02 : 1

        Behavior on color {
            ColorAnimation { duration: Theme.fast }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.fast }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: preview
            x: 8
            y: 8
            width: parent.width - 16
            height: Math.round(width * 9 / 16)
            radius: Theme.innerRadius - 4
            color: Theme.alpha(Theme.background, 0.7)
            clip: true

            // only while the picker is up, so nothing is captured otherwise
            ScreencopyView {
                anchors.fill: parent
                anchors.margins: 2
                captureSource: root.open ? choice.source : null
                live: root.open
                paintCursor: false
                constraintSize: Qt.size(width, height)
            }

            Text {
                anchors.centerIn: parent
                visible: choice.source === null
                text: choice.glyph
                color: Theme.muted
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 18
            }
        }

        RowLayout {
            id: captionRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            spacing: 8

            IconImage {
                visible: choice.iconSource !== ""
                implicitSize: 18
                source: choice.iconSource
            }
            Text {
                visible: choice.iconSource === ""
                text: choice.glyph
                color: choice.hovered ? Theme.accent : Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: choice.caption
                    elide: Text.ElideRight
                    color: choice.hovered ? Theme.accent : Theme.foreground
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    visible: choice.detail !== ""
                    text: choice.detail
                    elide: Text.ElideRight
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 2
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.picked()
        }
    }

    function appIcon(appId) {
        const entry = DesktopEntries.heuristicLookup(appId)
        const icon = entry?.icon ?? ""
        if (icon === "") return ""
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, true)
    }

    // --- header ----------------------------------------------------------------
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
                text: Icons.screenShare
                color: Theme.background
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 6
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Share your screen"
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 2
                font.bold: true
            }
            Text {
                text: "An app wants to see a screen or a window"
                color: Theme.subtext
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize - 1
            }
        }

        IconButton {
            icon: Icons.close
            tint: Theme.red
            onClicked: SharePicker.answer("")
        }
    }

    // --- outputs ---------------------------------------------------------------
    Heading { text: "Screens" }

    GridLayout {
        Layout.fillWidth: true
        columns: Math.min(3, Math.max(2, Quickshell.screens.length))
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
            model: Quickshell.screens

            Choice {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                source: modelData
                glyph: Icons.monitor
                caption: modelData.name
                detail: modelData.width + " × " + modelData.height
                onPicked: SharePicker.shareScreen(modelData.name)
            }
        }
    }

    // --- windows ---------------------------------------------------------------
    Heading {
        visible: SharePicker.windows.length > 0
        text: "Windows"
    }

    // Scrolls once there are more than two rows.
    Flickable {
        Layout.fillWidth: true
        visible: SharePicker.windows.length > 0
        Layout.preferredHeight: Math.min(windowGrid.implicitHeight, 2 * 210 + 10)
        contentHeight: windowGrid.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: windowGrid
            width: parent.width
            columns: 3
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: SharePicker.windows

                Choice {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    source: modelData.toplevel
                    glyph: Icons.window
                    iconSource: root.appIcon(modelData.appId)
                    caption: modelData.title || modelData.appId
                    detail: modelData.title !== "" ? modelData.appId : ""
                    onPicked: SharePicker.shareWindow(modelData.handle)
                }
            }
        }
    }

    // --- remember --------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.innerRadius
        color: rememberMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.well

        Behavior on color {
            ColorAnimation { duration: Theme.fast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 6
                color: SharePicker.remember ? Theme.accent : "transparent"
                border.color: SharePicker.remember ? Theme.accent : Theme.muted
                border.width: 2

                Behavior on color {
                    ColorAnimation { duration: Theme.fast }
                }

                Text {
                    anchors.centerIn: parent
                    visible: SharePicker.remember
                    text: Icons.check
                    color: Theme.background
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize - 2
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Remember this choice for the app"
                color: Theme.foreground
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize
            }
        }

        MouseArea {
            id: rememberMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SharePicker.remember = !SharePicker.remember
        }
    }
}
