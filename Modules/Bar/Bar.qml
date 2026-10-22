// The top bar. One instance per monitor, created by the Variants block in
// shell.qml: the system monitor, workspaces and the focused window's title on
// the left, the clock in the middle, the status cluster on the right.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Services

PanelWindow {
    id: root

    // Which monitor this bar belongs to. PopupLayer takes the same property,
    // so shell.qml hands both windows the screen the same way.
    required property var monitor

    screen: root.monitor
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight * Theme.scale
    color: Colors.bar.background

    WlrLayershell.namespace: "quickshell-bar"

    // Needed for the tray applications' own menus. Those open as Wayland popups
    // with a pointer grab, and a compositor will not grant a grab to a layer
    // surface that refuses keyboard focus — the menu silently never appears.
    // "OnDemand" only takes focus when something here actually asks for it.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    SystemMonitor {
        id: monitor

        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceSm * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
    }

    Workspaces {
        id: workspaces

        anchors.left: monitor.right
        anchors.leftMargin: Theme.barGroupSpacing * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
    }

    // Fills whatever room is left between the dots and the clock, so a long
    // title shortens itself rather than running underneath either of them.
    WindowTitle {
        anchors.left: workspaces.right
        anchors.leftMargin: Theme.barGroupSpacing * Theme.scale
        anchors.right: clock.left
        anchors.rightMargin: Theme.barGroupSpacing * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        monitor: root.monitor
    }

    Clock {
        id: clock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    StatusArea {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceXs * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        screen: root.monitor

        // A tray icon being dragged towards the drawer reparents itself to the
        // whole bar, so that it is neither clipped nor reflowing the row it
        // came out of.
        dragRoot: root.contentItem
    }

    // Tells the compositor not to consider the session idle. It has to hang off
    // a real window, and the bar is the one window that is always on screen.
    // The rest of the keep-awake logic is in Services/KeepAwake.qml.
    IdleInhibitor {
        window: root
        enabled: KeepAwake.enabled
    }
}
