--[[
    TotemBuddy - Totem Bar Module
    Main container frame holding the 4 totem tiles
]]

---@class TotemBar
local TotemBar = TotemBuddyLoader:CreateModule("TotemBar")
local _TotemBar = TotemBar.private

-- Module references
local TotemTile = nil
local TotemData = nil
local SpellScanner = nil

-- Main frame
TotemBar.frame = nil
TotemBar.tiles = {}

--- Create the totem bar
function TotemBar:Create()
    if self.frame then
        return self.frame
    end

    -- Get modules
    TotemTile = TotemBuddyLoader:ImportModule("TotemTile")
    TotemData = TotemBuddyLoader:ImportModule("TotemData")
    SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")

    local frame = CreateFrame("Frame", "TotemBuddyBar", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)

    -- Backdrop
    if TotemBuddy.db.profile.showBorder then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4},
        })
        -- Defensive check for backgroundColor table
        local bg = TotemBuddy.db.profile.backgroundColor
        if type(bg) ~= "table" then
            bg = {0, 0, 0, 0.5}
        end
        frame:SetBackdropColor(
            tonumber(bg[1]) or 0,
            tonumber(bg[2]) or 0,
            tonumber(bg[3]) or 0,
            tonumber(bg[4]) or 0.5
        )
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end

    -- Drag handling
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not TotemBuddy.db.profile.locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = self:GetPoint()
        TotemBuddy.db.profile.anchor = point
        TotemBuddy.db.profile.posX = x
        TotemBuddy.db.profile.posY = y
    end)

    -- Create 4 totem tiles
    self.tiles = {}
    for i = 1, 4 do
        self.tiles[i] = TotemTile:Create(frame, i)
    end

    self.frame = frame

    -- OnUpdate handler (will be set when shown, removed when hidden)
    self.updateInterval = 0.1
    self.timeSinceLastUpdate = 0
    self.onUpdateFunc = function(_, elapsed)
        TotemBar.timeSinceLastUpdate = TotemBar.timeSinceLastUpdate + elapsed
        if TotemBar.timeSinceLastUpdate >= TotemBar.updateInterval then
            TotemBar.timeSinceLastUpdate = 0
            TotemBar:UpdateTimers()
        end
    end

    -- Apply saved position
    self:RestorePosition()

    -- Apply layout
    self:UpdateLayout()

    -- Set initial totems
    self:RefreshAllTiles()

    return frame
end

--- Restore saved position
function TotemBar:RestorePosition()
    if not self.frame then
        return
    end

    local anchor = TotemBuddy.db.profile.anchor or "CENTER"
    local x = TotemBuddy.db.profile.posX or 0
    local y = TotemBuddy.db.profile.posY or -200

    self.frame:ClearAllPoints()
    self.frame:SetPoint(anchor, UIParent, anchor, x, y)
    self.frame:SetScale(TotemBuddy.db.profile.scale or 1.0)
end

--- Update the layout (horizontal, vertical, grid)
function TotemBar:UpdateLayout()
    if not self.frame or not self.tiles then
        return
    end

    local layout = TotemBuddy.db.profile.layout or "horizontal"
    local size = TotemBuddy.db.profile.tileSize or 40
    local spacing = TotemBuddy.db.profile.tileSpacing or 4
    local padding = 8

    -- Update tile sizes
    for _, tile in ipairs(self.tiles) do
        tile:UpdateSize(size)
    end

    -- Position tiles based on layout
    for i, tile in ipairs(self.tiles) do
        tile:ClearAllPoints()

        if layout == "horizontal" then
            tile:SetPoint("LEFT", self.frame, "LEFT",
                padding + (i - 1) * (size + spacing), 0)

        elseif layout == "vertical" then
            tile:SetPoint("TOP", self.frame, "TOP",
                0, -padding - (i - 1) * (size + spacing))

        elseif layout == "grid2x2" then
            local row = math.floor((i - 1) / 2)
            local col = (i - 1) % 2
            tile:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
                padding + col * (size + spacing),
                -padding - row * (size + spacing))
        end
    end

    -- Resize frame to fit tiles
    local width, height

    if layout == "horizontal" then
        width = padding * 2 + 4 * size + 3 * spacing
        height = padding * 2 + size
    elseif layout == "vertical" then
        width = padding * 2 + size
        height = padding * 2 + 4 * size + 3 * spacing
    elseif layout == "grid2x2" then
        width = padding * 2 + 2 * size + spacing
        height = padding * 2 + 2 * size + spacing
    end

    self.frame:SetSize(width, height)
end

--- Refresh all tiles with current settings
function TotemBar:RefreshAllTiles()
    if not self.tiles then
        return
    end

    for i = 1, #self.tiles do
        self:RefreshTile(i)
    end
end

--- Refresh a single tile
---@param element number The element index (1-4)
function TotemBar:RefreshTile(element)
    local tile = self.tiles[element]
    if not tile then
        return
    end

    -- Ensure modules are loaded
    if not TotemData then
        TotemData = TotemBuddyLoader:ImportModule("TotemData")
    end
    if not SpellScanner then
        SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
    end

    -- Get the saved default totem for this element
    local defaultTotemName = TotemBuddy.db.profile.defaultTotems and TotemBuddy.db.profile.defaultTotems[element]
    local totemData = nil
    local spellId = nil

    if defaultTotemName and defaultTotemName ~= "" then
        -- Use efficient O(1) lookup by name
        totemData = TotemData:GetTotemByName(defaultTotemName)
    end

    -- If no default set or not found, use first known totem
    if not totemData and SpellScanner then
        totemData = SpellScanner:GetFirstKnownTotemForElement(element)
    end

    -- Get spell ID
    if totemData then
        if TotemBuddy.db.profile.useHighestRank then
            spellId = TotemBuddy.HighestRanks[totemData.name]
        else
            local savedRank = TotemBuddy.db.profile.totemRanks[totemData.name]
            if savedRank and TotemBuddy.KnownTotems[savedRank] then
                spellId = savedRank
            else
                spellId = TotemBuddy.HighestRanks[totemData.name]
            end
        end
    end

    -- Update the tile
    tile:SetTotem(spellId, totemData)
end

--- Update cooldowns on all tiles
function TotemBar:UpdateCooldowns()
    if not self.tiles then
        return
    end

    for _, tile in ipairs(self.tiles) do
        tile:UpdateCooldown()
    end
end

--- Update timers on all tiles (called from OnUpdate)
function TotemBar:UpdateTimers()
    if not self.tiles or not self.frame or not self.frame:IsShown() then
        return
    end

    -- Only update if any timer option is enabled
    local db = TotemBuddy.db.profile
    if not db.showCooldownText and not db.showDurationText and not db.showActiveGlow then
        return
    end

    for _, tile in ipairs(self.tiles) do
        if tile.UpdateCooldown then
            tile:UpdateCooldown()
        end
    end
end

--- Update a specific totem slot (called on PLAYER_TOTEM_UPDATE)
---@param slot number The totem slot (1-4)
function TotemBar:UpdateTotemSlot(slot)
    -- Could add active totem indicator here
    -- For now, just update cooldown
    if self.tiles and self.tiles[slot] then
        self.tiles[slot]:UpdateCooldown()
    end
end

--- Show the totem bar
function TotemBar:Show()
    if self.frame then
        self.frame:Show()
        -- Enable OnUpdate when visible
        if self.onUpdateFunc then
            self.timeSinceLastUpdate = 0
            self.frame:SetScript("OnUpdate", self.onUpdateFunc)
        end
    end
end

--- Hide the totem bar
function TotemBar:Hide()
    if self.frame then
        -- Disable OnUpdate when hidden (performance)
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end

    -- Also hide selector
    local TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")
    if TotemSelector then
        TotemSelector:Hide()
    end
end

--- Set the locked state
---@param locked boolean Whether to lock the bar
function TotemBar:SetLocked(locked)
    if not self.frame then
        return
    end

    self.frame:SetMovable(not locked)

    -- Visual feedback
    if locked then
        self.frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    else
        self.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
end

--- Update the scale
---@param scale number The new scale (0.5-2.0)
function TotemBar:SetScale(scale)
    if self.frame then
        self.frame:SetScale(scale)
    end
end

--- Update the border visibility
---@param show boolean Whether to show the border
function TotemBar:SetBorderVisible(show)
    if not self.frame then
        return
    end

    if show then
        self.frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4},
        })
        -- Defensive check for backgroundColor table
        local bg = TotemBuddy.db.profile.backgroundColor
        if type(bg) ~= "table" then
            bg = {0, 0, 0, 0.5}
        end
        self.frame:SetBackdropColor(
            tonumber(bg[1]) or 0,
            tonumber(bg[2]) or 0,
            tonumber(bg[3]) or 0,
            tonumber(bg[4]) or 0.5
        )
    else
        self.frame:SetBackdrop(nil)
    end
end

return TotemBar
