--[[
    TotemBuddy - Shaman Procs Database
    Contains spell data for important Shaman proc effects to track

    Note: SpellIDs are for TBC/Classic Era. Some spells may not exist
    on all server versions.
]]

-- Create global database
_G.TotemBuddyShamanProcs = _G.TotemBuddyShamanProcs or {}
local DB = _G.TotemBuddyShamanProcs

-- =============================================================================
-- TRACKABLE PROCS
-- =============================================================================
-- These are important proc buffs that shamans want to track

DB.Procs = {
    -- Elemental Focus (Clearcasting from Elemental spec)
    {
        name = "Elemental Focus",
        buffName = "Clearcasting",  -- The actual buff name
        spellIds = {16246},  -- The buff spell ID
        triggerSpellIds = {16164},  -- The talent that grants it
        icon = "Interface\\Icons\\Spell_Shadow_ManaBurn",
        category = "clearcasting",
        description = "Next 2 damage spells cost 40% less mana",
        charges = 2,
        talent = "Elemental",
        priority = 1,
    },

    -- Nature's Swiftness (active buff when used)
    {
        name = "Nature's Swiftness",
        buffName = "Nature's Swiftness",
        spellIds = {16188},
        icon = "Interface\\Icons\\Spell_Nature_RavenForm",
        category = "instant",
        description = "Next nature spell is instant cast",
        talent = "Restoration",
        priority = 2,
        consumedOnCast = true,
    },

    -- Elemental Mastery (active buff when used)
    {
        name = "Elemental Mastery",
        buffName = "Elemental Mastery",
        spellIds = {16166},
        icon = "Interface\\Icons\\Spell_Nature_WispHeal",
        category = "instant",
        description = "Next spell is instant, guaranteed crit, no mana cost",
        talent = "Elemental",
        priority = 2,
        consumedOnCast = true,
    },

    -- Lightning Shield charges tracking (not exactly a proc, but useful)
    -- This is handled separately in ShieldTile

    -- WotLK Procs
    {
        name = "Maelstrom Weapon",
        buffName = "Maelstrom Weapon",
        spellIds = {53817},  -- 5 stack version
        stackIds = {53817, 53818, 53819, 53820, 53821},  -- Different stack counts have different IDs
        icon = "Interface\\Icons\\Spell_Shaman_MaelstromWeapon",
        category = "instant",
        description = "Next Lightning Bolt, Chain Lightning, or healing spell is instant",
        maxStacks = 5,
        talent = "Enhancement",
        priority = 1,
    },

    {
        name = "Tidal Waves",
        buffName = "Tidal Waves",
        spellIds = {53390},
        icon = "Interface\\Icons\\Spell_Shaman_TidalWaves",
        category = "haste",
        description = "Reduces cast time of Healing Wave or increases crit of Lesser Healing Wave",
        charges = 2,
        talent = "Restoration",
        priority = 2,
    },

    {
        name = "Lava Flows",
        buffName = "Lava Flows",
        spellIds = {65264},
        icon = "Interface\\Icons\\Spell_Shaman_LavaFlow",
        category = "haste",
        description = "Increases spell haste",
        talent = "Elemental",
        priority = 3,
    },
}

-- Build lookup tables
DB.ProcLookup = {}
DB.AllProcSpellIds = {}
DB.ProcByName = {}

for _, proc in ipairs(DB.Procs) do
    DB.ProcByName[proc.name] = proc
    if proc.buffName then
        DB.ProcByName[proc.buffName] = proc
    end
    for _, spellId in ipairs(proc.spellIds or {}) do
        DB.ProcLookup[spellId] = proc
        DB.AllProcSpellIds[spellId] = true
    end
    -- Also add stack IDs if present
    for _, spellId in ipairs(proc.stackIds or {}) do
        DB.ProcLookup[spellId] = proc
        DB.AllProcSpellIds[spellId] = true
    end
end

-- Category labels for UI
DB.CategoryLabels = {
    clearcasting = "Clearcasting",
    instant = "Instant Cast",
    haste = "Haste",
    damage = "Damage Bonus",
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

--- Check if a spell ID is a tracked proc
---@param spellId number
---@return boolean
function DB:IsTrackedProc(spellId)
    return self.AllProcSpellIds[spellId] == true
end

--- Get proc data by spell ID
---@param spellId number
---@return table|nil
function DB:GetProc(spellId)
    return self.ProcLookup[spellId]
end

--- Get proc data by name
---@param name string
---@return table|nil
function DB:GetProcByName(name)
    return self.ProcByName[name]
end

--- Get all tracked procs
---@return table
function DB:GetAllProcs()
    return self.Procs
end

--- Get all available procs
---@return table
function DB:GetAvailableProcs()
    return self.Procs
end

--- Scan player buffs for active procs
---@return table results Table of {proc=data, remaining=seconds, stacks=count, spellId=number}
function DB:ScanActiveProcs()
    local results = {}

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        -- Check if this is a tracked proc
        local procData = spellId and self.ProcLookup[spellId]
        if not procData then
            -- Try by name
            procData = self.ProcByName[name]
        end

        if procData then
            local remaining = 0
            if expirationTime and expirationTime > 0 then
                remaining = expirationTime - GetTime()
                if remaining < 0 then remaining = 0 end
            end

            table.insert(results, {
                proc = procData,
                spellId = spellId,
                name = name,
                icon = icon or procData.icon,
                remaining = remaining,
                duration = duration,
                stacks = count or 1,
            })
        end
    end

    -- Sort by priority
    table.sort(results, function(a, b)
        return (a.proc.priority or 99) < (b.proc.priority or 99)
    end)

    return results
end

--- Check if a specific proc is active
---@param procName string
---@return boolean active, number|nil remaining, number|nil stacks
function DB:IsProcActive(procName)
    local proc = self.ProcByName[procName]
    if not proc then return false end

    for i = 1, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        if name == procName or name == proc.buffName or (spellId and self.ProcLookup[spellId] == proc) then
            local remaining = 0
            if expirationTime and expirationTime > 0 then
                remaining = expirationTime - GetTime()
            end
            return true, remaining, count or 1
        end
    end

    return false
end

return DB
