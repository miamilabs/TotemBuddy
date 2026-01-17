--[[
    TotemBuddy - Shield Selector Module
    Popup menu for selecting shields when right-clicking the shield tile
]]

---@class ShieldSelector
local ShieldSelector = TotemBuddyLoader:CreateModule("ShieldSelector")
local _ShieldSelector = ShieldSelector.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ExtrasScanner = nil

-- Constants
local MAX_BUTTONS = 6  -- Maximum button pool size (shamans have ~3 shields max)

-- Selector frame
ShieldSelector.frame = nil
ShieldSelector.buttons = {}
ShieldSelector.parentTile = nil

--- Create the selector frame
function ShieldSelector:Create()
    if self.frame then
        return self.frame
    end

    -- Cancel any existing timers
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end

    local frame = CreateFrame("Frame", "TotemBuddyShieldSelector", UIParent, "BackdropTemplate")
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
    frame:SetBackdropColor(0.15, 0.15, 0.1, 0.95)  -- Slightly yellow tint
    frame:SetBackdropBorderColor(0.8, 0.8, 0.4, 1)  -- Yellow border

    frame:Hide()

    -- Leave detection
    frame:SetScript("OnLeave", function(self)
        _ShieldSelector.ScheduleHide()
    end)

    frame:SetScript("OnEnter", function(self)
        _ShieldSelector.CancelHide()
    end)

    self.frame = frame
    return frame
end

--- Get or create a button from the pool
---@param index number The button index
---@return Button|nil button The button, or nil if index exceeds max
function _ShieldSelector.GetButton(index)
    -- Cap button pool to prevent unbounded growth
    if index > MAX_BUTTONS then
        return nil
    end

    if ShieldSelector.buttons[index] then
        return ShieldSelector.buttons[index]
    end

    local btn = CreateFrame("Button", "TotemBuddyShieldSelectorBtn" .. index, ShieldSelector.frame)
    btn:SetSize(36, 36)

    -- Icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Highlight
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(0.8, 0.8, 0.3, 0.4)  -- Yellow tint
    btn.highlight:SetBlendMode("ADD")

    -- Border
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.border:SetBlendMode("ADD")
    btn.border:SetPoint("CENTER")
    btn.border:SetSize(44, 44)
    btn.border:SetAlpha(0)

    -- Click handler
    btn:SetScript("OnClick", function(self)
        _ShieldSelector.OnButtonClick(self)
    end)

    btn:SetScript("OnEnter", function(self)
        _ShieldSelector.CancelHide()
        _ShieldSelector.OnButtonEnter(self)
    end)

    btn:SetScript("OnLeave", function(self)
        _ShieldSelector.ScheduleHide()
        GameTooltip:Hide()
    end)

    ShieldSelector.buttons[index] = btn
    return btn
end

--- Show the selector for a tile
---@param tile Button The parent shield tile
function ShieldSelector:Show(tile)
    if not self.frame then
        self:Create()
    end

    -- Get ExtrasScanner
    if not ExtrasScanner then
        ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
    end

    self.parentTile = tile

    -- Get known shields
    local knownShields = ExtrasScanner:GetKnownShields()
    if not knownShields or #knownShields == 0 then
        return
    end

    -- Populate buttons
    local buttonIndex = 0
    local columns = 3  -- Fewer columns for shields (usually only 2-3)
    local buttonSize = 36
    local spacing = 4
    local padding = 8

    for _, shieldInfo in ipairs(knownShields) do
        buttonIndex = buttonIndex + 1
        local btn = _ShieldSelector.GetButton(buttonIndex)

        -- Skip if button pool exceeded
        if not btn then break end

        btn.shieldData = shieldInfo.data
        btn.spellId = shieldInfo.spellId

        -- Get spell info for icon
        local _, _, icon = GetSpellInfo(shieldInfo.spellId)
        btn.icon:SetTexture(icon or shieldInfo.data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Position button
        local row = math.floor((buttonIndex - 1) / columns)
        local col = (buttonIndex - 1) % columns
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
            padding + col * (buttonSize + spacing),
            -padding - row * (buttonSize + spacing))

        btn:Show()
    end

    -- Hide unused buttons
    for i = buttonIndex + 1, #self.buttons do
        local b = self.buttons[i]
        if b then
            b:Hide()
        end
    end

    -- Handle no buttons
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
end

--- Hide the selector
function ShieldSelector:Hide()
    if self.frame then
        self.frame:Hide()
    end
    self.parentTile = nil
end

--- Schedule hiding with delay
function ShieldSelector:ScheduleHide()
    _ShieldSelector.ScheduleHide()
end

function _ShieldSelector.ScheduleHide()
    if ShieldSelector.hideTimer then
        ShieldSelector.hideTimer:Cancel()
    end

    ShieldSelector.hideTimer = C_Timer.NewTimer(0.15, function()
        ShieldSelector.hideTimer = nil

        local frame = ShieldSelector.frame
        local tile = ShieldSelector.parentTile

        if frame and frame:IsShown() then
            if frame:IsMouseOver() then
                return
            end
            if tile and tile:IsMouseOver() then
                return
            end
            ShieldSelector:Hide()
        end
    end)
end

--- Cancel scheduled hide
function ShieldSelector:CancelHide()
    _ShieldSelector.CancelHide()
end

function _ShieldSelector.CancelHide()
    if ShieldSelector.hideTimer then
        ShieldSelector.hideTimer:Cancel()
        ShieldSelector.hideTimer = nil
    end
end

--- Handle button click
---@param btn Button The clicked button
function _ShieldSelector.OnButtonClick(btn)
    local shieldData = btn.shieldData
    local spellId = btn.spellId
    local tile = ShieldSelector.parentTile

    if not shieldData or not spellId or not tile then
        return
    end

    -- Check combat
    if InCombatLockdown() then
        -- Queue for after combat
        tile.pendingShieldData = shieldData
        tile.pendingSpellId = spellId

        local spellName = GetSpellInfo(spellId) or shieldData.name
        TotemBuddy:Print(string.format(L["%s will be set as default when leaving combat."], spellName))

        ShieldSelector:Hide()
        return
    end

    -- Save as default
    TotemBuddy.db.profile.defaultShield = spellId

    -- Update the tile
    tile:SetShield(spellId, shieldData)

    -- Hide selector
    ShieldSelector:Hide()
end

--- Handle button enter (tooltip)
---@param btn Button The hovered button
function _ShieldSelector.OnButtonEnter(btn)
    if not btn.spellId then
        return
    end

    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(btn.spellId)

    -- Add description if available
    if btn.shieldData and btn.shieldData.description then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(btn.shieldData.description, 1, 1, 1, true)
    end

    -- Add Earth Shield hint
    if btn.shieldData and btn.shieldData.isTargeted then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Can be cast on friendly targets"], 0.7, 0.7, 0.7)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Click to set as default"], 0.7, 0.7, 0.7)

    GameTooltip:Show()
end

return ShieldSelector
