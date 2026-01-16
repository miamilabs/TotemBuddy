--[[
    TotemBuddy - Spell Scanner Module
    Scans the player's spellbook to detect known totem spells
]]

---@class SpellScanner
local SpellScanner = TotemBuddyLoader:CreateModule("SpellScanner")
local _SpellScanner = SpellScanner.private

-- Module references (resolved on first use)
local TotemData = nil

--- Get TotemData module (lazy load)
local function GetTotemData()
    if not TotemData then
        TotemData = TotemBuddyLoader:ImportModule("TotemData")
    end
    return TotemData
end

--- Scan the spellbook for known totem spells
function SpellScanner:ScanTotems()
    local totemData = GetTotemData()
    if not totemData then
        return
    end

    -- Clear existing cache
    TotemBuddy.KnownTotems = {}
    TotemBuddy.HighestRanks = {}

    -- Scan all spellbook tabs
    local numTabs = GetNumSpellTabs()
    for tab = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tab)

        for slot = offset + 1, offset + numSlots do
            local spellType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)

            if spellType == "SPELL" and spellId then
                -- Check if this is a totem spell
                if totemData:IsTotemSpell(spellId) then
                    TotemBuddy.KnownTotems[spellId] = true
                end
            end
        end
    end

    -- Now calculate highest ranks for each totem
    self:UpdateHighestRanks()
end

--- Update the highest rank cache based on known totems
function SpellScanner:UpdateHighestRanks()
    local totemData = GetTotemData()
    if not totemData then
        return
    end

    TotemBuddy.HighestRanks = {}

    -- Iterate through all elements and totems
    for _, element in ipairs(totemData:GetAllElements()) do
        local totems = totemData:GetTotemsForElement(element)

        for _, totem in ipairs(totems) do
            local highestSpellId = totemData:GetHighestKnownRank(totem, TotemBuddy.KnownTotems)
            if highestSpellId then
                TotemBuddy.HighestRanks[totem.name] = highestSpellId
            end
        end
    end
end

--- Check if a totem is known (any rank)
---@param totemData table The totem data from database
---@return boolean isKnown Whether the player knows any rank of this totem
function SpellScanner:IsTotemKnown(totemData)
    if not totemData or not totemData.spellIds then
        return false
    end

    for _, spellId in ipairs(totemData.spellIds) do
        if TotemBuddy.KnownTotems[spellId] then
            return true
        end
    end

    return false
end

--- Check if a specific spell ID is known
---@param spellId number The spell ID to check
---@return boolean isKnown Whether the player knows this spell
function SpellScanner:IsSpellKnown(spellId)
    return TotemBuddy.KnownTotems[spellId] == true
end

--- Get the highest known rank spell ID for a totem
---@param totemName string The totem name
---@return number|nil spellId The highest known rank spell ID
function SpellScanner:GetHighestRank(totemName)
    return TotemBuddy.HighestRanks[totemName]
end

--- Get all known totem spell IDs
---@return table knownTotems Table of known spell IDs
function SpellScanner:GetKnownTotems()
    return TotemBuddy.KnownTotems
end

--- Get the number of known totems for an element
---@param element number The element (1-4)
---@return number count The number of known totems
function SpellScanner:GetKnownTotemCountForElement(element)
    local totemData = GetTotemData()
    if not totemData then
        return 0
    end

    local count = 0
    local totems = totemData:GetTotemsForElement(element)

    for _, totem in ipairs(totems) do
        if self:IsTotemKnown(totem) then
            count = count + 1
        end
    end

    return count
end

--- Get the first known totem for an element (for defaults)
---@param element number The element (1-4)
---@return table|nil totemData The first known totem data or nil
function SpellScanner:GetFirstKnownTotemForElement(element)
    local totemData = GetTotemData()
    if not totemData then
        return nil
    end

    local totems = totemData:GetTotemsForElement(element)

    for _, totem in ipairs(totems) do
        if self:IsTotemKnown(totem) then
            return totem
        end
    end

    return nil
end

return SpellScanner
