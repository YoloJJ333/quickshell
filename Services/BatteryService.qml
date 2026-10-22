pragma Singleton

// The laptop battery, as the bar wants to see it.
//
// Everything comes from UPower's "display device", which is the battery the
// system considers primary. `level` runs 0..1; `percent` is the same number as
// a whole percentage, and `fillColor` is that level mapped onto the green →
// yellow → orange → red ramp defined in Config/Colors.qml.

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Config

Singleton {
    id: root

    readonly property var device: UPower.displayDevice

    // False on a desktop, or before UPower has answered — the bar hides the
    // gauge entirely rather than showing a fake full battery.
    readonly property bool available: root.device !== null
                                   && root.device.ready
                                   && root.device.isLaptopBattery
                                   && root.device.isPresent

    readonly property real level: root.available ? root.device.percentage : 0
    readonly property int percent: Math.round(root.level * 100)

    readonly property int state: root.available ? root.device.state
                                                : UPowerDeviceState.Unknown
    readonly property bool charging: root.state === UPowerDeviceState.Charging
                                  || root.state === UPowerDeviceState.PendingCharge
    readonly property bool full: root.state === UPowerDeviceState.FullyCharged

    readonly property color fillColor: root.rampColor(root.level)

    // "1h 20m left" / "45m to full" / "Full" — for a tooltip or a future panel.
    readonly property string summary: {
        if (!root.available)
            return "";
        if (root.full)
            return "Full";
        if (root.charging)
            return root.device.timeToFull > 0
                 ? root.formatSeconds(root.device.timeToFull) + " to full"
                 : "Charging";
        return root.device.timeToEmpty > 0
             ? root.formatSeconds(root.device.timeToEmpty) + " left"
             : "On battery";
    }

    // Walks the ramp in Colors.battery and blends between the two stops the
    // level falls between.
    function rampColor(level: real): color {
        const stops = Colors.battery.ramp;

        for (let i = 1; i < stops.length; i++) {
            if (level > stops[i].level)
                continue;

            const lower = stops[i - 1];
            const upper = stops[i];
            const span = upper.level - lower.level;
            const t = span > 0 ? (level - lower.level) / span : 0;
            return Colors.mix(lower.color, upper.color, Math.max(0, Math.min(1, t)));
        }

        return stops[stops.length - 1].color;
    }

    function formatSeconds(seconds: real): string {
        const total = Math.round(seconds / 60);
        const hours = Math.floor(total / 60);
        const minutes = total % 60;
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }
}
