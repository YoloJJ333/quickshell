// One button in the session menu grid: icon, label and a shortcut pill.
// It knows nothing about the grid — the parent tells it whether it is the
// keyboard selection, and it reports clicks and hovers back with signals.

import QtQuick
import qs.Config
import qs.Widgets

Rectangle {
    id: root

    required property var modelData   // one entry of SessionService.actions
    required property int index       // position in the grid, 0-based
    property bool active: false       // is this the keyboard selection?
    property bool showBadge: true     // the 1..6 shortcut pill
    property real uiScale: Theme.scale // set by SessionMenu, sizes everything below

    signal activated()
    signal hovered()

    readonly property bool destructive: modelData.destructive === true
    readonly property bool highlighted: mouse.pressed || root.active

    implicitWidth: Theme.tileWidth * root.uiScale
    implicitHeight: Theme.tileHeight * root.uiScale
    radius: Theme.radiusLg * root.uiScale
    border.width: Theme.borderWidth

    // Each state picks a named role out of Colors.menu — see Config/Colors.qml.
    color: root.highlighted ? Colors.menu.tileSelected
         : mouse.containsMouse ? Colors.menu.tileHover
         : root.destructive ? Colors.menu.tileDanger
         : Colors.menu.tile

    border.color: root.highlighted ? Colors.menu.tileSelectedBorder
         : mouse.containsMouse ? Colors.menu.tileHoverBorder
         : Colors.menu.tileBorder

    // Foreground colour shared by the icon, the label and the pill.
    property color fg: root.highlighted ? Colors.menu.tileSelectedText
         : mouse.containsMouse ? Colors.menu.tileHoverText
         : root.destructive ? Colors.menu.tileDangerText
         : Colors.menu.tileText

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on fg { ColorAnimation { duration: Theme.animFast } }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceSm * root.uiScale

        IconSvg {
            anchors.horizontalCenter: parent.horizontalCenter
            path: root.modelData.icon
            color: root.fg
            size: Theme.glyphSize * root.uiScale
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.modelData.label
            color: root.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLg * root.uiScale
            font.weight: Font.Medium
        }
    }

    // shortcut pill, top-right
    Rectangle {
        visible: root.showBadge
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spaceXs * root.uiScale
        implicitWidth: Math.max(implicitHeight, badge.implicitWidth + Theme.spaceSm * root.uiScale)
        implicitHeight: badge.implicitHeight + Theme.spaceXs * root.uiScale
        radius: Theme.radiusSm * root.uiScale
        color: Colors.withAlpha(root.fg, Colors.menu.badgeOpacity)

        Text {
            id: badge
            anchors.centerIn: parent
            text: root.index + 1
            color: root.color
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm * root.uiScale
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.activated()
    }
}
