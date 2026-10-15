# jd_lib

A lightweight utility library and resource for FiveM development containing helpful client scripts, modules, addons, and a custom notification system.

---

## Project Structure

* `fxmanifest.luaux`: Resource manifest file configuring scripts and metadata.
* `shared/`: Shared code and core library functions.
* `client/`: Core client-side scripts and user editors.
* `modules/`: Reusable components (features a fully styled HTML/JS notification system).
* `addons/`: Optional gameplay mechanics and features.

---

## Installation

1. Download or clone this repository into your FiveM server's resources directory.
2. Add the following line to your `server.cfg`:

```cfg
ensure jd_lib
```

---

## Example Usage

### 1. Using Shared Library Functions
Access shared utilities across your resources using the core exports:

```lua
local lib = exports['jd_lib']:GetLib()
```

### 2. Triggering Notifications
Trigger custom alerts using the built-in HTML/JS notification module:

```lua
exports['jd_lib']:Notify({
    title = "System",
    message = "This is a notification test!",
    type = "success" -- Options: success, error, info
})
```

### 3. Addons Overview
The `addons/` folder contains optional plugins that enhance gameplay:
* **Death Script (`death-script.luaux`)**: Manages custom death-related states and events.
* **Gunpowder Smell (`gunpowder-smell.luaux`)**: Adds residue tracking and mechanics after firing weapons.
* **Stress Driving (`stress-driving.luaux`)**: Introduces immersive driving stress mechanics.

---

## 🛠️ Requirements & Compatibility
* **Platform**: FiveM (Lua / Luaux)