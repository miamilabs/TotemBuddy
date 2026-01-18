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
            selectorRightClickEnabled = {
                type = "toggle",
                name = L["Right-Click Opens Selector"],
                desc = L["When Lock Selector is enabled, right-clicking still opens the selector menu"],
                order = 20.05,
                disabled = function() return not TotemBuddy.db.profile.lockSelector end,
                get = function()
                    return TotemBuddy.db.profile.selectorRightClickEnabled
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.selectorRightClickEnabled = value
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
            -- ===========================================
            -- EXTRA FEATURES
            -- ===========================================
            dividerExtras = {
                type = "header",
                name = L["Extra Features"],
                order = 25,
            },
            showCallOfTotems = {
                type = "toggle",
                name = L["Show Call of Totems"],
                desc = L["Display button(s) for Call of the Elements/Ancestors/Spirits spells"],
                order = 26,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.showCallOfTotems
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showCallOfTotems = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if InCombatLockdown() then
                            TotemBar.pendingExtrasUpdate = true
                            TotemBuddy:Print(L["Changes will apply after combat."])
                        else
                            TotemBar:UpdateExtrasVisibility()
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
                disabled = function()
                    return not TotemBuddy.HasAnyCallSpells
                end,
            },
            showWeaponImbues = {
                type = "toggle",
                name = L["Show Weapon Imbues"],
                desc = L["Display buttons for weapon enchantments (Rockbiter, Flametongue, Windfury, etc.)"],
                order = 27,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.showWeaponImbues
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showWeaponImbues = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if InCombatLockdown() then
                            TotemBar.pendingExtrasUpdate = true
                            TotemBuddy:Print(L["Changes will apply after combat."])
                        else
                            TotemBar:UpdateExtrasVisibility()
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
                disabled = function()
                    return not TotemBuddy.HasAnyImbueSpells
                end,
            },
            showImbueCombatGlow = {
                type = "toggle",
                name = L["Show Combat Glow"],
                desc = L["Show a pulsing glow warning when weapon imbue is about to expire during combat"],
                order = 27.1,
                get = function()
                    return TotemBuddy.db.profile.showImbueCombatGlow
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showImbueCombatGlow = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showWeaponImbues
                end,
            },
            imbueWarningThreshold = {
                type = "range",
                name = L["Imbue Warning Threshold"],
                desc = L["Seconds remaining before imbue is considered 'expiring soon' (triggers warning in combat)"],
                order = 27.2,
                min = 30,
                max = 300,
                step = 10,
                get = function()
                    return TotemBuddy.db.profile.imbueWarningThreshold
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.imbueWarningThreshold = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showWeaponImbues or not TotemBuddy.db.profile.showImbueCombatGlow
                end,
            },
            showShields = {
                type = "toggle",
                name = L["Show Shields"],
                desc = L["Display button for Lightning Shield, Water Shield, or Earth Shield"],
                order = 28,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.showShields
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showShields = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if InCombatLockdown() then
                            TotemBar.pendingExtrasUpdate = true
                            TotemBuddy:Print(L["Changes will apply after combat."])
                        else
                            TotemBar:UpdateExtrasVisibility()
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
                disabled = function()
                    return not TotemBuddy.HasAnyShieldSpells
                end,
            },
            -- DISABLED: Party member Earth Shield tracking options
            -- Uncomment these blocks to re-enable party ES tracking UI options
            --[[
            trackEarthShieldOnTargets = {
                type = "toggle",
                name = L["Track Earth Shield on Targets"],
                desc = L["Track Earth Shield when cast on party or raid members, showing charges and duration on the shield tile"],
                order = 28.1,
                get = function()
                    return TotemBuddy.db.profile.trackEarthShieldOnTargets
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.trackEarthShieldOnTargets = value
                    -- Refresh shield tile display
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
                        TotemBar.shieldTile:UpdateStatus()
                    end
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showShields
                end,
            },
            showEarthShieldTargetName = {
                type = "toggle",
                name = L["Show Earth Shield Target Name"],
                desc = L["Display the name of the player who has your Earth Shield on the shield tile"],
                order = 28.2,
                get = function()
                    return TotemBuddy.db.profile.showEarthShieldTargetName
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showEarthShieldTargetName = value
                    -- Refresh shield tile display
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
                        TotemBar.shieldTile:UpdateStatus()
                    end
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showShields or not TotemBuddy.db.profile.trackEarthShieldOnTargets
                end,
            },
            --]]
            extrasHint = {
                type = "description",
                name = "|cff888888" .. L["Note: Features are disabled if no spells are known. Use 'Rescan Totems' after learning new spells."] .. "|r",
                order = 29,
                fontSize = "medium",
            },
            -- ===========================================
            -- COOLDOWN TRACKER
            -- ===========================================
            dividerCooldowns = {
                type = "header",
                name = L["Cooldown Tracker"],
                order = 30,
            },
            showCooldownTracker = {
                type = "toggle",
                name = L["Show Cooldown Tracker"],
                desc = L["Display a tracker for important cooldowns like Reincarnation, Elemental Totems, and Bloodlust/Heroism"],
                order = 31,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.showCooldownTracker
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showCooldownTracker = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if InCombatLockdown() then
                            TotemBar.pendingExtrasUpdate = true
                            TotemBuddy:Print(L["Changes will apply after combat."])
                        else
                            TotemBar:UpdateCooldownTrackerVisibility()
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
            },
            showCooldownReadyGlow = {
                type = "toggle",
                name = L["Show Ready Glow"],
                desc = L["Display a glow effect when a tracked cooldown is ready to use"],
                order = 32,
                get = function()
                    return TotemBuddy.db.profile.showCooldownReadyGlow
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showCooldownReadyGlow = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showCooldownTracker
                end,
            },
            cooldownTrackerPosition = {
                type = "select",
                name = L["Tracker Position"],
                desc = L["Where to display the cooldown tracker relative to the totem bar"],
                order = 33,
                values = {
                    above = L["Above"],
                    below = L["Below"],
                    left = L["Left"],
                    right = L["Right"],
                },
                get = function()
                    return TotemBuddy.db.profile.cooldownTrackerPosition
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.cooldownTrackerPosition = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if not InCombatLockdown() then
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showCooldownTracker
                end,
            },
            cooldownTrackerTileSize = {
                type = "range",
                name = L["Tracker Tile Size"],
                desc = L["Size of individual cooldown tracker tiles"],
                order = 34,
                min = 20,
                max = 50,
                step = 2,
                get = function()
                    return TotemBuddy.db.profile.cooldownTrackerTileSize
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.cooldownTrackerTileSize = value
                    local CooldownTracker = TotemBuddyLoader:ImportModule("CooldownTracker")
                    if CooldownTracker then
                        CooldownTracker:UpdateTileSize(value)
                    end
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar and TotemBar.UpdateLayout then
                        TotemBar:UpdateLayout()
                    end
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showCooldownTracker
                end,
            },
            -- ===========================================
            -- TARGET DEBUFF TRACKER
            -- ===========================================
            dividerDebuffs = {
                type = "header",
                name = L["Target Debuff Tracker"],
                order = 35,
            },
            showDebuffTracker = {
                type = "toggle",
                name = L["Show Debuff Tracker"],
                desc = L["Display a tracker for your debuffs on the target (Flame Shock, Stormstrike, etc.)"],
                order = 36,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.showDebuffTracker
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showDebuffTracker = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if InCombatLockdown() then
                            TotemBar.pendingExtrasUpdate = true
                            TotemBuddy:Print(L["Changes will apply after combat."])
                        else
                            TotemBar:UpdateDebuffTrackerVisibility()
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
            },
            debuffTrackerPosition = {
                type = "select",
                name = L["Debuff Tracker Position"],
                desc = L["Where to display the debuff tracker relative to the totem bar"],
                order = 37,
                values = {
                    above = L["Above"],
                    below = L["Below"],
                    left = L["Left"],
                    right = L["Right"],
                },
                get = function()
                    return TotemBuddy.db.profile.debuffTrackerPosition
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.debuffTrackerPosition = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if not InCombatLockdown() then
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showDebuffTracker
                end,
            },
            debuffWarningThreshold = {
                type = "range",
                name = L["Debuff Warning Threshold"],
                desc = L["Seconds remaining before debuff is considered 'expiring soon' (triggers warning color)"],
                order = 38,
                min = 1,
                max = 10,
                step = 1,
                get = function()
                    return TotemBuddy.db.profile.debuffWarningThreshold
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.debuffWarningThreshold = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showDebuffTracker
                end,
            },
            -- ===========================================
            -- PROC TRACKER
            -- ===========================================
            dividerProcs = {
                type = "header",
                name = L["Proc Tracker"],
                order = 38.5,
            },
            showProcTracker = {
                type = "toggle",
                name = L["Show Proc Tracker"],
                desc = L["Display a tracker for proc effects (Clearcasting, Nature's Swiftness, etc.)"],
                order = 38.6,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.showProcTracker
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.showProcTracker = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if InCombatLockdown() then
                            TotemBar.pendingExtrasUpdate = true
                            TotemBuddy:Print(L["Changes will apply after combat."])
                        else
                            TotemBar:UpdateProcTrackerVisibility()
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
            },
            procTrackerPosition = {
                type = "select",
                name = L["Proc Tracker Position"],
                desc = L["Where to display the proc tracker relative to the totem bar"],
                order = 38.7,
                values = {
                    above = L["Above"],
                    below = L["Below"],
                    left = L["Left"],
                    right = L["Right"],
                },
                get = function()
                    return TotemBuddy.db.profile.procTrackerPosition
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.procTrackerPosition = value
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        if not InCombatLockdown() then
                            TotemBar:UpdateLayout()
                        end
                    end
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.showProcTracker
                end,
            },

            -- ===========================================
            -- WARNING SYSTEM
            -- ===========================================
            dividerWarnings = {
                type = "header",
                name = L["Warning System"],
                order = 39,
            },
            warningsEnabled = {
                type = "toggle",
                name = L["Enable Warnings"],
                desc = L["Enable the warning system for expiring effects and missing buffs"],
                order = 39.1,
                width = "full",
                get = function()
                    return TotemBuddy.db.profile.warningsEnabled
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.warningsEnabled = value
                end,
            },
            warningSoundsEnabled = {
                type = "toggle",
                name = L["Enable Warning Sounds"],
                desc = L["Play sound alerts for warnings"],
                order = 39.2,
                get = function()
                    return TotemBuddy.db.profile.warningSoundsEnabled
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.warningSoundsEnabled = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.warningsEnabled
                end,
            },
            warningsOnlyInCombat = {
                type = "toggle",
                name = L["Warnings Only in Combat"],
                desc = L["Only trigger warnings while in combat"],
                order = 39.3,
                get = function()
                    return TotemBuddy.db.profile.warningsOnlyInCombat
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.warningsOnlyInCombat = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.warningsEnabled
                end,
            },
            warningCooldown = {
                type = "range",
                name = L["Warning Cooldown"],
                desc = L["Minimum seconds between repeated warnings for the same effect"],
                order = 39.4,
                min = 1,
                max = 30,
                step = 1,
                get = function()
                    return TotemBuddy.db.profile.warningCooldown
                end,
                set = function(_, value)
                    TotemBuddy.db.profile.warningCooldown = value
                end,
                disabled = function()
                    return not TotemBuddy.db.profile.warningsEnabled
                end,
            },

            -- ===========================================
            -- ACTIONS
            -- ===========================================
            divider2 = {
                type = "header",
                name = L["Actions"],
                order = 40,
            },
            resetPosition = {
                type = "execute",
                name = L["Reset Position"],
                desc = L["Reset the totem bar to the center of the screen"],
                order = 41,
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
                desc = L["Rescan your spellbook for known totems, imbues, shields, and call spells"],
                order = 42,
                func = function()
                    -- Scan totems
                    local SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
                    if SpellScanner then
                        SpellScanner:ScanTotems()
                    end

                    -- Scan extras (Call, Imbues, Shields)
                    local ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
                    if ExtrasScanner then
                        ExtrasScanner:ScanAllExtras()
                    end

                    -- Refresh UI
                    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                    if TotemBar then
                        TotemBar:RefreshAllTiles()
                        if TotemBar.RefreshAllExtras then
                            TotemBar:RefreshAllExtras()
                        end
                    end

                    TotemBuddy:Print(L["Totem scan complete"])
                end,
            },
        },
    }
end

return GeneralTab
