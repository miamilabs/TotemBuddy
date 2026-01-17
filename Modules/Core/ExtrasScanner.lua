--[[
    TotemBuddy - Extras Scanner Module
    Scans the player's spellbook for Call spells, Weapon Imbues, and Shields
]]

---@class ExtrasScanner
local ExtrasScanner = TotemBuddyLoader:CreateModule("ExtrasScanner")
local _ExtrasScanner = ExtrasScanner.private

-- Database reference (lazy loaded)
local ShamanExtrasDB = nil

--- Get the database (lazy load)
local function GetDB()
    if not ShamanExtrasDB then
        ShamanExtrasDB = _G.TotemBuddyShamanExtras
    end
    return ShamanExtrasDB
end

-- =============================================================================
-- MAIN SCAN FUNCTION
-- =============================================================================

--- Scan all extras (Call spells, Imbues, Shields)
function ExtrasScanner:ScanAllExtras()
    self:ScanCallSpells()
    self:ScanImbueSpells()
    self:ScanShieldSpells()
    self:UpdateHighestRanks()

    -- Update availability flags
    TotemBuddy.HasAnyCallSpells = self:HasAnyKnownCallSpells()
    TotemBuddy.HasAnyImbueSpells = self:HasAnyKnownImbues()
    TotemBuddy.HasAnyShieldSpells = self:HasAnyKnownShields()
end

-- =============================================================================
-- CALL SPELLS
-- =============================================================================

--- Scan spellbook for known Call spells
function ExtrasScanner:ScanCallSpells()
    local db = GetDB()
    if not db then return end

    -- Clear existing cache
    TotemBuddy.KnownCallSpells = {}

    -- Scan all spellbook tabs
    local numTabs = GetNumSpellTabs()
    for tab = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tab)

        for slot = offset + 1, offset + numSlots do
            local spellType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)

            if spellType == "SPELL" and spellId then
                if db:IsCallSpell(spellId) then
                    TotemBuddy.KnownCallSpells[spellId] = true
                end
            end
        end
    end
end

--- Check if player knows any Call spells
---@return boolean
function ExtrasScanner:HasAnyKnownCallSpells()
    if not TotemBuddy.KnownCallSpells then return false end
    for _ in pairs(TotemBuddy.KnownCallSpells) do
        return true
    end
    return false
end

--- Get all known Call spells with their data
---@return table knownCalls Array of {spellId, data} pairs
function ExtrasScanner:GetKnownCallSpells()
    local db = GetDB()
    if not db or not TotemBuddy.KnownCallSpells then return {} end

    local result = {}
    for spellId in pairs(TotemBuddy.KnownCallSpells) do
        local data = db:GetCallSpell(spellId)
        if data then
            table.insert(result, {spellId = spellId, data = data})
        end
    end

    return result
end

-- =============================================================================
-- WEAPON IMBUES
-- =============================================================================

--- Scan spellbook for known Weapon Imbue spells
function ExtrasScanner:ScanImbueSpells()
    local db = GetDB()
    if not db then return end

    -- Clear existing cache
    TotemBuddy.KnownImbues = {}

    -- Scan all spellbook tabs
    local numTabs = GetNumSpellTabs()
    for tab = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tab)

        for slot = offset + 1, offset + numSlots do
            local spellType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)

            if spellType == "SPELL" and spellId then
                if db:IsImbueSpell(spellId) then
                    TotemBuddy.KnownImbues[spellId] = true
                end
            end
        end
    end
end

--- Check if player knows any Imbue spells
---@return boolean
function ExtrasScanner:HasAnyKnownImbues()
    if not TotemBuddy.KnownImbues then return false end
    for _ in pairs(TotemBuddy.KnownImbues) do
        return true
    end
    return false
end

--- Get all known Imbue spells with their data (highest rank only per imbue type)
---@return table knownImbues Array of {spellId, data} pairs
function ExtrasScanner:GetKnownImbues()
    local db = GetDB()
    if not db or not TotemBuddy.KnownImbues then return {} end

    local result = {}
    local seenNames = {}

    -- Use highest ranks from our cache
    for imbueName, spellId in pairs(TotemBuddy.HighestImbueRanks or {}) do
        local data = db:GetImbue(spellId)
        if data and not seenNames[imbueName] then
            seenNames[imbueName] = true
            table.insert(result, {spellId = spellId, data = data})
        end
    end

    return result
end

--- Check if a specific imbue is known (any rank)
---@param imbueName string The imbue name
---@return boolean
function ExtrasScanner:IsImbueKnown(imbueName)
    return TotemBuddy.HighestImbueRanks and TotemBuddy.HighestImbueRanks[imbueName] ~= nil
end

-- =============================================================================
-- SHIELDS
-- =============================================================================

--- Scan spellbook for known Shield spells
function ExtrasScanner:ScanShieldSpells()
    local db = GetDB()
    if not db then return end

    -- Clear existing cache
    TotemBuddy.KnownShields = {}

    -- Scan all spellbook tabs
    local numTabs = GetNumSpellTabs()
    for tab = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tab)

        for slot = offset + 1, offset + numSlots do
            local spellType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)

            if spellType == "SPELL" and spellId then
                if db:IsShieldSpell(spellId) then
                    TotemBuddy.KnownShields[spellId] = true
                end
            end
        end
    end
end

--- Check if player knows any Shield spells
---@return boolean
function ExtrasScanner:HasAnyKnownShields()
    if not TotemBuddy.KnownShields then return false end
    for _ in pairs(TotemBuddy.KnownShields) do
        return true
    end
    return false
end

--- Get all known Shield spells with their data (highest rank only per shield type)
---@return table knownShields Array of {spellId, data} pairs
function ExtrasScanner:GetKnownShields()
    local db = GetDB()
    if not db or not TotemBuddy.KnownShields then return {} end

    local result = {}
    local seenNames = {}

    -- Use highest ranks from our cache
    for shieldName, spellId in pairs(TotemBuddy.HighestShieldRanks or {}) do
        local data = db:GetShield(spellId)
        if data and not seenNames[shieldName] then
            seenNames[shieldName] = true
            table.insert(result, {spellId = spellId, data = data})
        end
    end

    return result
end

--- Check if a specific shield is known (any rank)
---@param shieldName string The shield name
---@return boolean
function ExtrasScanner:IsShieldKnown(shieldName)
    return TotemBuddy.HighestShieldRanks and TotemBuddy.HighestShieldRanks[shieldName] ~= nil
end

-- =============================================================================
-- HIGHEST RANK CALCULATION
-- =============================================================================

--- Update highest rank caches for all extras
function ExtrasScanner:UpdateHighestRanks()
    local db = GetDB()
    if not db then return end

    -- Call spells (usually single rank, but be safe)
    TotemBuddy.HighestCallRanks = {}
    for _, callSpell in ipairs(db:GetAllCallSpells()) do
        local highest = db:GetHighestKnownRank(callSpell.spellIds, TotemBuddy.KnownCallSpells or {})
        if highest then
            TotemBuddy.HighestCallRanks[callSpell.name] = highest
        end
    end

    -- Weapon Imbues
    TotemBuddy.HighestImbueRanks = {}
    for _, imbue in ipairs(db:GetAllImbues()) do
        local highest = db:GetHighestKnownRank(imbue.spellIds, TotemBuddy.KnownImbues or {})
        if highest then
            TotemBuddy.HighestImbueRanks[imbue.name] = highest
        end
    end

    -- Shields
    TotemBuddy.HighestShieldRanks = {}
    for _, shield in ipairs(db:GetAllShields()) do
        local highest = db:GetHighestKnownRank(shield.spellIds, TotemBuddy.KnownShields or {})
        if highest then
            TotemBuddy.HighestShieldRanks[shield.name] = highest
        end
    end
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

--- Get the highest known rank spell ID for a Call spell by name
---@param name string The Call spell name
---@return number|nil spellId
function ExtrasScanner:GetHighestCallRank(name)
    return TotemBuddy.HighestCallRanks and TotemBuddy.HighestCallRanks[name]
end

--- Get the highest known rank spell ID for an Imbue by name
---@param name string The Imbue name
---@return number|nil spellId
function ExtrasScanner:GetHighestImbueRank(name)
    return TotemBuddy.HighestImbueRanks and TotemBuddy.HighestImbueRanks[name]
end

--- Get the highest known rank spell ID for a Shield by name
---@param name string The Shield name
---@return number|nil spellId
function ExtrasScanner:GetHighestShieldRank(name)
    return TotemBuddy.HighestShieldRanks and TotemBuddy.HighestShieldRanks[name]
end

--- Get the first known Call spell (for defaults)
---@return number|nil spellId, table|nil data
function ExtrasScanner:GetFirstKnownCallSpell()
    local known = self:GetKnownCallSpells()
    if #known > 0 then
        return known[1].spellId, known[1].data
    end
    return nil, nil
end

--- Get the first known Imbue (for defaults)
---@return number|nil spellId, table|nil data
function ExtrasScanner:GetFirstKnownImbue()
    local known = self:GetKnownImbues()
    if #known > 0 then
        return known[1].spellId, known[1].data
    end
    return nil, nil
end

--- Get the first known Shield (for defaults)
---@return number|nil spellId, table|nil data
function ExtrasScanner:GetFirstKnownShield()
    local known = self:GetKnownShields()
    if #known > 0 then
        return known[1].spellId, known[1].data
    end
    return nil, nil
end

return ExtrasScanner
