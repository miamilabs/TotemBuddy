--[[
    TotemBuddy - Long Cooldowns Database
    Contains spell data for important Shaman cooldowns to track

    Note: SpellIDs are for TBC/Classic Era. Some spells may not exist
    on all server versions - the scanner will detect what's available.
]]

-- Create global database
_G.TotemBuddyLongCooldowns = _G.TotemBuddyLongCooldowns or {}
local DB = _G.TotemBuddyLongCooldowns

-- =============================================================================
-- LONG COOLDOWN SPELLS
-- =============================================================================
-- These are important cooldowns that shamans want to track
-- Organized by category for UI grouping

DB.Cooldowns = {
    -- Resurrection/Survival
    {
        name = "Reincarnation",
        spellId = 20608,
        icon = "Interface\\Icons\\Spell_Nature_Reincarnation",
        category = "survival",
        baseCooldown = 3600,  -- 60 minutes (can be reduced by talents)
        description = "Resurrect yourself upon death",
        requiresReagent = true,  -- Ankh
    },

    -- Elemental Totems (long CD)
    {
        name = "Fire Elemental Totem",
        spellId = 2894,
        icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem",
        category = "totem",
        baseCooldown = 1200,  -- 20 minutes
        description = "Summons a Fire Elemental",
    },
    {
        name = "Earth Elemental Totem",
        spellId = 2062,
        icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem",
        category = "totem",
        baseCooldown = 1200,  -- 20 minutes
        description = "Summons an Earth Elemental",
    },

    -- Raid Cooldowns
    {
        name = "Bloodlust",
        spellId = 2825,
        icon = "Interface\\Icons\\Spell_Nature_BloodLust",
        category = "raid",
        baseCooldown = 600,  -- 10 minutes
        description = "Increases haste for the party",
        faction = "Horde",
    },
    {
        name = "Heroism",
        spellId = 32182,
        icon = "Interface\\Icons\\Ability_Shaman_Heroism",
        category = "raid",
        baseCooldown = 600,  -- 10 minutes
        description = "Increases haste for the party",
        faction = "Alliance",
    },

    -- Talent Cooldowns (3 min)
    {
        name = "Nature's Swiftness",
        spellId = 16188,
        icon = "Interface\\Icons\\Spell_Nature_RavenForm",
        category = "talent",
        baseCooldown = 180,  -- 3 minutes
        description = "Next nature spell is instant",
        talent = "Restoration",
    },
    {
        name = "Elemental Mastery",
        spellId = 16166,
        icon = "Interface\\Icons\\Spell_Nature_WispHeal",
        category = "talent",
        baseCooldown = 180,  -- 3 minutes
        description = "Next spell is guaranteed crit and costs no mana",
        talent = "Elemental",
    },

    -- WotLK Talent Cooldowns
    {
        name = "Feral Spirit",
        spellId = 51533,
        icon = "Interface\\Icons\\Spell_Shaman_FeralSpirit",
        category = "talent",
        baseCooldown = 180,  -- 3 minutes
        description = "Summon two Spirit Wolves",
        talent = "Enhancement",
    },
    {
        name = "Thunderstorm",
        spellId = 51490,
        icon = "Interface\\Icons\\Spell_Shaman_ThunderStorm",
        category = "talent",
        baseCooldown = 45,  -- 45 seconds
        description = "AoE damage and knockback, restores mana",
        talent = "Elemental",
    },
    {
        name = "Riptide",
        spellId = 61295,
        icon = "Interface\\Icons\\Spell_Nature_Riptide",
        category = "talent",
        baseCooldown = 6,  -- 6 seconds
        description = "Instant heal with HoT component",
        talent = "Restoration",
    },
}

-- Build lookup table for quick spell checking
DB.CooldownLookup = {}
DB.AllCooldownSpellIds = {}
for _, spell in ipairs(DB.Cooldowns) do
    DB.CooldownLookup[spell.spellId] = spell
    DB.AllCooldownSpellIds[spell.spellId] = true
end

-- Category labels for UI
DB.CategoryLabels = {
    survival = "Survival",
    totem = "Elemental Totems",
    raid = "Raid Cooldowns",
    talent = "Talent Abilities",
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

--- Check if a spell ID is a tracked cooldown
---@param spellId number
---@return boolean
function DB:IsCooldownSpell(spellId)
    return self.AllCooldownSpellIds[spellId] == true
end

--- Get cooldown spell data by ID
---@param spellId number
---@return table|nil
function DB:GetCooldownSpell(spellId)
    return self.CooldownLookup[spellId]
end

--- Get all cooldown spells
---@return table
function DB:GetAllCooldowns()
    return self.Cooldowns
end

--- Get cooldowns filtered by category
---@param category string
---@return table
function DB:GetCooldownsByCategory(category)
    local result = {}
    for _, spell in ipairs(self.Cooldowns) do
        if spell.category == category then
            table.insert(result, spell)
        end
    end
    return result
end

--- Get all available cooldowns
---@return table
function DB:GetAvailableCooldowns()
    return self.Cooldowns
end

--- Get the current cooldown remaining for a spell
---@param spellId number
---@return number remaining Seconds remaining (0 if ready)
---@return number duration Total cooldown duration
---@return boolean onCooldown Whether the spell is on cooldown
function DB:GetCooldownInfo(spellId)
    local start, duration, enabled = GetSpellCooldown(spellId)
    if not start or start == 0 then
        return 0, 0, false
    end

    -- Check for GCD (1.5s or less is usually GCD)
    if duration <= 1.5 then
        return 0, 0, false
    end

    local remaining = (start + duration) - GetTime()
    if remaining < 0 then remaining = 0 end

    return remaining, duration, remaining > 0
end

--- Check if the player knows a spell
---@param spellId number
---@return boolean
function DB:IsSpellKnown(spellId)
    -- IsSpellKnown is the primary check; fallback to GetSpellInfo for edge cases
    return IsSpellKnown(spellId) or (GetSpellInfo(spellId) ~= nil)
end

return DB
