// The tray drawer: the applications whose icons are not on the bar.
//
// Only hidden applications are listed — the pinned ones are already visible on
// the bar, so repeating them here would just be a second copy of the same row.
// The pin button sends one back to the bar, at which point it leaves this list.
//
// Clicking a row does the same as clicking the icon would, and the other button
// opens the application's own menu when it has one.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Theme.spaceSm * Theme.scale

    PopupHeader {
        width: parent.width
        title: "Hidden"
        subtitle: TrayService.hidden.length === 1
                ? "1 application"
                : `${TrayService.hidden.length} applications`
    }

    PopupList {
        width: parent.width

        Repeater {
            model: TrayService.hidden

            PopupRow {
                id: row

                required property var modelData

                label: TrayService.displayName(modelData)
                sublabel: modelData.id
                iconSource: modelData.icon
                iconPath: Icons.dots

                // Applications that only offer a menu (Tailscale, for one) have
                // nothing to activate, so show the menu instead.
                onClicked: modelData.onlyMenu ? appMenu.open() : modelData.activate()

                ChipButton {
                    icon: Icons.menu
                    visible: row.modelData.hasMenu
                    onClicked: appMenu.open()
                }

                ChipButton {
                    icon: Icons.pin
                    onClicked: TrayService.pin(row.modelData)
                }

                TrayMenu {
                    id: appMenu

                    item: row.modelData
                    anchorItem: row
                }
            }
        }

        Text {
            width: parent.width
            visible: TrayService.hidden.length === 0
            text: TrayService.items.length === 0
                ? "Nothing in the tray."
                : "Nothing hidden. Drag an icon onto the arrow to put it here."
            color: Colors.popup.sectionLabel
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale
            topPadding: Theme.spaceSm * Theme.scale
        }
    }
}
