# jd_lib

A lightweight utility library for FiveM with a clean, flat notification system and a few optional gameplay add-ons.

Fully Standalone. No ESX / QBCore needed.

---

## Contents

- [Features](#features)
- [Install](#install)
- [Sending notifications](#sending-notifications)
- [Notification options](#notification-options)
- [Test commands](#test-commands)
- [Add-ons](#add-ons)
- [Sling editor](#sling-editor)
- [Project layout](#project-layout)

---

## Features

- Notification system with 5 types, 8 screen positions and an animated countdown bar
- Works from any resource through exports, or through `lib.notify` inside jd_lib
- Safe text rendering (titles and descriptions can never inject HTML)
- Optional add-ons: death message, join message, gunpowder warning, reckless driving warning
- In-game weapon sling editor

---

## Install

1. Put the `jd_lib` folder in your `resources` folder.
2. Add this to your `server.cfg`:

```cfg
ensure jd_lib
```

3. In other resources that use it, you can add `dependencies { 'jd_lib' }` to make sure it starts first.

---

## Sending notifications

### From another resource

```lua
exports['jd_lib']:notify({
    title = 'Saved',
    description = 'Your changes were saved.',
    type = 'success',
    duration = 4000,
    position = 'top-right'
})
```

`exports['jd_lib']:Notify(...)` does the same thing and also accepts `message` instead of `description`.

### Using the library table

```lua
local lib = exports['jd_lib']:getLib()

lib.notify({ title = 'Heads Up', type = 'warning' })
```

---

## Notification options

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | string | none | Bold heading line |
| `description` | string | none | Body text (up to 3 lines). `message` also works |
| `type` | string | `info` | `success`, `error`, `warning`, `info`, `medical` |
| `duration` | number | `4000` | How long it stays on screen, in ms (minimum 1500) |
| `position` | string | `top-right` | See the table below |

You need at least a `title` or a `description`.

`inform`, `warn` and `medic` are accepted as shortcuts for `info`, `warning` and `medical`.

### Positions

| | Left | Center | Right |
|---|---|---|---|
| **Top** | `top-left` (`tl`) | `top-center` (`tc`) | `top-right` (`tr`) |
| **Middle** | `middle-left` (`ml`) | | `middle-right` (`mr`) |
| **Bottom** | `bottom-left` (`bl`) | `bottom-center` (`bc`) | `bottom-right` (`br`) |

Each position keeps its own stack, so you can show several at once. A stack holds up to 6 notifications; the oldest is removed first.

---

## Test commands

| Command | What it does |
|---|---|
| `/tesallnotis` | Shows every notification type at once (`/testallnotis` works too) |
| `/success` | Success example |
| `/error` | Error example |
| `/warning` | Warning example |
| `/info` | Info example |
| `/notify <type> <title> <description>` | Custom notification |

---

## Add-ons

Everything in the `addons/` folder is optional. Delete a file to turn that add-on off.

| File | What it does |
|---|---|
| `death-script.lua` | Shows "You Died" and names the player who killed you (including vehicle kills) |
| `joinserver-event/` | Tells everyone when a player joins the server |
| `gunpowder-smell.lua` | Warns you after firing a weapon (stun gun is exempt), then runs `/playerObs` for 5 minutes. Needs a resource that provides that command |
| `stress-driving.lua` | Warns the driver when going over 70 mph, repeating every 30 seconds |

Settings such as the speed limit or cooldowns are the constants at the top of each file.

---

## Sling editor

`/slingconfig` opens an in-game editor for placing a weapon sling on a ped bone.

It needs these resources running:

- `ox_lib`
- `object_gizmo`

---

## Project layout

```
jd_lib/
├── fxmanifest.lua
├── shared/lib.lua              lib.notify and the lib table
├── client/
│   ├── main.lua                test commands
│   └── editor.lua              sling editor
├── modules/notify/
│   ├── client.lua              exports
│   └── html/                   notification UI (index.html, style.css, app.js)
└── addons/                     optional add-ons
```

---

Made by JD Development & Designs.
