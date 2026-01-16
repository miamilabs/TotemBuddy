--[[
    TotemBuddy - Totem Settings Tab
    Totem rank settings and default totem selection
]]

---@class TotemTab
local TotemTab = TotemBuddyLoader:CreateModule("TotemTab")

-- Module references
local TotemData = nil
local SpellScanner = nil

--- Get the options table for this tab
---@return table options The AceConfig options table
function TotemTab:GetOptions()
    return {
        type = "group",
        name = "Totems",
        order = 3,
        args = {
            useHighestRank = {
                type = "toggle",
                name = "Use Highest Rank",
                desc = "Always cast the highest rank of each totem you know. When disabled, you can choose specific ranks.",
                order = 1,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.useHighestRank
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.useHighestRank = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:RefreshAllTiles()
                    end
                end,
            },
            rankNote = {
                type = "description",
                name = "When 'Use Highest Rank' is disabled, you can select specific ranks for each totem in the hover selection popup.",
                order = 2,
                fontSize = "medium",
            },
            showUnavailable = {
                type = "toggle",
                name = "Show Unavailable Totems",
                desc = "Show totems you haven't learned yet in the selector (grayed out)",
                order = 3,
                get = function()
                    return TotemBuddy.db.profile.showUnavailable
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showUnavailable = value
                end,
            },
            divider1 = {
                type = "header",
                name = "Default Totems",
                order = 10,
            },
            defaultNote = {
                type = "description",
                name = "Choose the default totem for each element. These will be displayed on the totem bar.",
                order = 11,
                fontSize = "medium",
            },
            earthDefault = self:CreateTotemDropdown(1, "Earth", 12),
            fireDefault = self:CreateTotemDropdown(2, "Fire", 13),
            waterDefault = self:CreateTotemDropdown(3, "Water", 14),
            airDefault = self:CreateTotemDropdown(4, "Air", 15),
        },
    }
end

--- Create a dropdown for selecting default totem for an element
---@param element number The element (1-4)
---@param name string The element name
---@param order number The display order
---@return table option The AceConfig option table
function TotemTab:CreateTotemDropdown(element, name, order)
    return {
        type = "select",
        name = name .. " Totem",
        desc = "Default " .. name:lower() .. " totem to display",
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
            if TotemData then
                local totems = TotemData:GetTotemsForElement(element)
                for _, totem in ipairs(totems) do
                    -- Only show known totems
                    if SpellScanner and SpellScanner:IsTotemKnown(totem) then
                        values[totem.name] = totem.name
                    end
                end
            end

            -- Add "First Available" option
            values["__first__"] = "First Available"

            return values
        end,
        sorting = function()
            -- Custom sort: First Available first, then alphabetical
            if not TotemData then
                TotemData = TotemBuddyLoader:ImportModule("TotemData")
            end
            if not SpellScanner then
                SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
            end

            local order = {"__first__"}
            if TotemData then
                local totems = TotemData:GetTotemsForElement(element)
                local names = {}
                for _, totem in ipairs(totems) do
                    if SpellScanner and SpellScanner:IsTotemKnown(totem) then
                        table.insert(names, totem.name)
                    end
                end
                table.sort(names)
                for _, name in ipairs(names) do
                    table.insert(order, name)
                end
            end
            return order
        end,
        get = function()
            local saved = TotemBuddy.db.profile.defaultTotems[element]
            return saved or "__first__"
        end,
        set = function(_, value)
            if value == "__first__" then
                TotemBuddy.db.profile.defaultTotems[element] = nil
            else
                TotemBuddy.db.profile.defaultTotems[element] = value
            end

            local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
            if TotemBar then
                TotemBar:RefreshTile(element)
            end
        end,
    }
end

return TotemTab
