-- AzerCore Ops UI Foundation
-- Development package: v0.4.0-dev001
-- Target: World of Warcraft 3.3.5a (Lua 5.1)
--
-- This file provides shared, non-authoritative UI and input helpers. It does
-- not execute server operations and may be loaded safely before AzerCoreOps.lua.

AzerCoreOpsUI = AzerCoreOpsUI or {}
local UI = AzerCoreOpsUI

UI.VERSION = "0.4.0-dev001"
UI.INPUT_KINDS = {
  quest = true,
  item = true,
  spell = true,
  achievement = true,
  player = true,
  creature = true,
  map = true,
}

local function Trim(value)
  return tostring(value or ""):match("^%s*(.-)%s*$")
end
UI.Trim = Trim

function UI.NormalizeWhitespace(value)
  return Trim(tostring(value or ""):gsub("%s+", " "))
end

function UI.ParseHyperlink(value)
  local text = tostring(value or "")
  local linkType, rawId = text:match("|H([^:|]+):([^:|]+)")
  local label = text:match("|h%[([^%]]+)%]|h")
  local player = text:match("|Hplayer:([^:|]+)")
  if not linkType then return nil end

  local numericId = tonumber(rawId)
  return {
    kind = linkType,
    id = numericId,
    rawId = rawId,
    label = label,
    player = player,
    original = text,
  }
end

function UI.ParseInput(value, expectedKind)
  local text = UI.NormalizeWhitespace(value)
  if text == "" then
    return nil, "empty", "Enter a value."
  end

  local link = UI.ParseHyperlink(text)
  if link then
    if expectedKind and link.kind ~= expectedKind then
      return nil, "wrong_link_type", "This field accepts " .. expectedKind .. " links, not " .. tostring(link.kind) .. " links."
    end
    if link.player then
      return { kind = "player", value = link.player, source = "link", link = link }
    end
    if link.id then
      return { kind = link.kind, value = link.id, source = "link", link = link }
    end
    return { kind = link.kind, value = link.label or text, source = "link", link = link }
  end

  local numeric = tonumber(text)
  if numeric and numeric > 0 and numeric == math.floor(numeric) then
    return { kind = expectedKind or "id", value = numeric, source = "id" }
  end

  return { kind = expectedKind or "text", value = text, source = "text" }
end

function UI.RequirePositiveId(value, label)
  local parsed, code = UI.ParseInput(value)
  if not parsed or parsed.source ~= "id" then
    return nil, code or "invalid_id", "Enter a valid " .. tostring(label or "numeric") .. " ID."
  end
  return parsed.value
end

function UI.SetButtonEnabled(button, enabled, reason)
  if not button then return end
  button.azerCoreOpsDisabledReason = reason
  button.azerCoreOpsEnabled = enabled and true or false
  if enabled then
    button:Enable()
    button:SetAlpha(1)
  else
    button:Disable()
    button:SetAlpha(0.45)
  end
end

function UI.AttachTooltip(frame, title, body, disabledReasonProvider)
  if not frame then return end
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title or "AzerCore Ops", 1, 0.82, 0)
    local disabledReason = disabledReasonProvider and disabledReasonProvider(self) or self.azerCoreOpsDisabledReason
    if disabledReason and disabledReason ~= "" then
      GameTooltip:AddLine(disabledReason, 1, 0.35, 0.35, true)
    elseif body and body ~= "" then
      GameTooltip:AddLine(body, 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI.AddClearButton(editBox, parent, xOffset)
  if not editBox then return nil end
  local owner = parent or editBox:GetParent()
  local button = CreateFrame("Button", nil, owner)
  button:SetWidth(18)
  button:SetHeight(18)
  button:SetPoint("LEFT", editBox, "RIGHT", xOffset or 4, 0)
  button:SetText("x")
  button:SetNormalFontObject(GameFontNormalSmall)
  button:SetHighlightFontObject(GameFontHighlightSmall)
  button:SetScript("OnClick", function()
    editBox:SetText("")
    editBox:SetFocus()
  end)
  UI.AttachTooltip(button, "Clear", "Clear this field.")
  return button
end

function UI.SetPlaceholder(editBox, placeholder)
  if not editBox then return end
  editBox.azerCoreOpsPlaceholder = placeholder

  local function Refresh(self)
    local empty = Trim(self:GetText()) == ""
    if empty and not self:HasFocus() then
      self.azerCoreOpsShowingPlaceholder = true
      self:SetText(placeholder or "")
      self:SetTextColor(0.5, 0.5, 0.5, 1)
    elseif self.azerCoreOpsShowingPlaceholder then
      self.azerCoreOpsShowingPlaceholder = nil
      self:SetText("")
      self:SetTextColor(1, 1, 1, 1)
    end
  end

  editBox:HookScript("OnEditFocusGained", function(self)
    if self.azerCoreOpsShowingPlaceholder then
      self.azerCoreOpsShowingPlaceholder = nil
      self:SetText("")
      self:SetTextColor(1, 1, 1, 1)
    end
  end)
  editBox:HookScript("OnEditFocusLost", Refresh)
  editBox:HookScript("OnTextChanged", function(self, userInput)
    if userInput and self.azerCoreOpsShowingPlaceholder then
      self.azerCoreOpsShowingPlaceholder = nil
      self:SetTextColor(1, 1, 1, 1)
    end
  end)
  Refresh(editBox)
end

function UI.GetInputText(editBox)
  if not editBox or editBox.azerCoreOpsShowingPlaceholder then return "" end
  return Trim(editBox:GetText())
end

function UI.BindButtonToInput(button, editBox, validator, invalidReason)
  if not button or not editBox then return end
  local function Refresh()
    local value = UI.GetInputText(editBox)
    local valid = validator and validator(value) or value ~= ""
    UI.SetButtonEnabled(button, valid, valid and nil or invalidReason or "Enter a valid value first.")
  end
  editBox:HookScript("OnTextChanged", Refresh)
  editBox:HookScript("OnEditFocusLost", Refresh)
  Refresh()
end

function UI.PositiveIntegerValidator(value)
  local n = tonumber(Trim(value))
  return n and n > 0 and n == math.floor(n) and true or false
end

function UI.NonEmptyValidator(value)
  return Trim(value) ~= ""
end
