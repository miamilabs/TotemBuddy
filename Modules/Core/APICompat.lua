--[[
    TotemBuddy - API Compatibility Layer
    Provides unified totem API wrapper for TBC Classic
]]

---@class APICompat
local APICompat = TotemBuddyLoader:CreateModule("APICompat")
local _APICompat = APICompat.private

-- Localize globals
local GetTime = GetTime
local GetTotemInfo = GetTotemInfo
local GetTotemTimeLeft = GetTotemTimeLeft

_APICompat.initialized = false

--- Initialize the module
function APICompat:Initialize()
    if _APICompat.initialized then return end
    _APICompat.initialized = true
end

--- Get totem information for a slot
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
    return GetTotemInfo(slot)
end

--- Get remaining time for a totem
---@param slot number The totem slot (1=Fire, 2=Earth, 3=Water, 4=Air)
---@return number timeLeft Remaining time in seconds (0 if no totem or expired)
function APICompat:GetTotemTimeLeft(slot)
    if not slot or slot < 1 or slot > 4 then
        return 0
    end
    return GetTotemTimeLeft(slot) or 0
end

--- Check if native totem API is available (always true for TBC)
---@return boolean hasNative True if GetTotemInfo exists
function APICompat:HasNativeAPI()
    return true
end

return APICompat
