// The tray: the drawer arrow, then one icon per pinned application.
//
// Both the arrow and the icons run right to left, the way Windows lays its
// tray out — the arrow is the leftmost thing, the application that registered
// first sits at the right-hand end, and anything new appears to the left of it.
//
// Dragging an icon onto another one moves it there; dragging it onto the arrow
// hides it. Getting it back is the pin button in the drawer, since dragging out
// of the drawer would mean dragging between two Wayland surfaces, which Qt
// cannot do.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Row {
    id: root

    required property var screen

    // Passed down to the icons: what a dragged icon reparents to mid-flight.
    required property Item dragRoot

    visible: TrayService.items.length > 0
    spacing: Theme.spaceXs * Theme.scale

    BarButton {
        id: drawer

        icon: Icons.chevronDown
        active: PopupService.isOpen("tray") || dropTarget.containsDrag
        accent: dropTarget.containsDrag ? Colors.bar.dropTarget : Colors.bar.buttonHover
        accentText: dropTarget.containsDrag ? Colors.bar.dropTargetText : Colors.bar.buttonHoverText
        onClicked: PopupService.toggle("tray", root.screen)

        DropArea {
            id: dropTarget

            anchors.fill: parent

            // `source` is the TrayIcon the dragged visual belongs to.
            onDropped: event => {
                if (event.source)
                    TrayService.hide(event.source.modelData);
            }
        }
    }

    Repeater {
        // Already in the order they should be drawn — see TrayService.pinned.
        model: TrayService.pinned

        TrayIcon {
            screen: root.screen
            dragRoot: root.dragRoot
        }
    }
}
