--[[
    TotemBuddy - Call Tile Module
    Button for Call of the Elements/Ancestors/Spirits spells
    Uses SecureActionButtonTemplate for combat-safe casting
]]

---@class CallTile
local CallTile = TotemBuddyLoader:CreateModule("CallTile")
local _CallTile = CallTile.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ExtrasScanner = nil

-- =============================================================================
-- CREATION
-- =============================================================================

--- Create a Call tile button
---@param parent Frame The parent frame
---@param index number The call tile index (1-3)
---@return Button tile The created tile button
function CallTile:Create(parent, index)
    -- Use SecureActionButtonTemplate for combat-safe casting
    local tile = CreateFrame("Button", "TotemBuddyCallTile" .. index, parent, "SecureActionButtonTemplate")

    -- Register for mouse clicks
    tile:RegisterForClicks("AnyUp", "AnyDown")

    -- Disable secure action on right-click (we use it for selector)
    tile:SetAttribute("type2", "")

    tile.tileIndex = index
    tile.tileType = "call"
    tile:SetSize(TotemBuddy.db.profile.tileSize, TotemBuddy.db.profile.tileSize)

    -- Icon texture
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Cooldown frame
    tile.cooldown = CreateFrame("Cooldown", nil, tile, "CooldownFrameTemplate")
    tile.cooldown:SetAllPoints()
    tile.cooldown:SetDrawEdge(true)
    tile.cooldown:SetHideCountdownNumbers(true)

    -- Cooldown text
    tile.cooldownText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.cooldownText:SetPoint("CENTER", 0, 0)
    tile.cooldownText:SetTextColor(1, 0.2, 0.2, 1)
    tile.cooldownText:SetShadowOffset(1, -1)
    tile.cooldownText:Hide()

    -- Type indicator (small icon badge showing "C" for Call)
    local tileSize = TotemBuddy.db.profile.tileSize or 40
    tile.typeIndicator = tile:CreateTexture(nil, "OVERLAY")
    tile.typeIndicator:SetColorTexture(0.4, 0.2, 0.6, 0.8)  -- Purple for Call
    tile.typeIndicator:SetPoint("BOTTOMLEFT", 2, 2)
    tile.typeIndicator:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.typeIndicator:SetHeight(3)

    -- Border for hover highlight
    tile.border = tile:CreateTexture(nil, "OVERLAY")
    tile.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.border:SetBlendMode("ADD")
    tile.border:SetPoint("CENTER")
    tile.border:SetSize(tileSize * 1.3, tileSize * 1.3)
    tile.border:SetAlpha(0.8)
    tile.border:Hide()

    -- Custom hover highlight
    tile.highlight = tile:CreateTexture(nil, "HIGHLIGHT")
    tile.highlight:SetAllPoints()
    tile.highlight:SetColorTexture(1, 1, 1, 0.2)
    tile.highlight:SetBlendMode("ADD")

    -- Event handlers
    tile:SetScript("OnEnter", function(self)
        _CallTile.OnEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _CallTile.OnLeave(self)
    end)

    -- Right-click handler (currently just shows tooltip, could open selector if multiple calls)
    tile:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            _CallTile.OnRightClick(self)
        end
    end)

    -- Store reference to module methods
    tile.SetSpell = function(self, spellId, callData)
        _CallTile.SetSpell(self, spellId, callData)
    end
    tile.UpdateCooldown = function(self)
        _CallTile.UpdateCooldown(self)
    end
    tile.UpdateSize = function(self, size)
        _CallTile.UpdateSize(self, size)
    end
    tile.ApplyPendingAttributes = function(self)
        _CallTile.ApplyPendingAttributes(self)
    end

    return tile
end

-- =============================================================================
-- ATTRIBUTE HANDLING (Combat-safe)
-- =============================================================================

--- Safely apply secure attributes (queues if in combat)
---@param tile Button The tile button
---@param spellId number|nil The spell ID to set
local function ApplyAttributesSafely(tile, spellId)
    if InCombatLockdown() then
        tile.pendingSpellId = spellId
        return false
    end

    if spellId then
        local spellName = GetSpellInfo(spellId)
        if spellName then
            tile:SetAttribute("type", "spell")
            tile:SetAttribute("spell", spellName)
        else
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

--- Set the spell for this tile
---@param tile Button The tile button
---@param spellId number|nil The spell ID
---@param callData table|nil The call spell data
function _CallTile.SetSpell(tile, spellId, callData)
    tile.callData = callData
    tile.spellId = spellId

    if not spellId then
        tile.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        ApplyAttributesSafely(tile, nil)
        return
    end

    -- Get spell info
    local name, _, icon = GetSpellInfo(spellId)
    tile.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Set secure action attributes
    ApplyAttributesSafely(tile, spellId)

    -- Update cooldown display
    _CallTile.UpdateCooldown(tile)
end

--- Apply pending attribute changes (called after leaving combat)
---@param tile Button The tile button
function _CallTile.ApplyPendingAttributes(tile)
    if tile.pendingSpellId then
        ApplyAttributesSafely(tile, tile.pendingSpellId)
    end
end

-- =============================================================================
-- UI UPDATES
-- =============================================================================

-- Use consolidated FormatTime from main addon
local FormatTime = function(seconds)
    return TotemBuddy.FormatTime(seconds)
end

--- Update the tile size
---@param tile Button The tile button
---@param size number The new size
function _CallTile.UpdateSize(tile, size)
    tile:SetSize(size, size)
    tile.border:SetSize(size * 1.4, size * 1.4)
end

--- Update cooldown display
---@param tile Button The tile button
function _CallTile.UpdateCooldown(tile)
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
        -- On cooldown (ignore GCD)
        tile.cooldown:SetCooldown(start, duration)

        -- Desaturate icon
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

        if tile.icon then
            tile.icon:SetDesaturated(false)
        end
    end
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

--- Handle mouse enter
---@param tile Button The tile button
function _CallTile.OnEnter(tile)
    tile.border:Show()

    -- Show tooltip
    if TotemBuddy.db.profile.showTooltips and tile.spellId then
        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(tile.spellId)

        -- Add description if available
        if tile.callData and tile.callData.description then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(tile.callData.description, 1, 1, 1, true)
        end

        GameTooltip:Show()
    end
end

--- Handle mouse leave
---@param tile Button The tile button
function _CallTile.OnLeave(tile)
    tile.border:Hide()
    GameTooltip:Hide()
end

--- Handle right-click
---@param tile Button The tile button
function _CallTile.OnRightClick(tile)
    -- For now, right-click does nothing special
    -- Could open a selector if multiple call spells are known
    if InCombatLockdown() then
        TotemBuddy:Print(L["Cannot open selector during combat."])
    end
end

return CallTile
