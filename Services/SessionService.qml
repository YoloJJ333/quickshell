pragma Singleton

// State and behaviour of the session (logout) menu, kept separate from its looks.
//
// Anything can open the menu without knowing how it is drawn:
//   SessionService.toggle()   — e.g. the bar button
//   SessionService.open()     — e.g. an IPC call from a Hyprland keybind
// and the menu itself just follows `SessionService.opened`.

import Quickshell
import qs.Widgets

Singleton {
    id: root

    // Is the menu currently on screen? SessionMenu binds its visibility to this.
    property bool opened: false

    // Row-major: reorder this list to rearrange the grid.
    // Commands run through `sh -c`, so $USER and friends expand as in a shell.
    readonly property var actions: [
        { label: "Lock",      cmd: "loginctl lock-session",         icon: Icons.lock },
        { label: "Logout",    cmd: "loginctl terminate-user $USER", icon: Icons.logout },
        { label: "Suspend",   cmd: "systemctl suspend",             icon: Icons.pause },
        { label: "Hibernate", cmd: "systemctl hibernate",           icon: Icons.zzz },
        { label: "Shutdown",  cmd: "systemctl poweroff",            icon: Icons.power, destructive: true },
        { label: "Reboot",    cmd: "systemctl reboot",              icon: Icons.refresh }
    ]

    function open(): void { root.opened = true }
    function close(): void { root.opened = false }
    function toggle(): void { root.opened = !root.opened }

    // Fires the command straight away: no arming, no countdown ring.
    function activate(i: int): void {
        if (i < 0 || i >= root.actions.length)
            return;

        Quickshell.execDetached(["sh", "-c", root.actions[i].cmd]);
        root.close();
    }
}
