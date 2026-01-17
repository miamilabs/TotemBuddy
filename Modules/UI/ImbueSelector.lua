--[[
    TotemBuddy - Imbue Selector Module
    Popup menu for selecting weapon imbues when right-clicking an imbue tile
]]

---@class ImbueSelector
local ImbueSelector = TotemBuddyLoader:CreateModule("ImbueSelector")
local _ImbueSelector = ImbueSelector.private
local L = TotemBuddy_L or setmetatable({}, { __index = function(_, k) return k end })

-- Module references
local ExtrasScanner = nil

-- Constants
local MAX_BUTTONS = 12  -- Maximum button pool size (shamans have ~5 imbues max)

-- Selector frame
ImbueSelector.frame = nil
ImbueSelector.buttons = {}
ImbueSelector.parentTile = nil

--- Create the selector frame
function ImbueSelector:Create()
    if self.frame then
        return self.frame
    end

    -- Cancel any existing timers
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end

    local frame = CreateFrame("Frame", "TotemBuddyImbueSelector", UIParent, "BackdropTemplate")
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
    frame:SetBackdropColor(0.1, 0.1, 0.15, 0.95)  -- Slightly blue tint
    frame:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)  -- Blue border

    frame:Hide()

    -- Leave detection
    frame:SetScript("OnLeave", function(self)
        _ImbueSelector.ScheduleHide()
    end)

    frame:SetScript("OnEnter", function(self)
        _ImbueSelector.CancelHide()
    end)

    self.frame = frame
    return frame
end

--- Get or create a button from the pool
---@param index number The button index
---@return Button|nil button The button, or nil if index exceeds max
function _ImbueSelector.GetButton(index)
    -- Cap button pool to prevent unbounded growth
    if index > MAX_BUTTONS then
        return nil
    end

    if ImbueSelector.buttons[index] then
        return ImbueSelector.buttons[index]
    end

    local btn = CreateFrame("Button", "TotemBuddyImbueSelectorBtn" .. index, ImbueSelector.frame)
    btn:SetSize(36, 36)

    -- Icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Highlight
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(0.3, 0.5, 0.8, 0.4)  -- Blue tint
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
        _ImbueSelector.OnButtonClick(self)
    end)

    btn:SetScript("OnEnter", function(self)
        _ImbueSelector.CancelHide()
        _ImbueSelector.OnButtonEnter(self)
    end)

    btn:SetScript("OnLeave", function(self)
        _ImbueSelector.ScheduleHide()
        GameTooltip:Hide()
    end)

    ImbueSelector.buttons[index] = btn
    return btn
end

--- Show the selector for a tile
---@param tile Button The parent imbue tile
function ImbueSelector:Show(tile)
    if not self.frame then
        self:Create()
    end

    -- Get ExtrasScanner
    if not ExtrasScanner then
        ExtrasScanner = TotemBuddyLoader:ImportModule("ExtrasScanner")
    end

    self.parentTile = tile

    -- Get known imbues
    local knownImbues = ExtrasScanner:GetKnownImbues()
    if not knownImbues or #knownImbues == 0 then
        return
    end

    -- Populate buttons
    local buttonIndex = 0
    local columns = 4
    local buttonSize = 36
    local spacing = 4
    local padding = 8

    for _, imbueInfo in ipairs(knownImbues) do
        buttonIndex = buttonIndex + 1
        local btn = _ImbueSelector.GetButton(buttonIndex)

        -- Skip if button pool exceeded
        if not btn then break end

        btn.imbueData = imbueInfo.data
        btn.spellId = imbueInfo.spellId

        -- Get spell info for icon
        local _, _, icon = GetSpellInfo(imbueInfo.spellId)
        btn.icon:SetTexture(icon or imbueInfo.data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

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
function ImbueSelector:Hide()
    if self.frame then
        self.frame:Hide()
    end
    self.parentTile = nil
end

--- Schedule hiding with delay
function ImbueSelector:ScheduleHide()
    _ImbueSelector.ScheduleHide()
end

function _ImbueSelector.ScheduleHide()
    if ImbueSelector.hideTimer then
        ImbueSelector.hideTimer:Cancel()
    end

    ImbueSelector.hideTimer = C_Timer.NewTimer(0.15, function()
        ImbueSelector.hideTimer = nil

        local frame = ImbueSelector.frame
        local tile = ImbueSelector.parentTile

        if frame and frame:IsShown() then
            if frame:IsMouseOver() then
                return
            end
            if tile and tile:IsMouseOver() then
                return
            end
            ImbueSelector:Hide()
        end
    end)
end

--- Cancel scheduled hide
function ImbueSelector:CancelHide()
    _ImbueSelector.CancelHide()
end

function _ImbueSelector.CancelHide()
    if ImbueSelector.hideTimer then
        ImbueSelector.hideTimer:Cancel()
        ImbueSelector.hideTimer = nil
    end
end

--- Handle button click
---@param btn Button The clicked button
function _ImbueSelector.OnButtonClick(btn)
    local imbueData = btn.imbueData
    local spellId = btn.spellId
    local tile = ImbueSelector.parentTile

    if not imbueData or not spellId or not tile then
        return
    end

    -- Check combat
    if InCombatLockdown() then
        -- Queue for after combat
        tile.pendingImbueData = imbueData
        tile.pendingSpellId = spellId

        local spellName = GetSpellInfo(spellId) or imbueData.name
        TotemBuddy:Print(string.format(L["%s will be set as default when leaving combat."], spellName))

        ImbueSelector:Hide()
        return
    end

    -- Save as default for this slot
    local db = TotemBuddy.db.profile
    if tile.slot == "offhand" then
        db.defaultOffhandImbue = spellId
    else
        db.defaultMainhandImbue = spellId
    end

    -- Update the tile
    tile:SetImbue(spellId, imbueData)

    -- Hide selector
    ImbueSelector:Hide()
end

--- Handle button enter (tooltip)
---@param btn Button The hovered button
function _ImbueSelector.OnButtonEnter(btn)
    if not btn.spellId then
        return
    end

    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(btn.spellId)

    -- Add description if available
    if btn.imbueData and btn.imbueData.description then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(btn.imbueData.description, 1, 1, 1, true)
    end

    -- Add slot info
    local tile = ImbueSelector.parentTile
    if tile then
        local slotName = tile.slot == "offhand" and L["Offhand"] or L["Mainhand"]
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L["Click to set for %s"], slotName), 0.7, 0.7, 0.7)
    end

    GameTooltip:Show()
end

return ImbueSelector
