--[[
    TotemBuddy - Totem Sets Module
    Named preset management with instant switching and combat-aware queuing

    Sets store 4 spellIds (one per element) that can be switched instantly.
    When switching in combat, changes are queued and applied on combat end.
]]

---@class TotemSets
local TotemSets = TotemBuddyLoader:CreateModule("TotemSets")
local _TotemSets = TotemSets.private

-- Pending set change (queued during combat)
_TotemSets.pendingSetName = nil

-- Module references (resolved lazily)
local TotemBar = nil
local TotemData = nil

--- Get module references (lazy load)
local function GetModules()
    if not TotemBar then
        TotemBar = TotemBuddyLoader:ImportModule("TotemBar")
    end
    if not TotemData then
        TotemData = TotemBuddyLoader:ImportModule("TotemData")
    end
end

--- Get the currently active set name
---@return string|nil setName The active set name, or nil if using manual defaults
function TotemSets:GetActiveSet()
    return TotemBuddy.db.profile.activeSetName
end

--- Get the active set's totems
---@return table|nil totems Table of {[element]=spellId} or nil if no active set
function TotemSets:GetActiveSetTotems()
    local setName = TotemBuddy.db.profile.activeSetName
    if not setName then
        return nil
    end
    return TotemBuddy.db.profile.sets[setName]
end

--- Set the active set (queues if in combat)
---@param name string|nil The set name to activate, or nil to clear
---@return boolean success Whether the set was activated (false if queued or invalid)
---@return string|nil message Status message
function TotemSets:SetActiveSet(name)
    -- Validate set exists (unless clearing)
    if name and not TotemBuddy.db.profile.sets[name] then
        return false, "Set '" .. tostring(name) .. "' does not exist"
    end

    -- If in combat, queue the change
    if InCombatLockdown() then
        _TotemSets.pendingSetName = name
        return false, "Set change queued until combat ends"
    end

    -- Apply immediately
    return self:ApplySet(name)
end

--- Internal: Apply a set immediately (must be out of combat)
---@param name string|nil The set name to apply
---@return boolean success
---@return string|nil message
function TotemSets:ApplySet(name)
    if InCombatLockdown() then
        return false, "Cannot change sets in combat"
    end

    -- Store the active set name
    TotemBuddy.db.profile.activeSetName = name

    -- Apply the set's totems to defaultTotems
    if name then
        local setTotems = TotemBuddy.db.profile.sets[name]
        if setTotems then
            for element = 1, 4 do
                TotemBuddy.db.profile.defaultTotems[element] = setTotems[element]
            end
        end
    end

    -- Refresh the UI
    GetModules()
    if TotemBar and TotemBar.RefreshAllTiles then
        TotemBar:RefreshAllTiles()
    end

    -- Update set name display
    if TotemBar and TotemBar.UpdateSetNameDisplay then
        TotemBar:UpdateSetNameDisplay()
    end

    return true, name and ("Activated set: " .. name) or "Cleared active set"
end

--- Process any pending set change (called after leaving combat)
function TotemSets:ProcessPending()
    if _TotemSets.pendingSetName ~= nil then
        local name = _TotemSets.pendingSetName
        _TotemSets.pendingSetName = nil
        local success, msg = self:ApplySet(name)
        if TotemBuddy and TotemBuddy.Print and msg then
            TotemBuddy:Print(msg)
        end
    end
end

--- Check if there's a pending set change
---@return boolean hasPending
function TotemSets:HasPending()
    return _TotemSets.pendingSetName ~= nil
end

--- Create a new set
---@param name string The set name
---@param totems table|nil Optional table of {[element]=spellId}. If nil, uses current defaultTotems.
---@return boolean success
---@return string|nil message
function TotemSets:CreateSet(name, totems)
    if not name or name == "" then
        return false, "Set name cannot be empty"
    end

    if TotemBuddy.db.profile.sets[name] then
        return false, "Set '" .. name .. "' already exists"
    end

    -- Build the set data
    local setData = {}
    if totems then
        for element = 1, 4 do
            setData[element] = totems[element]
        end
    else
        -- Copy from current defaults
        for element = 1, 4 do
            setData[element] = TotemBuddy.db.profile.defaultTotems[element]
        end
    end

    -- Store the set
    TotemBuddy.db.profile.sets[name] = setData

    -- Add to set order for cycling
    table.insert(TotemBuddy.db.profile.setOrder, name)

    return true, "Created set: " .. name
end

--- Delete a set
---@param name string The set name
---@return boolean success
---@return string|nil message
function TotemSets:DeleteSet(name)
    if not name or name == "" then
        return false, "Set name cannot be empty"
    end

    if not TotemBuddy.db.profile.sets[name] then
        return false, "Set '" .. name .. "' does not exist"
    end

    -- Remove from sets
    TotemBuddy.db.profile.sets[name] = nil

    -- Remove from set order
    local setOrder = TotemBuddy.db.profile.setOrder
    for i = #setOrder, 1, -1 do
        if setOrder[i] == name then
            table.remove(setOrder, i)
        end
    end

    -- Clear active set if it was the deleted one
    if TotemBuddy.db.profile.activeSetName == name then
        TotemBuddy.db.profile.activeSetName = nil
        -- Update display
        GetModules()
        if TotemBar and TotemBar.UpdateSetNameDisplay then
            TotemBar:UpdateSetNameDisplay()
        end
    end

    return true, "Deleted set: " .. name
end

--- Rename a set
---@param oldName string The current set name
---@param newName string The new set name
---@return boolean success
---@return string|nil message
function TotemSets:RenameSet(oldName, newName)
    if not oldName or oldName == "" then
        return false, "Old set name cannot be empty"
    end

    if not newName or newName == "" then
        return false, "New set name cannot be empty"
    end

    if oldName == newName then
        return true, "Names are identical"
    end

    if not TotemBuddy.db.profile.sets[oldName] then
        return false, "Set '" .. oldName .. "' does not exist"
    end

    if TotemBuddy.db.profile.sets[newName] then
        return false, "Set '" .. newName .. "' already exists"
    end

    -- Copy data to new name
    TotemBuddy.db.profile.sets[newName] = TotemBuddy.db.profile.sets[oldName]
    TotemBuddy.db.profile.sets[oldName] = nil

    -- Update set order
    local setOrder = TotemBuddy.db.profile.setOrder
    for i, name in ipairs(setOrder) do
        if name == oldName then
            setOrder[i] = newName
            break
        end
    end

    -- Update active set if it was the renamed one
    if TotemBuddy.db.profile.activeSetName == oldName then
        TotemBuddy.db.profile.activeSetName = newName
    end

    -- Update pending if it was the renamed one
    if _TotemSets.pendingSetName == oldName then
        _TotemSets.pendingSetName = newName
    end

    return true, "Renamed set: " .. oldName .. " -> " .. newName
end

--- Cycle to the next set
---@return boolean success
---@return string|nil message
function TotemSets:CycleNext()
    local setOrder = TotemBuddy.db.profile.setOrder
    if not setOrder or #setOrder == 0 then
        return false, "No sets defined"
    end

    local currentSet = TotemBuddy.db.profile.activeSetName
    local currentIndex = 0

    -- Find current index
    if currentSet then
        for i, name in ipairs(setOrder) do
            if name == currentSet then
                currentIndex = i
                break
            end
        end
    end

    -- Calculate next index (wrap around)
    local nextIndex = (currentIndex % #setOrder) + 1
    local nextSet = setOrder[nextIndex]

    return self:SetActiveSet(nextSet)
end

--- Cycle to the previous set
---@return boolean success
---@return string|nil message
function TotemSets:CyclePrev()
    local setOrder = TotemBuddy.db.profile.setOrder
    if not setOrder or #setOrder == 0 then
        return false, "No sets defined"
    end

    local currentSet = TotemBuddy.db.profile.activeSetName
    local currentIndex = 1

    -- Find current index
    if currentSet then
        for i, name in ipairs(setOrder) do
            if name == currentSet then
                currentIndex = i
                break
            end
        end
    end

    -- Calculate previous index (wrap around)
    local prevIndex = ((currentIndex - 2) % #setOrder) + 1
    local prevSet = setOrder[prevIndex]

    return self:SetActiveSet(prevSet)
end

--- Save current default totems as a new set
---@param name string The set name
---@return boolean success
---@return string|nil message
function TotemSets:SaveCurrentAsSet(name)
    return self:CreateSet(name, nil) -- nil = use current defaults
end

--- Update a set's totem for a specific element
---@param setName string The set name
---@param element number The element (1-4)
---@param spellId number|nil The spell ID (nil to clear)
---@return boolean success
---@return string|nil message
function TotemSets:UpdateSetTotem(setName, element, spellId)
    if not setName or not TotemBuddy.db.profile.sets[setName] then
        return false, "Set '" .. tostring(setName) .. "' does not exist"
    end

    if not element or element < 1 or element > 4 then
        return false, "Invalid element"
    end

    TotemBuddy.db.profile.sets[setName][element] = spellId

    -- If this is the active set, also update defaults
    if TotemBuddy.db.profile.activeSetName == setName then
        TotemBuddy.db.profile.defaultTotems[element] = spellId

        -- Refresh the affected tile
        GetModules()
        if TotemBar and TotemBar.RefreshTile then
            TotemBar:RefreshTile(element)
        end
    end

    return true
end

--- Get all set names in order
---@return table setNames List of set names
function TotemSets:GetSetNames()
    local result = {}
    for _, name in ipairs(TotemBuddy.db.profile.setOrder) do
        -- Verify set still exists (defensive)
        if TotemBuddy.db.profile.sets[name] then
            table.insert(result, name)
        end
    end
    return result
end

--- Get the number of defined sets
---@return number count
function TotemSets:GetSetCount()
    local count = 0
    for _ in pairs(TotemBuddy.db.profile.sets) do
        count = count + 1
    end
    return count
end

--- Check if a set exists
---@param name string The set name
---@return boolean exists
function TotemSets:SetExists(name)
    return name and TotemBuddy.db.profile.sets[name] ~= nil
end

--- Get a set's totems
---@param name string The set name
---@return table|nil totems Table of {[element]=spellId}
function TotemSets:GetSetTotems(name)
    if not name then return nil end
    return TotemBuddy.db.profile.sets[name]
end

--- Clone a set
---@param sourceName string The source set name
---@param newName string The new set name
---@return boolean success
---@return string|nil message
function TotemSets:CloneSet(sourceName, newName)
    if not TotemBuddy.db.profile.sets[sourceName] then
        return false, "Source set '" .. tostring(sourceName) .. "' does not exist"
    end

    -- Get source totems and create new set
    local sourceTotems = TotemBuddy.db.profile.sets[sourceName]
    local clonedTotems = {}
    for element = 1, 4 do
        clonedTotems[element] = sourceTotems[element]
    end

    return self:CreateSet(newName, clonedTotems)
end

--- Reorder sets (for UI drag-and-drop)
---@param newOrder table New ordered list of set names
---@return boolean success
function TotemSets:ReorderSets(newOrder)
    if not newOrder or type(newOrder) ~= "table" then
        return false
    end

    -- Verify all sets exist
    for _, name in ipairs(newOrder) do
        if not TotemBuddy.db.profile.sets[name] then
            return false
        end
    end

    TotemBuddy.db.profile.setOrder = newOrder
    return true
end

return TotemSets
