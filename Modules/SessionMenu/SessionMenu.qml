// Fullscreen overlay holding the session action grid.
//
// It is created once when the shell starts and simply shows/hides itself as
// SessionService.opened changes, so opening it is instant no matter what
// triggered it (bar button, IPC call from a keybind, ...).
//
// Keys: 1-6 fire an action, arrows/hjkl move, Enter confirms, Escape dismisses.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Services
import qs.Modules.SessionMenu

PanelWindow {
    id: root

    property int columns: 3        // 6 actions / 3 columns = 2 rows
    property bool showBadges: true // the 1..6 shortcut pills
    property int selected: -1      // keyboard cursor; -1 = nothing focused

    // Everything in the menu is sized off this. Change Theme.menuScale to
    // resize the menu alone, or Theme.scale to resize the whole shell with it.
    readonly property real uiScale: Theme.scale * Theme.menuScale

    visible: SessionService.opened
    color: "transparent"

    // cover the whole screen and let windows underneath keep their space
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-session"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) {
        root.selected = -1;
        body.forceActiveFocus();
    }

    // Move the keyboard cursor by `delta` tiles, wrapping around the ends.
    function move(delta: int): void {
        const n = SessionService.actions.length;
        root.selected = root.selected < 0
            ? (delta > 0 ? 0 : n - 1)
            : ((root.selected + delta) % n + n) % n;
    }

    Item {
        id: body
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                SessionService.close();
                event.accepted = true;
                return;
            }
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                SessionService.activate(event.key - Qt.Key_1);
                event.accepted = true;
                return;
            }
            switch (event.key) {
            case Qt.Key_Left:  case Qt.Key_H: root.move(-1); break;
            case Qt.Key_Right: case Qt.Key_L: root.move(1); break;
            case Qt.Key_Up:    case Qt.Key_K: root.move(-root.columns); break;
            case Qt.Key_Down:  case Qt.Key_J: root.move(root.columns); break;
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                SessionService.activate(root.selected); break;
            default: return;
            }
            event.accepted = true;
        }

        // scrim
        Rectangle {
            anchors.fill: parent
            color: Colors.withAlpha(Colors.menu.scrim, Colors.menu.scrimOpacity)
            MouseArea {
                anchors.fill: parent
                onClicked: SessionService.close()
            }
        }

        // panel
        Rectangle {
            id: card
            anchors.centerIn: parent
            implicitWidth: grid.implicitWidth + 2 * Theme.spaceLg * root.uiScale
            implicitHeight: grid.implicitHeight + 2 * Theme.spaceLg * root.uiScale
            radius: Theme.radiusXl * root.uiScale
            color: Colors.menu.card
            border.width: Theme.borderWidth
            border.color: Colors.menu.cardBorder

            opacity: SessionService.opened ? 1 : 0
            scale: SessionService.opened ? 1 : 0.97
            Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent } // swallow clicks inside the panel

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: root.columns
                spacing: Theme.spaceMd * root.uiScale

                Repeater {
                    model: SessionService.actions

                    SessionTile {
                        active: index === root.selected
                        showBadge: root.showBadges
                        uiScale: root.uiScale
                        onActivated: SessionService.activate(index)
                        onHovered: root.selected = -1
                    }
                }
            }
        }
    }
}
