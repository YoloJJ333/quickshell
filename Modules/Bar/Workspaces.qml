// The row of workspace dots at the left-hand end of the bar: the numbered
// workspaces, then the special ones, in the order they are listed in
// Services/WorkspaceService.qml.

import QtQuick
import qs.Config
import qs.Services

Row {
    id: root

    spacing: Theme.workspaceSpacing * Theme.scale

    Repeater {
        model: WorkspaceService.numbered

        WorkspaceButton {
            required property int index

            workspaceId: index + 1
        }
    }

    // A little air between the numbered ones and the special ones. An empty
    // Item has no implicit size of its own, so a spacer sets `width` directly.
    Item {
        width: Theme.spaceSm * Theme.scale
        height: Theme.workspaceSize * Theme.scale
    }

    Repeater {
        model: WorkspaceService.specials

        WorkspaceButton {
            required property var modelData

            special: modelData
        }
    }
}
