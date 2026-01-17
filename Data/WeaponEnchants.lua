--[[
    TotemBuddy - Weapon Enchant ID Mapping
    Maps GetWeaponEnchantInfo() enchant IDs to spell IDs

    This allows identification of which imbue type is active on a weapon,
    since GetWeaponEnchantInfo() only returns an enchant ID, not spell info.

    Data sourced from TotemTimers_Fork/tbc/TotemData.lua
]]

-- Create global database
_G.TotemBuddyWeaponEnchants = _G.TotemBuddyWeaponEnchants or {}
local DB = _G.TotemBuddyWeaponEnchants

-- =============================================================================
-- SPELL IDS (Base spell IDs for each imbue type)
-- =============================================================================

DB.SpellIDs = {
    FlametongueWeapon = 8024,
    RockbiterWeapon = 8017,
    FrostbrandWeapon = 8033,
    WindfuryWeapon = 8232,
    EarthlivingWeapon = 51730,  -- WotLK only
}

-- =============================================================================
-- ENCHANT ID TO SPELL ID MAPPING
-- =============================================================================
-- Key: enchant ID returned by GetWeaponEnchantInfo()
-- Value: base spell ID for the imbue type

DB.EnchantToSpell = {
    -- Flametongue Weapon (all ranks)
    [3] = DB.SpellIDs.FlametongueWeapon,
    [4] = DB.SpellIDs.FlametongueWeapon,
    [5] = DB.SpellIDs.FlametongueWeapon,
    [523] = DB.SpellIDs.FlametongueWeapon,
    [1665] = DB.SpellIDs.FlametongueWeapon,
    [1666] = DB.SpellIDs.FlametongueWeapon,
    [2634] = DB.SpellIDs.FlametongueWeapon,
    [3779] = DB.SpellIDs.FlametongueWeapon,
    [3780] = DB.SpellIDs.FlametongueWeapon,
    [3781] = DB.SpellIDs.FlametongueWeapon,
    [7567] = DB.SpellIDs.FlametongueWeapon,

    -- Rockbiter Weapon (all ranks)
    [1] = DB.SpellIDs.RockbiterWeapon,
    [6] = DB.SpellIDs.RockbiterWeapon,
    [29] = DB.SpellIDs.RockbiterWeapon,
    [503] = DB.SpellIDs.RockbiterWeapon,
    [504] = DB.SpellIDs.RockbiterWeapon,
    [683] = DB.SpellIDs.RockbiterWeapon,
    [1663] = DB.SpellIDs.RockbiterWeapon,
    [1664] = DB.SpellIDs.RockbiterWeapon,
    [2632] = DB.SpellIDs.RockbiterWeapon,
    [2633] = DB.SpellIDs.RockbiterWeapon,

    -- Windfury Weapon (all ranks)
    [283] = DB.SpellIDs.WindfuryWeapon,
    [284] = DB.SpellIDs.WindfuryWeapon,
    [525] = DB.SpellIDs.WindfuryWeapon,
    [1669] = DB.SpellIDs.WindfuryWeapon,
    [2636] = DB.SpellIDs.WindfuryWeapon,
    [3785] = DB.SpellIDs.WindfuryWeapon,
    [3786] = DB.SpellIDs.WindfuryWeapon,
    [3787] = DB.SpellIDs.WindfuryWeapon,

    -- Frostbrand Weapon (all ranks)
    [2] = DB.SpellIDs.FrostbrandWeapon,
    [12] = DB.SpellIDs.FrostbrandWeapon,
    [524] = DB.SpellIDs.FrostbrandWeapon,
    [1667] = DB.SpellIDs.FrostbrandWeapon,
    [1668] = DB.SpellIDs.FrostbrandWeapon,
    [2635] = DB.SpellIDs.FrostbrandWeapon,
    [3782] = DB.SpellIDs.FrostbrandWeapon,
    [3783] = DB.SpellIDs.FrostbrandWeapon,
    [3784] = DB.SpellIDs.FrostbrandWeapon,

    -- Earthliving Weapon (WotLK only)
    [3345] = DB.SpellIDs.EarthlivingWeapon,
    [3346] = DB.SpellIDs.EarthlivingWeapon,
    [3347] = DB.SpellIDs.EarthlivingWeapon,
    [3348] = DB.SpellIDs.EarthlivingWeapon,
    [3349] = DB.SpellIDs.EarthlivingWeapon,
    [3350] = DB.SpellIDs.EarthlivingWeapon,
}

-- Add Rockbiter range 3018-3044 (various ranks)
for i = 3018, 3044 do
    DB.EnchantToSpell[i] = DB.SpellIDs.RockbiterWeapon
end

-- =============================================================================
-- IMBUE TYPE NAMES (for display/comparison)
-- =============================================================================

DB.ImbueTypes = {
    [DB.SpellIDs.FlametongueWeapon] = "Flametongue",
    [DB.SpellIDs.RockbiterWeapon] = "Rockbiter",
    [DB.SpellIDs.FrostbrandWeapon] = "Frostbrand",
    [DB.SpellIDs.WindfuryWeapon] = "Windfury",
    [DB.SpellIDs.EarthlivingWeapon] = "Earthliving",
}

-- =============================================================================
-- MAX DURATION TRACKING
-- =============================================================================
-- Stores the maximum observed duration for each enchant type
-- Used to calculate accurate progress bars

DB.MaxDurations = {}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

--- Get the spell ID for a given enchant ID
---@param enchantId number The enchant ID from GetWeaponEnchantInfo()
---@return number|nil spellId The base spell ID for this imbue type
function DB:GetSpellIdForEnchant(enchantId)
    return self.EnchantToSpell[enchantId]
end

--- Get the imbue type name for a given enchant ID
---@param enchantId number The enchant ID from GetWeaponEnchantInfo()
---@return string|nil typeName The imbue type name (e.g., "Windfury")
function DB:GetImbueTypeName(enchantId)
    local spellId = self.EnchantToSpell[enchantId]
    if spellId then
        return self.ImbueTypes[spellId]
    end
    return nil
end

--- Get the texture for a given enchant ID
---@param enchantId number The enchant ID from GetWeaponEnchantInfo()
---@return string|nil texture The spell texture path
function DB:GetTextureForEnchant(enchantId)
    local spellId = self.EnchantToSpell[enchantId]
    if spellId then
        local _, _, icon = GetSpellInfo(spellId)
        return icon
    end
    return nil
end

--- Update the max observed duration for an enchant type
---@param enchantId number The enchant ID
---@param duration number The observed duration in seconds
function DB:UpdateMaxDuration(enchantId, duration)
    local spellId = self.EnchantToSpell[enchantId]
    if spellId then
        if not self.MaxDurations[spellId] or self.MaxDurations[spellId] < duration then
            self.MaxDurations[spellId] = duration
        end
    end
end

--- Get the max observed duration for an enchant type
---@param enchantId number The enchant ID
---@return number duration The max duration (defaults to 1800 = 30 min)
function DB:GetMaxDuration(enchantId)
    local spellId = self.EnchantToSpell[enchantId]
    if spellId and self.MaxDurations[spellId] then
        return self.MaxDurations[spellId]
    end
    return 1800  -- Default 30 minutes
end

--- Check if a spell ID matches the active enchant
---@param enchantId number The enchant ID from GetWeaponEnchantInfo()
---@param spellId number The spell ID to check against
---@return boolean matches True if the enchant is from this spell type
function DB:IsEnchantFromSpell(enchantId, spellId)
    local enchantSpellId = self.EnchantToSpell[enchantId]
    if not enchantSpellId then return false end

    -- Check if it's the same base spell or same imbue type
    -- (handles rank differences)
    local enchantType = self.ImbueTypes[enchantSpellId]
    local spellType = self.ImbueTypes[spellId]

    -- If we have type info, compare types
    if enchantType and spellType then
        return enchantType == spellType
    end

    -- Otherwise compare spell IDs directly
    return enchantSpellId == spellId
end

return DB
