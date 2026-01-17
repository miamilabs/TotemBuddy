--[[
    TotemBuddy - General Settings Tab
    Basic enable/disable and general options
]]

---@class GeneralTab
local GeneralTab = TotemBuddyLoader:CreateModule("GeneralTab")
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

--- Get the options table for this tab
---@return table options The AceConfig options table
function GeneralTab:GetOptions()
    return {
        type = "group",
        name = L["General"],
        order = 1,
        args = {
            enabled = {
                type = "toggle",
                name = L["Enable TotemBuddy"],
                desc = L["Show or hide the totem bar"],
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
                name = L["Lock Position"],
                desc = L["Prevent the totem bar from being moved"],
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
                name = L["Show Tooltips"],
                desc = L["Show spell tooltips when hovering over totem tiles"],
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
                name = L["Display Options"],
                order = 10,
            },
            showCooldowns = {
                type = "toggle",
                name = L["Show Cooldowns"],
                desc = L["Display cooldown swipe on totem tiles"],
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
                name = L["Show Keybinds"],
                desc = L["Display keybind text on totem tiles"],
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
                name = L["Show Element Indicator"],
                desc = L["Display colored bar indicating totem element"],
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
                name = L["Timer Options"],
                order = 14,
            },
            showCooldownText = {
                type = "toggle",
                name = L["Show Cooldown Numbers"],
                desc = L["Display countdown numbers when a totem is on cooldown"],
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
                name = L["Show Active Duration"],
                desc = L["Display remaining time for active totems"],
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
                name = L["Show Active Glow"],
                desc = L["Display a glow effect when a totem is active"],
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
                name = L["Show Duration Bar"],
                desc = L["Display a progress bar showing remaining totem duration"],
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
                name = L["Duration Bar Height"],
                desc = L["Height of the duration progress bar in pixels"],
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
                name = L["Expiring Warning Threshold"],
                desc = L["Seconds remaining before totem is considered 'expiring soon' (triggers color change and pulse)"],
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
                name = L["Expiring Warning Color"],
                desc = L["Color for duration text and bar when totem is about to expire"],
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
                name = L["Selector Options"],
                order = 18,
            },
            showSelectorInCombat = {
                type = "toggle",
                name = L["Show Selector in Combat"],
                desc = L["Allow the totem selector popup to appear while in combat (note: you cannot change totems during combat)"],
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
                name = L["Lock Selector"],
                desc = L["When enabled, the totem selector only opens when holding Shift while hovering or right-clicking"],
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
                name = "|cff888888" .. L["Tip: Right-click a totem tile to quickly open the selector."] .. "|r",
                order = 20.1,
                fontSize = "medium",
            },
            divider1d = {
                type = "header",
                name = L["Selector Behavior"],
                order = 20.2,
            },
            castOnSelect = {
                type = "toggle",
                name = L["Cast on Select"],
                desc = L["When selecting a totem from the popup, immediately cast it in addition to setting it as the default. Only works out of combat."],
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
                name = L["Actions"],
                order = 21,
            },
            resetPosition = {
                type = "execute",
                name = L["Reset Position"],
                desc = L["Reset the totem bar to the center of the screen"],
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
                name = L["Rescan Totems"],
                desc = L["Rescan your spellbook for known totems"],
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
                    TotemBuddy:Print(L["Totem scan complete"])
                end,
            },
        },
    }
end

return GeneralTab
