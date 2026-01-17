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

-- Module references
local TotemData = nil
local SpellScanner = nil
local TotemBar = nil

-- Element names for display
local ElementNames = {"Fire", "Earth", "Water", "Air"}

--- Get the options table for this tab
---@return table options The AceConfig options table
function ModifiersTab:GetOptions()
    return {
        type = "group",
        name = "Modifiers",
        order = 4,
        args = {
            description = {
                type = "description",
                name = "Configure modifier key overrides for each element. When holding Shift, Ctrl, or Alt while clicking a totem tile, it will cast the configured override totem instead of the default.\n\nThis uses secure macros built when out of combat, so modifiers work during combat.",
                order = 1,
                fontSize = "medium",
            },
            dividerFire = {
                type = "header",
                name = "|cFFFF6600Fire Totems|r",
                order = 10,
            },
            fireShift = self:CreateModifierDropdown(1, "shift", "Shift", 11),
            fireCtrl = self:CreateModifierDropdown(1, "ctrl", "Ctrl", 12),
            fireAlt = self:CreateModifierDropdown(1, "alt", "Alt", 13),
            dividerEarth = {
                type = "header",
                name = "|cFF996633Earth Totems|r",
                order = 20,
            },
            earthShift = self:CreateModifierDropdown(2, "shift", "Shift", 21),
            earthCtrl = self:CreateModifierDropdown(2, "ctrl", "Ctrl", 22),
            earthAlt = self:CreateModifierDropdown(2, "alt", "Alt", 23),
            dividerWater = {
                type = "header",
                name = "|cFF3399FFWater Totems|r",
                order = 30,
            },
            waterShift = self:CreateModifierDropdown(3, "shift", "Shift", 31),
            waterCtrl = self:CreateModifierDropdown(3, "ctrl", "Ctrl", 32),
            waterAlt = self:CreateModifierDropdown(3, "alt", "Alt", 33),
            dividerAir = {
                type = "header",
                name = "|cFFB8B8E6Air Totems|r",
                order = 40,
            },
            airShift = self:CreateModifierDropdown(4, "shift", "Shift", 41),
            airCtrl = self:CreateModifierDropdown(4, "ctrl", "Ctrl", 42),
            airAlt = self:CreateModifierDropdown(4, "alt", "Alt", 43),
            dividerActions = {
                type = "header",
                name = "Actions",
                order = 50,
            },
            clearAll = {
                type = "execute",
                name = "Clear All Modifiers",
                desc = "Remove all modifier override assignments",
                order = 51,
                confirm = true,
                confirmText = "Clear all modifier overrides?",
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
                        TotemBuddy:Print("Modifier overrides cleared. Macro updates will apply after combat ends.")
                    else
                        self:RebuildAllMacros()
                        TotemBuddy:Print("All modifier overrides cleared.")
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
        name = modifierName .. "+Click",
        desc = "Totem to cast when " .. modifierName .. "+clicking the " .. elementName:lower() .. " tile",
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
            values["__none__"] = "None (disabled)"

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
        TotemBuddy:Print("Cannot update macros in combat. Changes will apply after combat ends.")
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

return ModifiersTab
