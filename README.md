# yolojj333 quickshell config

Run with `qs -c yolojj333` (add `-d` to daemonize). Quickshell watches these
files and reloads by itself when one of them changes.

## Layout

```
shell.qml                 entry point — wires modules together, nothing else
Config/
  Colors.qml              singleton: the palette + one named colour per part
  Theme.qml               singleton: spacing, radii, sizes, animation timings
  Flavor.qml              singleton: the control centre's flavour text
Widgets/
  Icons.qml               singleton: SVG path data for icons
  IconSvg.qml             draws one of those paths as a stroked icon
  TrayMenu.qml            opens an application's own tray menu
  BarTooltip.qml          the label that appears under a hovered bar item
Services/
  SessionService.qml      singleton: session menu state + the action list
  KeepAwake.qml           singleton: the idle inhibitor ("keep the device on")
  FocusMode.qml           singleton: focus mode (wallpaper → black, lock screen too)
  PopupService.qml        singleton: which panel is dropped out of the bar
  BatteryService.qml      singleton: the battery, and the colour ramp for it
  AudioService.qml        singleton: the default Pipewire output
  BrightnessService.qml   singleton: brightness, via your own script
  KeyboardService.qml     singleton: the active keyboard layout
  WorkspaceService.qml    singleton: Hyprland's workspaces
  SystemMonitorService.qml singleton: CPU, memory, storage, temperature
  WifiService.qml         singleton: Wi-Fi networks, scanning, connecting
  BluetoothService.qml    singleton: Bluetooth adapter and devices
  TrayService.qml         singleton: tray items, split into pinned and hidden
Modules/
  Bar/
    Bar.qml               the top bar (one per monitor)
    SystemMonitor.qml     CPU / memory / storage / temperature, far left
    MonitorReadout.qml    one of those: an icon and a number
    Workspaces.qml        the row of dots after it
    WindowTitle.qml       the focused window's title, between the dots and the clock
    WorkspaceButton.qml   one workspace dot
    Clock.qml             date/time readout, in the middle
    StatusArea.qml        the cluster at the right-hand end
    BarButton.qml         small square icon button
    BatteryIndicator.qml  battery outline, fill and percentage
    TrayArea.qml          tray icons + the drawer button
    TrayIcon.qml          one application's tray icon
  Popups/
    PopupLayer.qml        the surface panels are drawn on (one per monitor)
    PopupCard.qml         a panel's background, border and fade
    PopupHeader.qml       title, status line, room for a switch
    PopupList.qml         the scrolling part of a panel
    PopupSection.qml      a "SAVED" / "NEARBY" divider
    PopupRow.qml          one entry in a panel's list
    ChipButton.qml        small square button at the end of a row
    ChipInput.qml         small text field at the end of a row (Bluetooth PIN)
    ToggleSwitch.qml      on/off switch
    SliderRow.qml         full-width slider with an icon and a readout
    WifiPanel.qml         Wi-Fi networks
    BluetoothPanel.qml    Bluetooth devices
    AudioPanel.qml        output volume
    ControlCenter.qml     volume, brightness, focus mode, keep awake, session
    TrayPanel.qml         the drawer: the applications not on the bar
  Desktop/
    FocusBackdrop.qml     the black over the wallpaper in focus mode (one per monitor)
  SessionMenu/
    SessionMenu.qml       fullscreen overlay + keyboard handling
    SessionTile.qml       one button in the grid
attic/
  session-standalone.qml  the original one-file version, kept for reference
```

Every folder has a `qmldir` naming it as a module (`module qs.Config`, ...),
which is what makes `import qs.Config` work from anywhere in the config.

Singletons (`pragma Singleton` + a `singleton` line in `qmldir`) exist once for
the whole shell, so `Theme.scale` and `WifiService.connected` mean the same
thing everywhere.

## The bar

The system monitor, the workspace dots and the focused window's title at the
left-hand end, the clock in the middle, and everything else at the right in
`Modules/Bar/StatusArea.qml`, in this order:

| | |
|---|---|
| Tray | the drawer arrow, then one icon per pinned application |
| Keyboard layout | the layout's name; click to move to the next one |
| Battery | outline, coloured fill, percentage inside; hover for how long is left |
| Wi-Fi | signal strength; opens the network panel |
| Bluetooth | opens the device panel |
| Volume | percentage; opens the volume panel |
| Controls | opens the control centre; red while keep-awake is on |

A button lights up amber while its panel is open, and clicking it again puts
the panel away. Adding another one is a `BarButton` in `StatusArea.qml` plus,
if it needs a panel, a `PopupCard` in `PopupLayer.qml`.

`BarButton` also takes a `label`, which widens it to fit text after its glyph —
that is the volume percentage, and with no `icon` at all it becomes the
text-only layout indicator. A `tooltip` puts a label under it on hover. `rest`
and `restText` recolour it at idle only — hovering, pressing and `active` all
win over them — which is how the controls button goes red for keep-awake
without looking any different once the mouse reaches it.

A button with only a glyph is exactly `Theme.barButtonSize` square, so a row of
them is evenly spaced; only a labelled one grows, by
`Theme.barButtonPadding` either side. Those two are the knobs for how wide the
bar's buttons are.

## System monitor

Four readouts at the far left: CPU load, memory in use, storage in use on `/`,
and the CPU temperature, each an icon and a number with the detail on hover
(the GiB behind a percentage, or which sensor the temperature is). One that
goes past its threshold turns red.

`Services/SystemMonitorService.qml` is where all of it is decided — the refresh
rate (2 s; storage every minute, since it barely moves), the thresholds, and
how each number is worked out. CPU and memory come straight from `/proc`, the
temperature from `/sys`, storage from `df`, and the percentage is rounded the
way `df` rounds it (up), so the bar never disagrees with the terminal by one.

The temperature is whichever hwmon chip is the CPU package — `coretemp` on
Intel, `k10temp` on AMD — found by name on startup, because hwmon numbering is
not stable across boots. A machine with no sensor this knows about just does
not get that readout; the other three close up.

Every number is given room for two digits, so a value ticking from 5% to 12%
does not shove everything to its right along. Not three: a reading of 100% is
rare and brief, and reserving for it left a permanent hole after every other
value.

## Window title

Whatever the focused window would put in its own title bar — a file manager's
current folder, an editor's file name — fills the gap between the workspace
dots and the clock. A title too long for the gap scrolls slowly to its end and
back, resting at each end; `Theme.titleScrollSpeed` (px/s) and
`Theme.titleScrollPause` (ms) set the pace.

Some titles change many times a second — a terminal showing a spinner — so the
scroll only starts over for a different window, or when the title's length
really changes (a file manager moving to another folder). A glyph swapping for
another of the same width just lets it carry on. Each monitor's bar shows the title only when the window
is on that monitor, and nothing at all on an empty workspace.

It comes from the Wayland toplevel protocol (`ToplevelManager.activeToplevel`),
not Hyprland's IPC. Hyprland's `activeToplevel` keeps pointing at the last
window after you move to an empty workspace, so its title would linger there;
the Wayland one clears as soon as nothing has focus. The colour is
`Colors.bar.windowTitle` — the same white as the system monitor's numbers.

## Workspaces

A fixed row of dots: `WorkspaceService.numbered` of them for 1..n, then one per
entry in `WorkspaceService.specials` — `scratchpad` and `majic` — which is
where to change how many there are or what the special ones are called.

The dots are drawn whether or not those workspaces exist, since Hyprland only
creates a workspace once something is on it. So every lookup copes with finding
nothing: an empty dot is one with no workspace object behind it yet, and
clicking it still switches there. A numbered dot dispatches
`hl.dsp.focus({ workspace = n })`; a special one dispatches
`hl.dsp.workspace.toggle_special("<name>")`, so the same click both shows and
hides it. Those are the Lua spellings — see the gotchas for why there are two.

A dot counts as occupied when `HyprlandWorkspace.toplevels` is non-empty —
Quickshell keeps that list current from window events as they happen. Not
`lastIpcObject.windows`: that is a snapshot only re-read on *workspace* events,
so a dot lagged behind an app opening on it, and a special workspace (created by
its first window) stayed dark until it was next toggled.

Special workspaces show their initial, with the full name on hover.
`Theme.workspaceSize` is the diameter.

## Keyboard layout

Hyprland holds a list of layouts and a matching list of variants — here
`us,us` and `,colemak_dh` — and switches between them by group index. That
index is the only thing separating the two, so `KeyboardService` reads
`active_layout_index` out of `hyprctl devices` rather than trying to read a
name, and re-reads it whenever Hyprland sends an `activelayout` event.

Two things make picking the right keyboard the whole problem. Every input
device carries the same layout list — the lid switch and the power button are
in that list too — but only the one being typed on ever changes group. And
ibus registers a virtual keyboard that announces `activelayout` constantly
while permanently sitting in group 0. So virtual keyboards are ignored
outright, and of the rest the service trusts whichever one Hyprland last
reported a real change for.

`displayNames` in that file is what each layout is called on the bar — `us`
and `us<sub>dh</sub>`. Those strings go through `Text.RichText`, so a subscript
or anything else HTML offers works. Anything unlisted falls back to its variant
in lower case, with underscores turned into dashes.

## Panels

All of them drop out of the same place — the top right corner, just under the
bar — and only one is ever open. `PopupService` is what decides which:

```qml
BarButton { active: PopupService.isOpen("wifi")
            onClicked: PopupService.toggle("wifi", root.monitor) }
PopupCard { name: "wifi"; WifiPanel {} }
```

They are drawn on `PopupLayer`, a full-screen overlay that only exists while
something is open. That is what makes them dismiss reliably: a click anywhere
outside a card lands on the layer, and so does Escape.

A panel is a `Column` of `PopupHeader` and `PopupList`, and a `PopupList` is a
stack of `PopupSection` dividers and `PopupRow` entries. A row takes an icon,
two lines of text and whatever controls belong at its right-hand end.

### Wi-Fi

Saved networks are listed first and join with a click; everything else in range
is listed underneath, greyed out, for information only — joining one of those
needs a password and the panel has nowhere to type it.

This goes through Quickshell's NetworkManager binding rather than shelling out,
so the list updates live. It is the same NetworkManager `nmcli` drives, just
over D-Bus. Disconnecting is the exception: NetworkManager only offers that on
the device, which has no binding yet, so `WifiService.disconnectActive()` runs
`nmcli device disconnect`.

NetworkManager only keeps the list of nearby access points fresh while
something is scanning, so the panel switches `WifiService.scanning` on while it
is open and off again when it closes.

### Bluetooth

Paired devices are at the top: click one to connect or disconnect, and the
switch on the right is BlueZ's "trusted" flag, which is what decides whether it
reconnects by itself. The bin forgets the device.

Everything the current scan turns up is underneath, newest at the top, and
clicking one of those pairs it. Devices that broadcast no name are left out —
BlueZ names those after their address, and a list of bare MAC addresses is
noise nobody can act on. "Newest" is measured against `BluetoothService.seen`,
the addresses in the order they appeared; a device BlueZ drops and later finds
again counts as new and goes back to the top.

While a device is pairing, its row is where the conversation happens. The
second line says what is wanted and the chips on the right are how to answer:

| the row says | what to do |
|---|---|
| Pairing… | wait; the ✕ backs out |
| Does it show 123456? | check the device's screen, then ✓ or ✕ |
| Type 123456 on it | the device has a keypad and no screen |
| Type its PIN here | a field appears; Enter submits (old speakers: try 0000) |
| Pairing failed · … | click the row to try again |

A device that pairs is also connected and trusted, so it comes back by itself
next time — the switch on its new row in the paired list turns that off.

**Pairing does not go through Quickshell's `device.pair()`**, and there is a
reason. BlueZ needs a *pairing agent* — a registered D-Bus object it can ask
"does this number match?" — and Quickshell's binding does not register one, so
its pair request fails with "Authentication Failed" for any device that asks a
question (bluetoothd logs `No agent available for request type 2`).
`bluetoothctl` registers an agent the moment it starts, which is why pairing by
hand in a terminal works. So `BluetoothService` runs `bluetoothctl`, sends
`pair <address>` over its stdin, and reads the questions back off its stdout.
Its prompts are readline prompts with no newline after them, hence the
`SplitParser` with an empty marker: chunks as they arrive, not lines. It exits
when the pairing does; nothing is left running in between.

Discovery, like Wi-Fi scanning, only runs while the panel is open.

### Control centre

Volume and brightness sliders across the full width, and three buttons in the
top right corner: the target for focus mode, the coffee cup for keep-awake, and
the session menu.
This is where anything that is neither a status readout nor a list of things to
connect to belongs.

The line under the heading is flavour text, picked fresh every time the panel
opens. **`Config/Flavor.qml` is where to add your own** — it is a plain list of
strings at the top of the file. The same line never comes up twice in a row, so
a short list still feels varied.

### Tray

The drawer arrow is the leftmost thing in the tray and the icons run right to
left from there, the way Windows lays its tray out: the application that
registered first is at the right-hand end, and anything new appears to its left.

| | |
|---|---|
| left click | activate the application, or show its menu if activating is not something it offers |
| right click | the application's own menu |
| middle click | the application's secondary action |
| drag onto the arrow | hide it |

Which gesture an application expects differs from one to the next, so both
buttons fall back to the menu rather than doing nothing.

Two things have to be true for those menus to open at all, and neither reports
a useful error on its own — see the gotchas at the bottom.

Dragging an icon onto another one moves it there, and dragging it onto the
arrow puts it away. Getting one back out of the drawer is the pin button on its
row: that direction cannot be a drag, since it would mean dragging between two
Wayland surfaces and Qt cannot do that.

Both the order and what is hidden are remembered across restarts in
`~/.local/state/quickshell/by-shell/<id>/tray.json`, and anything new is pinned
by default, so an application that starts later shows up on the bar by itself.

Nothing here is specific to any application — ibus, the keyboard layout
indicator, Steam, Tailscale and so on all arrive through the same
StatusNotifierItem protocol.

## Battery

The gauge fills from the left and slides green → yellow → orange → red as the
battery drains. The stops are `Colors.battery.ramp` and the blending between
them is `BatteryService.rampColor`, so recolouring it is a matter of editing
that list:

```qml
readonly property var ramp: [
    { level: 0.00, color: root.palette.coral },
    { level: 0.15, color: root.palette.coral },
    ...
]
```

The percentage is drawn twice — once light, once dark and clipped to the fill —
so it stays readable whether the fill is behind it or not.

Hovering the gauge shows `BatteryService.summary` ("1h 20m left", "45m to
full") in a tooltip. `Theme.batteryWidth` is how long the gauge is — the
percentage inside is centred, so it follows along.

## Volume and brightness

Both have a slider in the control centre, and volume has its own panel on the
bar as well. They share `SliderRow`, and every slider drives its service rather
than holding a value of its own, so two views of the same setting cannot drift
apart.

**Volume** is Pipewire's default output through `AudioService`. Clicking a
slider's icon mutes.

**Brightness** is handed off to your script:

```
~/.config/hypr/hyprland/scripts/brightness.sh set <0-110>
~/.config/hypr/hyprland/scripts/brightness.sh get
```

`BrightnessService.level` is that 0-110 number and nothing else — the script
owns the curve, so this deliberately does not try to match `brightnessctl`.

The script is the source of truth: while a panel with a brightness slider is
open, `get` is read back once a second, so pressing the brightness keys moves
the slider too. Its answer is prose — `Current Brightness: 69% (Raw:
2741/96000, Gamma: 100)` — and the number in front of the percent sign is what
gets used.

Two timers keep that from fighting with the mouse. Dragging the slider is
coalesced into one call to the script every 40ms rather than one per pixel, and
readings are ignored for 700ms after any change made here — otherwise a `get`
issued just before your own `set` landed would report the old level and drag
the handle backwards under the cursor.

The path is `BrightnessService.script`, and the 0-110 range is `minimum` and
`maximum` in the same file.

## Keeping the device awake

The coffee cup in the control centre toggles it, and turns amber while it is
on. The control centre button on the bar goes red at the same time, so the
machine being held up is visible with the panel closed — at rest only: hovering
or pressing that button looks the same as any other. Everything else about it
is in `Services/KeepAwake.qml`, and anything can flip it with
`KeepAwake.toggle()`.

It holds two locks at once, because "idle" is decided in two places:

- the **compositor's** idle-notify protocol, which is what `hypridle` listens
  to — blocked by the Wayland idle-inhibit protocol. That one needs a window to
  hang off, so the `IdleInhibitor` sits in `Modules/Bar/Bar.qml` next to the bar.
- **logind's** own idle handling — blocked by a `systemd-inhibit --what=idle`
  process. Check it with `systemd-inhibit --list` while the button is on.

Only `idle` is inhibited, never `sleep`, so a deliberate Suspend from the
session menu still works. Both locks drop when you toggle it off or when the
shell exits, so it cannot get stuck on.

## Focus mode

The target button in the control centre swaps the wallpaper for plain black,
on the desktop and on the lock screen, and turns amber while it is on. Windows
and the bar are untouched. It is
`Services/FocusMode.qml`, flipped with `FocusMode.toggle()`, or from a keybind:

```
bind = SUPER, F, exec, qs -c yolojj333 ipc call focus toggle
```

(`enable` and `disable` too.)

hyprpaper is never told anything. It draws on the layer-shell *background*
layer, and `Modules/Desktop/FocusBackdrop.qml` puts a black surface one layer
up, on *bottom* — still under every window and the bar, so it covers the
wallpaper and nothing else, whichever of the two started first. It ignores the
bar's reserved space so it reaches the top edge, takes no clicks, and fades over
`Theme.animSlow`. With focus mode off the surface does not exist at all (check
with `hyprctl layers`, namespace `quickshell-focus`). The colour is
`Colors.desktop.focus`.

Like keep-awake, it starts off every time the shell starts.

### The lock screen

hyprlock draws above everything, so no surface of the shell's can cover it —
hyprlock has to be told. The shell writes a small hyprlock config file
whenever focus mode changes, and once more at startup:

```
~/.local/state/quickshell/yolojj333/hyprlock.conf
```

Off, it holds only a comment. On, it holds `$lock_wallpaper =`, an empty
value. Three edits to `~/.config/hypr/hyprlock.conf` hook it up:

```
# 1. your wallpaper, in a variable, above the source line — exactly what
#    `path` says today: the link hypridle's pre-lock script repoints
$lock_wallpaper = ~/.cache/hyprlock/current-wallpaper

# 2. lets focus mode blank that variable
source = ~/.local/state/quickshell/yolojj333/hyprlock.conf

background {
    path = $lock_wallpaper   # 3. was: path = <your wallpaper>
    color = rgb(000000)      # what shows when path is empty
    # ...the rest of your background block, unchanged
}
```

Order matters: the variable is set first, the `source` line may override it,
and only then does `background` read it. A `path` left empty is hyprlock's
signal to fill the background with `color` instead. `screenshot` works as the
normal value too.

The script hypridle runs before each lock, which repoints
`~/.cache/hyprlock/current-wallpaper` at the wallpaper to show, needs no change:
the variable names the link, not the image, so it follows wherever the script
points it. With focus mode on the link
is simply not used for that lock. With more than one `background` block (one per monitor),
give each the same `path = $lock_wallpaper`.

hyprlock reads its config each time it starts, so the change shows from the
next lock on. If the file has not been written yet, hyprlock skips the
`source` line and shows the wallpaper as usual.

## The session menu

Anything can open it by calling into `SessionService`; the menu itself just
follows `SessionService.opened`.

- **Control centre** — the power button in its top right corner calls
  `SessionService.open()`.
- **Keybind** — `shell.qml` exposes an `IpcHandler` with target `session`:

  ```
  # hyprland.conf
  bind = SUPER SHIFT, E, exec, qs -c yolojj333 ipc call session toggle
  ```

  `open` and `close` are available too. List them with
  `qs -c yolojj333 ipc show`.

Inside the menu: `1`-`6` fire an action, arrows or `hjkl` move the selection,
`Enter` confirms, `Escape` or a click outside dismisses.

## Colours

`Config/Colors.qml` is the only file with a hex code in it, and it has two
layers:

1. `palette` — the raw colours (`night`, `plum`, `coral`, ...). Nothing is drawn
   with these directly.
2. `bar`, `workspace`, `popup`, `battery`, `monitor`, `desktop` and `menu` — one entry per
   visible part and state, each pointing at a palette colour.

The QML files only ever name roles, never palette colours:

| Part | Role |
|---|---|
| Bar background / clock | `bar.background` / `bar.text` |
| Focused window's title | `bar.windowTitle` |
| Bar button, idle / hover / press | `bar.button` / `bar.buttonHover` / `bar.buttonPressed` (`...Text` for the glyph) |
| Bar button whose panel is open | `bar.buttonActive`, `bar.buttonActiveText` |
| Bar button for something switched off | `bar.buttonTextMuted` |
| Power button hover | `bar.powerHover`, `bar.powerHoverText` |
| Controls button while keep-awake is on | `bar.keepAwake`, `bar.keepAwakeText` |
| Hover tooltip | `bar.tooltip`, `bar.tooltipText`, `bar.tooltipBorder` |
| Drawer arrow with an icon over it | `bar.dropTarget`, `bar.dropTargetText` |
| Panel background | `popup.background`, `popup.border` |
| Panel title / section label | `popup.heading` / `popup.sectionLabel` |
| List row, idle / hover / press | `popup.row` / `popup.rowHover` / `popup.rowPressed` (`...Text` for the label) |
| Row of the network or device in use | `popup.rowCurrent`, `popup.rowCurrentText` |
| Second line of a row | `popup.rowTextMuted` |
| Chip button | `popup.chip*`, and `popup.chipDanger*` for the bin |
| Switch | `popup.switchOff`, `popup.switchActive`, `popup.switchKnob` |
| Slider | `popup.slider`, `popup.sliderFill`, `popup.sliderKnob` |
| Battery fill | `battery.ramp` (see above) |
| Battery outline / percentage | `battery.outline` / `battery.text` and `battery.textOnFill` |
| Charging bolt | `battery.charging` |
| Monitor icon / number | `monitor.icon` / `monitor.text` |
| Monitor reading past its threshold | `monitor.hot` |
| Desktop in focus mode | `desktop.focus` |
| Dim over the desktop | `menu.scrim`, `menu.scrimOpacity` |
| Card behind the grid | `menu.card`, `menu.cardBorder` |
| Tile at rest | `menu.tile`, `menu.tileText`, `menu.tileBorder` |
| Tile hovered | `menu.tileHover`, `menu.tileHoverText`, `menu.tileHoverBorder` |
| Tile pressed / keyboard-selected | `menu.tileSelected`, `menu.tileSelectedText`, `menu.tileSelectedBorder` |
| Shutdown tile | `menu.tileDanger`, `menu.tileDangerText` |
| Number pill | the tile's own text colour at `menu.badgeOpacity` |

So: edit a palette hex to move everything that uses that colour, or repoint one
role to change a single part.

## Sizing

`Config/Theme.qml`. `scale` resizes the whole shell; `menuScale` multiplies on
top of it for the session menu alone.

In the bar: `barHeight` and `barButtonSize` set its height and the size of an
icon-only button, and `barButtonPadding` is how much room a button's text gets
either side.

Three knobs control the gaps, and each is exactly the number of pixels it says:

```
tray ─ kb ─ battery ═══ wifi · bt · volume ─ controls
      4       4     10       1    1        4
```

`barSpacing` is the default gap, `barGroupSpacing` separates the readouts from
the buttons that open a panel, and `connectivitySpacing` applies only between
Wi-Fi, Bluetooth and volume.

They come out honest because `StatusArea` is nested rows — the group gap *is*
the outer Row's `spacing`. Doing it with a spacer item between the groups
instead does not work: a spacer is a child like any other, so the Row puts
`spacing` on both sides of it and the gap silently becomes
`barGroupSpacing + 2 × barSpacing`.

`batteryPaddingLeft` and `batteryPaddingRight` are the room either side of the
battery gauge. Raising one and lowering the other by the same amount slides the
gauge along without resizing anything, so they position it as well as pad it.
The left one is skipped while charging, because the bolt is drawn in that space
and would otherwise push the gauge across.

`monitorSpacing` is the gap between two system monitor readouts, and
`monitorGap` the one between a readout's icon and its number.

`workspaceSize` and `workspaceSpacing` size the workspace dots. They add up to
the pitch of the row, so raising one and lowering the other by the same amount
makes the dots bigger without moving any of them.

In the panels: `popupWidth` and `rowHeight`, and `popupMaxHeight` for how tall
a list gets before it starts scrolling instead of growing.

## Adding things

- **A new session action** — add an entry to `actions` in
  `Services/SessionService.qml` (and an icon path in `Widgets/Icons.qml`). The
  grid and the number shortcuts follow automatically.
- **A new bar widget** — make a component under `Modules/Bar/`, list it in that
  folder's `qmldir`, then place it in `Bar.qml` or `StatusArea.qml`.
- **A new panel** — a `Column` of `PopupHeader` and `PopupList` under
  `Modules/Popups/`, a `PopupCard` for it in `PopupLayer.qml`, and a `BarButton`
  in `StatusArea.qml` that toggles it by name.
- **A new module** — new folder, a `qmldir` with `module qs.Modules.Whatever`,
  and one line per component.

## Gotchas

Don't name a property `onSomething` (`onError`, `onAccent`, ...). QML reads
`on` + a capital letter as a signal handler and refuses to load the file. That
is why colour roles are named `tileText`, `buttonHoverText` and so on rather
than the usual Material `onSurface` / `onPrimary` style.

Don't read a window's own `screen` inside one of its bindings — `Bar` and
`PopupLayer` are handed the monitor as `monitor` instead, because binding
`visible` to `screen` makes the two chase each other.

Text that comes from other applications goes through `elide` **and**
`maximumLineCount: 1`. Tray titles are arbitrary strings and at least one of
them (ibus) contains a newline and a paragraph of help text, which pushes a row
straight out through the bottom of a panel otherwise.

`PopupList` renders itself to a texture (`layer.enabled`). Plain `clip` is not
enough, because the stroked icons are `QtQuick.Shapes` and the curve renderer
draws straight past a clip node.

Hyprland's Lua configuration changed what `Hyprland.dispatch()` accepts, and
old calls fail **silently as far as the UI is concerned** — the error goes to
Quickshell's log and nowhere else, so a button just stops doing anything. The
string is now pasted into `return hl.dispatch(<your string>)`, which wants a
dispatcher object, not a flat command:

| was | is |
|---|---|
| `workspace 3` | `hl.dsp.focus({ workspace = 3 })` |
| `togglespecialworkspace magic` | `hl.dsp.workspace.toggle_special("magic")` |

`Hyprland.usingLua` says which configuration is running, and `WorkspaceService`
keeps both spellings behind it. Not everything moved: switching keyboard layout
was never a dispatcher, so `KeyboardService` still shells out to
`hyprctl switchxkblayout`. Two ways to find the right name for something —
`/usr/share/hypr/stubs/hl.meta.lua` lists every namespace, and
`strings /usr/bin/Hyprland | grep 'hl\.'` turns up Hyprland's own example
config with real bindings in it. `hyprctl eval '<lua>'` will tell you whether an
expression is even valid, though it prints `ok` and throws the result away.

A misspelled or missing property on a singleton fails **silently**. `Theme.nope`
is `undefined`, `undefined * Theme.scale` is `NaN`, and a `NaN` width does not
warn — it collapses the whole `Row` it is in, so every sibling vanishes at once.
The symptom looks like a layout bug and reads like a binding loop (it also
produces `possible QQuickItem::polish() loop` warnings by the thousand), which
is a long way from the cause. When widgets disappear for no reason, check that
every `Theme.` and `Colors.` name they use actually exists before anything else.

Writing to a `JsonAdapter` does not take effect until a later tick. Anything
that reads a value straight back after setting it — two tray drags in quick
succession, say — will work from the old one. `TrayService` keeps its own copy
of the lists for that reason, and saves on a short timer, because writing on
`adapterUpdated` alone drops the last change of a burst.

`Text.StyledText` does not support `<sub>` or `<sup>`, and gives no hint that
it doesn't — it renders the contents flat and drops the tag. `BarButton` labels
use `Text.RichText`, which does.

Don't clear a flag in a one-shot `Timer`'s `onRunningChanged`. Firing is what
stops the timer, so `running` goes false in the same breath as `triggered` and
undoes whatever the handler just did. `BarTooltip` clears its flag when the
hover ends instead.

Anything that needs to draw outside the bar needs its own window — the bar is
only as tall as one row of icons. That is why `BarTooltip` is a `PopupWindow`
and why the panels live on `PopupLayer` rather than in the bar itself.

An application's own tray menu needs **both** of these, and gives up quietly
without them:

- `//@ pragma UseQApplication` on the first line of `shell.qml`. Without it
  `QsMenuAnchor.open()` refuses outright — it does say so in the log, and only
  in the log. It is read at startup, so it needs a restart, not a reload.
- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` on whichever window
  the menu is anchored to. A menu is a Wayland popup with a pointer grab, and
  no compositor will grant a grab to a layer surface that refuses keyboard
  focus. This one fails silently: `open()` returns, `visible` stays false, and
  nothing is logged. Both the bar and `PopupLayer` set it.
