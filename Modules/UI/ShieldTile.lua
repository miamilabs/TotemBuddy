--[[
    TotemBuddy - Shield Tile Module
    Button for Lightning Shield, Water Shield, and Earth Shield
    Uses SecureActionButtonTemplate for combat-safe casting
]]

---@class ShieldTile
local ShieldTile = TotemBuddyLoader:CreateModule("ShieldTile")
local _ShieldTile = ShieldTile.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ShieldSelector = nil
local ExtrasScanner = nil
local EventHandler = nil

-- Database reference
local ShamanExtrasDB = nil

local function GetDB()
    if not ShamanExtrasDB then
        ShamanExtrasDB = _G.TotemBuddyShamanExtras
    end
    return ShamanExtrasDB
end

-- Earth Shield spell IDs (base spell ID used for tracking)
local EARTH_SHIELD_SPELL_IDS = {
    [974] = true,    -- Rank 1
    [32593] = true,  -- Rank 2
    [32594] = true,  -- Rank 3
}

-- Earth Shield constants (TBC Classic values)
local EARTH_SHIELD_DEFAULT_CHARGES = 6
local EARTH_SHIELD_DEFAULT_DURATION = 600  -- 10 minutes

-- Get the localized name for Earth Shield (cache it)
local EARTH_SHIELD_NAME = nil
local function GetEarthShieldName()
    if not EARTH_SHIELD_NAME then
        EARTH_SHIELD_NAME = GetSpellInfo(974) or "Earth Shield"
    end
    return EARTH_SHIELD_NAME
end

-- =============================================================================
-- EARTH SHIELD TRACKING STATE
-- =============================================================================

-- Earth Shield tracking data
_ShieldTile.earthShieldTarget = nil  -- { guid = string, name = string, charges = number, endTime = number }
_ShieldTile.cleuRegistered = false

-- Pending Earth Shield cast tracking (for UNIT_SPELLCAST_SENT -> SUCCEEDED flow)
_ShieldTile.lastESCastTarget = nil      -- Target name from UNIT_SPELLCAST_SENT
_ShieldTile.lastESCastGUID = nil        -- Cast GUID to match with SUCCEEDED
_ShieldTile.lastESCastUnitGUID = nil    -- Target's GUID (resolved at cast time)

-- =============================================================================
-- CREATION
-- =============================================================================

--- Create a Shield tile button
---@param parent Frame The parent frame
---@return Button tile The created tile button
function ShieldTile:Create(parent)
    -- Use SecureActionButtonTemplate for combat-safe casting
    local tile = CreateFrame("Button", "TotemBuddyShieldTile", parent, "SecureActionButtonTemplate")

    -- Register for mouse clicks
    tile:RegisterForClicks("AnyUp", "AnyDown")

    -- Disable secure action on right-click (used for selector)
    tile:SetAttribute("type2", "")

    tile.tileType = "shield"
    tile:SetSize(TotemBuddy.db.profile.tileSize, TotemBuddy.db.profile.tileSize)

    -- Icon texture
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Cooldown frame (for GCD)
    tile.cooldown = CreateFrame("Cooldown", nil, tile, "CooldownFrameTemplate")
    tile.cooldown:SetAllPoints()
    tile.cooldown:SetDrawEdge(true)
    tile.cooldown:SetHideCountdownNumbers(true)

    -- Active glow indicator
    local tileSize = TotemBuddy.db.profile.tileSize or 40
    tile.activeGlow = tile:CreateTexture(nil, "OVERLAY")
    tile.activeGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.activeGlow:SetBlendMode("ADD")
    tile.activeGlow:SetPoint("CENTER")
    tile.activeGlow:SetSize(tileSize * 1.4, tileSize * 1.4)
    tile.activeGlow:SetVertexColor(1.0, 1.0, 0.3, 0.6)  -- Yellow for shields
    tile.activeGlow:Hide()

    -- Charges text (for Lightning/Water Shield)
    tile.chargesText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.chargesText:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.chargesText:SetTextColor(1, 1, 0, 1)  -- Yellow
    tile.chargesText:SetShadowOffset(1, -1)
    tile.chargesText:Hide()

    -- Duration text
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.durationText:SetPoint("BOTTOM", 0, 8)
    tile.durationText:SetTextColor(1, 1, 0.3, 1)  -- Yellow
    tile.durationText:SetShadowOffset(1, -1)
    tile.durationText:Hide()

    -- Target name text (for Earth Shield - shows who has it)
    tile.targetNameText = tile:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tile.targetNameText:SetPoint("TOP", 0, -2)
    tile.targetNameText:SetTextColor(0.5, 1.0, 0.5, 1)  -- Light green
    tile.targetNameText:SetShadowOffset(1, -1)
    tile.targetNameText:SetJustifyH("CENTER")
    tile.targetNameText:SetWidth(tile:GetWidth() - 4)
    tile.targetNameText:Hide()

    -- Type indicator bar (bottom)
    tile.typeIndicator = tile:CreateTexture(nil, "OVERLAY")
    tile.typeIndicator:SetColorTexture(0.8, 0.8, 0.2, 0.8)  -- Yellow for Shield
    tile.typeIndicator:SetPoint("BOTTOMLEFT", 2, 2)
    tile.typeIndicator:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.typeIndicator:SetHeight(3)

    -- Border for hover highlight
    tile.border = tile:CreateTexture(nil, "OVERLAY")
    tile.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.border:SetBlendMode("ADD")
    tile.border:SetPoint("CENTER")
    tile.border:SetSize(tileSize * 1.3, tileSize * 1.3)
    tile.border:SetAlpha(0.8)
    tile.border:Hide()

    -- Custom hover highlight
    tile.highlight = tile:CreateTexture(nil, "HIGHLIGHT")
    tile.highlight:SetAllPoints()
    tile.highlight:SetColorTexture(1, 1, 1, 0.2)
    tile.highlight:SetBlendMode("ADD")

    -- Event handlers
    tile:SetScript("OnEnter", function(self)
        _ShieldTile.OnEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _ShieldTile.OnLeave(self)
    end)

    -- Right-click handler for selector
    tile:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            _ShieldTile.OnRightClick(self)
        end
    end)

    -- Store reference to module methods
    tile.SetShield = function(self, spellId, shieldData)
        _ShieldTile.SetShield(self, spellId, shieldData)
    end
    tile.UpdateStatus = function(self)
        _ShieldTile.UpdateStatus(self)
    end
    tile.UpdateSize = function(self, size)
        _ShieldTile.UpdateSize(self, size)
    end
    tile.ApplyPendingAttributes = function(self)
        _ShieldTile.ApplyPendingAttributes(self)
    end
    tile.OnGroupRosterUpdate = function(self)
        _ShieldTile.OnGroupRosterUpdate(self)
    end
    tile.GetEarthShieldTarget = function(self)
        return _ShieldTile.GetEarthShieldTarget()
    end

    -- Register for CLEU events (Earth Shield tracking)
    _ShieldTile.RegisterCLEUHandlers()

    return tile
end

-- =============================================================================
-- MACRO BUILDING
-- =============================================================================

--- Build macro text for shield casting
--- Earth Shield uses key modifier targeting (configurable)
---@param shieldName string The shield spell name
---@param shieldData table The shield data
---@return string macrotext
local function BuildShieldMacro(shieldName, shieldData)
    if not (shieldData and shieldData.isTargeted) then
        -- Self-cast shields (Lightning, Water)
        return string.format("#showtooltip %s\n/cast %s", shieldName, shieldName)
    end

    -- Earth Shield: Key modifier targeting
    local targeting = TotemBuddy.db and TotemBuddy.db.profile.earthShieldTargeting or {
        noModifier = "player", shift = "focus", ctrl = "none", alt = "none"
    }

    local parts = {}

    --- Add a targeting condition to the macro
    ---@param modifier string|nil The modifier key (nil for default/no modifier)
    ---@param target string The target unit ID
    local function addCondition(modifier, target)
        if target and target ~= "none" then
            if modifier then
                table.insert(parts, string.format("[mod:%s,@%s,help,nodead]", modifier, target))
            else
                table.insert(parts, string.format("[@%s,help,nodead]", target))
            end
        end
    end

    -- Build conditions in priority order: alt, ctrl, shift, then default
    -- First matching condition wins in WoW macros
    addCondition("alt", targeting.alt)
    addCondition("ctrl", targeting.ctrl)
    addCondition("shift", targeting.shift)
    addCondition(nil, targeting.noModifier)

    -- Fallback to player if no conditions matched (safety)
    if #parts == 0 then
        table.insert(parts, "[@player]")
    end

    return string.format("#showtooltip %s\n/cast %s %s", shieldName, table.concat(parts, ""), shieldName)
end

-- =============================================================================
-- ATTRIBUTE HANDLING (Combat-safe)
-- =============================================================================

--- Safely apply secure attributes (queues if in combat)
---@param tile Button The tile button
---@param spellId number|nil The spell ID
---@param macrotext string|nil Optional macro text
local function ApplyAttributesSafely(tile, spellId, macrotext)
    if InCombatLockdown() then
        tile.pendingSpellId = spellId
        tile.pendingMacrotext = macrotext
        return false
    end

    if macrotext then
        tile:SetAttribute("type", "macro")
        tile:SetAttribute("macrotext", macrotext)
        tile:SetAttribute("spell", nil)
    elseif spellId then
        local spellName = GetSpellInfo(spellId)
        if spellName then
            tile:SetAttribute("type", "spell")
            tile:SetAttribute("spell", spellName)
            tile:SetAttribute("macrotext", nil)
        else
            tile:SetAttribute("type", nil)
            tile:SetAttribute("spell", nil)
            tile:SetAttribute("macrotext", nil)
        end
    else
        tile:SetAttribute("type", nil)
        tile:SetAttribute("spell", nil)
        tile:SetAttribute("macrotext", nil)
    end

    tile.pendingSpellId = nil
    tile.pendingMacrotext = nil
    return true
end

--- Set the shield for this tile
---@param tile Button The tile button
---@param spellId number|nil The spell ID
---@param shieldData table|nil The shield data
function _ShieldTile.SetShield(tile, spellId, shieldData)
    tile.shieldData = shieldData
    tile.spellId = spellId

    if not spellId then
        tile.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        ApplyAttributesSafely(tile, nil, nil)
        return
    end

    -- Get spell info
    local name, _, icon = GetSpellInfo(spellId)
    tile.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Build macro (especially for Earth Shield mouseover)
    if name then
        local macrotext = BuildShieldMacro(name, shieldData)
        ApplyAttributesSafely(tile, spellId, macrotext)
    else
        ApplyAttributesSafely(tile, spellId, nil)
    end

    -- Update status display
    _ShieldTile.UpdateStatus(tile)
end

--- Apply pending attribute changes (called after leaving combat)
---@param tile Button The tile button
function _ShieldTile.ApplyPendingAttributes(tile)
    if tile.pendingSpellId or tile.pendingMacrotext then
        ApplyAttributesSafely(tile, tile.pendingSpellId, tile.pendingMacrotext)
    end
end

-- =============================================================================
-- EARTH SHIELD CLEU TRACKING
-- =============================================================================

--- Register CLEU handlers for Earth Shield tracking
function _ShieldTile.RegisterCLEUHandlers()
    if _ShieldTile.cleuRegistered then return end

    -- Get EventHandler module
    if not EventHandler then
        EventHandler = TotemBuddyLoader:ImportModule("EventHandler")
    end

    if not EventHandler then return end

    -- Register for aura events
    -- Note: Standard CLEU params - spellId is at position 12 in the vararg
    EventHandler:RegisterCLEUHandler("ShieldTile", {
        "SPELL_AURA_APPLIED",
        "SPELL_AURA_REFRESH",
        "SPELL_AURA_REMOVED",
        "SPELL_AURA_APPLIED_DOSE",
        "SPELL_AURA_REMOVED_DOSE",
    }, function(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, ...)
        local playerGUID = EventHandler:GetPlayerGUID()
        _ShieldTile.OnCLEUEvent(timestamp, subevent, sourceGUID, destGUID, destName, playerGUID, spellId, spellName)
    end)

    _ShieldTile.cleuRegistered = true
end

--- Handle CLEU events for Earth Shield
---@param timestamp number
---@param subevent string
---@param sourceGUID string
---@param destGUID string
---@param destName string
---@param playerGUID string
---@param spellId number
---@param spellName string
function _ShieldTile.OnCLEUEvent(timestamp, subevent, sourceGUID, destGUID, destName, playerGUID, spellId, spellName)
    -- Only track our own Earth Shield
    if sourceGUID ~= playerGUID then return end

    -- Check if this is Earth Shield
    if not EARTH_SHIELD_SPELL_IDS[spellId] then return end

    if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
        -- Earth Shield was applied/refreshed
        _ShieldTile.earthShieldTarget = {
            guid = destGUID,
            name = destName,
            charges = EARTH_SHIELD_DEFAULT_CHARGES,
            endTime = GetTime() + EARTH_SHIELD_DEFAULT_DURATION,
        }

        -- Scan the target to get accurate charge count
        _ShieldTile.ScanTargetForEarthShield(destGUID, destName)

    elseif subevent == "SPELL_AURA_REMOVED" then
        -- Earth Shield was removed
        if _ShieldTile.earthShieldTarget and _ShieldTile.earthShieldTarget.guid == destGUID then
            _ShieldTile.earthShieldTarget = nil
        end

    elseif subevent == "SPELL_AURA_APPLIED_DOSE" or subevent == "SPELL_AURA_REMOVED_DOSE" then
        -- Charge count changed (Earth Shield heal triggered)
        if _ShieldTile.earthShieldTarget and _ShieldTile.earthShieldTarget.guid == destGUID then
            -- Scan to get updated charge count
            _ShieldTile.ScanTargetForEarthShield(destGUID, destName)
        end
    end

    -- Update display
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
        TotemBar.shieldTile:UpdateStatus()
    end
end

-- =============================================================================
-- EARTH SHIELD SPELLCAST TRACKING (Primary method - more reliable than CLEU)
-- =============================================================================

--- Handle UNIT_SPELLCAST_SENT - captures target at cast time
---@param target string The target name or unit
---@param castGUID string The cast GUID
---@param spellID number The spell ID
function _ShieldTile.OnSpellcastSent(target, castGUID, spellID)
    -- Only track Earth Shield spells
    if not EARTH_SHIELD_SPELL_IDS[spellID] then return end

    -- Store pending cast info
    _ShieldTile.lastESCastTarget = target
    _ShieldTile.lastESCastGUID = castGUID

    -- Try to resolve the target's GUID
    -- First try direct unit lookup (works if target is a unit token like "target", "focus")
    _ShieldTile.lastESCastUnitGUID = UnitGUID(target)

    -- Fallback: if target is a name string, check common unit tokens
    if not _ShieldTile.lastESCastUnitGUID then
        if target == UnitName("target") then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("target")
        elseif target == UnitName("focus") then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("focus")
        elseif target == UnitName("player") then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("player")
        else
            -- Check party/raid members
            if IsInRaid() then
                for i = 1, 40 do
                    local unit = "raid" .. i
                    if UnitExists(unit) and target == UnitName(unit) then
                        _ShieldTile.lastESCastUnitGUID = UnitGUID(unit)
                        break
                    end
                end
            elseif IsInGroup() then
                for i = 1, 4 do
                    local unit = "party" .. i
                    if UnitExists(unit) and target == UnitName(unit) then
                        _ShieldTile.lastESCastUnitGUID = UnitGUID(unit)
                        break
                    end
                end
            end
        end
    end
end

--- Handle UNIT_SPELLCAST_SUCCEEDED - confirms cast and stores target
---@param castGUID string The cast GUID
function _ShieldTile.OnSpellcastSucceeded(castGUID)
    -- Only process if this matches our pending Earth Shield cast
    if not _ShieldTile.lastESCastGUID or castGUID ~= _ShieldTile.lastESCastGUID then
        return
    end

    -- Confirmed! Store the Earth Shield target
    _ShieldTile.earthShieldTarget = {
        guid = _ShieldTile.lastESCastUnitGUID,
        name = _ShieldTile.lastESCastTarget,
        charges = EARTH_SHIELD_DEFAULT_CHARGES,
        endTime = GetTime() + EARTH_SHIELD_DEFAULT_DURATION,
    }

    -- Clear pending cast state
    _ShieldTile.lastESCastTarget = nil
    _ShieldTile.lastESCastGUID = nil
    _ShieldTile.lastESCastUnitGUID = nil

    -- Try to get accurate charges if we have a valid GUID
    if _ShieldTile.earthShieldTarget.guid then
        _ShieldTile.ScanTargetForEarthShield(
            _ShieldTile.earthShieldTarget.guid,
            _ShieldTile.earthShieldTarget.name
        )
    end

    -- Update display
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
        TotemBar.shieldTile:UpdateStatus()
    end
end

--- Handle UNIT_AURA for Earth Shield target - updates charges and duration
---@param unit string The unit that had an aura change
function _ShieldTile.OnTargetAuraChanged(unit)
    -- Only process if we have a tracked Earth Shield target
    if not _ShieldTile.earthShieldTarget or not _ShieldTile.earthShieldTarget.guid then
        return
    end

    -- Check if this unit matches our Earth Shield target
    if UnitGUID(unit) ~= _ShieldTile.earthShieldTarget.guid then
        return
    end

    -- Scan the unit for Earth Shield buff info
    local earthShieldName = GetEarthShieldName()
    local found = false

    for i = 1, 40 do
        local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
        if not name then break end

        if EARTH_SHIELD_SPELL_IDS[spellId] and source == "player" then
            -- Update tracking data with accurate values
            _ShieldTile.earthShieldTarget.charges = count or 0
            _ShieldTile.earthShieldTarget.endTime = expirationTime or (GetTime() + 600)
            found = true
            break
        end
    end

    -- If Earth Shield is no longer on the target, clear tracking
    if not found then
        _ShieldTile.earthShieldTarget = nil
    end

    -- Update display
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
        TotemBar.shieldTile:UpdateStatus()
    end
end

--- Scan a specific target for Earth Shield charges
---@param targetGUID string
---@param targetName string
function _ShieldTile.ScanTargetForEarthShield(targetGUID, targetName)
    local earthShieldName = GetEarthShieldName()
    local playerGUID = UnitGUID("player")

    -- Build list of units to check
    local unitsToCheck = { "target", "focus", "player" }

    -- Add party/raid members
    if IsInRaid() then
        for i = 1, 40 do
            table.insert(unitsToCheck, "raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            table.insert(unitsToCheck, "party" .. i)
        end
    end

    -- Scan each unit
    for _, unit in ipairs(unitsToCheck) do
        if UnitExists(unit) and UnitGUID(unit) == targetGUID then
            for i = 1, 40 do
                local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                if not name then break end

                if EARTH_SHIELD_SPELL_IDS[spellId] and source == "player" then
                    _ShieldTile.earthShieldTarget = {
                        guid = targetGUID,
                        name = targetName or UnitName(unit),
                        charges = count or 0,
                        endTime = expirationTime or (GetTime() + 600),
                    }
                    return
                end
            end
            break
        end
    end
end

--- Scan all units for Earth Shield (called on login/reload)
function _ShieldTile.ScanAllUnitsForEarthShield()
    local earthShieldName = GetEarthShieldName()

    -- Build list of units to check
    local unitsToCheck = { "target", "focus", "player" }

    -- Add party/raid members
    if IsInRaid() then
        for i = 1, 40 do
            table.insert(unitsToCheck, "raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            table.insert(unitsToCheck, "party" .. i)
        end
    end

    -- Scan each unit
    for _, unit in ipairs(unitsToCheck) do
        if UnitExists(unit) then
            for i = 1, 40 do
                local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                if not name then break end

                if EARTH_SHIELD_SPELL_IDS[spellId] and source == "player" then
                    _ShieldTile.earthShieldTarget = {
                        guid = UnitGUID(unit),
                        name = UnitName(unit),
                        charges = count or 0,
                        endTime = expirationTime or (GetTime() + 600),
                    }
                    return
                end
            end
        end
    end

    -- No Earth Shield found
    _ShieldTile.earthShieldTarget = nil
end

--- Get the current Earth Shield target info
---@return table|nil earthShieldTarget The target info or nil
function _ShieldTile.GetEarthShieldTarget()
    -- Validate that the target still has the shield
    if _ShieldTile.earthShieldTarget then
        local now = GetTime()
        if _ShieldTile.earthShieldTarget.endTime and _ShieldTile.earthShieldTarget.endTime < now then
            -- Expired
            _ShieldTile.earthShieldTarget = nil
        end
    end
    return _ShieldTile.earthShieldTarget
end

--- Called when group roster changes
---@param tile Button The tile button (optional)
function _ShieldTile.OnGroupRosterUpdate(tile)
    -- Re-scan for Earth Shield when roster changes
    -- (target might have left group)
    C_Timer.After(0.5, function()
        _ShieldTile.ScanAllUnitsForEarthShield()

        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
            TotemBar.shieldTile:UpdateStatus()
        end
    end)
end

-- =============================================================================
-- STATUS DISPLAY
-- =============================================================================

-- Use consolidated FormatTime from main addon
local FormatTime = function(seconds)
    return TotemBuddy.FormatTime(seconds)
end

--- Check if any known shield is active on player
---@return boolean isActive, string|nil buffName, number|nil charges, number|nil remaining, number|nil spellId
local function GetActiveShieldInfo()
    local db = GetDB()
    if not db then return false end

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        -- Check if this is a known shield spell (spellId may be nil on some Classic clients)
        if spellId and db:IsShieldSpell(spellId) then
            local remaining = expirationTime and expirationTime > 0 and (expirationTime - GetTime()) or nil
            return true, name, count, remaining, spellId
        end
    end

    return false
end

--- Update the shield status display
---@param tile Button The tile button
function _ShieldTile.UpdateStatus(tile)
    if not TotemBuddy.db.profile.showShieldStatus then
        tile.activeGlow:Hide()
        tile.chargesText:Hide()
        tile.durationText:Hide()
        if tile.targetNameText then tile.targetNameText:Hide() end
        tile.icon:SetDesaturated(false)
        return
    end

    -- Check for Earth Shield on party members first (higher priority display)
    local earthShieldTarget = _ShieldTile.GetEarthShieldTarget()
    local showEarthShieldTracking = TotemBuddy.db.profile.trackEarthShieldOnTargets
    if showEarthShieldTracking == nil then showEarthShieldTracking = true end  -- Default to true

    if earthShieldTarget and showEarthShieldTracking then
        -- Earth Shield is active on a target
        if TotemBuddy.db.profile.showActiveGlow then
            tile.activeGlow:Show()
            -- Use a green tint for Earth Shield on others
            tile.activeGlow:SetVertexColor(0.3, 1.0, 0.5, 0.6)
        end

        -- Show charges
        if earthShieldTarget.charges and earthShieldTarget.charges > 0 then
            tile.chargesText:SetText(tostring(earthShieldTarget.charges))
            tile.chargesText:Show()
        else
            tile.chargesText:Hide()
        end

        -- Show remaining duration
        local remaining = earthShieldTarget.endTime and (earthShieldTarget.endTime - GetTime()) or 0
        if remaining > 0 and TotemBuddy.db.profile.showDurationText then
            tile.durationText:SetText(FormatTime(remaining))
            tile.durationText:Show()
        else
            tile.durationText:Hide()
        end

        -- Show target name
        local showTargetName = TotemBuddy.db.profile.showEarthShieldTargetName
        if showTargetName == nil then showTargetName = true end  -- Default to true

        if showTargetName and tile.targetNameText and earthShieldTarget.name then
            -- Truncate name if too long
            local name = earthShieldTarget.name
            if #name > 8 then
                name = string.sub(name, 1, 7) .. "..."
            end
            tile.targetNameText:SetText(name)
            tile.targetNameText:Show()
        elseif tile.targetNameText then
            tile.targetNameText:Hide()
        end

        -- Normal icon
        tile.icon:SetDesaturated(false)
        return
    end

    -- Hide target name if no Earth Shield on targets
    if tile.targetNameText then
        tile.targetNameText:Hide()
    end

    -- Check for self-shields (Lightning Shield, Water Shield, or Earth Shield on self)
    local isActive, buffName, charges, remaining, activeSpellId = GetActiveShieldInfo()

    if isActive then
        -- Shield is active on player
        if TotemBuddy.db.profile.showActiveGlow then
            tile.activeGlow:Show()
            -- Reset to yellow for self-shields
            tile.activeGlow:SetVertexColor(1.0, 1.0, 0.3, 0.6)
        end

        -- Show charges if available
        if charges and charges > 0 then
            tile.chargesText:SetText(tostring(charges))
            tile.chargesText:Show()
        else
            tile.chargesText:Hide()
        end

        -- Show duration if available
        if remaining and remaining > 0 and TotemBuddy.db.profile.showDurationText then
            tile.durationText:SetText(FormatTime(remaining))
            tile.durationText:Show()
        else
            tile.durationText:Hide()
        end

        -- Normal icon
        tile.icon:SetDesaturated(false)
    else
        -- No shield active
        tile.activeGlow:Hide()
        tile.chargesText:Hide()
        tile.durationText:Hide()

        -- Desaturate to indicate inactive
        tile.icon:SetDesaturated(true)
    end
end

--- Update the tile size
---@param tile Button The tile button
---@param size number The new size
function _ShieldTile.UpdateSize(tile, size)
    tile:SetSize(size, size)
    tile.border:SetSize(size * 1.4, size * 1.4)
    if tile.activeGlow then
        tile.activeGlow:SetSize(size * 1.4, size * 1.4)
    end
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

--- Handle mouse enter
---@param tile Button The tile button
function _ShieldTile.OnEnter(tile)
    tile.border:Show()

    -- Show tooltip
    if TotemBuddy.db.profile.showTooltips and tile.spellId then
        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(tile.spellId)

        -- Add status
        local isActive, buffName, charges, remaining = GetActiveShieldInfo()
        GameTooltip:AddLine(" ")

        if isActive then
            local statusText = L["Active"]
            if charges and charges > 0 then
                statusText = statusText .. string.format(" (%d %s)", charges, L["charges"])
            end
            if remaining and remaining > 0 then
                statusText = statusText .. string.format(" - %s", FormatTime(remaining))
            end
            GameTooltip:AddLine(statusText, 0, 1, 0)
        else
            GameTooltip:AddLine(L["Not active"], 1, 0.3, 0.3)
        end

        -- Add Earth Shield targeting hint
        if tile.shieldData and tile.shieldData.isTargeted then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Click"] .. ": " .. L["Self"], 0.7, 0.7, 0.7)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Right-click to select shield"], 0.5, 0.5, 0.5)

        GameTooltip:Show()
    end
end

--- Handle mouse leave
---@param tile Button The tile button
function _ShieldTile.OnLeave(tile)
    tile.border:Hide()
    GameTooltip:Hide()

    -- Schedule selector hide
    if not ShieldSelector then
        ShieldSelector = TotemBuddyLoader:ImportModule("ShieldSelector")
    end
    if ShieldSelector and ShieldSelector.ScheduleHide then
        ShieldSelector:ScheduleHide()
    end
end

--- Handle right-click (opens selector)
---@param tile Button The tile button
function _ShieldTile.OnRightClick(tile)
    if InCombatLockdown() then
        TotemBuddy:Print(L["Cannot open selector during combat."])
        return
    end

    if not ShieldSelector then
        ShieldSelector = TotemBuddyLoader:ImportModule("ShieldSelector")
    end

    if ShieldSelector and ShieldSelector.Show then
        ShieldSelector:Show(tile)
    end
end

return ShieldTile
