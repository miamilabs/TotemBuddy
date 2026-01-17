--[[
    TotemBuddy - Modifier Overrides Tab
    Configure Shift/Ctrl/Alt modifier totems for each element

    Enables secure macros that cast different totems based on modifier keys held:
    - No modifier: Default totem (from Totems tab)
    - Shift: Emergency/utility totem (e.g., Tremor Totem)
    - Ctrl: Alternative totem (e.g., Earthbind Totem)
    - Alt: Another alternative (e.g., Stoneclaw Totem)
]]

---@class ModifiersTab
local ModifiersTab = TotemBuddyLoader:CreateModule("ModifiersTab")
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local TotemData = nil
local SpellScanner = nil
local TotemBar = nil

-- Element names for display (localized)
local ElementNames = {L["Fire"], L["Earth"], L["Water"], L["Air"]}

--- Get the options table for this tab
---@return table options The AceConfig options table
function ModifiersTab:GetOptions()
    return {
        type = "group",
        name = L["Modifiers"],
        order = 4,
        args = {
            description = {
                type = "description",
                name = L["Configure modifier key overrides for each element. When holding Shift, Ctrl, or Alt while clicking a totem tile, it will cast the configured override totem instead of the default.\n\nThis uses secure macros built when out of combat, so modifiers work during combat."],
                order = 1,
                fontSize = "medium",
            },
            dividerFire = {
                type = "header",
                name = "|cFFFF6600" .. L["Fire Totems"] .. "|r",
                order = 10,
            },
            fireShift = self:CreateModifierDropdown(1, "shift", L["Shift"], 11),
            fireCtrl = self:CreateModifierDropdown(1, "ctrl", L["Ctrl"], 12),
            fireAlt = self:CreateModifierDropdown(1, "alt", L["Alt"], 13),
            dividerEarth = {
                type = "header",
                name = "|cFF996633" .. L["Earth Totems"] .. "|r",
                order = 20,
            },
            earthShift = self:CreateModifierDropdown(2, "shift", L["Shift"], 21),
            earthCtrl = self:CreateModifierDropdown(2, "ctrl", L["Ctrl"], 22),
            earthAlt = self:CreateModifierDropdown(2, "alt", L["Alt"], 23),
            dividerWater = {
                type = "header",
                name = "|cFF3399FF" .. L["Water Totems"] .. "|r",
                order = 30,
            },
            waterShift = self:CreateModifierDropdown(3, "shift", L["Shift"], 31),
            waterCtrl = self:CreateModifierDropdown(3, "ctrl", L["Ctrl"], 32),
            waterAlt = self:CreateModifierDropdown(3, "alt", L["Alt"], 33),
            dividerAir = {
                type = "header",
                name = "|cFFB8B8E6" .. L["Air Totems"] .. "|r",
                order = 40,
            },
            airShift = self:CreateModifierDropdown(4, "shift", L["Shift"], 41),
            airCtrl = self:CreateModifierDropdown(4, "ctrl", L["Ctrl"], 42),
            airAlt = self:CreateModifierDropdown(4, "alt", L["Alt"], 43),

            -- Earth Shield Targeting Section
            dividerEarthShield = {
                type = "header",
                name = "|cFF33FF33" .. L["Earth Shield Targeting"] .. "|r",
                order = 50,
            },
            earthShieldDesc = {
                type = "description",
                name = L["Configure which target Earth Shield casts on when holding modifier keys. Changes apply after leaving combat."],
                order = 51,
                fontSize = "medium",
            },
            earthShieldDefault = self:CreateTargetDropdown("noModifier", L["No Modifier (Default)"], 52),
            earthShieldShift = self:CreateTargetDropdown("shift", L["Shift+Click"], 53),
            earthShieldCtrl = self:CreateTargetDropdown("ctrl", L["Ctrl+Click"], 54),
            earthShieldAlt = self:CreateTargetDropdown("alt", L["Alt+Click"], 55),

            dividerActions = {
                type = "header",
                name = L["Actions"],
                order = 60,
            },
            clearAll = {
                type = "execute",
                name = L["Clear All Modifiers"],
                desc = L["Remove all modifier override assignments"],
                order = 61,
                confirm = true,
                confirmText = L["Clear all modifier overrides?"],
                func = function()
                    for element = 1, 4 do
                        TotemBuddy.db.profile.modifierOverrides[element] = {
                            default = nil,
                            shift = nil,
                            ctrl = nil,
                            alt = nil,
                        }
                    end
                    -- Batch combat check to avoid 4 separate error messages
                    if InCombatLockdown() then
                        TotemBuddy:Print(L["Modifier overrides cleared. Macro updates will apply after combat ends."])
                    else
                        self:RebuildAllMacros()
                        TotemBuddy:Print(L["All modifier overrides cleared."])
                    end
                end,
            },
        },
    }
end

--- Create a dropdown for selecting a modifier override totem
---@param element number The element (1-4)
---@param modifier string The modifier key ("shift", "ctrl", "alt")
---@param modifierName string Display name for the modifier
---@param order number Display order
---@return table option The AceConfig option table
function ModifiersTab:CreateModifierDropdown(element, modifier, modifierName, order)
    local elementName = ElementNames[element]

    return {
        type = "select",
        name = modifierName .. L["+Click"],
        desc = string.format(L["Totem to cast when %s+clicking the %s tile"], modifierName, elementName:lower()),
        order = order,
        values = function()
            -- Get modules
            if not TotemData then
                TotemData = TotemBuddyLoader:ImportModule("TotemData")
            end
            if not SpellScanner then
                SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
            end

            local values = {}
            values["__none__"] = L["None (disabled)"]

            if TotemData and SpellScanner then
                local totems = TotemData:GetTotemsForElement(element)
                for _, totem in ipairs(totems) do
                    -- Only show known totems
                    if SpellScanner:IsTotemKnown(totem) then
                        -- Get the highest rank spell ID for this totem
                        local spellId = SpellScanner:GetHighestRank(totem.name)
                        if spellId then
                            -- Use spellId as key, totem name as display
                            values[tostring(spellId)] = totem.name
                        end
                    end
                end
            end

            return values
        end,
        sorting = function()
            -- Custom sort: None first, then alphabetical
            if not TotemData then
                TotemData = TotemBuddyLoader:ImportModule("TotemData")
            end
            if not SpellScanner then
                SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
            end

            local sortOrder = {"__none__"}
            if TotemData and SpellScanner then
                local totems = TotemData:GetTotemsForElement(element)
                local items = {}
                for _, totem in ipairs(totems) do
                    if SpellScanner:IsTotemKnown(totem) then
                        local spellId = SpellScanner:GetHighestRank(totem.name)
                        if spellId then
                            table.insert(items, {name = totem.name, id = tostring(spellId)})
                        end
                    end
                end
                -- Sort by name
                table.sort(items, function(a, b) return a.name < b.name end)
                for _, item in ipairs(items) do
                    table.insert(sortOrder, item.id)
                end
            end
            return sortOrder
        end,
        get = function()
            local overrides = TotemBuddy.db.profile.modifierOverrides[element]
            if overrides and overrides[modifier] then
                return tostring(overrides[modifier])
            end
            return "__none__"
        end,
        set = function(_, value)
            -- Ensure the table exists
            if not TotemBuddy.db.profile.modifierOverrides[element] then
                TotemBuddy.db.profile.modifierOverrides[element] = {
                    default = nil,
                    shift = nil,
                    ctrl = nil,
                    alt = nil,
                }
            end

            if value == "__none__" then
                TotemBuddy.db.profile.modifierOverrides[element][modifier] = nil
            else
                TotemBuddy.db.profile.modifierOverrides[element][modifier] = tonumber(value)
            end

            -- Rebuild macros for this element
            self:RebuildMacroForElement(element)
        end,
    }
end

--- Rebuild secure macro for a single element tile
---@param element number The element index (1-4)
function ModifiersTab:RebuildMacroForElement(element)
    if InCombatLockdown() then
        TotemBuddy:Print(L["Cannot update macros in combat. Changes will apply after combat ends."])
        return
    end

    if not TotemBar then
        TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    end

    if TotemBar and TotemBar.tiles and TotemBar.tiles[element] then
        local TotemTile = TotemBuddyLoader:ImportModule("TotemTile")
        if TotemTile and TotemTile.RebuildMacro then
            TotemTile:RebuildMacro(TotemBar.tiles[element])
        end
    end
end

--- Rebuild secure macros for all element tiles
function ModifiersTab:RebuildAllMacros()
    for element = 1, 4 do
        self:RebuildMacroForElement(element)
    end
end

-- =============================================================================
-- EARTH SHIELD TARGETING
-- =============================================================================

--- Target values for Earth Shield targeting dropdowns
local TargetValues = {
    ["none"] = "Disabled",
    ["player"] = "Self",
    ["focus"] = "Focus",
    ["party1"] = "Party 1",
    ["party2"] = "Party 2",
    ["party3"] = "Party 3",
    ["party4"] = "Party 4",
    ["party5"] = "Party 5",
}

--- Sorting order for target dropdown
local TargetSorting = {"none", "player", "focus", "party1", "party2", "party3", "party4", "party5"}

--- Create a dropdown for selecting Earth Shield target
---@param key string The settings key ("noModifier", "shift", "ctrl", "alt")
---@param label string Display name for the dropdown
---@param order number Display order
---@return table option The AceConfig option table
function ModifiersTab:CreateTargetDropdown(key, label, order)
    return {
        type = "select",
        name = label,
        desc = string.format(L["Target for Earth Shield when %s is used"], label),
        order = order,
        values = function()
            local values = {}
            for k, v in pairs(TargetValues) do
                values[k] = L[v]
            end
            return values
        end,
        sorting = function()
            return TargetSorting
        end,
        get = function()
            local targeting = TotemBuddy.db.profile.earthShieldTargeting
            if targeting and targeting[key] then
                return targeting[key]
            end
            -- Defaults
            if key == "noModifier" then return "player" end
            if key == "shift" then return "focus" end
            return "none"
        end,
        set = function(_, value)
            -- Ensure the table exists
            if not TotemBuddy.db.profile.earthShieldTargeting then
                TotemBuddy.db.profile.earthShieldTargeting = {
                    noModifier = "player",
                    shift = "focus",
                    ctrl = "none",
                    alt = "none",
                }
            end

            TotemBuddy.db.profile.earthShieldTargeting[key] = value

            -- Rebuild shield macro
            self:RebuildShieldMacro()
        end,
    }
end

--- Rebuild the Earth Shield macro after settings change
function ModifiersTab:RebuildShieldMacro()
    if InCombatLockdown() then
        TotemBuddy:Print(L["Cannot update macros in combat. Changes will apply after combat ends."])
        return
    end

    -- Get TotemBar to access the shield tile
    if not TotemBar then
        TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    end

    if TotemBar and TotemBar.shieldTile then
        local ShieldTile = TotemBuddyLoader:ImportModule("ShieldTile")
        if ShieldTile then
            -- Re-set the shield to rebuild the macro
            local tile = TotemBar.shieldTile
            if tile and tile.spellId and tile.shieldData then
                tile:SetShield(tile.spellId, tile.shieldData)
            end
        end
    end
end

return ModifiersTab
