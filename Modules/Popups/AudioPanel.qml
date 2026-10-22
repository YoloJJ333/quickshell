// The audio panel: one slider for the default output, and the icon mutes it.
//
// The control centre carries the same slider; both drive AudioService, so
// whichever one you use the other follows.

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
        title: "Volume"
        subtitle: AudioService.available ? AudioService.deviceName : "No output"

        ChipButton {
            icon: AudioService.muted ? Icons.volumeMute : Icons.volume
            active: AudioService.muted
            onClicked: AudioService.toggleMute()
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
}
