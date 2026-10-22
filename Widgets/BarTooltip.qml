// The little label that appears under a bar item after hovering it for a moment.
//
// It has to be its own window: the bar is only as tall as one row of icons, so
// anything drawn inside it would be cut off at the bottom edge.
//
// Usage:
//   MouseArea { id: hover; hoverEnabled: true }
//   BarTooltip { anchorItem: root; text: "..."; show: hover.containsMouse }

import QtQuick
import Quickshell
import qs.Config

PopupWindow {
    id: root

    required property Item anchorItem
    property string text: ""

    // Set this to whatever means "the mouse is over the thing" — the delay is
    // applied here rather than at every call site.
    property bool show: false

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: label.implicitWidth + 2 * Theme.spaceSm * Theme.scale
    implicitHeight: label.implicitHeight + 2 * Theme.spaceXs * Theme.scale

    // Set once the pointer has been still for long enough — see the timer below.
    property bool settled: false

    onShowChanged: if (!root.show) root.settled = false

    visible: root.text !== "" && root.settled
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd * Theme.scale
        color: Colors.bar.tooltip
        border.width: Theme.borderWidth
        border.color: Colors.bar.tooltipBorder

        Text {
            id: label

            anchors.centerIn: parent
            text: root.text
            color: Colors.bar.tooltipText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale
        }
    }

    // Hovering past the bar on the way somewhere else should not flash a
    // tooltip, so the label waits for the pointer to settle. Clearing `settled`
    // is left to onShowChanged above: a one-shot Timer stops itself when it
    // fires, so doing it on `running` would undo the tooltip immediately.
    Timer {
        running: root.show
        interval: Theme.tooltipDelay
        onTriggered: root.settled = true
    }
}
