// The Wi-Fi panel.
//
// Saved networks come first and can be joined with a click. Everything else the
// adapter can see is listed underneath for information only — joining one of
// those needs a password, which this panel has nowhere to type.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Theme.spaceSm * Theme.scale

    // NetworkManager only keeps the list of nearby access points fresh while
    // something is scanning, so scan exactly as long as this panel is up.
    Binding {
        target: WifiService
        property: "scanning"
        value: PopupService.isOpen("wifi")
    }

    PopupHeader {
        width: parent.width
        title: "Wi-Fi"
        subtitle: !WifiService.available ? "No adapter"
                : !WifiService.enabled ? "Off"
                : WifiService.connected ? WifiService.ssid
                : "Not connected"

        ToggleSwitch {
            checked: WifiService.enabled
            onToggled: checked => WifiService.setEnabled(checked)
        }
    }

    PopupList {
        width: parent.width

        PopupSection {
            width: parent.width
            visible: WifiService.saved.length > 0
            text: "Saved"
        }

        Repeater {
            model: WifiService.saved
            delegate: networkRow
        }

        PopupSection {
            width: parent.width
            visible: WifiService.nearby.length > 0
            text: "Nearby"
            hint: "not saved"
        }

        Repeater {
            model: WifiService.nearby
            delegate: networkRow
        }

        Text {
            width: parent.width
            visible: WifiService.enabled && WifiService.networks.length === 0
            text: "Looking for networks…"
            color: Colors.popup.sectionLabel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale
            topPadding: Theme.spaceSm * Theme.scale
        }
    }

    // One row per access point. Saved networks are clickable; the rest are
    // greyed out and simply say what is in range.
    Component {
        id: networkRow

        PopupRow {
            required property var modelData

            readonly property int percent: Math.round(modelData.signalStrength * 100)

            label: modelData.name
            iconPath: Icons.wifiBars[WifiService.strengthBars(modelData.signalStrength)]
            current: modelData.connected
            interactive: modelData.known

            sublabel: modelData.connected ? "Connected"
                    : modelData.stateChanging ? "Connecting…"
                    : `${percent}% · ${WifiService.securityLabel(modelData)}`

            onClicked: {
                if (modelData.connected)
                    WifiService.disconnectActive();
                else
                    WifiService.connectTo(modelData);
            }
        }
    }
}
