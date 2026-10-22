pragma Singleton

// Hyprland's workspaces, as the bar wants to see them.
//
// The bar shows a fixed row of dots rather than only the workspaces that
// happen to exist: `numbered` of them for 1..n, then one per entry in
// `specials`. A workspace Hyprland has never created simply has no object
// behind it yet, which is why every lookup here copes with finding nothing —
// the dot is still there and still switches to it.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // How many numbered dots to draw, and which special workspaces follow them.
    readonly property int numbered: 10
    readonly property var specials: ["scratchpad", "majic"]

    readonly property var workspaces: Hyprland.workspaces.values

    // Hyprland calls a special workspace "special:<name>".
    function specialId(name: string): string {
        return `special:${name}`;
    }

    function find(id: int): var {
        return root.workspaces.find(w => w.id === id) ?? null;
    }

    function findSpecial(name: string): var {
        return root.workspaces.find(w => w.name === root.specialId(name)) ?? null;
    }

    // Whether anything is open on it. `toplevels` is kept up to date from
    // Hyprland's window events as they happen. Not `lastIpcObject.windows`:
    // that is a snapshot only re-read on *workspace* events, so it lagged
    // behind a window being opened — and on a special workspace, which is
    // created by its first window, stayed at zero until next toggled.
    function isOccupied(workspace: var): bool {
        return workspace !== null && workspace.toplevels.values.length > 0;
    }

    // Hyprland's Lua configuration replaced the old flat dispatcher strings
    // with expressions: `hl.dispatch()` wants a dispatcher object now, so
    // "workspace 3" arrives as `hl.dispatch(workspace 3)` and is a Lua syntax
    // error. The failure is reported to Quickshell's log and nowhere else, so a
    // button wired the old way simply does nothing when clicked.
    //
    // `Hyprland.usingLua` says which configuration is in use, so both spellings
    // stay here and the shell works either way.
    function focus(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua
                        ? `hl.dsp.focus({ workspace = ${id} })`
                        : `workspace ${id}`);
    }

    // Special workspaces are shown over whatever you are on rather than
    // switched to, so the same click both opens and closes one.
    function toggleSpecial(name: string): void {
        Hyprland.dispatch(Hyprland.usingLua
                        ? `hl.dsp.workspace.toggle_special("${name}")`
                        : `togglespecialworkspace ${name}`);
    }
}
