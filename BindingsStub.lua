--[[
    TotemBuddy - Keybinding Function Stubs

    This file provides stub functions for Bindings.xml.
    It MUST load before Bindings.xml in the TOC to ensure the binding
    functions exist when WoW parses the XML.

    The real implementations in TotemBuddy.lua will override these stubs.
]]

-- Binding header and names for Key Bindings UI
BINDING_HEADER_TOTEMBUDDY = "TotemBuddy"

-- Cast Element Totems
BINDING_NAME_TOTEMBUDDY_CAST_FIRE = "Cast Fire Totem"
BINDING_NAME_TOTEMBUDDY_CAST_EARTH = "Cast Earth Totem"
BINDING_NAME_TOTEMBUDDY_CAST_WATER = "Cast Water Totem"
BINDING_NAME_TOTEMBUDDY_CAST_AIR = "Cast Air Totem"

-- Open Selector
BINDING_NAME_TOTEMBUDDY_SELECT_FIRE = "Select Fire Totem"
BINDING_NAME_TOTEMBUDDY_SELECT_EARTH = "Select Earth Totem"
BINDING_NAME_TOTEMBUDDY_SELECT_WATER = "Select Water Totem"
BINDING_NAME_TOTEMBUDDY_SELECT_AIR = "Select Air Totem"

-- Set Management
BINDING_NAME_TOTEMBUDDY_NEXT_SET = "Next Totem Set"
BINDING_NAME_TOTEMBUDDY_PREV_SET = "Previous Totem Set"
BINDING_NAME_TOTEMBUDDY_SET_1 = "Activate Set 1"
BINDING_NAME_TOTEMBUDDY_SET_2 = "Activate Set 2"
BINDING_NAME_TOTEMBUDDY_SET_3 = "Activate Set 3"
BINDING_NAME_TOTEMBUDDY_SET_4 = "Activate Set 4"
BINDING_NAME_TOTEMBUDDY_SET_5 = "Activate Set 5"

-- Stub functions for keybindings (will be overwritten by TotemBuddy.lua)
if not TotemBuddy_CastElement then
    function TotemBuddy_CastElement(element)
        -- Stub: real implementation in TotemBuddy.lua
    end
end

if not TotemBuddy_SelectElement then
    function TotemBuddy_SelectElement(element)
        -- Stub: real implementation in TotemBuddy.lua
    end
end

if not TotemBuddy_CycleSet then
    function TotemBuddy_CycleSet(direction)
        -- Stub: real implementation in TotemBuddy.lua
    end
end

if not TotemBuddy_ActivateSet then
    function TotemBuddy_ActivateSet(index)
        -- Stub: real implementation in TotemBuddy.lua
    end
end
