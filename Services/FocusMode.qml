pragma Singleton

// "Focus mode" — hides the wallpaper behind plain black while it is on, on the
// desktop and on the lock screen.
//
// Anything can flip it without knowing how it is drawn:
//   FocusMode.toggle()      — e.g. the control centre button
//   FocusMode.enabled       — read it to show the state
//
// hyprpaper is left alone: the black is a surface of our own laid over it
// (Modules/Desktop/FocusBackdrop.qml), so switching back is instant and needs
// nothing from hyprpaper or its config.
//
// hyprlock draws above everything, so nothing the shell puts on screen can
// cover it. Instead the shell writes a small hyprlock config file (`lockFile`)
// that hyprlock.conf sources: empty while focus mode is off, and while it is on
// a line blanking `$lock_wallpaper`, which leaves hyprlock to fill its
// background with its `color`. hyprlock reads its config each time it starts,
// so a change shows from the next lock on. The lines that go in hyprlock.conf
// are in the README, under "Focus mode".

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The single source of truth. Everything else follows this.
    property bool enabled: false

    // Fixed rather than Quickshell.statePath(), whose folder is named after a
    // hash, because hyprlock.conf has to spell this path out.
    readonly property string lockFile: `${Quickshell.env("HOME")}/.local/state/quickshell/yolojj333/hyprlock.conf`

    function enable(): void { root.enabled = true }
    function disable(): void { root.enabled = false }
    function setEnabled(value: bool): void { root.enabled = value }
    function toggle(): void { root.enabled = !root.enabled }

    function writeLockFile(): void {
        lock.setText(root.enabled
            ? "# Written by quickshell: focus mode is on.\n$lock_wallpaper =\n"
            : "# Written by quickshell: focus mode is off.\n");
    }

    onEnabledChanged: root.writeLockFile()

    // Also written at startup, so a lock screen left black from before a
    // restart is put back in step with focus mode starting off.
    Component.onCompleted: root.writeLockFile()

    FileView {
        id: lock

        path: root.lockFile
        printErrors: false // only ever written, never read
    }
}
