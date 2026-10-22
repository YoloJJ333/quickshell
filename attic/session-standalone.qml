// ─────────────────────────────────────────────────────────────────────────────
//  Session menu — Noctalia-styled, 3 columns x 2 rows, no arm/countdown.
//
//  Install:  mkdir -p ~/.config/quickshell/session
//            cp shell.qml ~/.config/quickshell/session/
//  Run:      qs -c session          (one-shot, like wlogout: opens, then exits)
//
//  Bind it in your compositor, e.g.
//    niri:      Mod+Shift+E { spawn "qs" "-c" "session"; }
//    Hyprland:  bind = SUPER SHIFT, E, exec, qs -c session
//
//  Daemon mode (instant open, stays resident): set startVisible and quitOnClose
//  to false, launch `qs -c session` at startup, and bind
//    qs -c session ipc call session toggle
//
//  Keys: 1-6 fire an action, arrows/hjkl move, Enter confirms, Escape dismisses.
// ─────────────────────────────────────────────────────────────────────────────

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ── behaviour ────────────────────────────────────────────────────────────
    property bool startVisible: true          // show as soon as the process starts
    property bool quitOnClose: true           // exit after acting / dismissing
    property int columns: 3                   // 6 actions / 3 columns = 2 rows
    property real uiScale: 1.0                // scale the whole panel
    property bool showBadges: true            // 1..6 shortcut pills, like Noctalia
    property bool followNoctaliaColors: true  // live-read ~/.config/noctalia/colors.json

    property bool shown: false
    property int selected: -1                 // keyboard cursor; -1 = nothing focused

    // ── Noctalia default dark palette ────────────────────────────────────────
    // Replaced at runtime by your live Noctalia palette when it is readable.
    QtObject {
        id: theme
        property color surface: "#070722"
        property color surfaceVariant: "#11112d"
        property color onSurface: "#f3edf7"
        property color outline: "#21215f"
        property color primary: "#fff59b"
        property color onPrimary: "#0e0e43"
        property color hover: "#9bfece"
        property color onHover: "#0e0e43"
        property color error: "#fd4663"
        property color onError: "#0e0e43"
        property string fontFamily: Qt.application.font.family
    }

    // Tabler icon paths, the same glyphs Noctalia maps these actions to.
    QtObject {
        id: icons
        readonly property string lock: "M5 13a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z M11 16a1 1 0 1 0 2 0a1 1 0 1 0-2 0 M8 11V7a4 4 0 1 1 8 0v4"
        readonly property string logout: "M14 8V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2-2v-2 M9 12h12 M18 9l3 3l-3 3"
        readonly property string pause: "M6 6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1z M14 6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1z"
        readonly property string zzz: "M4 12h6l-6 8h6 M14 4h6l-6 8h6"
        readonly property string power: "M7 6a7.75 7.75 0 1 0 10 0 M12 4v8"
        readonly property string refresh: "M20 11a8.1 8.1 0 0 0-15.5-2m-.5-4v4h4 M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4"
    }

    // ── actions ──────────────────────────────────────────────────────────────
    // Row-major: reorder this list to rearrange the grid.
    // Commands run through `sh -c`, so $USER etc. expand as they did in wlogout.
    readonly property var actions: [
        { label: "Lock",      cmd: "loginctl lock-session",         icon: icons.lock },
        { label: "Logout",    cmd: "loginctl terminate-user $USER", icon: icons.logout },
        { label: "Suspend",   cmd: "systemctl suspend",             icon: icons.pause },
        { label: "Hibernate", cmd: "systemctl hibernate",           icon: icons.zzz },
        { label: "Shutdown",  cmd: "systemctl poweroff",            icon: icons.power, destructive: true },
        { label: "Reboot",    cmd: "systemctl reboot",              icon: icons.refresh }
    ]

    // ── components ───────────────────────────────────────────────────────────

    // Tabler-style stroked icon, drawn on a 24x24 grid.
    component Icon: Item {
        id: ico
        property string path: ""
        property color color: "white"
        property real size: 28
        implicitWidth: size
        implicitHeight: size

        Shape {
            anchors.centerIn: parent
            width: 24
            height: 24
            scale: ico.size / 24
            preferredRendererType: Shape.CurveRenderer   // remove this line on Qt < 6.6
            ShapePath {
                strokeColor: ico.color
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: ico.path }
            }
        }
    }

    component Tile: Rectangle {
        id: tile
        required property var modelData
        required property int index

        readonly property bool destructive: modelData.destructive === true
        readonly property bool active: tile.index === root.selected

        implicitWidth: 152 * root.uiScale    // kButtonMinWidth
        implicitHeight: 112 * root.uiScale   // kActionButtonMinHeight
        radius: 9 * root.uiScale             // radiusLg
        border.width: 1                      // borderWidth

        // Noctalia's Default / Destructive button palette, state for state.
        color: (ma.pressed || tile.active) ? theme.primary
             : ma.containsMouse ? theme.hover
             : tile.destructive ? theme.error : theme.surfaceVariant
        border.color: (ma.pressed || tile.active) ? theme.primary
             : ma.containsMouse ? "transparent" : theme.outline
        property color fg: (ma.pressed || tile.active) ? theme.onPrimary
             : ma.containsMouse ? theme.onHover
             : tile.destructive ? theme.onError : theme.onSurface

        Behavior on color { ColorAnimation { duration: 100 } }        // animFast
        Behavior on border.color { ColorAnimation { duration: 100 } }
        Behavior on fg { ColorAnimation { duration: 100 } }

        Column {
            anchors.centerIn: parent
            spacing: 8 * root.uiScale                                 // spaceSm

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                path: tile.modelData.icon
                color: tile.fg
                size: 28 * root.uiScale                               // glyphSize
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.modelData.label
                color: tile.fg
                font.family: theme.fontFamily
                font.pixelSize: 15 * root.uiScale                     // fontSizeBody + 1
                font.weight: Font.Medium
            }
        }

        // shortcut pill, top-right
        Rectangle {
            visible: root.showBadges
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4 * root.uiScale                         // spaceXs
            implicitWidth: Math.max(implicitHeight, badge.implicitWidth + 8 * root.uiScale)
            implicitHeight: badge.implicitHeight + 4 * root.uiScale
            radius: 3 * root.uiScale                                  // radiusSm
            color: Qt.rgba(tile.fg.r, tile.fg.g, tile.fg.b, 0.85)

            Text {
                id: badge
                anchors.centerIn: parent
                text: tile.index + 1
                color: tile.color
                font.family: theme.fontFamily
                font.pixelSize: 11 * root.uiScale
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selected = -1
            onClicked: root.activate(tile.index)
        }
    }

    // ── live theming off Noctalia ────────────────────────────────────────────
    FileView {
        path: root.followNoctaliaColors
            ? Quickshell.env("HOME") + "/.config/noctalia/colors.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                if (c.mSurface) theme.surface = c.mSurface;
                if (c.mSurfaceVariant) theme.surfaceVariant = c.mSurfaceVariant;
                if (c.mOnSurface) theme.onSurface = c.mOnSurface;
                if (c.mOutline) theme.outline = c.mOutline;
                if (c.mPrimary) theme.primary = c.mPrimary;
                if (c.mOnPrimary) theme.onPrimary = c.mOnPrimary;
                if (c.mHover) theme.hover = c.mHover;
                if (c.mOnHover) theme.onHover = c.mOnHover;
                if (c.mError) theme.error = c.mError;
                if (c.mOnError) theme.onError = c.mOnError;
            } catch (e) { /* keep the built-in palette */ }
        }
        onLoadFailed: { /* not running Noctalia — keep the built-in palette */ }
    }

    // ── logic ────────────────────────────────────────────────────────────────
    Component.onCompleted: if (root.startVisible) root.shown = true

    // Fires the command straight away: no arming, no countdown ring.
    function activate(i) {
        if (i < 0 || i >= actions.length) return;
        Quickshell.execDetached(["sh", "-c", actions[i].cmd]);
        root.dismiss();
    }

    function dismiss() {
        root.shown = false;
        if (root.quitOnClose) exitTimer.start();
    }

    function move(delta) {
        const n = actions.length;
        root.selected = root.selected < 0
            ? (delta > 0 ? 0 : n - 1)
            : ((root.selected + delta) % n + n) % n;
    }

    Timer { id: exitTimer; interval: 120; onTriggered: Qt.quit() }

    IpcHandler {
        target: "session"
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
        function toggle(): void { root.shown = !root.shown }
    }

    // ── window ───────────────────────────────────────────────────────────────
    PanelWindow {
        id: win
        visible: root.shown
        color: "transparent"
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-session"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) { root.selected = -1; body.forceActiveFocus() }

        Item {
            id: body
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { root.dismiss(); event.accepted = true; return }
                if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                    root.activate(event.key - Qt.Key_1); event.accepted = true; return
                }
                switch (event.key) {
                case Qt.Key_Left:  case Qt.Key_H: root.move(-1); break
                case Qt.Key_Right: case Qt.Key_L: root.move(1); break
                case Qt.Key_Up:    case Qt.Key_K: root.move(-root.columns); break
                case Qt.Key_Down:  case Qt.Key_J: root.move(root.columns); break
                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                    root.activate(root.selected); break
                default: return
                }
                event.accepted = true
            }

            // scrim
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.58)
                MouseArea { anchors.fill: parent; onClicked: root.dismiss() }
            }

            // panel
            Rectangle {
                id: card
                anchors.centerIn: parent
                implicitWidth: grid.implicitWidth + 28 * root.uiScale   // panelPadding 14
                implicitHeight: grid.implicitHeight + 28 * root.uiScale
                radius: 12 * root.uiScale                               // radiusXl
                color: theme.surface
                border.width: 1
                border.color: theme.outline

                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.97
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent }   // swallow clicks inside the panel

                Grid {
                    id: grid
                    anchors.centerIn: parent
                    columns: root.columns
                    spacing: 12 * root.uiScale                          // spaceMd
                    Repeater { model: root.actions; Tile {} }
                }
            }
        }
    }
}
