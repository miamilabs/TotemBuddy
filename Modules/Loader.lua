--[[
    TotemBuddy Module Loader
    Manages module creation and importing similar to Questie's pattern
]]

---@class TotemBuddyLoader
local TotemBuddyLoader = {}
TotemBuddyLoader._modules = {}

--- Creates a new module
---@param moduleName string The unique name for the module
---@return table module The created module table
function TotemBuddyLoader:CreateModule(moduleName)
    if self._modules[moduleName] then
        error("TotemBuddy: Module '" .. moduleName .. "' already exists!")
    end

    local module = {
        _name = moduleName,
        private = {},
    }

    self._modules[moduleName] = module
    return module
end

--- Imports an existing module
---@param moduleName string The name of the module to import
---@return table|nil module The module table or nil if not found
function TotemBuddyLoader:ImportModule(moduleName)
    local module = self._modules[moduleName]
    if not module then
        -- Module might not be loaded yet, return a placeholder that will be resolved later
        return nil
    end
    return module
end

--- Checks if a module exists
---@param moduleName string The name of the module to check
---@return boolean exists Whether the module exists
function TotemBuddyLoader:ModuleExists(moduleName)
    return self._modules[moduleName] ~= nil
end

--- Gets all registered module names
---@return table moduleNames List of module names
function TotemBuddyLoader:GetModuleNames()
    local names = {}
    for name, _ in pairs(self._modules) do
        table.insert(names, name)
    end
    return names
end

-- Make it globally accessible
_G.TotemBuddyLoader = TotemBuddyLoader
