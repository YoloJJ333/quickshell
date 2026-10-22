// A small text field that lives at the right-hand end of a PopupRow, the
// height of a ChipButton — for the one thing a panel ever asks you to type,
// a Bluetooth PIN. Enter submits; it takes focus by itself when it appears.

import QtQuick
import qs.Config

Rectangle {
    id: root

    property string placeholder: ""
    property bool numeric: false

    signal accepted(string text)

    implicitWidth: 72 * Theme.scale
    implicitHeight: Theme.chipSize * Theme.scale
    radius: Theme.radiusSm * Theme.scale
    color: Colors.popup.chip
    border.width: Theme.borderWidth
    border.color: input.activeFocus ? Colors.popup.chipHover : Colors.popup.border

    Behavior on border.color {
        ColorAnimation { duration: Theme.animFast }
    }

    onVisibleChanged: {
        if (root.visible)
            input.forceActiveFocus();
        else
            input.clear();
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: Theme.spaceSm * Theme.scale
        anchors.rightMargin: Theme.spaceSm * Theme.scale
        verticalAlignment: TextInput.AlignVCenter
        clip: true

        color: Colors.popup.rowText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm * Theme.scale
        inputMethodHints: root.numeric ? Qt.ImhDigitsOnly : Qt.ImhNone

        onAccepted: {
            if (input.text.trim() !== "")
                root.accepted(input.text);
        }
    }

    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Colors.popup.chipText
        font: input.font
    }
}
