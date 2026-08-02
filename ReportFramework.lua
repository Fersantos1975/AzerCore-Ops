-- AzerCore Ops Report Framework
-- Project Renaissance / DP003-R1
-- Reusable in-addon report panels. Operational output stays in context.

AzerCoreOpsReports = AzerCoreOpsReports or {}
local Reports = AzerCoreOpsReports

Reports.VERSION = "0.4.0-dp003-r1"

local function SetHeightForText(panel)
  if not panel or not panel.text or not panel.child then return end
  local _, lines = tostring(panel.text:GetText() or ""):gsub("\n", "\n")
  local height = math.max(panel.minimumHeight or 100, (lines + 2) * (panel.lineHeight or 15))
  panel.child:SetHeight(height)
  panel.text:SetHeight(height)
end

function Reports.SetText(panel, text, status)
  if not panel or not panel.text then return end
  panel.text:SetText(text or "")
  panel.status = status or "INFO"
  SetHeightForText(panel)
  if panel.scroll then panel.scroll:SetVerticalScroll(0) end
end

function Reports.Clear(panel, emptyText)
  Reports.SetText(panel, emptyText or "No report has been generated.", "INFO")
end

function Reports.FocusForCopy(panel)
  if not panel or not panel.text then return end
  panel.text:SetFocus()
  panel.text:HighlightText()
end

function Reports.Create(parent, options)
  options = options or {}
  local panel = CreateFrame("Frame", nil, parent)
  panel.minimumHeight = options.minimumHeight or 100
  panel.lineHeight = options.lineHeight or 15

  if options.backdrop then options.backdrop(panel, options.color) end

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", 8, -7)
  title:SetText(options.title or "Report")
  if options.titleColor then title:SetTextColor(unpack(options.titleColor)) end
  panel.title = title

  local clear = options.button and options.button(panel, "Clear", 54, 18, function()
    Reports.Clear(panel, options.emptyText)
    if options.onClear then options.onClear(panel) end
  end, "Clear this report")
  if clear then clear:SetPoint("TOPRIGHT", -66, -5) end

  local copy = options.button and options.button(panel, "Copy", 54, 18, function()
    Reports.FocusForCopy(panel)
  end, "Select the report text, then press Ctrl+C")
  if copy then copy:SetPoint("TOPRIGHT", -7, -5) end

  local scroll = CreateFrame("ScrollFrame", options.globalName, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 8, -28)
  scroll:SetPoint("BOTTOMRIGHT", -28, 8)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(math.max(0, self:GetVerticalScroll() - delta * 45))
  end)
  panel.scroll = scroll

  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(options.textWidth or 300)
  child:SetHeight(panel.minimumHeight)
  scroll:SetScrollChild(child)
  panel.child = child

  local text = CreateFrame("EditBox", nil, child)
  text:SetPoint("TOPLEFT", 0, 0)
  text:SetWidth(options.textWidth or 300)
  text:SetHeight(panel.minimumHeight)
  text:SetMultiLine(true)
  text:SetAutoFocus(false)
  text:SetFontObject(options.fontObject or GameFontHighlightSmall)
  text:SetTextColor(0.925, 0.940, 0.960, 1)
  text:SetScript("OnEscapePressed", function(self) self:HighlightText(0,0); self:ClearFocus() end)
  panel.text = text

  Reports.Clear(panel, options.emptyText)
  return panel
end
