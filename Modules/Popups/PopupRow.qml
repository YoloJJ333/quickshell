// One entry in a panel's list: an icon, a name, a line of status underneath,
// and room on the right for switches or chip buttons.
//
// The icon can be given either as SVG path data from Widgets/Icons.qml
// (`iconPath`) or as an image URL (`iconSource`, used for the icons that
// applications and BlueZ supply themselves). `iconSource` wins if both are set.
//
// Set `interactive: false` for a row that is only there to be read — it stops
// reacting to the mouse and greys its text.

import QtQuick
import Quickshell.Widgets
import qs.Config
import qs.Widgets

Rectangle {
    id: root

    property string label: ""
    property string sublabel: ""
    property string iconPath: ""
    property string iconSource: ""

    property bool current: false      // the network/device in use right now
    property bool interactive: true

    // Anything put inside the row lands in the group on the right.
    default property alias trailing: trailingRow.data

    signal clicked()

    readonly property bool hovered: root.interactive && mouse.containsMouse
    readonly property bool pressed: root.interactive && mouse.pressed

    // Foreground shared by the icon and the first line of text.
    readonly property color fg: root.pressed ? Colors.popup.rowPressedText
                              : !root.interactive ? Colors.popup.rowTextMuted
                              : Colors.popup.rowText

    implicitWidth: parent ? parent.width : 0
    implicitHeight: Theme.rowHeight * Theme.scale
    radius: Theme.radiusMd * Theme.scale

    color: root.pressed ? Colors.popup.rowPressed
         : root.hovered ? Colors.popup.rowHover
         : root.current ? Colors.popup.rowCurrent
         : Colors.popup.row

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    // Declared before everything else so that the chips in `trailing` sit on
    // top of it and get their own clicks.
    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    IconSvg {
        id: vectorIcon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconPath !== "" && root.iconSource === ""
        path: root.iconPath
        color: root.fg
        size: Theme.iconSize * Theme.scale
    }

    IconImage {
        id: imageIcon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconSource !== ""
        source: root.iconSource
        implicitSize: Theme.iconSize * Theme.scale
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: (vectorIcon.visible || imageIcon.visible)
                          ? (2 * Theme.spaceSm + Theme.iconSize) * Theme.scale
                          : Theme.spaceSm * Theme.scale
        anchors.right: trailingRow.left
        anchors.rightMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1 * Theme.scale

        // Both lines are pinned to one line each: some of this text comes
        // straight from other applications, and a stray newline in it would
        // otherwise push the row out through the bottom of the panel.
        Text {
            width: parent.width
            text: root.label
            color: root.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBody * Theme.scale - 1
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            width: parent.width
            visible: root.sublabel !== ""
            text: root.sublabel
            color: root.pressed ? Colors.popup.rowPressedText : Colors.popup.rowTextMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs * Theme.scale
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Row {
        id: trailingRow

        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceXs * Theme.scale
    }
}
