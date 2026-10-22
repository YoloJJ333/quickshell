// The battery gauge: a battery outline with the charge level filling it from
// the left and the percentage printed inside.
//
// The fill slides green → yellow → orange → red as the battery drains; the ramp
// itself is Colors.battery.ramp and the interpolation is BatteryService.
//
// The percentage is drawn twice — once light for the empty part of the gauge
// and once dark, clipped to the fill — so it stays legible at every level
// without ever sitting on a colour it disappears into.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Item {
    id: root

    visible: BatteryService.available

    // Where the gauge sits within its slot. Both knobs are in Theme.qml; the
    // left one goes to nothing while charging, because the bolt is drawn in
    // that space and would push the gauge across otherwise.
    readonly property real padLeft: BatteryService.charging
                                  ? 0
                                  : Theme.batteryPaddingLeft * Theme.scale
    readonly property real padRight: Theme.batteryPaddingRight * Theme.scale

    implicitWidth: content.implicitWidth + root.padLeft + root.padRight
    implicitHeight: Theme.barButtonSize * Theme.scale

    // How long is left, on hover.
    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
    }

    BarTooltip {
        anchorItem: root
        text: BatteryService.summary
        show: hover.containsMouse
    }

    Row {
        id: content

        // Anchored to the left rather than centred, so that the two paddings
        // are honoured separately instead of being averaged into one.
        anchors.left: parent.left
        anchors.leftMargin: root.padLeft
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1 * Theme.scale

        IconSvg {
            visible: BatteryService.charging
            path: Icons.bolt
            size: Theme.batteryHeight * Theme.scale
            strokeWidth: 2.2
            color: Colors.battery.charging
        }

        Item {
            id: gauge

            implicitWidth: body.width + nub.width
            implicitHeight: Theme.batteryHeight * Theme.scale

            Rectangle {
                id: body

                width: Theme.batteryWidth * Theme.scale
                height: parent.height
                radius: Theme.radiusSm * Theme.scale
                color: Colors.battery.body
                border.width: Math.max(1, Math.round(1.4 * Theme.scale))
                border.color: Colors.battery.outline
            }

            Rectangle {
                id: fill

                readonly property real inset: 2 * Theme.scale

                x: fill.inset
                y: fill.inset
                width: Math.max(0, (body.width - 2 * fill.inset) * BatteryService.level)
                height: body.height - 2 * fill.inset
                radius: Theme.radiusSm * Theme.scale * 0.7
                color: BatteryService.fillColor

                Behavior on width {
                    NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animNormal }
                }
            }

            // The little terminal on the positive end.
            Rectangle {
                id: nub

                anchors.left: body.right
                anchors.verticalCenter: body.verticalCenter
                width: 2 * Theme.scale
                height: parent.height * 0.42
                radius: width / 2
                color: Colors.battery.outline
            }

            Text {
                id: label

                anchors.centerIn: body
                text: BatteryService.percent
                color: Colors.battery.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs * Theme.scale
                font.weight: Font.DemiBold
            }

            // The same number again, in the dark ink, showing only where the
            // fill is behind it.
            Item {
                width: fill.x + fill.width
                height: gauge.height
                clip: true

                Text {
                    x: label.x
                    y: label.y
                    text: label.text
                    font: label.font
                    color: Colors.battery.textOnFill
                }
            }
        }
    }
}
