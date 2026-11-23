import QtQuick
import QtQuick.Layouts
import qs.services

// Section inside a panel: no box, just a column. Sections are split by Divider.
Item {
    id: root

    property int padding: 0
    property alias spacing: column.spacing
    default property alias content: column.data

    implicitWidth: column.implicitWidth + padding * 2
    implicitHeight: column.implicitHeight + padding * 2

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Theme.gapSm
    }
}
