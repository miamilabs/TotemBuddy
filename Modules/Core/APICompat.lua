--[[
    TotemBuddy - API Compatibility Layer
    Provides unified totem API that works across all Classic variants
    (Era, TBC, WotLK Anniversary)

    If GetTotemInfo/GetTotemTimeLeft are unavailable, implements a
    fallback tracker using COMBAT_LOG_EVENT_UNFILTERED and known durations.
]]

---@class APICompat
local APICompat = TotemBuddyLoader:CreateModule("APICompat")
local _APICompat = APICompat.private

-- Localize globals
local GetTime = GetTime
local GetTotemInfo = GetTotemInfo
local GetTotemTimeLeft = GetTotemTimeLeft
local UnitGUID = UnitGUID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetSpellInfo = GetSpellInfo

-- API detection flags (set once at load time)
_APICompat.hasNativeGetTotemInfo = (GetTotemInfo ~= nil)
_APICompat.hasNativeGetTotemTimeLeft = (GetTotemTimeLeft ~= nil)
_APICompat.initialized = false

-- Fallback totem state tracking (used when native API unavailable)
-- Slot order: Fire=1, Earth=2, Water=3, Air=4
_APICompat.totemState = {
    [1] = { haveTotem = false, name = nil, startTime = 0, duration = 0, icon = nil, spellId = nil },
    [2] = { haveTotem = false, name = nil, startTime = 0, duration = 0, icon = nil, spellId = nil },
    [3] = { haveTotem = false, name = nil, startTime = 0, duration = 0, icon = nil, spellId = nil },
    [4] = { haveTotem = false, name = nil, startTime = 0, duration = 0, icon = nil, spellId = nil },
}

-- Known totem durations (seconds) - used for fallback tracker
-- Most totems last 120 seconds (2 minutes) unless otherwise specified
_APICompat.totemDurations = {
    -- Fire totems
    [3599] = 30,   -- Searing Totem (all ranks)
    [6363] = 35,
    [6364] = 40,
    [6365] = 45,
    [10437] = 50,
    [10438] = 55,
    [1535] = 5,    -- Fire Nova Totem (all ranks) - short duration
    [8498] = 5,
    [8499] = 5,
    [11314] = 5,
    [11315] = 5,
    [8190] = 20,   -- Magma Totem (all ranks)
    [10585] = 20,
    [10586] = 20,
    [10587] = 20,
    [8227] = 120,  -- Flametongue Totem
    [8249] = 120,
    [10526] = 120,
    [16387] = 120,
    [8181] = 120,  -- Frost Resistance Totem
    [10478] = 120,
    [10479] = 120,

    -- Earth totems (most are 120s)
    [2484] = 45,   -- Earthbind Totem
    [5730] = 15,   -- Stoneclaw Totem (all ranks)
    [6390] = 15,
    [6391] = 15,
    [6392] = 15,
    [10427] = 15,
    [10428] = 15,
    [8071] = 120,  -- Stoneskin Totem
    [8154] = 120,
    [8155] = 120,
    [10406] = 120,
    [10407] = 120,
    [10408] = 120,
    [8075] = 120,  -- Strength of Earth Totem
    [8160] = 120,
    [8161] = 120,
    [10442] = 120,
    [25361] = 120,
    [8143] = 120,  -- Tremor Totem

    -- Water totems
    [5394] = 60,   -- Healing Stream Totem (all ranks)
    [6375] = 60,
    [6377] = 60,
    [10462] = 60,
    [10463] = 60,
    [5675] = 60,   -- Mana Spring Totem (all ranks)
    [10495] = 60,
    [10496] = 60,
    [10497] = 60,
    [8184] = 120,  -- Fire Resistance Totem
    [10537] = 120,
    [10538] = 120,
    [8170] = 120,  -- Disease Cleansing Totem
    [16190] = 12,  -- Mana Tide Totem (all ranks) - short duration
    [17354] = 12,
    [17359] = 12,
    [8166] = 120,  -- Poison Cleansing Totem

    -- Air totems
    [8835] = 120,  -- Grace of Air Totem
    [10627] = 120,
    [25359] = 120,
    [10595] = 120, -- Nature Resistance Totem
    [10600] = 120,
    [10601] = 120,
    [15107] = 120, -- Windwall Totem
    [15111] = 120,
    [15112] = 120,
    [8177] = 45,   -- Grounding Totem
    [8512] = 120,  -- Windfury Totem
    [10613] = 120,
    [10614] = 120,
    [6495] = 300,  -- Sentry Totem (5 minutes)
    [25908] = 120, -- Tranquil Air Totem

    -- TBC totems (will be loaded from TBCTotems.lua if present)
    [2062] = 120,  -- Earth Elemental Totem
    [2894] = 120,  -- Fire Elemental Totem
    [30706] = 120, -- Totem of Wrath
    [3738] = 120,  -- Wrath of Air Totem
}

-- Player GUID (for combat log filtering)
_APICompat.playerGUID = nil

-- Combat log event frame
_APICompat.eventFrame = nil

--- Initialize the module
function APICompat:Initialize()
    if _APICompat.initialized then return end
    _APICompat.initialized = true

    -- Cache player GUID
    _APICompat.playerGUID = UnitGUID("player")

    -- Log API detection results
    if TotemBuddy and TotemBuddy.db and TotemBuddy.db.profile then
        local status = _APICompat.hasNativeGetTotemInfo and "native" or "fallback"
        -- Debug logging (only in debug mode)
        -- TotemBuddy:Print("APICompat: Using " .. status .. " totem tracking")
    end

    -- If native API is missing, set up fallback tracker and provide global shims
    if not _APICompat.hasNativeGetTotemInfo then
        self:SetupFallbackTracker()

        -- Provide global wrappers so other modules calling GetTotemInfo/GetTotemTimeLeft don't error
        -- These shims allow code like GetTotemInfo(slot) to work on Classic Era where the API is missing
        if _G.GetTotemInfo == nil then
            _G.GetTotemInfo = function(slot)
                return APICompat:GetTotemInfo(slot)
            end
        end
        if _G.GetTotemTimeLeft == nil then
            _G.GetTotemTimeLeft = function(slot)
                return APICompat:GetTotemTimeLeft(slot)
            end
        end
    end
end

--- Set up the fallback totem tracker using combat log
function APICompat:SetupFallbackTracker()
    if _APICompat.eventFrame then return end

    _APICompat.eventFrame = CreateFrame("Frame")
    _APICompat.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    _APICompat.eventFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
    _APICompat.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    _APICompat.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            self:OnCombatLogEvent()
        elseif event == "PLAYER_TOTEM_UPDATE" then
            local slot = ...
            self:OnTotemUpdate(slot)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Re-cache player GUID (can change on login)
            _APICompat.playerGUID = UnitGUID("player")
            -- Clear totem state on login/reload
            self:ClearAllTotemState()
        end
    end)
end

--- Handle combat log events for fallback tracking
function APICompat:OnCombatLogEvent()
    local _, event, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()

    -- Only process our own events
    if sourceGUID ~= _APICompat.playerGUID then return end

    -- Check if this spell is a totem
    local TotemDatabase = _G.TotemBuddyTotemDatabase
    if not TotemDatabase or not TotemDatabase.SpellToTotem then return end

    local totemData = TotemDatabase.SpellToTotem[spellId]
    if not totemData then return end

    if event == "SPELL_SUMMON" then
        -- Totem was placed
        local slot = tonumber(totemData.element)
        -- Validate slot is a valid element index (1-4)
        if not slot or slot < 1 or slot > 4 then
            return
        end
        local name = GetSpellInfo(spellId) or totemData.name
        local duration = _APICompat.totemDurations[spellId] or 120

        _APICompat.totemState[slot] = {
            haveTotem = true,
            name = name,
            startTime = GetTime(),
            duration = duration,
            icon = totemData.icon,
            spellId = spellId,
        }
    end
end

--- Handle PLAYER_TOTEM_UPDATE for fallback tracking
---@param slot number The totem slot that updated
function APICompat:OnTotemUpdate(slot)
    if not slot or slot < 1 or slot > 4 then return end

    -- If native API available, we can use it to verify
    if _APICompat.hasNativeGetTotemInfo then
        return -- Let native API handle it
    end

    -- In fallback mode, PLAYER_TOTEM_UPDATE with no recent summon = totem died/recalled
    -- We use a simple heuristic: if the totem was active, mark it as inactive
    local state = _APICompat.totemState[slot]
    if state and state.haveTotem then
        local timeLeft = (state.startTime + state.duration) - GetTime()
        if timeLeft <= 0 then
            -- Totem expired naturally
            self:ClearTotemSlot(slot)
        end
        -- Otherwise, could be destroyed or recalled - hard to detect without native API
        -- For safety, we don't clear immediately; let the timer handle natural expiration
    end
end

--- Clear totem state for a specific slot
---@param slot number The slot to clear (1-4)
function APICompat:ClearTotemSlot(slot)
    _APICompat.totemState[slot] = {
        haveTotem = false,
        name = nil,
        startTime = 0,
        duration = 0,
        icon = nil,
        spellId = nil,
    }
end

--- Clear all totem state
function APICompat:ClearAllTotemState()
    for slot = 1, 4 do
        self:ClearTotemSlot(slot)
    end
end

--- Get totem information for a slot (unified API)
---@param slot number The totem slot (1=Fire, 2=Earth, 3=Water, 4=Air)
---@return boolean haveTotem Whether a totem is active in this slot
---@return string|nil name The totem name (localized)
---@return number startTime When the totem was placed (GetTime() value)
---@return number duration Total duration of the totem in seconds
---@return string|nil icon The icon texture path
function APICompat:GetTotemInfo(slot)
    if not slot or slot < 1 or slot > 4 then
        return false, nil, 0, 0, nil
    end

    -- Use native API if available
    if _APICompat.hasNativeGetTotemInfo then
        local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
        return haveTotem, name, startTime, duration, icon
    end

    -- Fallback: use our tracked state
    local state = _APICompat.totemState[slot]
    if not state then
        return false, nil, 0, 0, nil
    end

    -- Check if totem has expired
    if state.haveTotem and state.duration > 0 then
        local timeLeft = (state.startTime + state.duration) - GetTime()
        if timeLeft <= 0 then
            -- Totem expired, clear state
            self:ClearTotemSlot(slot)
            return false, nil, 0, 0, nil
        end
    end

    return state.haveTotem, state.name, state.startTime, state.duration, state.icon
end

--- Get remaining time for a totem (unified API)
---@param slot number The totem slot (1=Fire, 2=Earth, 3=Water, 4=Air)
---@return number timeLeft Remaining time in seconds (0 if no totem or expired)
function APICompat:GetTotemTimeLeft(slot)
    if not slot or slot < 1 or slot > 4 then
        return 0
    end

    -- Use native API if available
    if _APICompat.hasNativeGetTotemTimeLeft then
        return GetTotemTimeLeft(slot) or 0
    end

    -- Fallback: calculate from tracked state
    local state = _APICompat.totemState[slot]
    if not state or not state.haveTotem or state.duration <= 0 then
        return 0
    end

    local remaining = (state.startTime + state.duration) - GetTime()
    return math.max(0, remaining)
end

--- Check if native totem API is available
---@return boolean hasNative True if GetTotemInfo exists
function APICompat:HasNativeAPI()
    return _APICompat.hasNativeGetTotemInfo
end

--- Get the duration for a totem spell (for fallback tracker)
---@param spellId number The spell ID
---@return number duration Duration in seconds (defaults to 120)
function APICompat:GetTotemDuration(spellId)
    return _APICompat.totemDurations[spellId] or 120
end

--- Register additional totem durations (for expansion modules)
---@param durations table A table of spellId -> duration mappings
function APICompat:RegisterTotemDurations(durations)
    if type(durations) ~= "table" then return end

    for spellId, duration in pairs(durations) do
        _APICompat.totemDurations[spellId] = duration
    end
end

--- Force update totem state from a cast (used when we detect a totem cast ourselves)
---@param slot number The totem slot
---@param spellId number The spell ID that was cast
---@param name string|nil Optional override name
function APICompat:OnTotemCast(slot, spellId, name)
    if _APICompat.hasNativeGetTotemInfo then
        return -- Native API handles this
    end

    if not slot or slot < 1 or slot > 4 then return end

    local TotemDatabase = _G.TotemBuddyTotemDatabase
    local totemData = TotemDatabase and TotemDatabase.SpellToTotem and TotemDatabase.SpellToTotem[spellId]

    local totemName = name or (GetSpellInfo(spellId)) or (totemData and totemData.name) or "Unknown"
    local duration = _APICompat.totemDurations[spellId] or 120
    local icon = totemData and totemData.icon

    _APICompat.totemState[slot] = {
        haveTotem = true,
        name = totemName,
        startTime = GetTime(),
        duration = duration,
        icon = icon,
        spellId = spellId,
    }
end

return APICompat
