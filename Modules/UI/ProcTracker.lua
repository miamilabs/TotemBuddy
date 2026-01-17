--[[
    TotemBuddy - Proc Tracker Module
    Displays important shaman proc effects (Elemental Focus, Nature's Swiftness, etc.)
]]

---@class ProcTracker
local ProcTracker = TotemBuddyLoader:CreateModule("ProcTracker")
local _ProcTracker = ProcTracker.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ShamanProcs = nil

-- Constants
local TRACKER_TILE_SIZE = 36
local TRACKER_SPACING = 4
local UPDATE_INTERVAL = 0.1  -- Fast updates for smooth countdowns
local MAX_PROCS = 4  -- Maximum procs to display

-- State
_ProcTracker.frame = nil
_ProcTracker.tiles = {}
_ProcTracker.updateTimer = nil
_ProcTracker.activeProcs = {}

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

--- Get the ShamanProcs database
local function GetDB()
    if not ShamanProcs then
        ShamanProcs = _G.TotemBuddyShamanProcs
    end
    return ShamanProcs
end

-- =============================================================================
-- FRAME CREATION
-- =============================================================================

--- Create the proc tracker frame
---@param parent Frame The parent frame
---@return Frame trackerFrame
function ProcTracker:Create(parent)
    if _ProcTracker.frame then
        return _ProcTracker.frame
    end

    -- Create container frame
    local frame = CreateFrame("Frame", "TotemBuddyProcTracker", parent or UIParent)
    frame:SetSize(100, TRACKER_TILE_SIZE)

    _ProcTracker.frame = frame

    -- Create tile pool
    _ProcTracker.CreateTilePool()

    -- Register for buff events
    frame:RegisterEvent("UNIT_AURA")
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_AURA" and unit == "player" then
            _ProcTracker.RefreshProcs()
        end
    end)

    -- Start update timer
    _ProcTracker.StartUpdateTimer()

    return frame
end

--- Create a pool of reusable tiles
function _ProcTracker.CreateTilePool()
    local frame = _ProcTracker.frame
    if not frame then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local tileSize = profile.procTrackerTileSize or TRACKER_TILE_SIZE

    _ProcTracker.tiles = {}
    for i = 1, MAX_PROCS do
        local tile = _ProcTracker.CreateTile(frame, tileSize)
        tile:Hide()
        _ProcTracker.tiles[i] = tile
    end
end

--- Create a single proc tile
---@param parent Frame
---@param size number Tile size
---@return Frame tile
function _ProcTracker.CreateTile(parent, size)
    local tile = CreateFrame("Frame", nil, parent)
    tile:SetSize(size, size)

    -- Background glow (shows when proc is active)
    tile.glow = tile:CreateTexture(nil, "BACKGROUND")
    tile.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.glow:SetBlendMode("ADD")
    tile.glow:SetPoint("CENTER")
    tile.glow:SetSize(size * 1.5, size * 1.5)
    tile.glow:SetVertexColor(1.0, 0.8, 0.2, 0.7)

    -- Create glow animation
    tile.glowAnim = tile.glow:CreateAnimationGroup()
    tile.glowAnim:SetLooping("BOUNCE")
    local pulse = tile.glowAnim:CreateAnimation("Scale")
    pulse:SetScale(1.15, 1.15)
    pulse:SetDuration(0.5)
    pulse:SetSmoothing("IN_OUT")

    -- Icon
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Duration/stack text (centered, large)
    tile.stackText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    tile.stackText:SetPoint("CENTER", 0, 0)
    tile.stackText:SetTextColor(1, 1, 1, 1)
    tile.stackText:SetShadowOffset(1, -1)

    -- Duration text (bottom)
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    tile.durationText:SetPoint("BOTTOM", 0, 2)
    tile.durationText:SetTextColor(1, 1, 0.3, 1)
    tile.durationText:SetShadowOffset(1, -1)

    -- Border
    tile.border = tile:CreateTexture(nil, "OVERLAY", nil, 2)
    tile.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    tile.border:SetAllPoints()

    -- Tooltip
    tile:EnableMouse(true)
    tile:SetScript("OnEnter", function(self)
        _ProcTracker.OnTileEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _ProcTracker.OnTileLeave(self)
    end)

    return tile
end

-- =============================================================================
-- UPDATE LOGIC
-- =============================================================================

--- Start the periodic update timer
function _ProcTracker.StartUpdateTimer()
    if _ProcTracker.updateTimer then
        _ProcTracker.updateTimer:Cancel()
        _ProcTracker.updateTimer = nil
    end

    _ProcTracker.updateTimer = C_Timer.NewTicker(UPDATE_INTERVAL, function()
        _ProcTracker.UpdateAllTiles()
    end)
end

--- Stop the update timer
function _ProcTracker.StopUpdateTimer()
    if _ProcTracker.updateTimer then
        _ProcTracker.updateTimer:Cancel()
        _ProcTracker.updateTimer = nil
    end
end

--- Refresh procs from player buffs
function _ProcTracker.RefreshProcs()
    local db = GetDB()
    if not db then return end

    local frame = _ProcTracker.frame
    if not frame or not frame:IsShown() then return end

    -- Scan for active procs
    local procs = db:ScanActiveProcs()
    _ProcTracker.activeProcs = procs

    -- Update tiles
    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    local tileSize = profile.procTrackerTileSize or TRACKER_TILE_SIZE
    local spacing = profile.procTrackerSpacing or TRACKER_SPACING

    local visibleCount = 0
    for i, tile in ipairs(_ProcTracker.tiles) do
        local procInfo = procs[i]
        if procInfo then
            tile.procInfo = procInfo
            tile.icon:SetTexture(procInfo.icon)
            tile:Show()

            -- Start glow animation for important procs
            if procInfo.proc.priority <= 2 then
                tile.glowAnim:Play()
            else
                tile.glowAnim:Stop()
            end

            visibleCount = visibleCount + 1
        else
            tile.procInfo = nil
            tile:Hide()
            tile.glowAnim:Stop()
        end
    end

    -- Position visible tiles
    local xOffset = 0
    for i, tile in ipairs(_ProcTracker.tiles) do
        if tile:IsShown() then
            tile:ClearAllPoints()
            tile:SetPoint("LEFT", frame, "LEFT", xOffset, 0)
            xOffset = xOffset + tileSize + spacing
        end
    end

    -- Resize frame
    local totalWidth = math.max(1, xOffset - spacing)
    if visibleCount == 0 then
        totalWidth = 1
    end
    frame:SetSize(totalWidth, tileSize)

    -- Initial update
    _ProcTracker.UpdateAllTiles()
end

--- Update all visible tiles
function _ProcTracker.UpdateAllTiles()
    for _, tile in ipairs(_ProcTracker.tiles) do
        if tile:IsShown() and tile.procInfo then
            _ProcTracker.UpdateTile(tile)
        end
    end
end

--- Format time for display
---@param seconds number
---@return string
local function FormatProcTime(seconds)
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
function _ProcTracker.UpdateTile(tile)
    local info = tile.procInfo
    if not info then return end

    local db = GetDB()
    if not db then return end

    -- Re-scan for current state
    local active, remaining, stacks = db:IsProcActive(info.proc.name)

    if not active then
        -- Proc expired
        tile:Hide()
        tile.procInfo = nil
        tile.glowAnim:Stop()
        return
    end

    -- Update stack count display
    if info.proc.maxStacks and stacks then
        -- Show stack count prominently (e.g., Maelstrom Weapon)
        tile.stackText:SetText(tostring(stacks))
        tile.stackText:Show()

        -- Color based on stack count
        if stacks >= (info.proc.maxStacks or 5) then
            tile.stackText:SetTextColor(0.3, 1.0, 0.3)  -- Green at max
            tile.glow:SetVertexColor(0.3, 1.0, 0.3, 0.8)
        else
            tile.stackText:SetTextColor(1, 1, 1)
            tile.glow:SetVertexColor(1.0, 0.8, 0.2, 0.7)
        end
    elseif info.proc.charges and stacks and stacks > 0 then
        -- Show charges (e.g., Clearcasting)
        tile.stackText:SetText(tostring(stacks))
        tile.stackText:Show()
        tile.stackText:SetTextColor(1, 1, 1)
    else
        tile.stackText:Hide()
    end

    -- Update duration display
    if remaining and remaining > 0 then
        tile.durationText:SetText(FormatProcTime(remaining))
        tile.durationText:Show()

        -- Warning color when about to expire
        if remaining <= 3 then
            tile.durationText:SetTextColor(1, 0.3, 0.3)
        else
            tile.durationText:SetTextColor(1, 1, 0.3)
        end
    else
        tile.durationText:Hide()
    end
end

-- =============================================================================
-- TOOLTIP
-- =============================================================================

--- Show tooltip on tile hover
---@param tile Frame
function _ProcTracker.OnTileEnter(tile)
    if not tile.procInfo then return end

    local profile = TotemBuddy.db and TotemBuddy.db.profile or {}
    if not profile.showTooltips then return end

    local info = tile.procInfo

    GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
    if info.spellId then
        GameTooltip:SetSpellByID(info.spellId)
    else
        GameTooltip:AddLine(info.name, 1, 1, 1)
        if info.proc.description then
            GameTooltip:AddLine(info.proc.description, 1, 0.8, 0)
        end
    end

    -- Add proc info
    GameTooltip:AddLine(" ")

    local db = GetDB()
    if db then
        local active, remaining, stacks = db:IsProcActive(info.proc.name)
        if active then
            if stacks and stacks > 1 then
                GameTooltip:AddLine(string.format(L["Stacks: %d"], stacks), 0.3, 1, 0.3)
            end
            if remaining and remaining > 0 then
                GameTooltip:AddLine(string.format(L["Remaining: %.1fs"], remaining), 1, 0.8, 0.3)
            end
        end
    end

    -- Add category
    if info.proc.category then
        local db = GetDB()
        local categoryLabel = db and db.CategoryLabels[info.proc.category] or info.proc.category
        GameTooltip:AddLine(categoryLabel, 0.5, 0.5, 0.5)
    end

    GameTooltip:Show()
end

--- Hide tooltip
---@param tile Frame
function _ProcTracker.OnTileLeave(tile)
    GameTooltip:Hide()
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

--- Show the proc tracker
function ProcTracker:Show()
    if _ProcTracker.frame then
        _ProcTracker.frame:Show()
        _ProcTracker.StartUpdateTimer()
        _ProcTracker.RefreshProcs()
    end
end

--- Hide the proc tracker
function ProcTracker:Hide()
    if _ProcTracker.frame then
        _ProcTracker.frame:Hide()
        _ProcTracker.StopUpdateTimer()
    end
end

--- Refresh the tracker
function ProcTracker:Refresh()
    _ProcTracker.RefreshProcs()
end

--- Get the tracker frame
---@return Frame|nil
function ProcTracker:GetFrame()
    return _ProcTracker.frame
end

--- Update tile sizes
---@param size number
function ProcTracker:UpdateTileSize(size)
    if not _ProcTracker.tiles then return end

    for _, tile in ipairs(_ProcTracker.tiles) do
        tile:SetSize(size, size)
        if tile.glow then
            tile.glow:SetSize(size * 1.5, size * 1.5)
        end
    end

    _ProcTracker.RefreshProcs()
end

--- Cleanup
function ProcTracker:Cleanup()
    _ProcTracker.StopUpdateTimer()
end

return ProcTracker
