// The black that covers the wallpaper in focus mode. One per monitor, created
// next to the bar in shell.qml.
//
// hyprpaper draws on the layer-shell "background" layer; this sits one layer
// up, on "bottom", which is still underneath every window and the bar. So it
// hides the wallpaper and nothing else, whatever order the two started in.
//
// It fades rather than snapping, and the window only exists while there is
// something to show, so with focus mode off there is no surface here at all.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Services

PanelWindow {
    id: root

    required property var monitor

    screen: root.monitor
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    // Kept up through the fade-out, then dropped.
    visible: FocusMode.enabled || cover.opacity > 0

    WlrLayershell.namespace: "quickshell-focus"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Cover the whole monitor, under the bar too, instead of starting below it.
    exclusionMode: ExclusionMode.Ignore

    // An empty input region: clicks fall straight through to the desktop, as
    // if this were the wallpaper itself.
    mask: Region {}

    Rectangle {
        id: cover

        anchors.fill: parent
        color: Colors.desktop.focus
        opacity: FocusMode.enabled ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animSlow }
        }
    }
}
