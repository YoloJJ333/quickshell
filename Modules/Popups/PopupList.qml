// The scrolling part of a panel, under the header.
//
// It is exactly as tall as its contents until they pass Theme.popupMaxHeight,
// after which it stops growing and scrolls instead — so a panel showing two
// networks is short and one showing thirty is not taller than the screen.

import QtQuick
import qs.Config

Flickable {
    id: root

    // Anything put inside the list is stacked vertically in `column`.
    default property alias items: column.data

    implicitWidth: parent ? parent.width : 0
    implicitHeight: Math.min(column.implicitHeight, Theme.popupMaxHeight * Theme.scale)

    contentWidth: root.width
    contentHeight: column.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 6000

    // Rendering the list into its own texture is what keeps the scrolled-away
    // rows out of sight. Plain `clip` is not enough: the stroked icons are
    // QtQuick.Shapes, and the curve renderer draws straight past a clip node.
    clip: true
    layer.enabled: true

    Column {
        id: column

        width: root.width
        spacing: 2 * Theme.scale
    }
}
