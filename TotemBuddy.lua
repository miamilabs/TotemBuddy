--[[
    TotemBuddy - Shaman Totem Management Addon
    Main entry point using AceAddon-3.0
]]

---@class TotemBuddy : AceAddon, AceEvent-3.0, AceConsole-3.0
local TotemBuddy = LibStub("AceAddon-3.0"):NewAddon("TotemBuddy", "AceEvent-3.0", "AceConsole-3.0")
_G.TotemBuddy = TotemBuddy

-- Version info
TotemBuddy.version = "1.0.0"

-- Element constants (matches WoW API GetTotemInfo slot order)
TotemBuddy.FIRE = 1
TotemBuddy.EARTH = 2
TotemBuddy.WATER = 3
TotemBuddy.AIR = 4

-- Element names for display (indexed by slot)
TotemBuddy.ElementNames = {
    [1] = "Fire",
    [2] = "Earth",
    [3] = "Water",
    [4] = "Air",
}

-- Element colors (r, g, b) (indexed by slot)
TotemBuddy.ElementColors = {
    [1] = {1.0, 0.4, 0.1},   -- Fire: Orange
    [2] = {0.6, 0.4, 0.2},   -- Earth: Brown
    [3] = {0.2, 0.5, 1.0},   -- Water: Blue
    [4] = {0.7, 0.7, 0.9},   -- Air: Light purple
}

-- Runtime caches
TotemBuddy.KnownTotems = {}      -- [spellId] = true
TotemBuddy.HighestRanks = {}    -- [totemName] = spellId

--- Utility: Format time for display (consolidated function used across modules)
---@param seconds number Time in seconds
---@return string formatted Formatted time string
function TotemBuddy.FormatTime(seconds)
    if seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds))
    else
        return string.format("%.1f", seconds)
    end
end

--- Called when the addon is initialized
function TotemBuddy:OnInitialize()
    -- Check if player is a Shaman
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
        self:Print("TotemBuddy is only for Shamans!")
        return
    end

    -- Initialize saved variables with defaults
    local OptionsDefaults = TotemBuddyLoader:ImportModule("OptionsDefaults")
    self.db = LibStub("AceDB-3.0"):New("TotemBuddyDB", OptionsDefaults:GetDefaults(), true)

    -- Ensure defaultTotems table exists (AceDB might not init nested tables properly)
    if not self.db.profile.defaultTotems then
        self.db.profile.defaultTotems = {}
    end

    -- Register callbacks for profile changes
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- Initialize options
    local OptionsMain = TotemBuddyLoader:ImportModule("OptionsMain")
    if OptionsMain then
        OptionsMain:Initialize()
    end

    -- Register slash commands
    self:RegisterChatCommand("tb", "SlashCommand")
    self:RegisterChatCommand("totembuddy", "SlashCommand")
end

--- Called when the addon is enabled
function TotemBuddy:OnEnable()
    -- Check if player is a Shaman
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
        return
    end

    -- Initialize modules
    local EventHandler = TotemBuddyLoader:ImportModule("EventHandler")
    if EventHandler then
        EventHandler:RegisterEvents()
    end

    -- Scan for known totems
    local SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
    if SpellScanner then
        SpellScanner:ScanTotems()
    end

    -- Create the UI
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar then
        TotemBar:Create()
        if self.db.profile.enabled then
            TotemBar:Show()
        end
    end

    self:Print("TotemBuddy v" .. self.version .. " loaded. Type /tb for options.")
end

--- Called when the addon is disabled
function TotemBuddy:OnDisable()
    -- Hide UI
    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar then
        TotemBar:Hide()
    end

    -- Cleanup event handler timers
    local EventHandler = TotemBuddyLoader:ImportModule("EventHandler")
    if EventHandler and EventHandler.Cleanup then
        EventHandler:Cleanup()
    end

    -- Cleanup selector timers
    local TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")
    if TotemSelector then
        if TotemSelector.cooldownTimer then
            TotemSelector.cooldownTimer:Cancel()
            TotemSelector.cooldownTimer = nil
        end
        if TotemSelector.hideTimer then
            TotemSelector.hideTimer:Cancel()
            TotemSelector.hideTimer = nil
        end
    end
end

--- Handles profile changes
function TotemBuddy:RefreshConfig()
    -- Ensure defaultTotems table exists
    if not self.db.profile.defaultTotems then
        self.db.profile.defaultTotems = {}
    end

    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if TotemBar and TotemBar.frame then
        TotemBar:UpdateLayout()
        TotemBar:RefreshAllTiles()
    end
end

--- Slash command handler
---@param input string The command input
function TotemBuddy:SlashCommand(input)
    -- Defensive input handling
    input = input or ""
    input = input:gsub("^%s*(.-)%s*$", "%1"):lower()  -- trim and lowercase

    if input == "" or input == "options" or input == "config" then
        -- Open options panel (handle different WoW versions)
        local OptionsMain = TotemBuddyLoader:ImportModule("OptionsMain")
        if OptionsMain and OptionsMain.Open then
            OptionsMain:Open()
        elseif Settings and Settings.OpenToCategory then
            Settings.OpenToCategory("TotemBuddy")
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("TotemBuddy")
        else
            self:Print("Options panel not available.")
        end
    elseif input == "toggle" then
        -- Toggle visibility
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar then
            if TotemBar.frame and TotemBar.frame:IsShown() then
                TotemBar:Hide()
                self.db.profile.enabled = false
            else
                TotemBar:Show()
                self.db.profile.enabled = true
            end
        end
    elseif input == "lock" then
        -- Toggle lock
        self.db.profile.locked = not self.db.profile.locked
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar then
            TotemBar:SetLocked(self.db.profile.locked)
        end
        self:Print("TotemBuddy is now " .. (self.db.profile.locked and "locked" or "unlocked"))
    elseif input == "reset" then
        -- Reset position
        self.db.profile.posX = 0
        self.db.profile.posY = -200
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar and TotemBar.frame then
            TotemBar.frame:ClearAllPoints()
            TotemBar.frame:SetPoint(self.db.profile.anchor, UIParent, self.db.profile.anchor,
                self.db.profile.posX, self.db.profile.posY)
        end
        self:Print("TotemBuddy position reset")
    elseif input == "scan" then
        -- Force rescan totems
        local SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
        if SpellScanner then
            SpellScanner:ScanTotems()
            self:Print("Totem scan complete")
        end
    elseif input == "debug" then
        -- Debug info
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        self:Print("=== TotemBuddy Debug ===")
        self:Print("Enabled: " .. tostring(self.db.profile.enabled))
        self:Print("Frame exists: " .. tostring(TotemBar and TotemBar.frame ~= nil))
        if TotemBar and TotemBar.frame then
            self:Print("Frame shown: " .. tostring(TotemBar.frame:IsShown()))
            self:Print("Frame visible: " .. tostring(TotemBar.frame:IsVisible()))
            local point, _, _, x, y = TotemBar.frame:GetPoint()
            self:Print("Position: " .. tostring(point) .. " (" .. tostring(x) .. ", " .. tostring(y) .. ")")
            self:Print("Scale: " .. tostring(TotemBar.frame:GetScale()))
            self:Print("Alpha: " .. tostring(TotemBar.frame:GetAlpha()))
            self:Print("Size: " .. TotemBar.frame:GetWidth() .. "x" .. TotemBar.frame:GetHeight())
        end
        local count = 0
        for _ in pairs(self.KnownTotems) do count = count + 1 end
        self:Print("Known totems: " .. count)
        -- Show saved default totems
        self:Print("=== Saved Totems ===")
        if self.db.profile.defaultTotems then
            for i = 1, 4 do
                local name = self.db.profile.defaultTotems[i]
                self:Print("  Slot " .. i .. ": " .. tostring(name or "none"))
            end
        else
            self:Print("  defaultTotems table is nil!")
        end
    elseif input == "show" then
        -- Force show the bar
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar then
            if not TotemBar.frame then
                TotemBar:Create()
            end
            TotemBar:Show()
            TotemBar.frame:SetAlpha(1)
            self.db.profile.enabled = true
            self:Print("TotemBuddy bar forced visible")
        end
    else
        -- Help
        self:Print("TotemBuddy Commands:")
        self:Print("  /tb - Open options")
        self:Print("  /tb toggle - Toggle visibility")
        self:Print("  /tb lock - Toggle lock")
        self:Print("  /tb reset - Reset position")
        self:Print("  /tb scan - Rescan totems")
        self:Print("  /tb show - Force show bar")
        self:Print("  /tb debug - Show debug info")
    end
end

--- Utility: Check if in combat lockdown
---@return boolean inCombat Whether protected actions are blocked
function TotemBuddy:InCombatLockdown()
    return InCombatLockdown()
end

--- Utility: Get the spell ID to use for a totem (handles rank selection)
---@param totemData table The totem data from database
---@return number|nil spellId The spell ID to use
function TotemBuddy:GetTotemSpellId(totemData)
    if not totemData or not totemData.spellIds then
        return nil
    end

    if self.db.profile.useHighestRank then
        -- Use highest known rank
        return self.HighestRanks[totemData.name]
    else
        -- Check for saved rank preference
        local savedRank = self.db.profile.totemRanks[totemData.name]
        if savedRank and self.KnownTotems[savedRank] then
            return savedRank
        end
        -- Fall back to highest known
        return self.HighestRanks[totemData.name]
    end
end
