import QtQuick
import QtQuick.Layouts
import qs.services

// 1px hairline between panel sections
Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: Theme.gapXs
    Layout.bottomMargin: Theme.gapXs
    implicitHeight: Theme.borderWidth
    color: Theme.surface
}
