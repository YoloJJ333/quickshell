// The Bluetooth panel.
//
// Remembered devices are at the top and connect or disconnect with a click.
// Everything the current scan turns up is underneath, and clicking one of those
// pairs it — after which it moves up into the top group.
//
// While a device is pairing, its row is where the conversation happens: the
// second line says what is wanted (confirm a number, type a PIN, ...) and the
// chips on the right are how to answer. BluetoothService.pairingStage is what
// drives it.
//
// The switch on each remembered row is BlueZ's "trusted" flag, which is what
// decides whether a device reconnects by itself when it comes back in range.

import QtQuick
import Quickshell
import qs.Config
import qs.Services
import qs.Widgets

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Theme.spaceSm * Theme.scale

    readonly property bool opened: PopupService.isOpen("bluetooth")

    // Discover only while the panel is up, so the adapter is not scanning all
    // day in the background.
    Binding {
        target: BluetoothService
        property: "scanning"
        value: root.opened
    }

    // A failure message is for reading now, not for finding again next week.
    onOpenedChanged: {
        if (!root.opened)
            BluetoothService.clearPairing();
    }

    // The second line of a row that is pairing, per stage.
    function pairingText(device: var): string {
        const s = BluetoothService;
        if (s.pairingAddress !== device.address)
            return device.address;

        switch (s.pairingStage) {
        case "confirm": return `Does it show ${s.pairingPasskey}?`;
        case "display": return `Type ${s.pairingPasskey} on it`;
        case "enter":   return "Type its PIN here";
        case "failed":  return `Pairing failed · ${s.pairingError}`;
        default:        return "Pairing…";
        }
    }

    PopupHeader {
        width: parent.width
        title: "Bluetooth"
        subtitle: !BluetoothService.available ? "No adapter"
                : !BluetoothService.enabled ? "Off"
                : BluetoothService.connected
                  ? BluetoothService.connectedDevices.map(d => d.name).join(", ")
                  : "Not connected"

        ToggleSwitch {
            checked: BluetoothService.enabled
            onToggled: checked => BluetoothService.setEnabled(checked)
        }
    }

    PopupList {
        width: parent.width

        PopupSection {
            width: parent.width
            visible: BluetoothService.paired.length > 0
            text: "Paired"
            hint: "autoconnect"
        }

        Repeater {
            model: BluetoothService.paired

            PopupRow {
                required property var modelData

                label: modelData.name
                iconPath: Icons.bluetooth
                iconSource: Quickshell.iconPath(modelData.icon, true)
                current: modelData.connected

                sublabel: modelData.pairing ? "Pairing…"
                        : modelData.connected
                          ? (modelData.batteryAvailable
                             ? `Connected · ${Math.round(modelData.battery * 100)}%`
                             : "Connected")
                        : "Paired"

                onClicked: BluetoothService.activate(modelData)

                ToggleSwitch {
                    checked: modelData.trusted
                    onToggled: checked => BluetoothService.setAutoconnect(modelData, checked)
                }

                ChipButton {
                    icon: Icons.trash
                    danger: true
                    onClicked: BluetoothService.forget(modelData)
                }
            }
        }

        PopupSection {
            width: parent.width
            visible: BluetoothService.nearby.length > 0
            text: "Nearby"
            hint: "tap to pair"
        }

        Repeater {
            model: BluetoothService.nearby

            PopupRow {
                id: nearbyRow

                required property var modelData

                readonly property bool busy: BluetoothService.pairingActive
                                          && BluetoothService.pairingAddress === modelData.address

                label: modelData.name
                iconPath: Icons.bluetooth
                iconSource: Quickshell.iconPath(modelData.icon, true)
                sublabel: root.pairingText(modelData)

                // Clicking the row starts it; once started, the chips take over.
                onClicked: {
                    if (!nearbyRow.busy)
                        BluetoothService.activate(modelData);
                }

                ChipInput {
                    visible: nearbyRow.busy && BluetoothService.pairingAwaitsInput
                    placeholder: "PIN"
                    numeric: true
                    onAccepted: text => BluetoothService.submitPairingInput(text)
                }

                ChipButton {
                    visible: nearbyRow.busy && BluetoothService.pairingAwaitsAnswer
                    icon: Icons.check
                    active: true
                    onClicked: BluetoothService.answerPairing(true)
                }

                ChipButton {
                    visible: nearbyRow.busy
                    icon: Icons.close
                    danger: true
                    onClicked: BluetoothService.cancelPairing()
                }
            }
        }

        Text {
            width: parent.width
            visible: BluetoothService.enabled
                  && BluetoothService.paired.length === 0
                  && BluetoothService.nearby.length === 0
            text: "Looking for devices…"
            color: Colors.popup.sectionLabel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale
            topPadding: Theme.spaceSm * Theme.scale
        }
    }
}
