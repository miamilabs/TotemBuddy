--[[
    TotemBuddy - Debuff Tracker Module
    Displays important shaman debuffs on the current target (Flame Shock, Stormstrike, etc.)
]]

---@class DebuffTracker
local DebuffTracker = TotemBuddyLoader:CreateModule("DebuffTracker")
local _DebuffTracker = DebuffTracker.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local TargetDebuffs = nil

-- Constants
local TRACKER_TILE_SIZE = 28
local TRACKER_SPACING = 2
local UPDATE_INTERVAL = 0.1  -- Update frequently for smooth countdown
local MAX_DEBUFFS = 4  -- Maximum debuffs to display

-- State
_DebuffTracker.frame = nil
_DebuffTracker.tiles = {}
_DebuffTracker.updateTimer = nil
_DebuffTracker.currentTarget = nil

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

--- Get the TargetDebuffs database
local function GetDB()
    if not TargetDebuffs then
        TargetDebuffs = _G.TotemBuddyTargetDebuffs
    end
    return TargetDebuffs
end

-- =============================================================================
-- FRAME CREATION
-- =============================================================================

--- Create the debuff tracker frame
---@param parent Frame The parent frame
---@return Frame trackerFrame
function DebuffTracker:Create(parent)
    if _DebuffTracker.frame then
        return _DebuffTracker.frame
    end

    -- Create container frame
    local frame = CreateFrame("Frame", "TotemBuddyDebuffTracker", parent or UIParent)
    frame:SetSize(100, TRACKER_TILE_SIZE)  -- Will be resized based on content

    _DebuffTracker.frame = frame

    -- Create tile pool
    _DebuffTracker.CreateTilePool()

    -- Register for target change events
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_AURA")
    frame:SetScript("OnEvent", function(self, event, ...)
        _DebuffTracker.OnEvent(event, ...)
    end)

    -- Start update timer
    _DebuffTracker.StartUpdateTimer()

    return frame
end

--- Create a pool of reusable tiles
function _DebuffTracker.CreateTilePool()
    local frame = _DebuffTracker.frame
    if not frame then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local tileSize = profile.debuffTrackerTileSize or TRACKER_TILE_SIZE

    _DebuffTracker.tiles = {}
    for i = 1, MAX_DEBUFFS do
        local tile = _DebuffTracker.CreateTile(frame, tileSize)
        tile:Hide()
        _DebuffTracker.tiles[i] = tile
    end
end

--- Create a single debuff tile
---@param parent Frame
---@param size number Tile size
---@return Frame tile
function _DebuffTracker.CreateTile(parent, size)
    local tile = CreateFrame("Frame", nil, parent)
    tile:SetSize(size, size)

    -- Icon
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Duration bar (bottom)
    tile.durationBar = tile:CreateTexture(nil, "OVERLAY")
    tile.durationBar:SetColorTexture(1, 0.8, 0, 1)  -- Yellow/orange
    tile.durationBar:SetPoint("BOTTOMLEFT", 1, 1)
    tile.durationBar:SetPoint("BOTTOMRIGHT", -1, 1)
    tile.durationBar:SetHeight(3)

    -- Duration text (centered)
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    tile.durationText:SetPoint("CENTER", 0, 0)
    tile.durationText:SetTextColor(1, 1, 1, 1)
    tile.durationText:SetShadowOffset(1, -1)

    -- Stack count (top-right)
    tile.stackText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    tile.stackText:SetPoint("TOPRIGHT", -1, -1)
    tile.stackText:SetTextColor(1, 1, 1, 1)
    tile.stackText:SetShadowOffset(1, -1)
    tile.stackText:Hide()

    -- Border
    tile.border = tile:CreateTexture(nil, "OVERLAY", nil, 2)
    tile.border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    tile.border:SetAllPoints()
    tile.border:SetVertexColor(0.6, 0.6, 0.6, 0.8)

    -- Expiring warning glow
    tile.warningGlow = tile:CreateTexture(nil, "OVERLAY", nil, 3)
    tile.warningGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.warningGlow:SetBlendMode("ADD")
    tile.warningGlow:SetPoint("CENTER")
    tile.warningGlow:SetSize(size * 1.3, size * 1.3)
    tile.warningGlow:SetVertexColor(1.0, 0.3, 0.1, 0.6)  -- Red/orange
    tile.warningGlow:Hide()

    -- Tooltip
    tile:EnableMouse(true)
    tile:SetScript("OnEnter", function(self)
        _DebuffTracker.OnTileEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _DebuffTracker.OnTileLeave(self)
    end)

    return tile
end

-- =============================================================================
-- EVENT HANDLING
-- =============================================================================

--- Handle events
---@param event string
---@vararg any
function _DebuffTracker.OnEvent(event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        _DebuffTracker.OnTargetChanged()
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "target" then
            _DebuffTracker.RefreshDebuffs()
        end
    end
end

--- Called when target changes
function _DebuffTracker.OnTargetChanged()
    _DebuffTracker.currentTarget = UnitGUID("target")
    _DebuffTracker.RefreshDebuffs()
end

-- =============================================================================
-- UPDATE LOGIC
-- =============================================================================

--- Start the periodic update timer
function _DebuffTracker.StartUpdateTimer()
    if _DebuffTracker.updateTimer then
        _DebuffTracker.updateTimer:Cancel()
        _DebuffTracker.updateTimer = nil
    end

    _DebuffTracker.updateTimer = C_Timer.NewTicker(UPDATE_INTERVAL, function()
        _DebuffTracker.UpdateAllTiles()
    end)
end

--- Stop the update timer
function _DebuffTracker.StopUpdateTimer()
    if _DebuffTracker.updateTimer then
        _DebuffTracker.updateTimer:Cancel()
        _DebuffTracker.updateTimer = nil
    end
end

--- Refresh debuffs from target
function _DebuffTracker.RefreshDebuffs()
    local db = GetDB()
    if not db then return end

    local frame = _DebuffTracker.frame
    if not frame or not frame:IsShown() then return end

    -- Scan for debuffs
    local debuffs = db:ScanAllDebuffs("target")

    -- Update tiles
    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local tileSize = profile.debuffTrackerTileSize or TRACKER_TILE_SIZE
    local spacing = profile.debuffTrackerSpacing or TRACKER_SPACING

    local visibleCount = 0
    for i, tile in ipairs(_DebuffTracker.tiles) do
        local debuffInfo = debuffs[i]
        if debuffInfo then
            tile.debuffInfo = debuffInfo
            tile.icon:SetTexture(debuffInfo.icon)
            tile:Show()
            visibleCount = visibleCount + 1
        else
            tile.debuffInfo = nil
            tile:Hide()
        end
    end

    -- Position visible tiles
    local xOffset = 0
    for i, tile in ipairs(_DebuffTracker.tiles) do
        if tile:IsShown() then
            tile:ClearAllPoints()
            tile:SetPoint("LEFT", frame, "LEFT", xOffset, 0)
            xOffset = xOffset + tileSize + spacing
        end
    end

    -- Resize frame
    local totalWidth = math.max(1, xOffset - spacing)
    if visibleCount == 0 then
        totalWidth = 1  -- Minimal size when nothing to show
    end
    frame:SetSize(totalWidth, tileSize)

    -- Initial update
    _DebuffTracker.UpdateAllTiles()
end

--- Update all visible tiles
function _DebuffTracker.UpdateAllTiles()
    local db = GetDB()
    if not db then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local warningThreshold = profile.debuffWarningThreshold or 3

    for _, tile in ipairs(_DebuffTracker.tiles) do
        if tile:IsShown() and tile.debuffInfo then
            _DebuffTracker.UpdateTile(tile, warningThreshold)
        end
    end
end

--- Format time for display
---@param seconds number
---@return string
local function FormatDebuffTime(seconds)
    if seconds >= 60 then
        return string.format("%dm", math.floor(seconds / 60))
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds))
    else
        return string.format("%.1f", seconds)
    end
end

--- Update a single tile
---@param tile Frame
---@param warningThreshold number
function _DebuffTracker.UpdateTile(tile, warningThreshold)
    local info = tile.debuffInfo
    if not info then return end

    -- Re-scan for current remaining time
    local db = GetDB()
    local found, remaining, duration, stacks = db:ScanForDebuff(info.name, "target")

    if not found then
        -- Debuff expired or removed
        tile:Hide()
        tile.debuffInfo = nil
        return
    end

    -- Update duration text
    if remaining and remaining > 0 then
        tile.durationText:SetText(FormatDebuffTime(remaining))
        tile.durationText:Show()

        -- Update duration bar
        if duration and duration > 0 then
            local pct = remaining / duration
            local barWidth = tile:GetWidth() - 2
            tile.durationBar:SetWidth(math.max(1, barWidth * pct))
            tile.durationBar:Show()

            -- Color based on remaining time
            if remaining <= warningThreshold then
                tile.durationBar:SetColorTexture(1, 0.2, 0.1, 1)  -- Red
                tile.durationText:SetTextColor(1, 0.3, 0.3)
                tile.warningGlow:Show()
            elseif remaining <= warningThreshold * 2 then
                tile.durationBar:SetColorTexture(1, 0.6, 0, 1)  -- Orange
                tile.durationText:SetTextColor(1, 0.8, 0.3)
                tile.warningGlow:Hide()
            else
                tile.durationBar:SetColorTexture(0.2, 0.8, 0.2, 1)  -- Green
                tile.durationText:SetTextColor(1, 1, 1)
                tile.warningGlow:Hide()
            end
        else
            tile.durationBar:Hide()
        end
    else
        tile.durationText:Hide()
        tile.durationBar:Hide()
        tile.warningGlow:Hide()
    end

    -- Update stack count
    if stacks and stacks > 1 then
        tile.stackText:SetText(tostring(stacks))
        tile.stackText:Show()
    else
        tile.stackText:Hide()
    end
end

-- =============================================================================
-- TOOLTIP
-- =============================================================================

--- Show tooltip on tile hover
---@param tile Frame
function _DebuffTracker.OnTileEnter(tile)
    if not tile.debuffInfo then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    if not profile.showTooltips then return end

    local info = tile.debuffInfo

    GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
    if info.spellId then
        GameTooltip:SetSpellByID(info.spellId)
    else
        GameTooltip:AddLine(info.name, 1, 1, 1)
    end

    -- Add remaining time
    local db = GetDB()
    if db then
        local found, remaining, duration = db:ScanForDebuff(info.name, "target")
        if found and remaining and remaining > 0 then
            GameTooltip:AddLine(" ")
            local minutes = math.floor(remaining / 60)
            local seconds = math.floor(remaining % 60)
            if minutes > 0 then
                GameTooltip:AddLine(string.format(L["Remaining: %dm %ds"], minutes, seconds), 1, 0.8, 0.3)
            else
                GameTooltip:AddLine(string.format(L["Remaining: %ds"], seconds), 1, 0.8, 0.3)
            end
        end
    end

    -- Add category
    if info.debuff and info.debuff.category then
        local db = GetDB()
        local categoryLabel = db and db.CategoryLabels[info.debuff.category] or info.debuff.category
        GameTooltip:AddLine(categoryLabel, 0.5, 0.5, 0.5)
    end

    GameTooltip:Show()
end

--- Hide tooltip
---@param tile Frame
function _DebuffTracker.OnTileLeave(tile)
    GameTooltip:Hide()
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

--- Show the debuff tracker
function DebuffTracker:Show()
    if _DebuffTracker.frame then
        _DebuffTracker.frame:Show()
        _DebuffTracker.StartUpdateTimer()
        _DebuffTracker.RefreshDebuffs()
    end
end

--- Hide the debuff tracker
function DebuffTracker:Hide()
    if _DebuffTracker.frame then
        _DebuffTracker.frame:Hide()
        _DebuffTracker.StopUpdateTimer()
    end
end

--- Refresh the tracker
function DebuffTracker:Refresh()
    _DebuffTracker.RefreshDebuffs()
end

--- Get the tracker frame
---@return Frame|nil
function DebuffTracker:GetFrame()
    return _DebuffTracker.frame
end

--- Update tile sizes
---@param size number
function DebuffTracker:UpdateTileSize(size)
    if not _DebuffTracker.tiles then return end

    for _, tile in ipairs(_DebuffTracker.tiles) do
        tile:SetSize(size, size)
        if tile.warningGlow then
            tile.warningGlow:SetSize(size * 1.3, size * 1.3)
        end
    end

    -- Re-layout
    _DebuffTracker.RefreshDebuffs()
end

--- Cleanup (called when addon is disabled)
function DebuffTracker:Cleanup()
    _DebuffTracker.StopUpdateTimer()
end

return DebuffTracker
