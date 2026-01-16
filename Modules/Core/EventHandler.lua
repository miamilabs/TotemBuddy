--[[
    TotemBuddy - Event Handler Module
    Manages WoW event registration and handling
]]

---@class EventHandler
local EventHandler = TotemBuddyLoader:CreateModule("EventHandler")
local _EventHandler = EventHandler.private

-- Module references (resolved on first use)
local SpellScanner = nil
local TotemBar = nil
local TotemSelector = nil

-- Throttling state
_EventHandler.cooldownDebounce = nil
_EventHandler.lastCooldownUpdate = 0
_EventHandler.pendingRefresh = false

--- Safe event handler wrapper (prevents errors from breaking addon)
---@param handlerName string Name of the handler for error logging
---@param handler function The actual handler function
---@return function wrappedHandler A pcall-wrapped version
local function SafeHandler(handlerName, handler)
    return function(...)
        local ok, err = pcall(handler, ...)
        if not ok then
            if TotemBuddy and TotemBuddy.Print then
                TotemBuddy:Print("|cffff0000Error in " .. handlerName .. ":|r " .. tostring(err))
            end
        end
    end
end

--- Get module references (lazy load)
local function GetModules()
    if not SpellScanner then
        SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
    end
    if not TotemBar then
        TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    end
    if not TotemSelector then
        TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")
    end
end

--- Register all events
function EventHandler:RegisterEvents()
    GetModules()

    -- Player entering world (ensures spellbook is ready)
    TotemBuddy:RegisterEvent("PLAYER_ENTERING_WORLD", SafeHandler("PLAYER_ENTERING_WORLD", function()
        _EventHandler:OnPlayerEnteringWorld()
    end))

    -- Spells changed (backup for when spellbook updates)
    TotemBuddy:RegisterEvent("SPELLS_CHANGED", SafeHandler("SPELLS_CHANGED", function()
        _EventHandler:OnSpellsChanged()
    end))

    -- Combat events (for lockdown handling)
    TotemBuddy:RegisterEvent("PLAYER_REGEN_DISABLED", SafeHandler("PLAYER_REGEN_DISABLED", function()
        _EventHandler:OnEnterCombat()
    end))

    TotemBuddy:RegisterEvent("PLAYER_REGEN_ENABLED", SafeHandler("PLAYER_REGEN_ENABLED", function()
        _EventHandler:OnLeaveCombat()
    end))

    -- Spell learning events (to update known totems)
    TotemBuddy:RegisterEvent("LEARNED_SPELL_IN_TAB", SafeHandler("LEARNED_SPELL_IN_TAB", function(_, spellId)
        _EventHandler:OnSpellLearned(spellId)
    end))

    -- Cooldown tracking
    TotemBuddy:RegisterEvent("SPELL_UPDATE_COOLDOWN", SafeHandler("SPELL_UPDATE_COOLDOWN", function()
        _EventHandler:OnCooldownUpdate()
    end))

    -- Totem events
    TotemBuddy:RegisterEvent("PLAYER_TOTEM_UPDATE", SafeHandler("PLAYER_TOTEM_UPDATE", function(_, slot)
        _EventHandler:OnTotemUpdate(slot)
    end))

    -- Character level up (might unlock new totems)
    TotemBuddy:RegisterEvent("PLAYER_LEVEL_UP", SafeHandler("PLAYER_LEVEL_UP", function()
        _EventHandler:OnLevelUp()
    end))
end

--- Called when player enters the world (login, reload, zone change)
function _EventHandler:OnPlayerEnteringWorld()
    GetModules()

    -- Small delay to ensure spellbook is fully loaded
    C_Timer.After(0.5, function()
        -- Rescan totems
        if SpellScanner then
            SpellScanner:ScanTotems()
        end

        -- Refresh UI with saved totems
        if TotemBar then
            if not TotemBar.frame then
                TotemBar:Create()
            end
            TotemBar:RefreshAllTiles()

            -- Show if enabled
            if TotemBuddy.db.profile.enabled then
                TotemBar:Show()
            end
        end
    end)
end

--- Called when spells change (backup handler)
function _EventHandler:OnSpellsChanged()
    GetModules()

    -- Rescan totems in case new ones were learned
    if SpellScanner then
        SpellScanner:ScanTotems()
    end

    -- Refresh if not in combat
    if not InCombatLockdown() and TotemBar and TotemBar.frame then
        TotemBar:RefreshAllTiles()
    end
end

--- Called when entering combat
function _EventHandler:OnEnterCombat()
    GetModules()

    -- Hide the totem selector (can't modify secure frames in combat)
    if TotemSelector and TotemSelector.Hide then
        TotemSelector:Hide()
    end

    -- Lock the totem bar during combat
    if TotemBar and TotemBar.SetLocked then
        TotemBar:SetLocked(true)
    end
end

--- Called when leaving combat
function _EventHandler:OnLeaveCombat()
    GetModules()

    -- Restore lock state based on settings
    if TotemBar and TotemBar.SetLocked then
        TotemBar:SetLocked(TotemBuddy.db.profile.locked)
    end

    -- Process any pending updates
    _EventHandler:ProcessPendingUpdates()
end

--- Called when a new spell is learned
---@param spellId number The learned spell ID
function _EventHandler:OnSpellLearned(spellId)
    GetModules()

    -- Check if this is a totem spell
    local TotemData = TotemBuddyLoader:ImportModule("TotemData")
    if TotemData and TotemData:IsTotemSpell(spellId) then
        -- Rescan totems to update cache
        if SpellScanner then
            SpellScanner:ScanTotems()
        end

        -- Refresh the UI if not in combat
        if not InCombatLockdown() and TotemBar then
            TotemBar:RefreshAllTiles()
        else
            -- Queue for later
            _EventHandler.pendingRefresh = true
        end
    end
end

--- Called when spell cooldowns update (throttled to prevent excessive updates)
function _EventHandler:OnCooldownUpdate()
    local now = GetTime()
    local THROTTLE_INTERVAL = 0.15  -- Update at most every 150ms

    -- If we updated recently, debounce
    if now - _EventHandler.lastCooldownUpdate < THROTTLE_INTERVAL then
        -- Schedule one update if not already scheduled
        if not _EventHandler.cooldownDebounce then
            _EventHandler.cooldownDebounce = C_Timer.NewTimer(THROTTLE_INTERVAL, function()
                _EventHandler.cooldownDebounce = nil
                _EventHandler.lastCooldownUpdate = GetTime()
                GetModules()
                if TotemBar and TotemBar.UpdateCooldowns then
                    TotemBar:UpdateCooldowns()
                end
            end)
        end
        return
    end

    -- Immediate update
    _EventHandler.lastCooldownUpdate = now
    GetModules()

    if TotemBar and TotemBar.UpdateCooldowns then
        TotemBar:UpdateCooldowns()
    end
end

--- Called when a totem slot updates
---@param slot number The totem slot (1-4)
function _EventHandler:OnTotemUpdate(slot)
    GetModules()

    -- Could be used to show active totem indicators
    if TotemBar and TotemBar.UpdateTotemSlot then
        TotemBar:UpdateTotemSlot(slot)
    end
end

--- Called when player levels up
function _EventHandler:OnLevelUp()
    GetModules()

    -- Some totems are level-gated, but WoW handles learning automatically
    -- Just rescan to be safe
    if SpellScanner then
        SpellScanner:ScanTotems()
    end
end

--- Process pending updates (called after leaving combat)
function _EventHandler:ProcessPendingUpdates()
    GetModules()

    -- Apply any pending attribute changes to tiles
    if TotemBar and TotemBar.tiles then
        for _, tile in ipairs(TotemBar.tiles) do
            if tile.ApplyPendingAttributes then
                tile:ApplyPendingAttributes()
            end
        end
    end

    -- Refresh tiles if a refresh was queued during combat
    if _EventHandler.pendingRefresh then
        _EventHandler.pendingRefresh = false
        if TotemBar then
            TotemBar:RefreshAllTiles()
        end
    end
end

--- Cleanup function (called when addon is disabled)
--- Cancels any pending timers to prevent errors after disable
function EventHandler:Cleanup()
    -- Cancel cooldown debounce timer
    if _EventHandler.cooldownDebounce then
        _EventHandler.cooldownDebounce:Cancel()
        _EventHandler.cooldownDebounce = nil
    end

    -- Reset state
    _EventHandler.pendingRefresh = false
    _EventHandler.lastCooldownUpdate = 0
end

return EventHandler
