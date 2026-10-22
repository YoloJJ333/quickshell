// One reading in the system monitor: an icon, a number, and the detail behind
// the number on hover. Not a button — nothing happens when it is clicked.
//
// Usage: MonitorReadout { icon: Icons.cpu; value: "12%"; widest: "100%" }

import QtQuick
import qs.Config
import qs.Widgets

Item {
    id: root

    property string icon: ""
    property string value: ""

    // How much room the number gets whatever it currently says, so "5%"
    // ticking over to "12%" does not shove every readout to its right along by
    // a character. Two digits, not three: a reading of 100% is rare and brief,
    // and reserving for it left a permanent hole after every other value.
    property string widest: ""

    property string tooltip: ""

    // Past its threshold — drawn in the warning colour.
    property bool hot: false

    readonly property color fg: root.hot ? Colors.monitor.hot : Colors.monitor.text

    implicitWidth: content.implicitWidth
    implicitHeight: Theme.barButtonSize * Theme.scale

    Row {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.monitorGap * Theme.scale

        IconSvg {
            path: root.icon
            size: Theme.iconSize * Theme.scale
            color: root.hot ? Colors.monitor.hot : Colors.monitor.icon

            Behavior on color {
                ColorAnimation { duration: Theme.animNormal }
            }
        }

        Text {
            id: label

            // Matched to the glyph's height rather than anchored to it: items
            // inside a Row are not allowed anchors.
            width: Math.max(implicitWidth, reserve.width)
            height: Theme.iconSize * Theme.scale
            verticalAlignment: Text.AlignVCenter
            text: root.value
            color: root.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale

            Behavior on color {
                ColorAnimation { duration: Theme.animNormal }
            }
        }
    }

    TextMetrics {
        id: reserve

        font: label.font
        text: root.widest
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
    }

    BarTooltip {
        anchorItem: root
        text: root.tooltip
        show: hover.containsMouse
    }
}
