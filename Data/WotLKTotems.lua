--[[
    TotemBuddy - WotLK Totem Database Additions
    Contains additional totem spells added in Wrath of the Lich King

    Note: WotLK significantly changed totems with the addition of:
    - Call of the Elements (drop all 4 totems at once)
    - Totem Bar UI (built-in)
    - New totems and rank updates
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

-- WotLK Earth Totems
local wotlkEarth = {
    -- Stoneclaw Totem Rank 7-8
    -- Stoneskin Totem Rank 7-8
    -- Strength of Earth Totem Rank 6-7
}

-- WotLK Fire Totems
local wotlkFire = {
    {
        name = "Totem of Wrath",
        spellIds = {57720, 57721, 57722},  -- Updated ranks
        icon = "Interface\\Icons\\Spell_Fire_TotemOfWrath",
        element = FIRE,
        levelRequired = 50,
        talentRequired = true,
    },
    -- Searing Totem Rank 7-9
    -- Magma Totem Rank 5-7
    -- Flametongue Totem Rank 5
}

-- WotLK Water Totems
local wotlkWater = {
    {
        name = "Cleansing Totem",
        spellIds = {8170},  -- Combines Disease and Poison cleansing
        icon = "Interface\\Icons\\Spell_Nature_DiseaseCleansingTotem",
        element = WATER,
        levelRequired = 38,
    },
    -- Healing Stream Totem Rank 6-9
    -- Mana Spring Totem Rank 5
}

-- WotLK Air Totems
local wotlkAir = {
    -- Grace of Air Totem replaced by Windfury in WotLK
    -- Windfury Totem Rank 4-5
}

-- Merge WotLK totems into main database
local function MergeTotems(element, newTotems)
    for _, totem in ipairs(newTotems) do
        -- Check if totem already exists (update vs add)
        local found = false
        for i, existing in ipairs(Database[element]) do
            if existing.name == totem.name then
                -- Update existing totem with new ranks
                for _, spellId in ipairs(totem.spellIds) do
                    local exists = false
                    for _, existingId in ipairs(existing.spellIds) do
                        if existingId == spellId then
                            exists = true
                            break
                        end
                    end
                    if not exists then
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
            -- Add new totem
            table.insert(Database[element], totem)
            for _, spellId in ipairs(totem.spellIds) do
                Database.SpellToTotem[spellId] = totem
                Database.AllTotemSpellIds[spellId] = true
            end
        end
    end
end

MergeTotems(EARTH, wotlkEarth)
MergeTotems(FIRE, wotlkFire)
MergeTotems(WATER, wotlkWater)
MergeTotems(AIR, wotlkAir)
