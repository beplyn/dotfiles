import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services

// One notification in hakuspace's swaync style: dark card, accent text
// and a 3px accent underline (red for critical).
Rectangle {
    id: root

    required property Notification notif
    property bool popup: false
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property bool hovered: hover.hovered

    // The sender's image (e.g. a screenshot) wins over the app icon.
    readonly property string picture: {
        const img = notif?.image ?? ""
        if (img !== "") return img
        const icon = notif?.appIcon ?? ""
        if (icon.startsWith("/") || icon.startsWith("file://")) return icon
        return icon !== "" ? Quickshell.iconPath(icon, true) : ""
    }

    implicitHeight: body.implicitHeight + 32 + 3
    radius: Theme.radius
    color: critical ? Theme.red : Theme.accent

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 3
        radius: Theme.radius
        color: Theme.alpha(Theme.base, popup ? 0.9 : 0.8)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: m => m.button === Qt.MiddleButton ? root.notif.dismiss() : Notifs.activate(root.notif)
        }
    }

    Row {
        id: body
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12

        ClippingRectangle {
            visible: root.picture !== ""
            width: 48
            height: 48
            radius: 8
            color: "transparent"

            Image {
                anchors.fill: parent
                source: root.picture
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 96
                sourceSize.height: 96
                asynchronous: true
            }
        }

        Column {
            width: body.width - (root.picture !== "" ? 60 : 0)
            spacing: 4

            Item {
                width: parent.width
                height: summary.implicitHeight

                Text {
                    id: summary
                    anchors.left: parent.left
                    anchors.right: meta.left
                    anchors.rightMargin: 8
                    text: root.notif?.summary || root.notif?.appName || ""
                    elide: Text.ElideRight
                    color: root.critical ? Theme.red : Theme.accent
                    font.family: Theme.font
                    font.pointSize: Theme.popupFontSize + 2
                    font.bold: true
                }

                Row {
                    id: meta
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Notifs.age(root.notif?.id)
                        color: Theme.overlay
                        font.family: Theme.font
                        font.pointSize: Theme.popupFontSize
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: close.containsMouse ? Theme.red : Theme.subtext
                        font.pointSize: Theme.popupFontSize + 1

                        MouseArea {
                            id: close
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.notif.dismiss()
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.notif?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 4 : 6
                elide: Text.ElideRight
                color: Theme.text
                linkColor: Theme.blue
                font.family: Theme.font
                font.pointSize: Theme.popupFontSize + 1
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                width: parent.width
                spacing: 6
                visible: actions.count > 0
                topPadding: 4

                Repeater {
                    id: actions
                    model: (root.notif?.actions ?? []).filter(a => a.identifier !== "default")

                    Rectangle {
                        required property NotificationAction modelData
                        width: label.implicitWidth + 24
                        height: label.implicitHeight + 10
                        radius: 8
                        color: actionHover.containsMouse ? Theme.accent : Theme.alpha(Theme.surface, 0.8)

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: actionHover.containsMouse ? Theme.base : Theme.accent
                            font.family: Theme.font
                            font.pointSize: Theme.popupFontSize
                            font.bold: true
                        }

                        MouseArea {
                            id: actionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
