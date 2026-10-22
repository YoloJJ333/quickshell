pragma Singleton

// Sizes, spacing and timings for the whole shell. Colours live next door in
// Colors.qml.
//
// Import it anywhere with `import qs.Config` and use it as `Theme.spaceMd`.
// Because it is a singleton there is exactly one instance for the whole shell,
// so changing a value here resizes every widget at once.

import Quickshell
import QtQuick

Singleton {
    id: root

    // ── scale ────────────────────────────────────────────────────────────────
    // Pixel sizes below are multiplied by `scale`, so the whole shell can be
    // resized at once.
    property real scale: 1.0

    // Extra factor on top of `scale`, applied to the session menu only.
    // Raise it to make the menu bigger without touching the bar.
    property real menuScale: 1.50

    // ── spacing ──────────────────────────────────────────────────────────────
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16

    // ── corners and borders ──────────────────────────────────────────────────
    readonly property int radiusSm: 3
    readonly property int radiusMd: 6
    readonly property int radiusLg: 9
    readonly property int radiusXl: 12
    readonly property int borderWidth: 1

    // ── the bar ──────────────────────────────────────────────────────────────
    readonly property int barHeight: 30
    readonly property int barButtonSize: 24 // every control in the bar is this tall
    readonly property int iconSize: 17      // glyph inside a bar button
    readonly property int trayIconSize: 16  // an application's own tray icon

    // Space either side of the contents of a bar button that carries text. An
    // icon-only button ignores this and stays square at barButtonSize, so this
    // is the knob for how wide the volume and keyboard readouts are.
    readonly property int barButtonPadding: 5

    // The default gap between two things in the bar.
    readonly property int barSpacing: 4

    // A wider gap, used once in the bar to hold the status readouts apart from
    // the buttons that open a panel. Turn it up to push Wi-Fi, Bluetooth and
    // volume further right, away from the battery.
    readonly property int barGroupSpacing: 10

    // The gap inside that group — between Wi-Fi, Bluetooth and volume only.
    // Everything else in the bar, including volume to the control centre, keeps
    // barSpacing, so this tightens the three of them without moving the rest.
    readonly property int connectivitySpacing: 1

    // Room either side of the battery gauge. Raising one and lowering the other
    // by the same amount slides the gauge along without resizing anything, so
    // these are the knobs for where it sits rather than only how much air it
    // gets. The left one is skipped while charging, because the bolt appears in
    // that space and would otherwise push the gauge over.
    readonly property int batteryPaddingLeft: 5
    readonly property int batteryPaddingRight: 0

    // The system monitor: the gap between two readouts, and the gap between a
    // readout's icon and its number.
    readonly property int monitorSpacing: 4
    readonly property int monitorGap: 2

    // One workspace dot, and the gap between two of them. Deliberately smaller
    // than barButtonSize. Their sum is the pitch of the row, so trading one
    // against the other resizes the dots without moving any of them.
    readonly property int workspaceSize: 18
    readonly property int workspaceSpacing: 2

    // The battery gauge, excluding its little terminal nub on the right.
    // This is the knob to turn if the gauge looks too long or too stubby — the
    // percentage inside it is centred, so it follows along.
    readonly property int batteryWidth: 28
    readonly property int batteryHeight: 16

    // ── the panels that drop out of the bar ──────────────────────────────────
    readonly property int popupWidth: 320
    readonly property int popupMaxHeight: 420
    readonly property int popupGap: 6       // between the bar and the panel
    readonly property int rowHeight: 40     // one entry in a panel list
    readonly property int chipSize: 24      // a small square button inside a row
    readonly property int switchWidth: 34
    readonly property int switchHeight: 18
    readonly property int sliderHeight: 6   // the groove
    readonly property int sliderKnob: 14

    // ── tooltips ─────────────────────────────────────────────────────────────
    readonly property int tooltipDelay: 350 // ms of hovering before one appears

    // ── the session menu ─────────────────────────────────────────────────────
    // one tile, before menuScale is applied
    readonly property int tileWidth: 152
    readonly property int tileHeight: 112
    readonly property int glyphSize: 30

    // ── animation ────────────────────────────────────────────────────────────
    readonly property int animFast: 100
    readonly property int animNormal: 200
    readonly property int animSlow: 400     // focus mode fading the wallpaper out

    // A window title too long for the bar: how fast it scrolls (pixels a
    // second) and how long it rests at each end before turning round (ms).
    readonly property int titleScrollSpeed: 25
    readonly property int titleScrollPause: 3000

    // ── type ─────────────────────────────────────────────────────────────────
    readonly property string fontFamily: Qt.application.font.family
    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 12
    readonly property int fontSizeBody: 14
    readonly property int fontSizeLg: 15
}
