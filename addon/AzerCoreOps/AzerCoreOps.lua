local ADDON = ...

-- AzerCore Ops Platform 0.5.0
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
  history={},historyIndex=0,resultOffset=0,auditFilter="ALL",auditText=nil,auditChild=nil,questIdInternal=false,contextName=nil,contextKind="SELF",contextLabel=nil}
local compatUI={data=nil,text=nil,informationText=nil,received={}}
local instanceUI={my={},target={},captureUntil=0,myRows={},targetRows={},myOffset=0,targetOffset=0,mapBox=nil,diffBox=nil,targetLabel=nil}
local auditUI={search={},members={},searchRows={},memberRows={},filterButtons={},filtered={},mapBox=nil,diffBox=nil,summary=nil,scroll=nil,scrollChild=nil,horizontal=nil,filter="ALL",lastMap=nil,lastDifficulty=nil,reportEdit=nil}
local exportFrame, exportEdit
local ShowSelectableReport
local defaults={
  startMinimized=true,showMinimap=true,showMini=true,mbfCompatibility=true,scale=1,
  confirmCommands=true,hideAuditChat=true,defaultDifficulty=0,
  auditTooltips=true,wrapAuditReasons=true,mouseWheelAudit=true,problemsFirst=false,
  rememberAuditFilter=true,autoReaudit=false,confirmResetSelected=true,confirmResetAll=true,
  warnNoTarget=true,compactAuditRows=false,auditFontSize=10,shiftClickInsert=true,
}
local ADDON_VERSION="0.5.0"
local PROTOCOL_VERSION="1"
local TESTED_CORE="bf25eae704f5"
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
end

local function SetQuestId(value)
  if not questIdBox then return end
  questUI.questIdInternal=true
  questIdBox:SetText(value and tostring(value) or "")
  questUI.questIdInternal=false
end

local function SelectedQuestId()
  if questUI.info and tonumber(questUI.info.id) then return tonumber(questUI.info.id) end
  if questUI.selectedId then return tonumber(questUI.selectedId) end
end

local function QuestHistory()
  AzerCoreOpsDB.questSearchHistory=AzerCoreOpsDB.questSearchHistory or {}
  questUI.history=AzerCoreOpsDB.questSearchHistory
  return questUI.history
end

local function PushQuestHistory(value)
  value=tostring(value or ""):match("^%s*(.-)%s*$")
  if value=="" then return end
  local history=QuestHistory()
  for i=#history,1,-1 do if history[i]==value then table.remove(history,i) end end
  table.insert(history,1,value)
  while #history>50 do table.remove(history) end
  questUI.historyIndex=0
end

local function ShowQuestHistory(delta)
  local history=QuestHistory()
  if #history==0 then SetStatus("Quest search history is empty.",true); return end
  questUI.historyIndex=math.max(1,math.min(#history,(questUI.historyIndex or 0)+delta))
  questSearchBox:SetText(history[questUI.historyIndex] or "")
  questSearchBox:SetFocus(); questSearchBox:HighlightText()
  SetStatus("Saved quest search "..questUI.historyIndex.." of "..#history)
end

local function ShowSavedQuestHistory()
  local history=QuestHistory()
  if #history==0 then SetStatus("Quest search history is empty.",true); return end
  local lines={"AzerCore Ops saved quest searches",""}
  for i,value in ipairs(history) do table.insert(lines,string.format("%02d. %s",i,value)) end
  ShowSelectableReport("Saved quest search history",table.concat(lines,"\n"))
end

StaticPopupDialogs["AZERCORE_OPS_CLEAR_QUEST_HISTORY"]={
  text="Delete all saved Quest Intelligence search history?\n\nThis cannot be undone.",button1=YES,button2=NO,timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function() AzerCoreOpsDB.questSearchHistory={}; questUI.history=AzerCoreOpsDB.questSearchHistory; questUI.historyIndex=0; SetStatus("Saved quest search history deleted.") end
}

local RequestQuestInfo

local function RunQuestSearch()
  local raw=(questSearchBox:GetText() or ""):match("^%s*(.-)%s*$")
  if raw=="" then SetStatus("Enter a quest title or Quest ID.",true); return end
  PushQuestHistory(raw)
  local numeric=tonumber(raw)
  if numeric and numeric>0 and numeric==math.floor(numeric) then
    questUI.results={}; questUI.resultOffset=0; questUI.selectedId=numeric; SetQuestId(numeric); RenderQuest(); RequestQuestInfo(numeric); return
  end
  questUI.results={}; questUI.resultOffset=0; questUI.info=nil; questUI.chain={}; questUI.selectedId=nil; SetQuestId(nil); RenderQuest()
  SendCommand(string.format(CMD.questSearch,raw)); SetStatus("Searching quests by partial title...")
end

local function ClearQuestSearch()
  questSearchBox:SetText(""); SetQuestId(nil); questUI.results={}; questUI.resultOffset=0; questUI.info=nil; questUI.selectedId=nil; questUI.chain={}; questUI.auditMembers={}; questUI.auditActive=false
  RenderQuest(); SetStatus("Quest workspace cleared.")
end

local function LinkSelectedQuest()
  local id=SelectedQuestId()
  if not id then SetStatus("Select or inspect a quest first.",true); return end
  local title=(questUI.info and questUI.info.title) or (questSearchBox:GetText()~="" and questSearchBox:GetText()) or ("Quest "..id)
  local link="|cff808080|Hquest:"..id..":0|h["..title.."]|h|r"
  local chat=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
  if chat then chat:Insert(link); SetStatus("Inserted quest link into chat.")
  else SetStatus("Open a chat input, then press Link to insert the quest link.",true) end
end

RequestQuestInfo=function(id)
  id=tonumber(id)
  if not id then SetStatus("Select a valid quest first.",true); return end
  questUI.info=nil; questUI.chain={}; questUI.auditActive=false; questUI.auditMembers={}; questUI.selectedId=id; SetQuestId(id); RenderQuest()
  SendCommand(string.format(CMD.questInfo,id)); SetStatus("Loading quest "..id.." details...")
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

local function BuildQuest()
  local p=NewPage("Quest")
  QuestHistory()

  local title=Label(p,"Quest Intelligence","GameFontNormalLarge"); title:SetPoint("TOPLEFT",12,-8)
  local subtitle=Label(p,"Search, inspect, diagnose and operate on every quest lifecycle state.","GameFontHighlightSmall"); subtitle:SetTextColor(unpack(C.white)); subtitle:SetPoint("TOPLEFT",12,-27)

  Button(p,"<",28,24,function() ShowQuestHistory(1) end,"Previous saved quest search"):SetPoint("TOPLEFT",12,-55)
  questSearchBox=AddField(p,"Quest title or ID",48,-38,386,false); questSearchBox.azerCoreOpsExpected="quest"; questSearchBox.azerCoreOpsPlain=true
  Button(p,">",28,24,function() ShowQuestHistory(-1) end,"Next saved quest search"):SetPoint("TOPLEFT",441,-55)
  Button(p,"Search",72,24,RunQuestSearch,"Search by partial title or inspect a numeric Quest ID"):SetPoint("TOPLEFT",476,-55)
  Button(p,"Clear",58,24,ClearQuestSearch,"Clear the current Quest Intelligence workspace"):SetPoint("TOPLEFT",554,-55)
  Button(p,"Link",58,24,LinkSelectedQuest,"Insert the selected quest link into the active chat input"):SetPoint("TOPLEFT",618,-55)
  questSearchBox:SetScript("OnEnterPressed",function(self) self:ClearFocus(); RunQuestSearch() end)

  local selectionBar=CreateFrame("Frame",nil,p); selectionBar:SetPoint("TOPLEFT",12,-88); selectionBar:SetWidth(666); selectionBar:SetHeight(30); Backdrop(selectionBar,C.panel)
  local sid=Label(selectionBar,"Selected Quest ID","GameFontNormalSmall"); sid:SetPoint("LEFT",8,0)
  questIdBox=Edit(selectionBar,92,false); questIdBox:SetPoint("LEFT",sid,"RIGHT",8,0); questIdBox:SetText(""); questIdBox.azerCoreOpsExpected="quest"; questIdBox:EnableMouse(true); questIdBox:SetAutoFocus(false)
  questIdBox:SetScript("OnTextChanged",function(self,userInput) if userInput and not questUI.questIdInternal then SetQuestId(SelectedQuestId()) end end)
  questUI.contextName=questUI.contextName or UnitName("player") or "Self"
  questUI.contextKind=questUI.contextKind or "SELF"
  questUI.contextLabel=selectionBar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questUI.contextLabel:SetPoint("LEFT",questIdBox,"RIGHT",12,0)
  questUI.contextLabel:SetWidth(245); questUI.contextLabel:SetJustifyH("LEFT"); questUI.contextLabel:SetTextColor(unpack(C.white))
  UpdateQuestContextLabel()
  Button(selectionBar,"History",76,22,ShowSavedQuestHistory,"Open all automatically saved quest searches"):SetPoint("RIGHT",-104,0)
  Button(selectionBar,"Delete History",98,22,function() StaticPopup_Show("AZERCORE_OPS_CLEAR_QUEST_HISTORY") end,"Delete all saved quest search history after confirmation"):SetPoint("RIGHT",-4,0)

  local actionBar=CreateFrame("Frame",nil,p); actionBar:SetPoint("TOPLEFT",12,-124); actionBar:SetWidth(666); actionBar:SetHeight(34); Backdrop(actionBar,C.panel)
  Button(actionBar,"Audit Target",94,24,AuditQuestTarget,"Switch Quest Intelligence to the selected player and refresh quest details and analysis. With no target, audit yourself."):SetPoint("LEFT",8,0)
  local actions={{"Accept",CMD.questAdd,false,76},{"Complete",CMD.questComplete,false,82},{"Reward",CMD.questReward,true,76},{"Remove",CMD.questRemove,true,76}}
  local x=108
  for _,a in ipairs(actions) do
    Button(actionBar,a[1],a[4],24,function() local id=SelectedQuestId(); if id then local cmd=string.format(a[2],id); if a[3] then Confirm(cmd) else SendCommand(cmd) end else SetStatus("Select or inspect a quest first.",true) end end):SetPoint("LEFT",x,0)
    x=x+a[4]+6
  end
  Button(actionBar,"Audit Group",98,24,RunQuestAudit,"Check this quest for every online group or raid member"):SetPoint("LEFT",452,0)
  Button(actionBar,"Quest Log",94,24,function() ToggleQuestLog() end,"Open the Blizzard quest log"):SetPoint("LEFT",554,0)

  local contentTop=-166
  local results=CreateFrame("Frame",nil,p); results:SetPoint("TOPLEFT",12,contentTop); results:SetPoint("BOTTOMLEFT",12,132); results:SetWidth(285); Backdrop(results,C.panel)
  local rh=Label(results,"Quest matches","GameFontNormalSmall"); rh:SetPoint("TOPLEFT",8,-7)
  questUI.summary=results:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.summary:SetPoint("TOPRIGHT",-28,-7); questUI.summary:SetTextColor(unpack(C.white))
  Button(results,"^",18,18,function() questUI.resultOffset=math.max(0,(questUI.resultOffset or 0)-1); RenderQuest() end,"Scroll results up"):SetPoint("TOPRIGHT",-5,-24)
  Button(results,"v",18,18,function() questUI.resultOffset=math.min(math.max(0,#questUI.results-5),(questUI.resultOffset or 0)+1); RenderQuest() end,"Scroll results down"):SetPoint("BOTTOMRIGHT",-5,6)
  for i=1,5 do
    local row=Button(results,"",249,36,function(self)
      if not self.id then return end
      questUI.selectedId=self.id; SetQuestId(self.id); questSearchBox:SetText(self.title or ""); RequestQuestInfo(self.id)
    end)
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",6,-3); row.text:SetPoint("BOTTOMRIGHT",-6,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP")
    row:SetPoint("TOPLEFT",8,-27-(i-1)*38); row:Hide(); questUI.rows[i]=row
  end

  local details=CreateFrame("Frame",nil,p); details:SetPoint("TOPLEFT",305,contentTop); details:SetPoint("BOTTOMLEFT",305,132); details:SetWidth(184); Backdrop(details,C.panel)
  local dh=Label(details,"Quest information","GameFontNormalSmall"); dh:SetPoint("TOPLEFT",8,-7)
  local detailScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_QuestDetailScroll",details,"UIPanelScrollFrameTemplate"); detailScroll:SetPoint("TOPLEFT",8,-27); detailScroll:SetPoint("BOTTOMRIGHT",-28,31); detailScroll:EnableMouseWheel(true); questUI.detailScroll=detailScroll
  questUI.detailChild=CreateFrame("Frame",nil,detailScroll); questUI.detailChild:SetWidth(142); questUI.detailChild:SetHeight(180); detailScroll:SetScrollChild(questUI.detailChild)
  questUI.detailText=CreateFrame("EditBox",nil,questUI.detailChild); questUI.detailText:SetPoint("TOPLEFT",0,0); questUI.detailText:SetWidth(142); questUI.detailText:SetHeight(180); questUI.detailText:SetMultiLine(true); questUI.detailText:SetAutoFocus(false); questUI.detailText:SetFontObject(GameFontHighlightSmall); questUI.detailText:SetTextColor(unpack(C.white)); questUI.detailText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  Button(details,"Copy / Export",90,20,ShowQuestExport,"Copy or export quest information and chain"):SetPoint("BOTTOMRIGHT",-7,5)
  detailScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)

  local audit=CreateFrame("Frame",nil,p); audit:SetPoint("TOPLEFT",497,contentTop); audit:SetPoint("BOTTOMRIGHT",-12,132); Backdrop(audit,C.panel)
  local ah=Label(audit,"Group analysis","GameFontNormalSmall"); ah:SetPoint("TOPLEFT",8,-7)
  questUI.auditSummary=audit:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.auditSummary:SetPoint("TOPRIGHT",-8,-7); questUI.auditSummary:SetTextColor(unpack(C.white))
  local filters={{"All","ALL"},{"+ Pass","PASS"},{"! Warn","WARN"},{"X Fail","FAIL"}}
  for i,f in ipairs(filters) do Button(audit,f[1],43,18,function() questUI.auditFilter=f[2]; RenderQuest() end):SetPoint("TOPLEFT",6+(i-1)*45,-24) end
  local auditScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_QuestAuditScroll",audit,"UIPanelScrollFrameTemplate"); auditScroll:SetPoint("TOPLEFT",8,-48); auditScroll:SetPoint("BOTTOMRIGHT",-28,31); auditScroll:EnableMouseWheel(true); questUI.auditScroll=auditScroll
  questUI.auditChild=CreateFrame("Frame",nil,auditScroll); questUI.auditChild:SetWidth(142); questUI.auditChild:SetHeight(180); auditScroll:SetScrollChild(questUI.auditChild)
  questUI.auditText=CreateFrame("EditBox",nil,questUI.auditChild); questUI.auditText:SetPoint("TOPLEFT",0,0); questUI.auditText:SetWidth(142); questUI.auditText:SetHeight(180); questUI.auditText:SetMultiLine(true); questUI.auditText:SetAutoFocus(false); questUI.auditText:SetFontObject(GameFontHighlightSmall); questUI.auditText:SetTextColor(unpack(C.white)); questUI.auditText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  Button(audit,"Copy / Export",90,20,ShowGroupExport,"Copy or export the complete group analysis"):SetPoint("BOTTOMRIGHT",-7,5)
  auditScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)

  local posts=CreateFrame("Frame",nil,p); posts:SetPoint("BOTTOMLEFT",12,12); posts:SetPoint("BOTTOMRIGHT",-12,12); posts:SetHeight(108); Backdrop(posts,C.panel)
  local ph=Label(posts,"Quest activity and module output","GameFontNormalSmall"); ph:SetPoint("TOPLEFT",8,-7)
  local postScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_QuestPostScroll",posts,"UIPanelScrollFrameTemplate"); postScroll:SetPoint("TOPLEFT",8,-26); postScroll:SetPoint("BOTTOMRIGHT",-28,28); postScroll:EnableMouseWheel(true)
  local postChild=CreateFrame("Frame",nil,postScroll); postChild:SetWidth(632); postChild:SetHeight(84); postScroll:SetScrollChild(postChild); questUI.postChild=postChild
  questUI.postText=CreateFrame("EditBox",nil,postChild); questUI.postText:SetPoint("TOPLEFT",0,0); questUI.postText:SetWidth(632); questUI.postText:SetHeight(84); questUI.postText:SetMultiLine(true); questUI.postText:SetAutoFocus(false); questUI.postText:SetFontObject(GameFontHighlightSmall); questUI.postText:SetTextColor(unpack(C.white)); questUI.postText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  Button(posts,"Copy Output",96,20,ShowQuestOutputExport,"Open a selectable activity and module-output report"):SetPoint("BOTTOMRIGHT",-8,4)
  Button(posts,"Clear Output",92,20,function() questUI.posts={}; AppendQuestPost("Output cleared.","STATUS") end,"Clear this activity window"):SetPoint("BOTTOMRIGHT",-110,4)
  postScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  RenderQuest(); AppendQuestPost("Quest Intelligence ready.","STATUS")
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

ShowSelectableReport=function(title, report)
  if not exportFrame then
    exportFrame=CreateFrame("Frame","AZERCORE_OPS_ExportFrame",UIParent); exportFrame:SetWidth(610); exportFrame:SetHeight(410); exportFrame:SetPoint("CENTER"); exportFrame:SetFrameStrata("FULLSCREEN_DIALOG"); Backdrop(exportFrame); Movable(exportFrame,"export")
    exportFrame.title=Label(exportFrame,"AzerCoreOps report"); exportFrame.title:SetPoint("TOPLEFT",14,-14)
    local help=exportFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); help:SetPoint("TOPLEFT",14,-34); help:SetText("Select any text and press Ctrl+C. Ctrl+A selects the complete report."); help:SetTextColor(unpack(C.white))
    local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_ExportScroll",exportFrame,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",14,-58); scroll:SetPoint("BOTTOMRIGHT",-34,45); Backdrop(scroll,C.panel)
    exportEdit=CreateFrame("EditBox",nil,scroll); exportEdit:SetMultiLine(true); exportEdit:SetAutoFocus(false); exportEdit:SetFontObject(ChatFontNormal); exportEdit:SetWidth(545); exportEdit:SetTextInsets(6,6,6,6); exportEdit:SetScript("OnEscapePressed",function() exportFrame:Hide() end); scroll:SetScrollChild(exportEdit)
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*60)) end)
    Button(exportFrame,"Select All",90,24,function() exportEdit:SetFocus(); exportEdit:HighlightText() end):SetPoint("BOTTOMLEFT",14,12)
    Button(exportFrame,"Close",90,24,function() exportFrame:Hide() end):SetPoint("BOTTOMRIGHT",-14,12)
  end
  exportFrame.title:SetText(title or "AzerCoreOps report")
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
  local auditTab=Button(p,"Eligibility Audit",140,24,function() auditPage:Show(); bindPage:Hide() end,"Group and raid eligibility audit"); auditTab:SetPoint("TOPLEFT",12,-7)
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
  local rh=Label(resultPanel,"Group eligibility and visibility","GameFontNormalSmall"); rh:SetPoint("TOPLEFT",8,-7)
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
  local legend=Label(resultPanel,"PASS = eligible  •  WARN = context  •  FAIL = blocked  •  Hover for full reason","GameFontHighlightSmall"); legend:SetTextColor(unpack(C.white)); legend:SetPoint("BOTTOMLEFT",12,9)

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
local function ShowMain() main:Show(); mini:Hide() end
local function HideMain() main:Hide(); if Settings().showMini then mini:Show() else mini:Hide() end end

local function ApplySettings()
  local s=Settings()
  if main then main:SetScale(s.scale or 1) end
  if minimapButton then
    minimapButton:SetParent(s.mbfCompatibility and UIParent or Minimap)
    PositionMinimap()
    if s.showMinimap then minimapButton:Show() else minimapButton:Hide() end
  end
  if mini then
    if main and main:IsShown() then mini:Hide() elseif s.showMini then mini:Show() else mini:Hide() end
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
  Check(p,controls,"Chat","Hide AzerCoreOps protocol messages from chat","hideAuditChat",-230,"Keep AZERCORE_OPS server messages out of normal chat.")

  local scaleLabel=p:CreateFontString(nil,"ARTWORK","GameFontNormal"); scaleLabel:SetPoint("TOPLEFT",22,-278); scaleLabel:SetText("AzerCoreOps window scale")
  local slider=CreateFrame("Slider","AZERCORE_OPS_OptScale",p,"OptionsSliderTemplate"); slider:SetPoint("TOPLEFT",22,-302); slider:SetWidth(240); slider:SetMinMaxValues(.75,1.35); slider:SetValueStep(.05)
  _G[slider:GetName().."Low"]:SetText("75%"); _G[slider:GetName().."High"]:SetText("135%"); _G[slider:GetName().."Text"]:SetText("100%")
  slider:SetScript("OnValueChanged",function(self,value) value=math.floor(value*20+.5)/20; Settings().scale=value; _G[self:GetName().."Text"]:SetText(math.floor(value*100+.5).."%"); ApplySettings() end)

  local resetPos=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); resetPos:SetWidth(135); resetPos:SetHeight(24); resetPos:SetText("Reset positions"); resetPos:SetPoint("TOPLEFT",16,-370); resetPos:SetScript("OnClick",ResetPositions)
  local resetAll=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); resetAll:SetWidth(135); resetAll:SetHeight(24); resetAll:SetText("Restore defaults"); resetAll:SetPoint("LEFT",resetPos,"RIGHT",12,0)
  resetAll:SetScript("OnClick",function() AzerCoreOpsDB.settings={}; AzerCoreOpsDB.auditFilter=nil; Settings(); slider:SetValue(Settings().scale); ApplySettings(); p:GetScript("OnShow")(p); Print("Settings restored to defaults.") end)

  local diagnostics=CreateFrame("Frame",nil,p); diagnostics:SetPoint("TOPLEFT",340,-62); diagnostics:SetWidth(300); diagnostics:SetHeight(408); Backdrop(diagnostics,C.panel)
  local diagTitle=Label(diagnostics,"Compatibility diagnostics"); diagTitle:SetPoint("TOPLEFT",10,-10)
  compatUI.text=diagnostics:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.text:SetPoint("TOPLEFT",10,-38); compatUI.text:SetPoint("TOPRIGHT",-10,-38); compatUI.text:SetJustifyH("LEFT"); compatUI.text:SetJustifyV("TOP"); compatUI.text:SetWordWrap(true); compatUI.text:SetTextColor(unpack(C.white))
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
  {label="AzerCoreOps repository", url="https://github.com/Fersantos1975/AzerCore-Ops"},
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
  Card(p,"Eligibility Analyzer","Audit a dungeon or raid and identify the first blocker for every group member.",18,-126,355,105)
  Card(p,"Quest Intelligence","Inspect faction rules, requirements, character status, and linked quest chains.",389,-126,355,105)
  Card(p,"Instance Operations","Review personal and selected-player binds, then perform guarded reset actions.",18,-247,355,105)
  Card(p,"Compatibility","Addon "..ADDON_VERSION.."\nProtocol v"..PROTOCOL_VERSION,389,-247,355,105)
  local quick=CreateFrame("Frame",nil,p); quick:SetPoint("TOPLEFT",18,-374); quick:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(quick,C.panel)
  local qh=Label(quick,"Quick actions"); qh:SetPoint("TOPLEFT",12,-12)
  Button(quick,"Open Eligibility",150,30,function() SelectTab("Instances") end,"Search instances and audit your group"):SetPoint("TOPLEFT",12,-42)
  Button(quick,"Inspect Quest",150,30,function() SelectTab("Quest") end,"Open quest search and chain analysis"):SetPoint("TOPLEFT",174,-42)
  Button(quick,"Check Compatibility",150,30,function() RequestCompatibility(); OpenOptions() end,"Query the running AzerCoreOps module"):SetPoint("TOPLEFT",336,-42)
  Button(quick,"Information & Credits",170,30,function() SelectTab("Information") end,"View project links, credits, and acknowledgements"):SetPoint("TOPLEFT",498,-42)
  local note=quick:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); note:SetPoint("TOPLEFT",12,-92); note:SetPoint("BOTTOMRIGHT",-12,12); note:SetJustifyH("LEFT"); note:SetJustifyV("TOP"); note:SetWordWrap(true); note:SetTextColor(unpack(C.white)); note:SetText("Foundation release: v0.5.0\n\nAzerCore Ops Platform combines quest intelligence, instance inspection, movement tools, reports, compatibility information, and guarded administrative workflows. This source revision requires server compilation and in-game validation before production use.")
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
    {"Dashboard","Dashboard"}, {"Eligibility","Instances"}, {"Character","Character"},
    {"Quests","Quest"}, {"NPCs","NPC"}, {"Movement","Teleport"},
    {"Items","Item"}, {"Information","Information"},
  }
  for i,item in ipairs(nav) do
    local label,pageName=item[1],item[2]
    local b=Button(sidebar,label,132,30,function() SelectTab(pageName) end); b:SetPoint("TOPLEFT",14,-38-(i-1)*36); tabs[pageName]=b
  end
  local build=sidebar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); build:SetPoint("BOTTOMLEFT",14,14); build:SetPoint("BOTTOMRIGHT",-14,14); build:SetJustifyH("LEFT"); build:SetTextColor(.65,.65,.65,1); build:SetText("Protocol v"..PROTOCOL_VERSION.."\nDevelopment build")

  content=CreateFrame("Frame",nil,main); content:SetPoint("TOPLEFT",180,-48); content:SetPoint("BOTTOMRIGHT",-10,32); Backdrop(content,C.panel)
  statusText=main:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); statusText:SetPoint("BOTTOMLEFT",14,11); statusText:SetPoint("BOTTOMRIGHT",-14,11); statusText:SetJustifyH("LEFT")
  BuildDashboard(); BuildCharacter(); BuildNPC(); BuildQuest(); BuildTeleport(); BuildItem(); BuildInstances(); BuildInformation(); SelectTab(AzerCoreOpsDB.activeTab or "Dashboard")

  mini=CreateFrame("Button","AZERCORE_OPS_MiniButton",UIParent); mini:SetWidth(36); mini:SetHeight(28); mini:SetClampedToScreen(true); mini:SetFrameStrata("DIALOG"); Backdrop(mini); RestorePoint(mini,"mini","CENTER",290,0); Movable(mini,"mini")
  local mi=mini:CreateTexture(nil,"ARTWORK"); mi:SetTexture("Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"); mi:SetAllPoints()
  local mt=mini:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); mt:SetPoint("CENTER"); mt:SetText(""); mt:SetTextColor(unpack(C.gold))
  mini:SetScript("OnClick",function(self) if self._dragged then self._dragged=nil; return end; ShowMain() end); mini:Hide()

  minimapButton=CreateFrame("Button","AZERCORE_OPS_MinimapButton",Settings().mbfCompatibility and UIParent or Minimap); minimapButton:SetWidth(24); minimapButton:SetHeight(22); minimapButton:SetFrameStrata("MEDIUM"); minimapButton:RegisterForClicks("LeftButtonUp","RightButtonUp"); minimapButton:RegisterForDrag("LeftButton")
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
  elseif event=="PLAYER_TARGET_CHANGED" then RenderInstances(); UpdateQuestContextLabel()
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
      if f.id then SetQuestId(f.id) end; if f.title and questSearchBox then questSearchBox:SetText(f.title) end; if #questUI.results==0 and f.id then table.insert(questUI.results,{id=f.id,title=f.title,faction=f.faction,eligibility=f.eligibility,min=f.min}) end; RenderQuest(); SetStatus("Loaded quest "..(f.id or "?").." compatibility for "..(f.player or questUI.contextName or "current context"))
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
    elseif kind=="QUEST_ERROR" then SetStatus(f.reason or "Quest module error",true)
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
  end
  local function HideProtocol(_,_,message)
    return Settings().hideAuditChat and IsAzerCoreOpsProtocol(message)
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
