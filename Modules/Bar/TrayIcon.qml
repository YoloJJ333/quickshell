// One application's icon in the bar's tray area.
//
//   left click    — activate the application, or show its menu if activating is
//                   not something it offers
//   right click   — the application's own menu
//   middle click  — the application's secondary action
//   drag          — onto another icon to move it there, or onto the arrow to
//                   hide it
//
// Which gesture an application expects differs from one to the next, so both
// buttons fall back to the menu rather than doing nothing at all.
//
// Dragging works the way the Qt examples do it: the icon keeps a fixed cell in
// the row, and what actually moves is `visual`, which reparents itself to
// `dragRoot` (the whole bar) for the duration so the row does not reflow and
// the icon is not clipped on its way to the arrow.

import QtQuick
import Quickshell.Widgets
import qs.Config
import qs.Services
import qs.Widgets

Item {
    id: root

    required property var modelData  // a SystemTrayItem
    required property int index      // where it sits in the row, from the left
    required property var screen

    // The item the dragged icon is reparented to while it is in flight.
    required property Item dragRoot

    implicitWidth: Theme.barButtonSize * Theme.scale
    implicitHeight: Theme.barButtonSize * Theme.scale

    // Another icon dropped here takes this one's place in the row.
    DropArea {
        id: dropTarget

        anchors.fill: parent

        onDropped: event => {
            if (event.source && event.source !== root)
                TrayService.move(event.source.modelData, root.index);
        }
    }

    Item {
        id: visual

        width: root.width
        height: root.height

        Drag.active: mouse.drag.active
        Drag.source: root
        Drag.hotSpot.x: visual.width / 2
        Drag.hotSpot.y: visual.height / 2

        states: State {
            name: "dragging"
            when: mouse.drag.active

            ParentChange {
                target: visual
                parent: root.dragRoot
            }
            PropertyChanges {
                visual.opacity: 0.75
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm * Theme.scale
            color: dropTarget.containsDrag ? Colors.bar.dropTarget
                 : mouse.pressed ? Colors.bar.buttonPressed
                 : mouse.containsMouse ? Colors.bar.buttonHover
                 : Colors.bar.button

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        IconImage {
            anchors.centerIn: parent
            visible: root.modelData.icon !== ""
            source: root.modelData.icon
            implicitSize: Theme.trayIconSize * Theme.scale
        }

        // Not every application supplies an icon; this stands in for the ones
        // that do not so the row does not develop a gap.
        IconSvg {
            anchors.centerIn: parent
            visible: root.modelData.icon === ""
            path: Icons.dots
            size: Theme.trayIconSize * Theme.scale
            color: mouse.containsMouse ? Colors.bar.buttonHoverText : Colors.bar.buttonText
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            drag.target: visual
            drag.threshold: Theme.spaceSm

            onClicked: event => {
                const item = root.modelData;

                if (event.button === Qt.RightButton)
                    item.hasMenu ? appMenu.open() : item.secondaryActivate();
                else if (event.button === Qt.MiddleButton)
                    item.secondaryActivate();
                else if (item.onlyMenu)
                    appMenu.open();
                else
                    item.activate();
            }

            // Hand the drop to whatever is under the cursor. Leaving the
            // "dragging" state is what puts the icon back in the row, and that
            // happens by itself once `drag.active` goes false.
            onReleased: visual.Drag.drop()
        }
    }

    BarTooltip {
        anchorItem: root
        text: TrayService.displayName(root.modelData)
        show: mouse.containsMouse && !mouse.drag.active
    }

    TrayMenu {
        id: appMenu

        item: root.modelData
        anchorItem: root
    }
}
