pragma Singleton

// Screen brightness, handed off to your own script.
//
//   ~/.config/hypr/hyprland/scripts/brightness.sh {i|d|s|get} {0-110}
//
// The script owns the curve, so this service deliberately knows nothing about
// it: `level` is a plain 0-110 number that means whatever the script decides it
// means, and is not comparable to brightnessctl's percentage.
//
// The script is the source of truth rather than anything remembered here, so
// the brightness keys — or anything else that runs the script behind the
// shell's back — show up on the slider within a second of a panel being open.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int minimum: 0
    readonly property int maximum: 110

    readonly property string script: `${Quickshell.env("HOME")}/.config/hypr/hyprland/scripts/brightness.sh`

    // Set by whatever is showing a slider. The script is only asked where the
    // brightness is while someone can see the answer.
    property bool watching: false

    property int level: root.minimum

    // 0..1, for driving a slider.
    readonly property real fraction: (root.level - root.minimum) / (root.maximum - root.minimum)

    function set(value: real): void {
        root.level = root.clamp(value);
        apply.restart();
        settling.restart();
    }

    function setFraction(value: real): void {
        root.set(root.minimum + value * (root.maximum - root.minimum));
    }

    function increase(step: int): void {
        root.set(root.level + step);
    }

    function decrease(step: int): void {
        root.set(root.level - step);
    }

    function clamp(value: real): int {
        return Math.max(root.minimum, Math.min(root.maximum, Math.round(value)));
    }

    // Ask the script where the brightness actually is.
    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }

    Component.onCompleted: root.refresh()

    Process {
        id: reader

        command: [root.script, "get"]

        stdout: StdioCollector {
            // The script answers in prose — "Current Brightness: 69% (Raw:
            // 2741/96000, Gamma: 100)" — so take the number in front of the
            // percent sign and ignore the rest.
            onStreamFinished: {
                const found = text.match(/(\d+(?:\.\d+)?)\s*%/);
                if (found && !settling.running)
                    root.level = root.clamp(Number(found[1]));
            }
        }
    }

    Timer {
        id: poll

        running: root.watching
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Dragging a slider changes `level` on every pixel; this turns that into
    // one call to the script rather than a few hundred.
    Timer {
        id: apply

        interval: 40
        onTriggered: Quickshell.execDetached([root.script, "set", String(root.level)])
    }

    // A reading taken before our own change has landed would report the old
    // level and drag the slider backwards under the cursor, so readings are
    // ignored for a moment after anything set here.
    Timer {
        id: settling

        interval: 700
    }
}
