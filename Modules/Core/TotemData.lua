--[[
    TotemBuddy - Totem Data Module
    Provides interface to totem database
]]

---@class TotemData
local TotemData = TotemBuddyLoader:CreateModule("TotemData")
local _TotemData = TotemData.private

-- Reference to the database (loaded from Data/ClassicTotems.lua etc)
local Database = nil

--- Initialize the module
function TotemData:Initialize()
    Database = _G.TotemBuddyTotemDatabase
    if not Database then
        TotemBuddy:Print("Error: Totem database not loaded!")
    end
end

--- Get the totem database
---@return table database The totem database
function TotemData:GetDatabase()
    if not Database then
        self:Initialize()
    end
    return Database
end

-- Name lookup cache (built on first use)
local NameToTotemCache = nil

--- Build name lookup cache for efficient GetTotemByName
local function BuildNameCache()
    if NameToTotemCache then
        return
    end

    NameToTotemCache = {}
    local db = TotemData:GetDatabase()
    if not db then
        return
    end

    for element = 1, 4 do
        local totems = db[element]
        if totems then
            for _, totem in ipairs(totems) do
                if totem.name then
                    NameToTotemCache[totem.name] = totem
                end
            end
        end
    end
end

--- Get totem data by name (O(1) lookup via cache)
---@param name string The totem name
---@return table|nil totemData The totem data or nil
function TotemData:GetTotemByName(name)
    if not name then
        return nil
    end

    BuildNameCache()
    return NameToTotemCache and NameToTotemCache[name] or nil
end

--- Get all totems for an element
---@param element number The element (1=Earth, 2=Fire, 3=Water, 4=Air)
---@return table totems List of totem data for that element
function TotemData:GetTotemsForElement(element)
    local db = self:GetDatabase()
    return db and db[element] or {}
end

--- Get totem data by spell ID
---@param spellId number The spell ID
---@return table|nil totemData The totem data or nil
function TotemData:GetTotemBySpellId(spellId)
    local db = self:GetDatabase()
    return db and db.SpellToTotem and db.SpellToTotem[spellId] or nil
end

--- Check if a spell ID is a totem spell
---@param spellId number The spell ID to check
---@return boolean isTotem Whether it's a totem spell
function TotemData:IsTotemSpell(spellId)
    local db = self:GetDatabase()
    return db and db.AllTotemSpellIds and db.AllTotemSpellIds[spellId] or false
end

--- Get the highest rank spell ID for a totem
---@param totemData table The totem data
---@param knownSpells table Table of known spell IDs [spellId] = true
---@return number|nil spellId The highest known rank spell ID
function TotemData:GetHighestKnownRank(totemData, knownSpells)
    if not totemData or not totemData.spellIds then
        return nil
    end

    -- Iterate backwards through spell IDs (highest rank first)
    for i = #totemData.spellIds, 1, -1 do
        local spellId = totemData.spellIds[i]
        if knownSpells[spellId] then
            return spellId
        end
    end

    return nil
end

--- Get the rank number for a spell ID
---@param totemData table The totem data
---@param spellId number The spell ID
---@return number rank The rank number (1-based) or 0 if not found
function TotemData:GetRankForSpellId(totemData, spellId)
    if not totemData or not totemData.spellIds then
        return 0
    end

    for rank, sid in ipairs(totemData.spellIds) do
        if sid == spellId then
            return rank
        end
    end

    return 0
end

--- Get the total number of ranks for a totem
---@param totemData table The totem data
---@return number totalRanks The total number of ranks
function TotemData:GetTotalRanks(totemData)
    if not totemData or not totemData.spellIds then
        return 0
    end
    return #totemData.spellIds
end

--- Get all elements (for iteration)
---@return table elements List of element IDs {1, 2, 3, 4}
function TotemData:GetAllElements()
    return {1, 2, 3, 4}
end

--- Get element name (matches WoW API: 1=Fire, 2=Earth, 3=Water, 4=Air)
---@param element number The element ID
---@return string name The element name
function TotemData:GetElementName(element)
    local names = {"Fire", "Earth", "Water", "Air"}
    return names[element] or "Unknown"
end

--- Get element color (matches WoW API: 1=Fire, 2=Earth, 3=Water, 4=Air)
---@param element number The element ID
---@return number r Red (0-1)
---@return number g Green (0-1)
---@return number b Blue (0-1)
function TotemData:GetElementColor(element)
    local colors = {
        {1.0, 0.4, 0.1},   -- Fire: Orange
        {0.6, 0.4, 0.2},   -- Earth: Brown
        {0.2, 0.5, 1.0},   -- Water: Blue
        {0.7, 0.7, 0.9},   -- Air: Light purple
    }
    local c = colors[element] or {1, 1, 1}
    return c[1], c[2], c[3]
end

return TotemData
