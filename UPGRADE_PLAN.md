# TotemBuddy Upgrade Plan v2.0

## Overview

This document outlines the complete upgrade plan for TotemBuddy to add:
- API Compatibility Layer (works across all Classic variants)
- Totem Sets (named presets with instant switching)
- Modifier Overrides (Shift/Ctrl/Alt emergency totems via secure macros)
- Enhanced Timers (duration bars, expiring warnings, pulse animations)
- Improved Selector (right-click trigger, combat-aware behavior)
- Full Keybindings (15+ bindable actions)

---

## Current Architecture

- **Module System**: Custom loader + AceAddon-3.0
- **Secure Buttons**: Uses SecureActionButtonTemplate correctly
- **SpellID Storage**: Already locale-safe (stores spellIds, not names)
- **Combat Lockdown**: Basic queuing via `pendingSpellId` per tile
- **AceDB Profiles**: SavedVariables structure in place

---

## Implementation Phases

```
PHASE 1: Foundation          PHASE 2: Core Features      PHASE 3: Modifiers
    |                              |                           |
    v                              v                           v
+----------------+           +----------------+          +------------------+
| APICompat.lua  |---------->| TotemSets.lua  |--------->| Macro Generation |
| Migration.lua  |           | Slash Commands |          | OptionsModifiers |
| Schema Updates |           | Bar Integration|          | Secure Macrotext |
+----------------+           +----------------+          +------------------+
    |                              |                           |
    +------------------------------+---------------------------+
                                   |
                                   v
    PHASE 4: Visuals         PHASE 5: Selector          PHASE 6: Keybinds
         |                         |                          |
         v                         v                          v
+----------------+           +----------------+          +----------------+
| Duration Bars  |           | Right-Click    |          | Bindings.xml   |
| Pulse Animation|           | Combat Behavior|          | Localization   |
| Expiring Warn  |           | Better Tooltips|          | Global Handlers|
+----------------+           +----------------+          +----------------+
```

---

## File Changes

### NEW FILES (6)

| File | Purpose |
|------|---------|
| `Modules/Core/APICompat.lua` | GetTotemInfo/GetTotemTimeLeft wrapper with fallback tracker |
| `Modules/Core/Migration.lua` | SavedVariables schema versioning and migration |
| `Modules/Core/TotemSets.lua` | Named preset management (create/switch/cycle) |
| `Modules/Options/OptionsSets.lua` | Set configuration UI (AceConfig) |
| `Modules/Options/OptionsModifiers.lua` | Modifier override configuration UI |
| `Bindings.xml` | 15+ keybinding definitions |

### MODIFIED FILES (10)

| File | Changes |
|------|---------|
| `*.toc` (4 variants) | Add new files to load order |
| `TotemBuddy.lua` | Slash commands, keybind handlers, migration call |
| `OptionsDefaults.lua` | New schema fields (sets, modifiers, timers) |
| `OptionsGeneral.lua` | Timer threshold options |
| `TotemBar.lua` | Set display text, macro rebuild triggers |
| `TotemTile.lua` | Duration bar, pulse animation, macro mode |
| `TotemSelector.lua` | Right-click trigger, combat awareness |
| `EventHandler.lua` | Migration.Run(), TotemSets.ProcessPending() |
| `Locales/enUS.lua` | Keybinding localization strings |
| `Data/*.lua` | Add duration field for fallback tracker |

---

## Phase 1: Foundation

### 1.1 APICompat.lua

Provides a unified API layer that works across all Classic variants (Era, TBC, WotLK Anniversary).

**Key Functions:**
- `APICompat:GetTotemInfo(slot)` - Returns: haveTotem, name, startTime, duration, icon
- `APICompat:GetTotemTimeLeft(slot)` - Returns: seconds remaining

**Fallback Mechanism:**
- Detects if native `GetTotemInfo` exists
- If missing, tracks totems via `COMBAT_LOG_EVENT_UNFILTERED` + known durations
- Stores per-slot state: haveTotem, name, startTime, duration, icon

### 1.2 Migration.lua

Safely migrates SavedVariables from old schema to new.

**Schema Versioning:**
- `schemaVersion` field in profile (starts at 2 for upgraded addon)
- Migration functions run sequentially for each version bump
- Preserves existing settings while adding new defaults

### 1.3 OptionsDefaults.lua Updates

New fields to add:
```lua
-- Schema version
schemaVersion = 2,

-- Totem Sets
sets = {},
activeSetName = nil,
setOrder = {},

-- Modifier Overrides
modifierOverrides = {
    [1] = { default = nil, shift = nil, ctrl = nil, alt = nil },
    [2] = { default = nil, shift = nil, ctrl = nil, alt = nil },
    [3] = { default = nil, shift = nil, ctrl = nil, alt = nil },
    [4] = { default = nil, shift = nil, ctrl = nil, alt = nil },
},

-- Enhanced Timers
expiringThreshold = 10,
expiringColor = {1, 0.8, 0},
showDurationBar = true,
durationBarHeight = 4,

-- Selector Options
castOnSelect = false,
castOnSelectInCombat = false,
```

### 1.4 TOC Updates

Add new files to load order (after Loader.lua, before EventHandler.lua):
```
Modules/Core/APICompat.lua
Modules/Core/Migration.lua
```

---

## Phase 2: Core Features - Totem Sets

### Data Structure
```lua
db.profile.sets = {
    ["Default"] = { [1]=8190, [2]=8075, [3]=5394, [4]=8512 },
    ["Dungeon AOE"] = { [1]=8190, [2]=2484, [3]=5675, [4]=8512 },
}
db.profile.activeSetName = "Default"
db.profile.setOrder = {"Default", "Dungeon AOE"}
```

### API
```lua
TotemSets:GetActiveSet()
TotemSets:SetActiveSet(name)      -- Queues if in combat
TotemSets:CreateSet(name, totems)
TotemSets:DeleteSet(name)
TotemSets:RenameSet(oldName, newName)
TotemSets:CycleNext()
TotemSets:CyclePrev()
TotemSets:ApplySetToBar(setName)
TotemSets:SaveCurrentAsSet(name)
```

### Slash Commands
```
/tb set <name>     -- Activate named set
/tb nextset        -- Cycle forward
/tb prevset        -- Cycle backward
/tb saveset <name> -- Save current as new set
/tb delset <name>  -- Delete set
```

---

## Phase 3: Modifier Overrides

### Secure Macro Approach

Pre-build macros out of combat that handle all modifiers:
```
#showtooltip
/cast [mod:alt] Stoneclaw Totem; [mod:ctrl] Earthbind Totem; [mod:shift] Tremor Totem; Strength of Earth Totem
```

### Implementation
- Store spellIds in `modifierOverrides[element].{shift,ctrl,alt}`
- Build macro text using `GetSpellInfo(spellId)` for spell names
- Use `SetAttribute("type", "macro")` and `SetAttribute("macrotext", ...)`
- Rebuild macros when overrides change (out of combat only)

---

## Phase 4: Visual Enhancements

### Duration Bar
- Green bar at bottom of tile showing remaining duration
- Shrinks as totem duration decreases
- Turns yellow when below `expiringThreshold`

### Expiring Pulse Animation
- Gentle alpha pulse (1.0 to 0.5) when totem about to expire
- Uses AnimationGroup with BOUNCE looping

### Timer Display
- Duration text changes color based on time remaining
- Green: > threshold, Yellow: <= threshold

---

## Phase 5: Selector Improvements

### Right-Click Trigger
- Right-click on tile opens selector for that element
- Uses `SetAttribute("type2", "")` to prevent secure action on right-click

### Combat Behavior
- Out of combat: Click sets default (optionally casts)
- In combat: Click queues change, shows feedback message

### Enhanced Tooltips
- Uses `GameTooltip:SetSpellByID()` for full spell info
- Shows "Not yet learned" for unavailable totems
- Shows cooldown remaining if on cooldown

---

## Phase 6: Keybindings

### Bindings.xml
```xml
<Bindings>
    <Binding name="TOTEMBUDDY_CAST_FIRE" category="ADDONS" header="TOTEMBUDDY">
        TotemBuddy_CastElement(1)
    </Binding>
    <!-- ... Cast Earth/Water/Air ... -->
    <!-- ... Select Fire/Earth/Water/Air ... -->
    <!-- ... Next/Prev Set, Set 1-5 ... -->
</Bindings>
```

### Localization (enUS.lua)
```lua
BINDING_HEADER_TOTEMBUDDY = "TotemBuddy"
BINDING_NAME_TOTEMBUDDY_CAST_FIRE = "Cast Fire Totem"
-- ... etc
```

---

## Test Checklist

### Login/Reload
- [ ] Clean install loads without errors
- [ ] Existing config migrates correctly
- [ ] /reload preserves UI state
- [ ] Character switch loads correct profile

### Sets
- [ ] Create/rename/delete sets via UI
- [ ] Switch sets out of combat (immediate)
- [ ] Switch sets in combat (queued)
- [ ] /tb set, nextset, prevset commands work

### Modifiers
- [ ] Shift+click casts shift override
- [ ] Ctrl+click casts ctrl override
- [ ] Alt+click casts alt override
- [ ] Works during combat (pre-built macros)

### Timers
- [ ] Duration bar shrinks over time
- [ ] Yellow warning at threshold
- [ ] Pulse animation when expiring
- [ ] Clears immediately on totem death

### Combat Safety
- [ ] No "action blocked" messages
- [ ] No taint warnings
- [ ] Rapid combat enter/exit stable

### German Locale
- [ ] Spells resolve via GetSpellInfo(spellId)
- [ ] Names display in German
- [ ] No "spell not found" errors

---

## Hard Constraints (Maintained)

- No protected function calls from insecure contexts in combat
- Use SecureActionButtonTemplate (or secure macrotext) for casting
- Never SetAttribute() on protected buttons while in combat
- Avoid taint: keep secure/insecure separation clean
- Keep addon lightweight (no heavy OnUpdate spam)
- Locale-safe: store spellID and derive name/icon via GetSpellInfo(spellId)
