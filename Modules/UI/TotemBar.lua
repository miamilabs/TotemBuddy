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
local TotemSets = nil
local ExtrasScanner = nil
local CallTile = nil
local ImbueTile = nil
local ShieldTile = nil

-- Main frame
TotemBar.frame = nil
TotemBar.tiles = {}
TotemBar.setNameText = nil  -- FontString for set name display

-- Extra tiles (v2.1)
TotemBar.callTiles = {}
TotemBar.imbueMH = nil
TotemBar.imbueOH = nil
TotemBar.shieldTile = nil
TotemBar.pendingExtrasUpdate = false

--- Create the totem bar
function TotemBar:Create()
    if self.frame then
        return self.frame
    end

    -- Get modules
    TotemTile = TotemBuddyLoader:ImportModule("TotemTile")
    TotemData = TotemBuddyLoader:ImportModule("TotemData")
    SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
    TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
    ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
    CallTile = TotemBuddyLoader:ImportModule("CallTile")
    ImbueTile = TotemBuddyLoader:ImportModule("ImbueTile")
    ShieldTile = TotemBuddyLoader:ImportModule("ShieldTile")

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
        -- Save position (guard against nil values from GetPoint)
        local point, _, _, x, y = self:GetPoint()
        if point and x and y then
            TotemBuddy.db.profile.anchor = point
            TotemBuddy.db.profile.posX = x
            TotemBuddy.db.profile.posY = y
        end
    end)

    -- Create 4 totem tiles
    self.tiles = {}
    for i = 1, 4 do
        self.tiles[i] = TotemTile:Create(frame, i)
    end

    -- Create set name display text (v2.0)
    self.setNameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.setNameText:SetPoint("TOP", frame, "TOP", 0, -2)
    self.setNameText:SetTextColor(0.9, 0.9, 0.9, 1)
    self.setNameText:SetText("")

    self.frame = frame

    -- Create extra tiles (v2.1: Call, Imbues, Shield)
    self:CreateExtraTiles()

    -- OnUpdate handler (will be set when shown, removed when hidden)
    self.updateInterval = 0.1
    self.timeSinceLastUpdate = 0
    self.onUpdateFunc = function(_, elapsed)
        TotemBar.timeSinceLastUpdate = TotemBar.timeSinceLastUpdate + elapsed
        if TotemBar.timeSinceLastUpdate >= TotemBar.updateInterval then
            TotemBar.timeSinceLastUpdate = 0
            TotemBar:UpdateTimers()
            TotemBar:UpdateExtraTimers()
        end
    end

    -- Apply saved position
    self:RestorePosition()

    -- Apply layout
    self:UpdateLayout()

    -- Set initial totems
    self:RefreshAllTiles()

    -- Update set name display (v2.0)
    self:UpdateSetNameDisplay()

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

    -- Update tile sizes for main tiles
    for _, tile in ipairs(self.tiles) do
        tile:UpdateSize(size)
    end

    -- Update extra tile sizes
    if self.callTiles then
        for _, tile in ipairs(self.callTiles) do
            if tile.UpdateSize then tile:UpdateSize(size) end
        end
    end
    if self.imbueMH and self.imbueMH.UpdateSize then self.imbueMH:UpdateSize(size) end
    if self.imbueOH and self.imbueOH.UpdateSize then self.imbueOH:UpdateSize(size) end
    if self.shieldTile and self.shieldTile.UpdateSize then self.shieldTile:UpdateSize(size) end

    -- Position main totem tiles (4 tiles)
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

    -- Get extra tiles
    local extraTiles = self:GetVisibleExtraTiles()
    local extraCount = #extraTiles

    -- Position extra tiles (after the 4 main tiles)
    for i, tile in ipairs(extraTiles) do
        tile:ClearAllPoints()
        local slotIndex = 4 + i  -- After the 4 totem tiles

        if layout == "horizontal" then
            tile:SetPoint("LEFT", self.frame, "LEFT",
                padding + (slotIndex - 1) * (size + spacing), 0)

        elseif layout == "vertical" then
            tile:SetPoint("TOP", self.frame, "TOP",
                0, -padding - (slotIndex - 1) * (size + spacing))

        elseif layout == "grid2x2" then
            -- For grid: extras continue in the grid pattern
            local row = math.floor((slotIndex - 1) / 2)
            local col = (slotIndex - 1) % 2
            tile:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
                padding + col * (size + spacing),
                -padding - row * (size + spacing))
        end
    end

    -- Calculate total tile count for frame sizing
    local totalTiles = 4 + extraCount

    -- Resize frame to fit all tiles
    local width, height

    if layout == "horizontal" then
        width = padding * 2 + totalTiles * size + (totalTiles - 1) * spacing
        height = padding * 2 + size
    elseif layout == "vertical" then
        width = padding * 2 + size
        height = padding * 2 + totalTiles * size + (totalTiles - 1) * spacing
    elseif layout == "grid2x2" then
        local cols = 2
        local rows = math.ceil(totalTiles / cols)
        width = padding * 2 + cols * size + (cols - 1) * spacing
        height = padding * 2 + rows * size + (rows - 1) * spacing
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

    -- Stop any active pulse animations on tiles (prevents CPU waste while hidden)
    if self.tiles then
        for _, tile in pairs(self.tiles) do
            if tile and tile.pulseAnim and tile.isPulsing then
                tile.pulseAnim:Stop()
            end
        end
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

--- Update all tile sizes (for duration bar height changes, etc.)
function TotemBar:UpdateAllTileSizes()
    if not self.tiles then
        return
    end
    local size = TotemBuddy.db.profile.tileSize or 40
    for _, tile in ipairs(self.tiles) do
        tile:UpdateSize(size)
    end
end

--- Update the set name display (v2.0)
function TotemBar:UpdateSetNameDisplay()
    if not self.setNameText then
        return
    end

    -- Check if showing set name is enabled
    if not TotemBuddy.db.profile.showSetName then
        self.setNameText:Hide()
        return
    end

    -- Get active set name
    if not TotemSets then
        TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
    end

    local activeSet = TotemSets and TotemSets:GetActiveSet()

    if activeSet then
        self.setNameText:SetText(activeSet)
        self.setNameText:Show()
    else
        self.setNameText:SetText("")
        self.setNameText:Hide()
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

-- =============================================================================
-- EXTRA TILES (v2.1)
-- =============================================================================

--- Create the extra tiles (Call, Imbues, Shield)
function TotemBar:CreateExtraTiles()
    if not self.frame then return end

    -- Get modules if needed
    if not CallTile then CallTile = TotemBuddyLoader:ImportModule("CallTile") end
    if not ImbueTile then ImbueTile = TotemBuddyLoader:ImportModule("ImbueTile") end
    if not ShieldTile then ShieldTile = TotemBuddyLoader:ImportModule("ShieldTile") end
    if not ExtrasScanner then ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner") end

    -- Create Call tiles (up to 3)
    self.callTiles = {}
    if CallTile then
        for i = 1, 3 do
            self.callTiles[i] = CallTile:Create(self.frame, i)
            self.callTiles[i]:Hide()  -- Hidden by default
        end
    end

    -- Create Imbue tiles (Mainhand + Offhand)
    if ImbueTile then
        self.imbueMH = ImbueTile:Create(self.frame, "mainhand")
        self.imbueMH:Hide()

        self.imbueOH = ImbueTile:Create(self.frame, "offhand")
        self.imbueOH:Hide()
    end

    -- Create Shield tile
    if ShieldTile then
        self.shieldTile = ShieldTile:Create(self.frame)
        self.shieldTile:Hide()
    end
end

--- Update visibility of extra tiles based on settings
function TotemBar:UpdateExtrasVisibility()
    if not self.frame then return end

    local db = TotemBuddy.db.profile

    -- Call tiles
    if self.callTiles then
        local showCall = db.showCallOfTotems and TotemBuddy.HasAnyCallSpells
        for _, tile in ipairs(self.callTiles) do
            if showCall then
                -- Will be shown/hidden in RefreshAllExtras based on known spells
            else
                tile:Hide()
            end
        end
        if showCall then
            self:RefreshCallTiles()
        end
    end

    -- Imbue tiles
    if db.showWeaponImbues and TotemBuddy.HasAnyImbueSpells then
        if self.imbueMH then
            self.imbueMH:Show()
        end
        if self.imbueOH then
            -- Only show if offhand WEAPON equipped (not shield or held item)
            local showOH = false
            local ohItemId = GetInventoryItemID("player", 17)
            if ohItemId then
                local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(ohItemId)
                if equipLoc == nil then
                    -- Item info not cached yet; schedule retry and show optimistically
                    C_Timer.After(0.5, function()
                        if self and self.UpdateExtrasVisibility and not InCombatLockdown() then
                            self:UpdateExtrasVisibility()
                            self:UpdateLayout()
                        end
                    end)
                    showOH = true
                elseif equipLoc ~= "INVTYPE_SHIELD" and equipLoc ~= "INVTYPE_HOLDABLE" then
                    -- Only show for actual weapons, not shields or held items
                    showOH = true
                end
            end
            if showOH then
                self.imbueOH:Show()
            else
                self.imbueOH:Hide()
            end
        end
        self:RefreshImbueTiles()
    else
        if self.imbueMH then self.imbueMH:Hide() end
        if self.imbueOH then self.imbueOH:Hide() end
    end

    -- Shield tile
    if db.showShields and TotemBuddy.HasAnyShieldSpells then
        if self.shieldTile then
            self.shieldTile:Show()
        end
        self:RefreshShieldTile()
    else
        if self.shieldTile then self.shieldTile:Hide() end
    end
end

--- Refresh all extra tiles
function TotemBar:RefreshAllExtras()
    self:RefreshCallTiles()
    self:RefreshImbueTiles()
    self:RefreshShieldTile()
end

--- Refresh Call tiles with known spells
function TotemBar:RefreshCallTiles()
    if not ExtrasScanner then
        ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
    end
    if not ExtrasScanner or not self.callTiles then return end

    local db = TotemBuddy.db.profile
    if not db.showCallOfTotems then return end

    local knownCalls = ExtrasScanner:GetKnownCallSpells()
    local callIndex = 0

    for _, callInfo in ipairs(knownCalls) do
        callIndex = callIndex + 1
        if callIndex <= #self.callTiles then
            local tile = self.callTiles[callIndex]
            tile:SetSpell(callInfo.spellId, callInfo.data)
            tile:Show()
        end
    end

    -- Hide unused call tiles
    for i = callIndex + 1, #self.callTiles do
        self.callTiles[i]:Hide()
    end
end

--- Refresh Imbue tiles with default spells
function TotemBar:RefreshImbueTiles()
    if not ExtrasScanner then
        ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
    end
    if not ExtrasScanner then return end

    local db = TotemBuddy.db.profile
    if not db.showWeaponImbues then return end

    -- Get default or first known imbue
    local mhSpellId = db.defaultMainhandImbue
    local ohSpellId = db.defaultOffhandImbue

    -- If no default set, use first known
    if not mhSpellId then
        mhSpellId = ExtrasScanner:GetFirstKnownImbue()
    end
    if not ohSpellId then
        ohSpellId = ExtrasScanner:GetFirstKnownImbue()
    end

    -- Get imbue data
    local ShamanExtrasDB = _G.TotemBuddyShamanExtras
    local mhData = mhSpellId and ShamanExtrasDB and ShamanExtrasDB:GetImbue(mhSpellId)
    local ohData = ohSpellId and ShamanExtrasDB and ShamanExtrasDB:GetImbue(ohSpellId)

    -- Update mainhand tile
    if self.imbueMH then
        self.imbueMH:SetImbue(mhSpellId, mhData)
    end

    -- Update offhand tile
    if self.imbueOH then
        self.imbueOH:SetImbue(ohSpellId, ohData)
    end
end

--- Refresh Shield tile with default spell
function TotemBar:RefreshShieldTile()
    if not ExtrasScanner then
        ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
    end
    if not ExtrasScanner or not self.shieldTile then return end

    local db = TotemBuddy.db.profile
    if not db.showShields then return end

    -- Get default or first known shield
    local shieldSpellId = db.defaultShield
    if not shieldSpellId then
        shieldSpellId = ExtrasScanner:GetFirstKnownShield()
    end

    -- Get shield data
    local ShamanExtrasDB = _G.TotemBuddyShamanExtras
    local shieldData = shieldSpellId and ShamanExtrasDB and ShamanExtrasDB:GetShield(shieldSpellId)

    self.shieldTile:SetShield(shieldSpellId, shieldData)
end

--- Process pending extra tile updates (called after combat)
function TotemBar:ProcessPendingExtras()
    local db = TotemBuddy.db.profile

    -- Process pending Call tile attributes
    if self.callTiles then
        for _, tile in ipairs(self.callTiles) do
            if tile.ApplyPendingAttributes then
                tile:ApplyPendingAttributes()
            end
        end
    end

    -- Process pending Imbue tile attributes AND selector data
    if self.imbueMH then
        if self.imbueMH.ApplyPendingAttributes then
            self.imbueMH:ApplyPendingAttributes()
        end
        -- Handle pending imbue selection from selector (during combat)
        if self.imbueMH.pendingImbueData and self.imbueMH.pendingSpellId then
            db.defaultMainhandImbue = self.imbueMH.pendingSpellId
            self.imbueMH:SetImbue(self.imbueMH.pendingSpellId, self.imbueMH.pendingImbueData)
            self.imbueMH.pendingImbueData = nil
            self.imbueMH.pendingSpellId = nil
        end
    end
    if self.imbueOH then
        if self.imbueOH.ApplyPendingAttributes then
            self.imbueOH:ApplyPendingAttributes()
        end
        -- Handle pending imbue selection from selector (during combat)
        if self.imbueOH.pendingImbueData and self.imbueOH.pendingSpellId then
            db.defaultOffhandImbue = self.imbueOH.pendingSpellId
            self.imbueOH:SetImbue(self.imbueOH.pendingSpellId, self.imbueOH.pendingImbueData)
            self.imbueOH.pendingImbueData = nil
            self.imbueOH.pendingSpellId = nil
        end
    end

    -- Process pending Shield tile attributes AND selector data
    if self.shieldTile then
        if self.shieldTile.ApplyPendingAttributes then
            self.shieldTile:ApplyPendingAttributes()
        end
        -- Handle pending shield selection from selector (during combat)
        if self.shieldTile.pendingShieldData and self.shieldTile.pendingSpellId then
            db.defaultShield = self.shieldTile.pendingSpellId
            self.shieldTile:SetShield(self.shieldTile.pendingSpellId, self.shieldTile.pendingShieldData)
            self.shieldTile.pendingShieldData = nil
            self.shieldTile.pendingSpellId = nil
        end
    end

    -- Handle pending visibility update
    if self.pendingExtrasUpdate then
        self.pendingExtrasUpdate = false
        self:UpdateExtrasVisibility()
        self:UpdateLayout()
    end
end

--- Update extra tile timers (called from OnUpdate)
function TotemBar:UpdateExtraTimers()
    -- Update Imbue status
    if self.imbueMH and self.imbueMH:IsShown() and self.imbueMH.UpdateStatus then
        self.imbueMH:UpdateStatus()
    end
    if self.imbueOH and self.imbueOH:IsShown() and self.imbueOH.UpdateStatus then
        self.imbueOH:UpdateStatus()
    end

    -- Update Shield status
    if self.shieldTile and self.shieldTile:IsShown() and self.shieldTile.UpdateStatus then
        self.shieldTile:UpdateStatus()
    end

    -- Update Call cooldowns
    if self.callTiles then
        for _, tile in ipairs(self.callTiles) do
            if tile:IsShown() and tile.UpdateCooldown then
                tile:UpdateCooldown()
            end
        end
    end
end

--- Get the total number of visible extra tiles
---@return number count
function TotemBar:GetVisibleExtraTileCount()
    local count = 0

    -- Count visible call tiles
    if self.callTiles then
        for _, tile in ipairs(self.callTiles) do
            if tile:IsShown() then
                count = count + 1
            end
        end
    end

    -- Count imbue tiles
    if self.imbueMH and self.imbueMH:IsShown() then
        count = count + 1
    end
    if self.imbueOH and self.imbueOH:IsShown() then
        count = count + 1
    end

    -- Count shield tile
    if self.shieldTile and self.shieldTile:IsShown() then
        count = count + 1
    end

    return count
end

--- Collect all visible extra tiles in order
---@return table extraTiles Array of visible extra tile references
function TotemBar:GetVisibleExtraTiles()
    local tiles = {}

    -- Add visible call tiles
    if self.callTiles then
        for _, tile in ipairs(self.callTiles) do
            if tile:IsShown() then
                table.insert(tiles, tile)
            end
        end
    end

    -- Add imbue tiles
    if self.imbueMH and self.imbueMH:IsShown() then
        table.insert(tiles, self.imbueMH)
    end
    if self.imbueOH and self.imbueOH:IsShown() then
        table.insert(tiles, self.imbueOH)
    end

    -- Add shield tile
    if self.shieldTile and self.shieldTile:IsShown() then
        table.insert(tiles, self.shieldTile)
    end

    return tiles
end

return TotemBar
