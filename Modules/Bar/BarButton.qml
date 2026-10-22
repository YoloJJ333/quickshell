// A small square icon button for the bar.
// Usage: BarButton { icon: Icons.power; onClicked: SessionService.toggle() }

import QtQuick
import qs.Config
import qs.Widgets

Rectangle {
    id: root

    property string icon: ""

    // Optional text after the glyph, e.g. the volume percentage. The button
    // widens to fit it, and a button with a label and no icon is just text.
    property string label: ""

    // Optional label shown underneath after hovering for a moment.
    property string tooltip: ""

    // Light the button up: its toggle is on, or its panel is open.
    property bool active: false

    // Grey the glyph out: whatever the button controls is switched off.
    property bool muted: false

    // Hover colours, overridable per button — see Colors.bar in Config/Colors.qml.
    property color accent: Colors.bar.buttonHover
    property color accentText: Colors.bar.buttonHoverText

    // Colours at rest, likewise. Only the idle state: hovering, pressing and
    // `active` all take precedence, so a button given a loud rest colour still
    // behaves exactly like its neighbours the moment the mouse reaches it.
    property color rest: Colors.bar.button
    property color restText: Colors.bar.buttonText

    signal clicked()

    // Foreground shared by the glyph and the label.
    property color fg: mouse.pressed ? Colors.bar.buttonPressedText
                     : mouse.containsMouse ? root.accentText
                     : root.active ? Colors.bar.buttonActiveText
                     : root.muted ? Colors.bar.buttonTextMuted
                     : root.restText

    // Exactly square when there is only a glyph, so a row of icon buttons is
    // evenly spaced; only a labelled one grows, and Theme.barButtonPadding is
    // how much room its text gets.
    implicitWidth: label.visible
                 ? content.implicitWidth + 2 * Theme.barButtonPadding * Theme.scale
                 : Theme.barButtonSize * Theme.scale
    implicitHeight: Theme.barButtonSize * Theme.scale
    radius: Theme.radiusSm * Theme.scale

    color: mouse.pressed ? Colors.bar.buttonPressed
         : mouse.containsMouse ? root.accent
         : root.active ? Colors.bar.buttonActive
         : root.rest

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }
    Behavior on fg {
        ColorAnimation { duration: Theme.animFast }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: Theme.spaceXs * Theme.scale

        IconSvg {
            id: glyph

            // Hidden rather than empty, so that a text-only button does not
            // carry an icon's worth of blank space — a Row skips what is not
            // visible.
            visible: root.icon !== ""
            path: root.icon
            color: root.fg
            size: Theme.iconSize * Theme.scale
        }

        Text {
            id: label

            // Matched to the glyph's height rather than anchored to it: items
            // inside a Row are not allowed anchors.
            visible: root.label !== ""
            height: Theme.iconSize * Theme.scale
            verticalAlignment: Text.AlignVCenter
            text: root.label
            color: root.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * Theme.scale

            // So that a label can carry <sub>, <b> and friends — the keyboard
            // layout uses it. RichText rather than StyledText: StyledText's tag
            // list does not include <sub>, and silently renders it flat.
            //
            // Only this shell writes these strings; nothing that arrives from
            // another application is put here.
            textFormat: Text.RichText
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    BarTooltip {
        anchorItem: root
        text: root.tooltip
        show: mouse.containsMouse
    }
}
