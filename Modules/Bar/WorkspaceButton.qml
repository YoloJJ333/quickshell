// One workspace dot.
//
// Either a numbered workspace (`workspaceId`) or a special one (`special`), and
// the difference is only in what it looks up and what clicking it dispatches.
//
// A dot exists whether or not Hyprland has created that workspace yet, so
// `workspace` being null is the normal state of an empty one.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property int workspaceId: 0   // 1..n, or 0 for a special one
    property string special: ""   // name of a special workspace, without "special:"

    readonly property bool isSpecial: root.special !== ""

    readonly property var workspace: root.isSpecial
                                   ? WorkspaceService.findSpecial(root.special)
                                   : WorkspaceService.find(root.workspaceId)

    readonly property bool focused: root.workspace !== null && root.workspace.focused
    readonly property bool occupied: WorkspaceService.isOccupied(root.workspace)
    readonly property bool urgent: root.workspace !== null && root.workspace.urgent

    // Numbers speak for themselves; a special workspace gets its initial, with
    // the full name on hover.
    readonly property string label: root.isSpecial
                                  ? root.special.charAt(0).toUpperCase()
                                  : String(root.workspaceId)

    implicitWidth: Theme.workspaceSize * Theme.scale
    implicitHeight: Theme.workspaceSize * Theme.scale
    radius: height / 2

    color: mouse.containsMouse ? Colors.workspace.hover
         : root.urgent ? Colors.workspace.urgent
         : root.focused ? Colors.workspace.focused
         : root.occupied ? Colors.workspace.occupied
         : Colors.workspace.empty

    border.width: Theme.borderWidth
    border.color: mouse.containsMouse ? Colors.workspace.hover
                : root.focused ? Colors.workspace.focusedBorder
                : root.occupied ? Colors.workspace.occupiedBorder
                : Colors.workspace.emptyBorder

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.animFast }
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs * Theme.scale
        font.weight: root.focused ? Font.DemiBold : Font.Normal

        color: mouse.containsMouse ? Colors.workspace.hoverText
             : root.urgent ? Colors.workspace.urgentText
             : root.focused ? Colors.workspace.focusedText
             : root.occupied ? Colors.workspace.occupiedText
             : Colors.workspace.emptyText

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (root.isSpecial)
                WorkspaceService.toggleSpecial(root.special);
            else
                WorkspaceService.focus(root.workspaceId);
        }
    }

    BarTooltip {
        anchorItem: root
        text: root.isSpecial ? root.special : ""
        show: mouse.containsMouse
    }
}
