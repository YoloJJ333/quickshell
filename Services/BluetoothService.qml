pragma Singleton

// Bluetooth, through Quickshell's BlueZ binding — except for pairing, which
// goes through bluetoothctl. See "pairing" below for why.
//
// Devices come in two groups, which is how the panel lays them out:
//   `paired`  — remembered by BlueZ, connectable with one click
//   `nearby`  — seen by the current scan, pairing on first click
//
// BlueZ's "trusted" flag is what makes a device reconnect by itself when it
// comes back in range, so that is what the panel's autoconnect switch sets.
//
// As with Wi-Fi, discovery is only running while the panel is on screen.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root

    // Set by the panel while it is showing the device list.
    property bool scanning: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.available && root.adapter.enabled

    readonly property var devices: root.available ? root.adapter.devices.values : []

    // Remembered devices, connected ones first, then alphabetically.
    readonly property var paired: [...root.devices.filter(d => root.isPaired(d))]
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    // Anything else the scan has turned up, newest at the top, minus the
    // devices that broadcast no name — BlueZ calls those after their address,
    // and a list of bare MAC addresses is noise nobody can act on.
    readonly property var nearby: {
        // Read up front so this always re-sorts when the order changes, even
        // when the list is too short for the comparator to have run.
        const order = root.seen;
        return [...root.devices.filter(d => !root.isPaired(d) && root.hasName(d))]
            .sort((a, b) => order.indexOf(b.address) - order.indexOf(a.address));
    }

    // Every address in the order it turned up, oldest first — what "newest at
    // the top" is measured against. Rebuilt whenever the list changes: a device
    // BlueZ has since dropped is forgotten, so one that goes away and comes
    // back counts as new again and goes back to the top.
    property var seen: []

    function refreshSeen(): void {
        const present = root.devices.map(d => d.address);
        const kept = root.seen.filter(address => present.includes(address));
        const fresh = present.filter(address => !kept.includes(address));
        root.seen = [...kept, ...fresh];
    }

    onDevicesChanged: root.refreshSeen()
    Component.onCompleted: root.refreshSeen()

    readonly property var connectedDevices: root.devices.filter(d => d.connected)
    readonly property bool connected: root.connectedDevices.length > 0

    function isPaired(device: var): bool {
        return device.paired || device.bonded;
    }

    // BlueZ names a nameless device after its address, give or take the
    // separators, so that is what "no name" looks like from here.
    function hasName(device: var): bool {
        const plain = s => s.replace(/[-:]/g, "").toLowerCase();
        return !!device.name && plain(device.name) !== plain(device.address);
    }

    function find(address: string): var {
        return root.devices.find(d => d.address === address) ?? null;
    }

    // What clicking the body of a device row does, which depends on how far
    // along that device already is.
    function activate(device: var): void {
        if (device.connected)
            device.disconnect();
        else if (root.isPaired(device))
            device.connect();
        else
            root.pair(device);
    }

    function setAutoconnect(device: var, on: bool): void {
        device.trusted = on;
    }

    function forget(device: var): void {
        device.forget();
    }

    function setEnabled(on: bool): void {
        if (root.available)
            root.adapter.enabled = on;
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    // The adapter arrives a moment after startup, so this has to be a binding
    // rather than something set once — `when` re-applies it when it appears.
    Binding {
        target: root.adapter
        property: "discovering"
        value: root.scanning && root.enabled
        when: root.available
    }

    // ── pairing ──────────────────────────────────────────────────────────────
    // Pairing needs an *agent*: something registered with BlueZ that it can
    // ask "does 123456 match what the device shows?" or "what is its PIN?".
    // Quickshell's binding does not register one, so a pair request from it
    // fails with "Authentication Failed" for any device that asks a question —
    // bluetoothd logs "No agent available for request type 2". bluetoothctl
    // registers an agent the moment it starts, which is why pairing by hand in
    // a terminal works.
    //
    // So pairing is done by running bluetoothctl, telling it to pair over its
    // stdin, and reading its questions back off its stdout. The prompts are
    // readline prompts with no newline after them, hence the chunk-at-a-time
    // parser rather than a line one. It exits when the pairing does; nothing is
    // left running between pairings.
    //
    //   pairingAddress  which device, "" when nothing is going on
    //   pairingStage    starting  — bluetoothctl is coming up
    //                   pairing   — asked, waiting to hear back
    //                   confirm   — "does `pairingPasskey` match?": yes or no
    //                   display   — type `pairingPasskey` on the device
    //                   enter     — type the device's PIN/passkey here
    //                   failed    — see `pairingError`
    property string pairingAddress: ""
    property string pairingStage: ""
    property string pairingPasskey: ""
    property string pairingError: ""

    readonly property bool pairingActive: root.pairingAddress !== ""
                                       && root.pairingStage !== "failed"

    // Stages that are waiting on the person.
    readonly property bool pairingAwaitsAnswer: root.pairingStage === "confirm"
    readonly property bool pairingAwaitsInput: root.pairingStage === "enter"

    function pair(device: var): void {
        // One at a time — and not while the last one's bluetoothctl is still
        // on its way out, or this pairing would be pinned to a process that
        // is about to exit.
        if (root.pairingActive || pairer.running)
            return;

        root.pairingAddress = device.address;
        root.pairingStage = "starting";
        root.pairingPasskey = "";
        root.pairingError = "";
        pairer.buffer = "";
        pairer.running = true;
        watchdog.restart();
    }

    // The yes/no stages.
    function answerPairing(yes: bool): void {
        if (root.pairingAwaitsAnswer) {
            pairer.write(yes ? "yes\n" : "no\n");
            root.pairingStage = "pairing";
        }
    }

    // The type-it-in stage.
    function submitPairingInput(text: string): void {
        if (root.pairingAwaitsInput) {
            pairer.write(`${text.trim()}\n`);
            root.pairingStage = "pairing";
        }
    }

    // Whatever stage it is at, back out of it. A blank line is how a PIN prompt
    // is refused; "no" for a yes/no one; otherwise ask BlueZ to stop.
    function cancelPairing(): void {
        if (!pairer.running) {
            root.clearPairing();
            return;
        }

        if (root.pairingAwaitsAnswer)
            pairer.write("no\n");
        else if (root.pairingAwaitsInput)
            pairer.write("\n");
        else
            pairer.write(`cancel-pairing ${root.pairingAddress}\n`);

        pairer.write("quit\n");

        // Backing out on purpose is not a failure, so nothing is left on the
        // row — and with no address, whatever bluetoothctl says on its way
        // out is ignored.
        root.pairingAddress = "";
        root.pairingStage = "";
        root.pairingPasskey = "";
    }

    // Forget a failure, e.g. when the panel closes.
    function clearPairing(): void {
        if (!pairer.running) {
            root.pairingAddress = "";
            root.pairingStage = "";
            root.pairingPasskey = "";
        }
    }

    function failPairing(reason: string): void {
        root.pairingError = reason;
        root.pairingStage = "failed";
        if (pairer.running)
            pairer.write("quit\n");
    }

    // BlueZ's error names, in plainer words.
    readonly property var pairingErrors: ({
        "AuthenticationFailed": "Authentication failed",
        "AuthenticationCanceled": "Cancelled",
        "AuthenticationRejected": "Rejected by the device",
        "AuthenticationTimeout": "Timed out",
        "ConnectionAttemptFailed": "Could not connect",
        "AlreadyExists": "Already paired",
        "InProgress": "Already pairing"
    })

    function describePairingError(raw: string): string {
        const name = raw.trim().split(".").pop();
        return root.pairingErrors[name] ?? name.replace(/([a-z])([A-Z])/g, "$1 $2");
    }

    // Everything bluetoothctl says, one chunk at a time. Whole lines are
    // handled and dropped; what is left over is checked for a prompt, and
    // otherwise kept for the next chunk to complete.
    function readPairer(chunk: string): void {
        // Nothing to attach it to: the pairing finished or was cancelled and
        // this is bluetoothctl winding down.
        if (root.pairingAddress === "")
            return;

        // Colour codes, cursor movement, and the carriage returns readline
        // uses to redraw its prompt.
        pairer.buffer += chunk.replace(/\x1b\[[0-9;?]*[ -\/]*[@-~]/g, "").replace(/\r/g, "");

        const lines = pairer.buffer.split("\n");
        const tail = lines.pop();
        for (const line of lines)
            root.handlePairerLine(line);

        pairer.buffer = root.handlePairerPrompt(tail) ? "" : tail;
    }

    function handlePairerLine(line: string): void {
        let found;

        if (line.includes("Agent registered")) {
            // Now BlueZ has someone to ask, so now is the time to ask BlueZ.
            pairer.write(`pair ${root.pairingAddress}\n`);
            root.pairingStage = "pairing";
        } else if (line.includes("Pairing successful")) {
            root.pairingSucceeded();
        } else if ((found = line.match(/Failed to pair:?\s*(\S*)/))) {
            root.failPairing(root.describePairingError(found[1] || "Failed"));
        } else if (line.includes("not available")) {
            root.failPairing("Device not found");
        } else if (line.includes("Failed to register agent")) {
            root.failPairing("No pairing agent");
        } else if ((found = line.match(/Passkey:\s*(\d{6})/))) {
            // The device has a keypad and no screen: this end shows the number.
            root.pairingPasskey = found[1];
            root.pairingStage = "display";
        }
    }

    // Returns whether `text` was a prompt, i.e. bluetoothctl is now waiting
    // for a line on stdin.
    function handlePairerPrompt(text: string): bool {
        let found;

        if ((found = text.match(/Confirm passkey (\d{6}) \(yes\/no\):/))) {
            root.pairingPasskey = found[1];
            root.pairingStage = "confirm";
            return true;
        }

        if (/Authorize service .* \(yes\/no\):/.test(text)) {
            // The device asking whether it may use a profile, mid-pairing. It
            // was just chosen on purpose, so of course.
            pairer.write("yes\n");
            return true;
        }

        if (/Enter PIN code:|Enter passkey \(number in 0-999999\):/.test(text)) {
            root.pairingPasskey = "";
            root.pairingStage = "enter";
            return true;
        }

        return false;
    }

    // Paired, so connect too, and trust it: a device chosen on purpose is one
    // to let back in by itself. The autoconnect switch on its row turns that
    // off again.
    function pairingSucceeded(): void {
        const device = root.find(root.pairingAddress);
        if (device !== null) {
            device.trusted = true;
            device.connect();
        }

        root.pairingAddress = "";
        root.pairingStage = "";
        root.pairingPasskey = "";
        pairer.write("quit\n");
    }

    Process {
        id: pairer

        property string buffer: ""

        command: ["bluetoothctl"]
        stdinEnabled: true

        // Empty marker: every chunk as it arrives, rather than whole lines,
        // because a prompt is not a whole line.
        stdout: SplitParser {
            splitMarker: ""
            onRead: chunk => root.readPairer(chunk)
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: chunk => root.readPairer(chunk)
        }

        onExited: (code, status) => {
            watchdog.stop();

            // Gone without saying either way — killed, or crashed.
            if (root.pairingActive)
                root.failPairing("Stopped");
        }
    }

    // Long enough for a person to find the device's screen and read a number
    // off it; well short of forever.
    Timer {
        id: watchdog

        interval: 90000
        onTriggered: {
            if (root.pairingActive)
                root.failPairing("Timed out");
        }
    }
}
