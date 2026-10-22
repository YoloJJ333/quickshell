// A small on/off switch, for the things in a panel that are simply on or off:
// the Wi-Fi radio, the Bluetooth adapter, a device's autoconnect.
//
// It does not flip itself — it reports the click and waits for `checked` to
// come back from whatever it controls, so it can never disagree with reality.
//
// It is as tall as a ChipButton even though the track is thinner, so that a
// row of mixed controls lines up.

import QtQuick
import qs.Config

Item {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: Theme.switchWidth * Theme.scale
    implicitHeight: Theme.chipSize * Theme.scale

    Rectangle {
        id: track

        anchors.centerIn: parent
        width: parent.width
        height: Theme.switchHeight * Theme.scale
        radius: height / 2
        color: root.checked ? Colors.popup.switchActive : Colors.popup.switchOff

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        Rectangle {
            readonly property real inset: 2 * Theme.scale

            width: parent.height - 2 * inset
            height: width
            radius: height / 2
            y: inset
            x: root.checked ? parent.width - width - inset : inset
            color: Colors.popup.switchKnob

            Behavior on x {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
