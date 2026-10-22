// A small square icon button that lives at the right-hand end of a PopupRow —
// pin an icon to the bar, open an application's own menu, forget a device.

import QtQuick
import qs.Config
import qs.Widgets

Rectangle {
    id: root

    property string icon: ""
    property bool active: false   // the thing this button controls is on
    property bool danger: false   // destructive, e.g. forgetting a device

    signal clicked()

    implicitWidth: Theme.chipSize * Theme.scale
    implicitHeight: Theme.chipSize * Theme.scale
    radius: Theme.radiusSm * Theme.scale

    color: mouse.containsMouse ? (root.danger ? Colors.popup.chipDanger : Colors.popup.chipHover)
         : root.active ? Colors.popup.chipActive
         : Colors.popup.chip

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    IconSvg {
        anchors.centerIn: parent
        path: root.icon
        size: Theme.iconSize * Theme.scale * 0.8
        strokeWidth: 2.2
        color: mouse.containsMouse ? (root.danger ? Colors.popup.chipDangerText : Colors.popup.chipHoverText)
             : root.active ? Colors.popup.chipActiveText
             : Colors.popup.chipText
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
