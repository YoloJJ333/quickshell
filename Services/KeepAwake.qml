pragma Singleton

// "Keep the device awake" — blocks the screen blanking, locking or suspending
// on its own while it is on. Manual suspend (the session menu) still works.
//
// Anything can flip it without knowing how it is enforced:
//   KeepAwake.toggle()      — e.g. the bar button
//   KeepAwake.enabled       — read it to show the state
//
// Two mechanisms are held at once because idle is decided in two places:
//
//   1. the compositor's idle-notify protocol, which is what hypridle and
//      friends listen to. Blocked by the Wayland idle-inhibit protocol, which
//      needs a window to hang off — see the IdleInhibitor in Modules/Bar/Bar.qml.
//   2. logind's own idle handling. Blocked by holding a `systemd-inhibit` lock,
//      which is the Process below. `--what=idle` only: taking a `sleep` lock
//      too would also block a deliberate `systemctl suspend`.
//
// Both are released the moment `enabled` goes false, and again if the shell
// exits, so it can never get stuck on.

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The single source of truth. Everything else follows this.
    property bool enabled: false

    function enable(): void { root.enabled = true }
    function disable(): void { root.enabled = false }
    function setEnabled(value: bool): void { root.enabled = value }
    function toggle(): void { root.enabled = !root.enabled }

    // Lives exactly as long as `enabled` is true: `sleep infinity` does nothing
    // but keep systemd-inhibit alive, and the lock is held for its lifetime.
    // Visible in `systemd-inhibit --list`.
    Process {
        running: root.enabled
        command: [
            "systemd-inhibit",
            "--what=idle",
            "--who=quickshell",
            "--why=Keep awake is on",
            "--mode=block",
            "sleep", "infinity"
        ]
    }
}
