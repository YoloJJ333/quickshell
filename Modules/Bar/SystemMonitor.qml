// The system monitor at the left-hand end of the bar: CPU, memory, storage and
// temperature, each as an icon and a number, with the detail on hover.
//
// The numbers come from Services/SystemMonitorService.qml, which is also where
// the refresh rates and the thresholds for turning a readout red live.

import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

Row {
    id: root

    spacing: Theme.monitorSpacing * Theme.scale

    MonitorReadout {
        icon: Icons.cpu
        value: SystemMonitorService.percent(SystemMonitorService.cpu)
        widest: "99%"
        hot: SystemMonitorService.cpuHot
        tooltip: "CPU"
    }

    MonitorReadout {
        icon: Icons.memory
        value: SystemMonitorService.percent(SystemMonitorService.memory)
        widest: "99%"
        hot: SystemMonitorService.memoryHot
        tooltip: SystemMonitorService.memoryDetail
    }

    MonitorReadout {
        icon: Icons.storage
        value: SystemMonitorService.percent(SystemMonitorService.storage)
        widest: "99%"
        hot: SystemMonitorService.storageHot
        tooltip: SystemMonitorService.storageDetail
    }

    // The one reading that can be missing: a Row skips what is not visible,
    // so the others close up rather than leaving a hole.
    MonitorReadout {
        visible: SystemMonitorService.temperatureAvailable
        icon: Icons.thermometer
        value: `${Math.round(SystemMonitorService.temperature)}°`
        widest: "99°"
        hot: SystemMonitorService.temperatureHot
        tooltip: SystemMonitorService.temperatureSource
    }
}
