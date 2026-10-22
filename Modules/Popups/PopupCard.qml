// The card a panel is drawn on: rounded background, border, and the fade the
// panel appears with. One of these wraps each panel in PopupLayer.qml.
//
// Usage:
//   PopupCard {
//       name: "wifi"        // the name PopupService opens it under
//       WifiPanel {}
//   }
//
// The card is always present and simply fades itself in and out, so a panel
// keeps its scroll position while the shell is running.

import QtQuick
import qs.Config
import qs.Services

Rectangle {
    id: root

    required property string name

    // Whatever is put inside the card ends up in `body`.
    default property alias content: body.data

    readonly property bool opened: PopupService.isOpen(root.name)
    readonly property real padding: Theme.spaceMd * Theme.scale

    anchors.right: parent.right
    anchors.top: parent.top

    implicitWidth: Theme.popupWidth * Theme.scale
    implicitHeight: body.height + 2 * root.padding

    color: Colors.popup.background
    radius: Theme.radiusXl * Theme.scale
    border.width: Theme.borderWidth
    border.color: Colors.popup.border

    // Grow out of the corner it is anchored to rather than its middle.
    transformOrigin: Item.TopRight
    visible: root.opacity > 0
    opacity: root.opened ? 1 : 0
    scale: root.opened ? 1 : 0.96

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    // Swallow clicks so they do not reach the dismiss area behind the card.
    MouseArea {
        anchors.fill: parent
    }

    Item {
        id: body

        x: root.padding
        y: root.padding
        width: root.width - 2 * root.padding
        height: childrenRect.height
    }
}
