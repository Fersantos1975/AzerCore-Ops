local ADDON = ...

-- AzerCore Ops Platform 0.5.1-alpha1-target-quest-log
-- Target: WoW 3.3.5a / AzerothCore. All server commands live here so that
-- branch-specific command names can be changed without touching the UI.
local CMD = {
  revive = ".revive", repair = ".gear repair", summon = ".summon",
  appear = ".appear", combatStop = ".combatstop", save = ".save",
  npcInfo = ".npc info", npcKill = ".die", npcRespawn = ".respawn",
  npcMove = ".npc move", npcNear = ".npc near", npcAdd = ".npc add %d",
  npcDelete = ".npc delete",
  questLookup = ".lookup quest %s", questStatus = ".quest status %d",
  questAdd = ".quest add %d", questComplete = ".quest complete %d",
  questReward = ".quest reward %d", questRemove = ".quest remove %d",
  gps = ".gps", tele = ".tele %s", itemLookup = ".lookup item %s",
  itemAdd = ".additem %d %d", itemRemove = ".additem %d -%d",
  instanceList = ".instance listbinds",
  instanceUnbind = ".instance unbind %s %d",
  instanceUnbindAll = ".instance unbind all",
  auditSearch = ".azercoreops instance search %s",
  auditGroup = ".azercoreops instance audit %d %d",
  questSearch = ".azercoreops quest search %s",
  questInfo = ".azercoreops quest info %d",
  questAudit = ".azercoreops quest audit %d",
  questLog = ".azercoreops quest log",
  version = ".azercoreops version",
}

local DS = AzerCoreOpsDesign
local Platform = AzerCoreOpsPlatform
local C = {
  bg=DS.Colors.Background,
  panel=DS.Colors.Surface,
  border=DS.Colors.Border,
  button=DS.Colors.Button,
  hover=DS.Colors.ButtonHover,
  selected=DS.Colors.ButtonSelected,
  gold=DS.Colors.Diagnose,
  white=DS.Colors.Text,
  red=DS.Colors.Danger,
  inspect=DS.Colors.Inspect,
  diagnose=DS.Colors.Diagnose,
  resolve=DS.Colors.Resolve,
  operate=DS.Colors.Operate,
  muted=DS.Colors.Muted,
}

local main, mini, minimapButton, content, statusText, optionsPanel
local tabs, pages, activeTab = {}, {}, "Dashboard"
local lookup = { kind=nil, expires=0, results={} }
local questIdBox, questSearchBox, itemIdBox
local activeInput
local questUI={results={},rows={},info=nil,chain={},detailText=nil,chainText=nil,chainScroll=nil,chainChild=nil,summary=nil,
  auditMembers={},auditActive=false,auditQuest=nil,detailScroll=nil,detailChild=nil,posts={},postText=nil,postChild=nil,
  history={},historyIndex=0,resultOffset=0,auditFilter="ALL",auditText=nil,auditChild=nil,questIdInternal=false,contextName=nil,contextKind="SELF",contextLabel=nil,lockedQuestId=nil,lockedQuestTitle=nil,activeWorkspace="DATABASE",targetQuestText=nil,targetQuestScroll=nil,targetQuestChild=nil,lockedLabel=nil,
  targetLogEntries={},targetLogActive=false,targetLogLoading=false,targetLogPlayer=nil,targetLogError=nil}
local compatUI={data=nil,text=nil,informationText=nil,received={}}
local instanceUI={my={},target={},captureUntil=0,myRows={},targetRows={},myOffset=0,targetOffset=0,mapBox=nil,diffBox=nil,targetLabel=nil}
local auditUI={search={},members={},searchRows={},memberRows={},filterButtons={},filtered={},mapBox=nil,diffBox=nil,summary=nil,scroll=nil,scrollChild=nil,horizontal=nil,filter="ALL",lastMap=nil,lastDifficulty=nil,reportEdit=nil}
local exportFrame, exportEdit, exportActionButton
local shareFrame, shareText, courierUI
local ShowSelectableReport
local defaults={
  startMinimized=true,showMinimap=true,showMini=true,mbfCompatibility=true,scale=1,
  confirmCommands=true,hideAuditChat=true,defaultDifficulty=0,
  auditTooltips=true,wrapAuditReasons=true,mouseWheelAudit=true,problemsFirst=false,
  rememberAuditFilter=true,autoReaudit=false,confirmResetSelected=true,confirmResetAll=true,
  warnNoTarget=true,compactAuditRows=false,auditFontSize=10,shiftClickInsert=true,
}
local ADDON_VERSION="0.5.1-alpha1-target-quest-log"
local PROTOCOL_VERSION="1"
local TESTED_CORE="ceeb3116ebed"
local TESTED_PLAYERBOTS="3fa1c1e49f8f"

local function Settings()
  AzerCoreOpsDB=AzerCoreOpsDB or {}
  AzerCoreOpsDB.settings=AzerCoreOpsDB.settings or {}
  for key,value in pairs(defaults) do
    if AzerCoreOpsDB.settings[key]==nil then
      AzerCoreOpsDB.settings[key]=value
    end
  end
  return AzerCoreOpsDB.settings
end

local function Print(msg, errorColor)
  DEFAULT_CHAT_FRAME:AddMessage((errorColor and "|cffff5555AzerCore Ops|r: " or "|cff33ff99AzerCore Ops|r: ") .. tostring(msg))
end

local function AppendQuestPost(msg, kind)
  if not msg or msg=="" then return end
  questUI.posts=questUI.posts or {}
  table.insert(questUI.posts,1,{time=date("%H:%M:%S"),kind=kind or "STATUS",text=tostring(msg)})
  while #questUI.posts>80 do table.remove(questUI.posts) end
  if questUI.postText then
    local lines={}
    for i=#questUI.posts,1,-1 do
      local r=questUI.posts[i]
      table.insert(lines,string.format("[%s] %-8s %s",r.time,r.kind,r.text))
    end
    questUI.postText:SetText(table.concat(lines,"\n"))
    if questUI.postChild then
      local h=math.max(84,#lines*14+8)
      questUI.postChild:SetHeight(h); questUI.postText:SetHeight(h)
    end
  end
end

local function SetStatus(msg, bad)
  if statusText then
    statusText:SetText(msg or "Ready")
    statusText:SetTextColor(unpack(bad and C.red or C.white))
  end
  AppendQuestPost(msg or "Ready", bad and "ERROR" or "STATUS")
end

local function SendCommand(cmd)
  if not cmd or cmd == "" then return end
  SendChatMessage(cmd, "SAY")
  AzerCoreOpsDB.history = AzerCoreOpsDB.history or {}
  table.insert(AzerCoreOpsDB.history, 1, cmd)
  while #AzerCoreOpsDB.history > 20 do table.remove(AzerCoreOpsDB.history) end
  AppendQuestPost(cmd,"COMMAND")
  SetStatus("Sent: " .. cmd)
end

local function Backdrop(f, color)
  f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  f:SetBackdropColor(unpack(color or C.bg)); f:SetBackdropBorderColor(unpack(C.border))
end

local function Label(parent, text, template)
  local x=parent:CreateFontString(nil,"OVERLAY",template or "GameFontNormal")
  x:SetText(text); x:SetTextColor(unpack(C.gold)); return x
end

local function Button(parent, text, w, h, click, tip)
  local b=CreateFrame("Button",nil,parent); b:SetWidth(w); b:SetHeight(h); b:SetText(text)
  b:SetNormalFontObject(GameFontNormalSmall); b:SetHighlightFontObject(GameFontHighlightSmall)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
  b:SetBackdropColor(unpack(C.button)); b:SetBackdropBorderColor(unpack(C.border)); b:SetScript("OnClick",click)
  b:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover)); if tip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(text,1,.82,0); GameTooltip:AddLine(tip,1,1,1,true); GameTooltip:Show() end end)
  b:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(C.button)); GameTooltip:Hide() end)
  return b
end

local function Edit(parent, w, numeric)
  -- InputBoxTemplate only draws separate left/right caps on some 3.3.5a
  -- clients. A custom backdrop gives the field a clear, complete border.
  local e=CreateFrame("EditBox",nil,parent); e:SetWidth(w); e:SetHeight(24); e:SetAutoFocus(false)
  e:SetFontObject(ChatFontNormal); e:SetTextInsets(7,7,0,0)
  e:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
  e:SetBackdropColor(0.035,0.04,0.05,1); e:SetBackdropBorderColor(unpack(C.border))
  e:SetTextColor(unpack(C.white))
  if numeric then e:SetNumeric(true) end
  e.azerCoreOpsNumeric=numeric and true or false
  e:SetScript("OnEditFocusGained",function(self) activeInput=self; self:SetBackdropBorderColor(unpack(C.gold)); self:HighlightText() end)
  e:SetScript("OnEditFocusLost",function(self) if activeInput==self then activeInput=nil end; self:SetBackdropBorderColor(unpack(C.border)); self:HighlightText(0,0) end)
  e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end); return e
end

local originalInsertLink=ChatEdit_InsertLink
local function InsertAzerCoreOpsLink(link)
  if not activeInput or not activeInput:HasFocus() or not Settings().shiftClickInsert then return false end
  local linkType,id=link:match("|H([^:|]+):([^:|]+)")
  local player=link:match("|Hplayer:([^:|]+)")
  if activeInput.azerCoreOpsExpected and linkType~=activeInput.azerCoreOpsExpected then
    SetStatus("This field accepts "..activeInput.azerCoreOpsExpected.." links, not "..tostring(linkType or "unknown").." links.",true)
    return true
  end
  if activeInput.azerCoreOpsNumeric then
    local numericId=tonumber(id)
    if not numericId then SetStatus("This link does not contain a numeric ID.",true); return true end
    activeInput:SetText(tostring(numericId)); activeInput:HighlightText(); SetStatus("Inserted "..tostring(linkType).." ID "..numericId); return true
  end
  if player then activeInput:SetText(player); activeInput:HighlightText(); SetStatus("Inserted player "..player); return true end
  if activeInput.azerCoreOpsPlain then
    local label=link:match("|h%[([^%]]+)%]|h") or link
    activeInput:SetText(label); activeInput:HighlightText(); SetStatus("Inserted "..tostring(linkType or "game").." name"); return true
  end
  activeInput:Insert(link); SetStatus("Inserted "..tostring(linkType or "game").." link"); return true
end

if originalInsertLink then
  ChatEdit_InsertLink=function(link)
    if InsertAzerCoreOpsLink(link) then return true end
    return originalInsertLink(link)
  end
end

local function PositiveId(box, label)
  local n=tonumber(box:GetText() or "")
  if not n or n < 1 or n ~= math.floor(n) then SetStatus("Enter a valid "..label.." ID.",true); return end
  return n
end

local function NonEmpty(box, label)
  local s=(box:GetText() or ""):match("^%s*(.-)%s*$")
  if s=="" then SetStatus("Enter "..label..".",true); return end
  return s
end

local pendingCommand, pendingAfter
StaticPopupDialogs["AZERCORE_OPS_CONFIRM"]={text="Execute this command?\n%s",button1=YES,button2=NO,timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function() if pendingCommand then SendCommand(pendingCommand); pendingCommand=nil; local after=pendingAfter; pendingAfter=nil; if after then after() end end end,
  OnCancel=function() pendingCommand=nil; pendingAfter=nil end}
local function Confirm(cmd, enabled, after)
  if enabled==nil then enabled=Settings().confirmCommands end
  if not enabled then SendCommand(cmd); if after then after() end; return end
  pendingCommand=cmd; pendingAfter=after; StaticPopup_Show("AZERCORE_OPS_CONFIRM",cmd)
end

local function After(seconds,callback)
  local elapsed=0; local timer=CreateFrame("Frame")
  timer:SetScript("OnUpdate",function(self,delta) elapsed=elapsed+delta; if elapsed>=seconds then self:SetScript("OnUpdate",nil); callback() end end)
end

local function SavePoint(f,prefix)
  local point,_,rel,x,y=f:GetPoint(); AzerCoreOpsDB[prefix.."Point"]=point; AzerCoreOpsDB[prefix.."Rel"]=rel; AzerCoreOpsDB[prefix.."X"]=x; AzerCoreOpsDB[prefix.."Y"]=y
end
local function Movable(f,prefix)
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function(self) self._dragged=true; self:StartMoving() end)
  f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); SavePoint(self,prefix) end)
end
local function RestorePoint(f,prefix,point,x,y)
  f:SetPoint(AzerCoreOpsDB[prefix.."Point"] or point,UIParent,AzerCoreOpsDB[prefix.."Rel"] or point,AzerCoreOpsDB[prefix.."X"] or x,AzerCoreOpsDB[prefix.."Y"] or y)
end

local function TargetCreatureEntry()
  local guid=UnitGUID("target")
  if not guid then return nil,"Select a creature first." end
  if UnitIsPlayer("target") then return nil,"The selected target is a player." end
  -- 3.3.5 creature GUID: 0xF130 + 6 hex entry digits + 6 hex counter digits.
  if not guid:find("^0xF130") and not guid:find("^0xF140") then return nil,"Target is not a creature or pet." end
  local id=tonumber(guid:sub(7,12),16)
  if not id or id<1 then return nil,"Could not read the creature entry." end
  return id
end

local function AddField(parent,label,x,y,w,numeric)
  local l=Label(parent,label,"GameFontNormalSmall"); l:SetPoint("TOPLEFT",x,y)
  local e=Edit(parent,w,numeric); e:SetPoint("TOPLEFT",x,y-18); return e
end

local function AddCommandGrid(parent, defs, startY)
  for i,d in ipairs(defs) do
    local col=(i-1)%3; local row=math.floor((i-1)/3)
    local b=Button(parent,d[1],150,28,d[2],d[3]); b:SetPoint("TOPLEFT",18+col*164,startY-row*40)
  end
end

local function NewPage(name)
  local p=CreateFrame("Frame",nil,content); p:SetAllPoints(content); p:Hide(); pages[name]=p; return p
end

local function SelectTab(name)
  activeTab=name; AzerCoreOpsDB.activeTab=name
  for n,p in pairs(pages) do if n==name then p:Show() else p:Hide() end end
  for n,b in pairs(tabs) do b:SetBackdropColor(unpack(n==name and C.selected or C.button)) end
  SetStatus(name=="Teleport" and "Movement workspace" or name.." workspace")
end

local function BuildCharacter()
  local p=NewPage("Character"); local h=Label(p,"Character commands"); h:SetPoint("TOPLEFT",18,-18)
  AddCommandGrid(p,{
    {"Revive",function() SendCommand(CMD.revive) end,"Revive selected player or yourself"},
    {"Repair",function() SendCommand(CMD.repair) end,"Repair selected player's equipment"},
    {"Summon",function() SendCommand(CMD.summon) end,"Summon selected player"},
    {"Appear",function() SendCommand(CMD.appear) end,"Teleport to selected player"},
    {"Combat Stop",function() SendCommand(CMD.combatStop) end,"Stop combat for target or yourself"},
    {"Save",function() SendCommand(CMD.save) end,"Save your character"},
  },-48)
  local note=Label(p,"Commands use your current target when AzerothCore supports target selection.","GameFontHighlightSmall"); note:SetTextColor(unpack(C.white)); note:SetPoint("TOPLEFT",18,-145)
end

local function BuildNPC()
  local p=NewPage("NPC"); local h=Label(p,"Creature commands"); h:SetPoint("TOPLEFT",18,-18)
  local entry=AddField(p,"Creature entry ID",18,-56,145,true)
  Button(p,"Use Target",120,24,function() local id,err=TargetCreatureEntry(); if not id then SetStatus(err,true); return end; entry:SetText(id); SetStatus("Creature entry: "..id) end,"Read entry ID from selected creature"):SetPoint("TOPLEFT",180,-73)
  Button(p,"Add NPC",120,24,function() local id=PositiveId(entry,"creature"); if id then SendCommand(string.format(CMD.npcAdd,id)) end end,"Spawn creature at your position"):SetPoint("TOPLEFT",315,-73)
  AddCommandGrid(p,{
    {"NPC Info",function() SendCommand(CMD.npcInfo) end,"Show selected creature information"},
    {"Kill",function() SendCommand(CMD.npcKill) end,"Kill selected unit"},
    {"Respawn",function() SendCommand(CMD.npcRespawn) end,"Respawn selected creature"},
    {"Move Here",function() Confirm(CMD.npcMove) end,"Move selected spawn to your position"},
    {"NPC Near",function() SendCommand(CMD.npcNear) end,"List nearby creature spawns"},
    {"Delete NPC",function() Confirm(CMD.npcDelete) end,"Permanently delete selected creature spawn"},
  },-130)
end

local resultRows={quest={},item={}}
local function RenderResults()
  local rows=resultRows[lookup.kind] or {}
  for i,row in ipairs(rows) do
    local r=lookup.results[i]
    if r then
      row.id=r.id; row.kind=lookup.kind
      row.label:SetText(r.link or r.title or (lookup.kind.." "..r.id))
      row:Show()
    else
      row.id=nil; row.label:SetText(""); row:Hide()
    end
  end
end
local function StoreLookupResult(id,title,link,suffix)
  id=tonumber(id)
  if not id or id<1 then return end
  for _,r in ipairs(lookup.results) do if r.id==id then return end end
  if #lookup.results>=5 then return end
  title=(title or ""):gsub("^%[",""):gsub("%]$","")
  suffix=(suffix or ""):match("^%s*(.-)%s*$")
  local display=link
  if not display or display=="" then
    display=tostring(id).." - ["..title.."]"
    if suffix~="" then display=display.." "..suffix end
  end
  table.insert(lookup.results,{id=id,title=title,link=display})
  RenderResults()
  SetStatus(#lookup.results.." "..lookup.kind.." result(s) captured")
end
local function BeginLookup(kind,cmd)
  lookup.kind=kind; lookup.results={}; lookup.expires=GetTime()+5; RenderResults(); SendCommand(cmd); SetStatus("Collecting "..kind.." results for 5 seconds...")
end
local function AddResultsPanel(parent,kind)
  local box=CreateFrame("Frame",nil,parent); box:SetPoint("TOPLEFT",18,-148); box:SetWidth(478); box:SetHeight(142); Backdrop(box,C.panel)
  local title=Label(box,"Lookup results — click one to select it","GameFontNormalSmall"); title:SetPoint("TOPLEFT",9,-8)
  for i=1,5 do
    local row=Button(box,"",458,20,function(self)
      if self.kind=="quest" then questIdBox:SetText(self.id) else itemIdBox:SetText(self.id) end
      SetStatus("Selected "..self.kind.." ID "..self.id)
    end)
    -- Use our own FontString: Button:SetText is unreliable for dynamically
    -- updated text on some unmodified 3.3.5a clients.
    row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.label:SetPoint("LEFT",7,0); row.label:SetPoint("RIGHT",-7,0)
    row.label:SetJustifyH("LEFT"); row.label:SetTextColor(unpack(C.gold))
    row:SetPoint("TOPLEFT",9,-27-(i-1)*21); row:Hide(); resultRows[kind][i]=row
  end
end

local function FactionText(faction)
  if faction=="ALLIANCE" then return "|cff5599ffAlliance|r" end
  if faction=="HORDE" then return "|cffff5555Horde|r" end
  if faction=="BOTH" then return "|cffffff55Both|r" end
  return "|cffaaaaaaUnknown|r"
end

local function EligibilityText(value)
  if value=="AVAILABLE" then return "|cff55ff55AVAILABLE|r" end
  if value=="BLOCKED" then return "|cffff5555BLOCKED|r" end
  if value=="REWARDED" then return "|cffaaaaaaREWARDED|r" end
  if value=="COMPLETE" then return "|cff55ff55COMPLETE|r" end
  if value=="ACTIVE" then return "|cffffff55ACTIVE|r" end
  return "|cffffff55"..tostring(value or "UNKNOWN").."|r"
end

local function CleanQuestValue(value, fallback)
  local text=tostring(value or "")
  if text=="" or text:upper()=="NONE" or text:upper()=="NOT REPORTED" then return fallback or "None" end
  return text
end

local function IsQuestPositive(value)
  local v=tostring(value or ""):upper()
  return v=="AVAILABLE" or v=="ACTIVE" or v=="COMPLETE" or v=="REWARDED" or v=="PASS" or v=="ELIGIBLE"
end

local function TargetQuestReport(q, formatted)
  if not q then return nil end
  local status=tostring(q.status or "NONE"):upper()
  local eligibility=tostring(q.eligibility or "UNKNOWN"):upper()
  local reason=CleanQuestValue(q.reason,"No blocking reason was reported by the server module.")
  local title=q.title or questUI.lockedQuestTitle or "Locked Quest"
  local id=q.id or questUI.lockedQuestId or "?"
  local player=q.player or UnitName("target") or "Unknown"
  local goodStatus=IsQuestPositive(status)
  local eligible=IsQuestPositive(eligibility)
  local blocked=eligibility=="BLOCKED" or eligibility=="INELIGIBLE" or eligibility=="FAIL"

  local function heading(text)
    return formatted and ("|cffffd100"..text.."|r") or text
  end
  local function value(text)
    return formatted and ("|cffffffff"..text.."|r") or text
  end
  local function positive(text)
    return formatted and ("|cff55ff55"..text.."|r") or text
  end
  local function warning(text)
    return formatted and ("|cffffff55"..text.."|r") or text
  end
  local function negative(text)
    return formatted and ("|cffff5555"..text.."|r") or text
  end

  local lines={}
  table.insert(lines,heading(title))
  table.insert(lines,string.format("Quest ID: %s",value(tostring(id))))
  table.insert(lines,string.format("Inspected player: %s",value(player)))
  table.insert(lines,"")

  table.insert(lines,heading("CURRENT STATUS"))
  if status=="REWARDED" then
    table.insert(lines,positive("Rewarded — the player has already completed and received the reward."))
  elseif status=="COMPLETE" then
    table.insert(lines,positive("Complete — all objectives are complete and the quest is ready to turn in."))
  elseif status=="ACTIVE" then
    table.insert(lines,warning("Active — the quest is currently in the player's quest log."))
  elseif eligible and not blocked then
    table.insert(lines,positive("Available — the player meets the reported requirements and may accept the quest."))
  elseif blocked then
    table.insert(lines,negative("Blocked — the player does not currently meet one or more requirements."))
  else
    table.insert(lines,warning("Not active — the quest is not currently in the player's quest log."))
  end
  table.insert(lines,"")

  table.insert(lines,heading("WHY"))
  table.insert(lines,value(reason))
  table.insert(lines,"")

  table.insert(lines,heading("REQUIREMENTS"))
  local minLevel=CleanQuestValue(q.min,"Not reported")
  local questLevel=CleanQuestValue(q.level,"Not reported")
  local faction=CleanQuestValue(q.faction,"Unknown")
  local reputation=CleanQuestValue(q.reputation,"None")
  local items=CleanQuestValue(q.items,"None")
  table.insert(lines,string.format("Level: %s  |  Minimum: %s",value(questLevel),value(minLevel)))
  table.insert(lines,string.format("Faction: %s",value(faction)))
  table.insert(lines,string.format("Reputation: %s",value(reputation)))
  table.insert(lines,string.format("Required items: %s",value(items)))
  table.insert(lines,string.format("Quest type: %s  |  Repeatable: %s",value(CleanQuestValue(q.type,"Normal")),value(CleanQuestValue(q.repeatable,"No"))))
  table.insert(lines,"")

  table.insert(lines,heading("NEXT STEP"))
  if status=="REWARDED" then
    table.insert(lines,"No action is required. The quest has already been rewarded.")
  elseif status=="COMPLETE" then
    table.insert(lines,"Return to the quest ender and turn in the quest.")
  elseif status=="ACTIVE" then
    table.insert(lines,"Continue the quest objectives, then use Refresh Target to check the updated state.")
  elseif eligible and not blocked then
    table.insert(lines,"The player may accept the quest from a valid quest starter.")
  else
    table.insert(lines,"Resolve the reported blocker, then use Refresh Target to inspect the quest again.")
  end
  table.insert(lines,"")

  table.insert(lines,heading("GM ACTIONS"))
  if status=="REWARDED" then
    table.insert(lines,"Normally no GM action is needed. Use Remove Quest only when correcting invalid character data.")
  elseif status=="ACTIVE" then
    table.insert(lines,"Use Complete Quest or Reward Quest only when support intervention is justified.")
  elseif blocked then
    table.insert(lines,"Review the blocker before using Add Quest. Manual addition may bypass intended progression rules.")
  else
    table.insert(lines,"Add Quest is available when a justified support case requires manual intervention.")
  end
  table.insert(lines,"Refresh Target after any GM command to verify the final state.")
  return lines
end

local function TargetQuestLogLines(formatted)
  local function heading(text) return formatted and ("|cffffd100"..text.."|r") or text end
  local function statusText(status)
    status=tostring(status or "UNKNOWN"):upper()
    if not formatted then return status end
    if status=="COMPLETE" then return "|cff55ff55COMPLETE|r" end
    if status=="FAILED" then return "|cffff5555FAILED|r" end
    if status=="ACTIVE" then return "|cffffff55ACTIVE|r" end
    return "|cffaaaaaa"..status.."|r"
  end

  local player=questUI.targetLogPlayer or UnitName("target") or "Unknown"
  local entries=questUI.targetLogEntries or {}
  local lines={heading("TARGET QUEST LOG"),"Player: "..player,"Quests: "..#entries,""}
  if questUI.targetLogError then
    table.insert(lines,formatted and ("|cffff5555"..questUI.targetLogError.."|r") or questUI.targetLogError)
  elseif questUI.targetLogLoading then
    table.insert(lines,"Loading the selected player's quest log...")
  elseif #entries==0 then
    table.insert(lines,"The selected player's quest log is empty.")
  else
    for _,entry in ipairs(entries) do
      table.insert(lines,string.format("%02d. %s  %s",tonumber(entry.slot) or 0,statusText(entry.status),entry.title or "Unknown quest"))
      table.insert(lines,string.format("    Quest ID: %s  |  Level: %s  |  Minimum: %s",entry.id or "?",entry.level or "?",entry.min or "?"))
      table.insert(lines,string.format("    Type: %s  |  Faction: %s",entry.type or "Unknown",entry.faction or "UNKNOWN"))
      table.insert(lines,"")
    end
  end
  return lines
end

local function QuestAuditVisible(r)
  local filter=questUI.auditFilter or "ALL"
  if filter=="ALL" then return true end
  local result=tostring(r.result or "FAIL"):upper()
  if filter=="FAIL" then return result~="PASS" and result~="WARN" end
  return result==filter
end

local function UpdateQuestContextLabel()
  local me=UnitName("player") or "Self"
  local name=questUI.contextName or me
  local kind=questUI.contextKind=="TARGET" and "Target" or "Self"
  if questUI.contextLabel then
    questUI.contextLabel:SetText(string.format("Current context: |cffffffff%s|r |cffaaaaaa(%s)|r",name,kind))
  end
end

local function RenderQuest()
  UpdateQuestContextLabel()
  local offset=questUI.resultOffset or 0
  for i,row in ipairs(questUI.rows) do
    local r=questUI.results[offset+i]
    if r then
      row.id=tonumber(r.id); row.title=r.title
      row.text:SetText(string.format("%s  [%s] %s\n%s  •  level %s",r.id or "?",FactionText(r.faction),r.title or "Unknown",EligibilityText(r.eligibility),r.min or "?"))
      row:Show()
    else row.id=nil; row.title=nil; row:Hide() end
  end

  local detailLines={}
  if questUI.info then
    local q=questUI.info
    table.insert(detailLines,string.format("|cffffd100%s|r",q.title or "Unknown quest"))
    table.insert(detailLines,string.format("Quest ID: |cffffffff%s|r",q.id or "?"))
    table.insert(detailLines,string.format("Checked player: |cffffffff%s|r",q.player or UnitName("player") or "Unknown"))
    table.insert(detailLines,"")
    table.insert(detailLines,"Faction: "..FactionText(q.faction))
    table.insert(detailLines,"Eligibility: "..EligibilityText(q.eligibility))
    table.insert(detailLines,"Reason: |cffffffff"..(q.reason or "Unknown").."|r")
    table.insert(detailLines,"")
    table.insert(detailLines,string.format("Minimum level: |cffffffff%s|r",q.min or "?"))
    table.insert(detailLines,string.format("Quest level: |cffffffff%s|r",q.level or "?"))
    table.insert(detailLines,string.format("Type: |cffffffff%s|r",q.type or "Normal"))
    table.insert(detailLines,string.format("Repeatable: |cffffffff%s|r",q.repeatable or "no"))
    table.insert(detailLines,string.format("Character status: |cffffffff%s|r",q.status or "NONE"))
    table.insert(detailLines,string.format("Required reputation: |cffffffff%s|r",q.reputation or "None"))
    table.insert(detailLines,string.format("Required items: |cffffffff%s|r",q.items or "None"))
    table.insert(detailLines,string.format("Starts at: |cffffffff%s|r",q.starters or "Not listed"))
    table.insert(detailLines,string.format("Ends at: |cffffffff%s|r",q.enders or "Not listed"))
    table.insert(detailLines,"")
    table.insert(detailLines,"|cffffd100Quest chain|r")
    if #questUI.chain==0 then table.insert(detailLines,"No linked prerequisite/next quests reported.") end
    for _,r in ipairs(questUI.chain) do
      local arrow=r.direction=="NEXT" and "->" or "<-"
      local state=r.status=="REWARDED" and "|cff55ff55[REWARDED]|r" or (r.status=="COMPLETE" and "|cff55ff55[COMPLETE]|r" or (r.status=="ACTIVE" and "|cffffff55[ACTIVE]|r" or (r.eligibility=="AVAILABLE" and "|cff55ff55[AVAILABLE]|r" or "|cffff7777[BLOCKED]|r")))
      table.insert(detailLines,string.format("%s %s %s [%s]",state,arrow,r.title or "Unknown",r.id or "?"))
      if r.reason and r.reason~="" then table.insert(detailLines,"   "..r.reason) end
    end
  else
    table.insert(detailLines,"Select a search result, enter a partial title, or enter a Quest ID and press Search.")
  end
  if questUI.detailText then
    questUI.detailText:SetText(table.concat(detailLines,"\n"))
    local h=math.max(180,#detailLines*15+12); if questUI.detailChild then questUI.detailChild:SetHeight(h) end; questUI.detailText:SetHeight(h)
  end

  local auditLines={}
  local pass,warn,fail=0,0,0
  for _,r in ipairs(questUI.auditMembers) do
    local result=tostring(r.result or "FAIL"):upper()
    if result=="PASS" then pass=pass+1 elseif result=="WARN" then warn=warn+1 else fail=fail+1 end
    if QuestAuditVisible(r) then
      local mark,color=result=="PASS" and "+" or (result=="WARN" and "!" or "X"), result=="PASS" and "|cff55ff55" or (result=="WARN" and "|cffffff55" or "|cffff5555")
      local memberName=r.name or "Unknown"
      local contextMark=(questUI.contextName and memberName==questUI.contextName) and " |cffffd100< TARGET CONTEXT >|r" or ""
      table.insert(auditLines,string.format("%s[%s %s]|r  |cffffffff%s|r%s",color,mark,result,memberName,contextMark))
      table.insert(auditLines,string.format("Status: %s",r.status or "NONE"))
      table.insert(auditLines,"Reason: "..(r.reason or "No reason"))
      table.insert(auditLines,"")
    end
  end
  if #questUI.auditMembers==0 then table.insert(auditLines,questUI.auditActive and "Waiting for group results..." or "Run Audit Group to analyse the selected quest for your party or raid.") end
  if questUI.auditText then
    questUI.auditText:SetText(table.concat(auditLines,"\n")); local h=math.max(180,#auditLines*15+12); if questUI.auditChild then questUI.auditChild:SetHeight(h) end; questUI.auditText:SetHeight(h)
  end
  if questUI.auditSummary then questUI.auditSummary:SetText(string.format("+ %d   ! %d   X %d",pass,warn,fail)) end
  if questUI.summary then questUI.summary:SetText(#questUI.results.." result(s)") end

  if questUI.targetQuestText then
    local lines={}
    if questUI.targetLogActive then
      if questUI.targetBodyTitle then questUI.targetBodyTitle:SetText("TARGET QUEST LOG") end
      if questUI.targetHintText then questUI.targetHintText:SetText("Complete active quest list for "..(questUI.targetLogPlayer or "the selected player")..".") end
      for _,line in ipairs(TargetQuestLogLines(true)) do table.insert(lines,line) end
    elseif not questUI.lockedQuestId then
      if questUI.targetBodyTitle then questUI.targetBodyTitle:SetText("LOCKED QUEST IN TARGET CONTEXT") end
      table.insert(lines,"No quest is locked.")
      table.insert(lines,"")
      table.insert(lines,"Select a quest from Quest Explorer first.")
    elseif not (UnitExists("target") and UnitIsPlayer("target")) then
      if questUI.targetBodyTitle then questUI.targetBodyTitle:SetText("LOCKED QUEST IN TARGET CONTEXT") end
      table.insert(lines,string.format("|cffffd100%s|r  [Quest ID: %d]",questUI.lockedQuestTitle or "Locked Quest",questUI.lockedQuestId))
      table.insert(lines,"")
      table.insert(lines,"Select a player target to inspect this quest in their context.")
    elseif questUI.info and tonumber(questUI.info.id)==tonumber(questUI.lockedQuestId) then
      if questUI.targetBodyTitle then questUI.targetBodyTitle:SetText("LOCKED QUEST IN TARGET CONTEXT") end
      local report=TargetQuestReport(questUI.info,true)
      for _,line in ipairs(report or {}) do table.insert(lines,line) end
    else
      if questUI.targetBodyTitle then questUI.targetBodyTitle:SetText("LOCKED QUEST IN TARGET CONTEXT") end
      table.insert(lines,string.format("|cffffd100%s|r  [Quest ID: %d]",questUI.lockedQuestTitle or "Locked Quest",questUI.lockedQuestId))
      table.insert(lines,"")
      table.insert(lines,"Waiting for the target-context quest inspection...")
    end
    questUI.targetQuestText:SetText(table.concat(lines,"\n"))
    local reportHeight=math.max(220,#lines*15+12)
    questUI.targetQuestText:SetHeight(reportHeight)
    if questUI.targetQuestChild then questUI.targetQuestChild:SetHeight(reportHeight) end
  end
end

local function SetQuestId(value)
  if not questIdBox then return end
  questUI.questIdInternal=true
  questIdBox:SetText(value and tostring(value) or "")
  questUI.questIdInternal=false
end

local function SelectedQuestId()
  if questUI.lockedQuestId then return tonumber(questUI.lockedQuestId) end
  if questUI.info and tonumber(questUI.info.id) then return tonumber(questUI.info.id) end
  if questUI.selectedId then return tonumber(questUI.selectedId) end
end

local function LockQuest(id,title)
  id=tonumber(id)
  if not id then SetStatus("Select a valid quest before locking it.",true); return end
  questUI.lockedQuestId=id
  questUI.lockedQuestTitle=title or (questUI.info and questUI.info.title) or ("Quest "..id)
  questUI.selectedId=id
  SetQuestId(id)
  if questUI.lockedLabel then
    questUI.lockedLabel:SetText(string.format("|cffffd100%s|r\n\n|cffffffffQuest ID:|r |cffaaaaaa%d|r\n|cff55ff55Locked in framework|r",questUI.lockedQuestTitle,id))
  end
  AppendQuestPost(string.format("Locked quest %s [%d].",questUI.lockedQuestTitle,id),"CONTEXT")
end

local function QuestHistory()
  AzerCoreOpsDB.questSearchHistory=AzerCoreOpsDB.questSearchHistory or {}
  questUI.history=AzerCoreOpsDB.questSearchHistory
  return questUI.history
end

local function HistoryQuery(entry)
  if type(entry)=="table" then return tostring(entry.query or entry.title or entry.id or "") end
  return tostring(entry or "")
end

local function PushQuestHistory(value,id,title)
  value=tostring(value or ""):match("^%s*(.-)%s*$")
  if value=="" and not id then return end
  local history=QuestHistory()
  local key=tostring(id or "").."|"..value
  for i=#history,1,-1 do
    local e=history[i]
    local ekey=type(e)=="table" and (tostring(e.id or "").."|"..tostring(e.query or "")) or ("|"..tostring(e))
    if ekey==key then table.remove(history,i) end
  end
  table.insert(history,1,{query=value,id=tonumber(id),title=title})
  while #history>50 do table.remove(history) end
  questUI.historyIndex=0
end

local function UpdateLockedQuestHistory()
  if not questUI.lockedQuestId then return end
  PushQuestHistory(questSearchBox and questSearchBox:GetText() or questUI.lockedQuestTitle,questUI.lockedQuestId,questUI.lockedQuestTitle)
end

local function ShowQuestHistory(delta)
  local history=QuestHistory()
  if #history==0 then SetStatus("Quest search history is empty.",true); return end
  questUI.historyIndex=math.max(1,math.min(#history,(questUI.historyIndex or 0)+delta))
  questSearchBox:SetText(HistoryQuery(history[questUI.historyIndex]))
  questSearchBox:SetFocus(); questSearchBox:HighlightText()
  SetStatus("Saved quest search "..questUI.historyIndex.." of "..#history)
end

local function ShowSavedQuestHistory()
  local history=QuestHistory()
  if #history==0 then SetStatus("Quest search history is empty.",true); return end
  local lines={"AzerCore Ops saved quest searches",""}
  for i,entry in ipairs(history) do
    if type(entry)=="table" then
      table.insert(lines,string.format("%02d. %s%s",i,entry.query or entry.title or "Quest",entry.id and string.format("  [Quest ID: %d]",entry.id) or ""))
    else
      table.insert(lines,string.format("%02d. %s",i,tostring(entry)))
    end
  end
  ShowSelectableReport("Saved quest search history",table.concat(lines,"\n"),"Delete History",function()
    StaticPopup_Show("AZERCORE_OPS_CLEAR_QUEST_HISTORY")
  end)
end

StaticPopupDialogs["AZERCORE_OPS_CLEAR_QUEST_HISTORY"]={
  text="Delete all saved Quest Intelligence search history?\n\nThis cannot be undone.",button1=YES,button2=NO,timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function()
    AzerCoreOpsDB.questSearchHistory={}
    questUI.history=AzerCoreOpsDB.questSearchHistory
    questUI.historyIndex=0
    if exportFrame then exportFrame:Hide() end
    SetStatus("Saved quest search history deleted.")
  end
}

local RequestQuestInfo

local function RunQuestSearch()
  local raw=(questSearchBox:GetText() or ""):match("^%s*(.-)%s*$")
  if raw=="" then SetStatus("Enter a quest title or Quest ID.",true); return end
  PushQuestHistory(raw)
  local numeric=tonumber(raw)
  if numeric and numeric>0 and numeric==math.floor(numeric) then
    questUI.results={}; questUI.resultOffset=0; LockQuest(numeric,"Quest "..numeric); UpdateLockedQuestHistory(); RenderQuest(); RequestQuestInfo(numeric); return
  end
  questUI.results={}; questUI.resultOffset=0; questUI.info=nil; questUI.chain={}; questUI.selectedId=nil; SetQuestId(nil); RenderQuest()
  SendCommand(string.format(CMD.questSearch,raw)); SetStatus("Searching quests by partial title...")
end

local function ClearQuestSearch()
  questSearchBox:SetText(""); SetQuestId(nil); questUI.results={}; questUI.resultOffset=0; questUI.info=nil; questUI.selectedId=nil; questUI.lockedQuestId=nil; questUI.lockedQuestTitle=nil; questUI.chain={}; questUI.auditMembers={}; questUI.auditActive=false
  questUI.targetLogEntries={}; questUI.targetLogActive=false; questUI.targetLogLoading=false; questUI.targetLogPlayer=nil; questUI.targetLogError=nil
  if questUI.lockedLabel then questUI.lockedLabel:SetText("|cffaaaaaaNo quest locked.|r\n\nSelect a quest match to lock it into the framework.") end
  RenderQuest(); SetStatus("Quest workspace cleared.")
end

local function LinkSelectedQuest()
  local id=SelectedQuestId()
  if not id then SetStatus("Select or inspect a quest first.",true); return end
  local title=(questUI.info and questUI.info.title) or (questSearchBox:GetText()~="" and questSearchBox:GetText()) or ("Quest "..id)
  -- Native quest hyperlinks are broken in this client/core combination:
  -- even links shared directly from the Blizzard Quest Log fail on click
  -- because "questID:level" is parsed as one unsigned integer. Use a plain,
  -- portable reference while preserving the title and exact database ID.
  local link=string.format("[%s] (Quest ID: %d)",title,id)
  local chat=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
  if chat then
    chat:Insert(link)
    -- Clicking the addon button can leave the visible chat edit box without
    -- keyboard focus. Reactivate it so the next Enter sends the message.
    if ChatEdit_ActivateChat then ChatEdit_ActivateChat(chat) else chat:SetFocus() end
    if chat.SetCursorPosition then chat:SetCursorPosition(string.len(chat:GetText() or "")) end
    SetStatus("Inserted quest reference. Press Enter to send.")
  else SetStatus("Open a chat input, then press Reference to insert the quest.",true) end
end

RequestQuestInfo=function(id)
  id=tonumber(id)
  if not id then SetStatus("Select a valid quest first.",true); return end
  questUI.targetLogActive=false; questUI.targetLogLoading=false; questUI.targetLogError=nil
  questUI.info=nil; questUI.chain={}; questUI.auditActive=false; questUI.auditMembers={}; questUI.selectedId=id; SetQuestId(id); RenderQuest()
  SendCommand(string.format(CMD.questInfo,id)); SetStatus("Loading locked quest "..id.." details...")
end

local function RunQuestAudit()
  local id=SelectedQuestId()
  if not id then SetStatus("Select or inspect a quest first.",true); return end
  questUI.auditMembers={}; questUI.auditActive=true; questUI.auditQuest=id; questUI.auditFilter="ALL"; RenderQuest()
  SendCommand(string.format(CMD.questAudit,id)); SetStatus("Auditing quest "..id.." for the group...")
end

local function AuditQuestTarget()
  local id=SelectedQuestId()
  if not id then SetStatus("Select or inspect a quest before auditing a player.",true); return end

  local targetExists=UnitExists("target")
  if targetExists and not UnitIsPlayer("target") then
    SetStatus("Audit Target requires a player target. Clear the target to audit yourself.",true)
    return
  end

  local playerName=UnitName("player") or "Self"
  local targetName=targetExists and UnitName("target") or nil
  questUI.contextName=targetName or playerName
  questUI.contextKind=targetName and "TARGET" or "SELF"
  questUI.info=nil
  questUI.chain={}
  questUI.auditMembers={}
  questUI.auditActive=true
  questUI.auditQuest=id
  questUI.auditFilter="ALL"
  UpdateQuestContextLabel()
  RenderQuest()

  AppendQuestPost(string.format("Quest context switched to %s (%s).",questUI.contextName,questUI.contextKind=="TARGET" and "target" or "self"),"CONTEXT")
  SendCommand(string.format(CMD.questInfo,id))
  SendCommand(string.format(CMD.questAudit,id))
  SetStatus(string.format("Auditing quest %d in %s's context...",id,questUI.contextName))
end

local function QuestReportText()
  if not questUI.info and #questUI.auditMembers==0 then return nil end
  local lines={"AzerCore Ops — Quest Intelligence report",string.format("Generated: %s",date("%Y-%m-%d %H:%M:%S")),""}
  if questUI.info then
    local q=questUI.info
    table.insert(lines,string.format("Quest: %s [%s]",q.title or "Unknown",q.id or "?"))
    local ordered={"player","faction","eligibility","reason","min","level","type","repeatable","status","reputation","items","starters","enders"}
    local labels={player="Checked player",faction="Faction",eligibility="Eligibility",reason="Reason",min="Minimum level",level="Quest level",type="Type",repeatable="Repeatable",status="Character status",reputation="Required reputation",items="Required items",starters="Starts at",enders="Ends at"}
    for _,key in ipairs(ordered) do table.insert(lines,string.format("%s: %s",labels[key],q[key] or "Not reported by module")) end
    table.insert(lines,"")
    table.insert(lines,"All module fields")
    local keys={}; for key in pairs(q) do table.insert(keys,key) end; table.sort(keys)
    for _,key in ipairs(keys) do table.insert(lines,string.format("%s: %s",key,tostring(q[key]))) end
  end
  table.insert(lines,"")
  table.insert(lines,"Quest chain")
  if #questUI.chain==0 then table.insert(lines,"No linked quests reported.") end
  for _,r in ipairs(questUI.chain) do table.insert(lines,string.format("%s | %s [%s] | status=%s | eligibility=%s | reason=%s",r.direction or "?",r.title or "Unknown",r.id or "?",r.status or "?",r.eligibility or "?",r.reason or "")) end
  table.insert(lines,"")
  table.insert(lines,"Group analysis")
  if #questUI.auditMembers==0 then table.insert(lines,"No group audit results.") end
  for _,r in ipairs(questUI.auditMembers) do table.insert(lines,string.format("%s | %s | %s | %s",r.result or "?",r.name or "Unknown",r.status or "?",r.reason or "No reason")) end
  return table.concat(lines,"\n")
end

local function QuestDetailsReportText()
  if not questUI.info then return nil end
  local q=questUI.info
  local lines={"AzerCore Ops — Quest information",string.format("Generated: %s",date("%Y-%m-%d %H:%M:%S")),"",string.format("Quest: %s [%s]",q.title or "Unknown",q.id or "?")}
  local keys={}; for key in pairs(q) do table.insert(keys,key) end; table.sort(keys)
  for _,key in ipairs(keys) do table.insert(lines,string.format("%s: %s",key,tostring(q[key]))) end
  table.insert(lines,""); table.insert(lines,"Quest chain")
  if #questUI.chain==0 then table.insert(lines,"No linked quests reported.") end
  for _,r in ipairs(questUI.chain) do table.insert(lines,string.format("%s | %s [%s] | status=%s | eligibility=%s | reason=%s",r.direction or "?",r.title or "Unknown",r.id or "?",r.status or "?",r.eligibility or "?",r.reason or "")) end
  return table.concat(lines,"\n")
end

local function GroupAnalysisReportText()
  if #questUI.auditMembers==0 then return nil end
  local lines={"AzerCore Ops — Quest group analysis",string.format("Generated: %s",date("%Y-%m-%d %H:%M:%S")),"",string.format("Quest ID: %s",SelectedQuestId() or "?")}
  local pass,warn,fail=0,0,0
  for _,r in ipairs(questUI.auditMembers) do
    local result=tostring(r.result or "FAIL"):upper()
    if result=="PASS" then pass=pass+1 elseif result=="WARN" then warn=warn+1 else fail=fail+1 end
    table.insert(lines,string.format("%s | %s | status=%s | reason=%s",result,r.name or "Unknown",r.status or "?",r.reason or "No reason"))
  end
  table.insert(lines,4,string.format("Summary: %d pass, %d warning, %d fail",pass,warn,fail))
  return table.concat(lines,"\n")
end

local function TargetQuestReportText()
  if questUI.targetLogActive then
    if questUI.targetLogLoading then return nil,"Wait for the target quest log to finish loading." end
    return table.concat(TargetQuestLogLines(false),"\n")
  end
  if not questUI.lockedQuestId then return nil,"Select and lock a quest before exporting." end
  if not (UnitExists("target") and UnitIsPlayer("target")) then return nil,"Select a player target before exporting." end
  if not questUI.info or tonumber(questUI.info.id)~=tonumber(questUI.lockedQuestId) then return nil,"Refresh Target and wait for the target-context quest inspection before exporting." end
  local report=TargetQuestReport(questUI.info,false)
  local lines={"AzerCore Ops — Target quest analysis",string.format("Generated: %s",date("%Y-%m-%d %H:%M:%S")),""}
  for _,line in ipairs(report or {}) do table.insert(lines,line) end
  return table.concat(lines,"\n")
end

local function ShowTargetQuestExport()
  local text,err=TargetQuestReportText()
  if not text then SetStatus(err or "Target quest analysis is not ready.",true); return end
  ShowSelectableReport("AzerCore Ops Target quest analysis",text)
end

local function ShowTargetQuestCopy()
  local text,err=TargetQuestReportText()
  if not text then SetStatus(err or "Target quest analysis is not ready.",true); return end
  ShowSelectableReport("Copy target quest analysis",text)
end

local function CourierNormalizeText(text)
  text=tostring(text or "")
  text=text:gsub("\r\n","\n"):gsub("\r","\n")
  return text:match("^%s*(.-)%s*$") or ""
end

local function CourierCurrentReportText()
  if questUI.auditMembers and #questUI.auditMembers>0 and questUI.auditQuest and tonumber(questUI.auditQuest)==tonumber(questUI.lockedQuestId) then
    local group=GroupAnalysisReportText()
    if group and group~="" then return group,"GROUP" end
  end
  local text,err=TargetQuestReportText()
  if text and text~="" then return text,"TARGET" end
  return nil,nil,err or "No quest report is ready."
end

local function CourierChatPrefix(channel,target)
  if channel=="SAY" then return "/s " end
  if channel=="PARTY" then return "/p " end
  if channel=="RAID" then return "/raid " end
  if channel=="GUILD" then return "/g " end
  if channel=="OFFICER" then return "/o " end
  if channel=="WHISPER" then return "/w "..tostring(target or "").." " end
  return ""
end

local function CourierPrepareChat(channel,target,text)
  text=CourierNormalizeText(text):gsub("[\n]+"," | "):gsub("%s+"," ")
  -- In WoW chat, a single pipe starts a colour/link escape sequence.
  -- Courier reports use pipes as plain-text separators, so escape every pipe
  -- before placing the message in Blizzard's chat edit box.
  text=text:gsub("|","||")
  if text=="" then SetStatus("Courier message is empty.",true); return false end
  if channel=="WHISPER" and (not target or target=="") then SetStatus("Target a player before posting a Whisper.",true); return false end
  local prefix=CourierChatPrefix(channel,target)
  local limit=255-string.len(prefix)
  if string.len(text)>limit then text=string.sub(text,1,math.max(1,limit-3)).."..." end
  ChatFrame_OpenChat(prefix..text,DEFAULT_CHAT_FRAME)
  local edit=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
  if edit then
    edit:SetCursorPosition(string.len(edit:GetText() or ""))
    edit:SetFocus()

    -- Blizzard can finish activating its chat edit box one frame after
    -- ChatFrame_OpenChat. Retry focus briefly so Enter works immediately.
    local focusRetry=CreateFrame("Frame")
    local elapsedTotal=0
    focusRetry:SetScript("OnUpdate",function(self,elapsed)
      elapsedTotal=elapsedTotal+(elapsed or 0)
      local active=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
      if active then
        active:SetCursorPosition(string.len(active:GetText() or ""))
        active:SetFocus()
      end
      if elapsedTotal>=0.15 then self:SetScript("OnUpdate",nil); self:Hide() end
    end)

    SetStatus("Courier prepared for "..(channel=="WHISPER" and ("Whisper to "..target) or channel)..". Press Enter in Blizzard chat to send.")
    return true
  end
  SetStatus("Could not activate the Blizzard chat input.",true)
  return false
end

local function EnsureShareFrame()
  if shareFrame then return shareFrame end
  local f=CreateFrame("Frame","AZERCORE_OPS_ShareFrame",UIParent)
  f:SetWidth(720); f:SetHeight(500); f:SetClampedToScreen(true)
  f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(200); f:SetToplevel(true)
  Backdrop(f,C.bg); RestorePoint(f,"share","CENTER",0,0)
  f:SetMovable(true); f:EnableMouse(true); f:Hide(); shareFrame=f
  table.insert(UISpecialFrames,"AZERCORE_OPS_ShareFrame")

  f.locked=true; f.editing=false; f.destination="SAY"; f.message=""; f.reportKind=nil
  f.captured=false; f.postPending=false

  local dragBar=CreateFrame("Frame",nil,f)
  dragBar:SetPoint("TOPLEFT",4,-4); dragBar:SetPoint("TOPRIGHT",-36,-4); dragBar:SetHeight(32)
  dragBar:SetFrameLevel(f:GetFrameLevel()+10); dragBar:EnableMouse(true); dragBar:RegisterForDrag("LeftButton")
  dragBar:SetScript("OnDragStart",function() f:StartMoving() end)
  dragBar:SetScript("OnDragStop",function() f:StopMovingOrSizing(); SavePoint(f,"share") end)

  local title=Label(f,"COURIER","GameFontNormalLarge"); title:SetPoint("TOPLEFT",14,-12)
  local close=Button(f,"X",22,20,function() f:Hide() end,"Close Courier")
  close:SetFrameLevel(f:GetFrameLevel()+12); close:SetPoint("TOPRIGHT",-10,-9)

  local rail=CreateFrame("Frame",nil,f); rail:SetPoint("TOPLEFT",14,-48); rail:SetPoint("BOTTOMLEFT",14,38); rail:SetWidth(166); rail:SetFrameLevel(201); rail:EnableMouse(false); Backdrop(rail,C.panel)
  local railTitle=Label(rail,"COMMANDS","GameFontNormalSmall"); railTitle:SetPoint("TOPLEFT",12,-12)

  local body=CreateFrame("Frame",nil,f); body:SetPoint("TOPLEFT",190,-48); body:SetPoint("BOTTOMRIGHT",-14,38); body:SetFrameLevel(201); body:EnableMouse(false); Backdrop(body,C.panel)
  local msgTitle=Label(body,"MESSAGE","GameFontNormalSmall"); msgTitle:SetPoint("TOPLEFT",12,-12)
  local targetText=body:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); targetText:SetPoint("TOPRIGHT",-12,-14); targetText:SetTextColor(unpack(C.muted)); f.targetText=targetText

  local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_CourierMessageScroll",body,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",10,-36); scroll:SetPoint("BOTTOMRIGHT",-30,38); scroll:SetFrameLevel(210); scroll:EnableMouse(true); scroll:EnableMouseWheel(true)
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(480); child:SetHeight(360); child:SetFrameLevel(211); child:EnableMouse(false); scroll:SetScrollChild(child)
  local edit=CreateFrame("EditBox",nil,child)
  edit:SetPoint("TOPLEFT",4,-4); edit:SetWidth(468); edit:SetHeight(350); edit:SetMultiLine(true); edit:SetAutoFocus(false)
  edit:SetFontObject(ChatFontNormal or GameFontHighlightSmall); edit:SetTextColor(unpack(C.white)); edit:SetTextInsets(6,6,6,6)
  edit:SetFrameLevel(212); edit:EnableMouse(false); edit:EnableKeyboard(false)
  edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  edit:SetScript("OnTextChanged",function(self,userInput)
    local text=self:GetText() or ""; if userInput then f.message=text end
    local lines=1; for _ in text:gmatch("\n") do lines=lines+1 end
    lines=math.max(lines,math.ceil(string.len(text)/64)); local h=math.max(350,lines*15+20)
    self:SetHeight(h); child:SetHeight(h+8)
  end)
  scroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  f.preview=edit

  local status=body:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); status:SetPoint("BOTTOMLEFT",12,14); status:SetPoint("BOTTOMRIGHT",-12,14); status:SetJustifyH("LEFT"); status:SetTextColor(unpack(C.muted)); f.localStatus=status

  local buttons={}
  local allCommandButtons={}
  local function setButtonActive(button,active)
    if not button then return end
    if active then
      button:SetBackdropColor(unpack(C.selected)); button:SetBackdropBorderColor(unpack(C.gold))
    else
      button:SetBackdropColor(unpack(C.button)); button:SetBackdropBorderColor(unpack(C.border))
    end
  end
  local function refreshHighlights()
    for key,b in pairs(buttons) do setButtonActive(b,key==f.destination) end
    setButtonActive(f.captureButton,f.captured)
    setButtonActive(f.editButton,f.editing)
    setButtonActive(f.lockButton,f.locked)
    setButtonActive(f.postButton,f.postPending)
  end
  local function markDestination()
    refreshHighlights()
  end
  local function setLocal(text,bad)
    status:SetText(text or ""); status:SetTextColor(unpack(bad and C.red or C.muted))
  end
  local function refreshTarget()
    local name=UnitExists("target") and UnitName("target") or "None"
    local kind=(UnitExists("target") and UnitIsPlayer("target")) and "Player" or (UnitExists("target") and "Non-player" or "No target")
    targetText:SetText("Target: "..tostring(name).." ("..kind..")")
  end
  local function applyMessage(text,kind,lockIt)
    text=CourierNormalizeText(text)
    f.message=text; f.reportKind=kind
    edit:SetText(text); edit:SetCursorPosition(0); edit:ClearFocus()
    if lockIt~=false then f.locked=true; f.captured=(text~="") end
    f.postPending=false
    f.editing=false; edit:EnableKeyboard(false); edit:EnableMouse(false)
    if f.lockButton then f.lockButton:SetText(f.locked and "Unlock" or "Lock") end
    if f.editButton then f.editButton:SetText("Edit") end
    refreshHighlights()
    setLocal(text~="" and ((f.locked and "Message captured and locked." or "Live message updated.")) or "Message is empty.",text=="")
  end
  local function capture()
    local text,kind,err=CourierCurrentReportText()
    if not text then setLocal(err or "No report is ready.",true); SetStatus(err or "No report is ready.",true); return end
    applyMessage(text,kind,true)
  end
  local function toggleEdit()
    f.editing=not f.editing
    edit:EnableKeyboard(f.editing); edit:EnableMouse(f.editing)
    if f.editing then edit:SetFocus(); edit:SetCursorPosition(string.len(edit:GetText() or "")); f.editButton:SetText("Done"); setLocal("Editing enabled.")
    else f.message=edit:GetText() or ""; edit:ClearFocus(); f.editButton:SetText("Edit"); setLocal("Editing finished; message remains locked.") end
    refreshHighlights()
  end
  local function toggleLock()
    f.locked=not f.locked; f.lockButton:SetText(f.locked and "Unlock" or "Lock")
    f.postPending=false
    if f.locked then setLocal("Message locked. Target changes will not replace it.")
    else f.captured=false; setLocal("Live mode enabled. Target changes will refresh the report."); f:RefreshLive() end
    refreshHighlights()
  end
  local function choose(channel)
    if f.destination~=channel and f.postPending then f.postPending=false end
    f.destination=channel; refreshHighlights(); setLocal((channel=="WHISPER" and "Whisper" or channel).." selected.")
  end
  local function post()
    f.message=edit:GetText() or ""
    local target=nil
    if f.destination=="WHISPER" then
      if not (UnitExists("target") and UnitIsPlayer("target")) then setLocal("Whisper requires a player target.",true); return end
      target=UnitName("target")
    end
    if CourierPrepareChat(f.destination,target,f.message) then
      f.postPending=true
      refreshHighlights()
    end
  end
  local function clear()
    f.message=""; f.reportKind=nil; f.captured=false; f.postPending=false
    f.locked=false
    edit:SetText(""); edit:ClearFocus(); f.editing=false; edit:EnableKeyboard(false); edit:EnableMouse(false); f.editButton:SetText("Edit")
    if f.lockButton then f.lockButton:SetText("Lock") end
    refreshHighlights(); setLocal("Message deleted. Live mode is ready for the next player target.")
  end

  local y=-38
  local function command(label,fn,tip)
    local b=Button(rail,label,140,26,fn,tip); b:SetFrameLevel(220); b:EnableMouse(true); b:RegisterForClicks("LeftButtonUp"); b:SetPoint("TOPLEFT",12,y); table.insert(allCommandButtons,b); y=y-32; return b
  end
  f.captureButton=command("Capture Report",capture,"Capture the current target or group quest report and lock it.")
  f.editButton=command("Edit",toggleEdit,"Toggle message editing.")
  f.lockButton=command("Unlock",toggleLock,"Unlock for live target updates, or lock to preserve the message.")
  y=y-8
  for _,item in ipairs({{"Say","SAY"},{"Party","PARTY"},{"Raid","RAID"},{"Guild","GUILD"},{"Officer","OFFICER"},{"Whisper","WHISPER"}}) do
    local key=item[2]; local b=command(item[1],function() choose(key) end,"Select "..item[1].." as the Blizzard chat destination."); buttons[key]=b
  end
  y=y-8
  f.postButton=command("Post",post,"Prepare this message in Blizzard chat. Press Enter there to send.")
  command("Delete",clear,"Clear the Courier message.")

  function f:RefreshLive()
    refreshTarget()
    if self.locked then return end
    local text,kind=CourierCurrentReportText()
    if text then applyMessage(text,kind,false) else setLocal("Waiting for the current target inspection...") end
  end
  function f:SetCapturedMessage(text,kind)
    refreshTarget(); applyMessage(text,kind,true); refreshHighlights()
  end

  local function senderIsPlayer(sender)
    local player=UnitName("player") or ""
    sender=tostring(sender or "")
    return sender==player or sender:match("^[^-]+") == player
  end
  for _,eventName in ipairs({"CHAT_MSG_SAY","CHAT_MSG_PARTY","CHAT_MSG_RAID","CHAT_MSG_GUILD","CHAT_MSG_OFFICER","CHAT_MSG_WHISPER_INFORM"}) do
    f:RegisterEvent(eventName)
  end
  f:SetScript("OnEvent",function(self,event,message,sender)
    if not self.postPending then return end
    if event=="CHAT_MSG_WHISPER_INFORM" or senderIsPlayer(sender) then
      self.postPending=false
      refreshHighlights()
      setLocal("Message sent. "..(self.destination=="WHISPER" and "Whisper" or self.destination).." remains selected.")
    end
  end)

  f:SetScript("OnShow",function()
    refreshTarget(); markDestination()
    f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(200); f:SetToplevel(true); f:Raise()
    rail:SetFrameLevel(201); body:SetFrameLevel(201); scroll:SetFrameLevel(210); child:SetFrameLevel(211); edit:SetFrameLevel(212)
    for _,b in ipairs(allCommandButtons) do b:SetFrameLevel(220); b:EnableMouse(true); b:RegisterForClicks("LeftButtonUp") end
    if f.editButton then f.editButton:SetFrameLevel(220); f.editButton:EnableMouse(true) end
    if f.lockButton then f.lockButton:SetFrameLevel(220); f.lockButton:EnableMouse(true) end
    refreshHighlights()
  end)
  markDestination(); refreshTarget(); setLocal("Capture the current report to begin.")
  return f
end

local function ShareTargetQuestReport()
  local text,kind,err=CourierCurrentReportText()
  if not text then SetStatus(err or "Current quest report is not ready.",true); return end
  local f=EnsureShareFrame()
  f:SetCapturedMessage(text,kind)
  f:Show(); f:Raise()
  SetStatus("Courier opened with a locked report. Unlock only when live target updates are required.")
end

local function ShowQuestExport()
  local text=QuestDetailsReportText()
  if not text then SetStatus("Load quest information before copying or exporting.",true); return end
  ShowSelectableReport("AzerCore Ops Quest information",text)
end

local function ShowGroupExport()
  local text=GroupAnalysisReportText()
  if not text then SetStatus("Run Audit Group before copying or exporting group analysis.",true); return end
  ShowSelectableReport("AzerCore Ops Quest group analysis",text)
end

local function OutputReportText()
  local lines={"AzerCore Ops — Quest activity and module output",string.format("Generated: %s",date("%Y-%m-%d %H:%M:%S")),""}
  for i=#(questUI.posts or {}),1,-1 do local r=questUI.posts[i]; table.insert(lines,string.format("[%s] %-8s %s",r.time,r.kind,r.text)) end
  return table.concat(lines,"\n")
end

local function ShowQuestOutputExport()
  ShowSelectableReport("Quest activity and module output",OutputReportText())
end

local function OpenQuestLog()
  if not QuestLogFrame then
    local loaded = LoadAddOn and LoadAddOn("Blizzard_QuestLog")
    if not loaded and not QuestLogFrame then
      SetStatus("Could not load the Blizzard Quest Log.",true)
      return
    end
  end

  if QuestLogFrame and QuestLogFrame:IsShown() then
    HideUIPanel(QuestLogFrame)
    SetStatus("Quest Log closed.")
  elseif QuestLogFrame then
    ShowUIPanel(QuestLogFrame)
    SetStatus("Quest Log opened.")
  else
    SetStatus("Quest Log is unavailable.",true)
  end
end

local function UpdateQuestInspectorTarget(refreshQuest)
  if not questUI.targetNameText then return end
  local valid=UnitExists("target") and UnitIsPlayer("target")
  if valid then
    local name=UnitName("target") or "Unknown"
    if questUI.targetLogPlayer and questUI.targetLogPlayer~=name then
      questUI.targetLogEntries={}; questUI.targetLogLoading=false; questUI.targetLogError=nil
    end
    local level=UnitLevel("target") or "?"
    local class=select(1,UnitClass("target")) or "Player"
    local guild=GetGuildInfo("target")
    questUI.targetNameText:SetText(name)
    if questUI.railTargetText then questUI.railTargetText:SetText(name) end
    questUI.targetMetaText:SetText(string.format("Level %s  %s%s",tostring(level),class,guild and ("\nGuild: "..guild) or ""))
    if questUI.targetPortrait then SetPortraitTexture(questUI.targetPortrait,"target") end
    questUI.contextName=name
    questUI.contextKind="TARGET"
    UpdateQuestContextLabel()
    if questUI.lockedQuestId then
      questUI.targetHintText:SetText(string.format("Inspecting locked quest %s [%d] for %s.",questUI.lockedQuestTitle or "Quest",questUI.lockedQuestId,name))
      questUI.targetHintText:SetTextColor(unpack(C.white))
      if refreshQuest then RequestQuestInfo(questUI.lockedQuestId) end
    else
      questUI.targetHintText:SetText("Target detected. Inspect their Quest Log, or select and lock a quest in Quest Explorer.")
      questUI.targetHintText:SetTextColor(unpack(C.muted))
    end
  else
    questUI.targetLogEntries={}; questUI.targetLogActive=false; questUI.targetLogLoading=false; questUI.targetLogPlayer=nil; questUI.targetLogError=nil
    questUI.targetNameText:SetText("No player selected")
    if questUI.railTargetText then questUI.railTargetText:SetText("No player selected") end
    questUI.targetMetaText:SetText("Select a player target to inspect their Quest Log or a locked quest.")
    questUI.targetHintText:SetText("Target inspection requires an online player target.")
    questUI.targetHintText:SetTextColor(unpack(C.muted))
    if questUI.targetPortrait then questUI.targetPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
  end
  RenderQuest()
end

local function OpenTargetQuestLog()
  if not (UnitExists("target") and UnitIsPlayer("target")) then SetStatus("Select a player target first.",true); return end
  local name=UnitName("target") or "Unknown"
  questUI.targetLogEntries={}
  questUI.targetLogActive=true
  questUI.targetLogLoading=true
  questUI.targetLogPlayer=name
  questUI.targetLogError=nil
  RenderQuest()
  SendCommand(CMD.questLog)
  SetStatus("Inspecting "..name.."'s complete quest log...")
end

local function BuildQuest()
  local p=NewPage("Quest")
  QuestHistory()

  local function Section(parent,text,color)
    local h=parent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    h:SetText(text); h:SetTextColor(unpack(color or C.gold)); return h
  end
  local function RunSelectedCommand(template,confirm)
    local id=SelectedQuestId()
    if not id then SetStatus("Select or inspect a quest first.",true); return end
    local cmd=string.format(template,id)
    if confirm then Confirm(cmd) else SendCommand(cmd) end
  end
  local function Placeholder(parent,title,body)
    local t=Section(parent,title,C.inspect); t:SetPoint("TOPLEFT",12,-12)
    local x=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    x:SetPoint("TOPLEFT",12,-42); x:SetPoint("BOTTOMRIGHT",-12,12)
    x:SetJustifyH("CENTER"); x:SetJustifyV("MIDDLE"); x:SetWordWrap(true)
    x:SetTextColor(unpack(C.muted)); x:SetText(body)
    return x
  end

  StaticPopupDialogs["AZERCORE_OPS_QUEST_SEARCH_HELP"]={
    text="Quest Search Help\n\nSearch using an exact Quest ID, for example: 24874\n\nOr enter a partial or complete quest title, for example: Blood or Blood Quickening.\n\nSearch is not case-sensitive. Press Enter or click Search.",
    button1=OKAY,timeout=0,whileDead=1,hideOnEscape=1,preferredIndex=3,
  }

  local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-8); header:SetPoint("TOPRIGHT",-10,-8); header:SetHeight(48); Backdrop(header,C.bg)
  local title=Label(header,"Quest Inspector","GameFontNormalLarge"); title:SetPoint("TOPLEFT",12,-8)
  local subtitle=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); subtitle:SetPoint("TOPLEFT",12,-28); subtitle:SetTextColor(unpack(C.white)); subtitle:SetText("Quest intelligence and operations framework")
  questUI.workspaceHeader=header:CreateFontString(nil,"OVERLAY","GameFontNormal"); questUI.workspaceHeader:SetPoint("RIGHT",-14,0); questUI.workspaceHeader:SetTextColor(unpack(C.gold))

  local operation=CreateFrame("Frame",nil,p); operation:SetPoint("TOPLEFT",10,-64); operation:SetPoint("BOTTOMLEFT",10,10); operation:SetWidth(150); Backdrop(operation,C.panel)
  local oh=Section(operation,"OPERATIONS",C.gold); oh:SetPoint("TOP",0,-10)

  local explorer=CreateFrame("Frame",nil,p); explorer:SetPoint("TOPLEFT",168,-64); explorer:SetPoint("BOTTOMLEFT",168,10); explorer:SetWidth(218); Backdrop(explorer,C.panel)
  local eh=Section(explorer,"QUEST EXPLORER",C.resolve); eh:SetPoint("TOPLEFT",10,-10)

  local workspace=CreateFrame("Frame",nil,p); workspace:SetPoint("TOPLEFT",394,-64); workspace:SetPoint("BOTTOMRIGHT",-10,10); Backdrop(workspace,C.panel)
  local workspacePages={}
  local operationButtons={}
  local activeWorkspace="DATABASE"

  local function NewWorkspace(name)
    local f=CreateFrame("Frame",nil,workspace); f:SetAllPoints(workspace); f:Hide(); workspacePages[name]=f; return f
  end
  local function PaintOperationButton(key,hovered)
    local button=operationButtons[key]
    if not button then return end
    if key==activeWorkspace then
      button:SetBackdropColor(unpack(C.selected))
      button:SetBackdropBorderColor(unpack(C.gold))
    elseif hovered then
      button:SetBackdropColor(unpack(C.hover))
      button:SetBackdropBorderColor(unpack(C.border))
    else
      button:SetBackdropColor(unpack(C.button))
      button:SetBackdropBorderColor(unpack(C.border))
    end
  end
  local function SetOperation(name,label)
    activeWorkspace=name
    questUI.activeWorkspace=name
    for key,frame in pairs(workspacePages) do if key==name then frame:Show() else frame:Hide() end end
    for key in pairs(operationButtons) do PaintOperationButton(key,false) end
    if questUI.workspaceHeader then questUI.workspaceHeader:SetText(label or name) end
    SetStatus((label or name).." workspace")
  end
  local function OperationButton(key,text,y,activate,tip)
    local b=Button(operation,text,130,32,function()
      if activate and activate()==false then return end
      SetOperation(key,text)
    end,tip)
    b:SetPoint("TOPLEFT",10,y)
    operationButtons[key]=b
    b:SetScript("OnEnter",function(self)
      PaintOperationButton(key,true)
      if tip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(text,1,.82,0); GameTooltip:AddLine(tip,1,1,1,true); GameTooltip:Show() end
    end)
    b:SetScript("OnLeave",function() PaintOperationButton(key,false); GameTooltip:Hide() end)
    return b
  end

  OperationButton("DATABASE","Quest Database",-34,nil,"Search and lock a quest from the server database")
  OperationButton("TARGET","Target Player",-72,function()
    if not questUI.lockedQuestId then SetStatus("Select and lock a quest before opening Target Player.",true); return false end
    if not (UnitExists("target") and UnitIsPlayer("target")) then SetStatus("Select a player target first.",true); return false end
    UpdateQuestInspectorTarget(true)
    return true
  end,"Apply the locked quest to the selected player context")
  OperationButton("GROUP","Group Analysis",-110,function()
    if not SelectedQuestId() then SetStatus("Select and lock a quest before opening Group Analysis.",true); return false end
    RunQuestAudit()
    return true
  end,"Audit the locked quest for your party or raid")
  OperationButton("ACTIVITY","Quest Activity",-148,nil,"View commands, status messages and module output")

  local gm=Section(operation,"GM OPERATIONS",C.operate); gm:SetPoint("TOP",0,-198)
  Button(operation,"Add Quest",130,27,function() RunSelectedCommand(CMD.questAdd,false) end,"Add the locked quest to the current target"):SetPoint("TOPLEFT",10,-218)
  Button(operation,"Complete Quest",130,27,function() RunSelectedCommand(CMD.questComplete,false) end,"Force-complete the locked quest"):SetPoint("TOPLEFT",10,-251)
  Button(operation,"Reward Quest",130,27,function() RunSelectedCommand(CMD.questReward,true) end,"Reward the locked quest"):SetPoint("TOPLEFT",10,-284)
  Button(operation,"Remove Quest",130,27,function() RunSelectedCommand(CMD.questRemove,true) end,"Remove the locked quest"):SetPoint("TOPLEFT",10,-317)
  Button(operation,"Open Quest Log",130,27,OpenQuestLog,"Open the Blizzard Quest Log for the logged-in character"):SetPoint("TOPLEFT",10,-350)
  Button(operation,"Clear Workspace",130,27,ClearQuestSearch,"Clear the locked quest, results and audit data"):SetPoint("TOPLEFT",10,-383)

  local searchLabel=Section(explorer,"Quest title or Quest ID",C.gold); searchLabel:SetPoint("TOPLEFT",10,-36)
  Button(explorer,"?",22,20,function() StaticPopup_Show("AZERCORE_OPS_QUEST_SEARCH_HELP") end,"How to search by quest title or Quest ID"):SetPoint("TOPRIGHT",-10,-31)
  questSearchBox=Edit(explorer,144,false); questSearchBox:SetPoint("TOPLEFT",10,-56); questSearchBox.azerCoreOpsExpected="quest"; questSearchBox.azerCoreOpsPlain=true
  Button(explorer,"Search",50,24,RunQuestSearch,"Enter a partial quest title or an exact Quest ID"):SetPoint("TOPRIGHT",-10,-56)
  questSearchBox:SetScript("OnEnterPressed",function(self) self:ClearFocus(); RunQuestSearch() end)

  local matches=CreateFrame("Frame",nil,explorer); matches:SetPoint("TOPLEFT",8,-90); matches:SetPoint("TOPRIGHT",-8,-90); matches:SetHeight(250); Backdrop(matches,C.bg)
  local mh=Section(matches,"QUEST MATCHES",C.gold); mh:SetPoint("TOPLEFT",8,-8)
  questUI.summary=matches:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.summary:SetPoint("TOPRIGHT",-24,-8); questUI.summary:SetTextColor(unpack(C.white))
  local function ScrollResults(delta)
    local maxOffset=math.max(0,#questUI.results-7)
    questUI.resultOffset=math.max(0,math.min(maxOffset,(questUI.resultOffset or 0)+delta)); RenderQuest()
  end
  Button(matches,"^",18,18,function() ScrollResults(-1) end,"Scroll results up"):SetPoint("TOPRIGHT",-4,-27)
  Button(matches,"v",18,18,function() ScrollResults(1) end,"Scroll results down"):SetPoint("BOTTOMRIGHT",-4,5)
  matches:EnableMouseWheel(true); matches:SetScript("OnMouseWheel",function(_,delta) ScrollResults(delta>0 and -1 or 1) end)
  questUI.rows={}
  for i=1,7 do
    local row=Button(matches,"",172,28,function(self)
      if not self.id then return end
      LockQuest(self.id,self.title); questSearchBox:SetText(self.title or ""); UpdateLockedQuestHistory(); RequestQuestInfo(self.id); SetOperation("DATABASE","Quest Database")
    end)
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",5,-2); row.text:SetPoint("BOTTOMRIGHT",-5,2); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP")
    row:SetPoint("TOPLEFT",8,-28-(i-1)*30); row:Hide(); questUI.rows[i]=row
  end

  local selected=CreateFrame("Frame",nil,explorer); selected:SetPoint("TOPLEFT",8,-348); selected:SetPoint("BOTTOMRIGHT",-8,8); Backdrop(selected,C.bg)
  local sh=Section(selected,"LOCKED QUEST",C.gold); sh:SetPoint("TOPLEFT",8,-8)
  questIdBox=Edit(selected,1,false); questIdBox:SetPoint("TOPLEFT",-20,20); questIdBox.azerCoreOpsExpected="quest"; questIdBox:SetAutoFocus(false); questIdBox:Hide()
  questIdBox:SetScript("OnTextChanged",function(self,userInput) if userInput and not questUI.questIdInternal then questUI.selectedId=tonumber(self:GetText()) end end)
  questUI.contextName=questUI.contextName or UnitName("player") or "Self"; questUI.contextKind=questUI.contextKind or "SELF"
  questUI.contextLabel=nil
  questUI.lockedLabel=selected:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.lockedLabel:SetPoint("TOPLEFT",8,-34); questUI.lockedLabel:SetPoint("BOTTOMRIGHT",-8,38); questUI.lockedLabel:SetJustifyH("LEFT"); questUI.lockedLabel:SetJustifyV("TOP"); questUI.lockedLabel:SetWordWrap(true); questUI.lockedLabel:SetTextColor(unpack(C.white)); questUI.lockedLabel:SetText("|cffaaaaaaNo quest locked.|r\n\nSelect a quest match to lock it into the framework.")
  Button(selected,"History",68,22,ShowSavedQuestHistory,"Open saved searches with their selected Quest IDs"):SetPoint("BOTTOMLEFT",8,8)
  Button(selected,"<",24,22,function() ShowQuestHistory(1) end,"Previous saved quest search"):SetPoint("BOTTOMLEFT",80,8)
  Button(selected,">",24,22,function() ShowQuestHistory(-1) end,"Next saved quest search"):SetPoint("BOTTOMLEFT",108,8)
  Button(selected,"Reference",68,22,LinkSelectedQuest,"Insert the locked quest title and ID into chat"):SetPoint("BOTTOMRIGHT",-8,8)

  -- Quest Database workspace
  local db=NewWorkspace("DATABASE")
  local dbh=Section(db,"QUEST DATABASE",C.gold); dbh:SetPoint("TOPLEFT",12,-10)
  questUI.detailScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_QuestFrameworkDetailScroll",db,"UIPanelScrollFrameTemplate"); questUI.detailScroll:SetPoint("TOPLEFT",10,-34); questUI.detailScroll:SetPoint("BOTTOMRIGHT",-30,40); questUI.detailScroll:EnableMouseWheel(true)
  questUI.detailChild=CreateFrame("Frame",nil,questUI.detailScroll); questUI.detailChild:SetWidth(330); questUI.detailChild:SetHeight(430); questUI.detailScroll:SetScrollChild(questUI.detailChild)
  questUI.detailText=CreateFrame("EditBox",nil,questUI.detailChild); questUI.detailText:SetPoint("TOPLEFT",0,0); questUI.detailText:SetWidth(330); questUI.detailText:SetHeight(430); questUI.detailText:SetMultiLine(true); questUI.detailText:SetAutoFocus(false); questUI.detailText:SetFontObject(GameFontHighlightSmall); questUI.detailText:SetTextColor(unpack(C.white)); questUI.detailText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  questUI.detailScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  Button(db,"Export",70,22,ShowQuestExport,"Export quest information and chain"):SetPoint("BOTTOMRIGHT",-10,10)

  -- Target workspace
  local target=NewWorkspace("TARGET")
  local th=Section(target,"TARGET PLAYER",C.inspect); th:SetPoint("TOPLEFT",12,-10)

  local targetProfile=CreateFrame("Frame",nil,target); targetProfile:SetPoint("TOPLEFT",10,-30); targetProfile:SetPoint("TOPRIGHT",-10,-30); targetProfile:SetHeight(72); Backdrop(targetProfile,C.bg)
  questUI.targetPortrait=targetProfile:CreateTexture(nil,"ARTWORK"); questUI.targetPortrait:SetWidth(52); questUI.targetPortrait:SetHeight(52); questUI.targetPortrait:SetPoint("LEFT",10,0); questUI.targetPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  questUI.targetNameText=targetProfile:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); questUI.targetNameText:SetPoint("TOPLEFT",72,-12); questUI.targetNameText:SetPoint("TOPRIGHT",-12,-12); questUI.targetNameText:SetJustifyH("LEFT"); questUI.targetNameText:SetTextColor(unpack(C.white)); questUI.targetNameText:SetText("No player selected")
  questUI.targetMetaText=targetProfile:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.targetMetaText:SetPoint("TOPLEFT",72,-36); questUI.targetMetaText:SetPoint("BOTTOMRIGHT",-12,8); questUI.targetMetaText:SetJustifyH("LEFT"); questUI.targetMetaText:SetJustifyV("TOP"); questUI.targetMetaText:SetTextColor(unpack(C.muted))

  local targetActions=CreateFrame("Frame",nil,target); targetActions:SetPoint("TOPLEFT",10,-110); targetActions:SetPoint("TOPRIGHT",-10,-110); targetActions:SetHeight(30)
  Button(targetActions,"Inspect Quest Log",110,24,OpenTargetQuestLog,"Load the selected online player's complete active quest list from the server"):SetPoint("LEFT",0,0)

  local targetBody=CreateFrame("Frame",nil,target); targetBody:SetPoint("TOPLEFT",10,-148); targetBody:SetPoint("BOTTOMRIGHT",-10,48); Backdrop(targetBody,C.bg)
  local lockedTarget=Section(targetBody,"LOCKED QUEST IN TARGET CONTEXT",C.gold); lockedTarget:SetPoint("TOPLEFT",12,-10)
  questUI.targetBodyTitle=lockedTarget
  questUI.targetHintText=targetBody:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.targetHintText:SetPoint("TOPLEFT",12,-32); questUI.targetHintText:SetPoint("TOPRIGHT",-32,-32); questUI.targetHintText:SetHeight(30); questUI.targetHintText:SetJustifyH("LEFT"); questUI.targetHintText:SetWordWrap(true); questUI.targetHintText:SetTextColor(unpack(C.muted)); questUI.targetHintText:SetText("Select a player target and lock a quest.")

  questUI.targetQuestScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_TargetQuestReportScroll",targetBody,"UIPanelScrollFrameTemplate"); questUI.targetQuestScroll:SetPoint("TOPLEFT",12,-66); questUI.targetQuestScroll:SetPoint("BOTTOMRIGHT",-30,10); questUI.targetQuestScroll:EnableMouseWheel(true)
  questUI.targetQuestChild=CreateFrame("Frame",nil,questUI.targetQuestScroll); questUI.targetQuestChild:SetWidth(330); questUI.targetQuestChild:SetHeight(260); questUI.targetQuestScroll:SetScrollChild(questUI.targetQuestChild)
  questUI.targetQuestText=CreateFrame("EditBox",nil,questUI.targetQuestChild); questUI.targetQuestText:SetPoint("TOPLEFT",0,0); questUI.targetQuestText:SetWidth(330); questUI.targetQuestText:SetHeight(260); questUI.targetQuestText:SetMultiLine(true); questUI.targetQuestText:SetAutoFocus(false); questUI.targetQuestText:SetFontObject(GameFontHighlightSmall); questUI.targetQuestText:SetTextColor(unpack(C.white)); questUI.targetQuestText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  questUI.targetQuestScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)

  local targetFooter=CreateFrame("Frame",nil,target); targetFooter:SetPoint("BOTTOMLEFT",10,10); targetFooter:SetPoint("BOTTOMRIGHT",-10,10); targetFooter:SetHeight(30); Backdrop(targetFooter,C.panel)
  Button(targetFooter,"Refresh Target",96,22,function() if questUI.targetLogActive then OpenTargetQuestLog() else UpdateQuestInspectorTarget(true) end end,"Refresh the selected target's current quest inspection"):SetPoint("LEFT",6,0)
  Button(targetFooter,"Copy",54,22,ShowTargetQuestCopy,"Open the current report as selectable text for copying"):SetPoint("CENTER",0,0)
  Button(targetFooter,"Share",58,22,ShareTargetQuestReport,"Insert a concise report into chat; choose a channel or recipient before sending"):SetPoint("RIGHT",-82,0)
  Button(targetFooter,"Export",70,22,ShowTargetQuestExport,"Export the complete target quest analysis as selectable text"):SetPoint("RIGHT",-6,0)

  -- Group workspace
  local group=NewWorkspace("GROUP")
  local gh=Section(group,"GROUP ANALYSIS",C.gold); gh:SetPoint("TOPLEFT",12,-10)
  questUI.auditSummary=group:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.auditSummary:SetPoint("TOPRIGHT",-12,-10); questUI.auditSummary:SetTextColor(unpack(C.white))
  local filters={{"All","ALL"},{"Pass","PASS"},{"Warn","WARN"},{"Fail","FAIL"}}
  for i,f in ipairs(filters) do Button(group,f[1],58,20,function() questUI.auditFilter=f[2]; RenderQuest() end):SetPoint("TOPLEFT",10+(i-1)*62,-32) end
  questUI.auditScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_QuestFrameworkAuditScroll",group,"UIPanelScrollFrameTemplate"); questUI.auditScroll:SetPoint("TOPLEFT",10,-58); questUI.auditScroll:SetPoint("BOTTOMRIGHT",-30,40); questUI.auditScroll:EnableMouseWheel(true)
  questUI.auditChild=CreateFrame("Frame",nil,questUI.auditScroll); questUI.auditChild:SetWidth(330); questUI.auditChild:SetHeight(400); questUI.auditScroll:SetScrollChild(questUI.auditChild)
  questUI.auditText=CreateFrame("EditBox",nil,questUI.auditChild); questUI.auditText:SetPoint("TOPLEFT",0,0); questUI.auditText:SetWidth(330); questUI.auditText:SetHeight(400); questUI.auditText:SetMultiLine(true); questUI.auditText:SetAutoFocus(false); questUI.auditText:SetFontObject(GameFontHighlightSmall); questUI.auditText:SetTextColor(unpack(C.white)); questUI.auditText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  questUI.auditScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  Button(group,"Run Audit",80,22,RunQuestAudit,"Audit selected quest for the group"):SetPoint("BOTTOMLEFT",10,10)
  Button(group,"Export",70,22,ShowGroupExport,"Export group analysis"):SetPoint("BOTTOMRIGHT",-10,10)

  -- Activity workspace
  local activity=NewWorkspace("ACTIVITY")
  local ah=Section(activity,"QUEST ACTIVITY AND MODULE OUTPUT",C.gold); ah:SetPoint("TOPLEFT",12,-10)
  local postScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_QuestFrameworkPostScroll",activity,"UIPanelScrollFrameTemplate"); postScroll:SetPoint("TOPLEFT",10,-36); postScroll:SetPoint("BOTTOMRIGHT",-30,40); postScroll:EnableMouseWheel(true)
  questUI.postChild=CreateFrame("Frame",nil,postScroll); questUI.postChild:SetWidth(330); questUI.postChild:SetHeight(400); postScroll:SetScrollChild(questUI.postChild)
  questUI.postText=CreateFrame("EditBox",nil,questUI.postChild); questUI.postText:SetPoint("TOPLEFT",0,0); questUI.postText:SetWidth(330); questUI.postText:SetHeight(400); questUI.postText:SetMultiLine(true); questUI.postText:SetAutoFocus(false); questUI.postText:SetFontObject(GameFontHighlightSmall); questUI.postText:SetTextColor(unpack(C.white)); questUI.postText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  postScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  Button(activity,"Clear",70,22,function() questUI.posts={}; AppendQuestPost("Output cleared.","STATUS") end,"Clear activity output"):SetPoint("BOTTOMLEFT",10,10)
  Button(activity,"Export",70,22,ShowQuestOutputExport,"Export activity and module output"):SetPoint("BOTTOMRIGHT",-10,10)

  local initialOperation=questUI.activeWorkspace or "DATABASE"
  local operationLabels={DATABASE="Quest Database",TARGET="Target Player",GROUP="Group Analysis",ACTIVITY="Quest Activity"}
  if not workspacePages[initialOperation] then initialOperation="DATABASE" end
  SetOperation(initialOperation,operationLabels[initialOperation])
  RenderQuest(); UpdateQuestInspectorTarget(false); AppendQuestPost("Quest Framework ready.","STATUS")
end

local function BuildTeleport()
  local p=NewPage("Teleport"); local h=Label(p,"Teleport tools"); h:SetPoint("TOPLEFT",18,-18)
  local loc=AddField(p,"Teleport location",18,-56,260,false)
  Button(p,"Teleport",120,24,function() local s=NonEmpty(loc,"a teleport location"); if s then SendCommand(string.format(CMD.tele,s)) end end,"Use an AzerothCore teleport name"):SetPoint("TOPLEFT",295,-73)
  local playerName=AddField(p,"Player name",18,-125,210,false); playerName.azerCoreOpsExpected="player"; playerName.azerCoreOpsPlain=true
  Button(p,"Use Target",100,24,function()
    if UnitExists("target") and UnitIsPlayer("target") then playerName:SetText(UnitName("target") or ""); SetStatus("Selected player "..(UnitName("target") or ""))
    else SetStatus("Select a player first.",true) end
  end,"Copy the selected player's name"):SetPoint("TOPLEFT",245,-142)
  Button(p,"Appear",100,24,function()
    local name=NonEmpty(playerName,"a player name"); if name then Confirm(CMD.appear.." "..name) end
  end,"Teleport to the named player"):SetPoint("TOPLEFT",355,-142)
  Button(p,"Summon",100,24,function()
    local name=NonEmpty(playerName,"a player name"); if name then Confirm(CMD.summon.." "..name) end
  end,"Summon the named player to you"):SetPoint("TOPLEFT",465,-142)
  AddCommandGrid(p,{
    {"GPS",function() SendCommand(CMD.gps) end,"Show map and coordinates"},
    {"Appear Target",function() if UnitExists("target") and UnitIsPlayer("target") then Confirm(CMD.appear) else SetStatus("Select a player first.",true) end end,"Teleport to selected player"},
    {"Summon Target",function() if UnitExists("target") and UnitIsPlayer("target") then Confirm(CMD.summon) else SetStatus("Select a player first.",true) end end,"Summon selected player"},
  },-205)
  local note=Label(p,"Named-player commands are validated by AzerothCore. Confirm cross-map and instance movement before continuing.","GameFontHighlightSmall")
  note:SetTextColor(unpack(C.white)); note:SetPoint("TOPLEFT",18,-300); note:SetWidth(550); note:SetJustifyH("LEFT")
end

local function BuildItem()
  local p=NewPage("Item"); local titleBox=AddField(p,"Item name",18,-18,300,false); titleBox.azerCoreOpsExpected="item"; titleBox.azerCoreOpsPlain=true
  Button(p,"Lookup",110,24,function() local s=NonEmpty(titleBox,"an item name"); if s then BeginLookup("item",string.format(CMD.itemLookup,s)) end end,"Search the server item database"):SetPoint("TOPLEFT",334,-35)
  itemIdBox=AddField(p,"Item ID",18,-78,110,true); itemIdBox.azerCoreOpsExpected="item"; local count=AddField(p,"Quantity",145,-78,80,true); count:SetText("1")
  Button(p,"Add Item",105,24,function() local id=PositiveId(itemIdBox,"item"); local n=PositiveId(count,"quantity"); if id and n then SendCommand(string.format(CMD.itemAdd,id,n)) end end):SetPoint("TOPLEFT",245,-95)
  Button(p,"Remove",105,24,function() local id=PositiveId(itemIdBox,"item"); local n=PositiveId(count,"quantity"); if id and n then Confirm(string.format(CMD.itemRemove,id,n)) end end):SetPoint("TOPLEFT",365,-95)
  AddResultsPanel(p,"item")
end

local function ParseAuditFields(message)
  local fields={}
  for key,value in tostring(message):gmatch("|([^|=]+)=([^|]*)") do fields[key]=value end
  return fields
end

local function ShortTime(seconds)
  seconds=tonumber(seconds) or 0
  local d=math.floor(seconds/86400); local h=math.floor((seconds%86400)/3600); local m=math.floor((seconds%3600)/60)
  if d>0 then return d.."d "..h.."h" end
  if h>0 then return h.."h "..m.."m" end
  return m.."m"
end

local function SelectedPlayerName()
  if UnitExists("target") and UnitIsPlayer("target") then return UnitName("target") end
end

local function RequireSelectedPlayer()
  local name=SelectedPlayerName()
  if not name and Settings().warnNoTarget then SetStatus("Select the player whose binds you want to change.",true); return end
  return name
end

local function MyHasInstance(id)
  id=tostring(id or "")
  for _,r in ipairs(instanceUI.my) do if tostring(r.id)==id then return true end end
  return false
end

local function BindRow(parent,y,click)
  local row=CreateFrame("Button",nil,parent); row:SetPoint("TOPLEFT",7,y); row:SetPoint("TOPRIGHT",-7,y); row:SetHeight(41)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.075,.08,.095,.96)
  row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",6,-4); row.text:SetPoint("BOTTOMRIGHT",-6,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP"); row.text:SetTextColor(unpack(C.white))
  row:SetScript("OnClick",click); row:Hide(); return row
end

local function RenderInstances()
  if instanceUI.targetLabel then instanceUI.targetLabel:SetText("Selected player: |cffffffff"..(SelectedPlayerName() or "none").."|r") end
  for i,row in ipairs(instanceUI.myRows) do
    local r=instanceUI.my[instanceUI.myOffset+i]
    if r then
      local state=r.locked and "|cff55ff55Locked|r" or "|cffffff55Available|r"; if r.extended then state=state.." Extended" end
      row.data=r; row.text:SetText(string.format("%s |cffaaaaaa[%s]|r\nID %s  •  %s  •  resets %s",r.name,r.difficulty,r.id,state,ShortTime(r.reset))); row:Show()
    else row.data=nil; row:Hide() end
  end
  for i,row in ipairs(instanceUI.targetRows) do
    local r=instanceUI.target[instanceUI.targetOffset+i]
    if r then
      local match=MyHasInstance(r.instance) and "|cff55ff55SAME AS MINE|r" or "|cffffff55DIFFERENT / NOT MINE|r"
      row.data=r; row.text:SetText(string.format("Map %d  •  ID %d  •  Difficulty %d\n%s  •  can reset: %s  •  TTR %s",r.map,r.instance,r.difficulty,match,r.canReset,r.ttr)); row:Show()
    else row.data=nil; row:Hide() end
  end
end

local function RefreshMyInstances(skipRequest)
  instanceUI.my={}; instanceUI.myOffset=0; if not skipRequest then RequestRaidInfo() end
  local total=GetNumSavedInstances() or 0
  for i=1,total do
    local name,id,reset,difficulty,locked,extended,_,isRaid,maxPlayers,difficultyName=GetSavedInstanceInfo(i)
    table.insert(instanceUI.my,{name=name or "Unknown",id=id or "?",reset=reset,difficulty=difficultyName or tostring(difficulty or "?"),difficultyId=difficulty,locked=locked,extended=extended,isRaid=isRaid,maxPlayers=maxPlayers})
  end
  RenderInstances(); SetStatus(total.." personal lockout(s) found")
end

local function InspectTargetInstances()
  if not RequireSelectedPlayer() then return end
  instanceUI.target={}; instanceUI.targetOffset=0; instanceUI.captureUntil=GetTime()+5; RenderInstances(); SendCommand(CMD.instanceList); SetStatus("Collecting binds for "..SelectedPlayerName().."...")
end

local function FilteredAuditMembers()
  local out={}
  for _,r in ipairs(auditUI.members) do if auditUI.filter=="ALL" or r.result==auditUI.filter then table.insert(out,r) end end
  if Settings().problemsFirst then
    local rank={FAIL=1,OFFLINE=2,WARN=3,PASS=4}
    table.sort(out,function(a,b) local ar=rank[a.result] or 5; local br=rank[b.result] or 5; if ar==br then return (a.name or "")<(b.name or "") end; return ar<br end)
  end
  return out
end

local function RenderAudit()
  for i,row in ipairs(auditUI.searchRows) do
    local r=auditUI.search[i]
    if r then row.id=tonumber(r.map); row.label:SetText(string.format("%s — Map %s (%s)",r.name or "Unknown",r.map or "?",r.type or "instance")); row:Show() else row:Hide() end
  end
  auditUI.filtered=FilteredAuditMembers()
  local rowHeight=Settings().compactAuditRows and 28 or 40
  local contentWidth=Settings().wrapAuditReasons and 610 or 1050
  if auditUI.scrollChild then auditUI.scrollChild:SetWidth(contentWidth); auditUI.scrollChild:SetHeight(math.max(1,#auditUI.filtered)*rowHeight) end
  local reportLines={}
  for _,r in ipairs(auditUI.filtered) do
    local color=r.result=="PASS" and "|cff55ff55" or (r.result=="WARN" and "|cffffff55" or (r.result=="OFFLINE" and "|cffaaaaaa" or "|cffff5555"))
    table.insert(reportLines,color..(r.result or "?").."|r  "..(r.name or "Unknown"))
    table.insert(reportLines,"|cffdddddd"..(r.reason or "").."|r")
    table.insert(reportLines,"")
  end
  if auditUI.reportEdit then
    local text=table.concat(reportLines,"\n"); local h=math.max(1,#reportLines*15+10)
    auditUI.reportEdit:SetFont("Fonts\\FRIZQT__.TTF",Settings().auditFontSize or 10); auditUI.reportEdit:SetText(text); auditUI.reportEdit:SetHeight(h)
    auditUI.scrollChild:SetHeight(h)
  end
  for _,row in ipairs(auditUI.memberRows) do row:Hide() end
  if auditUI.scroll then auditUI.scroll:SetVerticalScroll(0); auditUI.scroll:SetHorizontalScroll(0) end
  if auditUI.horizontal then auditUI.horizontal:SetMinMaxValues(0,math.max(0,contentWidth-365)); auditUI.horizontal:SetValue(0) end
  if auditUI.summary then auditUI.summary:SetText(string.format("Showing %d of %d",#auditUI.filtered,#auditUI.members)) end
  for name,button in pairs(auditUI.filterButtons) do button:SetBackdropColor(unpack(name==auditUI.filter and C.selected or C.button)) end
end

ShowSelectableReport=function(title, report, actionLabel, actionFn)
  if not exportFrame then
    exportFrame=CreateFrame("Frame","AZERCORE_OPS_ExportFrame",UIParent); exportFrame:SetWidth(610); exportFrame:SetHeight(410); exportFrame:SetPoint("CENTER"); exportFrame:SetFrameStrata("FULLSCREEN_DIALOG"); Backdrop(exportFrame); Movable(exportFrame,"export")
    exportFrame.title=Label(exportFrame,"AzerCoreOps report"); exportFrame.title:SetPoint("TOPLEFT",14,-14)
    local help=exportFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); help:SetPoint("TOPLEFT",14,-34); help:SetText("Select any text and press Ctrl+C. Ctrl+A selects the complete report."); help:SetTextColor(unpack(C.white))
    local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_ExportScroll",exportFrame,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",14,-58); scroll:SetPoint("BOTTOMRIGHT",-34,45); Backdrop(scroll,C.panel)
    exportEdit=CreateFrame("EditBox",nil,scroll); exportEdit:SetMultiLine(true); exportEdit:SetAutoFocus(false); exportEdit:SetFontObject(ChatFontNormal); exportEdit:SetWidth(545); exportEdit:SetTextInsets(6,6,6,6); exportEdit:SetScript("OnEscapePressed",function() exportFrame:Hide() end); scroll:SetScrollChild(exportEdit)
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*60)) end)
    Button(exportFrame,"Select All",90,24,function() exportEdit:SetFocus(); exportEdit:HighlightText() end):SetPoint("BOTTOMLEFT",14,12)
    exportActionButton=Button(exportFrame,"Action",110,24,function() end); exportActionButton:SetPoint("BOTTOM",0,12); exportActionButton:Hide()
    Button(exportFrame,"Close",90,24,function() exportFrame:Hide() end):SetPoint("BOTTOMRIGHT",-14,12)
  end
  exportFrame.title:SetText(title or "AzerCoreOps report")
  if actionLabel and actionFn then
    exportActionButton:SetText(actionLabel)
    exportActionButton:SetScript("OnClick",actionFn)
    exportActionButton:Show()
  else
    exportActionButton:Hide()
  end
  exportEdit:SetText(report or ""); exportEdit:SetHeight(math.max(310,select(2,(report or ""):gsub("\n","\n"))*16+40)); exportFrame:Show(); exportEdit:SetFocus(); exportEdit:HighlightText()
end

local function ShowAuditExport()
  if #auditUI.members==0 then SetStatus("Run an instance audit before exporting.",true); return end
  local lines={"AzerCoreOps instance audit",string.format("Map: %s  Difficulty: %s",auditUI.lastMap or "?",auditUI.lastDifficulty or "?"),""}
  for _,r in ipairs(auditUI.members) do table.insert(lines,string.format("%s | %s | %s",r.result or "?",r.name or "Unknown",r.reason or "No reason")) end
  ShowSelectableReport("AzerCoreOps instance audit",table.concat(lines,"\n"))
end

local function AuditResultRow(parent)
  local row=CreateFrame("Button",nil,parent); row:SetHeight(38)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.075,.08,.095,.96)
  row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",7,-4); row.text:SetPoint("BOTTOMRIGHT",-7,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP")
  row:SetScript("OnEnter",function(self) if Settings().auditTooltips and self.data then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText((self.data.result or "?").." — "..(self.data.name or "Unknown"),1,.82,0); GameTooltip:AddLine(self.data.reason or "No details",1,1,1,true); GameTooltip:Show() end end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end); row:Hide(); return row
end

local function BuildInstances()
  local p=NewPage("Instances")
  local auditPage=CreateFrame("Frame",nil,p); auditPage:SetPoint("TOPLEFT",0,-36); auditPage:SetPoint("BOTTOMRIGHT")
  local bindPage=CreateFrame("Frame",nil,p); bindPage:SetPoint("TOPLEFT",0,-36); bindPage:SetPoint("BOTTOMRIGHT"); bindPage:Hide()
  local auditTab=Button(p,"Instance Access",140,24,function() auditPage:Show(); bindPage:Hide() end,"Check group and raid access to an instance"); auditTab:SetPoint("TOPLEFT",12,-7)
  local bindTab=Button(p,"Binds / Reset",120,24,function() bindPage:Show(); auditPage:Hide(); RenderInstances() end,"Inspect and safely remove instance binds"); bindTab:SetPoint("LEFT",auditTab,"RIGHT",8,0)

  local searchBox=AddField(auditPage,"Instance title",12,-5,225,false)
  Button(auditPage,"Search",70,24,function()
    local title=NonEmpty(searchBox,"an instance title")
    if title then auditUI.search={}; RenderAudit(); SendCommand(string.format(CMD.auditSearch,title)); SetStatus("Searching server instance maps...") end
  end,"Requires mod-azercore-ops"):SetPoint("TOPLEFT",247,-22)
  auditUI.mapBox=AddField(auditPage,"Map ID",330,-5,70,true)
  auditUI.diffBox=AddField(auditPage,"Difficulty",415,-5,65,true); auditUI.diffBox:SetText(tostring(Settings().defaultDifficulty))
  local function RunAudit()
    local map=PositiveId(auditUI.mapBox,"map"); local diff=tonumber(auditUI.diffBox:GetText())
    if not map or not diff or diff<0 or diff>3 then SetStatus("Difficulty must be 0, 1, 2, or 3.",true); return end
    auditUI.lastMap=map; auditUI.lastDifficulty=diff; auditUI.members={}; RenderAudit(); SendCommand(string.format(CMD.auditGroup,map,diff)); SetStatus("Auditing group on the server...")
  end
  Button(auditPage,"Audit Group",100,24,RunAudit,"Check every group or raid member"):SetPoint("TOPLEFT",495,-22)

  local searchPanel=CreateFrame("Frame",nil,auditPage); searchPanel:SetPoint("TOPLEFT",12,-59); searchPanel:SetWidth(190); searchPanel:SetHeight(307); Backdrop(searchPanel,C.panel)
  local sh=Label(searchPanel,"Instance matches","GameFontNormalSmall"); sh:SetPoint("TOPLEFT",8,-7)
  for i=1,8 do
    local row=Button(searchPanel,"",174,27,function(self) if self.id then auditUI.mapBox:SetText(self.id); SetStatus("Selected map "..self.id) end end)
    row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.label:SetPoint("LEFT",6,0); row.label:SetPoint("RIGHT",-6,0); row.label:SetJustifyH("LEFT"); row.label:SetTextColor(unpack(C.gold))
    row:SetPoint("TOPLEFT",8,-27-(i-1)*30); row:Hide(); auditUI.searchRows[i]=row
  end

  local resultPanel=CreateFrame("Frame",nil,auditPage); resultPanel:SetPoint("TOPLEFT",210,-59); resultPanel:SetPoint("BOTTOMRIGHT",-12,10); Backdrop(resultPanel,C.panel)
  local rh=Label(resultPanel,"Group access and visibility","GameFontNormalSmall"); rh:SetPoint("TOPLEFT",8,-7)
  auditUI.summary=resultPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); auditUI.summary:SetPoint("TOPRIGHT",-164,-7); auditUI.summary:SetTextColor(unpack(C.white))
  local filterNames={"ALL","FAIL","WARN","PASS","OFFLINE"}
  for i,name in ipairs(filterNames) do
    local filterName=name
    local filterButton=Button(resultPanel,filterName,54,18,function() auditUI.filter=filterName; if Settings().rememberAuditFilter then AzerCoreOpsDB.auditFilter=filterName end; RenderAudit() end,"Show "..filterName.." results")
    filterButton:SetPoint("TOPLEFT",8+(i-1)*58,-27); auditUI.filterButtons[filterName]=filterButton
    filterButton:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(filterName==auditUI.filter and C.selected or C.button)); GameTooltip:Hide() end)
  end
  Button(resultPanel,"Export",70,18,ShowAuditExport,"Open a selectable text report for copying"):SetPoint("TOPRIGHT",-84,-4)
  Button(resultPanel,"Re-audit",70,18,function() if auditUI.lastMap then auditUI.mapBox:SetText(auditUI.lastMap); auditUI.diffBox:SetText(auditUI.lastDifficulty); RunAudit() else SetStatus("Run an audit first.",true) end end,"Repeat the last audit"):SetPoint("TOPRIGHT",-8,-4)
  local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_AuditResultScroll",resultPanel,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",8,-48); scroll:SetPoint("BOTTOMRIGHT",-28,54); auditUI.scroll=scroll
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(610); child:SetHeight(1); scroll:SetScrollChild(child); auditUI.scrollChild=child
  auditUI.reportEdit=CreateFrame("EditBox",nil,child); auditUI.reportEdit:SetPoint("TOPLEFT",4,-2); auditUI.reportEdit:SetWidth(600); auditUI.reportEdit:SetHeight(1); auditUI.reportEdit:SetMultiLine(true); auditUI.reportEdit:SetAutoFocus(false); auditUI.reportEdit:SetFontObject(GameFontHighlightSmall); auditUI.reportEdit:SetTextColor(unpack(C.white)); auditUI.reportEdit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  for i=1,40 do auditUI.memberRows[i]=AuditResultRow(child); auditUI.memberRows[i]:Hide() end
  scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) if Settings().mouseWheelAudit then self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*80)) end end)
  local hs=CreateFrame("Slider","AZERCORE_OPS_AuditHorizontalScroll",resultPanel,"OptionsSliderTemplate"); hs:SetPoint("BOTTOMLEFT",12,31); hs:SetPoint("BOTTOMRIGHT",-12,31); hs:SetHeight(16); hs:SetMinMaxValues(0,0); hs:SetValueStep(10); hs:SetValue(0); auditUI.horizontal=hs
  _G[hs:GetName().."Low"]:SetText(""); _G[hs:GetName().."High"]:SetText(""); _G[hs:GetName().."Text"]:SetText("")
  hs:SetScript("OnValueChanged",function(_,value) if auditUI.scroll then auditUI.scroll:SetHorizontalScroll(value) end end)
  local legend=Label(resultPanel,"PASS = access allowed  •  WARN = context  •  FAIL = blocked  •  Hover for full reason","GameFontHighlightSmall"); legend:SetTextColor(unpack(C.white)); legend:SetPoint("BOTTOMLEFT",12,9)

  local myBox=CreateFrame("Frame",nil,bindPage); myBox:SetPoint("TOPLEFT",12,-4); myBox:SetWidth(295); myBox:SetHeight(260); Backdrop(myBox,C.panel)
  local mh=Label(myBox,"My saved instances","GameFontNormalSmall"); mh:SetPoint("TOPLEFT",9,-8)
  Button(myBox,"Refresh",70,20,RefreshMyInstances,"Refresh client lockouts"):SetPoint("TOPRIGHT",-8,-6)
  for i=1,5 do instanceUI.myRows[i]=BindRow(myBox,-31-(i-1)*44) end
  myBox:EnableMouseWheel(true); myBox:SetScript("OnMouseWheel",function(_,d) instanceUI.myOffset=math.max(0,math.min(math.max(0,#instanceUI.my-5),instanceUI.myOffset-d)); RenderInstances() end)

  local targetBox=CreateFrame("Frame",nil,bindPage); targetBox:SetPoint("TOPLEFT",317,-4); targetBox:SetWidth(295); targetBox:SetHeight(260); Backdrop(targetBox,C.panel)
  instanceUI.targetLabel=Label(targetBox,"Selected player: none","GameFontNormalSmall"); instanceUI.targetLabel:SetPoint("TOPLEFT",9,-8)
  Button(targetBox,"Inspect",70,20,InspectTargetInstances,"Run .instance listbinds for the selected player"):SetPoint("TOPRIGHT",-8,-6)
  for i=1,5 do instanceUI.targetRows[i]=BindRow(targetBox,-31-(i-1)*44,function(self) if self.data then instanceUI.mapBox:SetText(self.data.map); instanceUI.diffBox:SetText(self.data.difficulty); SetStatus("Selected map "..self.data.map..", difficulty "..self.data.difficulty) end end) end
  targetBox:EnableMouseWheel(true); targetBox:SetScript("OnMouseWheel",function(_,d) instanceUI.targetOffset=math.max(0,math.min(math.max(0,#instanceUI.target-5),instanceUI.targetOffset-d)); RenderInstances() end)

  instanceUI.mapBox=AddField(bindPage,"Map ID",14,-282,80,true); instanceUI.diffBox=AddField(bindPage,"Difficulty",110,-282,70,true); instanceUI.diffBox:SetText("0")
  Button(bindPage,"Reset Map",105,24,function()
    local name=RequireSelectedPlayer(); local map=PositiveId(instanceUI.mapBox,"map"); local diff=tonumber(instanceUI.diffBox:GetText())
    if name and map and diff and diff>=0 and diff<=3 then Confirm(string.format(CMD.instanceUnbind,tostring(map),diff),Settings().confirmResetSelected,function() if Settings().autoReaudit and auditUI.lastMap then After(.7,function() auditPage:Show(); bindPage:Hide(); RunAudit() end) end end) else SetStatus("Select a player and enter map ID plus difficulty 0–3.",true) end
  end,"Unbind the selected player from this map and difficulty"):SetPoint("TOPLEFT",198,-299)
  Button(bindPage,"Reset ALL",105,24,function() if RequireSelectedPlayer() then Confirm(CMD.instanceUnbindAll,Settings().confirmResetAll,function() if Settings().autoReaudit and auditUI.lastMap then After(.7,function() auditPage:Show(); bindPage:Hide(); RunAudit() end) end end) end end,"Clear all removable binds for the selected player"):SetPoint("TOPLEFT",313,-299)
  local note=Label(bindPage,"Click a selected-player bind to fill Map ID and Difficulty. Unbinding removes the character bind; it cannot reset an occupied instance or bypass encounter rules.","GameFontHighlightSmall")
  note:SetTextColor(unpack(C.white)); note:SetPoint("TOPLEFT",435,-282); note:SetWidth(175); note:SetJustifyH("LEFT")
  Button(bindPage,"Re-audit",90,22,function() if auditUI.lastMap then auditPage:Show(); bindPage:Hide(); auditUI.mapBox:SetText(auditUI.lastMap); auditUI.diffBox:SetText(auditUI.lastDifficulty); RunAudit() else SetStatus("Run an audit first.",true) end end,"Return to and repeat the last audit"):SetPoint("BOTTOMLEFT",14,13)
  auditUI.filter=(Settings().rememberAuditFilter and AzerCoreOpsDB.auditFilter) or "ALL"
  RenderAudit()
  RenderInstances()
end

local function PositionMinimap()
  local a=AzerCoreOpsDB.minimapAngle or 225; local r=78
  minimapButton:ClearAllPoints(); minimapButton:SetPoint("CENTER",Minimap,"CENTER",math.cos(math.rad(a))*r,math.sin(math.rad(a))*r)
end
local function ShowMain()
  if main then main:Show(); main:Raise() end
  if mini then mini:Hide() end
  if minimapButton and Settings().showMinimap then minimapButton:Show(); minimapButton:Raise() end
end
local function HideMain()
  if main then main:Hide() end
  if mini then
    if Settings().showMini then mini:Show(); mini:Raise() else mini:Hide() end
  end
  if minimapButton and Settings().showMinimap then minimapButton:Show(); minimapButton:Raise() end
end

local function ApplySettings()
  local s=Settings()
  if main then main:SetScale(s.scale or 1) end
  if minimapButton then
    minimapButton:SetParent(s.mbfCompatibility and UIParent or Minimap)
    PositionMinimap()
    if s.showMinimap then minimapButton:Show(); minimapButton:Raise() else minimapButton:Hide() end
  end
  if mini then
    if main and main:IsShown() then mini:Hide() elseif s.showMini then mini:Show(); mini:Raise() else mini:Hide() end
  end
  if auditUI.diffBox and not auditUI.diffBox:HasFocus() then auditUI.diffBox:SetText(tostring(s.defaultDifficulty or 0)) end
  if auditUI.scrollChild then RenderAudit() end
end

local function ResetPositions()
  AzerCoreOpsDB.mainPoint=nil; AzerCoreOpsDB.mainRel=nil; AzerCoreOpsDB.mainX=nil; AzerCoreOpsDB.mainY=nil; AzerCoreOpsDB.miniPoint=nil; AzerCoreOpsDB.miniRel=nil; AzerCoreOpsDB.miniX=nil; AzerCoreOpsDB.miniY=nil; AzerCoreOpsDB.minimapAngle=225
  main:ClearAllPoints(); main:SetPoint("CENTER"); mini:ClearAllPoints(); mini:SetPoint("CENTER",UIParent,"CENTER",290,0); PositionMinimap(); ShowMain(); SetStatus("Positions reset")
end

local function OpenOptions()
  InterfaceOptionsFrame_OpenToCategory(optionsPanel)
  InterfaceOptionsFrame_OpenToCategory(optionsPanel)
end

local function CompatibilityComplete()
  local r=compatUI.received or {}
  return r.VERSION and r.CAPABILITIES and r.PERMISSIONS and r.BUILD and r.BUILD_EXT
end

local function RenderCompatibility()
  local f=compatUI.data
  local target=compatUI.text
  if not f then
    local initial="AzerCore Ops\nAddon      |cffffffff"..ADDON_VERSION.."|r\nModule     |cffaaaaaaNot checked|r\nProtocol   v"..PROTOCOL_VERSION.."\n\nSelect Check compatibility to query the running worldserver."
    if target then target:SetText(initial) end
    if compatUI.informationText then compatUI.informationText:SetText(initial) end
    return
  end

  Platform:ApplyVersion(f)
  local compatibility, compatibilityReason=Platform:Compatibility(PROTOCOL_VERSION)
  local complete=CompatibilityComplete()
  if compatibility~="incompatible" and not complete then
    compatibility="unchecked"
    compatibilityReason="Connected; loading the platform registry and build information."
  end
  local protocolOK=tostring(f.protocol or "") == PROTOCOL_VERSION
  local function Workspace(value)
    value=tostring(value or "unknown")
    if value=="no" then return "|cff55ff55Clean|r" end
    if value=="yes" then return "|cffffff55Modified|r" end
    return "|cffffff55Unknown|r"
  end
  local statusColors={compatible="|cff55ff55Fully Compatible|r",limited="|cffffff55Limited Compatibility|r",incompatible="|cffff5555Incompatible|r",unchecked="|cffaaaaaaChecking...|r"}
  local status=statusColors[compatibility] or statusColors.unchecked
  local release=protocolOK and "|cff55ff55Supported|r" or "|cffff5555Unsupported|r"
  local capabilities=Platform:SortedCapabilities()
  local permissions=Platform:SortedPermissions()
  local capabilityText=#capabilities>0 and table.concat(capabilities, "\n") or "Not advertised"
  local permissionText=#permissions>0 and table.concat(permissions, "\n") or "Not advertised"
  local text=string.format(
    "Compatibility\n%s\n|cffaaaaaa%s|r\n\nSoftware\nAddon      |cffffffff%s|r\nModule     |cffffffff%s|r\nProtocol   v%s\nSchema     v%s\nRelease    %s (%s)\n\nCapabilities\n|cffffffff%s|r\n\nPermissions\n|cffffffff%s|r\n\nCommits\nAzerCore Ops |cffffffff%s|r\nCore         |cffffffff%s|r\nPlayerbots   |cffffffff%s|r\n\nWorkspace\nAzerCore Ops %s\nCore         %s\nPlayerbots   %s\n\nBuild\n%s\nBuilt %s",
    status,compatibilityReason,ADDON_VERSION,f.module or "unknown",f.protocol or "?",f.capschema or "?",release,f.release or "unknown",
    capabilityText,permissionText,f.modulegit or "unknown",f.core or "unknown",f.playerbots or "unknown",
    Workspace(f.moduledirty),Workspace(f.coredirty),Workspace(f.playerbotsdirty),f.build or "unknown",f.built or "unknown")
  if target then target:SetText(text) end
  if compatUI.informationText then compatUI.informationText:SetText(text) end
end

local function RequestCompatibility()
  compatUI.data=nil; compatUI.received={}; RenderCompatibility(); SendCommand(CMD.version); SetStatus("Checking compatibility: contacting the AzerCore Ops server module...")
end

local function BuildOptions()
  local p=CreateFrame("Frame","AZERCORE_OPS_OptionsPanel",UIParent); p.name="AzerCore Ops"; optionsPanel=p
  local title=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetText("AzerCore Ops")
  local version=p:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); version:SetPoint("LEFT",title,"RIGHT",8,0); version:SetText(ADDON_VERSION)
  local note=p:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); note:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-8); note:SetText("Settings are saved separately for each character.")
  local controls={}
  local function Check(parent,store,name,label,key,y,tip)
    local c=CreateFrame("CheckButton","AZERCORE_OPS_Opt"..name,parent,"InterfaceOptionsCheckButtonTemplate"); c:SetPoint("TOPLEFT",16,y)
    _G[c:GetName().."Text"]:SetText(label); c.tooltipText=tip; c:SetScript("OnClick",function(self) Settings()[key]=self:GetChecked() and true or false; ApplySettings() end)
    store[key]=c; return c
  end
  Check(p,controls,"StartMinimized","Start minimized after login or reload","startMinimized",-70,"Apply on the next login or /reload.")
  Check(p,controls,"Minimap","Show AzerCoreOps minimap button","showMinimap",-102,"Show the AzerCoreOps button around the minimap.")
  Check(p,controls,"Mini","Show floating AzerCoreOps button when minimized","showMini",-134,"Show the movable AzerCoreOps button when the main window is hidden.")
  Check(p,controls,"MBF","Keep AzerCoreOps outside Minimap Button Frame","mbfCompatibility",-166,"Enabled: MBF cannot collect AzerCoreOps. Disabled: AzerCoreOps can be added to MBF with /mbf scan.")
  Check(p,controls,"Confirm","Confirm destructive commands","confirmCommands",-198,"Ask before delete, remove, reset, reward, and other risky commands.")
  Check(p,controls,"Chat","Hide AzerCore Ops command echoes from chat","hideAuditChat",-230,"Hide dot-command echoes sent by AzerCore Ops. Structured protocol traffic is always hidden.")

  local scaleLabel=p:CreateFontString(nil,"ARTWORK","GameFontNormal"); scaleLabel:SetPoint("TOPLEFT",22,-278); scaleLabel:SetText("AzerCoreOps window scale")
  local slider=CreateFrame("Slider","AZERCORE_OPS_OptScale",p,"OptionsSliderTemplate"); slider:SetPoint("TOPLEFT",22,-302); slider:SetWidth(240); slider:SetMinMaxValues(.75,1.35); slider:SetValueStep(.05)
  _G[slider:GetName().."Low"]:SetText("75%"); _G[slider:GetName().."High"]:SetText("135%"); _G[slider:GetName().."Text"]:SetText("100%")
  slider:SetScript("OnValueChanged",function(self,value) value=math.floor(value*20+.5)/20; Settings().scale=value; _G[self:GetName().."Text"]:SetText(math.floor(value*100+.5).."%"); ApplySettings() end)

  local resetPos=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); resetPos:SetWidth(135); resetPos:SetHeight(24); resetPos:SetText("Reset positions"); resetPos:SetPoint("TOPLEFT",16,-370); resetPos:SetScript("OnClick",ResetPositions)
  local resetAll=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); resetAll:SetWidth(135); resetAll:SetHeight(24); resetAll:SetText("Restore defaults"); resetAll:SetPoint("LEFT",resetPos,"RIGHT",12,0)
  resetAll:SetScript("OnClick",function() AzerCoreOpsDB.settings={}; AzerCoreOpsDB.auditFilter=nil; Settings(); slider:SetValue(Settings().scale); ApplySettings(); p:GetScript("OnShow")(p); Print("Settings restored to defaults.") end)

  local diagnostics=CreateFrame("Frame",nil,p); diagnostics:SetPoint("TOPLEFT",340,-62); diagnostics:SetWidth(300); diagnostics:SetHeight(408); Backdrop(diagnostics,C.panel)
  local diagTitle=Label(diagnostics,"Compatibility diagnostics"); diagTitle:SetPoint("TOPLEFT",10,-10)
  compatUI.text=diagnostics:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.text:SetPoint("TOPLEFT",10,-38); compatUI.text:SetPoint("BOTTOMRIGHT",-10,44); compatUI.text:SetJustifyH("LEFT"); compatUI.text:SetJustifyV("TOP"); compatUI.text:SetWordWrap(true); compatUI.text:SetNonSpaceWrap(true); compatUI.text:SetTextColor(unpack(C.white))
  local check=CreateFrame("Button",nil,diagnostics,"UIPanelButtonTemplate"); check:SetWidth(150); check:SetHeight(24); check:SetText("Check compatibility"); check:SetPoint("BOTTOMLEFT",10,10); check:SetScript("OnClick",RequestCompatibility)
  RenderCompatibility()

  p:SetScript("OnShow",function()
    local s=Settings(); for key,c in pairs(controls) do c:SetChecked(s[key] and true or false) end
    slider:SetValue(s.scale)
  end)
  InterfaceOptions_AddCategory(p)

  local a=CreateFrame("Frame","AZERCORE_OPS_AuditOptionsPanel",UIParent); a.name="Audit & Instances"; a.parent="AzerCore Ops"
  local at=a:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); at:SetPoint("TOPLEFT",16,-16); at:SetText("AzerCoreOps — Audit & Instances")
  local an=a:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); an:SetPoint("TOPLEFT",at,"BOTTOMLEFT",0,-8); an:SetText("Display, filtering, bind-reset safety, and instance defaults.")
  local auditControls={}
  Check(a,auditControls,"AuditTips","Show complete audit reason tooltips","auditTooltips",-70,"Show the complete diagnostic reason while hovering.")
  Check(a,auditControls,"WrapAudit","Wrap long audit reasons","wrapAuditReasons",-102,"Use a narrower result canvas for easier reading.")
  Check(a,auditControls,"AuditWheel","Enable mouse-wheel audit scrolling","mouseWheelAudit",-134,"Scroll raid results with the mouse wheel.")
  Check(a,auditControls,"ProblemsFirst","Sort problems first","problemsFirst",-166,"Order FAIL, OFFLINE, WARN, then PASS.")
  Check(a,auditControls,"RememberFilter","Remember the selected audit filter","rememberAuditFilter",-198,"Restore the last selected result filter.")
  Check(a,auditControls,"AutoAudit","Automatically re-audit after a bind reset","autoReaudit",-230,"Repeat the last audit after an accepted bind reset.")
  Check(a,auditControls,"ConfirmMapReset","Confirm a selected map reset","confirmResetSelected",-262,"Confirm before removing one map/difficulty bind.")
  Check(a,auditControls,"ConfirmAllReset","Confirm reset of all instance binds","confirmResetAll",-294,"Confirm before removing every removable bind.")
  Check(a,auditControls,"WarnTarget","Warn when no player is selected","warnNoTarget",-326,"Prevent bind commands from accidentally applying to yourself.")
  Check(a,auditControls,"CompactRows","Use compact audit result rows","compactAuditRows",-358,"Fit more member results into the audit view.")
  Check(a,auditControls,"ShiftClick","Enable Shift-click link insertion","shiftClickInsert",-390,"With a AzerCoreOps field focused, Shift-click an item, quest, spell, or player link to insert it.")

  local diffLabel=a:CreateFontString(nil,"ARTWORK","GameFontNormal"); diffLabel:SetPoint("TOPLEFT",22,-438); diffLabel:SetText("Default instance difficulty")
  local diff=CreateFrame("Slider","AZERCORE_OPS_OptDifficulty",a,"OptionsSliderTemplate"); diff:SetPoint("TOPLEFT",22,-462); diff:SetWidth(200); diff:SetMinMaxValues(0,3); diff:SetValueStep(1)
  _G[diff:GetName().."Low"]:SetText("0"); _G[diff:GetName().."High"]:SetText("3")
  diff:SetScript("OnValueChanged",function(self,value) value=math.floor(value+.5); Settings().defaultDifficulty=value; _G[self:GetName().."Text"]:SetText(tostring(value)); if auditUI.diffBox then auditUI.diffBox:SetText(tostring(value)) end end)

  local fontLabel=a:CreateFontString(nil,"ARTWORK","GameFontNormal"); fontLabel:SetPoint("TOPLEFT",270,-438); fontLabel:SetText("Audit font size")
  local font=CreateFrame("Slider","AZERCORE_OPS_OptAuditFont",a,"OptionsSliderTemplate"); font:SetPoint("TOPLEFT",270,-462); font:SetWidth(200); font:SetMinMaxValues(8,14); font:SetValueStep(1)
  _G[font:GetName().."Low"]:SetText("8"); _G[font:GetName().."High"]:SetText("14")
  font:SetScript("OnValueChanged",function(self,value) value=math.floor(value+.5); Settings().auditFontSize=value; _G[self:GetName().."Text"]:SetText(tostring(value)); ApplySettings() end)

  a:SetScript("OnShow",function()
    local s=Settings(); for key,c in pairs(auditControls) do c:SetChecked(s[key] and true or false) end
    diff:SetValue(s.defaultDifficulty); font:SetValue(s.auditFontSize)
  end)
  InterfaceOptions_AddCategory(a)
end

local PROJECT_LINKS = {
  {label="AzerCoreOps repository", url="https://github.com/Fersantos1975/mod-azercore-ops"},
  {label="AzerothCore", url="https://github.com/azerothcore/azerothcore-wotlk"},
  {label="mod-playerbots", url="https://github.com/azerothcore/mod-playerbots"},
  {label="AzerothCore documentation", url="https://www.azerothcore.org/wiki/"},
  {label="Wowhead WotLK", url="https://www.wowhead.com/wotlk"},
}

local linkFrame, linkEdit
local function ShowCopyLink(label, url)
  if not linkFrame then
    linkFrame=CreateFrame("Frame","AZERCORE_OPS_LinkFrame",UIParent); linkFrame:SetWidth(620); linkFrame:SetHeight(145); linkFrame:SetPoint("CENTER"); linkFrame:SetFrameStrata("FULLSCREEN_DIALOG"); Backdrop(linkFrame)
    Movable(linkFrame,"link")
    local heading=Label(linkFrame,"Copy project link"); heading:SetPoint("TOPLEFT",14,-14); linkFrame.heading=heading
    local help=linkFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); help:SetPoint("TOPLEFT",14,-38); help:SetText("Press Ctrl+C to copy, then paste the address into your browser."); help:SetTextColor(unpack(C.white))
    linkEdit=Edit(linkFrame,570,false); linkEdit:SetPoint("TOPLEFT",14,-64); linkEdit:SetHeight(28)
    Button(linkFrame,"Select all",90,24,function() linkEdit:SetFocus(); linkEdit:HighlightText() end,"Select the complete address"):SetPoint("BOTTOMLEFT",14,12)
    Button(linkFrame,"Close",90,24,function() linkFrame:Hide() end,"Close this window"):SetPoint("BOTTOMRIGHT",-14,12)
  end
  linkFrame.heading:SetText(label or "Project link")
  linkEdit:SetText(url or ""); linkEdit:SetFocus(); linkEdit:HighlightText(); linkFrame:Show()
end

local function Card(parent,title,value,x,y,w,h)
  local f=CreateFrame("Frame",nil,parent); f:SetPoint("TOPLEFT",x,y); f:SetWidth(w); f:SetHeight(h); Backdrop(f,C.panel)
  local t=Label(f,title,"GameFontNormalSmall"); t:SetPoint("TOPLEFT",10,-9)
  local v=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); v:SetPoint("TOPLEFT",10,-31); v:SetPoint("BOTTOMRIGHT",-10,8); v:SetJustifyH("LEFT"); v:SetJustifyV("TOP"); v:SetWordWrap(true); v:SetText(value or ""); v:SetTextColor(unpack(C.white))
  return f,v
end

local function WorkflowStrip(parent,x,y,w)
  local strip=CreateFrame("Frame",nil,parent); strip:SetPoint("TOPLEFT",x,y); strip:SetWidth(w); strip:SetHeight(38); Backdrop(strip,C.panel)
  local phases={{"INSPECT",C.inspect},{"DIAGNOSE",C.diagnose},{"RESOLVE",C.resolve},{"OPERATE",C.operate}}
  for i,phase in ipairs(phases) do
    local label=strip:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    label:SetPoint("LEFT",14+(i-1)*(w/4),0); label:SetWidth((w/4)-16); label:SetJustifyH("CENTER")
    label:SetText(phase[1]); label:SetTextColor(unpack(phase[2]))
  end
  return strip
end

local function BuildDashboard()
  local p=NewPage("Dashboard")
  local title=Label(p,"AzerCore Ops Operations Center","GameFontNormalLarge"); title:SetPoint("TOPLEFT",18,-18)
  local intro=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); intro:SetPoint("TOPLEFT",18,-48); intro:SetPoint("TOPRIGHT",-18,-48); intro:SetJustifyH("LEFT"); intro:SetTextColor(unpack(C.white)); intro:SetText("A unified operations platform for AzerothCore administrators and Game Masters.")
  WorkflowStrip(p,18,-76,726)
  Card(p,"Instance Access","Check a dungeon or raid and identify the first access blocker for every group member.",18,-126,355,105)
  Card(p,"Quest Intelligence","Inspect faction rules, requirements, character status, and linked quest chains.",389,-126,355,105)
  Card(p,"Instance Operations","Review personal and selected-player binds, then perform guarded reset actions.",18,-247,355,105)
  Card(p,"Compatibility","Addon "..ADDON_VERSION.."\nProtocol v"..PROTOCOL_VERSION,389,-247,355,105)
  local quick=CreateFrame("Frame",nil,p); quick:SetPoint("TOPLEFT",18,-374); quick:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(quick,C.panel)
  local qh=Label(quick,"Quick actions"); qh:SetPoint("TOPLEFT",12,-12)
  Button(quick,"Open Instance Access",150,30,function() SelectTab("Instances") end,"Search instances and check group access"):SetPoint("TOPLEFT",12,-42)
  Button(quick,"Inspect Quest",150,30,function() SelectTab("Quest") end,"Open quest search and chain analysis"):SetPoint("TOPLEFT",174,-42)
  Button(quick,"Check Compatibility",150,30,function() RequestCompatibility(); OpenOptions() end,"Query the running AzerCoreOps module"):SetPoint("TOPLEFT",336,-42)
  Button(quick,"Information & Credits",170,30,function() SelectTab("Information") end,"View project links, credits, and acknowledgements"):SetPoint("TOPLEFT",498,-42)
  local note=quick:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); note:SetPoint("TOPLEFT",12,-92); note:SetPoint("BOTTOMRIGHT",-12,12); note:SetJustifyH("LEFT"); note:SetJustifyV("TOP"); note:SetWordWrap(true); note:SetTextColor(unpack(C.white)); note:SetText("Release candidate: v0.4.0-rc1\n\nThis release candidate completes the AzerCore Ops v0.4 platform foundation: unified design tokens, workflow semantics, compatibility reporting, instance access analysis, quest intelligence, instance operations, movement tools, reports, and guarded administrative actions. It is ready for server compilation and the final in-game release validation.")
end


local function BuildCourier()
  local p=NewPage("Courier")
  courierUI={active="INBOX",views={},buttons={}}

  local title=Label(p,"Courier","GameFontNormalLarge"); title:SetPoint("TOPLEFT",18,-16)
  local motto=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); motto:SetPoint("TOPLEFT",18,-42); motto:SetText("Structured communication for learning, diagnosis and collaboration."); motto:SetTextColor(unpack(C.white))
  local state=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); state:SetPoint("TOPRIGHT",-18,-20); state:SetText("|cffffff55LAYOUT PREVIEW|r"); courierUI.state=state

  local rail=CreateFrame("Frame",nil,p); rail:SetPoint("TOPLEFT",14,-70); rail:SetPoint("BOTTOMLEFT",14,14); rail:SetWidth(160); Backdrop(rail,C.bg)
  local navTitle=Label(rail,"COURIER","GameFontNormalSmall"); navTitle:SetPoint("TOPLEFT",12,-12)

  local body=CreateFrame("Frame",nil,p); body:SetPoint("TOPLEFT",184,-70); body:SetPoint("BOTTOMRIGHT",-14,14); Backdrop(body,C.bg)

  local function ShowView(key,label)
    courierUI.active=key
    for name,view in pairs(courierUI.views) do if name==key then view:Show() else view:Hide() end end
    for name,b in pairs(courierUI.buttons) do b:SetBackdropColor(unpack(name==key and C.selected or C.button)) end
    SetStatus("Courier — "..label.." layout preview")
  end
  local nav={{"INBOX","Inbox"},{"SENT","Sent"},{"APPROVED","Approved Users"},{"BLOCKED","Blocked Users"},{"PREFERENCES","Preferences"}}
  for i,item in ipairs(nav) do
    local key,label=item[1],item[2]
    local b=Button(rail,label,136,28,function() ShowView(key,label) end); b:SetPoint("TOPLEFT",12,-38-(i-1)*34); courierUI.buttons[key]=b
  end
  local compose=Button(rail,"Compose Courier",136,28,function() SetStatus("Compose Courier will be enabled when Courier transport is implemented.",true) end,"Preview of the future native Courier composer"); compose:SetPoint("BOTTOMLEFT",12,46)
  local receive=rail:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); receive:SetPoint("BOTTOMLEFT",12,16); receive:SetText("Receiving: |cff55ff55Everyone|r"); receive:SetTextColor(unpack(C.muted))

  local function View(key)
    local v=CreateFrame("Frame",nil,body); v:SetAllPoints(body); v:Hide(); courierUI.views[key]=v; return v
  end
  local function Header(v,text,sub)
    local h=Label(v,text,"GameFontNormal"); h:SetPoint("TOPLEFT",14,-12)
    local st=v:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); st:SetPoint("TOPLEFT",14,-34); st:SetText(sub); st:SetTextColor(unpack(C.muted))
  end

  local inbox=View("INBOX"); Header(inbox,"INBOX","Received Couriers and collaboration requests")
  local list=CreateFrame("Frame",nil,inbox); list:SetPoint("TOPLEFT",12,-62); list:SetPoint("BOTTOMLEFT",12,48); list:SetWidth(220); Backdrop(list,C.panel)
  local messages={{"ICC Heroic 10","Invitation","JohnGM","Urgent"},{"Quest 24874 analysis","Report","Zoly","Important"},{"New player profession help","Request","Ironpaw","Normal"}}
  for i,m in ipairs(messages) do
    local row=Button(list,"",204,58,function() courierUI.preview:SetText(string.format([[|cffffd100%s|r

Type: %s
From: %s
Priority: %s
Expires: 30 days

This is a visual Courier example. Structured delivery will be implemented next.]],m[1],m[2],m[3],m[4])) end)
    row:SetPoint("TOPLEFT",8,-8-(i-1)*62)
    local t=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); t:SetPoint("TOPLEFT",7,-5); t:SetPoint("BOTTOMRIGHT",-7,5); t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); t:SetText(string.format([[|cffffd100%s|r
%s • From %s]],m[1],m[2],m[3]))
  end
  local reader=CreateFrame("Frame",nil,inbox); reader:SetPoint("TOPLEFT",242,-62); reader:SetPoint("BOTTOMRIGHT",-12,48); Backdrop(reader,C.panel)
  local rh=Label(reader,"COURIER ENVELOPE","GameFontNormalSmall"); rh:SetPoint("TOPLEFT",12,-12)
  courierUI.preview=reader:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); courierUI.preview:SetPoint("TOPLEFT",12,-40); courierUI.preview:SetPoint("BOTTOMRIGHT",-12,54); courierUI.preview:SetJustifyH("LEFT"); courierUI.preview:SetJustifyV("TOP"); courierUI.preview:SetWordWrap(true); courierUI.preview:SetTextColor(unpack(C.white)); courierUI.preview:SetText("Select a Courier to read its envelope, body and attachments.")
  Button(reader,"Reply",62,22,function() SetStatus("Courier replies are not active in this layout preview.",true) end):SetPoint("BOTTOMLEFT",12,14)
  Button(reader,"Pin",54,22,function() SetStatus("Pinned Couriers will never expire.") end):SetPoint("BOTTOMLEFT",80,14)
  Button(reader,"Delete",58,22,function() SetStatus("Delete is disabled in the layout preview.",true) end):SetPoint("BOTTOMRIGHT",-12,14)
  local footer=CreateFrame("Frame",nil,inbox); footer:SetPoint("BOTTOMLEFT",12,12); footer:SetPoint("BOTTOMRIGHT",-12,12); footer:SetHeight(28); Backdrop(footer,C.panel)
  Button(footer,"Refresh",66,20,function() SetStatus("Courier Inbox preview refreshed.") end):SetPoint("LEFT",6,0)
  Button(footer,"Mark Read",76,20,function() SetStatus("Courier marked read in preview.") end):SetPoint("LEFT",78,0)
  Button(footer,"Clear Inbox",82,20,function() SetStatus("Clear Inbox is disabled in the layout preview.",true) end):SetPoint("RIGHT",-6,0)

  local function EmptyView(key,titleText,subText,bodyText)
    local v=View(key); Header(v,titleText,subText)
    local panel=CreateFrame("Frame",nil,v); panel:SetPoint("TOPLEFT",12,-62); panel:SetPoint("BOTTOMRIGHT",-12,12); Backdrop(panel,C.panel)
    local text=panel:CreateFontString(nil,"OVERLAY","GameFontHighlight"); text:SetPoint("CENTER",0,20); text:SetWidth(430); text:SetJustifyH("CENTER"); text:SetTextColor(unpack(C.white)); text:SetText(bodyText)
    local badge=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); badge:SetPoint("TOP",text,"BOTTOM",0,-18); badge:SetText("|cffffff55COURIER FRAMEWORK PREVIEW|r")
  end
  EmptyView("SENT","SENT","Couriers sent through the native AzerCore Ops network","Sent Couriers will appear here with delivery, read and expiration status.")
  EmptyView("APPROVED","APPROVED USERS","Trusted senders allowed by your receiving policy","Approved users will be managed here. Blocked users always take precedence.")
  EmptyView("BLOCKED","BLOCKED USERS","Senders who can never deliver Couriers to you","Blocked-user management and reasons will appear here.")

  local pref=View("PREFERENCES"); Header(pref,"PREFERENCES","Control who may contact you and how long Couriers are retained")
  local pp=CreateFrame("Frame",nil,pref); pp:SetPoint("TOPLEFT",12,-62); pp:SetPoint("BOTTOMRIGHT",-12,12); Backdrop(pp,C.panel)
  local pt=pp:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); pt:SetPoint("TOPLEFT",16,-18); pt:SetJustifyH("LEFT"); pt:SetTextColor(unpack(C.white)); pt:SetText([[Receiving policy

  • Disabled
  • Approved Users Only
  • Party / Raid
  • Guild
  • |cff55ff55Everyone|r

Message retention

  • 1 day
  • 7 days
  • |cff55ff5530 days (default)|r
  • 90 days
  • Never

Pinned Couriers never expire. Expired Couriers are automatically deleted.]])

  ShowView("INBOX","Inbox")
end

local function BuildInformation()
  local p=NewPage("Information")
  local title=Label(p,"Platform Information & Credits","GameFontNormalLarge"); title:SetPoint("TOPLEFT",18,-18)

  local platform=CreateFrame("Frame",nil,p); platform:SetPoint("TOPLEFT",18,-55); platform:SetPoint("TOPRIGHT",-18,-55); platform:SetHeight(360); Backdrop(platform,C.panel)
  local ph=Label(platform,"Platform status"); ph:SetPoint("TOPLEFT",12,-12)
  compatUI.informationText=platform:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  compatUI.informationText:SetPoint("TOPLEFT",12,-38); compatUI.informationText:SetPoint("BOTTOMRIGHT",-12,48)
  compatUI.informationText:SetJustifyH("LEFT"); compatUI.informationText:SetJustifyV("TOP"); compatUI.informationText:SetWordWrap(true); compatUI.informationText:SetTextColor(unpack(C.white))
  Button(platform,"Check compatibility",155,26,RequestCompatibility,"Query module, registry, permissions, and build information"):SetPoint("BOTTOMLEFT",12,14)

  local credits=CreateFrame("Frame",nil,p); credits:SetPoint("TOPLEFT",18,-431); credits:SetPoint("BOTTOMRIGHT",-389,18); Backdrop(credits,C.panel)
  local ch=Label(credits,"Project & credits"); ch:SetPoint("TOPLEFT",12,-12)
  local ct=credits:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ct:SetPoint("TOPLEFT",12,-38); ct:SetPoint("BOTTOMRIGHT",-12,12); ct:SetJustifyH("LEFT"); ct:SetJustifyV("TOP"); ct:SetWordWrap(true); ct:SetTextColor(unpack(C.white)); ct:SetText("AzerCore Ops is an open-source operations platform for AzerothCore administrators and Game Masters.\n\nCreated and maintained by |cffffd100Fernando Santos|r.\n\nBuilt with AzerothCore, mod-playerbots, and AI-assisted development from OpenAI ChatGPT.\n\nLicense: GPL-3.0")

  local resources=CreateFrame("Frame",nil,p); resources:SetPoint("TOPLEFT",389,-431); resources:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(resources,C.panel)
  local rh=Label(resources,"Project resources"); rh:SetPoint("TOPLEFT",12,-12)
  for i,item in ipairs(PROJECT_LINKS) do
    local entry=item
    Button(resources,entry.label,315,26,function() ShowCopyLink(entry.label,entry.url) end,"Open a selectable copy box for this address"):SetPoint("TOPLEFT",20,-38-(i-1)*32)
  end
  RenderCompatibility()
end

local function BuildUI()
  main=CreateFrame("Frame","AZERCORE_OPS_MainFrame",UIParent); main:SetWidth(980); main:SetHeight(650); main:SetClampedToScreen(true); main:SetFrameStrata("DIALOG"); Backdrop(main); RestorePoint(main,"main","CENTER",0,0); Movable(main,"main")
  local logo=main:CreateTexture(nil,"ARTWORK"); logo:SetTexture("Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"); logo:SetWidth(30); logo:SetHeight(30); logo:SetPoint("TOPLEFT",12,-7)
  local title=Label(main,"AzerCore Ops  |cffaaaaaa"..ADDON_VERSION.."|r"); title:SetPoint("TOPLEFT",50,-15)
  Button(main,"?",22,20,OpenOptions,"Open AzerCoreOps options"):SetPoint("TOPRIGHT",-66,-10)
  Button(main,"_",22,20,HideMain,"Minimize to floating button"):SetPoint("TOPRIGHT",-38,-10)
  Button(main,"X",22,20,HideMain,"Close"):SetPoint("TOPRIGHT",-10,-10)

  local sidebar=CreateFrame("Frame",nil,main); sidebar:SetPoint("TOPLEFT",10,-48); sidebar:SetPoint("BOTTOMLEFT",10,32); sidebar:SetWidth(160); Backdrop(sidebar,C.panel)
  local navTitle=Label(sidebar,"NAVIGATION","GameFontNormalSmall"); navTitle:SetPoint("TOPLEFT",14,-14)
  local nav={
    {"Dashboard","Dashboard"}, {"Instance Access","Instances"}, {"Character","Character"},
    {"Quests","Quest"}, {"NPCs","NPC"}, {"Movement","Teleport"},
    {"Items","Item"}, {"Courier","Courier"}, {"Information","Information"},
  }
  for i,item in ipairs(nav) do
    local label,pageName=item[1],item[2]
    local b=Button(sidebar,label,132,30,function() SelectTab(pageName) end); b:SetPoint("TOPLEFT",14,-38-(i-1)*36); tabs[pageName]=b
  end
  local build=sidebar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); build:SetPoint("BOTTOMLEFT",14,14); build:SetPoint("BOTTOMRIGHT",-14,14); build:SetJustifyH("LEFT"); build:SetTextColor(.65,.65,.65,1); build:SetText("Protocol v"..PROTOCOL_VERSION.."\nDevelopment build")

  content=CreateFrame("Frame",nil,main); content:SetPoint("TOPLEFT",180,-48); content:SetPoint("BOTTOMRIGHT",-10,32); Backdrop(content,C.panel)
  statusText=main:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); statusText:SetPoint("BOTTOMLEFT",14,11); statusText:SetPoint("BOTTOMRIGHT",-14,11); statusText:SetJustifyH("LEFT")
  BuildDashboard(); BuildCharacter(); BuildNPC(); BuildQuest(); BuildTeleport(); BuildItem(); BuildInstances(); BuildCourier(); BuildInformation(); SelectTab(AzerCoreOpsDB.activeTab or "Dashboard")

  mini=CreateFrame("Button","AZERCORE_OPS_MiniButton",UIParent); mini:SetWidth(36); mini:SetHeight(28); mini:SetClampedToScreen(true); mini:SetFrameStrata("HIGH"); mini:SetFrameLevel(100); Backdrop(mini); RestorePoint(mini,"mini","CENTER",290,0); Movable(mini,"mini")
  local mi=mini:CreateTexture(nil,"ARTWORK"); mi:SetTexture("Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"); mi:SetAllPoints()
  local mt=mini:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); mt:SetPoint("CENTER"); mt:SetText(""); mt:SetTextColor(unpack(C.gold))
  mini:SetScript("OnClick",function(self) if self._dragged then self._dragged=nil; return end; ShowMain() end); mini:Hide()

  minimapButton=CreateFrame("Button","AZERCORE_OPS_MinimapButton",Settings().mbfCompatibility and UIParent or Minimap); minimapButton:SetWidth(24); minimapButton:SetHeight(22); minimapButton:SetFrameStrata("HIGH"); minimapButton:SetFrameLevel(100); minimapButton:RegisterForClicks("LeftButtonUp","RightButtonUp"); minimapButton:RegisterForDrag("LeftButton")
  local bg=minimapButton:CreateTexture(nil,"BACKGROUND"); bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); bg:SetAllPoints()
  local bd=minimapButton:CreateTexture(nil,"OVERLAY"); bd:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); bd:SetPoint("TOPLEFT",-6,6); bd:SetPoint("BOTTOMRIGHT",6,-6)
  local icon=minimapButton:CreateTexture(nil,"ARTWORK"); icon:SetTexture("Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"); icon:SetPoint("TOPLEFT",2,-2); icon:SetPoint("BOTTOMRIGHT",-2,2)
  local tx=minimapButton:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); tx:SetPoint("CENTER"); tx:SetText(""); tx:SetTextColor(unpack(C.gold))
  minimapButton:SetScript("OnClick",function(_,button) if button=="RightButton" then HideMain() elseif main:IsShown() then HideMain() else ShowMain() end end)
  minimapButton:SetScript("OnDragStart",function(self) self:SetScript("OnUpdate",function() local mx,my=Minimap:GetCenter(); local px,py=GetCursorPosition(); local s=Minimap:GetEffectiveScale(); AzerCoreOpsDB.minimapAngle=math.deg(math.atan2(py/s-my,px/s-mx)); PositionMinimap() end) end)
  minimapButton:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end); PositionMinimap(); ApplySettings()
  if Settings().startMinimized then HideMain() end
end

local events=CreateFrame("Frame"); events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_ENTERING_WORLD"); events:RegisterEvent("CHAT_MSG_SYSTEM"); events:RegisterEvent("UPDATE_INSTANCE_INFO"); events:RegisterEvent("PLAYER_TARGET_CHANGED")
local compatibilityRequested=false
events:SetScript("OnEvent",function(_,event,arg1)
  if event=="ADDON_LOADED" then if arg1~=ADDON then return end; AzerCoreOpsDB=AzerCoreOpsDB or {}; Settings(); BuildOptions(); BuildUI(); Print("v"..ADDON_VERSION.." loaded. Type /azercoreops help")
  elseif event=="PLAYER_ENTERING_WORLD" and not compatibilityRequested then compatibilityRequested=true; SendChatMessage(CMD.version,"SAY")
  elseif event=="UPDATE_INSTANCE_INFO" then RefreshMyInstances(true)
  elseif event=="PLAYER_TARGET_CHANGED" then
    RenderInstances(); UpdateQuestContextLabel()
    if shareFrame and shareFrame:IsShown() and shareFrame.RefreshLive then shareFrame:RefreshLive() end
    if questUI.activeWorkspace=="TARGET" and questUI.targetLogActive and UnitExists("target") and UnitIsPlayer("target") then
      UpdateQuestInspectorTarget(false); OpenTargetQuestLog()
    elseif questUI.activeWorkspace=="TARGET" and questUI.lockedQuestId and UnitExists("target") and UnitIsPlayer("target") then
      UpdateQuestInspectorTarget(true)
    else
      UpdateQuestInspectorTarget(false)
    end
  elseif event=="CHAT_MSG_SYSTEM" and tostring(arg1):find("^AZERCORE_OPS|") then
    local kind=tostring(arg1):match("^AZERCORE_OPS|([^|]+)")
    local f=ParseAuditFields(arg1)
    if kind=="VERSION" then
      compatUI.data=f; compatUI.received.VERSION=true; RenderCompatibility()
      local ok=tostring(f.protocol or "")==PROTOCOL_VERSION
      SetStatus(ok and "Module detected; verifying protocol and loading platform data..." or "Addon and module protocols do not match.",not ok)
    elseif kind=="CAPABILITIES" then
      compatUI.data=compatUI.data or {}; compatUI.received.CAPABILITIES=true
      compatUI.data.capabilities=f.values or ""; compatUI.data.features=f.features or ""
      RenderCompatibility(); SetStatus("Capability registry loaded; reading permissions...")
    elseif kind=="PERMISSIONS" then
      compatUI.data=compatUI.data or {}; compatUI.received.PERMISSIONS=true
      compatUI.data.permissions=f.values or ""
      RenderCompatibility(); SetStatus("Permission registry loaded; reading build information...")
    elseif kind=="BUILD" then
      compatUI.data=compatUI.data or {}; compatUI.received.BUILD=true
      for key,value in pairs(f) do compatUI.data[key]=value end
      RenderCompatibility(); SetStatus("Core and module build information loaded...")
    elseif kind=="BUILD_EXT" then
      compatUI.data=compatUI.data or {}; compatUI.received.BUILD_EXT=true
      for key,value in pairs(f) do compatUI.data[key]=value end
      RenderCompatibility()
      local state=Platform:Compatibility(PROTOCOL_VERSION)
      SetStatus(state=="compatible" and "Platform ready: fully compatible." or state=="limited" and "Platform ready with limited compatibility." or "Platform compatibility check completed.",state=="incompatible")
    elseif kind=="ERROR" then
      SetStatus(f.reason or "AzerCore Ops server-module error",true)
    elseif kind=="QUEST_SEARCH" then
      if #questUI.results<50 then table.insert(questUI.results,f) end; RenderQuest(); SetStatus(#questUI.results.." quest match(es) with faction data")
    elseif kind=="QUEST_SEARCH_END" then
      if #questUI.results==0 then SetStatus("No matching quests found.",true) else SetStatus(#questUI.results.." quest result(s); select one for details") end
    elseif kind=="QUEST_INFO" then
      questUI.info=f; questUI.chain={}; questUI.selectedId=tonumber(f.id) or questUI.selectedId
      if f.player and f.player~="" then
        questUI.contextName=f.player
        questUI.contextKind=(f.player==(UnitName("player") or "")) and "SELF" or "TARGET"
      end
      if f.id then SetQuestId(f.id) end
      if f.title and tonumber(f.id)==tonumber(questUI.lockedQuestId) then
        questUI.lockedQuestTitle=f.title
        if questUI.lockedLabel then questUI.lockedLabel:SetText(string.format("|cffffd100LOCKED|r  %s\n|cffaaaaaaQuest ID: %d|r",f.title,tonumber(f.id))) end
        UpdateLockedQuestHistory()
      end
      if f.title and questSearchBox and questUI.activeWorkspace=="DATABASE" then questSearchBox:SetText(f.title) end
      if #questUI.results==0 and f.id then table.insert(questUI.results,{id=f.id,title=f.title,faction=f.faction,eligibility=f.eligibility,min=f.min}) end
      RenderQuest(); SetStatus("Loaded quest "..(f.id or "?").." compatibility for "..(f.player or questUI.contextName or "current context"))
      if shareFrame and shareFrame:IsShown() and shareFrame.RefreshLive then shareFrame:RefreshLive() end
    elseif kind=="QUEST_CHAIN" then
      table.insert(questUI.chain,f); RenderQuest()
    elseif kind=="QUEST_INFO_END" then
      RenderQuest(); SetStatus("Quest details and chain loaded")
    elseif kind=="QUEST_AUDIT_BEGIN" then
      questUI.auditActive=true; questUI.auditMembers={}; questUI.auditQuest=tonumber(f.id); RenderQuest(); SetStatus("Quest group audit started")
    elseif kind=="QUEST_AUDIT_MEMBER" then
      table.insert(questUI.auditMembers,f); RenderQuest()
    elseif kind=="QUEST_AUDIT_END" then
      RenderQuest(); SetStatus("Quest group audit completed for "..#questUI.auditMembers.." member(s)")
      if shareFrame and shareFrame:IsShown() and shareFrame.RefreshLive then shareFrame:RefreshLive() end
    elseif kind=="QUEST_LOG_BEGIN" then
      questUI.targetLogActive=true; questUI.targetLogLoading=true; questUI.targetLogEntries={}; questUI.targetLogPlayer=f.player or questUI.targetLogPlayer; questUI.targetLogError=nil
      RenderQuest(); SetStatus("Loading "..(questUI.targetLogPlayer or "target").."'s quest log...")
    elseif kind=="QUEST_LOG_ENTRY" then
      table.insert(questUI.targetLogEntries,f); RenderQuest()
    elseif kind=="QUEST_LOG_END" then
      questUI.targetLogLoading=false; questUI.targetLogPlayer=f.player or questUI.targetLogPlayer; RenderQuest()
      SetStatus("Loaded "..#questUI.targetLogEntries.." quest(s) for "..(questUI.targetLogPlayer or "target"))
      if shareFrame and shareFrame:IsShown() and shareFrame.RefreshLive then shareFrame:RefreshLive() end
    elseif kind=="QUEST_ERROR" then
      if questUI.targetLogLoading then questUI.targetLogLoading=false; questUI.targetLogError=f.reason or "Quest-log inspection failed"; RenderQuest() end
      SetStatus(f.reason or "Quest module error",true)
    elseif kind=="SEARCH" then
      if #auditUI.search<8 then table.insert(auditUI.search,f) end; RenderAudit(); SetStatus(#auditUI.search.." instance match(es)")
    elseif kind=="BEGIN" then
      auditUI.members={}; RenderAudit(); SetStatus("Auditing "..(f.name or "instance").."...")
    elseif kind=="MEMBER" then
      table.insert(auditUI.members,f); RenderAudit()
    elseif kind=="END" then
      local pass,fail,warn=0,0,0; for _,r in ipairs(auditUI.members) do if r.result=="PASS" then pass=pass+1 elseif r.result=="WARN" then warn=warn+1 else fail=fail+1 end end
      SetStatus(string.format("Audit complete: %d pass, %d warning, %d fail/offline",pass,warn,fail))
    elseif kind=="ERROR" then SetStatus(f.reason or "Instance audit error",true) end
  elseif event=="CHAT_MSG_SYSTEM" and instanceUI.captureUntil>0 and GetTime()<=instanceUI.captureUntil then
    local plain=tostring(arg1):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local map,inst,perm,diff,canReset,ttr=plain:match("map:%s*(%d+),%s*inst:%s*(%d+),%s*perm:%s*(%a+),%s*diff:%s*(%d+),%s*canReset:%s*(%a+),%s*TTR:%s*(.-)%s*$")
    if map then
      table.insert(instanceUI.target,{map=tonumber(map),instance=tonumber(inst),perm=perm,difficulty=tonumber(diff),canReset=canReset,ttr=ttr})
      RenderInstances(); SetStatus(#instanceUI.target.." selected-player bind(s) captured")
    end
  elseif event=="CHAT_MSG_SYSTEM" and lookup.kind and GetTime()<=lookup.expires then
    local pattern=lookup.kind=="quest" and "|Hquest:(%d+)[^|]*|h([^|]+)|h" or "|Hitem:(%d+)[^|]*|h([^|]+)|h"
    for id,title in tostring(arg1):gmatch(pattern) do
      StoreLookupResult(id,title,arg1:match("(|H"..lookup.kind..":"..id.."[^|]*|h[^|]+|h)"),"")
    end
    -- Playerbot builds commonly print plain lookup lines, for example:
    -- 24510 - [Inside the Frozen Citadel] [Rewarded]
    local plain=tostring(arg1):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local id,title,suffix=plain:match("^%s*(%d+)%s*%-%s*(%b[])%s*(.-)%s*$")
    if id and title then StoreLookupResult(id,title,nil,suffix) end
  end
end)

-- Structured module messages are consumed by AzerCoreOps and hidden from normal chat.
if ChatFrame_AddMessageEventFilter then
  local function IsAzerCoreOpsProtocol(message)
    local plain=tostring(message or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    return plain:find("AZERCORE_OPS|",1,true)~=nil
      or plain:find("AZERCORE-OPS|",1,true)~=nil
  end
  local function HideProtocol(_,_,message)
    -- Protocol traffic is internal application data and must never be
    -- displayed in normal player chat.
    return IsAzerCoreOpsProtocol(message)
  end
  for _,eventName in ipairs({"CHAT_MSG_SYSTEM","CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_WHISPER","CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_GUILD","CHAT_MSG_OFFICER","CHAT_MSG_CHANNEL"}) do
    ChatFrame_AddMessageEventFilter(eventName,HideProtocol)
  end
  ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY",function(_,_,message)
    local plain=tostring(message or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    return Settings().hideAuditChat and plain:find("^%s*%.")~=nil
  end)
end

-- WotLK does not route Quest Log shift-clicks to arbitrary edit boxes the way it does item links.
-- Capture the Quest Log title click explicitly when an AzerCore Ops field has focus.
if hooksecurefunc and QuestLogTitleButton_OnClick then
  hooksecurefunc("QuestLogTitleButton_OnClick",function(self)
    if not IsShiftKeyDown() or not activeInput or not activeInput:HasFocus() then return end
    local index=self and self.GetID and self:GetID()
    local link=index and GetQuestLink and GetQuestLink(index)
    if link and InsertAzerCoreOpsLink(link) then
      local id=link:match("|Hquest:(%d+)")
      local title=link:match("|h%[([^%]]+)%]|h")
      if id then questUI.selectedId=tonumber(id); SetQuestId(id) end
      if title and questSearchBox then questSearchBox:SetText(title) end
    end
  end)
end

SLASH_AZERCORE_OPS1="/azercoreops"; SLASH_AZERCORE_OPS2="/ro"; SlashCmdList.AZERCORE_OPS=function(msg)
  msg=(msg or ""):lower():match("^%s*(.-)%s*$")
  if msg=="reset" then ResetPositions()
  elseif msg=="options" or msg=="config" then OpenOptions()
  elseif msg=="help" then Print("/azercoreops - toggle, /azercoreops options - settings, /azercoreops reset - reset positions")
  elseif main:IsShown() then HideMain() else ShowMain() end
end
