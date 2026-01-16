--[[
    TotemBuddy - TBC Totem Database Additions
    Contains additional totem spells added in The Burning Crusade
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

-- TBC Earth Totems
local tbcEarth = {
    {
        name = "Earth Elemental Totem",
        spellIds = {2062},
        icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem",
        element = EARTH,
        levelRequired = 66,
    },
}

-- TBC Fire Totems
local tbcFire = {
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
}

-- TBC Water Totems
local tbcWater = {
    -- Additional ranks for existing totems may be added here
}

-- TBC Air Totems
local tbcAir = {
    {
        name = "Wrath of Air Totem",
        spellIds = {3738},
        icon = "Interface\\Icons\\Spell_Nature_SlowingTotem",
        element = AIR,
        levelRequired = 64,
    },
}

-- Merge TBC totems into main database
local function MergeTotems(element, newTotems)
    for _, totem in ipairs(newTotems) do
        table.insert(Database[element], totem)

        -- Add to spell lookup
        for _, spellId in ipairs(totem.spellIds) do
            Database.SpellToTotem[spellId] = totem
            Database.AllTotemSpellIds[spellId] = true
        end
    end
end

MergeTotems(EARTH, tbcEarth)
MergeTotems(FIRE, tbcFire)
MergeTotems(WATER, tbcWater)
MergeTotems(AIR, tbcAir)
