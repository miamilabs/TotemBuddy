--[[
    TotemBuddy - General Settings Tab
    Basic enable/disable and general options
]]

---@class GeneralTab
local GeneralTab = TotemBuddyLoader:CreateModule("GeneralTab")

--- Get the options table for this tab
---@return table options The AceConfig options table
function GeneralTab:GetOptions()
    return {
        type = "group",
        name = "General",
        order = 1,
        args = {
            enabled = {
                type = "toggle",
                name = "Enable TotemBuddy",
                desc = "Show or hide the totem bar",
                order = 1,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.enabled
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.enabled = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if value then
                            TotemBar:Show()
                        else
                            TotemBar:Hide()
                        end
                    end
                end,
            },
            locked = {
                type = "toggle",
                name = "Lock Position",
                desc = "Prevent the totem bar from being moved",
                order = 2,
                get = function()
                    return TotemBuddy.db.profile.locked
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.locked = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:SetLocked(value)
                    end
                end,
            },
            showTooltips = {
                type = "toggle",
                name = "Show Tooltips",
                desc = "Show spell tooltips when hovering over totem tiles",
                order = 3,
                get = function()
                    return TotemBuddy.db.profile.showTooltips
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showTooltips = value
                end,
            },
            divider1 = {
                type = "header",
                name = "Display Options",
                order = 10,
            },
            showCooldowns = {
                type = "toggle",
                name = "Show Cooldowns",
                desc = "Display cooldown swipe on totem tiles",
                order = 11,
                get = function()
                    return TotemBuddy.db.profile.showCooldowns
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showCooldowns = value
                end,
            },
            showKeybinds = {
                type = "toggle",
                name = "Show Keybinds",
                desc = "Display keybind text on totem tiles",
                order = 12,
                get = function()
                    return TotemBuddy.db.profile.showKeybinds
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showKeybinds = value
                end,
            },
            showElementIndicator = {
                type = "toggle",
                name = "Show Element Indicator",
                desc = "Display colored bar indicating totem element",
                order = 13,
                get = function()
                    return TotemBuddy.db.profile.showElementIndicator
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showElementIndicator = value
                end,
            },
            divider1b = {
                type = "header",
                name = "Timer Options",
                order = 14,
            },
            showCooldownText = {
                type = "toggle",
                name = "Show Cooldown Numbers",
                desc = "Display countdown numbers when a totem is on cooldown",
                order = 15,
                get = function()
                    return TotemBuddy.db.profile.showCooldownText
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showCooldownText = value
                end,
            },
            showDurationText = {
                type = "toggle",
                name = "Show Active Duration",
                desc = "Display remaining time for active totems",
                order = 16,
                get = function()
                    return TotemBuddy.db.profile.showDurationText
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showDurationText = value
                end,
            },
            showActiveGlow = {
                type = "toggle",
                name = "Show Active Glow",
                desc = "Display a glow effect when a totem is active",
                order = 17,
                get = function()
                    return TotemBuddy.db.profile.showActiveGlow
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showActiveGlow = value
                end,
            },
            showDurationBar = {
                type = "toggle",
                name = "Show Duration Bar",
                desc = "Display a progress bar showing remaining totem duration",
                order = 17.1,
                get = function()
                    return TotemBuddy.db.profile.showDurationBar
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showDurationBar = value
                end,
            },
            durationBarHeight = {
                type = "range",
                name = "Duration Bar Height",
                desc = "Height of the duration progress bar in pixels",
                order = 17.2,
                min = 2,
                max = 10,
                step = 1,
                disabled = function() return not TotemBuddy.db.profile.showDurationBar end,
                get = function()
                    return TotemBuddy.db.profile.durationBarHeight
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.durationBarHeight = value
                    -- Update all tiles
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar and TotemBar.UpdateAllTileSizes then
                        TotemBar:UpdateAllTileSizes()
                    end
                end,
            },
            expiringThreshold = {
                type = "range",
                name = "Expiring Warning Threshold",
                desc = "Seconds remaining before totem is considered 'expiring soon' (triggers color change and pulse)",
                order = 17.3,
                min = 3,
                max = 30,
                step = 1,
                get = function()
                    return TotemBuddy.db.profile.expiringThreshold
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.expiringThreshold = value
                end,
            },
            expiringColor = {
                type = "color",
                name = "Expiring Warning Color",
                desc = "Color for duration text and bar when totem is about to expire",
                order = 17.4,
                hasAlpha = false,
                get = function()
                    local c = TotemBuddy.db.profile.expiringColor or {1, 0.8, 0}
                    return c[1], c[2], c[3]
                end,
                set = function(_, r, g, b)
                    TotemBuddy.db.profile.expiringColor = {r, g, b}
                end,
            },
            divider1c = {
                type = "header",
                name = "Selector Options",
                order = 18,
            },
            showSelectorInCombat = {
                type = "toggle",
                name = "Show Selector in Combat",
                desc = "Allow the totem selector popup to appear while in combat (note: you cannot change totems during combat)",
                order = 19,
                get = function()
                    return TotemBuddy.db.profile.showSelectorInCombat
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showSelectorInCombat = value
                end,
            },
            lockSelector = {
                type = "toggle",
                name = "Lock Selector",
                desc = "When enabled, the totem selector only opens when holding Shift while hovering or right-clicking",
                order = 20,
                get = function()
                    return TotemBuddy.db.profile.lockSelector
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.lockSelector = value
                end,
            },
            selectorHint = {
                type = "description",
                name = "|cff888888Tip: Right-click a totem tile to quickly open the selector.|r",
                order = 20.1,
                fontSize = "medium",
            },
            divider1d = {
                type = "header",
                name = "Selector Behavior",
                order = 20.2,
            },
            castOnSelect = {
                type = "toggle",
                name = "Cast on Select",
                desc = "When selecting a totem from the popup, immediately cast it in addition to setting it as the default. Only works out of combat.",
                order = 20.3,
                get = function()
                    return TotemBuddy.db.profile.castOnSelect
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.castOnSelect = value
                end,
            },
            divider2 = {
                type = "header",
                name = "Actions",
                order = 21,
            },
            resetPosition = {
                type = "execute",
                name = "Reset Position",
                desc = "Reset the totem bar to the center of the screen",
                order = 21,
                func = function()
                    TotemBuddy.db.profile.posX = 0
                    TotemBuddy.db.profile.posY = -200
                    TotemBuddy.db.profile.anchor = "CENTER"
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:RestorePosition()
                    end
                end,
            },
            rescanTotems = {
                type = "execute",
                name = "Rescan Totems",
                desc = "Rescan your spellbook for known totems",
                order = 22,
                func = function()
                    local SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
                    if SpellScanner then
                        SpellScanner:ScanTotems()
                    end
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:RefreshAllTiles()
                    end
                    TotemBuddy:Print("Totem scan complete")
                end,
            },
        },
    }
end

return GeneralTab
