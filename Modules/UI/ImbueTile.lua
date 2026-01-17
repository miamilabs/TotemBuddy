--[[
    TotemBuddy - Imbue Tile Module
    Button for Weapon Imbues (Rockbiter, Flametongue, Windfury, etc.)
    Uses SecureActionButtonTemplate with macro for slot-specific application
]]

---@class ImbueTile
local ImbueTile = TotemBuddyLoader:CreateModule("ImbueTile")
local _ImbueTile = ImbueTile.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ImbueSelector = nil
local ExtrasScanner = nil

-- Slot constants
local SLOT_MAINHAND = "mainhand"
local SLOT_OFFHAND = "offhand"
local EQUIP_SLOT_MH = 16  -- MainHandSlot
local EQUIP_SLOT_OH = 17  -- SecondaryHandSlot

-- =============================================================================
-- CREATION
-- =============================================================================

--- Create an Imbue tile button
---@param parent Frame The parent frame
---@param slot string "mainhand" or "offhand"
---@return Button tile The created tile button
function ImbueTile:Create(parent, slot)
    local slotName = slot == SLOT_OFFHAND and "Offhand" or "Mainhand"

    -- Use SecureActionButtonTemplate for combat-safe casting
    local tile = CreateFrame("Button", "TotemBuddyImbue" .. slotName, parent, "SecureActionButtonTemplate")

    -- Register for mouse clicks
    tile:RegisterForClicks("AnyUp", "AnyDown")

    -- Disable secure action on right-click (used for selector)
    tile:SetAttribute("type2", "")

    tile.slot = slot
    tile.equipSlot = slot == SLOT_OFFHAND and EQUIP_SLOT_OH or EQUIP_SLOT_MH
    tile.tileType = "imbue"
    tile:SetSize(TotemBuddy.db.profile.tileSize, TotemBuddy.db.profile.tileSize)

    -- Icon texture
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetAllPoints()
    tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Cooldown frame (for GCD, not really used for imbues)
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
    tile.activeGlow:SetVertexColor(0.3, 0.7, 1.0, 0.6)  -- Blue tint for imbues
    tile.activeGlow:Hide()

    -- Duration text
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.durationText:SetPoint("BOTTOM", 0, 8)
    tile.durationText:SetTextColor(0.3, 0.7, 1.0, 1)  -- Blue
    tile.durationText:SetShadowOffset(1, -1)
    tile.durationText:Hide()

    -- Duration progress bar
    local barHeight = TotemBuddy.db.profile.durationBarHeight or 4
    tile.durationBar = tile:CreateTexture(nil, "OVERLAY", nil, 1)
    tile.durationBar:SetColorTexture(0.3, 0.7, 1.0, 0.8)  -- Blue
    tile.durationBar:SetPoint("BOTTOMLEFT", 2, 2)
    tile.durationBar:SetHeight(barHeight)
    tile.durationBar:SetWidth(tileSize - 4)
    tile.durationBar:Hide()

    -- Duration bar background
    tile.durationBarBG = tile:CreateTexture(nil, "OVERLAY", nil, 0)
    tile.durationBarBG:SetColorTexture(0, 0, 0, 0.5)
    tile.durationBarBG:SetPoint("BOTTOMLEFT", 2, 2)
    tile.durationBarBG:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.durationBarBG:SetHeight(barHeight)
    tile.durationBarBG:Hide()

    -- Slot indicator (MH or OH text)
    tile.slotText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    tile.slotText:SetPoint("TOPLEFT", 2, -2)
    tile.slotText:SetText(slot == SLOT_OFFHAND and "OH" or "MH")

    -- Type indicator bar (bottom)
    tile.typeIndicator = tile:CreateTexture(nil, "OVERLAY")
    tile.typeIndicator:SetColorTexture(0.3, 0.5, 0.8, 0.8)  -- Blue for Imbue
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
        _ImbueTile.OnEnter(self)
    end)
    tile:SetScript("OnLeave", function(self)
        _ImbueTile.OnLeave(self)
    end)

    -- Right-click handler for selector
    tile:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            _ImbueTile.OnRightClick(self)
        end
    end)

    -- Store reference to module methods
    tile.SetImbue = function(self, spellId, imbueData)
        _ImbueTile.SetImbue(self, spellId, imbueData)
    end
    tile.UpdateStatus = function(self)
        _ImbueTile.UpdateStatus(self)
    end
    tile.UpdateSize = function(self, size)
        _ImbueTile.UpdateSize(self, size)
    end
    tile.ApplyPendingAttributes = function(self)
        _ImbueTile.ApplyPendingAttributes(self)
    end
    tile.HasWeaponEquipped = function(self)
        return _ImbueTile.HasWeaponEquipped(self)
    end

    return tile
end

-- =============================================================================
-- MACRO BUILDING
-- =============================================================================

--- Build macro text for applying imbue to specific slot
---@param imbueName string The imbue spell name
---@param slot string "mainhand" or "offhand"
---@return string macrotext
local function BuildImbueMacro(imbueName, slot)
    local equipSlot = slot == SLOT_OFFHAND and 17 or 16

    -- Macro: cast imbue, then use on weapon slot
    -- Format: #showtooltip\n/cast ImbueName\n/use SlotNumber
    return string.format("#showtooltip %s\n/cast %s\n/use %d", imbueName, imbueName, equipSlot)
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

--- Set the imbue for this tile
---@param tile Button The tile button
---@param spellId number|nil The spell ID
---@param imbueData table|nil The imbue data
function _ImbueTile.SetImbue(tile, spellId, imbueData)
    tile.imbueData = imbueData
    tile.spellId = spellId

    if not spellId then
        tile.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        ApplyAttributesSafely(tile, nil, nil)
        return
    end

    -- Get spell info
    local name, _, icon = GetSpellInfo(spellId)
    tile.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Build macro for slot-specific application
    if name then
        local macrotext = BuildImbueMacro(name, tile.slot)
        ApplyAttributesSafely(tile, spellId, macrotext)
    else
        ApplyAttributesSafely(tile, spellId, nil)
    end

    -- Update status display
    _ImbueTile.UpdateStatus(tile)
end

--- Apply pending attribute changes (called after leaving combat)
---@param tile Button The tile button
function _ImbueTile.ApplyPendingAttributes(tile)
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

--- Check if weapon is equipped in this slot (not shield or held item)
---@param tile Button The tile button
---@return boolean hasWeapon
function _ImbueTile.HasWeaponEquipped(tile)
    local itemId = GetInventoryItemID("player", tile.equipSlot)
    if not itemId then return false end

    -- For offhand, check if it's actually a weapon (not shield or held item)
    if tile.slot == SLOT_OFFHAND then
        local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
        if not equipLoc then return false end
        -- Shields and held items (books, orbs) cannot be imbued
        if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then
            return false
        end
    end

    return true
end

--- Update the enchant status display
---@param tile Button The tile button
function _ImbueTile.UpdateStatus(tile)
    if not TotemBuddy.db.profile.showImbueStatus then
        tile.activeGlow:Hide()
        tile.durationText:Hide()
        tile.durationBar:Hide()
        tile.durationBarBG:Hide()
        tile.icon:SetDesaturated(false)
        return
    end

    -- Check weapon enchant status
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges,
          hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()

    local hasEnchant, expiration
    if tile.slot == SLOT_OFFHAND then
        hasEnchant = hasOffHandEnchant
        expiration = offHandExpiration
    else
        hasEnchant = hasMainHandEnchant
        expiration = mainHandExpiration
    end

    if hasEnchant and expiration then
        -- Enchant is active
        -- expiration is in milliseconds from now
        local remainingSeconds = expiration / 1000

        -- Show active glow
        if TotemBuddy.db.profile.showActiveGlow then
            tile.activeGlow:Show()
        end

        -- Show duration text
        if TotemBuddy.db.profile.showDurationText and remainingSeconds > 0 then
            tile.durationText:SetText(FormatTime(remainingSeconds))
            tile.durationText:Show()
        else
            tile.durationText:Hide()
        end

        -- Show duration bar
        -- Note: We don't know the total duration, so we estimate based on typical 30min imbue
        local totalDuration = 30 * 60  -- 30 minutes
        if TotemBuddy.db.profile.showDurationBar and remainingSeconds > 0 then
            local progress = math.min(remainingSeconds / totalDuration, 1.0)
            local tileWidth = tile:GetWidth() - 4
            local barWidth = tileWidth * progress
            if barWidth < 1 then barWidth = 1 end

            tile.durationBar:SetWidth(barWidth)
            tile.durationBar:Show()
            tile.durationBarBG:Show()
        else
            tile.durationBar:Hide()
            tile.durationBarBG:Hide()
        end

        -- Normal icon
        tile.icon:SetDesaturated(false)
    else
        -- No enchant active
        tile.activeGlow:Hide()
        tile.durationText:Hide()
        tile.durationBar:Hide()
        tile.durationBarBG:Hide()

        -- Desaturate to indicate no imbue
        tile.icon:SetDesaturated(true)
    end
end

--- Update the tile size
---@param tile Button The tile button
---@param size number The new size
function _ImbueTile.UpdateSize(tile, size)
    tile:SetSize(size, size)
    tile.border:SetSize(size * 1.4, size * 1.4)
    if tile.activeGlow then
        tile.activeGlow:SetSize(size * 1.4, size * 1.4)
    end

    -- Update duration bar height
    local barHeight = TotemBuddy.db.profile.durationBarHeight or 4
    if tile.durationBar then
        tile.durationBar:SetHeight(barHeight)
    end
    if tile.durationBarBG then
        tile.durationBarBG:SetHeight(barHeight)
    end
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

--- Handle mouse enter
---@param tile Button The tile button
function _ImbueTile.OnEnter(tile)
    tile.border:Show()

    -- Show tooltip
    if TotemBuddy.db.profile.showTooltips and tile.spellId then
        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(tile.spellId)

        -- Add slot info
        local slotName = tile.slot == SLOT_OFFHAND and L["Offhand"] or L["Mainhand"]
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L["Applies to: %s"], slotName), 0.7, 0.7, 0.7)

        -- Add status
        local hasMainHandEnchant, mainHandExpiration, _,
              hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()

        local hasEnchant, expiration
        if tile.slot == SLOT_OFFHAND then
            hasEnchant = hasOffHandEnchant
            expiration = offHandExpiration
        else
            hasEnchant = hasMainHandEnchant
            expiration = mainHandExpiration
        end

        if hasEnchant and expiration then
            local remaining = expiration / 1000
            GameTooltip:AddLine(string.format(L["Active: %s remaining"], FormatTime(remaining)), 0, 1, 0)
        else
            GameTooltip:AddLine(L["Not active"], 1, 0.3, 0.3)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Right-click to select imbue"], 0.5, 0.5, 0.5)

        GameTooltip:Show()
    end

    -- Show selector on hover (optional)
    -- Currently disabled - only show on right-click
end

--- Handle mouse leave
---@param tile Button The tile button
function _ImbueTile.OnLeave(tile)
    tile.border:Hide()
    GameTooltip:Hide()

    -- Schedule selector hide if showing
    if not ImbueSelector then
        ImbueSelector = TotemBuddyLoader:ImportModule("ImbueSelector")
    end
    if ImbueSelector and ImbueSelector.ScheduleHide then
        ImbueSelector:ScheduleHide()
    end
end

--- Handle right-click (opens selector)
---@param tile Button The tile button
function _ImbueTile.OnRightClick(tile)
    if InCombatLockdown() then
        TotemBuddy:Print(L["Cannot open selector during combat."])
        return
    end

    if not ImbueSelector then
        ImbueSelector = TotemBuddyLoader:ImportModule("ImbueSelector")
    end

    if ImbueSelector and ImbueSelector.Show then
        ImbueSelector:Show(tile)
    end
end

return ImbueTile
