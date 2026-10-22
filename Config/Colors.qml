pragma Singleton

// Every colour in the shell, in two layers:
//
//   1. `palette` — the raw colours, named after what they look like.
//      Nothing is drawn with these directly.
//   2. the role blocks below (`bar`, `workspace`, `popup`, `battery`,
//      `monitor`, `desktop`, `menu`) — one entry per visible part and state, each
//      pointing at a palette colour.
//
// So: change a palette hex to recolour everything that uses that colour, or
// repoint a role to move one single part onto a different colour.
//
// The QML files only ever mention roles, never the palette, e.g.
//   color: Colors.popup.background
//
// Note: a property may not be named "on" + a capital letter (onError, onHover).
// QML reads that as a signal handler and refuses to load the file.

import Quickshell
import QtQuick

Singleton {
    id: root

    // ── 1. palette ───────────────────────────────────────────────────────────
    readonly property QtObject palette: QtObject {
        readonly property color night: "#070722"    // deepest background
        readonly property color eggplant: "#120722" // raised background
        readonly property color plum: "#1f1138"     // raised background, lighter
        readonly property color slate: "#2b1a49"    // raised background, lightest
        readonly property color indigo: "#21215f"   // borders
        readonly property color ink: "#0e0e43"      // text on bright fills
        readonly property color paper: "#f3edf7"    // text on dark fills
        readonly property color haze: "#8f86b0"     // secondary text on dark fills
        readonly property color butter: "#fff59b"   // selection / press
        readonly property color mint: "#9bfece"     // hover
        readonly property color leaf: "#57d98a"     // full battery, "connected"
        readonly property color lemon: "#f2d75c"    // half battery
        readonly property color amber: "#ffb454"    // low battery, toggle switched on
        readonly property color coral: "#fd4663"    // empty battery, danger
        readonly property color black: "#000000"    // focus mode's desktop
    }

    // ── 2a. the bar ──────────────────────────────────────────────────────────
    readonly property QtObject bar: QtObject {
        readonly property color background: root.palette.night
        readonly property color text: root.palette.paper
        readonly property color separator: root.palette.indigo

        // the focused window's title — the same white as the system monitor's
        // numbers
        readonly property color windowTitle: root.palette.paper

        // icon buttons: idle is transparent so the bar shows through
        readonly property color button: "transparent"
        readonly property color buttonText: root.palette.paper
        readonly property color buttonTextMuted: root.palette.haze // feature switched off
        readonly property color buttonHover: root.palette.mint
        readonly property color buttonHoverText: root.palette.ink
        readonly property color buttonPressed: root.palette.butter
        readonly property color buttonPressedText: root.palette.ink

        // a toggle button that is switched on, or whose panel is open
        readonly property color buttonActive: root.palette.amber
        readonly property color buttonActiveText: root.palette.ink

        // the power button, which gets the danger colour on hover
        readonly property color powerHover: root.palette.coral
        readonly property color powerHoverText: root.palette.ink

        // the control centre button while keep-awake is switched on — at rest
        // only; hovering and pressing it look the same as any other button
        readonly property color keepAwake: root.palette.coral
        readonly property color keepAwakeText: root.palette.ink

        // the little label that appears under a hovered bar item
        readonly property color tooltip: root.palette.eggplant
        readonly property color tooltipText: root.palette.paper
        readonly property color tooltipBorder: root.palette.indigo

        // the tray drawer while an icon is being dragged onto it
        readonly property color dropTarget: root.palette.mint
        readonly property color dropTargetText: root.palette.ink
    }

    // ── 2b. the workspace dots ───────────────────────────────────────────────
    readonly property QtObject workspace: QtObject {
        // nothing open on it
        readonly property color empty: "transparent"
        readonly property color emptyText: root.palette.haze
        readonly property color emptyBorder: root.palette.indigo

        // has windows, but you are not looking at it
        readonly property color occupied: root.palette.plum
        readonly property color occupiedText: root.palette.paper
        readonly property color occupiedBorder: "transparent"

        // the one you are on
        readonly property color focused: root.palette.mint
        readonly property color focusedText: root.palette.ink
        readonly property color focusedBorder: "transparent"

        readonly property color hover: root.palette.butter
        readonly property color hoverText: root.palette.ink

        readonly property color urgent: root.palette.coral
        readonly property color urgentText: root.palette.ink
    }

    // ── 2c. the panels that drop out of the bar ──────────────────────────────
    readonly property QtObject popup: QtObject {
        readonly property color background: root.palette.eggplant
        readonly property color border: root.palette.indigo
        readonly property color separator: root.palette.plum

        readonly property color heading: root.palette.paper
        readonly property color sectionLabel: root.palette.haze

        // a list row at rest, hovered, and while the mouse is down
        readonly property color row: "transparent"
        readonly property color rowText: root.palette.paper
        readonly property color rowTextMuted: root.palette.haze
        readonly property color rowHover: root.palette.slate
        readonly property color rowHoverText: root.palette.paper
        readonly property color rowPressed: root.palette.mint
        readonly property color rowPressedText: root.palette.ink

        // the row of the thing you are currently connected to
        readonly property color rowCurrent: root.palette.plum
        readonly property color rowCurrentText: root.palette.paper
        readonly property color accent: root.palette.leaf   // "connected" ticks and dots

        // small square buttons inside a row (pin, menu, forget)
        readonly property color chip: root.palette.plum
        readonly property color chipText: root.palette.haze
        readonly property color chipHover: root.palette.mint
        readonly property color chipHoverText: root.palette.ink
        readonly property color chipActive: root.palette.amber
        readonly property color chipActiveText: root.palette.ink
        readonly property color chipDanger: root.palette.coral
        readonly property color chipDangerText: root.palette.ink

        // the on/off switches in panel headers
        readonly property color switchOff: root.palette.slate
        readonly property color switchActive: root.palette.leaf
        readonly property color switchKnob: root.palette.paper

        // the volume and brightness sliders
        readonly property color slider: root.palette.slate
        readonly property color sliderFill: root.palette.mint
        readonly property color sliderKnob: root.palette.paper
    }

    // ── 2d. the battery gauge ────────────────────────────────────────────────
    readonly property QtObject battery: QtObject {
        // The fill colour is interpolated along these stops, so the gauge slides
        // green → yellow → orange → red as it drains. Stops must be in order.
        readonly property var ramp: [
            { level: 0.00, color: root.palette.coral },
            { level: 0.15, color: root.palette.coral },
            { level: 0.35, color: root.palette.amber },
            { level: 0.60, color: root.palette.lemon },
            { level: 0.85, color: root.palette.leaf }
        ]

        readonly property color outline: root.palette.haze
        readonly property color body: "transparent"       // the not-yet-drained part
        readonly property color text: root.palette.paper  // percentage over the body
        readonly property color textOnFill: root.palette.ink // percentage over the fill
        readonly property color charging: root.palette.leaf  // the charging bolt
    }

    // ── 2e. the system monitor ───────────────────────────────────────────────
    readonly property QtObject monitor: QtObject {
        readonly property color icon: root.palette.haze
        readonly property color text: root.palette.paper

        // a reading past its threshold — both the icon and the number
        readonly property color hot: root.palette.coral
    }

    // ── 2f. the desktop ──────────────────────────────────────────────────────
    readonly property QtObject desktop: QtObject {
        // what replaces the wallpaper while focus mode is on
        readonly property color focus: root.palette.black
    }

    // ── 2g. the session menu ─────────────────────────────────────────────────
    readonly property QtObject menu: QtObject {
        // the dim laid over the desktop behind the menu
        readonly property color scrim: root.palette.night
        readonly property real scrimOpacity: 0.55

        // the card holding the grid
        readonly property color card: root.palette.eggplant
        readonly property color cardBorder: root.palette.indigo

        // a tile at rest
        readonly property color tile: root.palette.plum
        readonly property color tileText: root.palette.paper
        readonly property color tileBorder: root.palette.indigo

        // hovered by the mouse
        readonly property color tileHover: root.palette.mint
        readonly property color tileHoverText: root.palette.ink
        readonly property color tileHoverBorder: "transparent"

        // pressed, or picked with the keyboard
        readonly property color tileSelected: root.palette.butter
        readonly property color tileSelectedText: root.palette.ink
        readonly property color tileSelectedBorder: root.palette.butter

        // destructive actions (Shutdown), when not hovered or selected
        readonly property color tileDanger: root.palette.coral
        readonly property color tileDangerText: root.palette.ink

        // the 1..6 shortcut pill, drawn in the tile's own text colour
        readonly property real badgeOpacity: 0.85
    }

    // Same colour, different opacity. Handy for scrims and subtle fills.
    function withAlpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Blend two colours, `t` running 0 (all `a`) to 1 (all `b`).
    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t,
                       a.a + (b.a - a.a) * t);
    }
}
