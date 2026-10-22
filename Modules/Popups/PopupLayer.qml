// The surface the panels are drawn on. One per monitor, alongside that
// monitor's bar.
//
// It is a full-screen, click-through-when-hidden overlay that only appears
// while PopupService has a panel open, which is what makes dismissing one
// reliable: a click anywhere outside a card lands here, and Escape does too.
//
// Every panel drops out of the same place — the top right corner, just under
// the bar — so `slot` positions them all and the cards only fade in and out.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Services

PanelWindow {
    id: root

    // Which monitor this layer belongs to. It is kept separate from the
    // window's own `screen` on purpose: reading `screen` back inside the
    // `visible` binding below makes the two chase each other.
    required property var monitor

    screen: root.monitor
    visible: PopupService.current !== "" && PopupService.screen === root.monitor
    color: "transparent"

    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: if (root.visible) body.forceActiveFocus()

    Item {
        id: body

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: PopupService.close()

        // Anywhere that is not a card puts the open panel away.
        MouseArea {
            anchors.fill: parent
            onClicked: PopupService.close()
        }

        Item {
            id: slot

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: Theme.spaceSm * Theme.scale
            anchors.topMargin: (Theme.barHeight + Theme.popupGap) * Theme.scale

            PopupCard {
                name: "tray"

                TrayPanel {}
            }

            PopupCard {
                name: "wifi"

                WifiPanel {}
            }

            PopupCard {
                name: "bluetooth"

                BluetoothPanel {}
            }

            PopupCard {
                name: "audio"

                AudioPanel {}
            }

            PopupCard {
                name: "controls"

                ControlCenter {}
            }
        }
    }
}
