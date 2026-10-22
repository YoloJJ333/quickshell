// An application's own tray menu, drawn by Quickshell as a native popup menu.
//
// Tray applications ship their menu over D-Bus rather than as anything this
// shell draws, so all there is to do is point at it and call open().
//
// Usage:
//   TrayMenu { id: appMenu; item: modelData; anchorItem: someItem }
//   ... appMenu.open()

import QtQuick
import Quickshell

QsMenuAnchor {
    id: root

    required property var item      // a SystemTrayItem
    required property Item anchorItem // what the menu should drop out of

    menu: root.item.menu
    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
}
