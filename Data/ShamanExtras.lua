--[[
    TotemBuddy - Shaman Extras Database
    Contains spell data for Call of Totems, Weapon Imbues, and Shields

    Note: SpellIDs are for TBC/Classic Era. Some spells may not exist
    on all server versions - the scanner will detect what's available.
]]

-- Create global database
_G.TotemBuddyShamanExtras = _G.TotemBuddyShamanExtras or {}
local DB = _G.TotemBuddyShamanExtras

-- =============================================================================
-- CALL OF THE TOTEMS
-- =============================================================================
-- These spells drop multiple totems at once (TBC/WotLK feature)
-- Note: Availability depends on talents and expansion

DB.CallSpells = {
    {
        name = "Call of the Elements",
        -- Drops Fire + Earth totems
        spellIds = {66842},
        icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem",
        dropsElements = {1, 2},  -- Fire, Earth
        description = "Places your Fire and Earth totems",
    },
    {
        name = "Call of the Ancestors",
        -- Drops Water + Air totems
        spellIds = {66843},
        icon = "Interface\\Icons\\Spell_Nature_Invisibilty",
        dropsElements = {3, 4},  -- Water, Air
        description = "Places your Water and Air totems",
    },
    {
        name = "Call of the Spirits",
        -- Drops all 4 totems
        spellIds = {66844},
        icon = "Interface\\Icons\\Spell_Shaman_TotemRecall",
        dropsElements = {1, 2, 3, 4},  -- All
        description = "Places all four totems",
    },
    {
        name = "Totemic Recall",
        -- Destroys totems and returns mana
        spellIds = {36936},
        icon = "Interface\\Icons\\Spell_Shaman_TotemRecall",
        recallsAll = true,
        description = "Destroys your totems and returns mana",
    },
}

-- Build lookup table for quick spell checking
DB.CallSpellLookup = {}
DB.AllCallSpellIds = {}
for _, spell in ipairs(DB.CallSpells) do
    for _, spellId in ipairs(spell.spellIds) do
        DB.CallSpellLookup[spellId] = spell
        DB.AllCallSpellIds[spellId] = true
    end
end

-- =============================================================================
-- WEAPON IMBUES
-- =============================================================================
-- Shaman weapon enchantments (temporary)
-- SpellIDs ordered by rank (lowest to highest)

DB.WeaponImbues = {
    {
        name = "Rockbiter Weapon",
        spellIds = {8017, 8018, 8019, 10399, 16314, 16315, 16316, 25479, 25500},
        icon = "Interface\\Icons\\Spell_Nature_RockBiter",
        description = "Increases melee damage",
        element = "earth",
    },
    {
        name = "Flametongue Weapon",
        spellIds = {8024, 8027, 8030, 16339, 16341, 16342, 25489},
        icon = "Interface\\Icons\\Spell_Fire_FlameTounge",
        description = "Adds fire damage to attacks",
        element = "fire",
    },
    {
        name = "Frostbrand Weapon",
        -- Ranks: 1=8033, 2=8038, 3=10456, 4=16355, 5=16356, 6=25501
        spellIds = {8033, 8038, 10456, 16355, 16356, 25501},
        icon = "Interface\\Icons\\Spell_Frost_IceShock",
        description = "Adds frost damage and slows",
        element = "frost",
    },
    {
        name = "Windfury Weapon",
        spellIds = {8232, 8235, 10486, 16362, 25505},
        icon = "Interface\\Icons\\Spell_Nature_Cyclone",
        description = "Chance for extra attacks",
        element = "air",
    },
    {
        name = "Earthliving Weapon",
        -- WotLK only - may not exist in TBC
        spellIds = {51730, 51988, 51991, 51992, 51993, 51994},
        icon = "Interface\\Icons\\Spell_Shaman_EarthlivingWeapon",
        description = "Heals are improved",
        element = "earth",
        wotlkOnly = true,
    },
}

-- Build lookup table for weapon imbues
DB.ImbueLookup = {}
DB.AllImbueSpellIds = {}
for _, imbue in ipairs(DB.WeaponImbues) do
    for _, spellId in ipairs(imbue.spellIds) do
        DB.ImbueLookup[spellId] = imbue
        DB.AllImbueSpellIds[spellId] = true
    end
end

-- =============================================================================
-- SHIELDS
-- =============================================================================
-- Shaman self-buff shields
-- SpellIDs ordered by rank (lowest to highest)

DB.Shields = {
    {
        name = "Lightning Shield",
        spellIds = {324, 325, 905, 945, 8134, 10431, 10432, 25469, 25472},
        icon = "Interface\\Icons\\Spell_Nature_LightningShield",
        description = "Damages attackers",
        hasCharges = true,
        targetSelf = true,
    },
    {
        name = "Water Shield",
        -- TBC spell
        spellIds = {24398, 33736},
        icon = "Interface\\Icons\\Ability_Shaman_WaterShield",
        description = "Restores mana when hit",
        hasCharges = true,
        targetSelf = true,
        tbcOnly = true,
    },
    {
        name = "Earth Shield",
        -- Resto talent
        spellIds = {974, 32593, 32594},
        icon = "Interface\\Icons\\Spell_Nature_SkinOfEarth",
        description = "Heals target when hit",
        hasCharges = true,
        targetSelf = false,  -- Can target others
        isTargeted = true,
        talentRequired = true,
    },
}

-- Build lookup table for shields
DB.ShieldLookup = {}
DB.AllShieldSpellIds = {}
for _, shield in ipairs(DB.Shields) do
    for _, spellId in ipairs(shield.spellIds) do
        DB.ShieldLookup[spellId] = shield
        DB.AllShieldSpellIds[spellId] = true
    end
end

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

--- Check if a spell ID is a Call spell
---@param spellId number
---@return boolean
function DB:IsCallSpell(spellId)
    return self.AllCallSpellIds[spellId] == true
end

--- Check if a spell ID is a Weapon Imbue
---@param spellId number
---@return boolean
function DB:IsImbueSpell(spellId)
    return self.AllImbueSpellIds[spellId] == true
end

--- Check if a spell ID is a Shield spell
---@param spellId number
---@return boolean
function DB:IsShieldSpell(spellId)
    return self.AllShieldSpellIds[spellId] == true
end

--- Get Call spell data by ID
---@param spellId number
---@return table|nil
function DB:GetCallSpell(spellId)
    return self.CallSpellLookup[spellId]
end

--- Get Imbue data by ID
---@param spellId number
---@return table|nil
function DB:GetImbue(spellId)
    return self.ImbueLookup[spellId]
end

--- Get Shield data by ID
---@param spellId number
---@return table|nil
function DB:GetShield(spellId)
    return self.ShieldLookup[spellId]
end

--- Get all Call spells
---@return table
function DB:GetAllCallSpells()
    return self.CallSpells
end

--- Get all Weapon Imbues
---@return table
function DB:GetAllImbues()
    return self.WeaponImbues
end

--- Get all Shields
---@return table
function DB:GetAllShields()
    return self.Shields
end

--- Get the highest rank spell ID from a list that the player knows
---@param spellIds table List of spell IDs (ordered lowest to highest rank)
---@param knownSpells table Table of known spell IDs
---@return number|nil highestKnown The highest known spell ID
function DB:GetHighestKnownRank(spellIds, knownSpells)
    local highest = nil
    for _, spellId in ipairs(spellIds) do
        if knownSpells[spellId] then
            highest = spellId
        end
    end
    return highest
end

return DB
