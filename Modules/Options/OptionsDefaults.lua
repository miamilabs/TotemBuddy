--[[
    TotemBuddy Options Defaults
    Defines the default settings schema for AceDB
]]

---@class OptionsDefaults
local OptionsDefaults = TotemBuddyLoader:CreateModule("OptionsDefaults")

--- Returns the default settings table for AceDB
---@return table defaults The defaults table
function OptionsDefaults:GetDefaults()
    return {
        profile = {
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

            -- Totem Settings
            useHighestRank = true,  -- false = manual rank selection

            -- Per-element default totems (stores totem index in database)
            defaultTotems = {
                [1] = nil,  -- Earth: nil means first available
                [2] = nil,  -- Fire
                [3] = nil,  -- Water
                [4] = nil,  -- Air
            },

            -- Specific rank overrides (when useHighestRank = false)
            -- [totemName] = spellId
            totemRanks = {},

            -- Selector Settings
            selectorPosition = "above",  -- "above", "below", "left", "right"
            selectorColumns = 4,
            showUnavailable = false,  -- Show totems not yet learned (grayed)
            selectorScale = 1.0,
            showSelectorInCombat = false,  -- Show selector popup while in combat
            lockSelector = false,  -- Lock selector: only opens with Shift+hover
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
