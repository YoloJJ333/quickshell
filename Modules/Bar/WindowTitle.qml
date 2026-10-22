// The focused window's title — what an application would put in its own title
// bar, e.g. the folder a file manager is showing. Sits between the workspace
// dots and the clock.
//
// A title too long for the space scrolls slowly to its end and back, pausing
// at each end so both can be read. Speed and pause are in Theme.qml.
//
// It comes from the Wayland toplevel protocol rather than Hyprland's IPC:
// Hyprland's `activeToplevel` keeps pointing at the last window after you move
// to an empty workspace, so the old title would linger there. The Wayland one
// clears as soon as nothing has focus.
//
// Each bar shows the title only when that window is on its own monitor.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config

Item {
    id: root

    required property var monitor

    readonly property var toplevel: ToplevelManager.activeToplevel

    // A window can straddle monitors; it counts as on this one if any part of
    // it is. An empty list means the compositor has not said yet, which is
    // treated as "here" rather than flickering blank.
    readonly property bool here: root.toplevel !== null
                              && (root.toplevel.screens.length === 0
                                  || root.toplevel.screens.includes(root.monitor))

    property string title: root.here ? root.toplevel.title.trim() : ""

    // How far the text runs past the room it has. Nothing scrolls at 0.
    readonly property real overflow: Math.max(0, label.implicitWidth - root.width)

    // The overflow the running scroll was started with. Some titles change
    // many times a second — a terminal showing a spinner, say — and starting
    // over on every change would mean never getting anywhere. So the scroll
    // only starts over for a new window, or when the length has really
    // changed (a file manager moving to another folder); a glyph or two of
    // difference just carries on.
    property real distance: 0
    readonly property real tolerance: 4 * Theme.scale

    readonly property int travel: Math.round(1000 * root.distance / (Theme.titleScrollSpeed * Theme.scale))

    implicitHeight: Theme.barButtonSize * Theme.scale
    clip: true

    function restart(): void {
        scroll.stop();
        label.x = 0;
        root.distance = root.overflow;
        if (root.distance > 0)
            scroll.start();
    }

    onToplevelChanged: root.restart()
    onOverflowChanged: {
        if (Math.abs(root.overflow - root.distance) > root.tolerance)
            root.restart();
    }

    Text {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Colors.bar.windowTitle
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm * Theme.scale

        // Titles are whatever the application sends, so they are pinned to one
        // line in case one carries a newline.
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }

    SequentialAnimation {
        id: scroll

        loops: Animation.Infinite

        PauseAnimation { duration: Theme.titleScrollPause }
        NumberAnimation {
            target: label
            property: "x"
            to: -root.distance
            duration: root.travel
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: Theme.titleScrollPause }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: root.travel
            easing.type: Easing.InOutSine
        }
    }
}
