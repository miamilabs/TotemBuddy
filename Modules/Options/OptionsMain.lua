--[[
    TotemBuddy - Options Main Module
    Manages the settings panel registration with AceConfig
]]

---@class OptionsMain
local OptionsMain = TotemBuddyLoader:CreateModule("OptionsMain")

-- Module references
local GeneralTab = nil
local LayoutTab = nil
local TotemTab = nil
local ModifiersTab = nil

--- Initialize the options panel
function OptionsMain:Initialize()
    -- Get tab modules
    GeneralTab = TotemBuddyLoader:ImportModule("GeneralTab")
    LayoutTab = TotemBuddyLoader:ImportModule("LayoutTab")
    TotemTab = TotemBuddyLoader:ImportModule("TotemTab")
    ModifiersTab = TotemBuddyLoader:ImportModule("ModifiersTab")

    -- Build the main options table
    local options = {
        type = "group",
        name = "TotemBuddy",
        childGroups = "tab",
        args = {},
    }

    -- Add tabs
    if GeneralTab then
        options.args.general = GeneralTab:GetOptions()
    end

    if LayoutTab then
        options.args.layout = LayoutTab:GetOptions()
    end

    if TotemTab then
        options.args.totems = TotemTab:GetOptions()
    end

    if ModifiersTab then
        options.args.modifiers = ModifiersTab:GetOptions()
    end

    -- Add profiles tab (from AceDBOptions)
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(TotemBuddy.db)
    options.args.profiles.order = 100

    -- Register with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TotemBuddy", options)

    -- Add to Blizzard options
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TotemBuddy", "TotemBuddy")

    -- Note: Slash commands are registered in TotemBuddy.lua to avoid duplicates
end

--- Open the options panel
function OptionsMain:Open()
    -- Try new Settings API first (10.0+), fall back to InterfaceOptionsFrame
    if type(Settings) == "table" and Settings.OpenToCategory then
        Settings.OpenToCategory("TotemBuddy")
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)  -- Call twice due to Blizzard bug
    else
        TotemBuddy:Print("Options panel not available in this client.")
    end
end

--- Refresh the options panel (after profile change, etc.)
function OptionsMain:Refresh()
    -- Force AceConfig to re-read all options
    LibStub("AceConfigRegistry-3.0"):NotifyChange("TotemBuddy")
end

return OptionsMain
