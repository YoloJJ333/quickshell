pragma Singleton

// Flavour text for the control centre, picked fresh every time the panel opens.
//
// ── Add your own lines to the list below. ──
//
// Anything goes; they are drawn as the small line under the "Controls" heading,
// so one short sentence works best. The same line is never picked twice in a
// row, so a short list still feels varied.

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var lines: [
        "Everything is fine.",
        "All systems nominal.",
        "The pixels are holding.",
        "No notifications. Blissful.",
        "Somewhere, a fan is spinning.",
        "Electrons arriving on schedule.",
        "Quietly doing nothing in particular.",
        "The compositor sends its regards.",
        "Warm, dry, and reasonably powered.",
        "Still here. Still going.",
        "Nothing on fire that I can see.",
        "Running on hope and a battery.",
        "The desktop is in a good mood.",
        "Ready when you are."
    ]

    // The line shown last, so it does not come up twice in a row.
    property string previous: ""

    function pick(): string {
        if (root.lines.length === 0)
            return "";
        if (root.lines.length === 1)
            return root.lines[0];

        let choice = root.previous;
        while (choice === root.previous)
            choice = root.lines[Math.floor(Math.random() * root.lines.length)];

        root.previous = choice;
        return choice;
    }
}
