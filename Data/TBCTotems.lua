--[[
    TotemBuddy - TBC Totem Database Additions
    Contains new totems and rank upgrades added in The Burning Crusade (2.0 - 2.4.3)

    All spell IDs verified against Wowhead TBC Classic.
    Rank upgrades are merged into existing Classic totem entries by name.
    New TBC-only totems are appended to the element tables.
]]

-- Only load if database exists (Classic must load first)
local Database = _G.TotemBuddyTotemDatabase
if not Database then
    return
end

-- Element constants (matches WoW API GetTotemInfo slot order)
local FIRE = 1
local EARTH = 2
local WATER = 3
local AIR = 4

-- TBC Earth Totems (new totems + rank upgrades for existing)
local tbcEarth = {
    -- New TBC totem
    {
        name = "Earth Elemental Totem",
        spellIds = {2062},
        icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem",
        element = EARTH,
        levelRequired = 66,
    },
    -- Rank upgrades for Classic totems
    {
        name = "Stoneclaw Totem",
        spellIds = {25525},               -- Rank 7 (level 67)
        element = EARTH,
    },
    {
        name = "Stoneskin Totem",
        spellIds = {25508, 25509},         -- Rank 7 (level 63), Rank 8 (level 70)
        element = EARTH,
    },
    {
        name = "Strength of Earth Totem",
        spellIds = {25528},                -- Rank 6 (level 65)
        element = EARTH,
    },
}

-- TBC Fire Totems (new totems + rank upgrades for existing)
local tbcFire = {
    -- New TBC totems
    {
        name = "Fire Elemental Totem",
        spellIds = {2894},
        icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem",
        element = FIRE,
        levelRequired = 68,
    },
    {
        name = "Totem of Wrath",
        spellIds = {30706},
        icon = "Interface\\Icons\\Spell_Fire_TotemOfWrath",
        element = FIRE,
        levelRequired = 50,
        talentRequired = true,
    },
    -- Rank upgrades for Classic totems
    {
        name = "Searing Totem",
        spellIds = {25533},                -- Rank 7 (level 69)
        element = FIRE,
    },
    {
        name = "Fire Nova Totem",
        spellIds = {25546, 25547},         -- Rank 6 (level 61), Rank 7 (level 70)
        element = FIRE,
    },
    {
        name = "Magma Totem",
        spellIds = {25552},                -- Rank 5 (level 65)
        element = FIRE,
    },
    {
        name = "Flametongue Totem",
        spellIds = {25557},                -- Rank 5 (level 67)
        element = FIRE,
    },
    {
        name = "Frost Resistance Totem",
        spellIds = {25560},                -- Rank 4 (level 64)
        element = FIRE,
    },
}

-- TBC Water Totems (rank upgrades for existing)
local tbcWater = {
    {
        name = "Healing Stream Totem",
        spellIds = {25567},                -- Rank 6 (level 69)
        element = WATER,
    },
    {
        name = "Mana Spring Totem",
        spellIds = {25570},                -- Rank 5 (level 65)
        element = WATER,
    },
    {
        name = "Fire Resistance Totem",
        spellIds = {25563},                -- Rank 4 (level 64)
        element = WATER,
    },
}

-- TBC Air Totems (new totems + rank upgrades for existing)
local tbcAir = {
    -- New TBC totem
    {
        name = "Wrath of Air Totem",
        spellIds = {3738},
        icon = "Interface\\Icons\\Spell_Nature_SlowingTotem",
        element = AIR,
        levelRequired = 64,
    },
    -- Rank upgrades for Classic totems
    {
        name = "Windfury Totem",
        spellIds = {25585, 25587},         -- Rank 4 (level 61), Rank 5 (level 70)
        element = AIR,
    },
    {
        name = "Windwall Totem",
        spellIds = {25577},                -- Rank 4 (level 65)
        element = AIR,
    },
    {
        name = "Nature Resistance Totem",
        spellIds = {25574},                -- Rank 4 (level 64)
        element = AIR,
    },
}

--- Merge TBC totems into the main database.
--- If a totem with the same name already exists (Classic base), append new spell IDs.
--- If the totem is new (TBC-only), add a full entry to the element table.
---@param element number Element constant (FIRE/EARTH/WATER/AIR)
---@param newTotems table Array of totem entries to merge
local function MergeTotems(element, newTotems)
    if not Database[element] then
        return
    end

    for _, totem in ipairs(newTotems) do
        -- Check if this totem already exists in the database (by name)
        local found = false
        for _, existing in ipairs(Database[element]) do
            if existing.name == totem.name then
                -- Existing totem: append new rank spell IDs
                for _, spellId in ipairs(totem.spellIds) do
                    local duplicate = false
                    for _, existingId in ipairs(existing.spellIds) do
                        if existingId == spellId then
                            duplicate = true
                            break
                        end
                    end
                    if not duplicate then
                        table.insert(existing.spellIds, spellId)
                        Database.SpellToTotem[spellId] = existing
                        Database.AllTotemSpellIds[spellId] = true
                    end
                end
                found = true
                break
            end
        end

        if not found then
            -- New totem: validate required fields before inserting
            if totem.icon and totem.levelRequired then
                table.insert(Database[element], totem)
                for _, spellId in ipairs(totem.spellIds) do
                    Database.SpellToTotem[spellId] = totem
                    Database.AllTotemSpellIds[spellId] = true
                end
            end
        end
    end
end

MergeTotems(EARTH, tbcEarth)
MergeTotems(FIRE, tbcFire)
MergeTotems(WATER, tbcWater)
MergeTotems(AIR, tbcAir)
