// A full-width slider with an icon on the left and its value on the right:
//
//   [icon] ━━━━━●──────────  85%
//
// `value` runs 0..1. Like ToggleSwitch it never moves itself — it reports where
// the handle was dragged to and waits for `value` to come back from whatever it
// controls, so it cannot drift out of step with the real setting.
//
// `moved` fires continuously while dragging; whatever is listening is expected
// to cope with that (both AudioService and BrightnessService do).

import QtQuick
import qs.Config
import qs.Widgets

Item {
    id: root

    property string iconPath: ""
    property real value: 0
    property string valueText: ""

    // Clicking the icon — mute, or whatever else suits.
    signal iconClicked()
    signal moved(real value)

    implicitWidth: parent ? parent.width : 0
    implicitHeight: Theme.rowHeight * Theme.scale

    IconSvg {
        id: icon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        path: root.iconPath
        color: iconMouse.containsMouse ? Colors.popup.sliderFill : Colors.popup.rowText
        size: Theme.iconSize * Theme.scale

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        MouseArea {
            id: iconMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Text {
        id: readout

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        width: Theme.chipSize * 1.6 * Theme.scale
        text: root.valueText
        color: Colors.popup.rowTextMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs * Theme.scale
    }

    Item {
        id: track

        anchors.left: icon.right
        anchors.right: readout.left
        anchors.leftMargin: Theme.spaceSm * Theme.scale
        anchors.rightMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.sliderKnob * Theme.scale

        readonly property real knobSize: Theme.sliderKnob * Theme.scale
        readonly property real span: Math.max(1, track.width - track.knobSize)

        Rectangle {
            id: groove

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.sliderHeight * Theme.scale
            radius: height / 2
            color: Colors.popup.slider

            Rectangle {
                width: parent.width * root.value
                height: parent.height
                radius: parent.radius
                color: Colors.popup.sliderFill
            }
        }

        Rectangle {
            id: knob

            x: track.span * root.value
            width: track.knobSize
            height: track.knobSize
            radius: height / 2
            color: Colors.popup.sliderKnob
            scale: drag.pressed ? 1.15 : 1

            Behavior on scale {
                NumberAnimation { duration: Theme.animFast }
            }
        }

        MouseArea {
            id: drag

            // Taller than the track so it is easier to grab, but exactly as
            // wide, so `event.x` needs no correcting below.
            anchors.fill: parent
            anchors.topMargin: -Theme.spaceSm * Theme.scale
            anchors.bottomMargin: -Theme.spaceSm * Theme.scale
            cursorShape: Qt.PointingHandCursor

            function report(x: real): void {
                const at = (x - track.knobSize / 2) / track.span;
                root.moved(Math.max(0, Math.min(1, at)));
            }

            onPressed: event => drag.report(event.x)
            onPositionChanged: event => {
                if (drag.pressed)
                    drag.report(event.x);
            }
        }
    }
}
