//@ pragma UseQApplication

// Entry point of the shell: `qs -c yolojj333`.
//
// The pragma above is what lets the tray applications' own menus open —
// Quickshell refuses QsMenuAnchor.open() without it. It is read once at
// startup, so changing it needs a restart rather than a reload.
//
// This file only wires modules together — the actual widgets live in Modules/,
// shared state in Services/, reusable pieces in Widgets/ and the styling in
// Config/. Each of those folders has a `qmldir` naming it as a module, which is
// what makes the `import qs.Something` lines below work.

import Quickshell
import Quickshell.Io
import qs.Services
import qs.Modules.Bar
import qs.Modules.Popups
import qs.Modules.SessionMenu
import qs.Modules.Desktop

ShellRoot {
    // Every monitor gets a bar and, sitting over it, the surface its panels are
    // drawn on. Variants recreates the delegate for every entry in the model
    // and passes that entry to it as `modelData`; Scope is just a bag to hold
    // the two windows together.
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            Bar {
                monitor: perScreen.modelData
            }

            PopupLayer {
                monitor: perScreen.modelData
            }

            // Only puts a window up while focus mode is on.
            FocusBackdrop {
                monitor: perScreen.modelData
            }
        }
    }

    // The session menu exists from startup but stays hidden until something
    // calls SessionService.open()/toggle().
    SessionMenu {}

    // External control, e.g. a Hyprland keybind:
    //   bind = SUPER SHIFT, E, exec, qs -c yolojj333 ipc call session toggle
    // List what is available with:
    //   qs -c yolojj333 ipc show
    IpcHandler {
        target: "session"

        function open(): void { SessionService.open() }
        function close(): void { SessionService.close() }
        function toggle(): void { SessionService.toggle() }
    }

    //   bind = SUPER, F, exec, qs -c yolojj333 ipc call focus toggle
    IpcHandler {
        target: "focus"

        function enable(): void { FocusMode.enable() }
        function disable(): void { FocusMode.disable() }
        function toggle(): void { FocusMode.toggle() }
    }
}
