# TotemBuddy Addon - Implementation Plan

## Overview

TotemBuddy is a WoW Classic addon for Shaman totem management featuring:
- 4 totem tiles (Earth, Fire, Water, Air) for quick casting
- Hover selection for known totems
- Default totem assignment per tile
- Modern, flexible settings (horizontal/vertical/grid layout)
- Auto-detection of known totems
- Highest rank auto-selection with manual override

## Architecture

```
+------------------+     +------------------+     +------------------+
|   TotemBuddy     |---->|     Loader       |---->|   All Modules    |
|   (Main Entry)   |     |   (Module Mgmt)  |     |                  |
+------------------+     +------------------+     +------------------+
         |                                                 |
         v                                                 v
+------------------+     +------------------+     +------------------+
|     AceDB        |     |   SpellScanner   |<----|   TotemData      |
|  (SavedVars)     |     | (Known Totems)   |     | (Spell Database) |
+------------------+     +------------------+     +------------------+
         |                       |
         v                       v
+------------------+     +------------------+     +------------------+
|    TotemBar      |---->|   TotemTile x4   |<----|  TotemSelector   |
|  (Container)     |     | (SecureButtons)  |     | (Hover Popup)    |
+------------------+     +------------------+     +------------------+
```

## File Structure

```
TotemBuddy/
├── TotemBuddy.toc              # Main TOC file
├── TotemBuddy-Classic.toc      # Classic Era
├── TotemBuddy-BCC.toc          # TBC
├── TotemBuddy-WOTLKC.toc       # WotLK
├── TotemBuddy.lua              # Entry point
├── embeds.xml                  # Library deps
│
├── Libs/                       # Ace3 libraries
│   ├── LibStub/
│   ├── AceAddon-3.0/
│   ├── AceDB-3.0/
│   ├── AceConfig-3.0/
│   ├── AceGUI-3.0/
│   └── AceEvent-3.0/
│
├── Modules/
│   ├── Loader.lua              # Module system
│   ├── Core/
│   │   ├── TotemData.lua       # Totem database
│   │   ├── SpellScanner.lua    # Detect known totems
│   │   └── EventHandler.lua    # Event dispatch
│   │
│   ├── UI/
│   │   ├── TotemBar.lua        # Main container
│   │   ├── TotemTile.lua       # Individual tiles
│   │   └── TotemSelector.lua   # Hover popup
│   │
│   └── Options/
│       ├── OptionsMain.lua     # Settings manager
│       ├── OptionsDefaults.lua # Default values
│       ├── GeneralTab.lua      # General settings
│       ├── LayoutTab.lua       # Layout options
│       └── TotemTab.lua        # Totem config
│
├── Data/
│   ├── ClassicTotems.lua       # Classic totem data
│   ├── TBCTotems.lua           # TBC additions
│   └── WotLKTotems.lua         # WotLK additions
│
└── Localization/
    └── enUS.lua
```

## Implementation Phases

### Phase 1: Foundation
1. Create folder structure and TOC files
2. Set up embeds.xml with Ace3 libraries
3. Implement Loader module system
4. Create TotemBuddy.lua entry point
5. Configure AceDB for saved variables

### Phase 2: Core Data
1. Build complete totem database (all spellIds, ranks, icons)
2. Implement SpellScanner (scan spellbook for known totems)
3. Create EventHandler (LEARNED_SPELL_IN_TAB tracking)

### Phase 3: UI Components
1. Implement TotemBar frame container
2. Create TotemTile secure action buttons
3. Build TotemSelector hover popup
4. Add layout switching logic
5. Implement cooldown tracking

### Phase 4: Settings
1. Create OptionsDefaults.lua
2. Build all settings tabs
3. Integrate AceDBOptions for profiles
4. Add slash commands (/tb, /totembuddy)

### Phase 5: Polish
1. Add localization support
2. Test combat lockdown behavior
3. Test addon compatibility

### Phase 6: Expansion Support
1. Add TBC totem data
2. Add WotLK totem data
3. Test across game versions

## Settings Schema

```lua
defaults = {
    profile = {
        -- General
        enabled = true,
        locked = false,
        showTooltips = true,

        -- Layout
        layout = "horizontal",  -- "horizontal", "vertical", "grid2x2"
        anchor = "CENTER",
        posX = 0,
        posY = -200,
        scale = 1.0,
        tileSize = 40,
        tileSpacing = 4,

        -- Appearance
        showBorder = true,
        borderStyle = "tooltip",
        backgroundColor = {0, 0, 0, 0.5},
        showCooldowns = true,
        showKeybinds = true,

        -- Totem Settings
        useHighestRank = true,
        defaultTotems = {
            [1] = nil,  -- Earth
            [2] = nil,  -- Fire
            [3] = nil,  -- Water
            [4] = nil,  -- Air
        },
        totemRanks = {},

        -- Selector
        selectorPosition = "above",
        selectorColumns = 4,
        showUnavailable = false,
    },
}
```

## Technical Notes

### Combat Safety
- Uses SecureActionButtonTemplate for totem tiles
- Selector hidden during combat (PLAYER_REGEN_DISABLED)
- Frame modifications queued until combat ends

### Totem Detection
- Scans spellbook tabs for totem spells
- Matches against known spellIds in database
- Updates on LEARNED_SPELL_IN_TAB event
- Caches highest known rank per totem

### Layout System
- Positions stored as offsets from anchor point
- Recalculates on layout/size change
- Supports all WoW anchor points
