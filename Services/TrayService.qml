pragma Singleton

// The system tray: which applications are on the bar, in what order, and which
// are tucked away in the drawer.
//
// Both of those choices are remembered across restarts in a small JSON file
// next to the shell's other state:
//
//   hidden — ids of the applications that live in the drawer
//   order  — ids in the order they appear on the bar, left to right
//
// Items identify themselves with a stable id ("ibus-ui-gtk3", "tailscale", ...),
// which is what gets written to disk.
//
// An application nobody has arranged yet is not in `order` at all, and goes to
// the left-hand end — so the tray fills right to left, oldest at the right.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property var items: SystemTray.items.values

    // Ids of the items that live in the drawer. Anything not listed is on the
    // bar, so a newly started application shows up there by itself.
    property var hiddenIds: Array.from(trayState.hidden)

    // Ids in bar order, left to right. Only the ones that have been dragged
    // somewhere are listed; the rest are placed by the rule above.
    property var orderIds: Array.from(trayState.order)

    // On the bar, in the order they are drawn.
    readonly property var pinned: {
        const visible = root.items.filter(item => !root.isHidden(item));

        const arranged = root.orderIds
            .map(id => visible.find(item => item.id === id))
            .filter(item => item !== undefined);

        // Newest first, so a new icon appears at the left-hand end.
        const unarranged = visible
            .filter(item => !root.orderIds.includes(item.id))
            .reverse();

        return [...unarranged, ...arranged];
    }

    readonly property var hidden: root.items.filter(item => root.isHidden(item))

    // A tray title is whatever the application felt like sending — IBus, for
    // one, packs a paragraph of help into it — so take the first line, and fall
    // back to the id for the applications that send nothing at all.
    function displayName(item: var): string {
        const title = item.title.split("\n")[0].trim();
        return title !== "" ? title : item.id;
    }

    function isHidden(item: var): bool {
        return root.hiddenIds.includes(item.id);
    }

    function hide(item: var): void {
        if (!root.isHidden(item))
            root.setHidden([...root.hiddenIds, item.id]);
    }

    function pin(item: var): void {
        root.setHidden(root.hiddenIds.filter(id => id !== item.id));
    }

    function toggle(item: var): void {
        if (root.isHidden(item))
            root.pin(item);
        else
            root.hide(item);
    }

    // Put `item` where `position` currently is, counting from the left.
    //
    // The whole of the current arrangement is written out, not just the item
    // that moved: that pins down where everything else is sitting too, so the
    // icons that were only placed by the default rule stay put from now on.
    function move(item: var, position: int): void {
        const ids = root.pinned.map(entry => entry.id);
        const from = ids.indexOf(item.id);
        if (from === -1 || position < 0)
            return;

        ids.splice(from, 1);
        ids.splice(Math.min(position, ids.length), 0, item.id);
        root.setOrder(ids);
    }

    // The lists are held here as well as in the file because writing to the
    // adapter does not take effect until a later tick — dragging two icons in
    // quick succession would otherwise have the second one work from the
    // arrangement before the first. These two properties start out bound to
    // whatever was loaded, and assigning to them hands ownership over.
    function setHidden(ids: var): void {
        root.hiddenIds = ids;
        trayState.hidden = ids;
        save.restart();
    }

    function setOrder(ids: var): void {
        root.orderIds = ids;
        trayState.order = ids;
        save.restart();
    }

    // Writing on `adapterUpdated` alone loses the last change of a burst, so
    // the file is also written once the arranging has stopped.
    Timer {
        id: save

        interval: 250
        onTriggered: stateFile.writeAdapter()
    }

    FileView {
        id: stateFile

        path: Quickshell.statePath("tray.json")
        printErrors: false // the file does not exist until something is moved

        onAdapterUpdated: writeAdapter()
        Component.onCompleted: reload()

        // Deliberately not watching the file for changes. The shell is its only
        // writer, and reloading on every write races the next one: two moves in
        // quick succession would see the reload of the first arrive after the
        // second was assigned, and quietly undo it.

        adapter: JsonAdapter {
            id: trayState

            property list<string> hidden: []
            property list<string> order: []
        }
    }
}
