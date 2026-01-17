--[[
    TotemBuddy - Totem Selector Module
    Popup menu for selecting totems when hovering over a tile
]]

---@class TotemSelector
local TotemSelector = TotemBuddyLoader:CreateModule("TotemSelector")
local _TotemSelector = TotemSelector.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local TotemData = nil
local SpellScanner = nil
local TotemBar = nil

-- Selector frame
TotemSelector.frame = nil
TotemSelector.buttons = {}
TotemSelector.parentTile = nil

--- Create the selector frame
function TotemSelector:Create()
    if self.frame then
        return self.frame
    end

    -- Cancel any existing timers from a previous instance (defensive cleanup)
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end
    if self.cooldownTimer then
        self.cooldownTimer:Cancel()
        self.cooldownTimer = nil
    end

    local frame = CreateFrame("Frame", "TotemBuddySelector", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    frame:Hide()

    -- Leave detection with delay
    frame:SetScript("OnLeave", function(self)
        _TotemSelector.ScheduleHide()
    end)

    frame:SetScript("OnEnter", function(self)
        _TotemSelector.CancelHide()
    end)

    self.frame = frame
    return frame
end

--- Get or create a button from the pool
---@param index number The button index
---@return Button button The button
function _TotemSelector.GetButton(index)
    if TotemSelector.buttons[index] then
        return TotemSelector.buttons[index]
    end

    local btn = CreateFrame("Button", "TotemBuddySelectorBtn" .. index, TotemSelector.frame)
    btn:SetSize(36, 36)

    -- Icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Cooldown frame
    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints()
    btn.cooldown:SetDrawEdge(true)
    btn.cooldown:SetHideCountdownNumbers(true)

    -- Cooldown text
    btn.cooldownText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.cooldownText:SetPoint("CENTER", 0, 0)
    btn.cooldownText:SetTextColor(1, 1, 1, 1)
    btn.cooldownText:Hide()

    -- Highlight (full size)
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(1, 1, 1, 0.3)
    btn.highlight:SetBlendMode("ADD")

    -- Border
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.border:SetBlendMode("ADD")
    btn.border:SetPoint("CENTER")
    btn.border:SetSize(44, 44)
    btn.border:SetAlpha(0)

    -- Unavailable overlay (for totems not yet learned)
    btn.unavailable = btn:CreateTexture(nil, "OVERLAY")
    btn.unavailable:SetColorTexture(0, 0, 0, 0.6)
    btn.unavailable:SetAllPoints()
    btn.unavailable:Hide()

    -- Click handler
    btn:SetScript("OnClick", function(self)
        _TotemSelector.OnButtonClick(self)
    end)

    btn:SetScript("OnEnter", function(self)
        _TotemSelector.CancelHide()
        _TotemSelector.OnButtonEnter(self)
    end)

    btn:SetScript("OnLeave", function(self)
        _TotemSelector.ScheduleHide()
        GameTooltip:Hide()
    end)

    TotemSelector.buttons[index] = btn
    return btn
end

-- Use consolidated FormatTime from main addon
local FormatTime = function(seconds)
    return TotemBuddy.FormatTime(seconds)
end

--- Update cooldown display for a button
---@param btn Button The button to update
function _TotemSelector.UpdateButtonCooldown(btn)
    if not btn.spellId or not btn.isKnown then
        if btn.cooldown then
            btn.cooldown:Clear()
        end
        if btn.cooldownText then
            btn.cooldownText:Hide()
        end
        return
    end

    local start, duration, enabled = GetSpellCooldown(btn.spellId)

    if start and start > 0 and duration > 1.5 then
        -- On cooldown (ignore GCD)
        btn.cooldown:SetCooldown(start, duration)
        local remaining = (start + duration) - GetTime()
        if remaining > 0 then
            btn.cooldownText:SetText(FormatTime(remaining))
            btn.cooldownText:Show()
        else
            btn.cooldownText:Hide()
        end
    else
        btn.cooldown:Clear()
        btn.cooldownText:Hide()
    end
end

--- Update all visible button cooldowns
function _TotemSelector.UpdateAllCooldowns()
    for _, btn in ipairs(TotemSelector.buttons) do
        if btn:IsShown() then
            _TotemSelector.UpdateButtonCooldown(btn)
        end
    end
end

--- Show the selector for a tile
---@param tile Button The parent tile
function TotemSelector:Show(tile)
    if not self.frame then
        self:Create()
    end

    -- Get modules
    if not TotemData then
        TotemData = TotemBuddyLoader:ImportModule("TotemData")
    end
    if not SpellScanner then
        SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
    end

    self.parentTile = tile
    local elementIndex = tile.elementIndex

    -- Get totems for this element
    local totems = TotemData:GetTotemsForElement(elementIndex)
    if not totems or #totems == 0 then
        return
    end

    -- Populate buttons
    local buttonIndex = 0
    -- Defensive: ensure columns is at least 1 to prevent division by zero
    local columns = math.max(1, tonumber(TotemBuddy.db.profile.selectorColumns) or 4)
    local buttonSize = 36
    local spacing = 4
    local padding = 8

    for _, totemData in ipairs(totems) do
        local isKnown = SpellScanner:IsTotemKnown(totemData)

        -- Show if known, or if showing unavailable
        if isKnown or TotemBuddy.db.profile.showUnavailable then
            buttonIndex = buttonIndex + 1
            local btn = _TotemSelector.GetButton(buttonIndex)

            btn.totemData = totemData
            btn.isKnown = isKnown

            -- Get spell ID for cooldown tracking
            btn.spellId = TotemBuddy.HighestRanks[totemData.name]

            -- Set icon
            btn.icon:SetTexture(totemData.icon)

            -- Show unavailable overlay if not known
            if isKnown then
                btn.unavailable:Hide()
                btn.icon:SetDesaturated(false)
            else
                btn.unavailable:Show()
                btn.icon:SetDesaturated(true)
            end

            -- Update cooldown display
            _TotemSelector.UpdateButtonCooldown(btn)

            -- Position button
            local row = math.floor((buttonIndex - 1) / columns)
            local col = (buttonIndex - 1) % columns
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
                padding + col * (buttonSize + spacing),
                -padding - row * (buttonSize + spacing))

            btn:Show()
        end
    end

    -- Hide unused buttons (defensive nil check)
    for i = buttonIndex + 1, #self.buttons do
        local b = self.buttons[i]
        if b then
            b:Hide()
        end
    end

    -- Handle case where no buttons to show
    if buttonIndex == 0 then
        self.frame:Hide()
        return
    end

    -- Size the frame
    local numRows = math.ceil(buttonIndex / columns)
    local numCols = math.min(buttonIndex, columns)
    local width = padding * 2 + numCols * buttonSize + (numCols - 1) * spacing
    local height = padding * 2 + numRows * buttonSize + (numRows - 1) * spacing
    self.frame:SetSize(width, height)

    -- Position relative to tile
    self.frame:ClearAllPoints()
    local pos = TotemBuddy.db.profile.selectorPosition or "above"

    if pos == "above" then
        self.frame:SetPoint("BOTTOM", tile, "TOP", 0, 4)
    elseif pos == "below" then
        self.frame:SetPoint("TOP", tile, "BOTTOM", 0, -4)
    elseif pos == "left" then
        self.frame:SetPoint("RIGHT", tile, "LEFT", -4, 0)
    elseif pos == "right" then
        self.frame:SetPoint("LEFT", tile, "RIGHT", 4, 0)
    end

    -- Apply scale
    self.frame:SetScale(TotemBuddy.db.profile.selectorScale or 1.0)

    self.frame:Show()

    -- Start cooldown update timer (0.25s interval for better performance)
    if self.cooldownTimer then
        self.cooldownTimer:Cancel()
    end
    self.cooldownTimer = C_Timer.NewTicker(0.25, function()
        _TotemSelector.UpdateAllCooldowns()
    end)
end

--- Hide the selector
function TotemSelector:Hide()
    -- Stop cooldown update timer
    if self.cooldownTimer then
        self.cooldownTimer:Cancel()
        self.cooldownTimer = nil
    end

    if self.frame then
        self.frame:Hide()
    end
    self.parentTile = nil
end

--- Schedule hiding with delay (public method)
function TotemSelector:ScheduleHide()
    _TotemSelector.ScheduleHide()
end

--- Schedule hiding with delay (internal)
function _TotemSelector.ScheduleHide()
    -- Cancel any existing timer and start a new one
    if TotemSelector.hideTimer then
        TotemSelector.hideTimer:Cancel()
    end

    TotemSelector.hideTimer = C_Timer.NewTimer(0.15, function()
        TotemSelector.hideTimer = nil

        -- Check if mouse is still over selector or parent tile
        local frame = TotemSelector.frame
        local tile = TotemSelector.parentTile

        if frame and frame:IsShown() then
            if frame:IsMouseOver() then
                return
            end
            if tile and tile:IsMouseOver() then
                return
            end
            TotemSelector:Hide()
        end
    end)
end

--- Cancel scheduled hide (public method)
function TotemSelector:CancelHide()
    _TotemSelector.CancelHide()
end

--- Cancel scheduled hide (internal)
function _TotemSelector.CancelHide()
    if TotemSelector.hideTimer then
        TotemSelector.hideTimer:Cancel()
        TotemSelector.hideTimer = nil
    end
end

--- Handle button click
---@param btn Button The clicked button
function _TotemSelector.OnButtonClick(btn)
    if not btn.isKnown then
        -- Can't select unavailable totem
        return
    end

    local totemData = btn.totemData
    local tile = TotemSelector.parentTile

    if not totemData or not tile then
        return
    end

    -- Get the spell ID to use
    local spellId = TotemBuddy.HighestRanks[totemData.name]
    if not spellId then
        return
    end

    local element = tile.elementIndex
    local db = TotemBuddy.db.profile

    -- CRITICAL: Cannot modify secure frame attributes during combat
    if InCombatLockdown() then
        -- In combat: queue the change for when combat ends
        tile.pendingTotemData = totemData
        tile.pendingSpellId = spellId

        -- Visual feedback: flash the selector button to confirm queuing
        if btn.highlight then
            btn.highlight:SetColorTexture(1, 0.8, 0, 0.5)  -- Yellow flash
            C_Timer.After(0.3, function()
                if btn.highlight then
                    btn.highlight:SetColorTexture(1, 1, 1, 0.3)  -- Reset
                end
            end)
        end

        -- Show feedback message
        local spellName = GetSpellInfo(spellId) or totemData.name
        TotemBuddy:Print(string.format(L["%s will be set as default when leaving combat."], spellName))

        -- Hide selector
        TotemSelector:Hide()
        return
    end

    -- Out of combat: save as default for this element
    db.defaultTotems[element] = totemData.name

    -- Update the tile
    tile:SetTotem(spellId, totemData)

    -- Optionally cast the totem immediately after selection
    if db.castOnSelect then
        local spellName = GetSpellInfo(spellId)
        -- Re-check combat state and wrap in pcall for safety
        if spellName and not InCombatLockdown() then
            local ok, err = pcall(CastSpellByName, spellName)
            if not ok then
                TotemBuddy:Print(string.format(L["Failed to cast %s: %s"], spellName, tostring(err)))
            end
        end
    end

    -- Hide selector
    TotemSelector:Hide()
end

--- Handle button enter (for tooltip)
---@param btn Button The hovered button
function _TotemSelector.OnButtonEnter(btn)
    if not btn.totemData then
        return
    end

    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")

    -- Get highest known rank for tooltip
    local spellId = TotemBuddy.HighestRanks[btn.totemData.name]

    if spellId and btn.isKnown then
        -- Show full spell info for known totems
        GameTooltip:SetSpellByID(spellId)

        -- Show cooldown info if on cooldown
        local start, duration, enabled = GetSpellCooldown(spellId)
        if start and start > 0 and duration > 1.5 then
            local remaining = (start + duration) - GetTime()
            if remaining > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format(L["Cooldown: %s"], FormatTime(remaining)), 1, 0.5, 0.5)
            end
        end

        GameTooltip:AddLine(" ")

        -- Different hint text based on combat state
        if InCombatLockdown() then
            GameTooltip:AddLine(L["Click to queue as default (after combat)"], 1, 0.8, 0)
        else
            local castOnSelect = TotemBuddy.db.profile.castOnSelect
            if castOnSelect then
                GameTooltip:AddLine(L["Click to set as default and cast"], 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine(L["Click to set as default"], 0.7, 0.7, 0.7)
            end
        end
    else
        -- Show basic info for unavailable totems
        GameTooltip:AddLine(btn.totemData.name, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Not yet learned"], 1, 0.3, 0.3)

        if btn.totemData.levelRequired then
            local playerLevel = UnitLevel("player")
            if playerLevel < btn.totemData.levelRequired then
                GameTooltip:AddLine(string.format(L["Requires level %d"], btn.totemData.levelRequired), 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine(L["Visit a trainer to learn"], 0.7, 0.7, 0.7)
            end
        end
    end

    GameTooltip:Show()
end

return TotemSelector
