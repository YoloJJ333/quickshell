// The control centre: the panel behind the sliders button at the end of the
// bar, and the place where anything that is neither a status readout nor a
// list of things to connect to should go.
//
// The power button in its top right corner opens the session menu.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Theme.spaceSm * Theme.scale

    readonly property bool opened: PopupService.isOpen("controls")

    // A fresh line every time the panel is opened. The list to add to is in
    // Config/Flavor.qml.
    //
    // Assigned rather than bound: picking a line also records it as the one to
    // avoid repeating, and a binding that writes to what it reads is a loop.
    property string flavor: ""

    Component.onCompleted: root.flavor = Flavor.pick()

    onOpenedChanged: if (root.opened) root.flavor = Flavor.pick()

    // Read the brightness back from the script while the panel is up, so the
    // slider follows the brightness keys instead of only its own drags.
    Binding {
        target: BrightnessService
        property: "watching"
        value: root.opened
    }

    PopupHeader {
        width: parent.width
        title: "Controls"
        subtitle: root.flavor

        // Left to right, in source order.
        ChipButton {
            icon: Icons.focus
            active: FocusMode.enabled
            onClicked: FocusMode.toggle()
        }

        ChipButton {
            icon: Icons.coffee
            active: KeepAwake.enabled
            onClicked: KeepAwake.toggle()
        }

        ChipButton {
            icon: Icons.power
            danger: true
            onClicked: {
                PopupService.close();
                SessionService.open();
            }
        }
    }

    SliderRow {
        width: parent.width
        visible: AudioService.available
        iconPath: AudioService.muted ? Icons.volumeMute
                : AudioService.percent < 50 ? Icons.volumeLow
                : Icons.volume
        value: AudioService.volume
        valueText: `${AudioService.percent}%`
        onIconClicked: AudioService.toggleMute()
        onMoved: value => AudioService.setVolume(value)
    }

    SliderRow {
        width: parent.width
        iconPath: Icons.brightness
        value: BrightnessService.fraction
        valueText: `${BrightnessService.level}`
        onMoved: value => BrightnessService.setFraction(value)
    }
}
