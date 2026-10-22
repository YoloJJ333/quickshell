// A small caps label dividing a panel's list into groups ("SAVED", "NEARBY").
// `hint` labels whatever sits at the right-hand end of the rows below it.

import QtQuick
import qs.Config

Item {
    id: root

    property string text: ""
    property string hint: ""

    implicitHeight: label.implicitHeight + 2 * Theme.spaceSm * Theme.scale

    Text {
        id: label

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spaceXs * Theme.scale
        text: root.text.toUpperCase()
        color: Colors.popup.sectionLabel
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs * Theme.scale
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8 * Theme.scale
    }

    Text {
        anchors.right: parent.right
        anchors.baseline: label.baseline
        visible: root.hint !== ""
        text: root.hint.toUpperCase()
        color: Colors.popup.sectionLabel
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs * Theme.scale
        font.letterSpacing: 0.8 * Theme.scale
    }
}
