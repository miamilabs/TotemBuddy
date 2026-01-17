--[[
    TotemBuddy - Migration Module
    Handles SavedVariables schema versioning and migration

    Schema Versions:
    - 1: Original schema (v1.0.0)
    - 2: Added sets, modifierOverrides, enhanced timer options (v2.0.0)
]]

---@class Migration
local Migration = TotemBuddyLoader:CreateModule("Migration")
local _Migration = Migration.private

-- Current schema version
Migration.CURRENT_VERSION = 2

-- Migration status tracking
_Migration.migrationRan = false
_Migration.migrationResults = {}

--- Run all necessary migrations on the database
---@param db table The AceDB database object
---@return boolean success Whether migrations completed successfully
---@return table results Details about what was migrated
function Migration:Run(db)
    if not db or not db.profile then
        return false, { error = "Invalid database object" }
    end

    _Migration.migrationResults = {}

    local currentVersion = db.profile.schemaVersion or 1
    local targetVersion = Migration.CURRENT_VERSION

    -- Already at current version
    if currentVersion >= targetVersion then
        _Migration.migrationRan = true
        return true, { message = "No migration needed", fromVersion = currentVersion }
    end

    -- Run migrations sequentially
    local success = true
    for version = currentVersion + 1, targetVersion do
        local migrationFunc = _Migration.migrations[version]
        if migrationFunc then
            local ok, err = pcall(migrationFunc, db)
            if ok then
                table.insert(_Migration.migrationResults, {
                    version = version,
                    success = true,
                })
            else
                table.insert(_Migration.migrationResults, {
                    version = version,
                    success = false,
                    error = tostring(err),
                })
                success = false
                break
            end
        end
    end

    -- Update schema version if successful
    if success then
        db.profile.schemaVersion = targetVersion
    end

    _Migration.migrationRan = true
    return success, _Migration.migrationResults
end

--- Check if migration has been run this session
---@return boolean ran Whether migration has run
function Migration:HasRun()
    return _Migration.migrationRan
end

--- Get the current schema version from a database
---@param db table The AceDB database object
---@return number version The schema version (1 if not set)
function Migration:GetVersion(db)
    if not db or not db.profile then
        return 1
    end
    return db.profile.schemaVersion or 1
end

--- Get the target schema version
---@return number version The current schema version constant
function Migration:GetCurrentVersion()
    return Migration.CURRENT_VERSION
end

-- Migration functions table
_Migration.migrations = {}

--[[
    Migration to Version 2 (v2.0.0)
    - Adds totem sets system
    - Adds modifier overrides
    - Adds enhanced timer options
    - Adds selector behavior options
    - Migrates any spell-name-based storage to spellIds (if found)
]]
_Migration.migrations[2] = function(db)
    local profile = db.profile

    -- Initialize sets if not present
    if profile.sets == nil then
        profile.sets = {}
    end

    -- Initialize active set name
    if profile.activeSetName == nil then
        profile.activeSetName = nil
    end

    -- Initialize set order for cycling
    if profile.setOrder == nil then
        profile.setOrder = {}
    end

    -- Initialize modifier overrides structure
    if profile.modifierOverrides == nil then
        profile.modifierOverrides = {
            [1] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Fire
            [2] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Earth
            [3] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Water
            [4] = { default = nil, shift = nil, ctrl = nil, alt = nil },  -- Air
        }
    else
        -- Ensure all elements have the full structure
        for element = 1, 4 do
            if profile.modifierOverrides[element] == nil then
                profile.modifierOverrides[element] = { default = nil, shift = nil, ctrl = nil, alt = nil }
            else
                -- Ensure all modifier keys exist
                local mo = profile.modifierOverrides[element]
                if mo.default == nil then mo.default = nil end
                if mo.shift == nil then mo.shift = nil end
                if mo.ctrl == nil then mo.ctrl = nil end
                if mo.alt == nil then mo.alt = nil end
            end
        end
    end

    -- Initialize enhanced timer options
    if profile.expiringThreshold == nil then
        profile.expiringThreshold = 10  -- seconds
    end

    if profile.expiringColor == nil then
        profile.expiringColor = {1, 0.8, 0}  -- Yellow
    end

    if profile.showDurationBar == nil then
        profile.showDurationBar = true
    end

    if profile.durationBarHeight == nil then
        profile.durationBarHeight = 4
    end

    -- Initialize selector behavior options
    if profile.castOnSelect == nil then
        profile.castOnSelect = false
    end

    if profile.castOnSelectInCombat == nil then
        profile.castOnSelectInCombat = false
    end

    -- Initialize show set name option
    if profile.showSetName == nil then
        profile.showSetName = true
    end

    -- Migrate any spell-name-based defaultTotems to spellIds
    -- (Original schema stored totem index, not spell names, so this is mostly defensive)
    if profile.defaultTotems then
        local TotemDatabase = _G.TotemBuddyTotemDatabase
        if TotemDatabase then
            for element = 1, 4 do
                local value = profile.defaultTotems[element]
                -- If value is a string (spell name), try to convert to spellId
                if type(value) == "string" then
                    local converted = _Migration:SpellNameToId(value, element, TotemDatabase)
                    if converted then
                        profile.defaultTotems[element] = converted
                    else
                        -- Can't convert, clear it
                        profile.defaultTotems[element] = nil
                    end
                end
                -- If value is a number, assume it's already correct (spellId or index)
            end
        end
    end

    -- Migrate totemRanks if they were stored as names
    if profile.totemRanks then
        local newRanks = {}
        for key, value in pairs(profile.totemRanks) do
            -- If key is a string name and value is a spellId, keep as-is
            -- This structure is: [totemName] = spellId, which is correct
            if type(key) == "string" and type(value) == "number" then
                newRanks[key] = value
            end
        end
        profile.totemRanks = newRanks
    end

    return true
end

--- Helper: Convert a spell name to spellId by searching the totem database
---@param spellName string The localized spell name
---@param element number The element to search in (1-4)
---@param TotemDatabase table The totem database
---@return number|nil spellId The spell ID if found
function _Migration:SpellNameToId(spellName, element, TotemDatabase)
    if not TotemDatabase or not TotemDatabase[element] then
        return nil
    end

    -- Search totems in the element
    for _, totem in ipairs(TotemDatabase[element]) do
        -- Check the base name
        if totem.name == spellName then
            -- Return the highest rank spellId
            return totem.spellIds[#totem.spellIds]
        end

        -- Check each spell's localized name
        for _, spellId in ipairs(totem.spellIds) do
            local localName = GetSpellInfo(spellId)
            -- Guard against nil (GetSpellInfo can return nil early in load or for invalid IDs)
            if localName and localName == spellName then
                return spellId
            end
        end
    end

    return nil
end

--- Create a backup of current profile before migration (optional utility)
---@param db table The AceDB database object
---@param backupName string Name for the backup profile
---@return boolean success Whether backup was created
function Migration:BackupProfile(db, backupName)
    if not db or not db.profile then
        return false
    end

    -- AceDB profiles have a CopyProfile method
    if db.profiles and db.SetProfile and db.CopyProfile then
        local currentProfile = db:GetCurrentProfile()
        local backup = backupName or (currentProfile .. "_backup_v" .. (db.profile.schemaVersion or 1))

        -- Copy current profile to backup
        local ok, err = pcall(function()
            db:SetProfile(backup)
            db:CopyProfile(currentProfile)
            db:SetProfile(currentProfile)
        end)

        return ok
    end

    return false
end

--- Validate that all required fields exist in the profile
---@param db table The AceDB database object
---@return boolean valid Whether profile has all required fields
---@return table|nil missing List of missing fields (if any)
function Migration:ValidateProfile(db)
    if not db or not db.profile then
        return false, { "profile" }
    end

    local missing = {}
    local profile = db.profile

    -- Check for v2 required fields
    local requiredFields = {
        "enabled",
        "locked",
        "layout",
        "scale",
        "tileSize",
        "defaultTotems",
        "sets",
        "modifierOverrides",
        "expiringThreshold",
        "showDurationBar",
    }

    for _, field in ipairs(requiredFields) do
        if profile[field] == nil then
            table.insert(missing, field)
        end
    end

    if #missing > 0 then
        return false, missing
    end

    return true, nil
end

--- Reset profile to defaults (emergency recovery)
---@param db table The AceDB database object
function Migration:ResetToDefaults(db)
    if not db then return end

    -- AceDB has a ResetProfile method
    if db.ResetProfile then
        db:ResetProfile()
    end
end

return Migration
