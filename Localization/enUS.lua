--[[
    TotemBuddy Localization - English (US)
    Default/fallback locale
]]

local L = {}

-- General
L["General"] = "General"
L["TotemBuddy"] = "TotemBuddy"
L["Enable TotemBuddy"] = "Enable TotemBuddy"
L["Show or hide the totem bar"] = "Show or hide the totem bar"
L["Lock Position"] = "Lock Position"
L["Prevent the totem bar from being moved"] = "Prevent the totem bar from being moved"
L["Show Tooltips"] = "Show Tooltips"
L["Show spell tooltips when hovering over totem tiles"] = "Show spell tooltips when hovering over totem tiles"

-- Display Options
L["Display Options"] = "Display Options"
L["Show Cooldowns"] = "Show Cooldowns"
L["Display cooldown swipe on totem tiles"] = "Display cooldown swipe on totem tiles"
L["Show Keybinds"] = "Show Keybinds"
L["Display keybind text on totem tiles"] = "Display keybind text on totem tiles"
L["Show Element Indicator"] = "Show Element Indicator"
L["Display colored bar indicating totem element"] = "Display colored bar indicating totem element"

-- Timer Options
L["Timer Options"] = "Timer Options"
L["Show Cooldown Numbers"] = "Show Cooldown Numbers"
L["Display countdown numbers when a totem is on cooldown"] = "Display countdown numbers when a totem is on cooldown"
L["Show Active Duration"] = "Show Active Duration"
L["Display remaining time for active totems"] = "Display remaining time for active totems"
L["Show Active Glow"] = "Show Active Glow"
L["Display a glow effect when a totem is active"] = "Display a glow effect when a totem is active"
L["Show Duration Bar"] = "Show Duration Bar"
L["Display a progress bar showing remaining totem duration"] = "Display a progress bar showing remaining totem duration"
L["Duration Bar Height"] = "Duration Bar Height"
L["Height of the duration progress bar in pixels"] = "Height of the duration progress bar in pixels"
L["Expiring Warning Threshold"] = "Expiring Warning Threshold"
L["Seconds remaining before totem is considered 'expiring soon' (triggers color change and pulse)"] = "Seconds remaining before totem is considered 'expiring soon' (triggers color change and pulse)"
L["Expiring Warning Color"] = "Expiring Warning Color"
L["Color for duration text and bar when totem is about to expire"] = "Color for duration text and bar when totem is about to expire"

-- Selector Options
L["Selector Options"] = "Selector Options"
L["Show Selector in Combat"] = "Show Selector in Combat"
L["Allow the totem selector popup to appear while in combat (note: you cannot change totems during combat)"] = "Allow the totem selector popup to appear while in combat (note: you cannot change totems during combat)"
L["Lock Selector"] = "Lock Selector"
L["When enabled, the totem selector only opens when holding Shift while hovering or right-clicking"] = "When enabled, the totem selector only opens when holding Shift while hovering or right-clicking"
L["Tip: Right-click a totem tile to quickly open the selector."] = "Tip: Right-click a totem tile to quickly open the selector."
L["Selector Behavior"] = "Selector Behavior"
L["Cast on Select"] = "Cast on Select"
L["When selecting a totem from the popup, immediately cast it in addition to setting it as the default. Only works out of combat."] = "When selecting a totem from the popup, immediately cast it in addition to setting it as the default. Only works out of combat."

-- Actions
L["Actions"] = "Actions"
L["Reset Position"] = "Reset Position"
L["Reset the totem bar to the center of the screen"] = "Reset the totem bar to the center of the screen"
L["Rescan Totems"] = "Rescan Totems"
L["Rescan your spellbook for known totems"] = "Rescan your spellbook for known totems"

-- Layout
L["Layout"] = "Layout"
L["Bar Layout"] = "Bar Layout"
L["Choose how totem tiles are arranged"] = "Choose how totem tiles are arranged"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertical"
L["2x2 Grid"] = "2x2 Grid"
L["Size"] = "Size"
L["Scale"] = "Scale"
L["Overall scale of the totem bar"] = "Overall scale of the totem bar"
L["Tile Size"] = "Tile Size"
L["Size of individual totem tiles"] = "Size of individual totem tiles"
L["Tile Spacing"] = "Tile Spacing"
L["Space between totem tiles"] = "Space between totem tiles"
L["Appearance"] = "Appearance"
L["Show Border"] = "Show Border"
L["Show a border around the totem bar"] = "Show a border around the totem bar"
L["Background Color"] = "Background Color"
L["Background color of the totem bar"] = "Background color of the totem bar"
L["Selector Popup"] = "Selector Popup"
L["Selector Position"] = "Selector Position"
L["Where the totem selection popup appears"] = "Where the totem selection popup appears"
L["Above"] = "Above"
L["Below"] = "Below"
L["Left"] = "Left"
L["Right"] = "Right"
L["Selector Columns"] = "Selector Columns"
L["Number of columns in the totem selector popup"] = "Number of columns in the totem selector popup"
L["Selector Scale"] = "Selector Scale"
L["Scale of the totem selector popup"] = "Scale of the totem selector popup"

-- Totems Tab
L["Totems"] = "Totems"
L["Use Highest Rank"] = "Use Highest Rank"
L["Always cast the highest rank of each totem you know. When disabled, you can choose specific ranks."] = "Always cast the highest rank of each totem you know. When disabled, you can choose specific ranks."
L["When 'Use Highest Rank' is disabled, you can select specific ranks for each totem in the hover selection popup."] = "When 'Use Highest Rank' is disabled, you can select specific ranks for each totem in the hover selection popup."
L["Show Unavailable Totems"] = "Show Unavailable Totems"
L["Show totems you haven't learned yet in the selector (grayed out)"] = "Show totems you haven't learned yet in the selector (grayed out)"
L["Default Totems"] = "Default Totems"
L["Choose the default totem for each element. These will be displayed on the totem bar."] = "Choose the default totem for each element. These will be displayed on the totem bar."
L["Earth Totem"] = "Earth Totem"
L["Fire Totem"] = "Fire Totem"
L["Water Totem"] = "Water Totem"
L["Air Totem"] = "Air Totem"
L["First Available"] = "First Available"
L["Totem"] = "Totem"
L["Default %s totem to display"] = "Default %s totem to display"

-- Elements
L["Earth"] = "Earth"
L["Fire"] = "Fire"
L["Water"] = "Water"
L["Air"] = "Air"

-- Modifiers Tab
L["Modifiers"] = "Modifiers"
L["Configure modifier key overrides for each element. When holding Shift, Ctrl, or Alt while clicking a totem tile, it will cast the configured override totem instead of the default.\n\nThis uses secure macros built when out of combat, so modifiers work during combat."] = "Configure modifier key overrides for each element. When holding Shift, Ctrl, or Alt while clicking a totem tile, it will cast the configured override totem instead of the default.\n\nThis uses secure macros built when out of combat, so modifiers work during combat."
L["Fire Totems"] = "Fire Totems"
L["Earth Totems"] = "Earth Totems"
L["Water Totems"] = "Water Totems"
L["Air Totems"] = "Air Totems"
L["Shift"] = "Shift"
L["Ctrl"] = "Ctrl"
L["Alt"] = "Alt"
L["+Click"] = "+Click"
L["Totem to cast when %s+clicking the %s tile"] = "Totem to cast when %s+clicking the %s tile"
L["Clear All Modifiers"] = "Clear All Modifiers"
L["Remove all modifier override assignments"] = "Remove all modifier override assignments"
L["Clear all modifier overrides?"] = "Clear all modifier overrides?"
L["Modifier overrides cleared. Macro updates will apply after combat ends."] = "Modifier overrides cleared. Macro updates will apply after combat ends."
L["All modifier overrides cleared."] = "All modifier overrides cleared."
L["None (disabled)"] = "None (disabled)"
L["Cannot update macros in combat. Changes will apply after combat ends."] = "Cannot update macros in combat. Changes will apply after combat ends."

-- Profiles
L["Profiles"] = "Profiles"

-- Messages
L["Locked"] = "locked"
L["Unlocked"] = "unlocked"
L["Position Reset"] = "Position reset"
L["Scan Complete"] = "Totem scan complete"
L["Totem scan complete"] = "Totem scan complete"
L["%s is now your default."] = "%s is now your default."
L["Cannot open selector during combat."] = "Cannot open selector during combat."
L["%s will be set as default when leaving combat."] = "%s will be set as default when leaving combat."
L["Options panel not available in this client."] = "Options panel not available in this client."
L["Failed to cast %s: %s"] = "Failed to cast %s: %s"

-- Tooltip hints
L["Cooldown: %s"] = "Cooldown: %s"
L["Click to queue as default (after combat)"] = "Click to queue as default (after combat)"
L["Click to set as default and cast"] = "Click to set as default and cast"
L["Click to set as default"] = "Click to set as default"
L["Not yet learned"] = "Not yet learned"
L["Requires level %d"] = "Requires level %d"
L["Visit a trainer to learn"] = "Visit a trainer to learn"

-- Make globally accessible with fallback metatable
setmetatable(L, {
    __index = function(t, k)
        -- Fallback: return the key itself if translation is missing
        return k
    end
})
TotemBuddy_L = L

-- Keybinding Localization (global variables required by WoW API)
BINDING_HEADER_TOTEMBUDDY = "TotemBuddy"

-- Cast Element Totems
BINDING_NAME_TOTEMBUDDY_CAST_FIRE = "Cast Fire Totem"
BINDING_NAME_TOTEMBUDDY_CAST_EARTH = "Cast Earth Totem"
BINDING_NAME_TOTEMBUDDY_CAST_WATER = "Cast Water Totem"
BINDING_NAME_TOTEMBUDDY_CAST_AIR = "Cast Air Totem"

-- Open Element Selectors
BINDING_NAME_TOTEMBUDDY_SELECT_FIRE = "Select Fire Totem"
BINDING_NAME_TOTEMBUDDY_SELECT_EARTH = "Select Earth Totem"
BINDING_NAME_TOTEMBUDDY_SELECT_WATER = "Select Water Totem"
BINDING_NAME_TOTEMBUDDY_SELECT_AIR = "Select Air Totem"

-- Set Cycling
BINDING_NAME_TOTEMBUDDY_NEXT_SET = "Next Totem Set"
BINDING_NAME_TOTEMBUDDY_PREV_SET = "Previous Totem Set"

-- Direct Set Access
BINDING_NAME_TOTEMBUDDY_SET_1 = "Activate Set 1"
BINDING_NAME_TOTEMBUDDY_SET_2 = "Activate Set 2"
BINDING_NAME_TOTEMBUDDY_SET_3 = "Activate Set 3"
BINDING_NAME_TOTEMBUDDY_SET_4 = "Activate Set 4"
BINDING_NAME_TOTEMBUDDY_SET_5 = "Activate Set 5"
