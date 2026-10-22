// The title strip at the top of a panel: a name, a line of status underneath,
// and room on the right for a switch or a button or two.
//
// Usage:
//   PopupHeader {
//       title: "Wi-Fi"
//       subtitle: "ORBI581"
//       ToggleSwitch { ... }
//   }

import QtQuick
import qs.Config

Item {
    id: root

    property string title: ""
    property string subtitle: ""

    // Anything put inside the header lands in the row on the right.
    default property alias trailing: trailingRow.data

    implicitHeight: Math.max(labels.implicitHeight, trailingRow.implicitHeight)
                  + Theme.spaceSm * Theme.scale

    Column {
        id: labels

        anchors.left: parent.left
        anchors.right: trailingRow.left
        anchors.rightMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * Theme.scale

        Text {
            width: parent.width
            text: root.title
            color: Colors.popup.heading
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBody * Theme.scale
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Colors.popup.sectionLabel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale
            elide: Text.ElideRight
        }
    }

    Row {
        id: trailingRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceXs * Theme.scale
    }
}
