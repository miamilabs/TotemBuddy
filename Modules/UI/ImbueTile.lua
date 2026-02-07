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

-- Weapon Enchants database (for enchant ID identification)
local WeaponEnchants = _G.TotemBuddyWeaponEnchants

-- Slot constants
local SLOT_MAINHAND = "mainhand"
local SLOT_OFFHAND = "offhand"
local EQUIP_SLOT_MH = 16  -- MainHandSlot
local EQUIP_SLOT_OH = 17  -- SecondaryHandSlot

-- Combat glow state tracking
_ImbueTile.combatGlowShown = {}

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

    -- Combat warning glow (pulsing red/orange when enchant expiring in combat)
    tile.combatGlow = tile:CreateTexture(nil, "OVERLAY", nil, 2)
    tile.combatGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tile.combatGlow:SetBlendMode("ADD")
    tile.combatGlow:SetPoint("CENTER")
    tile.combatGlow:SetSize(tileSize * 1.5, tileSize * 1.5)
    tile.combatGlow:SetVertexColor(1.0, 0.4, 0.1, 0.8)  -- Orange/red warning
    tile.combatGlow:Hide()

    -- Combat glow animation group
    tile.combatGlowAnim = tile.combatGlow:CreateAnimationGroup()
    tile.combatGlowAnim:SetLooping("BOUNCE")
    local fadeOut = tile.combatGlowAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.8)
    fadeOut:SetToAlpha(0.3)
    fadeOut:SetDuration(0.5)
    fadeOut:SetSmoothing("IN_OUT")

    -- Duration progress bar height (needed for text positioning)
    local barHeight = TotemBuddy.db.profile.durationBarHeight or 4

    -- Duration text (positioned above the duration bar)
    tile.durationText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.durationText:SetPoint("BOTTOM", 0, barHeight + 4)  -- Above bar: bar_y(2) + barHeight + gap(2)
    tile.durationText:SetTextColor(0.3, 0.7, 1.0, 1)  -- Blue
    tile.durationText:SetShadowOffset(1, -1)
    tile.durationText:Hide()

    -- Duration progress bar
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
    tile.ShowCombatGlow = function(self)
        _ImbueTile.ShowCombatGlow(self)
    end
    tile.HideCombatGlow = function(self)
        _ImbueTile.HideCombatGlow(self)
    end
    tile.GetActiveEnchantInfo = function(self)
        return _ImbueTile.GetActiveEnchantInfo(self)
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

-- =============================================================================
-- ENCHANT IDENTIFICATION
-- =============================================================================

--- Get detailed information about the active enchant on this slot
---@param tile Button The tile button
---@return boolean hasEnchant, number|nil remaining, number|nil enchantId, number|nil spellId, string|nil imbueType
function _ImbueTile.GetActiveEnchantInfo(tile)
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandId,
          hasOffHandEnchant, offHandExpiration, offHandCharges, offHandId = GetWeaponEnchantInfo()

    -- Debug logging if enabled
    if TotemBuddy.db and TotemBuddy.db.profile and TotemBuddy.db.profile.debugImbues then
        print(string.format("[TotemBuddy] GetWeaponEnchantInfo: MH=%s/%s/%s OH=%s/%s/%s (tile=%s)",
            tostring(hasMainHandEnchant), tostring(mainHandExpiration), tostring(mainHandId),
            tostring(hasOffHandEnchant), tostring(offHandExpiration), tostring(offHandId),
            tostring(tile.slot)))
    end

    local hasEnchant, expiration, enchantId
    if tile.slot == SLOT_OFFHAND then
        hasEnchant = hasOffHandEnchant
        expiration = offHandExpiration
        enchantId = offHandId
    else
        hasEnchant = hasMainHandEnchant
        expiration = mainHandExpiration
        enchantId = mainHandId
    end

    -- hasEnchant is the authoritative indicator - don't require expiration
    if not hasEnchant then
        return false, nil, nil, nil, nil
    end

    -- Normalize expiration to seconds
    -- GetWeaponEnchantInfo() returns milliseconds in TBC/Classic clients.
    -- Imbues last at most 30 min (1800s), so any value above that is in ms.
    local remainingSeconds = nil
    if expiration and expiration > 0 then
        if expiration > 1800 then
            remainingSeconds = expiration / 1000
        else
            remainingSeconds = expiration
        end
    end

    local spellId = nil
    local imbueType = nil

    -- Use WeaponEnchants database to identify the enchant type
    if WeaponEnchants and enchantId then
        spellId = WeaponEnchants:GetSpellIdForEnchant(enchantId)
        imbueType = WeaponEnchants:GetImbueTypeName(enchantId)

        -- Update max duration tracking (only if we have valid duration)
        if remainingSeconds then
            WeaponEnchants:UpdateMaxDuration(enchantId, remainingSeconds)
        end
    end

    return true, remainingSeconds, enchantId, spellId, imbueType
end

-- =============================================================================
-- COMBAT GLOW
-- =============================================================================

--- Show the combat warning glow with pulsing animation
---@param tile Button The tile button
function _ImbueTile.ShowCombatGlow(tile)
    if not tile.combatGlow then return end
    local tileKey = tile.slot or "unknown"

    if not _ImbueTile.combatGlowShown[tileKey] then
        _ImbueTile.combatGlowShown[tileKey] = true
        tile.combatGlow:Show()
        if tile.combatGlowAnim then
            tile.combatGlowAnim:Play()
        end
    end
end

--- Hide the combat warning glow
---@param tile Button The tile button
function _ImbueTile.HideCombatGlow(tile)
    if not tile.combatGlow then return end
    local tileKey = tile.slot or "unknown"

    if _ImbueTile.combatGlowShown[tileKey] then
        _ImbueTile.combatGlowShown[tileKey] = false
        if tile.combatGlowAnim then
            tile.combatGlowAnim:Stop()
        end
        tile.combatGlow:Hide()
    end
end

-- =============================================================================
-- STATUS DISPLAY
-- =============================================================================

--- Update the enchant status display
---@param tile Button The tile button
function _ImbueTile.UpdateStatus(tile)
    -- Hide combat glow if status display is disabled
    if not TotemBuddy.db.profile.showImbueStatus then
        tile.activeGlow:Hide()
        tile.durationText:Hide()
        tile.durationBar:Hide()
        tile.durationBarBG:Hide()
        tile.icon:SetDesaturated(false)
        _ImbueTile.HideCombatGlow(tile)
        return
    end

    -- Get detailed enchant info using enhanced tracking
    local hasEnchant, remainingSeconds, enchantId, identifiedSpellId, imbueType =
        _ImbueTile.GetActiveEnchantInfo(tile)

    -- hasEnchant is authoritative - show active state even if duration unavailable
    if hasEnchant then
        -- Enchant is active

        -- Show active glow (regardless of duration availability)
        if TotemBuddy.db.profile.showActiveGlow then
            tile.activeGlow:Show()
        end

        -- Normal icon (not desaturated)
        tile.icon:SetDesaturated(false)

        -- Store identified enchant info on tile for tooltip enhancement
        tile.activeEnchantId = enchantId
        tile.activeEnchantSpellId = identifiedSpellId
        tile.activeEnchantType = imbueType

        -- Duration-dependent display (only if we have valid remainingSeconds)
        if remainingSeconds and remainingSeconds > 0 then
            -- Show duration text
            if TotemBuddy.db.profile.showDurationText then
                tile.durationText:SetText(FormatTime(remainingSeconds))
                tile.durationText:Show()
            else
                tile.durationText:Hide()
            end

            -- Show duration bar with accurate max duration
            local totalDuration = 30 * 60  -- Default 30 minutes
            if WeaponEnchants and enchantId and WeaponEnchants.GetMaxDuration then
                totalDuration = WeaponEnchants:GetMaxDuration(enchantId)
            end
            -- Guard against zero or nil duration
            if not totalDuration or totalDuration <= 0 then
                totalDuration = 30 * 60
            end

            if TotemBuddy.db.profile.showDurationBar then
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

            -- Combat glow warning: show when in combat and enchant is expiring soon
            local showCombatGlow = TotemBuddy.db.profile.showImbueCombatGlow
            if showCombatGlow == nil then showCombatGlow = true end  -- Default to true

            if showCombatGlow then
                local combatWarningThreshold = TotemBuddy.db.profile.imbueWarningThreshold or 60
                local inCombat = InCombatLockdown() or UnitAffectingCombat("player")

                if inCombat and remainingSeconds < combatWarningThreshold then
                    _ImbueTile.ShowCombatGlow(tile)
                    -- Trigger audio warning via WarningManager
                    local WarningManager = TotemBuddyLoader:ImportModule("WarningManager")
                    if WarningManager then
                        WarningManager:ImbueExpiring(tile.slot, remainingSeconds)
                    end
                else
                    _ImbueTile.HideCombatGlow(tile)
                end
            else
                _ImbueTile.HideCombatGlow(tile)
            end
        else
            -- Enchant active but duration unknown - hide duration-dependent elements
            tile.durationText:Hide()
            tile.durationBar:Hide()
            tile.durationBarBG:Hide()
            _ImbueTile.HideCombatGlow(tile)
        end
    else
        -- No enchant active
        tile.activeGlow:Hide()
        tile.durationText:Hide()
        tile.durationBar:Hide()
        tile.durationBarBG:Hide()
        _ImbueTile.HideCombatGlow(tile)

        -- Desaturate to indicate no imbue
        tile.icon:SetDesaturated(true)

        -- Clear stored enchant info
        tile.activeEnchantId = nil
        tile.activeEnchantSpellId = nil
        tile.activeEnchantType = nil
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
    if tile.combatGlow then
        tile.combatGlow:SetSize(size * 1.5, size * 1.5)
    end

    -- Update duration bar height and text position
    local barHeight = TotemBuddy.db.profile.durationBarHeight or 4
    if tile.durationBar then
        tile.durationBar:SetHeight(barHeight)
    end
    if tile.durationBarBG then
        tile.durationBarBG:SetHeight(barHeight)
    end
    -- Reposition duration text above the bar
    if tile.durationText then
        tile.durationText:ClearAllPoints()
        tile.durationText:SetPoint("BOTTOM", 0, barHeight + 4)
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

        -- Add status with enhanced enchant identification
        local hasEnchant, remaining, enchantId, identifiedSpellId, imbueType =
            _ImbueTile.GetActiveEnchantInfo(tile)

        if hasEnchant and remaining then
            -- Show active enchant info
            if imbueType then
                -- We identified the enchant type
                GameTooltip:AddLine(string.format(L["Active: %s (%s remaining)"], imbueType, FormatTime(remaining)), 0, 1, 0)
            else
                -- Couldn't identify, show generic
                GameTooltip:AddLine(string.format(L["Active: %s remaining"], FormatTime(remaining)), 0, 1, 0)
            end

            -- Show warning if expiring soon
            local warningThreshold = TotemBuddy.db.profile.imbueWarningThreshold or 60
            if remaining < warningThreshold then
                GameTooltip:AddLine(L["Warning: Enchant expiring soon!"], 1, 0.5, 0)
            end
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

    -- Check if selector is locked and right-click is disabled
    local lockSelector = TotemBuddy.db.profile.lockSelector
    local rightClickEnabled = TotemBuddy.db.profile.selectorRightClickEnabled
    if lockSelector and not rightClickEnabled then
        -- Right-click disabled when locked, only Shift+hover works
        if not IsShiftKeyDown() then
            return
        end
    end

    if not ImbueSelector then
        ImbueSelector = TotemBuddyLoader:ImportModule("ImbueSelector")
    end

    if ImbueSelector and ImbueSelector.Show then
        ImbueSelector:Show(tile)
    end
end

return ImbueTile
