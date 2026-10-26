import QtQuick
import QtQuick.Layouts
import qs.services

// Recessed section inside a panel card; children stack in a column.
Rectangle {
    id: root

    property int padding: 12
    property alias spacing: column.spacing
    default property alias content: column.data

    implicitWidth: column.implicitWidth + padding * 2
    implicitHeight: column.implicitHeight + padding * 2
    radius: Theme.innerRadius
    color: Theme.well

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 8
    }
}
