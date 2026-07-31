-- AzerCore Ops Search Framework
-- Project Renaissance / DP003-R1
-- Shared parsing and normalization for workspace searches.

AzerCoreOpsSearch = AzerCoreOpsSearch or {}
local Search = AzerCoreOpsSearch

Search.VERSION = "0.4.0-dp003-r1"

local function Trim(value)
  return tostring(value or ""):match("^%s*(.-)%s*$")
end

function Search.Normalize(value)
  return Trim(tostring(value or ""):gsub("%s+", " "))
end

function Search.Classify(value, expectedKind)
  local text = Search.Normalize(value)
  if text == "" then
    return nil, "Enter a search term or numeric ID."
  end

  local linkType, rawId = text:match("|H([^:|]+):([^:|]+)")
  if linkType then
    if expectedKind and linkType ~= expectedKind then
      return nil, "This search accepts " .. expectedKind .. " links, not " .. tostring(linkType) .. " links."
    end
    local id = tonumber(rawId)
    if id and id > 0 then
      return { mode="id", id=math.floor(id), query=tostring(math.floor(id)), source="link" }
    end
    local label = text:match("|h%[([^%]]+)%]|h")
    if label and label ~= "" then
      return { mode="text", query=Search.Normalize(label), source="link" }
    end
  end

  local id = tonumber(text)
  if id and id > 0 and id == math.floor(id) then
    return { mode="id", id=id, query=tostring(id), source="id" }
  end

  return { mode="text", query=text, source="text" }
end

function Search.Matches(value, query)
  local haystack = string.lower(Search.Normalize(value))
  local needle = string.lower(Search.Normalize(query))
  return needle ~= "" and string.find(haystack, needle, 1, true) ~= nil
end
