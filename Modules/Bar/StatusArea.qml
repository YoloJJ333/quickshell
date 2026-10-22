// The cluster at the right-hand end of the bar: tray icons, then the status
// readouts, then the control centre.
//
// The buttons that have a panel behind them all work the same way — they light
// up while their panel is open, and clicking again puts it away. The panels
// themselves live in Modules/Popups.
//
// Three gaps, three knobs, and each one is exactly the number it says:
//
//   readouts ─ barSpacing ─ readouts ═ barGroupSpacing ═ connect ─ connect
//
// That only works because the gap between the two halves is the outer Row's own
// `spacing` rather than a spacer item wedged between them: a spacer is a child
// like any other, so the Row would put `spacing` either side of it and the gap
// would come out at barGroupSpacing + 2 × barSpacing.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Row {
    id: root

    required property var screen
    required property Item dragRoot

    // Between the two groups below, and nowhere else.
    spacing: Theme.barGroupSpacing * Theme.scale

    // What the machine is doing: nothing here is a button onto a panel.
    Row {
        spacing: Theme.barSpacing * Theme.scale

        TrayArea {
            screen: root.screen
            dragRoot: root.dragRoot
        }

        // Text only — the layout's own name is the whole indicator. Clicking it
        // moves to the next configured layout, the same as the keybind does.
        BarButton {
            visible: KeyboardService.available
            label: KeyboardService.layout
            tooltip: KeyboardService.description
            onClicked: KeyboardService.next()
        }

        BatteryIndicator {}
    }

    // What you click to connect something. Wi-Fi, Bluetooth and volume are
    // nested one level deeper so they can be packed tighter than the control
    // centre button that follows them.
    Row {
        spacing: Theme.barSpacing * Theme.scale

        Row {
            spacing: Theme.connectivitySpacing * Theme.scale

            BarButton {
                icon: WifiService.enabled ? Icons.wifiBars[WifiService.bars] : Icons.wifiOff
                muted: !WifiService.enabled || !WifiService.connected
                active: PopupService.isOpen("wifi")
                tooltip: !WifiService.enabled ? "Wi-Fi off"
                       : WifiService.connected ? WifiService.ssid
                       : "Not connected"
                onClicked: PopupService.toggle("wifi", root.screen)
            }

            BarButton {
                icon: !BluetoothService.enabled ? Icons.bluetoothOff
                    : BluetoothService.connected ? Icons.bluetoothOn
                    : Icons.bluetooth
                muted: !BluetoothService.enabled
                active: PopupService.isOpen("bluetooth")
                tooltip: !BluetoothService.enabled ? "Bluetooth off"
                       : BluetoothService.connected
                         ? BluetoothService.connectedDevices.map(d => d.name).join(", ")
                         : "Not connected"
                onClicked: PopupService.toggle("bluetooth", root.screen)
            }

            BarButton {
                visible: AudioService.available
                icon: AudioService.muted ? Icons.volumeMute
                    : AudioService.percent < 50 ? Icons.volumeLow
                    : Icons.volume
                label: `${AudioService.percent}%`
                muted: AudioService.muted
                active: PopupService.isOpen("audio")
                tooltip: AudioService.deviceName
                onClicked: PopupService.toggle("audio", root.screen)
            }
        }

        // Red while keep-awake is on, so a machine that is being held up is
        // never a surprise. Only at rest: hover, press and the open-panel
        // colour all win over it.
        BarButton {
            icon: Icons.sliders
            active: PopupService.isOpen("controls")
            rest: KeepAwake.enabled ? Colors.bar.keepAwake : Colors.bar.button
            restText: KeepAwake.enabled ? Colors.bar.keepAwakeText : Colors.bar.buttonText
            tooltip: KeepAwake.enabled ? "Keeping awake" : ""
            onClicked: PopupService.toggle("controls", root.screen)
        }
    }
}
