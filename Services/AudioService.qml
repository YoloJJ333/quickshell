pragma Singleton

// The default audio output, through Pipewire.
//
// `volume` runs 0..1 and `percent` is the same number as a whole percentage.
// Both the bar's audio button and the sliders in the panels read from here, so
// they can never disagree about how loud things are.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: (root.sink?.audio ?? null) !== null

    // Each of these checks the sink itself rather than leaning on `available`.
    // When the default output changes, bindings re-run in no promised order,
    // and one that runs before `available` has caught up would otherwise read
    // `.audio` off a sink that is already gone.
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property int percent: Math.round(root.volume * 100)
    readonly property bool muted: root.sink?.audio?.muted ?? false

    readonly property string deviceName: root.sink
        ? (root.sink.description || root.sink.nickname || root.sink.name)
        : ""

    function setVolume(value: real): void {
        if (root.available)
            root.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setPercent(value: real): void {
        root.setVolume(value / 100);
    }

    function setMuted(value: bool): void {
        if (root.available)
            root.sink.audio.muted = value;
    }

    function toggleMute(): void {
        root.setMuted(!root.muted);
    }

    // Pipewire only keeps a node's properties up to date while something is
    // tracking it, and this is that something.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
