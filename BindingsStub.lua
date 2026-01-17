--[[
    TotemBuddy - Keybinding Function Stubs

    This file provides stub functions for Bindings.xml.
    It MUST load before Bindings.xml in the TOC to ensure the binding
    functions exist when WoW parses the XML.

    The real implementations in TotemBuddy.lua will override these stubs.
]]

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
