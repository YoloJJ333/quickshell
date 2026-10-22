pragma Singleton

// Tabler-style icon outlines, as SVG path data drawn on a 24x24 grid.
// Add new icons here and render them with IconSvg { path: Icons.whatever }.

import Quickshell

Singleton {
    id: root

    // ── session ──────────────────────────────────────────────────────────────
    readonly property string lock: "M5 13a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z M11 16a1 1 0 1 0 2 0a1 1 0 1 0-2 0 M8 11V7a4 4 0 1 1 8 0v4"
    readonly property string logout: "M14 8V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2-2v-2 M9 12h12 M18 9l3 3l-3 3"
    readonly property string pause: "M6 6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1z M14 6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1z"
    readonly property string zzz: "M4 12h6l-6 8h6 M14 4h6l-6 8h6"
    readonly property string power: "M7 6a7.75 7.75 0 1 0 10 0 M12 4v8"
    readonly property string refresh: "M20 11a8.1 8.1 0 0 0-15.5-2m-.5-4v4h4 M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4"
    readonly property string focus: "M12 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0-2 0 M12 12m-7 0a7 7 0 1 0 14 0a7 7 0 1 0-14 0 M12 3v2 M3 12h2 M12 19v2 M19 12h2"
    readonly property string coffee:"M4 10h12v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5z M16 12h1.5a2.5 2.5 0 0 1 0 5H16 M8 3a2 2 0 0 0 0 3 M12 3a2 2 0 0 0 0 3"

    // ── wi-fi ────────────────────────────────────────────────────────────────
    // Four arcs of the same fan, so `wifiBars[n]` is the icon for n bars of
    // signal. WifiService.bars produces the index.
    readonly property string wifi0: "M12 18h.01"
    readonly property string wifi1: "M12 18h.01 M9.17 15.17a4 4 0 0 1 5.66 0"
    readonly property string wifi2: "M12 18h.01 M9.17 15.17a4 4 0 0 1 5.66 0 M6.34 12.34a8 8 0 0 1 11.32 0"
    readonly property string wifi3: "M12 18h.01 M9.17 15.17a4 4 0 0 1 5.66 0 M6.34 12.34a8 8 0 0 1 11.32 0 M3.51 9.51a12 12 0 0 1 16.98 0"
    readonly property var wifiBars: [root.wifi0, root.wifi1, root.wifi2, root.wifi3]
    readonly property string wifiOff: "M12 18h.01 M3 3l18 18 M9.17 15.17a4 4 0 0 1 4.24-1.03"

    // ── bluetooth ────────────────────────────────────────────────────────────
    readonly property string bluetooth: "M7 7l10 10l-5 5V2l5 5L7 17"
    readonly property string bluetoothOn: "M7 7l10 10l-5 5V2l5 5L7 17 M2 12h2 M20 12h2"
    readonly property string bluetoothOff: "M7 7l10 10l-5 5v-7 M3 3l18 18 M12 8V2l5 5l-2 2"

    // ── battery ──────────────────────────────────────────────────────────────
    readonly property string bolt: "M13 3v7h6l-8 11v-7H5z"

    // ── sliders ──────────────────────────────────────────────────────────────
    readonly property string volume: "M6 15H4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1h2l3.5-4.5a.8.8 0 0 1 1.5.5v13a.8.8 0 0 1-1.5.5z M15 8a5 5 0 0 1 0 8 M17.7 5a9 9 0 0 1 0 14"
    readonly property string volumeLow: "M6 15H4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1h2l3.5-4.5a.8.8 0 0 1 1.5.5v13a.8.8 0 0 1-1.5.5z M15 8a5 5 0 0 1 0 8"
    readonly property string volumeMute: "M6 15H4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1h2l3.5-4.5a.8.8 0 0 1 1.5.5v13a.8.8 0 0 1-1.5.5z M16 10l4 4 M20 10l-4 4"
    readonly property string brightness: "M12 12m-4 0a4 4 0 1 0 8 0a4 4 0 1 0-8 0 M12 3v2 M12 19v2 M3 12h2 M19 12h2 M5.6 5.6l1.4 1.4 M17 17l1.4 1.4 M5.6 18.4l1.4-1.4 M17 7l1.4-1.4"

    // ── tray and panels ──────────────────────────────────────────────────────
    readonly property string dots: "M5 12h.01 M12 12h.01 M19 12h.01"
    readonly property string chevronDown: "M6 9l6 6l6-6"
    readonly property string sliders: "M14 6m-2 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0 M4 6h8 M16 6h4 M8 12m-2 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0 M4 12h2 M10 12h10 M17 18m-2 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0 M4 18h11 M19 18h1"
    readonly property string pin: "M9 4v6l-2 4v2h10v-2l-2-4V4 M12 16v5 M8 4h8"
    readonly property string pinOff: "M9 4v6l-2 4v2h8 M12 16v5 M8 4h8 M3 3l18 18"
    readonly property string menu: "M4 6h16 M4 12h16 M4 18h16"
    readonly property string check: "M5 12l5 5l9-9"
    readonly property string close: "M18 6L6 18 M6 6l12 12"
    readonly property string trash: "M4 7h16 M10 11v6 M14 11v6 M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2l1-12 M9 7V4h6v3"

    // ── system monitor ───────────────────────────────────────────────────────
    readonly property string cpu: "M6 5h12a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z M9 9h6v6H9z M3 10h2 M3 14h2 M10 3v2 M14 3v2 M21 10h-2 M21 14h-2 M10 19v2 M14 19v2"
    readonly property string thermometer: "M10 13.5a4 4 0 1 0 4 0V5a2 2 0 0 0-4 0z M10 9h4"
    readonly property string memory: "M4 7h16a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z M8 10v3 M12 10v3 M16 10v3 M6 16v2 M10 16v2 M14 16v2 M18 16v2"
    readonly property string storage: "M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0 M4 6v6a8 3 0 0 0 16 0V6 M4 12v6a8 3 0 0 0 16 0v-6"
}
