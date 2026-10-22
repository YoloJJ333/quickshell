// Date and time readout.
//
// SystemClock ticks in-process and wakes only as often as `precision` needs,
// which is cheaper and steadier than re-running `date` on a Timer.

import QtQuick
import Quickshell
import qs.Config

Text {
    id: root

    // strftime-ish format string, see Qt.formatDateTime
    property string format: "ddd d MMM  hh:mm:ss"

    text: Qt.formatDateTime(clock.date, root.format)
    color: Colors.bar.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeBody * Theme.scale

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
