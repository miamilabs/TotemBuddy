--[[
    TotemBuddy - Shaman Totem Management Addon
    Main entry point using AceAddon-3.0
]]

---@class TotemBuddy : AceAddon, AceEvent-3.0, AceConsole-3.0
local TotemBuddy = LibStub("AceAddon-3.0"):NewAddon("TotemBuddy", "AceEvent-3.0", "AceConsole-3.0")
_G.TotemBuddy = TotemBuddy

-- Version info
TotemBuddy.version = "2.0.0"

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

    -- Run migrations if needed (v2.0 schema changes)
    local Migration = TotemBuddyLoader:ImportModule("Migration")
    if Migration then
        local success, results = Migration:Run(self.db)
        if not success then
            self:Print("|cffff0000Warning: Migration failed. Some settings may be reset.|r")
        end
    end

    -- Ensure defaultTotems table exists (AceDB might not init nested tables properly)
    if not self.db.profile.defaultTotems then
        self.db.profile.defaultTotems = {}
    end

    -- Ensure v2.0 tables exist
    if not self.db.profile.sets then
        self.db.profile.sets = {}
    end
    if not self.db.profile.setOrder then
        self.db.profile.setOrder = {}
    end
    if not self.db.profile.modifierOverrides then
        self.db.profile.modifierOverrides = {
            [1] = { default = nil, shift = nil, ctrl = nil, alt = nil },
            [2] = { default = nil, shift = nil, ctrl = nil, alt = nil },
            [3] = { default = nil, shift = nil, ctrl = nil, alt = nil },
            [4] = { default = nil, shift = nil, ctrl = nil, alt = nil },
        }
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

    -- Initialize API compatibility layer (must be done early)
    local APICompat = TotemBuddyLoader:ImportModule("APICompat")
    if APICompat then
        APICompat:Initialize()
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
    input = input:gsub("^%s*(.-)%s*$", "%1")  -- trim only, preserve case for set names

    -- Split into command and arguments
    local cmd, args = input:match("^(%S*)%s*(.*)$")
    cmd = (cmd or ""):lower()
    args = args or ""

    if cmd == "" or cmd == "options" or cmd == "config" then
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
    elseif cmd == "toggle" then
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
    elseif cmd == "lock" then
        -- Toggle lock
        self.db.profile.locked = not self.db.profile.locked
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        if TotemBar then
            TotemBar:SetLocked(self.db.profile.locked)
        end
        self:Print("TotemBuddy is now " .. (self.db.profile.locked and "locked" or "unlocked"))
    elseif cmd == "reset" then
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
    elseif cmd == "scan" then
        -- Force rescan totems
        local SpellScanner = TotemBuddyLoader:ImportModule("SpellScanner")
        if SpellScanner then
            SpellScanner:ScanTotems()
            self:Print("Totem scan complete")
        end

    -- Totem Sets commands (v2.0)
    elseif cmd == "set" then
        -- Activate a named set: /tb set <name>
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
        if not TotemSets then
            self:Print("TotemSets module not loaded")
            return
        end

        if args == "" then
            -- Show current set
            local currentSet = TotemSets:GetActiveSet()
            if currentSet then
                self:Print("Active set: " .. currentSet)
            else
                self:Print("No active set")
            end
            -- List available sets
            local setNames = TotemSets:GetSetNames()
            if #setNames > 0 then
                self:Print("Available sets: " .. table.concat(setNames, ", "))
            else
                self:Print("No sets defined. Use /tb saveset <name> to create one.")
            end
        else
            local success, msg = TotemSets:SetActiveSet(args)
            self:Print(msg or (success and "Set activated" or "Failed to activate set"))
        end

    elseif cmd == "nextset" then
        -- Cycle to next set: /tb nextset
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
        if TotemSets then
            local success, msg = TotemSets:CycleNext()
            if msg then self:Print(msg) end
        end

    elseif cmd == "prevset" then
        -- Cycle to previous set: /tb prevset
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
        if TotemSets then
            local success, msg = TotemSets:CyclePrev()
            if msg then self:Print(msg) end
        end

    elseif cmd == "saveset" then
        -- Save current totems as a new set: /tb saveset <name>
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
        if not TotemSets then
            self:Print("TotemSets module not loaded")
            return
        end

        if args == "" then
            self:Print("Usage: /tb saveset <name>")
        else
            local success, msg = TotemSets:SaveCurrentAsSet(args)
            self:Print(msg or (success and "Set saved" or "Failed to save set"))
        end

    elseif cmd == "delset" then
        -- Delete a set: /tb delset <name>
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
        if not TotemSets then
            self:Print("TotemSets module not loaded")
            return
        end

        if args == "" then
            self:Print("Usage: /tb delset <name>")
        else
            local success, msg = TotemSets:DeleteSet(args)
            self:Print(msg or (success and "Set deleted" or "Failed to delete set"))
        end

    elseif cmd == "sets" then
        -- List all sets: /tb sets
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
        if TotemSets then
            local setNames = TotemSets:GetSetNames()
            local activeSet = TotemSets:GetActiveSet()
            if #setNames > 0 then
                self:Print("=== Totem Sets ===")
                for _, name in ipairs(setNames) do
                    local marker = (name == activeSet) and " [ACTIVE]" or ""
                    self:Print("  " .. name .. marker)
                end
            else
                self:Print("No sets defined. Use /tb saveset <name> to create one.")
            end
        end

    elseif cmd == "debug" then
        -- Debug info
        local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
        local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
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
        -- Show active set info
        if TotemSets then
            self:Print("=== Set Info ===")
            local activeSet = TotemSets:GetActiveSet()
            self:Print("Active set: " .. tostring(activeSet or "none"))
            self:Print("Set count: " .. TotemSets:GetSetCount())
            self:Print("Pending set: " .. tostring(TotemSets:HasPending() and "yes" or "no"))
        end
    elseif cmd == "show" then
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
        self:Print("Set Commands:")
        self:Print("  /tb set <name> - Activate a set")
        self:Print("  /tb sets - List all sets")
        self:Print("  /tb nextset - Cycle to next set")
        self:Print("  /tb prevset - Cycle to previous set")
        self:Print("  /tb saveset <name> - Save current as set")
        self:Print("  /tb delset <name> - Delete a set")
    end
end

--- Utility: Check if in combat lockdown
---@return boolean inCombat Whether protected actions are blocked
function TotemBuddy:InCombatLockdown()
    return InCombatLockdown()
end

--[[
    Global Keybinding Handlers
    These functions are called by Bindings.xml when the user presses bound keys.
    They are defined in the global namespace so WoW can find them.
]]

--- Cast the default totem for an element (keybind handler)
--- NOTE: Casting via keybind only works out of combat (SecureActionButton limitation)
--- For combat casting, click the tile directly or use the SetOverrideBindingClick system
---@param element number The element index (1=Fire, 2=Earth, 3=Water, 4=Air)
function TotemBuddy_CastElement(element)
    if not element or element < 1 or element > 4 then
        return
    end

    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    if not TotemBar or not TotemBar.tiles or not TotemBar.tiles[element] then
        return
    end

    local tile = TotemBar.tiles[element]

    -- If in combat, we can't programmatically click secure buttons
    -- The user should click the tile directly or use SetOverrideBindingClick
    if InCombatLockdown() then
        TotemBuddy:Print("Keybind casting is not available in combat. Click the tile directly.")
        return
    end

    -- Out of combat: we can safely click the secure button
    tile:Click("LeftButton")
end

--- Open the totem selector for an element (keybind handler)
---@param element number The element index (1=Fire, 2=Earth, 3=Water, 4=Air)
function TotemBuddy_SelectElement(element)
    if not element or element < 1 or element > 4 then
        return
    end

    local TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    local TotemSelector = TotemBuddyLoader:ImportModule("TotemSelector")

    if not TotemBar or not TotemBar.tiles or not TotemBar.tiles[element] then
        return
    end

    if not TotemSelector or not TotemSelector.Show then
        return
    end

    local tile = TotemBar.tiles[element]

    -- Check combat setting for selector
    local inCombat = InCombatLockdown()
    local showInCombat = TotemBuddy.db.profile.showSelectorInCombat

    if not inCombat or showInCombat then
        TotemSelector:Show(tile)
    elseif inCombat then
        TotemBuddy:Print("Cannot open selector during combat.")
    end
end

--- Cycle totem sets (keybind handler)
---@param direction number 1 for next, -1 for previous
function TotemBuddy_CycleSet(direction)
    local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
    if not TotemSets then
        return
    end

    local success, msg
    if direction == 1 then
        success, msg = TotemSets:CycleNext()
    else
        success, msg = TotemSets:CyclePrev()
    end

    if msg then
        TotemBuddy:Print(msg)
    end
end

--- Activate a totem set by order index (keybind handler)
---@param index number The set index (1-5)
function TotemBuddy_ActivateSet(index)
    if not index or index < 1 or index > 5 then
        return
    end

    local TotemSets = TotemBuddyLoader:ImportModule("TotemSets")
    if not TotemSets then
        return
    end

    -- Get set names in order
    local setNames = TotemSets:GetSetNames()
    if not setNames or #setNames < index then
        TotemBuddy:Print("No set at position " .. index)
        return
    end

    local setName = setNames[index]
    local success, msg = TotemSets:SetActiveSet(setName)

    if msg then
        TotemBuddy:Print(msg)
    end
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
