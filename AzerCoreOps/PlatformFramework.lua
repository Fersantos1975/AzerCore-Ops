local ADDON = ...

AzerCoreOpsPlatform = AzerCoreOpsPlatform or {}
local Platform = AzerCoreOpsPlatform

Platform.capabilities = Platform.capabilities or {}
Platform.features = Platform.features or {}
Platform.permissions = Platform.permissions or {}
Platform.server = Platform.server or nil

local function Split(value, separator)
  local result = {}
  value = tostring(value or "")
  for token in value:gmatch("[^"..separator.."]+") do result[#result+1] = token end
  return result
end

function Platform:Reset()
  self.capabilities, self.features, self.permissions = {}, {}, {}
  self.server = nil
end

function Platform:ApplyVersion(fields)
  self:Reset()
  self.server = fields or {}
  for _, key in ipairs(Split(fields and fields.capabilities, ",")) do self.capabilities[key] = true end
  for _, definition in ipairs(Split(fields and fields.features, ";")) do
    local name, values = definition:match("^([^:]+):(.+)$")
    if name then
      self.features[name] = {}
      for _, key in ipairs(Split(values, ",")) do self.features[name][key] = true end
    end
  end
  for _, definition in ipairs(Split(fields and fields.permissions, ";")) do
    local operation, permission = definition:match("^([^=]+)=(.+)$")
    if operation then self.permissions[operation] = permission end
  end
end

function Platform:HasCapability(key) return self.capabilities[key] == true end
function Platform:PermissionFor(operation) return self.permissions[operation] end

function Platform:FeatureState(name)
  local requirements = self.features[name]
  if not requirements then return "unknown", "The module did not advertise this feature." end
  local missing = {}
  for key in pairs(requirements) do if not self:HasCapability(key) then missing[#missing+1] = key end end
  table.sort(missing)
  if #missing > 0 then return "limited", "Missing capabilities: "..table.concat(missing, ", ") end
  return "available", "All advertised capabilities are present."
end

function Platform:Compatibility(addonProtocol)
  if not self.server then return "unchecked", "The server module has not been queried." end
  if tostring(self.server.protocol or "") ~= tostring(addonProtocol or "") then
    return "incompatible", "Addon and module protocols do not match."
  end
  local limited = false
  for name in pairs(self.features) do
    if self:FeatureState(name) == "limited" then limited = true break end
  end
  if limited then return "limited", "Core functions are compatible, but some advertised features are incomplete." end
  return "compatible", "Addon and module protocols match."
end

function Platform:SortedCapabilities()
  local values = {}
  for key in pairs(self.capabilities) do values[#values+1] = key end
  table.sort(values)
  return values
end

function Platform:SortedPermissions()
  local values = {}
  for operation, permission in pairs(self.permissions) do values[#values+1] = operation.." — "..permission end
  table.sort(values)
  return values
end
