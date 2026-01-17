--[[
    TotemBuddy - Shield Tile Module
    Button for Lightning Shield, Water Shield, and Earth Shield
    Uses SecureActionButtonTemplate for combat-safe casting
]]

---@class ShieldTile
local ShieldTile = TotemBuddyLoader:CreateModule("ShieldTile")
local _ShieldTile = ShieldTile.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ShieldSelector = nil
local ExtrasScanner = nil

-- Database reference
local ShamanExtrasDB = nil

local function GetDB()
    if not ShamanExtrasDB then
        ShamanExtrasDB = _G.TotemBuddyShamanExtras
    end
    return ShamanExtrasDB
end

-- =============================================================================
-- CREATION
-- =============================================================================

--- Create a Shield tile button
---@param parent Frame The parent frame
---@return Button tile The created tile button
function ShieldTile:Create(parent)
    -- Use SecureActionButtonTemplate for combat-safe casting
    local tile = CreateFrame("Button", "TotemBuddyShieldTile", parent, "SecureActionButtonTemplate")

    -- Register for mouse clicks
    tile:RegisterForClicks("AnyUp", "AnyDown")

    -- Disable secure action on right-click (used for selector)
    tile:SetAttribute("type2", "")

    tile.tileType = "shield"
    tile:SetSize(TotemBuddy.db.profile.tileSize, TotemBuddy.db.profile.tileSize)

    -- Icon texture
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Cooldown frame (for GCD)
    tile.cooldown = CreateFrame("Cooldown", nil, tile, "CooldownFrameTemplate")
    tile.cooldown:SetAllPoints()
    tile.cooldown:SetDrawEdge(true)
    tile.cooldown:SetHideCountdownNumbers(true)

    -- Active glow indicator
    local tileSize = TotemBuddy.db.profile.tileSize or 40
    tile.activeGlow = tile:CreateTexture(nil, "OVERLAY")
    tile.activeGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.activeGlow:SetBlendMode("ADD")
    tile.activeGlow:SetPoint("CENTER")
    tile.activeGlow:SetSize(tileSize * 1.4, tileSize * 1.4)
    tile.activeGlow:SetVertexColor(1.0, 1.0, 0.3, 0.6)  -- Yellow for shields
    tile.activeGlow:Hide()

    -- Charges text (for Lightning/Water Shield)
    tile.chargesText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.chargesText:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.chargesText:SetTextColor(1, 1, 0, 1)  -- Yellow
    tile.chargesText:SetShadowOffset(1, -1)
    tile.chargesText:Hide()

    -- Duration text
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.durationText:SetPoint("BOTTOM", 0, 8)
    tile.durationText:SetTextColor(1, 1, 0.3, 1)  -- Yellow
    tile.durationText:SetShadowOffset(1, -1)
    tile.durationText:Hide()

    -- Type indicator bar (bottom)
    tile.typeIndicator = tile:CreateTexture(nil, "OVERLAY")
    tile.typeIndicator:SetColorTexture(0.8, 0.8, 0.2, 0.8)  -- Yellow for Shield
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
        _ShieldTile.OnEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _ShieldTile.OnLeave(self)
    end)

    -- Right-click handler for selector
    tile:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            _ShieldTile.OnRightClick(self)
        end
    end)

    -- Store reference to module methods
    tile.SetShield = function(self, spellId, shieldData)
        _ShieldTile.SetShield(self, spellId, shieldData)
    end
    tile.UpdateStatus = function(self)
        _ShieldTile.UpdateStatus(self)
    end
    tile.UpdateSize = function(self, size)
        _ShieldTile.UpdateSize(self, size)
    end
    tile.ApplyPendingAttributes = function(self)
        _ShieldTile.ApplyPendingAttributes(self)
    end

    return tile
end

-- =============================================================================
-- MACRO BUILDING
-- =============================================================================

--- Build macro text for shield casting
--- Earth Shield uses key modifier targeting (configurable)
---@param shieldName string The shield spell name
---@param shieldData table The shield data
---@return string macrotext
local function BuildShieldMacro(shieldName, shieldData)
    if not (shieldData and shieldData.isTargeted) then
        -- Self-cast shields (Lightning, Water)
        return string.format("#showtooltip %s\n/cast %s", shieldName, shieldName)
    end

    -- Earth Shield: Key modifier targeting
    local targeting = TotemBuddy.db and TotemBuddy.db.profile.earthShieldTargeting or {
        noModifier = "player", shift = "focus", ctrl = "none", alt = "none"
    }

    local parts = {}

    --- Add a targeting condition to the macro
    ---@param modifier string|nil The modifier key (nil for default/no modifier)
    ---@param target string The target unit ID
    local function addCondition(modifier, target)
        if target and target ~= "none" then
            if modifier then
                table.insert(parts, string.format("[mod:%s,@%s,help,nodead]", modifier, target))
            else
                table.insert(parts, string.format("[@%s,help,nodead]", target))
            end
        end
    end

    -- Build conditions in priority order: alt, ctrl, shift, then default
    -- First matching condition wins in WoW macros
    addCondition("alt", targeting.alt)
    addCondition("ctrl", targeting.ctrl)
    addCondition("shift", targeting.shift)
    addCondition(nil, targeting.noModifier)

    -- Fallback to player if no conditions matched (safety)
    if #parts == 0 then
        table.insert(parts, "[@player]")
    end

    return string.format("#showtooltip %s\n/cast %s %s", shieldName, table.concat(parts, ""), shieldName)
end

-- =============================================================================
-- ATTRIBUTE HANDLING (Combat-safe)
-- =============================================================================

--- Safely apply secure attributes (queues if in combat)
---@param tile Button The tile button
---@param spellId number|nil The spell ID
---@param macrotext string|nil Optional macro text
local function ApplyAttributesSafely(tile, spellId, macrotext)
    if InCombatLockdown() then
        tile.pendingSpellId = spellId
        tile.pendingMacrotext = macrotext
        return false
    end

    if macrotext then
        tile:SetAttribute("type", "macro")
        tile:SetAttribute("macrotext", macrotext)
        tile:SetAttribute("spell", nil)
    elseif spellId then
        local spellName = GetSpellInfo(spellId)
        if spellName then
            tile:SetAttribute("type", "spell")
            tile:SetAttribute("spell", spellName)
            tile:SetAttribute("macrotext", nil)
        else
            tile:SetAttribute("type", nil)
            tile:SetAttribute("spell", nil)
            tile:SetAttribute("macrotext", nil)
        end
    else
        tile:SetAttribute("type", nil)
        tile:SetAttribute("spell", nil)
        tile:SetAttribute("macrotext", nil)
    end

    tile.pendingSpellId = nil
    tile.pendingMacrotext = nil
    return true
end

--- Set the shield for this tile
---@param tile Button The tile button
---@param spellId number|nil The spell ID
---@param shieldData table|nil The shield data
function _ShieldTile.SetShield(tile, spellId, shieldData)
    tile.shieldData = shieldData
    tile.spellId = spellId

    if not spellId then
        tile.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        ApplyAttributesSafely(tile, nil, nil)
        return
    end

    -- Get spell info
    local name, _, icon = GetSpellInfo(spellId)
    tile.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Build macro (especially for Earth Shield mouseover)
    if name then
        local macrotext = BuildShieldMacro(name, shieldData)
        ApplyAttributesSafely(tile, spellId, macrotext)
    else
        ApplyAttributesSafely(tile, spellId, nil)
    end

    -- Update status display
    _ShieldTile.UpdateStatus(tile)
end

--- Apply pending attribute changes (called after leaving combat)
---@param tile Button The tile button
function _ShieldTile.ApplyPendingAttributes(tile)
    if tile.pendingSpellId or tile.pendingMacrotext then
        ApplyAttributesSafely(tile, tile.pendingSpellId, tile.pendingMacrotext)
    end
end

-- =============================================================================
-- STATUS DISPLAY
-- =============================================================================

-- Use consolidated FormatTime from main addon
local FormatTime = function(seconds)
    return TotemBuddy.FormatTime(seconds)
end

--- Check if any known shield is active on player
---@return boolean isActive, string|nil buffName, number|nil charges, number|nil remaining, number|nil spellId
local function GetActiveShieldInfo()
    local db = GetDB()
    if not db then return false end

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        -- Check if this is a known shield spell (spellId may be nil on some Classic clients)
        if spellId and db:IsShieldSpell(spellId) then
            local remaining = expirationTime and expirationTime > 0 and (expirationTime - GetTime()) or nil
            return true, name, count, remaining, spellId
        end
    end

    return false
end

--- Update the shield status display
---@param tile Button The tile button
function _ShieldTile.UpdateStatus(tile)
    if not TotemBuddy.db.profile.showShieldStatus then
        tile.activeGlow:Hide()
        tile.chargesText:Hide()
        tile.durationText:Hide()
        tile.icon:SetDesaturated(false)
        return
    end

    local isActive, buffName, charges, remaining, activeSpellId = GetActiveShieldInfo()

    if isActive then
        -- Shield is active
        if TotemBuddy.db.profile.showActiveGlow then
            tile.activeGlow:Show()
        end

        -- Show charges if available
        if charges and charges > 0 then
            tile.chargesText:SetText(tostring(charges))
            tile.chargesText:Show()
        else
            tile.chargesText:Hide()
        end

        -- Show duration if available
        if remaining and remaining > 0 and TotemBuddy.db.profile.showDurationText then
            tile.durationText:SetText(FormatTime(remaining))
            tile.durationText:Show()
        else
            tile.durationText:Hide()
        end

        -- Normal icon
        tile.icon:SetDesaturated(false)
    else
        -- No shield active
        tile.activeGlow:Hide()
        tile.chargesText:Hide()
        tile.durationText:Hide()

        -- Desaturate to indicate inactive
        tile.icon:SetDesaturated(true)
    end
end

--- Update the tile size
---@param tile Button The tile button
---@param size number The new size
function _ShieldTile.UpdateSize(tile, size)
    tile:SetSize(size, size)
    tile.border:SetSize(size * 1.4, size * 1.4)
    if tile.activeGlow then
        tile.activeGlow:SetSize(size * 1.4, size * 1.4)
    end
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

--- Handle mouse enter
---@param tile Button The tile button
function _ShieldTile.OnEnter(tile)
    tile.border:Show()

    -- Show tooltip
    if TotemBuddy.db.profile.showTooltips and tile.spellId then
        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(tile.spellId)

        -- Add status
        local isActive, buffName, charges, remaining = GetActiveShieldInfo()
        GameTooltip:AddLine(" ")

        if isActive then
            local statusText = L["Active"]
            if charges and charges > 0 then
                statusText = statusText .. string.format(" (%d %s)", charges, L["charges"])
            end
            if remaining and remaining > 0 then
                statusText = statusText .. string.format(" - %s", FormatTime(remaining))
            end
            GameTooltip:AddLine(statusText, 0, 1, 0)
        else
            GameTooltip:AddLine(L["Not active"], 1, 0.3, 0.3)
        end

        -- Add Earth Shield targeting hint
        if tile.shieldData and tile.shieldData.isTargeted then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Click"] .. ": " .. L["Self"], 0.7, 0.7, 0.7)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Right-click to select shield"], 0.5, 0.5, 0.5)

        GameTooltip:Show()
    end
end

--- Handle mouse leave
---@param tile Button The tile button
function _ShieldTile.OnLeave(tile)
    tile.border:Hide()
    GameTooltip:Hide()

    -- Schedule selector hide
    if not ShieldSelector then
        ShieldSelector = TotemBuddyLoader:ImportModule("ShieldSelector")
    end
    if ShieldSelector and ShieldSelector.ScheduleHide then
        ShieldSelector:ScheduleHide()
    end
end

--- Handle right-click (opens selector)
---@param tile Button The tile button
function _ShieldTile.OnRightClick(tile)
    if InCombatLockdown() then
        TotemBuddy:Print(L["Cannot open selector during combat."])
        return
    end

    if not ShieldSelector then
        ShieldSelector = TotemBuddyLoader:ImportModule("ShieldSelector")
    end

    if ShieldSelector and ShieldSelector.Show then
        ShieldSelector:Show(tile)
    end
end

return ShieldTile
