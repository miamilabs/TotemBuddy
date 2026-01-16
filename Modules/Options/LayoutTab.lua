--[[
    TotemBuddy - Layout Settings Tab
    Layout, size, and appearance options
]]

---@class LayoutTab
local LayoutTab = TotemBuddyLoader:CreateModule("LayoutTab")

--- Get the options table for this tab
---@return table options The AceConfig options table
function LayoutTab:GetOptions()
    return {
        type = "group",
        name = "Layout",
        order = 2,
        args = {
            layout = {
                type = "select",
                name = "Bar Layout",
                desc = "Choose how totem tiles are arranged",
                order = 1,
                values = {
                    horizontal = "Horizontal",
                    vertical = "Vertical",
                    grid2x2 = "2x2 Grid",
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
                name = "Size",
                order = 10,
            },
            scale = {
                type = "range",
                name = "Scale",
                desc = "Overall scale of the totem bar",
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
                name = "Tile Size",
                desc = "Size of individual totem tiles",
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
                name = "Tile Spacing",
                desc = "Space between totem tiles",
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
                name = "Appearance",
                order = 20,
            },
            showBorder = {
                type = "toggle",
                name = "Show Border",
                desc = "Show a border around the totem bar",
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
                name = "Background Color",
                desc = "Background color of the totem bar",
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
                name = "Selector Popup",
                order = 30,
            },
            selectorPosition = {
                type = "select",
                name = "Selector Position",
                desc = "Where the totem selection popup appears",
                order = 31,
                values = {
                    above = "Above",
                    below = "Below",
                    left = "Left",
                    right = "Right",
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
                name = "Selector Columns",
                desc = "Number of columns in the totem selector popup",
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
                name = "Selector Scale",
                desc = "Scale of the totem selector popup",
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
