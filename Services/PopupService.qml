pragma Singleton

// Which panel is dropped out of the bar, if any.
//
// There is only ever one, so opening a second closes the first. A panel is
// identified by a plain name string ("wifi", "bluetooth", "tray"), which both
// the bar button and the panel itself refer to:
//
//   BarButton { active: PopupService.isOpen("wifi")
//               onClicked: PopupService.toggle("wifi", root.screen) }
//   PopupCard { name: "wifi"; ... }
//
// `screen` decides which monitor the panel drops out of, so on a multi-monitor
// setup it appears on the bar that was clicked.

import Quickshell

Singleton {
    id: root

    // Name of the open panel, or "" when nothing is open.
    property string current: ""

    // The monitor the open panel belongs to.
    property var screen: null

    function isOpen(name: string): bool {
        return root.current === name;
    }

    function open(name: string, onScreen: var): void {
        root.screen = onScreen;
        root.current = name;
    }

    function close(): void {
        root.current = "";
    }

    function toggle(name: string, onScreen: var): void {
        if (root.isOpen(name))
            root.close();
        else
            root.open(name, onScreen);
    }
}
