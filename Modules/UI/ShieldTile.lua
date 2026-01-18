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
_ShieldTile.pendingCastTimer = nil      -- Timer to expire stale pending casts
_ShieldTile.fallbackScanTimer = nil     -- Timer for fallback scan if CLEU doesn't confirm

-- Pending cast timeout (seconds)
local PENDING_CAST_TIMEOUT = 5

-- Debug mode flag
_ShieldTile.debugMode = false

--- Debug print helper
local function DebugPrint(...)
    if (_ShieldTile.debugMode or (TotemBuddy and TotemBuddy.esDebugMode)) and TotemBuddy and TotemBuddy.Print then
        TotemBuddy:Print("|cff00ffff[ES Debug]|r", ...)
    end
end

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
        -- Debug: show that the dispatcher called us
        if TotemBuddy and TotemBuddy.esDebugMode then
            print("|cff00ff00[ES Dispatcher]|r subevent=" .. tostring(subevent) .. " src=" .. tostring(sourceName) .. " dest=" .. tostring(destName) .. " spellId=" .. tostring(spellId) .. " spell=" .. tostring(spellName))
        end
        _ShieldTile.OnCLEUEvent(timestamp, subevent, sourceGUID, destGUID, destName, playerGUID, spellId, spellName)
    end)

    _ShieldTile.cleuRegistered = true
    if TotemBuddy and TotemBuddy.esDebugMode then
        print("|cff00ff00[ES]|r CLEU handlers registered for ShieldTile")
    end
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
    -- Debug: log all aura events from player
    if sourceGUID == playerGUID and (_ShieldTile.debugMode or (TotemBuddy and TotemBuddy.esDebugMode)) then
        print("|cff00ffffTotemBuddy CLEU:|r " .. tostring(subevent) .. " spellId=" .. tostring(spellId) .. " spell=" .. tostring(spellName) .. " dest=" .. tostring(destName))
    end

    -- Only track our own Earth Shield
    if sourceGUID ~= playerGUID then return end

    -- Check if this is Earth Shield (by ID or by name as fallback)
    local earthShieldName = GetEarthShieldName()
    local isEarthShield = EARTH_SHIELD_SPELL_IDS[spellId] or (spellName == earthShieldName)
    if not isEarthShield then return end

    -- DISABLED: Party member Earth Shield tracking
    -- Only track Earth Shield on self (player) when trackEarthShieldOnTargets is false
    local trackOnTargets = TotemBuddy.db and TotemBuddy.db.profile.trackEarthShieldOnTargets
    if not trackOnTargets and destGUID ~= playerGUID then
        DebugPrint("CLEU: Skipping party ES tracking (disabled) - dest=" .. tostring(destName))
        return
    end

    DebugPrint("CLEU: Earth Shield detected! subevent=" .. tostring(subevent))

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
---@param spellID number|nil The spell ID (may be nil on Classic/TBC clients)
---@param spellName string|nil The spell name (fallback for Classic/TBC clients)
function _ShieldTile.OnSpellcastSent(target, castGUID, spellID, spellName)
    -- Check by ID first, then by name as fallback (Classic/TBC clients may not provide spellID)
    local earthShieldName = GetEarthShieldName()
    local isEarthShield = EARTH_SHIELD_SPELL_IDS[spellID] or (not spellID and spellName == earthShieldName)
    if not isEarthShield then return end

    -- DISABLED: Party member Earth Shield tracking
    -- Skip tracking cast on others when party tracking is disabled
    local trackOnTargets = TotemBuddy.db and TotemBuddy.db.profile.trackEarthShieldOnTargets
    local playerName = UnitName("player")
    if not trackOnTargets then
        -- Only track self-cast Earth Shield
        local isSelfCast = (not target or target == "" or target == "player" or target == playerName)
        if not isSelfCast then
            DebugPrint("SPELLCAST_SENT: Skipping party ES cast tracking (disabled) - target=" .. tostring(target))
            return
        end
    end

    DebugPrint("SPELLCAST_SENT: spellID=" .. tostring(spellID) .. " spellName=" .. tostring(spellName) .. " target=" .. tostring(target))

    -- Cancel any existing pending cast timeout
    if _ShieldTile.pendingCastTimer then
        _ShieldTile.pendingCastTimer:Cancel()
        _ShieldTile.pendingCastTimer = nil
    end

    -- Store pending cast info
    _ShieldTile.lastESCastTarget = target
    _ShieldTile.lastESCastGUID = castGUID

    -- Set up timeout to clear stale pending state if SUCCEEDED/FAILED never fires
    local thisCastGUID = castGUID
    _ShieldTile.pendingCastTimer = C_Timer.After(PENDING_CAST_TIMEOUT, function()
        _ShieldTile.pendingCastTimer = nil
        -- Only clear if this is still the pending cast (not replaced by a newer one)
        if _ShieldTile.lastESCastGUID == thisCastGUID or (not thisCastGUID and _ShieldTile.lastESCastTarget) then
            DebugPrint("Pending cast timeout: Clearing stale state")
            _ShieldTile.lastESCastTarget = nil
            _ShieldTile.lastESCastGUID = nil
            _ShieldTile.lastESCastUnitGUID = nil
        end
    end)

    -- Try to resolve the target's GUID
    -- First try direct unit lookup (works if target is a unit token like "target", "focus", "player")
    _ShieldTile.lastESCastUnitGUID = UnitGUID(target)
    DebugPrint("  -> UnitGUID(target) = " .. tostring(_ShieldTile.lastESCastUnitGUID))

    -- Fallback: if target is a name string, check common unit tokens
    -- Check player FIRST (most common self-cast case via macro)
    if not _ShieldTile.lastESCastUnitGUID then
        local playerName = UnitName("player")
        if target == playerName or target == "player" then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("player")
            _ShieldTile.lastESCastTarget = playerName
            DebugPrint("  -> matched player, GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))
        elseif target == UnitName("target") and UnitIsFriend("player", "target") then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("target")
            DebugPrint("  -> matched current target, GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))
        elseif target == UnitName("focus") then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("focus")
            DebugPrint("  -> matched focus, GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))
        else
            -- Check party/raid members
            if IsInRaid() then
                for i = 1, 40 do
                    local unit = "raid" .. i
                    if UnitExists(unit) and target == UnitName(unit) then
                        _ShieldTile.lastESCastUnitGUID = UnitGUID(unit)
                        DebugPrint("  -> matched " .. unit .. ", GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))
                        break
                    end
                end
            elseif IsInGroup() then
                for i = 1, 4 do
                    local unit = "party" .. i
                    if UnitExists(unit) and target == UnitName(unit) then
                        _ShieldTile.lastESCastUnitGUID = UnitGUID(unit)
                        DebugPrint("  -> matched " .. unit .. ", GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))
                        break
                    end
                end
            end
        end

        -- Final fallback: if target is empty/nil and we couldn't resolve, assume self-cast
        -- (default Earth Shield macro casts on player when no modifier is pressed)
        if not _ShieldTile.lastESCastUnitGUID and (not target or target == "") then
            _ShieldTile.lastESCastUnitGUID = UnitGUID("player")
            _ShieldTile.lastESCastTarget = playerName
            DebugPrint("  -> target empty, defaulting to player, GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))
        end

        if not _ShieldTile.lastESCastUnitGUID then
            DebugPrint("  -> WARNING: Could not resolve GUID for target!")
        end
    end
end

--- Handle UNIT_SPELLCAST_SUCCEEDED - confirms cast succeeded, schedules fallback scan
--- NOTE: CLEU SPELL_AURA_APPLIED is the authoritative source for Earth Shield tracking.
--- This function only schedules a fallback scan in case CLEU doesn't arrive.
---@param castGUID string|nil The cast GUID (nil on TBC/Classic)
---@param spellID number|nil The spell ID (nil on TBC/Classic)
---@param spellName string|nil The spell name (for TBC/Classic fallback)
function _ShieldTile.OnSpellcastSucceeded(castGUID, spellID, spellName)
    -- Check if we have a pending Earth Shield cast
    if not _ShieldTile.lastESCastTarget and not _ShieldTile.lastESCastUnitGUID then
        return
    end

    -- Match by castGUID if available (modern clients), or by spellName (TBC/Classic)
    local isMatch = false
    if castGUID and _ShieldTile.lastESCastGUID then
        -- Modern client: match by castGUID
        isMatch = (castGUID == _ShieldTile.lastESCastGUID)
    else
        -- TBC/Classic: no castGUID, match by spellName
        local earthShieldName = GetEarthShieldName()
        isMatch = EARTH_SHIELD_SPELL_IDS[spellID] or (spellName == earthShieldName)
    end

    if not isMatch then
        return
    end

    DebugPrint("SPELLCAST_SUCCEEDED: matched! (castGUID=" .. tostring(castGUID) .. ", spellName=" .. tostring(spellName) .. ")")
    DebugPrint("  -> Pending target: name=" .. tostring(_ShieldTile.lastESCastTarget) .. " GUID=" .. tostring(_ShieldTile.lastESCastUnitGUID))

    -- Cancel pending cast timeout timer (cast succeeded, no longer pending)
    if _ShieldTile.pendingCastTimer then
        _ShieldTile.pendingCastTimer:Cancel()
        _ShieldTile.pendingCastTimer = nil
    end

    -- Cancel any existing fallback scan timer
    if _ShieldTile.fallbackScanTimer then
        _ShieldTile.fallbackScanTimer:Cancel()
        _ShieldTile.fallbackScanTimer = nil
    end

    -- Store pending info for fallback scan (don't clear yet - CLEU might need it)
    local pendingGUID = _ShieldTile.lastESCastUnitGUID
    local pendingName = _ShieldTile.lastESCastTarget

    -- Schedule a fallback scan in case CLEU doesn't set earthShieldTarget
    -- CLEU is authoritative, but sometimes it doesn't fire (e.g., target out of range for aura query)
    _ShieldTile.fallbackScanTimer = C_Timer.After(0.5, function()
        _ShieldTile.fallbackScanTimer = nil

        -- Only run fallback if CLEU hasn't already set the target
        if not _ShieldTile.earthShieldTarget then
            DebugPrint("Fallback scan: CLEU didn't set target, scanning...")
            local found = _ShieldTile.ScanTargetForEarthShield(pendingGUID, pendingName)
            if found then
                DebugPrint("Fallback scan: Found Earth Shield on " .. tostring(_ShieldTile.earthShieldTarget.name))
                local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
                if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
                    TotemBar.shieldTile:UpdateStatus()
                end
            else
                DebugPrint("Fallback scan: Earth Shield not found")
            end
        else
            DebugPrint("Fallback scan: CLEU already set target, skipping")
        end
    end)

    -- Clear pending cast state (CLEU will use destGUID/destName from the event itself)
    _ShieldTile.lastESCastTarget = nil
    _ShieldTile.lastESCastGUID = nil
    _ShieldTile.lastESCastUnitGUID = nil
end

--- Clear pending Earth Shield cast state (called on cast failure/interrupt)
---@param spellName string|nil The spell name that failed
function _ShieldTile.ClearPendingCast(spellName)
    -- Only clear if the failed spell is Earth Shield
    local earthShieldName = GetEarthShieldName()
    if spellName and spellName ~= earthShieldName then
        return
    end

    DebugPrint("ClearPendingCast: Clearing stale pending state for " .. tostring(spellName))

    -- Cancel pending cast timeout timer
    if _ShieldTile.pendingCastTimer then
        _ShieldTile.pendingCastTimer:Cancel()
        _ShieldTile.pendingCastTimer = nil
    end

    -- Cancel fallback scan timer
    if _ShieldTile.fallbackScanTimer then
        _ShieldTile.fallbackScanTimer:Cancel()
        _ShieldTile.fallbackScanTimer = nil
    end

    -- Clear pending state
    _ShieldTile.lastESCastTarget = nil
    _ShieldTile.lastESCastGUID = nil
    _ShieldTile.lastESCastUnitGUID = nil
end

--- Handle UNIT_AURA for Earth Shield target - updates charges and duration
---@param unit string The unit that had an aura change
function _ShieldTile.OnTargetAuraChanged(unit)
    -- DISABLED: Party member Earth Shield tracking
    -- Skip if party tracking is disabled and unit is not player
    local trackOnTargets = TotemBuddy.db and TotemBuddy.db.profile.trackEarthShieldOnTargets
    if not trackOnTargets and unit ~= "player" then
        return
    end

    -- Only process if we have a tracked Earth Shield target
    if not _ShieldTile.earthShieldTarget then
        return
    end

    local targetGUID = _ShieldTile.earthShieldTarget.guid
    local targetName = _ShieldTile.earthShieldTarget.name

    -- Check if this unit matches our Earth Shield target
    -- If we have a GUID, match by GUID. If not, try matching by name.
    local unitGUID = UnitGUID(unit)
    local unitName = UnitName(unit)

    local isMatch = false
    if targetGUID and unitGUID then
        isMatch = (unitGUID == targetGUID)
    elseif targetName and unitName then
        -- Fallback to name matching if GUID is unavailable
        isMatch = (unitName == targetName)
    end

    if not isMatch then
        return
    end

    DebugPrint("UNIT_AURA: unit=" .. tostring(unit) .. " matched ES target!")
    DebugPrint("  -> targetGUID=" .. tostring(targetGUID) .. " targetName=" .. tostring(targetName))

    -- Determine the best unit token to use for UnitBuff
    -- Target and focus give more reliable source info than party/raid units
    local scanUnit = unit
    if targetGUID then
        if UnitGUID("target") == targetGUID then
            scanUnit = "target"
            DebugPrint("  -> using 'target' for scan (better source info)")
        elseif UnitGUID("focus") == targetGUID then
            scanUnit = "focus"
            DebugPrint("  -> using 'focus' for scan (better source info)")
        end
    end

    -- Scan the unit for Earth Shield buff info
    local earthShieldName = GetEarthShieldName()
    DebugPrint("  -> scanning for buff: " .. tostring(earthShieldName))
    local found = false

    for i = 1, 40 do
        local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(scanUnit, i)
        if not name then break end

        local isEarthShield = (spellId and EARTH_SHIELD_SPELL_IDS[spellId]) or (not spellId and name == earthShieldName)
        if isEarthShield then
            DebugPrint("  -> found Earth Shield! spellId=" .. tostring(spellId) .. " name=" .. tostring(name) .. " source=" .. tostring(source) .. " count=" .. tostring(count))
            -- Some clients return a unit token for source (e.g., "raid5"),
            -- and some return nil for units outside target/focus.
            if source == nil or source == "player" or UnitIsUnit(source, "player") then
                -- Update tracking data with accurate values
                _ShieldTile.earthShieldTarget.charges = count or 0
                _ShieldTile.earthShieldTarget.endTime = expirationTime or (GetTime() + 600)
                -- Also update the GUID if we didn't have it before
                if not _ShieldTile.earthShieldTarget.guid and unitGUID then
                    _ShieldTile.earthShieldTarget.guid = unitGUID
                    DebugPrint("  -> updated GUID to " .. tostring(unitGUID))
                end
                found = true
                DebugPrint("  -> SUCCESS: charges=" .. tostring(count))
                break
            else
                DebugPrint("  -> SKIPPED: source mismatch (source=" .. tostring(source) .. ")")
            end
        end
    end

    -- If Earth Shield is no longer on the target, clear tracking
    if not found then
        DebugPrint("  -> Earth Shield NOT found on target, clearing tracking")
        _ShieldTile.earthShieldTarget = nil
    end

    -- Update display
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
        TotemBar.shieldTile:UpdateStatus()
    end
end

--- Scan a specific target for Earth Shield charges
---@param targetGUID string|nil
---@param targetName string|nil
---@return boolean found True if Earth Shield was found and earthShieldTarget was updated
function _ShieldTile.ScanTargetForEarthShield(targetGUID, targetName)
    local earthShieldName = GetEarthShieldName()

    -- First try target and focus (most reliable source info)
    local preferredUnits = {}
    if targetGUID then
        if UnitGUID("target") == targetGUID then
            table.insert(preferredUnits, "target")
        end
        if UnitGUID("focus") == targetGUID then
            table.insert(preferredUnits, "focus")
        end
    end

    -- Build list of units to check (preferred units first)
    local unitsToCheck = preferredUnits
    for _, unit in ipairs({ "target", "focus", "player" }) do
        if not tContains(preferredUnits, unit) then
            table.insert(unitsToCheck, unit)
        end
    end

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
            local unitGUID = UnitGUID(unit)
            local unitName = UnitName(unit)

            -- Match by GUID if available, otherwise by name
            local isMatch = false
            if targetGUID and unitGUID then
                isMatch = (unitGUID == targetGUID)
            elseif targetName and unitName then
                isMatch = (unitName == targetName)
            end

            if isMatch then
                for i = 1, 40 do
                    local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                    if not name then break end

                    local isEarthShield = (spellId and EARTH_SHIELD_SPELL_IDS[spellId]) or (not spellId and name == earthShieldName)
                    if isEarthShield then
                        if source == nil or source == "player" or UnitIsUnit(source, "player") then
                            _ShieldTile.earthShieldTarget = {
                                guid = unitGUID or targetGUID,
                                name = targetName or unitName,
                                charges = count or 0,
                                endTime = expirationTime or (GetTime() + 600),
                            }
                            return true
                        end
                    end
                end
                -- If we matched by GUID but didn't find the buff, don't keep searching
                if targetGUID and unitGUID == targetGUID then
                    break
                end
            end
        end
    end
    return false
end

--- Scan all units for Earth Shield (called on login/reload)
function _ShieldTile.ScanAllUnitsForEarthShield()
    local earthShieldName = GetEarthShieldName()

    -- DISABLED: Party member Earth Shield tracking
    -- Only scan player when trackEarthShieldOnTargets is false
    local trackOnTargets = TotemBuddy.db and TotemBuddy.db.profile.trackEarthShieldOnTargets
    if not trackOnTargets then
        -- Only check player for self-shield
        local unitsToCheck = { "player" }
        local checkedGUIDs = {}
        for _, unit in ipairs(unitsToCheck) do
            if UnitExists(unit) then
                local unitGUID = UnitGUID(unit)
                if unitGUID and not checkedGUIDs[unitGUID] then
                    checkedGUIDs[unitGUID] = true
                    for i = 1, 40 do
                        local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                        if not name then break end
                        local isEarthShield = (spellId and EARTH_SHIELD_SPELL_IDS[spellId]) or (not spellId and name == earthShieldName)
                        if isEarthShield and (source == nil or source == "player" or UnitIsUnit(source, "player")) then
                            _ShieldTile.earthShieldTarget = {
                                guid = unitGUID,
                                name = UnitName(unit),
                                charges = count or 0,
                                endTime = expirationTime or (GetTime() + EARTH_SHIELD_DEFAULT_DURATION),
                            }
                            return
                        end
                    end
                end
            end
        end
        _ShieldTile.earthShieldTarget = nil
        return
    end

    -- Build list of units to check (target and focus first for better source info)
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

    -- Track which GUIDs we've already checked to avoid duplicates
    local checkedGUIDs = {}

    -- Scan each unit
    for _, unit in ipairs(unitsToCheck) do
        if UnitExists(unit) then
            local unitGUID = UnitGUID(unit)

            -- Skip if we've already checked this GUID (e.g., target == party2)
            if unitGUID and not checkedGUIDs[unitGUID] then
                checkedGUIDs[unitGUID] = true

                for i = 1, 40 do
                    local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                    if not name then break end

                    -- Use same detection pattern as OnTargetAuraChanged/ScanTargetForEarthShield
                    -- spellId can be nil on some TBC builds, so fall back to name matching
                    local isEarthShield = (spellId and EARTH_SHIELD_SPELL_IDS[spellId]) or (not spellId and name == earthShieldName)
                    -- source can be a unit token like "raid5" instead of "player", so use UnitIsUnit()
                    if isEarthShield and (source == nil or source == "player" or UnitIsUnit(source, "player")) then
                        _ShieldTile.earthShieldTarget = {
                            guid = unitGUID,
                            name = UnitName(unit),
                            charges = count or 0,
                            endTime = expirationTime or (GetTime() + EARTH_SHIELD_DEFAULT_DURATION),
                        }
                        return
                    end
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
    -- DISABLED: Party member Earth Shield tracking
    -- Skip roster update handling when party tracking is disabled
    local trackOnTargets = TotemBuddy.db and TotemBuddy.db.profile.trackEarthShieldOnTargets
    if not trackOnTargets then
        return
    end

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

-- Cache of localized shield spell names (built on first use)
local _shieldNameCache = nil
local function GetShieldNameCache()
    if _shieldNameCache then return _shieldNameCache end

    _shieldNameCache = {}
    local db = GetDB()
    if db and db.Shields then
        for _, shield in ipairs(db.Shields) do
            -- Get localized name from the first spellId
            if shield.spellIds and shield.spellIds[1] then
                local localizedName = GetSpellInfo(shield.spellIds[1])
                if localizedName then
                    _shieldNameCache[localizedName] = true
                end
            end
        end
    end
    return _shieldNameCache
end

--- Check if any known shield is active on player
---@return boolean isActive, string|nil buffName, number|nil charges, number|nil remaining, number|nil spellId
local function GetActiveShieldInfo()
    local db = GetDB()
    if not db then return false end

    -- Get localized shield names for fallback detection
    local shieldNames = GetShieldNameCache()

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        -- Check if this is a known shield spell
        -- Try spellId first, then fall back to name matching (for clients where spellId is nil)
        local isShield = (spellId and db:IsShieldSpell(spellId)) or (not spellId and shieldNames[name])
        if isShield then
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

    -- Check if selector is locked and right-click is disabled
    local lockSelector = TotemBuddy.db.profile.lockSelector
    local rightClickEnabled = TotemBuddy.db.profile.selectorRightClickEnabled
    if lockSelector and not rightClickEnabled then
        -- Right-click disabled when locked, only Shift+hover works
        if not IsShiftKeyDown() then
            return
        end
    end

    if not ShieldSelector then
        ShieldSelector = TotemBuddyLoader:ImportModule("ShieldSelector")
    end

    if ShieldSelector and ShieldSelector.Show then
        ShieldSelector:Show(tile)
    end
end

-- =============================================================================
-- DEBUG COMMANDS
-- =============================================================================

--- Toggle debug mode
function ShieldTile:ToggleDebug()
    _ShieldTile.debugMode = not _ShieldTile.debugMode
    return _ShieldTile.debugMode
end

--- Force scan for Earth Shield (manual trigger)
function ShieldTile:ForceScan()
    DebugPrint("ForceScan triggered")
    _ShieldTile.ScanAllUnitsForEarthShield()
    if _ShieldTile.earthShieldTarget then
        DebugPrint("Found ES on: " .. tostring(_ShieldTile.earthShieldTarget.name))
        -- Update display
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar and TotemBar.shieldTile and TotemBar.shieldTile.UpdateStatus then
            TotemBar.shieldTile:UpdateStatus()
        end
        return true, _ShieldTile.earthShieldTarget.name, _ShieldTile.earthShieldTarget.charges
    end
    return false
end

--- Get debug info about Earth Shield tracking
---@return table debugInfo
function ShieldTile:GetDebugInfo()
    local info = {
        debugMode = _ShieldTile.debugMode,
        earthShieldName = GetEarthShieldName(),
        tracking = nil,
        pending = nil,
        partyUnits = {},
    }

    -- Current tracking state
    if _ShieldTile.earthShieldTarget then
        info.tracking = {
            guid = _ShieldTile.earthShieldTarget.guid,
            name = _ShieldTile.earthShieldTarget.name,
            charges = _ShieldTile.earthShieldTarget.charges,
            endTime = _ShieldTile.earthShieldTarget.endTime,
            remaining = _ShieldTile.earthShieldTarget.endTime and (_ShieldTile.earthShieldTarget.endTime - GetTime()) or nil,
        }
    end

    -- Pending cast state
    if _ShieldTile.lastESCastTarget then
        info.pending = {
            target = _ShieldTile.lastESCastTarget,
            castGUID = _ShieldTile.lastESCastGUID,
            unitGUID = _ShieldTile.lastESCastUnitGUID,
        }
    end

    -- Scan party/raid for Earth Shield buffs
    local unitsToCheck = { "player", "target", "focus" }
    if IsInRaid() then
        for i = 1, 40 do
            table.insert(unitsToCheck, "raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            table.insert(unitsToCheck, "party" .. i)
        end
    end

    local checkedGUIDs = {}
    local earthShieldName = GetEarthShieldName()

    for _, unit in ipairs(unitsToCheck) do
        if UnitExists(unit) then
            local unitGUID = UnitGUID(unit)
            if unitGUID and not checkedGUIDs[unitGUID] then
                checkedGUIDs[unitGUID] = true
                local unitName = UnitName(unit)

                -- Check for Earth Shield buff
                for i = 1, 40 do
                    local name, _, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                    if not name then break end

                    local isEarthShield = (spellId and EARTH_SHIELD_SPELL_IDS[spellId]) or (not spellId and name == earthShieldName)
                    if isEarthShield then
                        table.insert(info.partyUnits, {
                            unit = unit,
                            name = unitName,
                            guid = unitGUID,
                            charges = count,
                            source = source,
                            spellId = spellId,
                            buffName = name,
                        })
                        break
                    end
                end
            end
        end
    end

    return info
end

--- Print debug info to chat
function ShieldTile:PrintDebugInfo()
    local info = self:GetDebugInfo()

    TotemBuddy:Print("=== Earth Shield Debug ===")
    TotemBuddy:Print("Debug mode: " .. (info.debugMode and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    TotemBuddy:Print("CLEU registered: " .. (_ShieldTile.cleuRegistered and "|cff00ff00YES|r" or "|cffff0000NO|r"))
    TotemBuddy:Print("ES spell name: " .. tostring(info.earthShieldName))

    if info.tracking then
        TotemBuddy:Print("--- Current Tracking ---")
        TotemBuddy:Print("  Name: " .. tostring(info.tracking.name))
        TotemBuddy:Print("  GUID: " .. tostring(info.tracking.guid))
        TotemBuddy:Print("  Charges: " .. tostring(info.tracking.charges))
        if info.tracking.remaining then
            TotemBuddy:Print("  Remaining: " .. string.format("%.1f", info.tracking.remaining) .. "s")
        end
    else
        TotemBuddy:Print("--- No Earth Shield tracked ---")
    end

    if info.pending then
        TotemBuddy:Print("--- Pending Cast ---")
        TotemBuddy:Print("  Target: " .. tostring(info.pending.target))
        TotemBuddy:Print("  UnitGUID: " .. tostring(info.pending.unitGUID))
    end

    if #info.partyUnits > 0 then
        TotemBuddy:Print("--- Earth Shields Found in Group ---")
        for _, data in ipairs(info.partyUnits) do
            local sourceStr = data.source or "nil"
            TotemBuddy:Print("  " .. data.unit .. " (" .. tostring(data.name) .. "): " ..
                tostring(data.charges) .. " charges, spellId=" .. tostring(data.spellId) .. ", source=" .. sourceStr)
        end
    else
        TotemBuddy:Print("--- No Earth Shields in group ---")
    end
end

return ShieldTile
