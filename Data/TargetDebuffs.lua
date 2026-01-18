--[[
    TotemBuddy - Target Debuffs Database
    Contains spell data for important Shaman debuffs to track on targets

    Note: SpellIDs are for TBC/Classic Era. Some spells may not exist
    on all server versions.
]]

-- Create global database
_G.TotemBuddyTargetDebuffs = _G.TotemBuddyTargetDebuffs or {}
local DB = _G.TotemBuddyTargetDebuffs

-- =============================================================================
-- TRACKABLE DEBUFFS
-- =============================================================================
-- These are important debuffs that shamans want to track on their target

DB.Debuffs = {
    -- Flame Shock (DoT - important for all specs)
    {
        name = "Flame Shock",
        spellIds = {8050, 8052, 8053, 10447, 10448, 29228, 25457},  -- Ranks 1-7
        icon = "Interface\\Icons\\Spell_Fire_FlameShock",
        category = "dot",
        description = "Fire damage over time",
        hasDuration = true,
        baseDuration = 12,  -- Base duration in seconds
        priority = 1,  -- Higher = more important to track
    },

    -- Stormstrike (Enhancement debuff - increases nature damage taken)
    {
        name = "Stormstrike",
        spellIds = {17364, 32175, 32176},  -- Base + ranks
        icon = "Interface\\Icons\\Ability_Shaman_Stormstrike",
        category = "debuff",
        description = "Increases nature damage taken",
        hasDuration = true,
        baseDuration = 12,
        priority = 2,
        talent = "Enhancement",
    },

    -- Frost Shock (slow - useful for kiting)
    {
        name = "Frost Shock",
        spellIds = {8056, 8058, 10472, 10473, 25464},  -- Ranks 1-5
        icon = "Interface\\Icons\\Spell_Frost_FrostShock",
        category = "slow",
        description = "Slows movement speed",
        hasDuration = true,
        baseDuration = 8,
        priority = 3,
    },

    -- Earth Shock (interrupt - no debuff component but can track recent use)
    -- Note: Earth Shock doesn't leave a debuff, but we include for completeness
    -- {
    --     name = "Earth Shock",
    --     spellIds = {8042, 8044, 8045, 8046, 10412, 10413, 10414, 25454},
    --     icon = "Interface\\Icons\\Spell_Nature_EarthShock",
    --     category = "interrupt",
    --     description = "Interrupts spellcasting",
    --     hasDuration = false,
    --     priority = 4,
    -- },

    -- Searing Totem (not a debuff but tracks if totem is hitting target)
    -- This would require different tracking logic

    -- WotLK additions
    {
        name = "Lava Burst",
        spellIds = {51505, 60043},
        icon = "Interface\\Icons\\Spell_Shaman_LavaBurst",
        category = "dot",
        description = "Guaranteed crit if Flame Shock is on target",
        hasDuration = false,  -- Instant, but consumes Flame Shock in some versions
        priority = 1,
        trackFlameShockConsumption = true,  -- Special flag
    },
}

-- Build lookup tables
DB.DebuffLookup = {}
DB.AllDebuffSpellIds = {}
DB.DebuffByName = {}

for _, debuff in ipairs(DB.Debuffs) do
    DB.DebuffByName[debuff.name] = debuff
    for _, spellId in ipairs(debuff.spellIds) do
        DB.DebuffLookup[spellId] = debuff
        DB.AllDebuffSpellIds[spellId] = true
    end
end

-- Category labels for UI
DB.CategoryLabels = {
    dot = "Damage over Time",
    debuff = "Debuff",
    slow = "Slow",
    interrupt = "Interrupt",
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

--- Check if a spell ID is a tracked debuff
---@param spellId number
---@return boolean
function DB:IsTrackedDebuff(spellId)
    return self.AllDebuffSpellIds[spellId] == true
end

--- Get debuff data by spell ID
---@param spellId number
---@return table|nil
function DB:GetDebuff(spellId)
    return self.DebuffLookup[spellId]
end

--- Get debuff data by name
---@param name string
---@return table|nil
function DB:GetDebuffByName(name)
    return self.DebuffByName[name]
end

--- Get all tracked debuffs
---@return table
function DB:GetAllDebuffs()
    return self.Debuffs
end

--- Get all available debuffs
---@return table
function DB:GetAvailableDebuffs()
    return self.Debuffs
end

--- Scan target for a specific debuff
---@param debuffName string The localized debuff name
---@param unit string The unit to scan (default "target")
---@return boolean found, number|nil remaining, number|nil duration, number|nil stacks
function DB:ScanForDebuff(debuffName, unit)
    unit = unit or "target"
    if not UnitExists(unit) then
        return false, nil, nil, nil
    end

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, source, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end

        -- Check if this is our debuff (by name or spellId)
        if name == debuffName or (spellId and self.AllDebuffSpellIds[spellId]) then
            -- Verify it's from the player
            if source == "player" then
                local remaining = 0
                if expirationTime and expirationTime > 0 then
                    remaining = expirationTime - GetTime()
                    if remaining < 0 then remaining = 0 end
                end
                return true, remaining, duration, count or 1
            end
        end
    end

    return false, nil, nil, nil
end

--- Scan target for all tracked debuffs
---@param unit string The unit to scan (default "target")
---@return table results Table of {debuff=data, remaining=seconds, duration=seconds, stacks=count}
function DB:ScanAllDebuffs(unit)
    unit = unit or "target"
    local results = {}

    if not UnitExists(unit) then
        return results
    end

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, source, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end

        -- Check if this is a tracked debuff from the player
        local debuffData = spellId and self.DebuffLookup[spellId]
        if debuffData and source == "player" then
            local remaining = 0
            if expirationTime and expirationTime > 0 then
                remaining = expirationTime - GetTime()
                if remaining < 0 then remaining = 0 end
            end

            table.insert(results, {
                debuff = debuffData,
                spellId = spellId,
                name = name,
                icon = icon,
                remaining = remaining,
                duration = duration,
                stacks = count or 1,
            })
        end
    end

    -- Sort by priority
    table.sort(results, function(a, b)
        return (a.debuff.priority or 99) < (b.debuff.priority or 99)
    end)

    return results
end

return DB
