import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services

// tray: 18px icons, passive items included (show-passive-items).
Row {
    id: root

    required property var window

    spacing: 10
    leftPadding: 4
    rightPadding: 4

    Repeater {
        model: SystemTray.items

        IconImage {
            id: icon
            required property SystemTrayItem modelData

            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 18
            source: modelData.icon
            opacity: modelData.status === Status.Passive ? 0.6 : 1

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => {
                    const item = icon.modelData
                    if (m.button === Qt.MiddleButton) {
                        item.secondaryActivate()
                    } else if (m.button === Qt.RightButton || item.onlyMenu) {
                        if (!item.hasMenu) return
                        const p = icon.mapToItem(null, 0, icon.height + 8)
                        item.display(root.window, p.x, p.y)
                    } else {
                        item.activate()
                    }
                }
                onWheel: w => icon.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }
}
