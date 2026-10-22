pragma Singleton

// CPU load, memory, storage and temperature, for the readouts at the left-hand
// end of the bar.
//
// CPU and memory are read straight out of /proc, and the temperature out of
// /sys, every `interval`. Storage barely moves, so `df` is asked far less
// often. Each reading is a fraction 0..1 (the temperature is in °C), with a
// matching `...Hot` flag for when it is past the threshold that should make
// the readout change colour.
//
// The temperature is whichever sensor is the CPU package. hwmon numbering is
// not stable across boots, so the sensor is found by name on startup rather
// than by path.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── timing ───────────────────────────────────────────────────────────────
    readonly property int interval: 2000        // ms between /proc reads
    readonly property int storageInterval: 60000 // ms between df runs

    // ── thresholds ───────────────────────────────────────────────────────────
    // Past these a readout is drawn in Colors.monitor.hot.
    readonly property real cpuThreshold: 0.90
    readonly property real memoryThreshold: 0.90
    readonly property real storageThreshold: 0.90
    readonly property real temperatureThreshold: 80 // °C

    // ── readings ─────────────────────────────────────────────────────────────
    property real cpu: 0
    property real memory: 0
    property real storage: 0
    property real temperature: 0

    readonly property bool cpuHot: root.cpu >= root.cpuThreshold
    readonly property bool memoryHot: root.memory >= root.memoryThreshold
    readonly property bool storageHot: root.storage >= root.storageThreshold
    readonly property bool temperatureHot: root.temperature >= root.temperatureThreshold

    // For the tooltips.
    property string memoryDetail: ""      // "5.3 of 15.5 GiB"
    property string storageDetail: ""     // "294 of 376 GiB on /"
    property string temperatureSource: "" // "coretemp · Package id 0"

    // Only the temperature can be missing: not every machine has a sensor
    // that this knows how to find.
    readonly property bool temperatureAvailable: sensor.path !== ""

    function percent(fraction: real): string {
        return `${Math.round(fraction * 100)}%`;
    }

    function formatBytes(bytes: real): string {
        const gib = bytes / 1073741824;
        return gib >= 100 ? `${Math.round(gib)} GiB` : `${gib.toFixed(1)} GiB`;
    }

    // ── cpu ──────────────────────────────────────────────────────────────────
    // The first line of /proc/stat is cumulative ticks since boot, split into
    // user, nice, system, idle, iowait, irq, softirq, steal. Load is how much
    // of the time since the last look was not spent idle.
    property real lastTotal: 0
    property real lastIdle: 0

    function readCpu(): void {
        const fields = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return;

        const idle = fields[3] + fields[4];
        const total = fields.reduce((sum, ticks) => sum + ticks, 0);

        const dTotal = total - root.lastTotal;
        const dIdle = idle - root.lastIdle;
        if (root.lastTotal > 0 && dTotal > 0)
            root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));

        root.lastTotal = total;
        root.lastIdle = idle;
    }

    // ── memory ───────────────────────────────────────────────────────────────
    // "Used" is what the kernel says it could not free up on demand, which is
    // the number that matters, rather than total minus free.
    function readMemory(): void {
        const values = {};
        for (const line of meminfo.text().split("\n")) {
            const found = line.match(/^(\w+):\s+(\d+)/);
            if (found)
                values[found[1]] = Number(found[2]) * 1024;
        }

        const total = values.MemTotal ?? 0;
        const available = values.MemAvailable ?? 0;
        if (total === 0)
            return;

        root.memory = (total - available) / total;
        root.memoryDetail = `${root.formatBytes(total - available)} of ${root.formatBytes(total)}`;
    }

    // ── temperature ──────────────────────────────────────────────────────────
    function readTemperature(): void {
        const millidegrees = Number(sensor.text().trim());
        if (!isNaN(millidegrees))
            root.temperature = millidegrees / 1000;
    }

    // The finder prints the sensor's path, then its chip name, then its label
    // if it has one.
    function useSensor(output: string): void {
        const lines = output.trim().split("\n").map(line => line.trim()).filter(line => line !== "");
        if (lines.length === 0)
            return;

        sensor.path = lines[0];
        root.temperatureSource = lines.slice(1).join(" · ");
        sensor.reload();
        root.readTemperature();
    }

    // ── storage ──────────────────────────────────────────────────────────────
    // `df -P` is one line per filesystem in a fixed order: device, size, used,
    // available, use%, mount. The percentage is worked out the same way df
    // does — from used and available, rounded *up* to a whole percent — so the
    // bar never disagrees with the terminal by one.
    function readStorage(output: string): void {
        const line = output.trim().split("\n").pop() ?? "";
        const fields = line.trim().split(/\s+/);
        if (fields.length < 6)
            return;

        const used = Number(fields[2]);
        const available = Number(fields[3]);
        if (used + available === 0)
            return;

        root.storage = Math.ceil(100 * used / (used + available)) / 100;
        root.storageDetail = `${root.formatBytes(used)} of ${root.formatBytes(used + available)} on ${fields[5]}`;
    }

    // ── sources ──────────────────────────────────────────────────────────────
    // Blocking reads: these are /proc and /sys, which answer instantly, and it
    // keeps a reading and the parse that uses it on the same tick.
    FileView { id: stat;    path: "/proc/stat";    blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: sensor;  path: "";              blockLoading: true; printErrors: false }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
            root.readCpu();
            root.readMemory();

            if (root.temperatureAvailable) {
                sensor.reload();
                root.readTemperature();
            }
        }
    }

    // Prefers the CPU package sensor by chip name, then the kernel's thermal
    // zone for it. Exits at the first match, so the order is the preference.
    Process {
        running: true
        command: ["sh", "-c", `
            for d in /sys/class/hwmon/hwmon*; do
                case "$(cat "$d/name" 2>/dev/null)" in
                    coretemp|k10temp|zenpower|cpu_thermal|cpu-thermal)
                        echo "$d/temp1_input"
                        cat "$d/name"
                        cat "$d/temp1_label" 2>/dev/null
                        exit 0 ;;
                esac
            done
            for z in /sys/class/thermal/thermal_zone*; do
                case "$(cat "$z/type" 2>/dev/null)" in
                    x86_pkg_temp|cpu-thermal|cpu_thermal|soc_thermal)
                        echo "$z/temp"
                        cat "$z/type"
                        exit 0 ;;
                esac
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: root.useSensor(text)
        }
    }

    Timer {
        interval: root.storageInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }

    Process {
        id: df

        command: ["df", "-P", "-B1", "/"]

        stdout: StdioCollector {
            onStreamFinished: root.readStorage(text)
        }
    }
}
