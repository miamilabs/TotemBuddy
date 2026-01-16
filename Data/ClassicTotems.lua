--[[
    TotemBuddy - Classic Era Totem Database
    Contains all totem spells for WoW Classic (Era/Season of Discovery)
]]

---@class TotemDatabase
local TotemDatabase = {}

-- Element constants (matches WoW API GetTotemInfo slot order)
local FIRE = 1
local EARTH = 2
local WATER = 3
local AIR = 4

--[[
    Totem Data Structure:
    {
        name = "Totem Name",
        spellIds = {rank1, rank2, rank3, ...},  -- Ordered by rank
        icon = "Interface\\Icons\\IconPath",
        element = ELEMENT_CONSTANT,
        levelRequired = minLevel,  -- Level when first rank is learned
    }
]]

TotemDatabase[EARTH] = {
    {
        name = "Earthbind Totem",
        spellIds = {2484},
        icon = "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02",
        element = EARTH,
        levelRequired = 6,
    },
    {
        name = "Stoneclaw Totem",
        spellIds = {5730, 6390, 6391, 6392, 10427, 10428},
        icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem",
        element = EARTH,
        levelRequired = 8,
    },
    {
        name = "Stoneskin Totem",
        spellIds = {8071, 8154, 8155, 10406, 10407, 10408},
        icon = "Interface\\Icons\\Spell_Nature_StoneSkinTotem",
        element = EARTH,
        levelRequired = 4,
    },
    {
        name = "Strength of Earth Totem",
        spellIds = {8075, 8160, 8161, 10442, 25361},
        icon = "Interface\\Icons\\Spell_Nature_EarthBindTotem",
        element = EARTH,
        levelRequired = 10,
    },
    {
        name = "Tremor Totem",
        spellIds = {8143},
        icon = "Interface\\Icons\\Spell_Nature_TremorTotem",
        element = EARTH,
        levelRequired = 18,
    },
}

TotemDatabase[FIRE] = {
    {
        name = "Searing Totem",
        spellIds = {3599, 6363, 6364, 6365, 10437, 10438},
        icon = "Interface\\Icons\\Spell_Fire_SearingTotem",
        element = FIRE,
        levelRequired = 10,
    },
    {
        name = "Fire Nova Totem",
        spellIds = {1535, 8498, 8499, 11314, 11315},
        icon = "Interface\\Icons\\Spell_Fire_SealOfFire",
        element = FIRE,
        levelRequired = 12,
    },
    {
        name = "Magma Totem",
        spellIds = {8190, 10585, 10586, 10587},
        icon = "Interface\\Icons\\Spell_Fire_SelfDestruct",
        element = FIRE,
        levelRequired = 26,
    },
    {
        name = "Flametongue Totem",
        spellIds = {8227, 8249, 10526, 16387},
        icon = "Interface\\Icons\\Spell_Nature_GuardianWard",
        element = FIRE,
        levelRequired = 28,
    },
    {
        name = "Frost Resistance Totem",
        spellIds = {8181, 10478, 10479},
        icon = "Interface\\Icons\\Spell_FrostResistanceTotem_01",
        element = FIRE,
        levelRequired = 24,
    },
}

TotemDatabase[WATER] = {
    {
        name = "Healing Stream Totem",
        spellIds = {5394, 6375, 6377, 10462, 10463},
        icon = "Interface\\Icons\\INV_Spear_04",
        element = WATER,
        levelRequired = 20,
    },
    {
        name = "Mana Spring Totem",
        spellIds = {5675, 10495, 10496, 10497},
        icon = "Interface\\Icons\\Spell_Nature_ManaRegenTotem",
        element = WATER,
        levelRequired = 26,
    },
    {
        name = "Fire Resistance Totem",
        spellIds = {8184, 10537, 10538},
        icon = "Interface\\Icons\\Spell_FireResistanceTotem_01",
        element = WATER,
        levelRequired = 28,
    },
    {
        name = "Disease Cleansing Totem",
        spellIds = {8170},
        icon = "Interface\\Icons\\Spell_Nature_DiseaseCleansingTotem",
        element = WATER,
        levelRequired = 38,
    },
    {
        name = "Mana Tide Totem",
        spellIds = {16190, 17354, 17359},
        icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
        element = WATER,
        levelRequired = 40,
        talentRequired = true,
    },
    {
        name = "Poison Cleansing Totem",
        spellIds = {8166},
        icon = "Interface\\Icons\\Spell_Nature_PoisonCleansingTotem",
        element = WATER,
        levelRequired = 22,
    },
}

TotemDatabase[AIR] = {
    {
        name = "Grace of Air Totem",
        spellIds = {8835, 10627, 25359},
        icon = "Interface\\Icons\\Spell_Nature_InvisibilityTotem",
        element = AIR,
        levelRequired = 42,
    },
    {
        name = "Nature Resistance Totem",
        spellIds = {10595, 10600, 10601},
        icon = "Interface\\Icons\\Spell_Nature_NatureResistanceTotem",
        element = AIR,
        levelRequired = 30,
    },
    {
        name = "Windwall Totem",
        spellIds = {15107, 15111, 15112},
        icon = "Interface\\Icons\\Spell_Nature_EarthBind",
        element = AIR,
        levelRequired = 36,
    },
    {
        name = "Grounding Totem",
        spellIds = {8177},
        icon = "Interface\\Icons\\Spell_Nature_GroundingTotem",
        element = AIR,
        levelRequired = 30,
    },
    {
        name = "Windfury Totem",
        spellIds = {8512, 10613, 10614},
        icon = "Interface\\Icons\\Spell_Nature_Windfury",
        element = AIR,
        levelRequired = 32,
    },
    {
        name = "Sentry Totem",
        spellIds = {6495},
        icon = "Interface\\Icons\\Spell_Nature_RemoveCurse",
        element = AIR,
        levelRequired = 34,
    },
    {
        name = "Tranquil Air Totem",
        spellIds = {25908},
        icon = "Interface\\Icons\\Spell_Nature_Brilliance",
        element = AIR,
        levelRequired = 50,
    },
}

-- Build a reverse lookup: spellId -> totem data
TotemDatabase.SpellToTotem = {}
for element = 1, 4 do
    for _, totem in ipairs(TotemDatabase[element]) do
        for _, spellId in ipairs(totem.spellIds) do
            TotemDatabase.SpellToTotem[spellId] = totem
        end
    end
end

-- Build a list of all totem spell IDs for quick lookup
TotemDatabase.AllTotemSpellIds = {}
for spellId, _ in pairs(TotemDatabase.SpellToTotem) do
    TotemDatabase.AllTotemSpellIds[spellId] = true
end

-- Make globally accessible
_G.TotemBuddyTotemDatabase = TotemDatabase
