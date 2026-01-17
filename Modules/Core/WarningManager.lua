--[[
    TotemBuddy - Warning Manager Module
    Provides centralized warning system for various conditions:
    - Totem expiring/destroyed
    - Shield about to expire
    - Weapon imbue about to expire
    - Low charges on shields
]]

---@class WarningManager
local WarningManager = TotemBuddyLoader:CreateModule("WarningManager")
local _WarningManager = WarningManager.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Warning types
local WARNING_TYPES = {
    TOTEM_EXPIRING = "totemExpiring",
    TOTEM_DESTROYED = "totemDestroyed",
    SHIELD_EXPIRING = "shieldExpiring",
    SHIELD_LOW_CHARGES = "shieldLowCharges",
    IMBUE_EXPIRING = "imbueExpiring",
    IMBUE_MISSING = "imbueMissing",
    DEBUFF_EXPIRING = "debuffExpiring",
}

-- Sound IDs (SOUNDKIT constants for TBC/WotLK Classic compatibility)
-- Using numeric IDs ensures cross-version compatibility
local SOUNDS = {
    warning = SOUNDKIT and SOUNDKIT.IG_QUEST_FAILED or 847,           -- Quest failed sound (attention-grabbing)
    alert = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959,               -- Raid warning sound
    tick = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856, -- Checkbox tick (subtle)
    gong = SOUNDKIT and SOUNDKIT.READY_CHECK or 8960,                 -- Ready check gong
}

-- State
_WarningManager.lastWarnings = {}  -- Track when we last warned about each thing
_WarningManager.suppressUntil = {}  -- Suppress warnings temporarily
_WarningManager.combatOnlyWarnings = {}  -- Warnings that only trigger in combat

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

--- Get warning configuration from profile
---@return table config
local function GetConfig()
    local db = TotemBuddy.db and TotemBuddy.db.profile or {}
    return {
        enabled = db.warningsEnabled ~= false,  -- Default to true
        soundEnabled = db.warningSoundsEnabled ~= false,
        -- Sound settings per warning type
        totemExpiringSound = db.totemExpiringSound or "warning",
        totemDestroyedSound = db.totemDestroyedSound or "alert",
        shieldExpiringSound = db.shieldExpiringSound or "tick",
        imbueExpiringSound = db.imbueExpiringSound or "warning",
        -- Cooldown between repeated warnings (seconds)
        warningCooldown = db.warningCooldown or 5,
        -- Combat-only settings
        onlyInCombat = db.warningsOnlyInCombat or false,
    }
end

-- =============================================================================
-- SOUND PLAYBACK
-- =============================================================================

--- Play a warning sound
---@param soundKey string Key from SOUNDS table
local function PlayWarningSound(soundKey)
    local config = GetConfig()
    if not config.soundEnabled then return end

    local soundId = SOUNDS[soundKey]
    if soundId then
        -- Use pcall for safety across different WoW versions
        -- TBC Classic uses PlaySound(soundId), WotLK may support channel param
        pcall(PlaySound, soundId)
    end
end

-- =============================================================================
-- WARNING TRACKING
-- =============================================================================

--- Check if we should issue a warning (respects cooldowns)
---@param warningKey string Unique key for this warning
---@param cooldown number|nil Override cooldown (uses default if nil)
---@return boolean shouldWarn
local function ShouldWarn(warningKey, cooldown)
    local config = GetConfig()

    -- Check global enable
    if not config.enabled then return false end

    -- Check combat-only setting
    if config.onlyInCombat and not InCombatLockdown() then
        return false
    end

    -- Check if suppressed
    local suppressTime = _WarningManager.suppressUntil[warningKey]
    if suppressTime and GetTime() < suppressTime then
        return false
    end

    -- Check cooldown
    local lastWarn = _WarningManager.lastWarnings[warningKey] or 0
    local cd = cooldown or config.warningCooldown
    if GetTime() - lastWarn < cd then
        return false
    end

    return true
end

--- Mark that we just warned about something
---@param warningKey string
local function MarkWarned(warningKey)
    _WarningManager.lastWarnings[warningKey] = GetTime()
end

--- Suppress warnings for a key temporarily
---@param warningKey string
---@param duration number Seconds to suppress
function WarningManager:SuppressWarning(warningKey, duration)
    _WarningManager.suppressUntil[warningKey] = GetTime() + duration
end

-- =============================================================================
-- PUBLIC WARNING API
-- =============================================================================

--- Trigger a totem expiring warning
---@param element number Element index (1-4)
---@param totemName string The totem name
---@param remaining number Seconds remaining
function WarningManager:TotemExpiring(element, totemName, remaining)
    local key = "totem_expiring_" .. element
    if not ShouldWarn(key, 10) then return end

    local config = GetConfig()
    if config.totemExpiringSound and config.totemExpiringSound ~= "none" then
        PlayWarningSound(config.totemExpiringSound)
    end

    MarkWarned(key)
end

--- Trigger a totem destroyed warning
---@param element number Element index (1-4)
---@param totemName string The totem name
function WarningManager:TotemDestroyed(element, totemName)
    local key = "totem_destroyed_" .. element
    if not ShouldWarn(key, 3) then return end

    local config = GetConfig()
    if config.totemDestroyedSound and config.totemDestroyedSound ~= "none" then
        PlayWarningSound(config.totemDestroyedSound)
    end

    MarkWarned(key)
end

--- Trigger a shield expiring warning
---@param shieldName string The shield name
---@param remaining number Seconds remaining
function WarningManager:ShieldExpiring(shieldName, remaining)
    local key = "shield_expiring"
    if not ShouldWarn(key, 15) then return end

    local config = GetConfig()
    if config.shieldExpiringSound and config.shieldExpiringSound ~= "none" then
        PlayWarningSound(config.shieldExpiringSound)
    end

    MarkWarned(key)
end

--- Trigger a shield low charges warning
---@param shieldName string The shield name
---@param charges number Current charges
function WarningManager:ShieldLowCharges(shieldName, charges)
    local key = "shield_low_charges"
    if not ShouldWarn(key, 10) then return end

    -- Only warn if charges are critically low (1-2)
    if charges > 2 then return end

    local config = GetConfig()
    PlayWarningSound("tick")

    MarkWarned(key)
end

--- Trigger a weapon imbue expiring warning
---@param slot string "mainhand" or "offhand"
---@param remaining number Seconds remaining
function WarningManager:ImbueExpiring(slot, remaining)
    local key = "imbue_expiring_" .. slot
    if not ShouldWarn(key, 30) then return end

    local config = GetConfig()
    if config.imbueExpiringSound and config.imbueExpiringSound ~= "none" then
        PlayWarningSound(config.imbueExpiringSound)
    end

    MarkWarned(key)
end

--- Trigger a missing imbue warning (only in combat)
---@param slot string "mainhand" or "offhand"
function WarningManager:ImbueMissing(slot)
    -- Only warn in combat
    if not InCombatLockdown() then return end

    local key = "imbue_missing_" .. slot
    if not ShouldWarn(key, 60) then return end

    PlayWarningSound("tick")
    MarkWarned(key)
end

--- Trigger a debuff expiring warning
---@param debuffName string The debuff name
---@param remaining number Seconds remaining
function WarningManager:DebuffExpiring(debuffName, remaining)
    local key = "debuff_expiring_" .. (debuffName or "unknown")
    if not ShouldWarn(key, 3) then return end

    -- Don't play sound for debuffs (too frequent), visual warning is enough
    MarkWarned(key)
end

-- =============================================================================
-- FLASH/PULSE EFFECTS
-- =============================================================================

--- Flash the main bar frame (for critical warnings)
---@param duration number Duration of flash in seconds
function WarningManager:FlashMainBar(duration)
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if not TotemBar or not TotemBar.frame then return end

    local frame = TotemBar.frame
    duration = duration or 0.5

    -- Create flash texture if not exists
    if not frame.warningFlash then
        frame.warningFlash = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        frame.warningFlash:SetAllPoints()
        frame.warningFlash:SetColorTexture(1, 0.2, 0.1, 0.4)
        frame.warningFlash:Hide()

        -- Create animation
        frame.warningFlashAnim = frame.warningFlash:CreateAnimationGroup()

        local fadeIn = frame.warningFlashAnim:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.15)
        fadeIn:SetOrder(1)

        local fadeOut = frame.warningFlashAnim:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.35)
        fadeOut:SetOrder(2)

        frame.warningFlashAnim:SetScript("OnFinished", function()
            frame.warningFlash:Hide()
        end)
    end

    -- Play flash
    frame.warningFlash:Show()
    frame.warningFlashAnim:Stop()
    frame.warningFlashAnim:Play()
end

-- =============================================================================
-- RESET
-- =============================================================================

--- Reset all warning cooldowns (e.g., on combat end)
function WarningManager:ResetCooldowns()
    _WarningManager.lastWarnings = {}
    _WarningManager.suppressUntil = {}
end

return WarningManager
