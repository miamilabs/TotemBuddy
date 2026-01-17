--[[
    TotemBuddy Options Defaults
    Defines the default settings schema for AceDB

    Schema Version: 2 (v2.0.0)
    - Added totem sets system
    - Added modifier overrides (Shift/Ctrl/Alt)
    - Added enhanced timer options
    - Added selector behavior options
]]

---@class OptionsDefaults
local OptionsDefaults = TotemBuddyLoader:CreateModule("OptionsDefaults")

--- Returns the default settings table for AceDB
---@return table defaults The defaults table
function OptionsDefaults:GetDefaults()
    return {
        profile = {
            -- Schema version for migrations
            schemaVersion = 2,

            -- General Settings
            enabled = true,
            locked = false,
            showTooltips = true,

            -- Layout Settings
            layout = "horizontal",  -- "horizontal", "vertical", "grid2x2"
            anchor = "CENTER",
            posX = 0,
            posY = -200,
            scale = 1.0,
            tileSize = 40,
            tileSpacing = 4,

            -- Appearance Settings
            showBorder = true,
            borderStyle = "tooltip",  -- "tooltip", "dialog", "none"
            backgroundColor = {0, 0, 0, 0.5},
            showCooldowns = true,
            showCooldownText = true,      -- Show cooldown numbers
            showDurationText = true,      -- Show active totem duration
            showActiveGlow = true,        -- Show glow when totem is active
            showKeybinds = true,
            showElementIndicator = true,

            -- Enhanced Timer Settings (v2.0)
            showDurationBar = true,       -- Show progress bar for totem duration
            durationBarHeight = 4,        -- Height in pixels
            expiringThreshold = 10,       -- Seconds before "expiring soon" warning
            expiringColor = {1, 0.8, 0},  -- Yellow color for expiring warning

            -- Totem Settings
            useHighestRank = true,  -- false = manual rank selection

            -- Per-element default totems (stores spellId)
            -- Element order: Fire=1, Earth=2, Water=3, Air=4
            defaultTotems = {
                [1] = nil,  -- Fire: nil means first available
                [2] = nil,  -- Earth
                [3] = nil,  -- Water
                [4] = nil,  -- Air
            },

            -- Specific rank overrides (when useHighestRank = false)
            -- [totemName] = spellId
            totemRanks = {},

            -- Totem Sets (v2.0)
            -- Named presets storing 4 spellIds (one per element)
            -- Format: sets["SetName"] = { [1]=fireSpellId, [2]=earthSpellId, [3]=waterSpellId, [4]=airSpellId }
            sets = {},

            -- Currently active set name (nil = using defaultTotems directly)
            activeSetName = nil,

            -- Order of sets for cycling (list of set names)
            setOrder = {},

            -- Show active set name on bar
            showSetName = true,

            -- Modifier Overrides (v2.0)
            -- Per-element override spellIds for Shift/Ctrl/Alt modifiers
            -- Format: modifierOverrides[element] = { default=spellId, shift=spellId, ctrl=spellId, alt=spellId }
            modifierOverrides = {
                [1] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Fire
                [2] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Earth
                [3] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Water
                [4] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Air
            },

            -- Selector Settings
            selectorPosition = "above",  -- "above", "below", "left", "right"
            selectorColumns = 4,
            showUnavailable = false,  -- Show totems not yet learned (grayed)
            selectorScale = 1.0,
            showSelectorInCombat = false,  -- Show selector popup while in combat
            lockSelector = false,  -- Lock selector: only opens with Shift+hover

            -- Selector Behavior (v2.0)
            castOnSelect = false,         -- Cast totem immediately when selected (out of combat)
            castOnSelectInCombat = false, -- In combat: queue default change (true) or block (false)

            -- ===========================================
            -- EXTRA FEATURES (v2.1)
            -- ===========================================

            -- Feature Toggles
            showCallOfTotems = true,      -- Show Call of the Elements/Ancestors/Spirits buttons
            showWeaponImbues = true,      -- Show Weapon Imbue buttons (Mainhand/Offhand)
            showShields = true,           -- Show Shield button (Lightning/Water/Earth Shield)

            -- Call of Totems defaults
            defaultCallSpell = nil,       -- nil = use first available

            -- Weapon Imbue defaults
            defaultMainhandImbue = nil,   -- nil = use first available
            defaultOffhandImbue = nil,    -- nil = use first available
            showImbueStatus = true,       -- Show active/duration indicator
            imbueModifierOverrides = {
                mainhand = { default = nil, shift = nil, ctrl = nil, alt = nil },
                offhand = { default = nil, shift = nil, ctrl = nil, alt = nil },
            },

            -- Shield defaults
            defaultShield = nil,          -- nil = use first available (Lightning Shield)
            showShieldStatus = true,      -- Show active/charges indicator

            -- Earth Shield Targeting (v2.2)
            -- Configure modifier-based targeting for Earth Shield
            -- Options: "none", "player", "focus", "party1"-"party5"
            earthShieldTargeting = {
                noModifier = "player",    -- Default: cast on self
                shift = "focus",          -- Shift+click: cast on focus
                ctrl = "none",            -- Ctrl+click: disabled
                alt = "party1",           -- Alt+click: cast on party1
            },

            -- Extra tiles layout
            extraTilesPosition = "after", -- "after" (after totem tiles) or "before"
            showExtraTilesSeparator = false, -- Show visual separator between totems and extras
        },
        char = {
            -- Character-specific settings (currently unused)
        },
        global = {
            -- Global settings across all characters
            firstRun = true,
        },
    }
end

return OptionsDefaults
