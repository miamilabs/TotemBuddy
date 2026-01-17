--[[
    TotemBuddy - Layout Settings Tab
    Layout, size, and appearance options
]]

---@class LayoutTab
local LayoutTab = TotemBuddyLoader:CreateModule("LayoutTab")
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

--- Get the options table for this tab
---@return table options The AceConfig options table
function LayoutTab:GetOptions()
    return {
        type = "group",
        name = L["Layout"],
        order = 2,
        args = {
            layout = {
                type = "select",
                name = L["Bar Layout"],
                desc = L["Choose how totem tiles are arranged"],
                order = 1,
                values = {
                    horizontal = L["Horizontal"],
                    vertical = L["Vertical"],
                    grid2x2 = L["2x2 Grid"],
                },
                get = function()
                    return TotemBuddy.db.profile.layout
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.layout = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:UpdateLayout()
                    end
                end,
            },
            divider1 = {
                type = "header",
                name = L["Size"],
                order = 10,
            },
            scale = {
                type = "range",
                name = L["Scale"],
                desc = L["Overall scale of the totem bar"],
                order = 11,
                min = 0.5,
                max = 2.0,
                step = 0.05,
                isPercent = false,
                get = function()
                    return TotemBuddy.db.profile.scale
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.scale = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:SetScale(value)
                    end
                end,
            },
            tileSize = {
                type = "range",
                name = L["Tile Size"],
                desc = L["Size of individual totem tiles"],
                order = 12,
                min = 24,
                max = 64,
                step = 1,
                get = function()
                    return TotemBuddy.db.profile.tileSize
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.tileSize = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:UpdateLayout()
                    end
                end,
            },
            tileSpacing = {
                type = "range",
                name = L["Tile Spacing"],
                desc = L["Space between totem tiles"],
                order = 13,
                min = 0,
                max = 16,
                step = 1,
                get = function()
                    return TotemBuddy.db.profile.tileSpacing
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.tileSpacing = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:UpdateLayout()
                    end
                end,
            },
            divider2 = {
                type = "header",
                name = L["Appearance"],
                order = 20,
            },
            showBorder = {
                type = "toggle",
                name = L["Show Border"],
                desc = L["Show a border around the totem bar"],
                order = 21,
                get = function()
                    return TotemBuddy.db.profile.showBorder
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showBorder = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:SetBorderVisible(value)
                    end
                end,
            },
            backgroundColor = {
                type = "color",
                name = L["Background Color"],
                desc = L["Background color of the totem bar"],
                order = 22,
                hasAlpha = true,
                get = function()
                    local c = TotemBuddy.db.profile.backgroundColor
                    return c[1], c[2], c[3], c[4]
                end,
                set = function(_, r, g, b, a)
                    TotemBuddy.db.profile.backgroundColor = {r, g, b, a}
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar and TotemBar.frame then
                        TotemBar.frame:SetBackdropColor(r, g, b, a)
                    end
                end,
            },
            divider3 = {
                type = "header",
                name = L["Selector Popup"],
                order = 30,
            },
            selectorPosition = {
                type = "select",
                name = L["Selector Position"],
                desc = L["Where the totem selection popup appears"],
                order = 31,
                values = {
                    above = L["Above"],
                    below = L["Below"],
                    left = L["Left"],
                    right = L["Right"],
                },
                get = function()
                    return TotemBuddy.db.profile.selectorPosition
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.selectorPosition = value
                end,
            },
            selectorColumns = {
                type = "range",
                name = L["Selector Columns"],
                desc = L["Number of columns in the totem selector popup"],
                order = 32,
                min = 2,
                max = 6,
                step = 1,
                get = function()
                    return TotemBuddy.db.profile.selectorColumns
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.selectorColumns = value
                end,
            },
            selectorScale = {
                type = "range",
                name = L["Selector Scale"],
                desc = L["Scale of the totem selector popup"],
                order = 33,
                min = 0.5,
                max = 2.0,
                step = 0.05,
                get = function()
                    return TotemBuddy.db.profile.selectorScale
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.selectorScale = value
                end,
            },
        },
    }
end

return LayoutTab
