pragma Singleton

// Wi-Fi, through Quickshell's NetworkManager binding.
//
// This is the same NetworkManager that `nmcli` drives, just over D-Bus instead
// of a subprocess, so the lists update live and connecting is a single call.
// The one thing NetworkManager exposes only to a device is "disconnect", which
// has no binding yet, so that one goes out through nmcli.
//
// Important: NetworkManager only keeps the list of nearby access points fresh
// while something is scanning. The panel sets `scanning` true while it is on
// screen; leave it false the rest of the time so the radio stays idle.

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // Set by the panel while it is showing the network list.
    property bool scanning: false

    // The first Wi-Fi adapter. Null on a machine without one, and for the first
    // moment after startup while NetworkManager is still answering.
    readonly property var device: {
        for (const dev of Networking.devices.values)
            if (dev.type === DeviceType.Wifi)
                return dev;
        return null;
    }

    readonly property bool available: root.device !== null
    readonly property bool enabled: Networking.wifiEnabled

    readonly property var networks: root.device ? root.device.networks.values : []

    // Networks NetworkManager has a saved profile for, strongest first, then
    // everything else it can see.
    readonly property var saved: root.sortByStrength(root.networks.filter(n => n.known))
    readonly property var nearby: root.sortByStrength(root.networks.filter(n => !n.known))

    readonly property var active: root.networks.find(n => n.connected) ?? null
    readonly property bool connected: root.active !== null
    readonly property string ssid: root.connected ? root.active.name : ""
    readonly property real strength: root.connected ? root.active.signalStrength : 0

    // 0..3, which is what Icons.wifiBars is indexed by.
    readonly property int bars: root.strengthBars(root.strength)

    function strengthBars(strength: real): int {
        if (strength >= 0.75)
            return 3;
        if (strength >= 0.50)
            return 2;
        if (strength >= 0.25)
            return 1;
        return 0;
    }

    function isSecured(network: var): bool {
        return network.security !== WifiSecurityType.Open
            && network.security !== WifiSecurityType.Owe;
    }

    // The short name for a network's security, for the second line of its row.
    function securityLabel(network: var): string {
        switch (network.security) {
        case WifiSecurityType.Open:
        case WifiSecurityType.Owe:
            return "Open";
        case WifiSecurityType.Sae:
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3";
        case WifiSecurityType.Wpa2Psk:
        case WifiSecurityType.Wpa2Eap:
            return "WPA2";
        case WifiSecurityType.WpaPsk:
        case WifiSecurityType.WpaEap:
            return "WPA";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP";
        case WifiSecurityType.Leap:
            return "LEAP";
        default:
            return "";
        }
    }

    function sortByStrength(list: var): var {
        return [...list].sort((a, b) => b.signalStrength - a.signalStrength);
    }

    function connectTo(network: var): void {
        network.connect();
    }

    function disconnectActive(): void {
        if (root.device)
            Quickshell.execDetached(["nmcli", "device", "disconnect", root.device.name]);
    }

    function setEnabled(on: bool): void {
        Networking.wifiEnabled = on;
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    // The adapter arrives a moment after startup, so this has to be a binding
    // rather than something set once — `when` re-applies it when it appears.
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.scanning && root.enabled
        when: root.device !== null
    }
}
