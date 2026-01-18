--[[
    TotemBuddy - Cooldown Tracker Module
    Displays important shaman cooldowns (Reincarnation, Elementals, Bloodlust, etc.)
]]

---@class CooldownTracker
local CooldownTracker = TotemBuddyLoader:CreateModule("CooldownTracker")
local _CooldownTracker = CooldownTracker.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local LongCooldowns = nil

-- Constants
local TRACKER_TILE_SIZE = 32
local TRACKER_SPACING = 3
local UPDATE_INTERVAL = 0.5  -- Update every 500ms

-- State
_CooldownTracker.frame = nil
_CooldownTracker.tiles = {}
_CooldownTracker.knownCooldowns = {}
_CooldownTracker.updateTimer = nil

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

--- Get the LongCooldowns database
local function GetDB()
    if not LongCooldowns then
        LongCooldowns = _G.TotemBuddyLongCooldowns
    end
    return LongCooldowns
end

--- Scan for known cooldown spells
function _CooldownTracker.ScanKnownCooldowns()
    local db = GetDB()
    if not db then return end

    _CooldownTracker.knownCooldowns = {}

    local availableCooldowns = db:GetAvailableCooldowns()

    for _, spell in ipairs(availableCooldowns) do
        -- Check faction for Bloodlust/Heroism
        local factionMatch = true
        if spell.faction then
            local _, playerFaction = UnitFactionGroup("player")
            factionMatch = (spell.faction == playerFaction)
        end

        -- Check if spell is known
        if factionMatch and IsSpellKnown(spell.spellId) then
            table.insert(_CooldownTracker.knownCooldowns, spell)
        end
    end
end

-- =============================================================================
-- FRAME CREATION
-- =============================================================================

--- Create the cooldown tracker frame
---@param parent Frame The parent frame (TotemBar)
---@return Frame trackerFrame
function CooldownTracker:Create(parent)
    if _CooldownTracker.frame then
        return _CooldownTracker.frame
    end

    -- Scan for known cooldowns first
    _CooldownTracker.ScanKnownCooldowns()

    -- Create container frame
    local frame = CreateFrame("Frame", "TotemBuddyCooldownTracker", parent)
    frame:SetSize(100, TRACKER_TILE_SIZE)  -- Will be resized based on content

    _CooldownTracker.frame = frame

    -- Create tiles for each known cooldown
    _CooldownTracker.CreateTiles()

    -- Start update timer
    _CooldownTracker.StartUpdateTimer()

    return frame
end

--- Create individual cooldown tiles
function _CooldownTracker.CreateTiles()
    local frame = _CooldownTracker.frame
    if not frame then return end

    -- Clear existing tiles
    for _, tile in ipairs(_CooldownTracker.tiles) do
        tile:Hide()
        tile:SetParent(nil)
    end
    _CooldownTracker.tiles = {}

    -- Get profile settings
    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local tileSize = profile.cooldownTrackerTileSize or TRACKER_TILE_SIZE
    local spacing = profile.cooldownTrackerSpacing or TRACKER_SPACING

    -- Create a tile for each known cooldown
    local xOffset = 0
    for i, spell in ipairs(_CooldownTracker.knownCooldowns) do
        local tile = _CooldownTracker.CreateTile(frame, spell, tileSize)
        tile:SetPoint("LEFT", frame, "LEFT", xOffset, 0)
        tile:Show()

        table.insert(_CooldownTracker.tiles, tile)
        xOffset = xOffset + tileSize + spacing
    end

    -- Update frame size
    local totalWidth = math.max(1, xOffset - spacing)
    frame:SetSize(totalWidth, tileSize)
end

--- Create a single cooldown tile
---@param parent Frame
---@param spell table The spell data from LongCooldowns
---@param size number Tile size
---@return Frame tile
function _CooldownTracker.CreateTile(parent, spell, size)
    local tile = CreateFrame("Frame", nil, parent)
    tile:SetSize(size, size)

    -- Store spell reference
    tile.spell = spell
    tile.spellId = spell.spellId

    -- Icon
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    tile.icon:SetTexture(spell.icon)

    -- Cooldown overlay (semi-transparent)
    tile.cooldownOverlay = tile:CreateTexture(nil, "OVERLAY")
    tile.cooldownOverlay:SetAllPoints()
    tile.cooldownOverlay:SetColorTexture(0, 0, 0, 0.6)
    tile.cooldownOverlay:Hide()

    -- Cooldown text (centered)
    tile.cooldownText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    tile.cooldownText:SetPoint("CENTER", 0, 0)
    tile.cooldownText:SetTextColor(1, 1, 1, 1)
    tile.cooldownText:SetShadowOffset(1, -1)
    tile.cooldownText:Hide()

    -- Ready indicator (green glow when off cooldown)
    tile.readyGlow = tile:CreateTexture(nil, "OVERLAY", nil, 2)
    tile.readyGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.readyGlow:SetBlendMode("ADD")
    tile.readyGlow:SetPoint("CENTER")
    tile.readyGlow:SetSize(size * 1.3, size * 1.3)
    tile.readyGlow:SetVertexColor(0.3, 1.0, 0.3, 0.5)
    tile.readyGlow:Hide()

    -- Border
    tile.border = tile:CreateTexture(nil, "OVERLAY")
    tile.border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    tile.border:SetAllPoints()
    tile.border:SetVertexColor(0.3, 0.3, 0.3, 0.8)

    -- Tooltip
    tile:EnableMouse(true)
    tile:SetScript("OnEnter", function(self)
        _CooldownTracker.OnTileEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _CooldownTracker.OnTileLeave(self)
    end)

    -- Update function
    tile.Update = function(self)
        _CooldownTracker.UpdateTile(self)
    end

    return tile
end

-- =============================================================================
-- UPDATE LOGIC
-- =============================================================================

--- Start the periodic update timer
function _CooldownTracker.StartUpdateTimer()
    if _CooldownTracker.updateTimer then
        _CooldownTracker.updateTimer:Cancel()
        _CooldownTracker.updateTimer = nil
    end

    _CooldownTracker.updateTimer = C_Timer.NewTicker(UPDATE_INTERVAL, function()
        _CooldownTracker.UpdateAllTiles()
    end)
end

--- Stop the update timer
function _CooldownTracker.StopUpdateTimer()
    if _CooldownTracker.updateTimer then
        _CooldownTracker.updateTimer:Cancel()
        _CooldownTracker.updateTimer = nil
    end
end

--- Update all cooldown tiles
function _CooldownTracker.UpdateAllTiles()
    for _, tile in ipairs(_CooldownTracker.tiles) do
        _CooldownTracker.UpdateTile(tile)
    end
end

--- Format time for display
---@param seconds number
---@return string
local function FormatCooldownTime(seconds)
    if seconds >= 3600 then
        -- Hours
        return string.format("%dh", math.floor(seconds / 3600))
    elseif seconds >= 60 then
        -- Minutes
        return string.format("%dm", math.floor(seconds / 60))
    else
        -- Seconds
        return string.format("%d", math.floor(seconds))
    end
end

--- Update a single cooldown tile
---@param tile Frame
function _CooldownTracker.UpdateTile(tile)
    if not tile or not tile.spellId then return end

    local db = GetDB()
    if not db then return end

    local remaining, duration, onCooldown = db:GetCooldownInfo(tile.spellId)

    if onCooldown and remaining > 0 then
        -- On cooldown - show overlay and time
        tile.cooldownOverlay:Show()
        tile.cooldownText:SetText(FormatCooldownTime(remaining))
        tile.cooldownText:Show()
        tile.readyGlow:Hide()
        tile.icon:SetDesaturated(true)

        -- Color text based on time remaining
        if remaining <= 30 then
            tile.cooldownText:SetTextColor(0.3, 1.0, 0.3)  -- Green - almost ready
        elseif remaining <= 60 then
            tile.cooldownText:SetTextColor(1.0, 1.0, 0.3)  -- Yellow
        else
            tile.cooldownText:SetTextColor(1.0, 1.0, 1.0)  -- White
        end
    else
        -- Ready
        tile.cooldownOverlay:Hide()
        tile.cooldownText:Hide()
        tile.icon:SetDesaturated(false)

        -- Show ready glow if configured
        local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
        if profile.showCooldownReadyGlow then
            tile.readyGlow:Show()
        else
            tile.readyGlow:Hide()
        end
    end
end

-- =============================================================================
-- TOOLTIP
-- =============================================================================

--- Show tooltip on tile hover
---@param tile Frame
function _CooldownTracker.OnTileEnter(tile)
    if not tile.spell then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    if not profile.showTooltips then return end

    GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(tile.spellId)

    -- Add cooldown info
    local db = GetDB()
    if db then
        local remaining, duration, onCooldown = db:GetCooldownInfo(tile.spellId)

        GameTooltip:AddLine(" ")
        if onCooldown and remaining > 0 then
            local minutes = math.floor(remaining / 60)
            local seconds = math.floor(remaining % 60)
            if minutes > 0 then
                GameTooltip:AddLine(string.format(L["Cooldown: %dm %ds"], minutes, seconds), 1, 0.3, 0.3)
            else
                GameTooltip:AddLine(string.format(L["Cooldown: %ds"], seconds), 1, 0.3, 0.3)
            end
        else
            GameTooltip:AddLine(L["Ready"], 0.3, 1, 0.3)
        end

        -- Show category
        if tile.spell.category then
            local categoryLabel = db.CategoryLabels[tile.spell.category] or tile.spell.category
            GameTooltip:AddLine(categoryLabel, 0.5, 0.5, 0.5)
        end
    end

    GameTooltip:Show()
end

--- Hide tooltip
---@param tile Frame
function _CooldownTracker.OnTileLeave(tile)
    GameTooltip:Hide()
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

--- Show the cooldown tracker
function CooldownTracker:Show()
    if _CooldownTracker.frame then
        _CooldownTracker.frame:Show()
        _CooldownTracker.StartUpdateTimer()
    end
end

--- Hide the cooldown tracker
function CooldownTracker:Hide()
    if _CooldownTracker.frame then
        _CooldownTracker.frame:Hide()
        _CooldownTracker.StopUpdateTimer()
    end
end

--- Refresh the tracker (rescan spells, recreate tiles)
function CooldownTracker:Refresh()
    _CooldownTracker.ScanKnownCooldowns()
    if _CooldownTracker.frame then
        _CooldownTracker.CreateTiles()
        _CooldownTracker.UpdateAllTiles()
    end
end

--- Get the tracker frame
---@return Frame|nil
function CooldownTracker:GetFrame()
    return _CooldownTracker.frame
end

--- Update tile sizes
---@param size number
function CooldownTracker:UpdateTileSize(size)
    if not _CooldownTracker.frame then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local spacing = profile.cooldownTrackerSpacing or TRACKER_SPACING

    local xOffset = 0
    for _, tile in ipairs(_CooldownTracker.tiles) do
        tile:SetSize(size, size)
        tile:ClearAllPoints()
        tile:SetPoint("LEFT", _CooldownTracker.frame, "LEFT", xOffset, 0)

        if tile.readyGlow then
            tile.readyGlow:SetSize(size * 1.3, size * 1.3)
        end

        xOffset = xOffset + size + spacing
    end

    -- Update frame size
    local totalWidth = math.max(1, xOffset - spacing)
    _CooldownTracker.frame:SetSize(totalWidth, size)
end

--- Cleanup (called when addon is disabled)
function CooldownTracker:Cleanup()
    _CooldownTracker.StopUpdateTimer()
end

return CooldownTracker
