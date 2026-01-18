--[[
    TotemBuddy - Totem Tile Module
    Individual totem button using SecureActionButtonTemplate for combat casting
]]

---@class TotemTile
local TotemTile = TotemBuddyLoader:CreateModule("TotemTile")
local _TotemTile = TotemTile.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

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

    -- Disable secure action on right-click (we use it to open selector)
    tile:SetAttribute("type2", "")

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

    -- Cooldown text (shows remaining cooldown) - positioned at top to avoid overlap with duration text
    tile.cooldownText = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    tile.cooldownText:SetPoint("TOP", 0, -2)
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

    -- Duration progress bar (shows remaining totem duration)
    local barHeight = TotemBuddy.db.profile.durationBarHeight or 4
    tile.durationBar = tile:CreateTexture(nil, "OVERLAY", nil, 1)  -- Sublayer 1 to be above element indicator
    tile.durationBar:SetColorTexture(0, 1, 0, 0.8)  -- Green by default
    tile.durationBar:SetPoint("BOTTOMLEFT", 2, 2)
    tile.durationBar:SetHeight(barHeight)
    tile.durationBar:SetWidth(tileSize - 4)  -- Full width initially
    tile.durationBar:Hide()

    -- Duration bar background (dark backdrop)
    tile.durationBarBG = tile:CreateTexture(nil, "OVERLAY", nil, 0)  -- Sublayer 0 behind the bar
    tile.durationBarBG:SetColorTexture(0, 0, 0, 0.5)
    tile.durationBarBG:SetPoint("BOTTOMLEFT", 2, 2)
    tile.durationBarBG:SetPoint("BOTTOMRIGHT", -2, 2)
    tile.durationBarBG:SetHeight(barHeight)
    tile.durationBarBG:Hide()

    -- Expiring pulse animation group
    tile.pulseAnim = tile:CreateAnimationGroup()
    tile.pulseAnim:SetLooping("BOUNCE")

    local pulse = tile.pulseAnim:CreateAnimation("Alpha")
    pulse:SetFromAlpha(1.0)
    pulse:SetToAlpha(0.5)
    pulse:SetDuration(0.5)
    pulse:SetSmoothing("IN_OUT")

    tile.pulseAnim:SetScript("OnPlay", function()
        tile.isPulsing = true
    end)
    tile.pulseAnim:SetScript("OnStop", function()
        tile.isPulsing = false
        tile:SetAlpha(1.0)
    end)

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

    -- Right-click handler to open selector
    tile:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            _TotemTile.OnRightClick(self)
        end
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

--- Check if any modifier overrides are configured for an element
---@param elementIndex number The element index (1-4)
---@return boolean hasOverrides Whether any modifiers are configured
local function HasModifierOverrides(elementIndex)
    local overrides = TotemBuddy.db.profile.modifierOverrides
    if not overrides or not overrides[elementIndex] then
        return false
    end

    local o = overrides[elementIndex]
    return o.shift ~= nil or o.ctrl ~= nil or o.alt ~= nil
end

--- Build macro text for a tile with modifier overrides
---@param elementIndex number The element index (1-4)
---@param defaultSpellId number The default spell ID
---@return string|nil macrotext The macro text or nil if building failed
local function BuildMacroText(elementIndex, defaultSpellId)
    local overrides = TotemBuddy.db.profile.modifierOverrides
    if not overrides or not overrides[elementIndex] then
        return nil
    end

    local o = overrides[elementIndex]

    -- Get default spell name
    local defaultName = defaultSpellId and GetSpellInfo(defaultSpellId)
    if not defaultName then
        return nil
    end

    -- Build conditional macro
    -- Format: #showtooltip\n/cast [mod:alt] AltSpell; [mod:ctrl] CtrlSpell; [mod:shift] ShiftSpell; DefaultSpell
    local parts = {}

    -- Add modifier conditions in order: alt, ctrl, shift
    -- Order matters: first matching condition wins
    if o.alt then
        local altName = GetSpellInfo(o.alt)
        if altName then
            table.insert(parts, "[mod:alt] " .. altName)
        end
    end

    if o.ctrl then
        local ctrlName = GetSpellInfo(o.ctrl)
        if ctrlName then
            table.insert(parts, "[mod:ctrl] " .. ctrlName)
        end
    end

    if o.shift then
        local shiftName = GetSpellInfo(o.shift)
        if shiftName then
            table.insert(parts, "[mod:shift] " .. shiftName)
        end
    end

    -- Add default (no condition)
    table.insert(parts, defaultName)

    -- Build final macro
    local castLine = "/cast " .. table.concat(parts, "; ")
    return "#showtooltip\n" .. castLine
end

--- Safely apply secure attributes (queues if in combat)
--- NOTE: WoW secure templates require spell NAME (string), not spell ID
--- Uses macro mode when modifier overrides are configured
---@param tile Button The tile button
---@param spellId number|nil The spell ID to set
local function ApplyAttributesSafely(tile, spellId)
    if InCombatLockdown() then
        -- Queue for later - will be applied when leaving combat
        tile.pendingSpellId = spellId
        return false
    end

    if spellId then
        -- Check if we need macro mode (modifier overrides configured)
        local elementIndex = tile.elementIndex
        if elementIndex and HasModifierOverrides(elementIndex) then
            -- Use macro mode for modifier support
            local macrotext = BuildMacroText(elementIndex, spellId)
            if macrotext then
                tile:SetAttribute("type", "macro")
                tile:SetAttribute("macrotext", macrotext)
                -- Clear spell attribute to avoid conflicts
                tile:SetAttribute("spell", nil)
            else
                -- Fallback to simple spell mode
                local spellName = GetSpellInfo(spellId)
                if spellName then
                    tile:SetAttribute("type", "spell")
                    tile:SetAttribute("spell", spellName)
                    tile:SetAttribute("macrotext", nil)
                end
            end
        else
            -- Simple spell mode (no modifiers)
            local spellName = GetSpellInfo(spellId)
            if spellName then
                tile:SetAttribute("type", "spell")
                tile:SetAttribute("spell", spellName)
                tile:SetAttribute("macrotext", nil)
            else
                -- Fallback: clear attributes if spell name can't be resolved
                tile:SetAttribute("type", nil)
                tile:SetAttribute("spell", nil)
                tile:SetAttribute("macrotext", nil)
            end
        end
    else
        tile:SetAttribute("type", nil)
        tile:SetAttribute("spell", nil)
        tile:SetAttribute("macrotext", nil)
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
    -- Handle pending totem selection from selector (includes updating default)
    if tile.pendingTotemData and tile.pendingSpellId then
        local totemData = tile.pendingTotemData
        local spellId = tile.pendingSpellId
        local element = tile.elementIndex

        -- Save as default for this element
        if element then
            TotemBuddy.db.profile.defaultTotems[element] = totemData.name
        end

        -- Update the tile
        _TotemTile.SetTotem(tile, spellId, totemData)

        -- Clear pending data
        tile.pendingTotemData = nil
        tile.pendingSpellId = nil

        -- Show confirmation
        local spellName = GetSpellInfo(spellId) or totemData.name
        TotemBuddy:Print(string.format(L["%s is now your default."], spellName))
        return
    end

    -- Handle simple pending spell ID (from set changes, etc.)
    if tile.pendingSpellId then
        ApplyAttributesSafely(tile, tile.pendingSpellId)
    end
end

--- Rebuild the macro/attributes for a tile (called when modifier settings change)
---@param tile Button The tile button
function TotemTile:RebuildMacro(tile)
    if not tile or not tile.spellId then
        return
    end

    if InCombatLockdown() then
        -- Queue for when leaving combat
        tile.pendingSpellId = tile.spellId
        return
    end

    -- Re-apply attributes with current spell ID
    -- This will use macro mode if modifiers are configured
    ApplyAttributesSafely(tile, tile.spellId)
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

--- Handle right-click (opens selector)
---@param tile Button The tile button
function _TotemTile.OnRightClick(tile)
    -- Check if selector is locked and right-click is disabled
    local selectorLocked = TotemBuddy.db.profile.lockSelector
    local rightClickEnabled = TotemBuddy.db.profile.selectorRightClickEnabled
    if selectorLocked and not rightClickEnabled then
        -- Right-click disabled when locked, only Shift+hover works
        if not IsShiftKeyDown() then
            return
        end
    end

    -- Check combat setting
    local inCombat = InCombatLockdown()
    local showInCombat = TotemBuddy.db.profile.showSelectorInCombat

    if not inCombat or showInCombat then
        if not TotemSelector then
            TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")
        end
        if TotemSelector and TotemSelector.Show then
            TotemSelector:Show(tile)
        end
    elseif inCombat then
        TotemBuddy:Print(L["Cannot open selector during combat."])
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

    -- Update duration bar height
    local barHeight = TotemBuddy.db.profile.durationBarHeight or 4
    if tile.durationBar then
        tile.durationBar:SetHeight(barHeight)
        -- Width is updated dynamically in UpdateActiveState
    end
    if tile.durationBarBG then
        tile.durationBarBG:SetHeight(barHeight)
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
    local db = TotemBuddy.db.profile

    if haveTotem and duration and duration > 0 then
        local remaining = (startTime + duration) - GetTime()
        if remaining > 0 then
            -- Calculate progress ratio (1.0 = full, 0.0 = expired)
            local progress = remaining / duration

            -- Check if expiring soon
            local threshold = db.expiringThreshold or 10
            local isExpiring = remaining <= threshold

            -- Determine color: green for normal, yellow/orange for expiring
            local textR, textG, textB = 0, 1, 0  -- Green default
            local barR, barG, barB = 0, 1, 0
            if isExpiring then
                local expiringColor = db.expiringColor or {1, 0.8, 0}
                textR, textG, textB = expiringColor[1], expiringColor[2], expiringColor[3]
                barR, barG, barB = expiringColor[1], expiringColor[2], expiringColor[3]
            end

            -- Show active indicator (glow)
            if tile.activeGlow and db.showActiveGlow then
                tile.activeGlow:Show()
            end

            -- Show duration text with color
            if tile.durationText and db.showDurationText then
                tile.durationText:SetText(FormatTime(remaining))
                tile.durationText:SetTextColor(textR, textG, textB, 1)
                tile.durationText:Show()
            end

            -- Show duration bar
            if tile.durationBar and db.showDurationBar then
                local tileWidth = tile:GetWidth() - 4  -- Account for margins
                local barWidth = tileWidth * progress
                if barWidth < 1 then barWidth = 1 end

                tile.durationBar:SetWidth(barWidth)
                tile.durationBar:SetColorTexture(barR, barG, barB, 0.8)
                tile.durationBar:Show()

                if tile.durationBarBG then
                    tile.durationBarBG:Show()
                end
            end

            -- Handle pulse animation
            if tile.pulseAnim then
                if isExpiring then
                    if not tile.isPulsing then
                        tile.pulseAnim:Play()
                    end
                else
                    if tile.isPulsing then
                        tile.pulseAnim:Stop()
                    end
                end
            end

            return
        end
    end

    -- No active totem - hide all indicators
    if tile.activeGlow then
        tile.activeGlow:Hide()
    end
    if tile.durationText then
        tile.durationText:Hide()
    end
    if tile.durationBar then
        tile.durationBar:Hide()
    end
    if tile.durationBarBG then
        tile.durationBarBG:Hide()
    end
    if tile.pulseAnim and tile.isPulsing then
        tile.pulseAnim:Stop()
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
