pragma Singleton

// Which keyboard layout is active, for the indicator on the bar.
//
// Hyprland is configured with a list of layouts and a matching list of
// variants — here, `us,us` and `,colemak_dh` — and switches between them by
// group index. The index is the only thing that distinguishes the two: both
// groups report an `active_keymap` of "English (US)", because the variant does
// not appear in the keymap name.
//
// So the index is read out of `hyprctl devices`, and re-read whenever Hyprland
// says the layout changed.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // What the bar shows for each layout, keyed by "layout" or "layout:variant".
    // These go through Text.StyledText, so <sub> and friends work.
    //
    // Anything not listed falls back to its variant, or its layout code, in
    // lower case — so a layout added to hyprland.conf shows something sensible
    // without needing an entry here.
    readonly property var displayNames: ({
        "us": "us",
        "us:colemak_dh": "us<sub>dh</sub>"
    })

    property string layout: ""       // short name for the bar, e.g. "COLEMAK-DH"
    property string description: ""  // the full thing, for the tooltip
    property string device: ""       // the keyboard the index came from
    property int count: 0            // how many layouts are configured

    // Nothing worth showing until there is more than one layout to be in.
    readonly property bool available: root.count > 1 && root.layout !== ""

    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }

    // Switching layouts is a hyprctl command of its own rather than a
    // dispatcher, which is lucky: dispatchers changed shape when Hyprland moved
    // to a Lua configuration, and this one did not. See WorkspaceService for the
    // dispatchers that did.
    function next(): void {
        if (root.device !== "")
            Quickshell.execDetached(["hyprctl", "switchxkblayout", root.device, "next"]);
    }

    function prettify(layout: string, variant: string): string {
        const key = variant !== "" ? `${layout}:${variant}` : layout;
        if (root.displayNames[key] !== undefined)
            return root.displayNames[key];

        return (variant !== "" ? variant : layout).replace(/_/g, "-").toLowerCase();
    }

    // Every device carries the same layout list, but only the keyboard being
    // typed on changes group — so picking the right one is the whole problem.
    function pickKeyboard(keyboards: var): var {
        // Whatever Hyprland last reported a layout change for is definitive.
        const reported = keyboards.find(k => k.name === root.device);
        if (reported)
            return reported;

        // Before any change has been seen: one that has already left group 0,
        // otherwise something that at least calls itself a keyboard. The lid
        // switch and the power button are in this list too.
        return keyboards.find(k => k.active_layout_index > 0)
            ?? keyboards.find(k => k.name.toLowerCase().includes("keyboard"))
            ?? keyboards[0];
    }

    function parse(json: string): void {
        const keyboards = JSON.parse(json).keyboards ?? [];

        // Virtual keyboards — the one ibus creates, for instance — carry the
        // layout list but never leave group 0, so they are never the answer.
        const physical = keyboards.filter(k => !k.name.startsWith("hl-virtual-"));
        if (physical.length === 0)
            return;

        const active = root.pickKeyboard(physical);

        const layouts = active.layout.split(",").map(s => s.trim());
        const variants = (active.variant ?? "").split(",").map(s => s.trim());
        const index = Math.min(active.active_layout_index, layouts.length - 1);

        root.device = active.name;
        root.count = layouts.length;
        root.layout = root.prettify(layouts[index], variants[index] ?? "");
        root.description = variants[index]
                         ? `${layouts[index]} · ${variants[index]}`
                         : layouts[index];
    }

    Component.onCompleted: root.refresh()

    Process {
        id: reader

        command: ["hyprctl", "devices", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Connections {
        target: Hyprland

        // "activelayout" carries "KEYBOARDNAME,LAYOUTNAME", and the name is what
        // settles which keyboard to trust. ibus's virtual keyboard announces
        // itself constantly and never actually changes group, so its events are
        // dropped rather than allowed to claim the indicator.
        function onRawEvent(event: var): void {
            if (event.name !== "activelayout")
                return;

            const keyboard = event.data.split(",")[0];
            if (keyboard.startsWith("hl-virtual-"))
                return;

            root.device = keyboard;
            root.refresh();
        }
    }
}
