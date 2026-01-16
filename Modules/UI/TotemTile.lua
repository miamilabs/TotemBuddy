--[[
    TotemBuddy - Totem Tile Module
    Individual totem button using SecureActionButtonTemplate for combat casting
]]

---@class TotemTile
local TotemTile = TotemBuddyLoader:CreateModule("TotemTile")
local _TotemTile = TotemTile.private

-- Module references
local TotemSelector = nil
local SpellScanner = nil
local TotemData = nil

--- Create a totem tile button
---@param parent Frame The parent frame
---@param elementIndex number The element index (1-4)
---@return Button tile The created tile button
function TotemTile:Create(parent, elementIndex)
    -- Use SecureActionButtonTemplate for combat-safe casting
    local tile = CreateFrame("Button", "TotemBuddyTile" .. elementIndex, parent, "SecureActionButtonTemplate")

    -- Register for mouse clicks to enable spell casting
    tile:RegisterForClicks("AnyUp", "AnyDown")

    tile.elementIndex = elementIndex
    tile:SetSize(TotemBuddy.db.profile.tileSize, TotemBuddy.db.profile.tileSize)

    -- Icon texture
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- Slight crop for cleaner look

    -- Cooldown frame
    tile.cooldown = CreateFrame("Cooldown", nil, tile, "CooldownFrameTemplate")
    tile.cooldown:SetAllPoints()
    tile.cooldown:SetDrawEdge(true)
    tile.cooldown:SetHideCountdownNumbers(true)  -- We'll show our own

    -- Cooldown text (shows remaining cooldown)
    tile.cooldownText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.cooldownText:SetPoint("CENTER", 0, 0)
    tile.cooldownText:SetTextColor(1, 0.2, 0.2, 1)
    tile.cooldownText:SetShadowOffset(1, -1)
    tile.cooldownText:Hide()

    -- Active duration text (shows remaining totem duration) - positioned above element indicator
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.durationText:SetPoint("BOTTOM", 0, 8)
    tile.durationText:SetTextColor(0, 1, 0, 1)
    tile.durationText:SetShadowOffset(1, -1)
    tile.durationText:Hide()

    -- Active glow indicator
    local tileSize = TotemBuddy.db.profile.tileSize or 40
    tile.activeGlow = tile:CreateTexture(nil, "OVERLAY")
    tile.activeGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.activeGlow:SetBlendMode("ADD")
    tile.activeGlow:SetPoint("CENTER")
    tile.activeGlow:SetSize(tileSize * 1.4, tileSize * 1.4)
    tile.activeGlow:SetVertexColor(0, 1, 0, 0.6)
    tile.activeGlow:Hide()

    -- Border for hover highlight
    tile.border = tile:CreateTexture(nil, "OVERLAY")
    tile.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.border:SetBlendMode("ADD")
    tile.border:SetPoint("CENTER")
    tile.border:SetSize(tile:GetWidth() * 1.3, tile:GetHeight() * 1.3)
    tile.border:SetAlpha(0.8)
    tile.border:Hide()

    -- Keybind text
    tile.keybind = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    tile.keybind:SetPoint("TOPRIGHT", -2, -2)

    -- Element color indicator (bottom bar)
    local r, g, b = unpack(TotemBuddy.ElementColors[elementIndex] or {1, 1, 1})
    tile.elementIndicator = tile:CreateTexture(nil, "OVERLAY")
    tile.elementIndicator:SetColorTexture(r, g, b, 1)
    tile.elementIndicator:SetPoint("BOTTOMLEFT", 2, 2)
    tile.elementIndicator:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.elementIndicator:SetHeight(3)

    -- Custom hover highlight (full size, no inner box)
    tile.highlight = tile:CreateTexture(nil, "HIGHLIGHT")
    tile.highlight:SetAllPoints()
    tile.highlight:SetColorTexture(1, 1, 1, 0.2)
    tile.highlight:SetBlendMode("ADD")

    -- Event handlers
    tile:SetScript("OnEnter", function(self)
        _TotemTile.OnEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _TotemTile.OnLeave(self)
    end)

    -- Store reference to module methods
    tile.SetTotem = function(self, spellId, totemData)
        _TotemTile.SetTotem(self, spellId, totemData)
    end
    tile.UpdateCooldown = function(self)
        _TotemTile.UpdateCooldown(self)
    end
    tile.UpdateSize = function(self, size)
        _TotemTile.UpdateSize(self, size)
    end
    tile.ApplyPendingAttributes = function(self)
        _TotemTile.ApplyPendingAttributes(self)
    end
    tile.UpdateActiveState = function(self)
        _TotemTile.UpdateActiveState(self)
    end

    return tile
end

--- Safely apply secure attributes (queues if in combat)
--- NOTE: WoW secure templates require spell NAME (string), not spell ID
---@param tile Button The tile button
---@param spellId number|nil The spell ID to set
local function ApplyAttributesSafely(tile, spellId)
    if InCombatLockdown() then
        -- Queue for later - will be applied when leaving combat
        tile.pendingSpellId = spellId
        return false
    end

    if spellId then
        -- Convert spell ID to spell name (required for secure casting)
        local spellName = GetSpellInfo(spellId)
        if spellName then
            tile:SetAttribute("type", "spell")
            tile:SetAttribute("spell", spellName)
        else
            -- Fallback: clear attributes if spell name can't be resolved
            tile:SetAttribute("type", nil)
            tile:SetAttribute("spell", nil)
        end
    else
        tile:SetAttribute("type", nil)
        tile:SetAttribute("spell", nil)
    end
    tile.pendingSpellId = nil
    return true
end

--- Set the totem for this tile
---@param tile Button The tile button
---@param spellId number|nil The spell ID to set
---@param totemData table|nil The totem data
function _TotemTile.SetTotem(tile, spellId, totemData)
    tile.totemData = totemData
    tile.spellId = spellId

    if not spellId then
        -- No totem set - show placeholder
        tile.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        ApplyAttributesSafely(tile, nil)
        return
    end

    -- Get spell info (guard against nil)
    local name, _, icon = GetSpellInfo(spellId)
    tile.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Set secure action attributes (queued if in combat)
    ApplyAttributesSafely(tile, spellId)

    -- Update cooldown display
    _TotemTile.UpdateCooldown(tile)
end

--- Apply any pending attribute changes (called after leaving combat)
---@param tile Button The tile button
function _TotemTile.ApplyPendingAttributes(tile)
    if tile.pendingSpellId then
        ApplyAttributesSafely(tile, tile.pendingSpellId)
    end
end

--- Handle mouse enter
---@param tile Button The tile button
function _TotemTile.OnEnter(tile)
    -- Show highlight border
    tile.border:Show()

    -- Show tooltip
    if TotemBuddy.db.profile.showTooltips and tile.spellId then
        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(tile.spellId)
        GameTooltip:Show()
    end

    -- Check if selector is locked (requires Shift+hover to open)
    local selectorLocked = TotemBuddy.db.profile.lockSelector
    if selectorLocked and not IsShiftKeyDown() then
        return  -- Selector locked and shift not held, don't show
    end

    -- Show selector popup (check combat setting)
    local inCombat = InCombatLockdown()
    local showInCombat = TotemBuddy.db.profile.showSelectorInCombat

    if not inCombat or showInCombat then
        if not TotemSelector then
            TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")
        end
        if TotemSelector and TotemSelector.Show then
            TotemSelector:Show(tile)
        end
    end
end

--- Handle mouse leave
---@param tile Button The tile button
function _TotemTile.OnLeave(tile)
    -- Hide highlight border
    tile.border:Hide()

    -- Hide tooltip
    GameTooltip:Hide()

    -- Schedule selector hide (selector will cancel if mouse enters it)
    if not TotemSelector then
        TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")
    end
    if TotemSelector and TotemSelector.ScheduleHide then
        TotemSelector:ScheduleHide()
    end
end

--- Update the tile size
---@param tile Button The tile button
---@param size number The new size
function _TotemTile.UpdateSize(tile, size)
    tile:SetSize(size, size)
    tile.border:SetSize(size * 1.4, size * 1.4)
    if tile.activeGlow then
        tile.activeGlow:SetSize(size * 1.4, size * 1.4)
    end
end

-- Use consolidated FormatTime from main addon
local FormatTime = function(seconds)
    return TotemBuddy.FormatTime(seconds)
end

--- Update the active totem state (duration remaining)
---@param tile Button The tile button
function _TotemTile.UpdateActiveState(tile)
    if not tile.elementIndex then
        return
    end

    -- Check if ANY totem is active in this element slot
    local haveTotem, totemName, startTime, duration = GetTotemInfo(tile.elementIndex)

    if haveTotem and duration and duration > 0 then
        local remaining = (startTime + duration) - GetTime()
        if remaining > 0 then
            -- Show active indicator (glow)
            if tile.activeGlow and TotemBuddy.db.profile.showActiveGlow then
                tile.activeGlow:Show()
            end
            -- Show duration text
            if tile.durationText and TotemBuddy.db.profile.showDurationText then
                tile.durationText:SetText(FormatTime(remaining))
                tile.durationText:Show()
            end
            return
        end
    end

    -- No active totem - hide indicators
    if tile.activeGlow then
        tile.activeGlow:Hide()
    end
    if tile.durationText then
        tile.durationText:Hide()
    end
end

--- Update cooldown display with text
---@param tile Button The tile button
function _TotemTile.UpdateCooldown(tile)
    if not tile.spellId then
        if tile.cooldown then
            tile.cooldown:Clear()
        end
        if tile.cooldownText then
            tile.cooldownText:Hide()
        end
        if tile.icon then
            tile.icon:SetDesaturated(false)
        end
        return
    end

    local start, duration, enabled = GetSpellCooldown(tile.spellId)

    if start and start > 0 and duration > 1.5 then
        -- On cooldown (ignore GCD which is ~1.5s)
        tile.cooldown:SetCooldown(start, duration)

        -- Desaturate icon to show it's on cooldown
        if tile.icon then
            tile.icon:SetDesaturated(true)
        end

        -- Show cooldown text
        if TotemBuddy.db.profile.showCooldownText then
            local remaining = (start + duration) - GetTime()
            if remaining > 0 then
                tile.cooldownText:SetText(FormatTime(remaining))
                tile.cooldownText:Show()
            else
                tile.cooldownText:Hide()
            end
        else
            tile.cooldownText:Hide()
        end
    else
        -- Not on cooldown
        tile.cooldown:Clear()
        tile.cooldownText:Hide()

        -- Restore icon color
        if tile.icon then
            tile.icon:SetDesaturated(false)
        end
    end

    -- Also update active state (duration remaining)
    _TotemTile.UpdateActiveState(tile)
end

return TotemTile
