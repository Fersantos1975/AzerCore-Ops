local ADDON = ...

-- AzerCore Ops Platform 0.7.1
-- Target: WoW 3.3.5a / AzerothCore. All server commands live here so that
-- branch-specific command names can be changed without touching the UI.
local CMD = {
  revive = ".revive", repair = ".gear repair", summon = ".summon",
  appear = ".appear", combatStop = ".combatstop", save = ".save",
  npcKill = ".die", npcRespawn = ".respawn",
  npcMove = ".npc move", npcNear = ".npc near", npcAdd = ".npc add %d",
  npcDelete = ".npc delete",
  questLookup = ".lookup quest %s", questStatus = ".quest status %d",
  questAdd = ".quest add %d", questComplete = ".quest complete %d",
  questReward = ".quest reward %d", questRemove = ".quest remove %d",
  gps = ".gps", tele = ".tele %s", itemLookup = ".lookup item %s",
  itemAdd = ".additem %d %d", itemRemove = ".additem %d -%d",
  itemInspect = ".azercoreops item inspect %d",
  movementCatalog = ".azercoreops movement catalog", movementCurrent = ".azercoreops movement current",
  movementGo = ".azercoreops movement go %d %.3f %.3f %.3f %.3f", movementReturn = ".azercoreops movement return",
  instanceBindsSelf = ".azercoreops instance binds self",
  instanceBindsTarget = ".azercoreops instance binds target",
  instanceUnbind = ".azercoreops instance unbind %s",
  instanceDiagnose = ".azercoreops instance diagnose",
  instanceHistory = ".azercoreops instance history",
  auditSearch = ".azercoreops instance search %s",
  auditGroup = ".azercoreops instance audit %d %d",
  questSearch = ".azercoreops quest search %s",
  questInfo = ".azercoreops quest info %d",
  questAudit = ".azercoreops quest audit %d",
  questLog = ".azercoreops quest log",
  characterInspect = ".azercoreops character inspect",
  characterRaid = ".azercoreops character raid %s %s",
  characterSaveTarget = ".azercoreops character save",
  npcInspect = ".azercoreops npc inspect",
  npcSearch = ".azercoreops npc search %s",
  npcSpawns = ".azercoreops npc spawns %d",
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
local characterUI={activity={},buttons={},viewButtons={},target=nil,identityFrame=nil,portrait=nil,nameText=nil,metaText=nil,
  overviewText=nil,stateText=nil,locationText=nil,contextText=nil,statusText=nil,modeText=nil,Update=nil,Render=nil,Log=nil,
  view="OVERVIEW",overviewPanels={},reportPanel=nil,reportText=nil,reportChild=nil,server={},capturePlayer=nil,autoInspect=false,Inspect=nil,
  equipmentFrame=nil,equipmentSlots={},equipment={},talents={},inspectionPlayer=nil,inspectionGuid=nil,inspectionState="UNLOADED",
  inspectionGeneration=0,inspectionRetries=0,inspectionClassToken=nil,activeOperation="Inspect Character",
  equipmentActionBar=nil,equipmentActionStatus=nil,footer=nil,roleText=nil,roleIcon=nil,detectedRole="Unknown",detectedSpec=nil,RequestClientInspection=nil,RefreshInspection=nil,
  professionFrame=nil,professionRows={},RenderProfessions=nil,
  raidControls=nil,raidButton=nil,difficultyButton=nil,raidMenu=nil,difficultyMenu=nil,RequestRaid=nil,
  raidCatalog={
    {key="VOA",name="Vault of Archavon",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"}}},
    {key="NAXX",name="Naxxramas",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"}}},
    {key="OS",name="The Obsidian Sanctum",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"},{key="10HM",name="10 Player Hard Mode"},{key="25HM",name="25 Player Hard Mode"}}},
    {key="EOE",name="The Eye of Eternity",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"}}},
    {key="ULDUAR",name="Ulduar",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"},{key="10HM",name="10 Player Hard Mode"},{key="25HM",name="25 Player Hard Mode"}}},
    {key="TOC",name="Trial of the Crusader",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"},{key="10H",name="10 Player Heroic"},{key="25H",name="25 Player Heroic"}}},
    {key="ONYXIA",name="Onyxia's Lair",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"}}},
    {key="ICC",name="Icecrown Citadel",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"},{key="10H",name="10 Player Heroic"},{key="25H",name="25 Player Heroic"}}},
    {key="RS",name="The Ruby Sanctum",difficulties={{key="10N",name="10 Player"},{key="25N",name="25 Player"},{key="10H",name="10 Player Heroic"},{key="25H",name="25 Player Heroic"}}},
  }}
Platform.NPCUI={activity={},buttons={},viewButtons={},server={quests={},loot={},story={}},captureEntry=nil,ignoreStream=false,
  view="OVERVIEW",activeOperation="Inspect NPC",autoInspect=true,Update=nil,Render=nil,Inspect=nil,
  identityName=nil,identityMeta=nil,portrait=nil,workspaceTitle=nil,text=nil,textChild=nil,model=nil,modelViewport=nil,
  questRows={},lootRows={},
  searchResults={},spawns={},searchRows={},spawnRows={},
  searchQuery="",searchLoading=false,spawnsLoading=false,spawnTotal=0,
  selectedSearch=nil,selectedSpawn=nil,searchBox=nil,requestEntry=nil,inspectionLoading=false,
  lootLinkRetry=0,lootLinkRetryPending=false,
  Search=nil,LoadSpawns=nil,SelectSearchResult=nil,GoToSpawn=nil,EmergencyReturn=nil}
Platform.ItemUI={view="OVERVIEW",selected=nil,buttons={},viewButtons={},Select=nil,Render=nil,Report=nil,server={crafts={},reagents={},recipes={},sources={},uses={}},linkRows={}}
Platform.MovementUI={view="DESTINATIONS",serverCatalog={},regions={},selectedRegion=nil,selectedZone=nil,selected=nil,current=nil,loading=false,Render=nil,Report=nil,RefreshCatalog=nil}
local instanceUI={my={},target={},captureUntil=0,myRows={},targetRows={},myOffset=0,targetOffset=0,targetLabel=nil,
  selectedBind=nil,filter="ALL",filterButtons={},detailText=nil,summaryText=nil,myEmpty=nil,targetEmpty=nil,inspectionText=nil,
  inspectedPlayer=nil,inspectedAt=nil,statusText=nil,myScroll=nil,targetScroll=nil,detailScroll=nil,horizontals={},activity={},
  view="OVERVIEW",viewButtons={},myHeading=nil,targetHeader=nil,autoInspect=false,bindPage=nil,bindScope=nil,unbindOperation=nil,
  myLoadState="UNLOADED",targetLoadState="UNLOADED",ignoreBindStream=false,targetPortrait=nil,targetPortraitFrame=nil,targetIdentity=nil,
  targetIdentityName=nil,targetIdentityMeta=nil}
instanceUI.diagnostics={findings={},recoveries={},loading=false,header=nil,summary=nil,error=nil,generatedAt=nil,historyIndex=0,mode="SCAN"}
instanceUI.encounterHistory={entries={},stats={},loading=false,header=nil,summary=nil,error=nil,generatedAt=nil}
local auditUI={search={},members={},searchRows={},memberRows={},filterButtons={},filtered={},mapBox=nil,diffBox=nil,summary=nil,scroll=nil,scrollChild=nil,horizontal=nil,filter="ALL",lastMap=nil,lastDifficulty=nil,reportEdit=nil,
  searchOffset=0,selectedMap=nil,selectedName=nil,selectedType=nil,selectedMaxPlayers=nil,difficulty=0,difficultyLabel="Normal",lockedText=nil,difficultyButton=nil,difficultyMenu=nil,historyIndex=0,searchBox=nil,
  referenceId=0,expectedMembers=0,display={},groupVerdict="NOT AUDITED",groupReason="Run Group Audit",generatedAt=nil,stale=false}
local exportFrame, exportEdit, exportActionButton
local shareFrame, shareText, courierUI
local ShowSelectableReport
local EnsureShareFrame
local ApplyPlayerTargetIdentity
local defaults={
  startMinimized=true,showMinimap=true,showMini=true,mbfCompatibility=true,scale=1,roleMode="AUTOMATIC",
  characterRaid="ICC",characterRaidDifficulty="10N",
  characterRaidLocked=true,
  confirmCommands=true,hideAuditChat=true,defaultDifficulty=0,
  auditTooltips=true,wrapAuditReasons=true,mouseWheelAudit=true,problemsFirst=false,
  rememberAuditFilter=true,autoReaudit=false,confirmResetSelected=true,
  warnNoTarget=true,compactAuditRows=false,auditFontSize=10,shiftClickInsert=true,
}
local ADDON_VERSION="0.7.1"
local PROTOCOL_VERSION="1"
local TESTED_CORE="190184a04539"
local TESTED_PLAYERBOTS="ba46fcdecde3"

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

local function EffectiveCharacterMode()
  local requested=tostring(Settings().roleMode or "AUTOMATIC"):upper()
  local granted=tostring(Platform:PermissionFor("CHARACTER_MODE") or "PLAYER"):upper()
  if requested=="PLAYER" then return "PLAYER" end
  if requested=="GM" then return granted=="GM" and "GM" or "PLAYER" end
  return granted=="GM" and "GM" or "PLAYER"
end

function Platform:UpdateWorkspaceMode()
  local gm=EffectiveCharacterMode()=="GM"
  if compatUI.workspaceModeText then
    compatUI.workspaceModeText:SetText(gm and "|cff55ff55GM MODE|r" or "|cffffff55PLAYER MODE|r")
  end
  if characterUI.modeText then
    characterUI.modeText:SetText(gm and "GM MODE — server authorized" or "PLAYER MODE — GM operations unavailable")
  end
end

function Platform:RegisterRoleButton(button,policy,reason)
  if not button then return button end
  button.azerRolePolicy=policy or "PLAYER_ALLOWED"
  button.azerRoleReason=reason
  self.rolePolicyButtons=self.rolePolicyButtons or {}
  table.insert(self.rolePolicyButtons,button)
  return button
end

function Platform:ApplyRoleButtonPolicies()
  local gm=EffectiveCharacterMode()=="GM"
  for _,button in ipairs(self.rolePolicyButtons or {}) do
    if button.azerRolePolicy=="GM_REQUIRED" then
      if not gm then
        if not button.azerRoleDenied then button.azerRoleWasEnabled=button:IsEnabled() and true or false end
        button.azerRoleDenied=true; button:Disable(); button:SetNormalFontObject(GameFontDisableSmall); button:SetBackdropColor(.08,.08,.08,1)
        button.disabledReason=button.azerRoleReason or "Unavailable in Player Mode. This operation requires server-authorized GM Mode."
      elseif button.azerRoleDenied then
        button.azerRoleDenied=false; button.disabledReason=nil
        if button.azerRoleWasEnabled then button:Enable(); button:SetNormalFontObject(GameFontNormalSmall); button:SetBackdropColor(unpack(C.button)) end
      end
    end
  end
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

-- Shared section heading used by every workspace. Keep this outside individual
-- builders so new pages do not accidentally depend on Quest-local helpers.
local function Section(parent,text,color)
  local h=parent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  h:SetText(text); h:SetTextColor(unpack(color or C.gold)); return h
end

local function Button(parent, text, w, h, click, tip)
  local b=CreateFrame("Button",nil,parent); b:SetWidth(w); b:SetHeight(h); b:SetText(text)
  b:SetNormalFontObject(GameFontNormalSmall); b:SetHighlightFontObject(GameFontHighlightSmall)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
  b:SetBackdropColor(unpack(C.button)); b:SetBackdropBorderColor(unpack(C.border)); b:SetScript("OnClick",click)
  b:SetScript("OnEnter",function(self)
    self:SetBackdropColor(unpack(C.hover))
    local explanation=self.disabledReason or tip
    if explanation then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(text,1,.82,0); GameTooltip:AddLine(explanation,1,1,1,true); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave",function(self)
    if self:IsEnabled() then self:SetBackdropColor(unpack(C.button)) else self:SetBackdropColor(.08,.08,.08,1) end
    GameTooltip:Hide()
  end)
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
StaticPopupDialogs["AZERCORE_OPS_BIND_NOT_APPLICABLE"]={text="This bind cannot be removed now.\n\n%s",button1=OKAY,timeout=0,whileDead=1,hideOnEscape=1}
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
    if d[4] then Platform:RegisterRoleButton(b,d[4],d[5]) end
  end
end

local function CharacterUnit()
  if UnitExists("target") and UnitIsPlayer("target") then return "target" end
  return "player"
end

local function CharacterContextName()
  return UnitName(CharacterUnit())
end

local function NewPage(name)
  local p=CreateFrame("Frame",nil,content); p:SetAllPoints(content); p:Hide(); pages[name]=p; return p
end

local function SelectTab(name)
  activeTab=name; AzerCoreOpsDB.activeTab=name
  for n,p in pairs(pages) do if n==name then p:Show() else p:Hide() end end
  for n,b in pairs(tabs) do b:SetBackdropColor(unpack(n==name and C.selected or C.button)); b:SetBackdropBorderColor(unpack(n==name and C.gold or C.border)) end
  if name=="Character" and characterUI.Update then
    characterUI.activeOperation="Inspect Character"; characterUI.autoInspect=true; characterUI.Update()
    if characterUI.Inspect then characterUI.Inspect(true) end
  end
  if name=="NPC" and Platform.NPCUI.Update then
    Platform.NPCUI.activeOperation="Inspect NPC"; Platform.NPCUI.autoInspect=true; Platform.NPCUI.Update()
    if Platform.NPCUI.Inspect then Platform.NPCUI.Inspect(true) end
  end
  Platform:UpdateWorkspaceMode(); Platform:ApplyRoleButtonPolicies()
  SetStatus(name=="Teleport" and "Movement workspace" or name.." workspace")
end

local function BuildCharacter()
  local p=NewPage("Character")
  local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-10); header:SetPoint("TOPRIGHT",-10,-10); header:SetHeight(52); Backdrop(header,C.bg)
  local h=Label(header,"Character Inspector","GameFontNormalLarge"); h:SetPoint("TOPLEFT",12,-8)
  local subtitle=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); subtitle:SetPoint("TOPLEFT",12,-31); subtitle:SetText("Character status, recovery and controlled GM operations"); subtitle:SetTextColor(unpack(C.white))
  local mode=Label(header,"PLAYER MODE","GameFontNormalSmall"); mode:SetPoint("TOPRIGHT",-12,-17); characterUI.modeText=mode

  local operations=CreateFrame("Frame",nil,p); operations:SetPoint("TOPLEFT",10,-70); operations:SetPoint("BOTTOMLEFT",10,36); operations:SetWidth(148); Backdrop(operations,C.panel)
  local opTitle=Section(operations,"OPERATIONS",C.gold); opTitle:SetPoint("TOPLEFT",10,-10)

  local workspace=CreateFrame("Frame",nil,p); workspace:SetPoint("TOPLEFT",166,-70); workspace:SetPoint("BOTTOMRIGHT",-10,36); Backdrop(workspace,C.panel)
  local identity=CreateFrame("Frame",nil,workspace); identity:SetPoint("TOPLEFT",8,-8); identity:SetPoint("TOPRIGHT",-8,-8); identity:SetHeight(92); Backdrop(identity,C.panel); characterUI.identityFrame=identity
  local identityHeading=Section(identity,"SELECTED TARGET",C.inspect); identityHeading:SetPoint("TOPLEFT",10,-9)
  local portraitFrame=CreateFrame("Frame",nil,identity); portraitFrame:SetPoint("TOPLEFT",10,-28); portraitFrame:SetWidth(50); portraitFrame:SetHeight(50); Backdrop(portraitFrame,C.panel)
  local portrait=portraitFrame:CreateTexture(nil,"ARTWORK"); portrait:SetPoint("TOPLEFT",3,-3); portrait:SetPoint("BOTTOMRIGHT",-3,3); characterUI.portrait=portrait
  local nameText=identity:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); nameText:SetPoint("TOPLEFT",72,-31); nameText:SetTextColor(unpack(C.white)); characterUI.nameText=nameText
  local metaText=identity:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); metaText:SetPoint("TOPLEFT",72,-56); metaText:SetPoint("BOTTOMRIGHT",-184,8); metaText:SetJustifyH("LEFT"); metaText:SetJustifyV("TOP"); metaText:SetTextColor(unpack(C.white)); characterUI.metaText=metaText

  local roleBox=CreateFrame("Frame",nil,identity); roleBox:SetPoint("TOPRIGHT",-10,-27); roleBox:SetWidth(166); roleBox:SetHeight(52); Backdrop(roleBox,C.bg)
  local roleHeading=Section(roleBox,"DETECTED ROLE",C.inspect); roleHeading:SetPoint("TOPLEFT",8,-7)
  local roleIcon=roleBox:CreateTexture(nil,"ARTWORK"); roleIcon:SetWidth(24); roleIcon:SetHeight(24); roleIcon:SetPoint("BOTTOMLEFT",8,5); characterUI.roleIcon=roleIcon
  local roleText=roleBox:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); roleText:SetPoint("LEFT",roleIcon,"RIGHT",7,0); roleText:SetPoint("RIGHT",-5,0); roleText:SetJustifyH("LEFT"); roleText:SetText("Unknown"); characterUI.roleText=roleText

  local actionBar=CreateFrame("Frame",nil,workspace); actionBar:SetPoint("TOPLEFT",8,-108); actionBar:SetPoint("BOTTOMLEFT",8,8); actionBar:SetWidth(112); Backdrop(actionBar,C.panel); characterUI.actionBar=actionBar
  local actionHeading=Section(actionBar,"ACTION BAR",C.gold); actionHeading:SetPoint("TOPLEFT",8,-9)
  local function CharacterViewButton(label,view,index)
    local b=Button(actionBar,label,96,24,function()
      characterUI.view=view
      if (view=="EQUIPMENT" or view=="TALENTS") and characterUI.RequestClientInspection and (characterUI.inspectionGuid~=UnitGUID(CharacterUnit()) or characterUI.inspectionState=="UNLOADED" or characterUI.inspectionState=="UNAVAILABLE") then characterUI.RequestClientInspection(false) end
      if characterUI.Render then characterUI.Render() end
    end); b:SetPoint("TOPLEFT",8,-28-(index-1)*28); b:SetScript("OnLeave",function() if characterUI.Render then characterUI.Render() end; GameTooltip:Hide() end); characterUI.viewButtons[view]=b; return b
  end
  CharacterViewButton("Overview","OVERVIEW",1)
  CharacterViewButton("Inventory","INVENTORY",2)
  CharacterViewButton("Equipment","EQUIPMENT",3)
  CharacterViewButton("Talents","TALENTS",4)
  CharacterViewButton("Professions","PROFESSIONS",5)
  CharacterViewButton("Raid EXP","RAID",6)
  CharacterViewButton("Technical","TECHNICAL",7)

  local viewArea=CreateFrame("Frame",nil,workspace); viewArea:SetPoint("TOPLEFT",128,-108); viewArea:SetPoint("BOTTOMRIGHT",-8,8); characterUI.viewArea=viewArea
  local overview=CreateFrame("Frame",nil,viewArea); overview:SetPoint("TOPLEFT",0,0); overview:SetPoint("TOPRIGHT",viewArea,"TOP",-4,0); overview:SetHeight(132); Backdrop(overview,C.panel)
  local overviewHeading=Section(overview,"CHARACTER OVERVIEW",C.inspect); overviewHeading:SetPoint("TOPLEFT",10,-10)
  local overviewText=overview:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); overviewText:SetPoint("TOPLEFT",10,-34); overviewText:SetPoint("BOTTOMRIGHT",-10,8); overviewText:SetJustifyH("LEFT"); overviewText:SetJustifyV("TOP"); overviewText:SetTextColor(unpack(C.white)); characterUI.overviewText=overviewText

  local state=CreateFrame("Frame",nil,viewArea); state:SetPoint("TOPLEFT",viewArea,"TOP",4,0); state:SetPoint("TOPRIGHT",0,0); state:SetHeight(132); Backdrop(state,C.panel)
  local stateHeading=Section(state,"CURRENT STATE",C.diagnose); stateHeading:SetPoint("TOPLEFT",10,-10)
  local stateText=state:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); stateText:SetPoint("TOPLEFT",10,-34); stateText:SetPoint("BOTTOMRIGHT",-10,8); stateText:SetJustifyH("LEFT"); stateText:SetJustifyV("TOP"); stateText:SetTextColor(unpack(C.white)); characterUI.stateText=stateText

  local location=CreateFrame("Frame",nil,viewArea); location:SetPoint("TOPLEFT",0,-140); location:SetPoint("TOPRIGHT",viewArea,"TOP",-4,-140); location:SetPoint("BOTTOM",viewArea,"BOTTOM",0,0); Backdrop(location,C.panel)
  local locationHeading=Section(location,"LOCATION",C.diagnose); locationHeading:SetPoint("TOPLEFT",10,-10)
  local locationText=location:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); locationText:SetPoint("TOPLEFT",10,-34); locationText:SetPoint("BOTTOMRIGHT",-10,8); locationText:SetJustifyH("LEFT"); locationText:SetJustifyV("TOP"); locationText:SetWordWrap(true); locationText:SetTextColor(unpack(C.white)); characterUI.locationText=locationText

  local context=CreateFrame("Frame",nil,viewArea); context:SetPoint("TOPLEFT",viewArea,"TOP",4,-140); context:SetPoint("TOPRIGHT",0,-140); context:SetPoint("BOTTOM",viewArea,"BOTTOM",0,0); Backdrop(context,C.panel)
  local contextHeading=Section(context,"SELECTION CONTEXT",C.operate); contextHeading:SetPoint("TOPLEFT",10,-10)
  local contextText=context:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); contextText:SetPoint("TOPLEFT",10,-34); contextText:SetPoint("BOTTOMRIGHT",-10,8); contextText:SetJustifyH("LEFT"); contextText:SetJustifyV("TOP"); contextText:SetWordWrap(true); contextText:SetTextColor(unpack(C.white)); characterUI.contextText=contextText
  characterUI.overviewPanels={overview,state,location,context}

  local reportPanel=CreateFrame("Frame",nil,viewArea); reportPanel:SetAllPoints(viewArea); Backdrop(reportPanel,C.panel); reportPanel:Hide(); characterUI.reportPanel=reportPanel

  local equipmentFrame=CreateFrame("Frame",nil,viewArea); equipmentFrame:SetAllPoints(viewArea); Backdrop(equipmentFrame,C.panel); equipmentFrame:Hide(); characterUI.equipmentFrame=equipmentFrame
  local equipmentHeading=Section(equipmentFrame,"EQUIPMENT INSPECTION",C.inspect); equipmentHeading:SetPoint("TOPLEFT",10,-10); equipmentHeading:SetWidth(145); equipmentHeading:SetWordWrap(false)
  local equipmentSummary=equipmentFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); equipmentSummary:SetPoint("TOPLEFT",160,-11); equipmentSummary:SetPoint("TOPRIGHT",-10,-11); equipmentSummary:SetJustifyH("RIGHT"); equipmentSummary:SetWordWrap(false); characterUI.equipmentSummary=equipmentSummary
  local refreshEquipment=Button(equipmentFrame,"",24,22,function() if characterUI.RefreshInspection then characterUI.RefreshInspection() end end,"Refresh equipment and talents for the selected character.")
  local refreshTexture=refreshEquipment:CreateTexture(nil,"ARTWORK"); refreshTexture:SetTexture("Interface\\Buttons\\UI-RotationRight-Button-Up"); refreshTexture:SetPoint("TOPLEFT",2,-2); refreshTexture:SetPoint("BOTTOMRIGHT",-2,2)
  local helpEquipment=Button(equipmentFrame,"?",22,22,nil,"Equipment follows the selected target automatically. Mouse over a slot for its complete item tooltip and use the arrow buttons beside the character's head to rotate. The target must be nearby, visible, friendly and online.")

  local equipmentActionBar=CreateFrame("Frame",nil,equipmentFrame); equipmentActionBar:Hide(); characterUI.equipmentActionBar=equipmentActionBar
  local equipmentActionStatus=equipmentActionBar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); equipmentActionStatus:SetPoint("LEFT",8,0); equipmentActionStatus:SetPoint("RIGHT",-190,0); equipmentActionStatus:SetJustifyH("LEFT"); equipmentActionStatus:SetTextColor(unpack(C.white)); equipmentActionStatus:SetText("Equipment inspection ready"); characterUI.equipmentActionStatus=equipmentActionStatus

  local leftRail=CreateFrame("Frame",nil,equipmentFrame); leftRail:SetPoint("TOPLEFT",5,-32); leftRail:SetPoint("BOTTOMLEFT",5,5); leftRail:SetWidth(42); Backdrop(leftRail,C.bg); characterUI.leftEquipmentRail=leftRail
  local rightRail=CreateFrame("Frame",nil,equipmentFrame); rightRail:SetPoint("TOPRIGHT",-5,-32); rightRail:SetPoint("BOTTOMRIGHT",-5,5); rightRail:SetWidth(42); Backdrop(rightRail,C.bg); characterUI.rightEquipmentRail=rightRail

  local equipmentDock=CreateFrame("Frame",nil,equipmentFrame); equipmentDock:SetPoint("BOTTOMLEFT",leftRail,"BOTTOMRIGHT",5,0); equipmentDock:SetPoint("BOTTOMRIGHT",rightRail,"BOTTOMLEFT",-5,0); equipmentDock:SetHeight(38); Backdrop(equipmentDock,C.bg); characterUI.equipmentDock=equipmentDock

  local modelViewport=CreateFrame("Frame",nil,equipmentFrame); modelViewport:SetPoint("TOPLEFT",50,-32); modelViewport:SetPoint("BOTTOMRIGHT",equipmentDock,"TOPRIGHT",0,4); characterUI.equipmentModelViewport=modelViewport
  local model=CreateFrame("PlayerModel",nil,modelViewport); model:SetPoint("CENTER"); model:SetWidth(1); model:SetHeight(1); model:SetUnit("player"); characterUI.equipmentModel=model
  characterUI.UpdateEquipmentCamera=function()
    -- Keep the model width at 70%, but give its rendering surface the complete
    -- workspace height so tall helmets, shoulders and weapons are not clipped.
    local viewportWidth=math.max(1,modelViewport:GetWidth() or 1)
    local viewportHeight=math.max(1,modelViewport:GetHeight() or 1)
    model:SetWidth(viewportWidth*.70)
    model:SetHeight(viewportHeight)
    if model.SetCamDistanceScale then model:SetCamDistanceScale(1) end
    -- Cancel the parent window scale so the 3D module retains one physical size.
    model:SetScale(.75/math.max(.75,math.min(1.35,Settings().scale or 1)))
  end
  modelViewport:SetScript("OnSizeChanged",function() if characterUI.UpdateEquipmentCamera then characterUI.UpdateEquipmentCamera() end end)
  characterUI.UpdateEquipmentCamera()
  model.azerFacing=0
  Button(equipmentFrame,"<",26,20,function() model.azerFacing=model.azerFacing-.25; model:SetFacing(model.azerFacing) end,"Rotate character left"):SetPoint("TOP",modelViewport,"TOP",-118,-42)
  Button(equipmentFrame,">",26,20,function() model.azerFacing=model.azerFacing+.25; model:SetFacing(model.azerFacing) end,"Rotate character right"):SetPoint("TOP",modelViewport,"TOP",118,-42)
  helpEquipment:SetPoint("BOTTOMLEFT",equipmentDock,"BOTTOMLEFT",5,8)
  refreshEquipment:SetPoint("LEFT",helpEquipment,"RIGHT",5,0)

  local slotLayout={
    {1,"HeadSlot","Head","LEFT",-4},{2,"NeckSlot","Neck","LEFT",-40},{3,"ShoulderSlot","Shoulders","LEFT",-76},{15,"BackSlot","Back","LEFT",-112},{5,"ChestSlot","Chest","LEFT",-148},{4,"ShirtSlot","Shirt","LEFT",-184},{19,"TabardSlot","Tabard","LEFT",-220},{9,"WristSlot","Wrist","LEFT",-256},
    {10,"HandsSlot","Hands","RIGHT",-4},{6,"WaistSlot","Waist","RIGHT",-40},{7,"LegsSlot","Legs","RIGHT",-76},{8,"FeetSlot","Feet","RIGHT",-112},{11,"Finger0Slot","Finger 1","RIGHT",-148},{12,"Finger1Slot","Finger 2","RIGHT",-184},{13,"Trinket0Slot","Trinket 1","RIGHT",-220},{14,"Trinket1Slot","Trinket 2","RIGHT",-256},
    {16,"MainHandSlot","Main Hand","BOTTOM",-36},{17,"SecondaryHandSlot","Off Hand","BOTTOM",0},{18,"RangedSlot","Ranged","BOTTOM",36},
  }
  for _,definition in ipairs(slotLayout) do
    local slotId,slotName,label,rail,y=definition[1],definition[2],definition[3],definition[4],definition[5]
    local slotParent=rail=="LEFT" and leftRail or (rail=="RIGHT" and rightRail or equipmentDock)
    local slot=CreateFrame("Button",nil,slotParent); slot:SetWidth(32); slot:SetHeight(32); Backdrop(slot,C.bg); slot.slotId=slotId; slot.slotName=slotName; slot.slotLabel=label
    slot:RegisterForClicks("LeftButtonUp","RightButtonUp")
    local icon=slot:CreateTexture(nil,"ARTWORK"); icon:SetPoint("TOPLEFT",3,-3); icon:SetPoint("BOTTOMRIGHT",-3,3); icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-"..slotName); slot.icon=icon
    local count=slot:CreateFontString(nil,"OVERLAY","NumberFontNormalSmall"); count:SetPoint("BOTTOMRIGHT",-3,3); slot.count=count
    if rail=="BOTTOM" then slot:SetPoint("CENTER",equipmentDock,"CENTER",y,0)
    else slot:SetPoint("TOPLEFT",5,y) end
    slot:SetScript("OnEnter",function(self)
      local item=characterUI.equipment[self.slotId]
      GameTooltip:SetOwner(self,rail=="LEFT" and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
      if item and item.link then GameTooltip:SetHyperlink(item.link) else GameTooltip:SetText(self.slotLabel); GameTooltip:AddLine("Empty or not yet inspected",.7,.7,.7) end
      GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function() GameTooltip:Hide() end)
    slot:SetScript("OnClick",function(self)
      local item=characterUI.equipment[self.slotId]
      if not item or not item.link or not IsShiftKeyDown() then return end
      if HandleModifiedItemClick then HandleModifiedItemClick(item.link)
      elseif ChatEdit_InsertLink then ChatEdit_InsertLink(item.link) end
    end)
    characterUI.equipmentSlots[slotId]=slot
  end

  local professionCatalog={
    {id="164",name="Blacksmithing",category="Primary",icon="Interface\\Icons\\Trade_BlackSmithing"},
    {id="165",name="Leatherworking",category="Primary",icon="Interface\\Icons\\Trade_LeatherWorking"},
    {id="171",name="Alchemy",category="Primary",icon="Interface\\Icons\\Trade_Alchemy"},
    {id="182",name="Herbalism",category="Primary",icon="Interface\\Icons\\Trade_Herbalism"},
    {id="186",name="Mining",category="Primary",icon="Interface\\Icons\\Trade_Mining"},
    {id="197",name="Tailoring",category="Primary",icon="Interface\\Icons\\Trade_Tailoring"},
    {id="202",name="Engineering",category="Primary",icon="Interface\\Icons\\Trade_Engineering"},
    {id="333",name="Enchanting",category="Primary",icon="Interface\\Icons\\Trade_Engraving"},
    {id="393",name="Skinning",category="Primary",icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01"},
    {id="755",name="Jewelcrafting",category="Primary",icon="Interface\\Icons\\INV_Misc_Gem_01"},
    {id="129",name="First Aid",category="Secondary",icon="Interface\\Icons\\Spell_Holy_SealOfSacrifice"},
    {id="185",name="Cooking",category="Secondary",icon="Interface\\Icons\\INV_Misc_Food_15"},
    {id="356",name="Fishing",category="Secondary",icon="Interface\\Icons\\Trade_Fishing"},
  }
  local professionFrame=CreateFrame("Frame",nil,viewArea); professionFrame:SetAllPoints(viewArea); Backdrop(professionFrame,C.panel); professionFrame:Hide(); characterUI.professionFrame=professionFrame
  local professionHeading=Section(professionFrame,"PROFESSIONS",C.inspect); professionHeading:SetPoint("TOPLEFT",10,-10)
  local professionSummary=professionFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); professionSummary:SetPoint("TOPLEFT",100,-10); professionSummary:SetPoint("TOPRIGHT",-10,-10); professionSummary:SetJustifyH("RIGHT"); professionSummary:SetWordWrap(false); characterUI.professionSummary=professionSummary
  local professionScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_CharacterProfessionScroll",professionFrame,"UIPanelScrollFrameTemplate"); professionScroll:SetPoint("TOPLEFT",8,-32); professionScroll:SetPoint("BOTTOMRIGHT",-28,8); professionScroll:EnableMouseWheel(true)
  local professionChild=CreateFrame("Frame",nil,professionScroll); professionChild:SetWidth(410); professionChild:SetHeight(520); professionScroll:SetScrollChild(professionChild)
  professionScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  local primaryHeading=Section(professionChild,"PRIMARY PROFESSIONS",C.gold)
  local secondaryHeading=Section(professionChild,"SECONDARY PROFESSIONS",C.gold)
  for index,definition in ipairs(professionCatalog) do
    local row=CreateFrame("Frame",nil,professionChild); row:SetWidth(398); row:SetHeight(34); Backdrop(row,C.bg); row.definition=definition
    local icon=row:CreateTexture(nil,"ARTWORK"); icon:SetWidth(26); icon:SetHeight(26); icon:SetPoint("LEFT",4,0); icon:SetTexture(definition.icon); row.icon=icon
    local name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); name:SetPoint("TOPLEFT",36,-4); name:SetWidth(150); name:SetJustifyH("LEFT"); name:SetText(definition.name); row.name=name
    local bar=CreateFrame("StatusBar",nil,row); bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); bar:SetPoint("BOTTOMLEFT",36,5); bar:SetWidth(248); bar:SetHeight(8); bar:SetMinMaxValues(0,450); row.bar=bar
    local value=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); value:SetPoint("RIGHT",-7,0); value:SetWidth(100); value:SetJustifyH("RIGHT"); row.value=value
    row:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.definition.name,1,.82,0)
      GameTooltip:AddLine(self.learned and ("Skill: "..tostring(self.current).." / "..tostring(self.maximum)) or "Not learned",1,1,1,true); GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    characterUI.professionRows[index]=row
  end
  characterUI.RenderProfessions=function()
    local learnedById={}; local primaryLearned,secondaryLearned=0,0
    for _,record in ipairs((characterUI.server and characterUI.server.professions) or {}) do learnedById[tostring(record.id or "")]=record end
    local y=-4
    local function RenderCategory(category,heading)
      heading:ClearAllPoints(); heading:SetPoint("TOPLEFT",4,y); y=y-22
      for learnedPass=1,2 do
        for index,definition in ipairs(professionCatalog) do
          if definition.category==category then
            local record=learnedById[definition.id]; local learned=record~=nil
            if (learnedPass==1 and learned) or (learnedPass==2 and not learned) then
              local row=characterUI.professionRows[index]; local current=tonumber(record and record.value) or 0; local maximum=tonumber(record and record.maximum) or 450
              row:ClearAllPoints(); row:SetPoint("TOPLEFT",4,y); row.learned=learned; row.current=current; row.maximum=maximum
              row:SetAlpha(learned and 1 or .38); row.bar:SetMinMaxValues(0,math.max(1,maximum)); row.bar:SetValue(current); row.bar:SetStatusBarColor(learned and C.gold[1] or .3,learned and C.gold[2] or .3,learned and C.gold[3] or .3,1)
              row.value:SetText(learned and string.format("%d / %d",current,maximum) or "Not learned"); row:Show(); y=y-38
              if learned then if category=="Primary" then primaryLearned=primaryLearned+1 else secondaryLearned=secondaryLearned+1 end end
            end
          end
        end
      end
      y=y-6
    end
    RenderCategory("Primary",primaryHeading); RenderCategory("Secondary",secondaryHeading)
    professionChild:SetHeight(math.max(360,-y+8)); professionSummary:SetText(string.format("Primary: %d learned  •  Secondary: %d learned",primaryLearned,secondaryLearned))
  end

  local raidControls=CreateFrame("Frame",nil,reportPanel); raidControls:SetPoint("TOPLEFT",8,-8); raidControls:SetPoint("TOPRIGHT",-28,-8); raidControls:SetHeight(34); raidControls:Hide(); characterUI.raidControls=raidControls
  local raidLabel=raidControls:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); raidLabel:SetPoint("LEFT",2,0); raidLabel:SetText("Raid")
  local raidButton=Button(raidControls,"Select raid",132,24,nil,"Choose the raid whose recorded achievements will be inspected. This selection remains locked while targets change and after reload."); raidButton:SetPoint("LEFT",36,0); characterUI.raidButton=raidButton
  local difficultyLabel=raidControls:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); difficultyLabel:SetPoint("LEFT",raidButton,"RIGHT",8,0); difficultyLabel:SetText("Difficulty")
  local difficultyButton=Button(raidControls,"Select difficulty",112,24,nil,"Only difficulties applicable to the selected raid are listed."); difficultyButton:SetPoint("LEFT",difficultyLabel,"RIGHT",6,0); characterUI.difficultyButton=difficultyButton
  local raidLockButton=Button(raidControls,"",24,24,nil); raidLockButton:SetPoint("LEFT",difficultyButton,"RIGHT",8,0); characterUI.raidLockButton=raidLockButton
  local raidLockIcon=raidLockButton:CreateTexture(nil,"ARTWORK"); raidLockIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK"); raidLockIcon:SetPoint("TOPLEFT",3,-3); raidLockIcon:SetPoint("BOTTOMRIGHT",-3,3)
  local raidUnlockMark=raidLockButton:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); raidUnlockMark:SetPoint("CENTER",6,-5); raidUnlockMark:SetText("X"); raidUnlockMark:SetTextColor(1,.12,.12,1); raidUnlockMark:Hide()

  local talentControls=CreateFrame("Frame",nil,reportPanel); talentControls:SetPoint("TOPLEFT",8,-8); talentControls:SetPoint("TOPRIGHT",-28,-8); talentControls:SetHeight(34); talentControls:Hide(); characterUI.talentControls=talentControls
  local talentStatus=talentControls:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); talentStatus:SetPoint("LEFT",2,0); talentStatus:SetPoint("RIGHT",-88,0); talentStatus:SetJustifyH("LEFT"); talentStatus:SetText("Live inspected talents"); characterUI.talentStatus=talentStatus
  Button(talentControls,"Refresh",76,22,function() if characterUI.RefreshInspection then characterUI.RefreshInspection() end end,"Request current equipment and talent information again for the selected target."):SetPoint("RIGHT",-2,0)

  local raidMenu=CreateFrame("Frame",nil,reportPanel); raidMenu:SetWidth(214); raidMenu:SetHeight(#characterUI.raidCatalog*23+10); raidMenu:SetPoint("TOPLEFT",raidButton,"BOTTOMLEFT",0,-2); raidMenu:SetFrameStrata("FULLSCREEN_DIALOG"); raidMenu:SetFrameLevel(260); Backdrop(raidMenu,C.panel); raidMenu:Hide(); characterUI.raidMenu=raidMenu
  local difficultyMenu=CreateFrame("Frame",nil,reportPanel); difficultyMenu:SetWidth(194); difficultyMenu:SetHeight(106); difficultyMenu:SetPoint("TOPLEFT",difficultyButton,"BOTTOMLEFT",0,-2); difficultyMenu:SetFrameStrata("FULLSCREEN_DIALOG"); difficultyMenu:SetFrameLevel(260); Backdrop(difficultyMenu,C.panel); difficultyMenu:Hide(); characterUI.difficultyMenu=difficultyMenu

  local function RaidDefinition(key)
    for _,raid in ipairs(characterUI.raidCatalog) do if raid.key==key then return raid end end
    return characterUI.raidCatalog[1]
  end
  local function DifficultyDefinition(raid,key)
    for _,difficulty in ipairs(raid.difficulties) do if difficulty.key==key then return difficulty end end
    return raid.difficulties[1]
  end
  local function RefreshRaidSelectors()
    local settings=Settings(); local raid=RaidDefinition(settings.characterRaid); local difficulty=DifficultyDefinition(raid,settings.characterRaidDifficulty)
    settings.characterRaid=raid.key; settings.characterRaidDifficulty=difficulty.key
    raidButton:SetText(raid.name.."  v"); difficultyButton:SetText(difficulty.name.."  v")
    return raid,difficulty
  end
  local function RefreshRaidLock()
    local locked=Settings().characterRaidLocked~=false
    if locked then
      raidButton:Disable(); difficultyButton:Disable(); raidUnlockMark:Hide(); raidLockButton:SetBackdropBorderColor(unpack(C.gold))
    else
      raidButton:Enable(); difficultyButton:Enable(); raidUnlockMark:Show(); raidLockButton:SetBackdropBorderColor(unpack(C.red))
    end
    raidLockButton.locked=locked
  end
  raidLockButton:SetScript("OnClick",function()
    Settings().characterRaidLocked=not (Settings().characterRaidLocked~=false)
    raidMenu:Hide(); difficultyMenu:Hide(); RefreshRaidLock()
    if Settings().characterRaidLocked then SetStatus("Raid Experience selection locked.") else SetStatus("Raid Experience selection unlocked; choose a raid and difficulty.") end
  end)
  raidLockButton:SetScript("OnEnter",function(self)
    self:SetBackdropColor(unpack(C.hover)); GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(self.locked and "Unlock Raid Experience" or "Lock Raid Experience",1,.82,0)
    GameTooltip:AddLine(self.locked and "Allow the raid and difficulty selection to be changed." or "Preserve this selection across targets and reloads.",1,1,1,true); GameTooltip:Show()
  end)
  raidLockButton:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(C.button)); RefreshRaidLock(); GameTooltip:Hide() end)
  local function SelectRaid(raid)
    local settings=Settings(); settings.characterRaid=raid.key
    settings.characterRaidDifficulty=DifficultyDefinition(raid,settings.characterRaidDifficulty).key
    raidMenu:Hide(); difficultyMenu:Hide(); characterUI.server.raid={}; characterUI.server.raidSelection=nil
    RefreshRaidSelectors(); if characterUI.Render then characterUI.Render() end; if characterUI.RequestRaid then characterUI.RequestRaid() end
  end
  for index,raid in ipairs(characterUI.raidCatalog) do
    local definition=raid; local option=Button(raidMenu,definition.name,204,21,function() SelectRaid(definition) end); option:SetPoint("TOPLEFT",5,-5-(index-1)*23)
  end
  local difficultyOptions={}
  for index=1,4 do
    local option=Button(difficultyMenu,"",184,21,nil); option:SetPoint("TOPLEFT",5,-5-(index-1)*23); difficultyOptions[index]=option
  end
  local function OpenDifficultyMenu()
    local raid=RaidDefinition(Settings().characterRaid)
    for index,option in ipairs(difficultyOptions) do
      local definition=raid.difficulties[index]
      if definition then
        option:SetText(definition.name); option:SetScript("OnClick",function()
          Settings().characterRaidDifficulty=definition.key; difficultyMenu:Hide(); raidMenu:Hide(); characterUI.server.raid={}; characterUI.server.raidSelection=nil
          RefreshRaidSelectors(); if characterUI.Render then characterUI.Render() end; if characterUI.RequestRaid then characterUI.RequestRaid() end
        end); option:Show()
      else option:Hide() end
    end
    difficultyMenu:SetHeight(#raid.difficulties*23+10); difficultyMenu:Show(); difficultyMenu:Raise()
  end
  raidButton:SetScript("OnClick",function() difficultyMenu:Hide(); if raidMenu:IsShown() then raidMenu:Hide() else raidMenu:Show(); raidMenu:Raise() end end)
  difficultyButton:SetScript("OnClick",function() raidMenu:Hide(); if difficultyMenu:IsShown() then difficultyMenu:Hide() else OpenDifficultyMenu() end end)
  RefreshRaidSelectors(); RefreshRaidLock()

  local reportScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_CharacterReportScroll",reportPanel,"UIPanelScrollFrameTemplate"); reportScroll:SetPoint("TOPLEFT",8,-8); reportScroll:SetPoint("BOTTOMRIGHT",-28,8); reportScroll:EnableMouseWheel(true)
  characterUI.reportScroll=reportScroll
  local reportChild=CreateFrame("Frame",nil,reportScroll); reportChild:SetWidth(410); reportChild:SetHeight(360); reportScroll:SetScrollChild(reportChild); characterUI.reportChild=reportChild
  local reportText=reportChild:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); reportText:SetPoint("TOPLEFT",4,-4); reportText:SetWidth(396); reportText:SetJustifyH("LEFT"); reportText:SetJustifyV("TOP"); reportText:SetWordWrap(true); reportText:SetTextColor(unpack(C.white)); characterUI.reportText=reportText
  reportScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)

  local roleByClass={
    WARRIOR={"Damage","Damage","Tank"}, PALADIN={"Healer","Tank","Damage"}, HUNTER={"Damage","Damage","Damage"},
    ROGUE={"Damage","Damage","Damage"}, PRIEST={"Healer","Healer","Damage"}, SHAMAN={"Damage","Damage","Healer"},
    MAGE={"Damage","Damage","Damage"}, WARLOCK={"Damage","Damage","Damage"}, DRUID={"Damage","Tank / Damage","Healer"},
    DEATHKNIGHT={"Tank / Damage","Tank / Damage","Damage"},
  }
  local talentTreesByClass={
    WARRIOR={"Arms","Fury","Protection"}, PALADIN={"Holy","Protection","Retribution"}, HUNTER={"Beast Mastery","Marksmanship","Survival"},
    ROGUE={"Assassination","Combat","Subtlety"}, PRIEST={"Discipline","Holy","Shadow"}, SHAMAN={"Elemental","Enhancement","Restoration"},
    MAGE={"Arcane","Fire","Frost"}, WARLOCK={"Affliction","Demonology","Destruction"}, DRUID={"Balance","Feral Combat","Restoration"},
    DEATHKNIGHT={"Blood","Frost","Unholy"},
  }
  local function CaptureClientInspection(generation)
    if generation and generation~=characterUI.inspectionGeneration then return false end
    local unit=CharacterUnit()
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
    local inspectOther=not UnitIsUnit(unit,"player")
    local selectedGuid=UnitGUID(unit)
    local _,classToken=UnitClass(unit)
    if characterUI.inspectionGuid and selectedGuid~=characterUI.inspectionGuid then return false end
    if characterUI.inspectionClassToken and classToken~=characterUI.inspectionClassToken then return false end
    local candidateEquipment={}
    local equipped=0
    for slotId,slot in pairs(characterUI.equipmentSlots) do
      local link=GetInventoryItemLink(unit,slotId)
      if link then
        local name,_,quality,itemLevel,_,_,_,_,_,texture=GetItemInfo(link)
        quality=quality or 1; itemLevel=tonumber(itemLevel) or 0
        candidateEquipment[slotId]={link=link,name=name or link,quality=quality,itemLevel=itemLevel,texture=texture or GetInventoryItemTexture(unit,slotId),label=slot.slotLabel}; equipped=equipped+1
      end
    end
    if inspectOther and equipped==0 then return false end
    local tabs={}; local dominantIndex,dominantPoints=1,-1
    local expectedTrees=talentTreesByClass[classToken or ""]
    for tabIndex=1,3 do
      local tabName,tabIcon,pointsSpent,background=GetTalentTabInfo(tabIndex,inspectOther,false)
      if not tabName or (expectedTrees and tabName~=expectedTrees[tabIndex]) then return false end
      pointsSpent=tonumber(pointsSpent) or 0
      local tab={name=tabName,icon=tabIcon,points=pointsSpent,background=background,talents={}}
      if pointsSpent>dominantPoints then dominantIndex,dominantPoints=tabIndex,pointsSpent end
      local count=GetNumTalents(tabIndex,inspectOther,false) or 0
      for talentIndex=1,count do
        local talentName,talentIcon,tier,column,rank,maxRank=GetTalentInfo(tabIndex,talentIndex,inspectOther,false)
        rank=tonumber(rank) or 0
        if rank>0 then table.insert(tab.talents,{name=talentName or ("Talent "..talentIndex),icon=talentIcon,tier=tier,column=column,rank=rank,maxRank=maxRank or rank}) end
      end
      tabs[tabIndex]=tab
    end
    if generation and generation~=characterUI.inspectionGeneration then return false end
    characterUI.equipment=candidateEquipment; characterUI.talents=tabs
    for slotId,slot in pairs(characterUI.equipmentSlots) do
      local item=candidateEquipment[slotId]
      if item then slot.icon:SetTexture(item.texture); slot:SetBackdropBorderColor(GetItemQualityColor(item.quality))
      else slot.icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-"..slot.slotName); slot:SetBackdropBorderColor(unpack(C.border)) end
      slot:SetAlpha(1)
    end
    local roles=roleByClass[classToken or ""] or {}
    characterUI.detectedRole=dominantPoints>0 and (roles[dominantIndex] or "Damage") or "Unknown"
    characterUI.detectedSpec=dominantPoints>0 and tabs[dominantIndex] and tabs[dominantIndex].name or nil
    if characterUI.roleText then characterUI.roleText:SetText(characterUI.detectedRole..(characterUI.detectedSpec and ("\n|cffaaaaaa"..characterUI.detectedSpec.."|r") or "")) end
    if characterUI.roleIcon then
      if characterUI.detectedSpec and tabs[dominantIndex] then characterUI.roleIcon:SetTexture(tabs[dominantIndex].icon); characterUI.roleIcon:Show() else characterUI.roleIcon:Hide() end
    end
    characterUI.inspectionState="LOADED"
    characterUI.inspectionRequestSent=false
    characterUI.inspectedAt=date("%H:%M:%S")
    if characterUI.equipmentSummary then characterUI.equipmentSummary:SetText(string.format("%d / 19 equipped  •  inspected %s",equipped,characterUI.inspectedAt)) end
    if characterUI.equipmentActionStatus then characterUI.equipmentActionStatus:SetText("Inspection loaded for "..tostring(characterUI.inspectionPlayer or UnitName(unit) or "character")) end
    if characterUI.equipmentNotice then characterUI.equipmentNotice:SetText("Mouse over an item for its full tooltip. Inspection follows the selected target automatically.") end
    if characterUI.equipmentModel then characterUI.equipmentModel:SetUnit(unit); After(.05,function() if characterUI.UpdateEquipmentCamera then characterUI.UpdateEquipmentCamera() end end) end
    if characterUI.Render then characterUI.Render() end
    return true
  end
  characterUI.CaptureClientInspection=CaptureClientInspection
  characterUI.RequestClientInspection=function(manual)
    local unit=CharacterUnit()
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    characterUI.inspectionGeneration=(characterUI.inspectionGeneration or 0)+1
    local generation=characterUI.inspectionGeneration
    characterUI.inspectionPlayer=UnitName(unit); characterUI.inspectionGuid=UnitGUID(unit); characterUI.inspectionClassToken=select(2,UnitClass(unit)); characterUI.inspectionState="LOADING"; characterUI.inspectionRetries=0; characterUI.inspectionRequestSent=false
    for _,slot in pairs(characterUI.equipmentSlots) do slot:SetAlpha(.38) end
    if characterUI.equipmentSummary then characterUI.equipmentSummary:SetText("Refreshing "..tostring(characterUI.inspectionPlayer).."...") end
    if characterUI.equipmentActionStatus then characterUI.equipmentActionStatus:SetText((manual and "Refreshing " or "Inspecting ")..tostring(characterUI.inspectionPlayer).."...") end
    if characterUI.equipmentModel then characterUI.equipmentModel:SetUnit(unit); After(.05,function() if generation==characterUI.inspectionGeneration and characterUI.UpdateEquipmentCamera then characterUI.UpdateEquipmentCamera() end end) end
    local inspectOther=not UnitIsUnit(unit,"player")
    local inspectionReady=not inspectOther
    local function Attempt()
      if generation~=characterUI.inspectionGeneration or characterUI.inspectionState~="LOADING" then return end
      local currentUnit=CharacterUnit()
      if UnitGUID(currentUnit)~=characterUI.inspectionGuid then return end
      if inspectionReady and CaptureClientInspection(generation) then return end
      inspectionReady=not inspectOther
      characterUI.inspectionRetries=(characterUI.inspectionRetries or 0)+1
      if characterUI.inspectionRetries>=4 then
        characterUI.inspectionState="UNAVAILABLE"
        for _,slot in pairs(characterUI.equipmentSlots) do slot:SetAlpha(.38) end
        if characterUI.equipmentSummary then characterUI.equipmentSummary:SetText("Inspection unavailable for "..tostring(characterUI.inspectionPlayer)) end
        if characterUI.Render then characterUI.Render() end
        return
      end
      if ClearInspectPlayer then ClearInspectPlayer() end
      characterUI.inspectionRequestSent=true; NotifyInspect(currentUnit); After(1.5,Attempt)
    end
    characterUI.OnInspectionReady=function() inspectionReady=true; Attempt() end
    if not inspectOther then After(.08,Attempt)
    else if ClearInspectPlayer then ClearInspectPlayer() end; After(.3,function() if generation==characterUI.inspectionGeneration then characterUI.inspectionRequestSent=true; NotifyInspect(CharacterUnit()); After(1.35,Attempt) end end) end
    if characterUI.statusText then characterUI.statusText:SetText((manual and "Refreshing " or "Inspecting ")..tostring(characterUI.inspectionPlayer).."...") end
  end
  characterUI.RefreshInspection=function() characterUI.RequestClientInspection(true) end

  local function EquipmentReport()
    local target=characterUI.target; local lines={"AzerCore Ops — Equipment Inspection","Generated: "..date("%Y-%m-%d %H:%M:%S"),"Target: "..(target and target.name or "None"),"Role: "..(characterUI.detectedRole or "Unknown")..(characterUI.detectedSpec and (" ("..characterUI.detectedSpec..")") or ""),""}
    if characterUI.inspectionState~="LOADED" then table.insert(lines,"Equipment inspection is not complete. The target must be a nearby, visible player.") return table.concat(lines,"\n") end
    local ordered={1,2,3,15,5,4,19,9,10,6,7,8,11,12,13,14,16,17,18}
    for _,slotId in ipairs(ordered) do local slot=characterUI.equipmentSlots[slotId]; local item=characterUI.equipment[slotId]; table.insert(lines,string.format("%-10s  %s",slot.slotLabel..":",item and ("["..tostring(item.name or "Unknown item").."] — item level "..tostring(item.itemLevel or "?")) or "Empty")) end
    return table.concat(lines,"\n")
  end
  local function TalentsReport()
    local target=characterUI.target; local lines={"AzerCore Ops — Talent Inspection","Generated: "..date("%Y-%m-%d %H:%M:%S"),"Target: "..(target and target.name or "None"),"Detected role: "..(characterUI.detectedRole or "Unknown"),"Specialization: "..(characterUI.detectedSpec or "Unknown"),""}
    if characterUI.inspectionState~="LOADED" or not characterUI.talents[1] then table.insert(lines,"Talent inspection is not complete. The target must be a nearby, visible player.") return table.concat(lines,"\n") end
    local build={}; for i=1,3 do table.insert(build,tostring(characterUI.talents[i].points or 0)) end; table.insert(lines,"Build: "..table.concat(build," / ")); table.insert(lines,"")
    for _,tab in ipairs(characterUI.talents) do
      table.insert(lines,string.format("%s — %d points",tab.name,tab.points or 0))
      if #tab.talents==0 then table.insert(lines,"  No points spent") else for _,talent in ipairs(tab.talents) do table.insert(lines,string.format("  %s — %d/%d",talent.name,talent.rank,talent.maxRank)) end end
      table.insert(lines,"")
    end
    return table.concat(lines,"\n")
  end

  local CharacterViewText
  local function CharacterReport()
    if characterUI.view=="EQUIPMENT" then return EquipmentReport() end
    if characterUI.view=="TALENTS" then return TalentsReport():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","") end
    if characterUI.view~="OVERVIEW" and CharacterViewText then
      local target=characterUI.target; local body=CharacterViewText(characterUI.view)
      return table.concat({"AzerCore Ops — Character "..characterUI.view,"Generated: "..date("%Y-%m-%d %H:%M:%S"),"Target: "..(target and target.name or "None"),"",body or ""},"\n"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    end
    local target=characterUI.target
    local lines={"AzerCore Ops — Character Inspector","Generated: "..date("%Y-%m-%d %H:%M:%S"),"Target: "..(target and target.name or "None"),"Detected role: "..(characterUI.detectedRole or "Unknown")..(characterUI.detectedSpec and (" ("..characterUI.detectedSpec..")") or ""),"",characterUI.overviewText:GetText() or "", "",characterUI.stateText:GetText() or "", "",characterUI.locationText:GetText() or "", "",characterUI.contextText:GetText() or ""}
    local server=characterUI.server or {}
    if server.inventory then local r=server.inventory; table.insert(lines,""); table.insert(lines,"INVENTORY SUMMARY"); table.insert(lines,string.format("Bag slots: %s / %s | Equipped: %s | Average item level: %s",r.used or "?",r.capacity or "?",r.equipped or "?",r.average or "?")) end
    if server.professions and #server.professions>0 then table.insert(lines,""); table.insert(lines,"PROFESSIONS"); for _,r in ipairs(server.professions) do table.insert(lines,string.format("%s | %s | %s/%s",r.category or "Skill",r.name or "Unknown",r.value or "?",r.maximum or "?")) end end
    if server.raid and #server.raid>0 then local raid,difficulty=RefreshRaidSelectors(); table.insert(lines,""); table.insert(lines,"RAID EXPERIENCE — "..raid.name.." — "..difficulty.name..(Settings().characterRaidLocked~=false and " (LOCKED)" or " (UNLOCKED)")); for _,r in ipairs(server.raid) do table.insert(lines,string.format("%s | %s | Achievement %s",r.complete=="1" and "COMPLETED" or "NOT RECORDED",r.section or "Unknown section",r.achievement or "?")) end; table.insert(lines,"Achievement records indicate completion, not mastery of the current role.") end
    return table.concat(lines,"\n"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  end
  local function LogCharacter(action,result)
    table.insert(characterUI.activity,1,string.format("[%s] %-12s %s",date("%H:%M:%S"),action,result or "Submitted"))
    while #characterUI.activity>80 do table.remove(characterUI.activity) end
  end
  characterUI.Log=LogCharacter
  characterUI.RequestRaid=function()
    local settings=Settings(); characterUI.server.raid={}; characterUI.server.raidSelection=nil
    SendCommand(string.format(CMD.characterRaid,settings.characterRaid,settings.characterRaidDifficulty))
    characterUI.statusText:SetText("Loading Raid Experience selection for "..tostring(CharacterContextName()).."...")
  end
  local function SelectedTarget()
    if not UnitExists("target") or not UnitIsPlayer("target") then SetStatus("Select a player before using this Character operation.",true); return end
    return UnitName("target")
  end
  local function RunTargetCommand(label,command,confirm)
    local target=SelectedTarget(); if not target then return end
    local result="Submitted for "..target.."; authoritative result awaits server-module integration."
    local after=function() LogCharacter(label,result); SetStatus(label.." submitted for "..target..". Check the server response for confirmation.") end
    if confirm then Confirm(command,nil,after) else SendCommand(command); after() end
  end
  local function RefreshOperationButtons()
    for name,button in pairs(characterUI.buttons) do
      if name==characterUI.activeOperation and button:IsEnabled() then button:SetBackdropColor(unpack(C.selected)); button:SetBackdropBorderColor(unpack(C.gold))
      elseif button:IsEnabled() then button:SetBackdropColor(unpack(C.button)); button:SetBackdropBorderColor(unpack(C.border)) end
    end
  end
  characterUI.RefreshOperationButtons=RefreshOperationButtons
  local function OpButton(text,y,click,tip,requiresTarget,gmOnly)
    local b=Button(operations,text,128,28,function()
      characterUI.activeOperation=text; characterUI.autoInspect=text=="Inspect Character"
      if characterUI.Update then characterUI.Update() else RefreshOperationButtons() end
      if click then click() end
    end,tip); b:SetPoint("TOPLEFT",10,y); b.requiresTarget=requiresTarget; b.gmOnly=gmOnly; characterUI.buttons[text]=b
    b:SetScript("OnLeave",function(self) RefreshOperationButtons(); GameTooltip:Hide() end)
    return b
  end
  characterUI.Inspect=function(automatic)
    characterUI.Update(); characterUI.server={professions={},raid={}}
    local target=CharacterContextName()
    characterUI.capturePlayer=target
    if not target then return end
    if characterUI.RequestClientInspection then characterUI.RequestClientInspection(false) end
    SendCommand(CMD.characterInspect)
    After(.05,function() if characterUI.RequestRaid then characterUI.RequestRaid() end end)
    LogCharacter(automatic and "Auto Inspect" or "Inspect","Requested authoritative Character data for "..target)
    characterUI.statusText:SetText("Loading module Character data for "..target.."...")
  end
  local inspectOperation=OpButton("Inspect Character",-34,function()
    characterUI.autoInspect=true; characterUI.Inspect(false)
  end,"Automatic Character inspection is active in this workspace. It uses the selected player, or your own character when no player target is selected.",false,false)
  inspectOperation:SetScript("OnLeave",function() RefreshOperationButtons(); GameTooltip:Hide() end)
  OpButton("Revive",-70,function() RunTargetCommand("Revive",CMD.revive,true) end,"Revive the explicitly selected player",true,true)
  OpButton("Repair Equipment",-106,function() RunTargetCommand("Repair",CMD.repair,true) end,"Repair the explicitly selected player's equipment",true,true)
  OpButton("Summon",-142,function() RunTargetCommand("Summon",CMD.summon,true) end,"Summon the explicitly selected player to your location",true,true)
  OpButton("Appear",-178,function() RunTargetCommand("Appear",CMD.appear,true) end,"Teleport your GM character to the explicitly selected player",true,true)
  OpButton("Stop Combat",-214,function() RunTargetCommand("Stop Combat",CMD.combatStop,true) end,"Stop combat for the explicitly selected player when supported",true,true)
  OpButton("Save My Character",-250,function() Confirm(CMD.save,nil,function() LogCharacter("Save","Submitted for "..(UnitName("player") or "self")); SetStatus("Save submitted for your character.") end) end,"Save your own character; this command does not use the selected target")
  OpButton("Save Target",-286,function()
    local target=SelectedTarget(); if not target then return end
    Confirm(CMD.characterSaveTarget,true,function() LogCharacter("Save Target","Requested authoritative save for "..target); characterUI.statusText:SetText("Waiting for target-save verification for "..target.."...") end)
  end,"Persist the selected online character without logging that player out",true,true)
  OpButton("Character Activity",-334,function()
    local lines={"AzerCore Ops — Character activity","Generated: "..date("%Y-%m-%d %H:%M:%S"),""}
    if #characterUI.activity==0 then table.insert(lines,"No Character operations recorded in this session.") else for i=#characterUI.activity,1,-1 do table.insert(lines,characterUI.activity[i]) end end
    ShowSelectableReport("Character activity and operation output",table.concat(lines,"\n"))
  end,"Review Character operations attempted during this session")

  local footer=CreateFrame("Frame",nil,workspace); footer:SetWidth(1); footer:SetHeight(1); footer:Hide(); characterUI.footer=footer
  characterUI.statusText=footer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); characterUI.statusText:SetPoint("CENTER"); characterUI.statusText:SetTextColor(unpack(C.white))
  local function CopyCharacterReport() ShowSelectableReport("Copy Character report",CharacterReport()) end
  local function ShareCharacterReport() local text=CharacterReport(); local f=EnsureShareFrame(); f:SetCapturedMessage(text,"CHARACTER",function() return CharacterReport(),"CHARACTER" end); f:Show(); f:Raise(); SetStatus("Courier opened with the Character report.") end
  local function ExportCharacterReport() ShowSelectableReport("Export Character report",CharacterReport()) end
  Button(actionBar,"Copy",96,22,CopyCharacterReport,"Copy the currently selected Character workspace"):SetPoint("BOTTOMLEFT",8,62)
  Button(actionBar,"Share",96,22,ShareCharacterReport,"Share the currently selected Character workspace through Courier"):SetPoint("BOTTOMLEFT",8,35)
  Button(actionBar,"Export",96,22,ExportCharacterReport,"Export the currently selected Character workspace"):SetPoint("BOTTOMLEFT",8,8)

  CharacterViewText=function(view)
    local s=characterUI.server or {}
    if not characterUI.target then return "Select and inspect a player to load this workspace." end
    if view=="INVENTORY" then
      local r=s.inventory
      if not r then return "Inventory summary has not been loaded.\n\nSelect Inspect Character to request the module-authoritative summary." end
      local used,capacity=tonumber(r.used) or 0,tonumber(r.capacity) or 0
      return string.format("|cffffd100INVENTORY SUMMARY|r\n\nBag slots used: %d / %d\nFree bag slots: %d\nEquipped items: %s / %d\nAverage item level: %s\n\nThis summary deliberately excludes private item-level detail from shared reports.",used,capacity,math.max(0,capacity-used),r.equipped or "?",19,r.average or "?")
    elseif view=="TALENTS" then
      return TalentsReport()
    elseif view=="PROFESSIONS" then
      local lines={"|cffffd100PROFESSIONS|r",""}; local learned={}; for _,record in ipairs(s.professions or {}) do learned[tostring(record.id or "")]=record end
      for _,category in ipairs({"Primary","Secondary"}) do
        table.insert(lines,category:upper().." PROFESSIONS")
        for pass=1,2 do for _,definition in ipairs(professionCatalog) do if definition.category==category then local record=learned[definition.id]; if (pass==1 and record) or (pass==2 and not record) then table.insert(lines,string.format("%-18s  %s",definition.name,record and ((record.value or "?").." / "..(record.maximum or "?")) or "Not learned")) end end end end
        table.insert(lines,"")
      end
      return table.concat(lines,"\n")
    elseif view=="RAID" then
      local raid,difficulty=RefreshRaidSelectors(); local lines={"|cffffd100"..raid.name.." — "..difficulty.name.."|r",Settings().characterRaidLocked~=false and "|cffffff55Selection is locked across target changes and reloads.|r" or "|cffff7777Selection is unlocked and may be changed.|r","Achievements are evidence of recorded completion; they do not prove mastery of the current role.",""}; local rows=s.raid or {}
      if not s.raidSelection then table.insert(lines,"Loading the selected raid experience from the module...")
      elseif #rows==0 then table.insert(lines,"No achievement records are defined for this selection.")
      else for _,r in ipairs(rows) do table.insert(lines,string.format("%s  %s  [Achievement %s]",r.complete=="1" and "|cff55ff55COMPLETED|r" or "|cffaaaaaaNOT RECORDED|r",r.section or "Unknown",r.achievement or "?")) end end
      return table.concat(lines,"\n")
    elseif view=="TECHNICAL" then
      if EffectiveCharacterMode()~="GM" then return "|cffff5555RESTRICTED|r\n\nTechnical Character details require module-authorized GM mode." end
      local o,l=s.overview or {},s.location or {}
      return string.format("|cffffd100TECHNICAL DETAILS|r\n\nCharacter GUID (low): %s\nMap ID: %s\nZone ID: %s\nArea ID: %s\nInstance ID: %s\nPhase mask: %s\nPosition: %s, %s, %s\nOrientation: %s\n\nAccount, email and network identifiers are intentionally excluded.",o.guid or "Not loaded",l.map or "?",l.zone or "?",l.area or "?",l.instance or "?",l.phase or "?",l.x or "?",l.y or "?",l.z or "?",l.o or "?")
    end
    return ""
  end

  characterUI.Render=function()
    local overviewMode=characterUI.view=="OVERVIEW"
    local equipmentMode=characterUI.view=="EQUIPMENT"
    local professionMode=characterUI.view=="PROFESSIONS"
    local raidMode=characterUI.view=="RAID"
    local talentMode=characterUI.view=="TALENTS"
    if raidMode then characterUI.raidControls:Show() else characterUI.raidControls:Hide(); characterUI.raidMenu:Hide(); characterUI.difficultyMenu:Hide() end
    if talentMode then characterUI.talentControls:Show(); characterUI.talentStatus:SetText(characterUI.inspectionState=="LOADED" and ("Live talents inspected at "..tostring(characterUI.inspectedAt or "now")) or "Waiting for live talent inspection...") else characterUI.talentControls:Hide() end
    characterUI.reportScroll:ClearAllPoints(); characterUI.reportScroll:SetPoint("TOPLEFT",8,(raidMode or talentMode) and -48 or -8); characterUI.reportScroll:SetPoint("BOTTOMRIGHT",-28,8)
    for _,panel in ipairs(characterUI.overviewPanels) do if overviewMode then panel:Show() else panel:Hide() end end
    if equipmentMode then characterUI.reportPanel:Hide(); characterUI.professionFrame:Hide(); characterUI.equipmentFrame:Show()
    elseif professionMode then characterUI.reportPanel:Hide(); characterUI.equipmentFrame:Hide(); characterUI.professionFrame:Show(); if characterUI.RenderProfessions then characterUI.RenderProfessions() end
    elseif overviewMode then characterUI.reportPanel:Hide(); characterUI.equipmentFrame:Hide(); characterUI.professionFrame:Hide()
    else
      characterUI.equipmentFrame:Hide(); characterUI.professionFrame:Hide()
      characterUI.reportPanel:Show(); local text=CharacterViewText(characterUI.view); characterUI.reportText:SetText(text)
      local lines=1; for _ in text:gmatch("\n") do lines=lines+1 end; local height=math.max(360,lines*16+18); characterUI.reportText:SetHeight(height); characterUI.reportChild:SetHeight(height+8)
    end
    for view,button in pairs(characterUI.viewButtons) do button:SetBackdropColor(unpack(view==characterUI.view and C.selected or C.button)); button:SetBackdropBorderColor(unpack(view==characterUI.view and C.gold or C.border)) end
  end

  characterUI.Update=function()
    local unit=CharacterUnit()
    local explicitTarget=unit=="target"
    local identityData=ApplyPlayerTargetIdentity(characterUI.portrait,characterUI.identityFrame,unit)
    characterUI.target=identityData
    local gmMode=EffectiveCharacterMode()=="GM"
    Platform:UpdateWorkspaceMode()
    for _,button in pairs(characterUI.buttons) do
      if button.requiresTarget or button.gmOnly then
        local enabled=(not button.requiresTarget or explicitTarget) and (not button.gmOnly or gmMode)
        if enabled then button:Enable(); button.disabledReason=nil; button:SetNormalFontObject(GameFontNormalSmall); button:SetBackdropColor(unpack(C.button))
        else
          button:Disable(); button:SetNormalFontObject(GameFontDisableSmall); button:SetBackdropColor(.08,.08,.08,1)
          if button.requiresTarget and not identityData then button.disabledReason="Select a player target to use this operation."
          elseif button.gmOnly and not gmMode then button.disabledReason="Unavailable in Player Mode. GM authorization must be granted by the server; Automatic Mode will use it when available."
          else button.disabledReason="This operation is unavailable in the current context." end
        end
      end
    end
    if characterUI.RefreshOperationButtons then characterUI.RefreshOperationButtons() end
    local technicalButton=characterUI.viewButtons.TECHNICAL
    if technicalButton then if gmMode then technicalButton:Enable(); technicalButton.disabledReason=nil; technicalButton:SetNormalFontObject(GameFontNormalSmall) else technicalButton:Disable(); technicalButton.disabledReason="Unavailable in Player Mode. Technical Character details require server-authorized GM Mode."; technicalButton:SetNormalFontObject(GameFontDisableSmall); if characterUI.view=="TECHNICAL" then characterUI.view="OVERVIEW" end end end
    if not identityData then
      characterUI.nameText:SetText("No player selected"); characterUI.metaText:SetText("Select a player target to inspect Character information.")
      characterUI.detectedRole="Unknown"; characterUI.detectedSpec=nil; if characterUI.roleText then characterUI.roleText:SetText("Unknown") end; if characterUI.roleIcon then characterUI.roleIcon:Hide() end
      if characterUI.equipmentActionStatus then characterUI.equipmentActionStatus:SetText("Select a player target to inspect equipment") end
      characterUI.overviewText:SetText("No Character information loaded.")
      characterUI.stateText:SetText("No player state available.")
      characterUI.locationText:SetText("No target location available.")
      characterUI.contextText:SetText("Target-dependent operations are unavailable.\n\nSave My Character always applies to your own character.")
      characterUI.statusText:SetText("No player selected")
      characterUI.Render()
      return
    end
    local name=identityData.name; local faction=UnitFactionGroup(unit) or "Unknown"; local guild=identityData.guild or "None"
    characterUI.nameText:SetText(name)
    characterUI.metaText:SetText(string.format("Level %s %s %s\nGuild: %s",tostring(identityData.level),identityData.race or "Unknown",identityData.class or "Player",guild))
    local relation=UnitIsUnit(unit,"player") and "Self" or (UnitInRaid(unit) and "Raid member" or (UnitInParty(unit) and "Party member" or "Outside your group"))
    characterUI.overviewText:SetText(string.format("Name: %s\nLevel: %s\nRace: %s\nClass: %s\nFaction: %s\nGuild: %s\nRelationship: %s",name,tostring(identityData.level),identityData.race or "Unknown",identityData.class or "Player",faction,guild,relation))
    local maximum=math.max(1,UnitHealthMax(unit) or 1); local health=UnitHealth(unit) or 0
    local powerMaximum=math.max(1,UnitManaMax(unit) or 1); local power=UnitMana(unit) or 0
    local life=UnitIsGhost(unit) and "Ghost" or (UnitIsDead(unit) and "Dead" or "Alive")
    local connection=UnitIsConnected(unit) and "Online" or "Offline"
    local combat=UnitAffectingCombat(unit) and "In combat" or "Not in combat"
    local flags=(UnitIsAFK(unit) and "AFK" or (UnitIsDND(unit) and "DND" or "Available"))
    characterUI.stateText:SetText(string.format("Connection: %s\nLife state: %s\nHealth: %d / %d  (%d%%)\nPower: %d / %d  (%d%%)\nCombat: %s\nPlayer flag: %s\nVisibility: %s",connection,life,health,maximum,math.floor(health/maximum*100+.5),power,powerMaximum,math.floor(power/powerMaximum*100+.5),combat,flags,UnitIsVisible(unit) and "Visible" or "Not currently visible"))
    if UnitIsUnit(unit,"player") then
      characterUI.locationText:SetText(string.format("Zone: %s\nArea: %s\n\nExact map, coordinates, orientation and instance context require the planned Character module integration.",GetRealZoneText() or "Unknown",GetSubZoneText() or "Unknown"))
    else
      characterUI.locationText:SetText("Target location is not exposed reliably by the client.\n\nExact map, zone, coordinates, orientation and instance context require the planned Character module integration.")
    end
    characterUI.contextText:SetText(string.format("Selected target: %s\nContext: %s\n\nRevive, Repair Equipment, Summon, Appear and Stop Combat require this explicit target.\n\nSave My Character always applies to %s.",name,relation,UnitName("player") or "your character"))
    characterUI.statusText:SetText("Client-visible Character state loaded for "..name)
    local server=characterUI.server or {}
    if server.location and server.location.authorized=="1" then
      local l=server.location
      characterUI.locationText:SetText(string.format("Map ID: %s\nZone ID: %s  |  Area ID: %s\nInstance ID: %s  |  Phase: %s\nCoordinates: %s, %s, %s\nOrientation: %s",l.map or "?",l.zone or "?",l.area or "?",l.instance or "?",l.phase or "?",l.x or "?",l.y or "?",l.z or "?",l.o or "?"))
    end
    characterUI.Render()
  end
  characterUI.Update()
end

Platform.ItemCacheTooltip=
  Platform.ItemCacheTooltip
  or CreateFrame(
    "GameTooltip",
    "AZERCORE_OPS_ItemCacheTooltip",
    UIParent,
    "GameTooltipTemplate"
  )

Platform.ItemCacheTooltip:SetOwner(UIParent,"ANCHOR_NONE")
Platform.ItemCacheTooltip:Hide()

Platform.ItemCacheRequested=Platform.ItemCacheRequested or {}

Platform.NativeItemLink=function(item)
  if not item then return nil end

  if item.link and tostring(item.link):find("|Hitem:",1,true) then
    return item.link
  end

  local id=tonumber(item.id)
  if not id or id<=0 then return nil end

  -- First check the normal client cache.
  local _,link=GetItemInfo(id)

  if link and tostring(link):find("|Hitem:",1,true) then
    return link
  end

  -- WoW 3.3.5 does not reliably populate uncached items merely by
  -- repeatedly calling GetItemInfo(). Setting a hidden tooltip hyperlink
  -- initiates the client -> server item query.
  --
  -- Query each item once. The existing NPC Loot retry loop will then
  -- pick up the native hyperlink asynchronously when it arrives.
  if
    not Platform.ItemCacheRequested[id]
    and Platform.ItemCacheTooltip
  then
    Platform.ItemCacheRequested[id]=true

    Platform.ItemCacheTooltip:ClearLines()
    Platform.ItemCacheTooltip:SetHyperlink("item:"..id)
    Platform.ItemCacheTooltip:Hide()
  end

  return nil
end

Platform.InsertItemLink=function(link)
  if not link or not tostring(link):find("|Hitem:",1,true) then
    return false
  end

  local function InsertInto(editBox)
    if not editBox then return false end

    if ChatEdit_ActivateChat then
      ChatEdit_ActivateChat(editBox)
    end

    -- IMPORTANT:
    -- Use Blizzard's original insert function directly.
    -- ChatEdit_InsertLink is wrapped by AzerCore Ops earlier in this file
    -- for inserting links into AzerCore Ops input fields.
    if originalInsertLink then
      originalInsertLink(link)
    elseif editBox.Insert then
      editBox:Insert(link)
    else
      return false
    end

    if editBox.SetFocus then
      editBox:SetFocus()
    end

    return true
  end

  local active=
    ChatEdit_GetActiveWindow
    and ChatEdit_GetActiveWindow()
    or nil

  -- Chat is already open: insert immediately.
  if active then
    return InsertInto(active)
  end

  -- Chat is closed. Open the default chat window first.
  if not ChatFrame_OpenChat then
    return false
  end

  ChatFrame_OpenChat("",DEFAULT_CHAT_FRAME)

  -- 3.3.5 needs a short settling period after ChatFrame_OpenChat.
  -- After(0) was still racing the chat edit-box activation.
  After(.05,function()
    local editBox=
      ChatEdit_GetActiveWindow
      and ChatEdit_GetActiveWindow()
      or nil

    if not editBox and DEFAULT_CHAT_FRAME then
      editBox=DEFAULT_CHAT_FRAME.editBox
    end

    InsertInto(editBox)
  end)

  return true
end

local function BuildNPC()
  local p=NewPage("NPC")
  local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-10); header:SetPoint("TOPRIGHT",-10,-10); header:SetHeight(52); Backdrop(header,C.bg)
  local h=Label(header,"NPC Inspector","GameFontNormalLarge"); h:SetPoint("TOPLEFT",12,-8)
  local sub=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); sub:SetPoint("TOPLEFT",12,-31); sub:SetText("Search, inspect, navigate to and diagnose AzerothCore creature spawns")

  local operations=CreateFrame("Frame",nil,p); operations:SetPoint("TOPLEFT",10,-70); operations:SetPoint("BOTTOMLEFT",10,36); operations:SetWidth(148); Backdrop(operations,C.panel)
  local opTitle=Section(operations,"OPERATIONS",C.gold); opTitle:SetPoint("TOPLEFT",10,-10)
  local opDefs={
    {"Inspect NPC",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="Inspect NPC"; Platform.NPCUI.Inspect(false) end,"Inspect the selected creature and resume automatic target inspection"},
    {"Go to NPC",function()
      Platform.NPCUI.autoInspect=true
      Platform.NPCUI.activeOperation="Go to NPC"
      if Platform.NPCUI.GoToNPC then Platform.NPCUI.GoToNPC() end
    end,"Teleport near the selected live NPC while preserving an Emergency Return point","GM_REQUIRED"},
    {"Go to Spawn",function()
      Platform.NPCUI.autoInspect=true
      Platform.NPCUI.activeOperation="Go to Spawn"
      if Platform.NPCUI.GoToSpawn then Platform.NPCUI.GoToSpawn() end
    end,"Teleport to the selected database spawn while preserving an Emergency Return point","GM_REQUIRED"},
    {"Emergency Return",function()
      Platform.NPCUI.autoInspect=true
      Platform.NPCUI.activeOperation="Emergency Return"
      if Platform.NPCUI.EmergencyReturn then Platform.NPCUI.EmergencyReturn() end
    end,"Return to the position saved before the last AzerCore Ops teleport","GM_REQUIRED"},
    {"NPC Info",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="NPC Info"; Platform.NPCUI.view="TECHNICAL"; Platform.NPCUI.Inspect(false); Platform.NPCUI.Render() end,"Load technical NPC information inside AzerCore Ops","GM_REQUIRED"},
    {"Kill",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="Kill"; Confirm(CMD.npcKill) end,"Kill the selected creature","GM_REQUIRED"},
    {"Respawn",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="Respawn"; SendCommand(CMD.npcRespawn) end,"Respawn the selected creature","GM_REQUIRED"},
    {"Move Here",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="Move Here"; Confirm(CMD.npcMove) end,"Move the selected spawn to your position","GM_REQUIRED"},
    {"Summon Here",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="Summon Here"; SendCommand(CMD.summon) end,"Summon the selected creature to you","GM_REQUIRED"},
    {"NPC Near",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="NPC Near"; SendCommand(CMD.npcNear) end,"List nearby creature spawns","GM_REQUIRED"},
    {"Delete NPC",function() Platform.NPCUI.autoInspect=true; Platform.NPCUI.activeOperation="Delete NPC"; Confirm(CMD.npcDelete) end,"Permanently delete the selected spawn","GM_REQUIRED"},
  }
  local function RefreshNPCOperationButtons()
    for name,button in pairs(Platform.NPCUI.buttons) do
      if name==Platform.NPCUI.activeOperation and button:IsEnabled() then button:SetBackdropColor(unpack(C.selected)); button:SetBackdropBorderColor(unpack(C.gold))
      elseif button:IsEnabled() then button:SetBackdropColor(unpack(C.button)); button:SetBackdropBorderColor(unpack(C.border)) end
    end
  end
  Platform.NPCUI.RefreshOperationButtons=RefreshNPCOperationButtons
  for i,d in ipairs(opDefs) do
    local operationName,operationClick=d[1],d[2]
    local b=Button(operations,operationName,128,24,function()
      Platform.NPCUI.activeOperation=operationName; Platform.NPCUI.autoInspect=true; RefreshNPCOperationButtons(); operationClick()
    end,d[3]); b:SetPoint("TOPLEFT",10,-30-(i-1)*31); Platform.NPCUI.buttons[operationName]=b
    b:SetScript("OnLeave",function() RefreshNPCOperationButtons(); GameTooltip:Hide() end)
    if d[4] then Platform:RegisterRoleButton(b,d[4]) end
  end

  local body=CreateFrame("Frame",nil,p); body:SetPoint("TOPLEFT",166,-70); body:SetPoint("BOTTOMRIGHT",-10,36); Backdrop(body,C.panel)

  local searchPanel=CreateFrame("Frame",nil,body)
  searchPanel:SetPoint("TOPLEFT",8,-8)
  searchPanel:SetPoint("TOPRIGHT",-8,-8)
  searchPanel:SetHeight(44)
  Backdrop(searchPanel,C.bg)

  local searchTitle=Section(searchPanel,"NPC SEARCH",C.gold)
  searchTitle:SetPoint("LEFT",10,0)

  local searchBox=CreateFrame("EditBox",nil,searchPanel,"InputBoxTemplate")
  searchBox:SetHeight(20)
  searchBox:SetPoint("LEFT",105,0)
  searchBox:SetPoint("RIGHT",-178,0)
  searchBox:SetAutoFocus(false)
  searchBox:SetMaxLetters(80)
  Platform.NPCUI.searchBox=searchBox

  local searchButton=Button(
    searchPanel,
    "Search",
    76,
    22,
    function()
      if Platform.NPCUI.Search then Platform.NPCUI.Search() end
    end,
    "Search by creature name or exact Entry ID"
  )
  searchButton:SetPoint("RIGHT",-92,0)

  local clearButton=Button(
    searchPanel,
    "Clear",
    76,
    22,
    function()
      if Platform.NPCUI.Clear then Platform.NPCUI.Clear() end
    end,
    "Clear NPC search, selection and loaded inspection data"
  )
  clearButton:SetPoint("RIGHT",-10,0)

  searchBox:SetScript("OnEnterPressed",function(self)
    self:ClearFocus()
    if Platform.NPCUI.Search then Platform.NPCUI.Search() end
  end)

  searchBox:SetScript("OnEscapePressed",function(self)
    self:ClearFocus()
  end)

  local identity=CreateFrame("Frame",nil,body); identity:SetPoint("TOPLEFT",8,-60); identity:SetPoint("TOPRIGHT",-8,-60); identity:SetHeight(82); Backdrop(identity,C.bg)
  local ih=Section(identity,"SELECTED NPC",C.inspect); ih:SetPoint("TOPLEFT",10,-8)
  local pf=CreateFrame("Frame",nil,identity); pf:SetPoint("TOPLEFT",10,-27); pf:SetSize(44,44); Backdrop(pf,C.panel)
  local portrait=pf:CreateTexture(nil,"ARTWORK"); portrait:SetPoint("TOPLEFT",3,-3); portrait:SetPoint("BOTTOMRIGHT",-3,3); Platform.NPCUI.portrait=portrait
  local iname=identity:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); iname:SetPoint("TOPLEFT",65,-31); iname:SetTextColor(unpack(C.white)); Platform.NPCUI.identityName=iname
  local imeta=identity:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); imeta:SetPoint("TOPLEFT",65,-54); imeta:SetPoint("RIGHT",-8,0); imeta:SetJustifyH("LEFT"); Platform.NPCUI.identityMeta=imeta

  local action=CreateFrame("Frame",nil,body); action:SetPoint("TOPLEFT",8,-150); action:SetPoint("BOTTOMLEFT",8,8); action:SetWidth(104); Backdrop(action,C.bg)
  local ah=Section(action,"ACTION BAR",C.gold); ah:SetPoint("TOPLEFT",8,-9)
  local views={{"Overview","OVERVIEW"},{"Story","STORY"},{"Quests","QUESTS"},{"Services","SERVICES"},{"Spawn","SPAWN"},{"Location","LOCATION"},{"Combat","COMBAT"},{"Loot","LOOT"},{"Technical","TECHNICAL"}}

  local workspace=CreateFrame("Frame",nil,body); workspace:SetPoint("TOPLEFT",120,-150); workspace:SetPoint("BOTTOMRIGHT",-8,8); Backdrop(workspace,C.bg)
  local wt=Section(workspace,"NPC OVERVIEW",C.inspect); wt:SetPoint("TOPLEFT",10,-10); Platform.NPCUI.workspaceTitle=wt
  local refresh=Button(workspace,"",23,21,function() Platform.NPCUI.Inspect(false) end,"Refresh the selected NPC")
  local rt=refresh:CreateTexture(nil,"ARTWORK"); rt:SetTexture("Interface\\Buttons\\UI-RotationRight-Button-Up"); rt:SetPoint("TOPLEFT",2,-2); rt:SetPoint("BOTTOMRIGHT",-2,2); refresh:SetPoint("BOTTOMLEFT",8,7)
  local help=Button(workspace,"?",22,21,nil,"NPC inspection follows selected creatures automatically. Use Inspect NPC or Refresh to force a new scan. Shift-click quest and item rows to insert game links into chat."); help:SetPoint("LEFT",refresh,"RIGHT",5,0)

  local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_NPCScroll",workspace,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",8,-31); scroll:SetPoint("BOTTOMRIGHT",-29,34)
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(380); child:SetHeight(420); scroll:SetScrollChild(child); Platform.NPCUI.textChild=child
  local text=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); text:SetPoint("TOPLEFT",4,-4); text:SetWidth(360); text:SetJustifyH("LEFT"); text:SetJustifyV("TOP"); text:SetTextColor(unpack(C.white)); Platform.NPCUI.text=text

  local modelViewport=CreateFrame("Frame",nil,workspace); modelViewport:SetPoint("TOPLEFT",workspace,"TOP",4,-35); modelViewport:SetPoint("BOTTOMRIGHT",-8,34); Platform.NPCUI.modelViewport=modelViewport
  local model=CreateFrame("PlayerModel",nil,modelViewport); model:SetAllPoints(modelViewport); model:SetUnit("player"); if model.SetCamDistanceScale then model:SetCamDistanceScale(1) end; model.azerFacing=0; Platform.NPCUI.model=model
  Button(modelViewport,"<",25,20,function() model.azerFacing=model.azerFacing-.25; model:SetFacing(model.azerFacing) end,"Rotate NPC left"):SetPoint("TOPLEFT",8,-8)
  Button(modelViewport,">",25,20,function() model.azerFacing=model.azerFacing+.25; model:SetFacing(model.azerFacing) end,"Rotate NPC right"):SetPoint("TOPRIGHT",-8,-8)

  Platform.NPCUI.Clear=function()
    Platform.NPCUI.autoInspect=true
    Platform.NPCUI.activeOperation="Inspect NPC"
    Platform.NPCUI.server={quests={},loot={},lootReferences={},story={}}
    Platform.NPCUI.captureEntry=nil
    Platform.NPCUI.requestEntry=nil
    Platform.NPCUI.inspectionLoading=false
    Platform.NPCUI.ignoreStream=true
    Platform.NPCUI.searchQuery=""
    Platform.NPCUI.searchResults={}
    Platform.NPCUI.spawns={}
    Platform.NPCUI.spawnTotal=0
    Platform.NPCUI.selectedSearch=nil
    Platform.NPCUI.selectedSpawn=nil
    Platform.NPCUI.searchLoading=false
    Platform.NPCUI.spawnsLoading=false
    Platform.NPCUI.lootLinkRetry=0
    Platform.NPCUI.lootLinkRetryPending=false
    Platform.NPCUI.view="OVERVIEW"

    searchBox:SetText("")
    searchBox:ClearFocus()

    if Platform.NPCUI.RefreshOperationButtons then
      Platform.NPCUI.RefreshOperationButtons()
    end

    Platform.NPCUI.Render()

    portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    model:SetUnit("player")
    iname:SetText("No creature selected")
    imeta:SetText("Search for an NPC or target a live creature to inspect it.")

    SetStatus("NPC workspace cleared.")
  end

  local function QuestLink(q)
    if GetQuestLink then local link=GetQuestLink(tonumber(q.id)); if link then return link end end
    return string.format("|cffffff00|Hquest:%d:%d|h[%s]|h|r",tonumber(q.id) or 0,tonumber(q.level) or 0,q.title or ("Quest "..tostring(q.id)))
  end
  local function ItemLink(item)
    return Platform.NativeItemLink(item)
  end

  local function InsertLink(link)
    return Platform.InsertItemLink(link)
  end

  local function AddLinkedRow(i)
    local row=Button(
      child,
      "",
      355,
      44,
      function() end,
      "Shift-click to insert this link in chat"
    )

    row:SetScript("OnMouseUp",function(self,button)
      if button~="LeftButton" or not IsShiftKeyDown() then return end

      if not self.link then
        if self.linkExpected then
          SetStatus(
            "This item is not yet cached by the WoW client; its chat link is unavailable.",
            true
          )
        end
        return
      end

      InsertLink(self.link)
    end)

    local rowLabel=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    rowLabel:SetPoint("TOPLEFT",7,-6)
    rowLabel:SetPoint("RIGHT",-7,0)
    rowLabel:SetJustifyH("LEFT")
    rowLabel:SetJustifyV("TOP")
    rowLabel:SetWordWrap(true)
    row:SetFontString(rowLabel)
    row.label=rowLabel

    local detail=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT",rowLabel,"BOTTOMLEFT",0,-3)
    detail:SetPoint("RIGHT",-7,0)
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(true)
    detail:SetTextColor(.75,.75,.75)
    row.detail=detail

    row:SetPoint("TOPLEFT",2,-2-(i-1)*47)
    row:Hide()
    Platform.NPCUI.questRows[i]=row
  end

  for i=1,14 do AddLinkedRow(i) end

  local function EnsureLinkedRows(count)
    for i=#Platform.NPCUI.questRows+1,count do AddLinkedRow(i) end
  end

  local function NPCQuestStateText(state)
    state=tostring(state or "UNKNOWN"):upper()

    local color="|cffaaaaaa"
    if state=="AVAILABLE" or state=="READY" or state=="COMPLETED" then
      color="|cff55ff55"
    elseif state=="ACTIVE" then
      color="|cffffff55"
    elseif state=="FUTURE" then
      color="|cffffaa55"
    elseif state=="FAILED" or state=="BLOCKED" or state=="INELIGIBLE" then
      color="|cffff5555"
    end

    return color.."["..state.."]|r"
  end

  local function BuildNPCQuestDisplayRows(quests)
    local rows={}
    local byId={}

    for _,q in ipairs(quests or {}) do
      local key=tostring(q.id or "?")
      local entry=byId[key]

      if not entry then
        entry={
          quest=q,
          start=false,
          finish=false,
        }
        byId[key]=entry
        table.insert(rows,entry)
      end

      local relation=tostring(q.relation or ""):upper()
      if relation=="START" then
        entry.start=true
      elseif relation=="END" then
        entry.finish=true
      end
    end

    return rows
  end

  local function LayoutNPCQuestRow(row,y,entry)
    local q=entry.quest or {}

    local relation
    if entry.start and entry.finish then
      relation="START + END"
    elseif entry.start then
      relation="START"
    elseif entry.finish then
      relation="END"
    else
      relation="RELATION"
    end

    local state=q.eligibility or q.status or "UNKNOWN"

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT",2,-y)
    row:SetWidth(355)
    row.label:SetWordWrap(true)
    row.link=QuestLink(q)

    row:SetText(string.format(
      "|cffffd100%s|r  %s  %s  |cff888888[%s]|r",
      relation,
      NPCQuestStateText(state),
      q.title or ("Quest "..tostring(q.id or "?")),
      tostring(q.id or "?")
    ))

    local meta={
      "Req Lv "..tostring(q.min or "?"),
      "Quest Lv "..tostring(q.level or "?"),
      tostring(q.type or "Normal"),
    }

    if tostring(q.repeatable or "0")=="1" then
      table.insert(meta,"Repeatable")
    end

    local status=tostring(q.status or "NONE"):upper()
    if status~="" and status~="NONE" and status~="UNKNOWN" then
      table.insert(meta,"Status "..status)
    end

    local detailText=table.concat(meta,"  •  ")

    if q.reason and q.reason~="" then
      detailText=detailText.."\n"..q.reason
    end

    row.detail:SetText(detailText)
    row:Show()

    local titleHeight=math.max(13,row.label:GetStringHeight() or 13)
    local detailHeight=0

    if detailText~="" then
      detailHeight=math.max(13,row.detail:GetStringHeight() or 13)
    end

    local height=math.max(
      42,
      math.ceil(12 + titleHeight + (detailHeight>0 and detailHeight+4 or 0))
    )

    row:SetHeight(height)

    return y + height + 6
  end

  local function AddNPCSearchRow(i)
    local row=Button(
      child,
      "",
      355,
      46,
      function(self)
        if self.result and Platform.NPCUI.SelectSearchResult then
          Platform.NPCUI.SelectSearchResult(self.result)
        end
      end,
      "Select this creature and load its database spawns"
    )

    local label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",7,-6)
    label:SetPoint("RIGHT",-7,0)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(false)
    row:SetFontString(label)
    row.label=label

    local detail=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT",label,"BOTTOMLEFT",0,-4)
    detail:SetPoint("RIGHT",-7,0)
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(false)
    detail:SetTextColor(.70,.70,.70)
    row.detail=detail

    row:Hide()
    Platform.NPCUI.searchRows[i]=row
  end

  local function EnsureNPCSearchRows(count)
    for i=#Platform.NPCUI.searchRows+1,count do
      AddNPCSearchRow(i)
    end
  end

  local function AddNPCSpawnRow(i)
    local row=Button(
      child,
      "",
      355,
      52,
      function(self)
        if not self.spawn then return end
        Platform.NPCUI.selectedSpawn=self.spawn
        if Platform.NPCUI.Render then Platform.NPCUI.Render() end
        SetStatus(
          string.format(
            "Selected spawn %s for %s.",
            tostring(self.spawn.guid or "?"),
            tostring(
              Platform.NPCUI.selectedSearch
              and Platform.NPCUI.selectedSearch.name
              or "NPC"
            )
          )
        )
      end,
      "Select this database spawn. Use Go to Spawn to teleport."
    )

    local label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",7,-6)
    label:SetPoint("RIGHT",-7,0)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(false)
    row:SetFontString(label)
    row.label=label

    local detail=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT",label,"BOTTOMLEFT",0,-4)
    detail:SetPoint("RIGHT",-7,0)
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(true)
    detail:SetTextColor(.70,.70,.70)
    row.detail=detail

    row:Hide()
    Platform.NPCUI.spawnRows[i]=row
  end

  local function EnsureNPCSpawnRows(count)
    for i=#Platform.NPCUI.spawnRows+1,count do
      AddNPCSpawnRow(i)
    end
  end

  local function ServicesText(flags)
    flags=tonumber(flags) or 0; local names={}
    local defs={{1,"Gossip"},{2,"Quest giver"},{16,"Trainer"},{32,"Class trainer"},{64,"Profession trainer"},{128,"Vendor"},{256,"Ammo vendor"},{512,"Food vendor"},{1024,"Poison vendor"},{2048,"Reagent vendor"},{4096,"Repair"},{8192,"Flight master"},{16384,"Spirit healer"},{32768,"Spirit guide"},{65536,"Innkeeper"},{131072,"Banker"},{262144,"Petitioner"},{524288,"Tabard designer"},{1048576,"Battlemaster"},{2097152,"Auctioneer"},{4194304,"Stable master"},{16777216,"Guild banker"}}
    for _,d in ipairs(defs) do if bit.band(flags,d[1])~=0 then table.insert(names,"• "..d[2]) end end
    return #names>0 and table.concat(names,"\n") or "No standard NPC services are advertised."
  end
  local function FormatNPCStoryText(value, server)
    local story=tostring(value or "")
    if story=="" then return "" end

    local playerName=
      (server and server.begin and server.begin.player)
      or UnitName("player")
      or "player"

    local className=UnitClass("player") or "adventurer"

    -- Blizzard quest/creature text substitutions observed in the
    -- authoritative world DB. Keep unknown tokens untouched so that
    -- future regression cases remain visible instead of being guessed.
    story=story:gsub("%$[Nn]",function() return playerName end)
    story=story:gsub("%$[Cc]",function() return className end)
    story=story:gsub("%$[Bb]","\n")

    return story
  end

  local function NPCReportColor(text,color,formatted)
    text=tostring(text or "")
    if not formatted then return text end
    return "|cff"..color..text.."|r"
  end

  local function NPCStoryStatusText(value,formatted)
    local status=tostring(value or "UNKNOWN"):upper()

    local color="aaaaaa"

    if status=="COMPLETED" or status=="REWARDED" or status=="READY" then
      color="55ff55"
    elseif status=="ACTIVE" then
      color="ffff55"
    elseif status=="AVAILABLE" then
      color="55ff55"
    elseif status=="FUTURE" or status=="BLOCKED" or status=="INELIGIBLE" then
      color="ffaa55"
    elseif status=="FAILED" then
      color="ff5555"
    end

    return NPCReportColor("["..status.."]",color,formatted)
  end

  local function NPCStoryCategoryLabel(category,formatted)
    local labels={
      GOSSIP={"Introduction / gossip","66ccff"},
      GOSSIP_OPTION={"Conversation option","66ccff"},
      SPOKEN_LINE={"Spoken line","ffffff"},
      QUEST_DETAILS={"Quest story","ffd100"},
      QUEST_OBJECTIVES={"Quest objectives","5599ff"},
      QUEST_REQUEST={"Quest progress dialogue","ffff55"},
      QUEST_REWARD={"Quest completion dialogue","55ff55"},
      QUEST_COMPLETED={"Completed text","aaaaaa"},
    }

    local entry=labels[category]
    local label=entry and entry[1] or tostring(category or "Story")
    local color=entry and entry[2] or "ffd100"

    return NPCReportColor(label,color,formatted)
  end

  local function Report(formatted)
    local s=Platform.NPCUI.server or {}; local o=s.overview or {}; local st=s.state or {}; local l=s.location or {}; local t=s.technical or {}; local sp=s.spawn or {}
    local reportName=s.begin and s.begin.name or UnitName("target") or "No NPC"
    local reportEntry=s.begin and s.begin.entry or "?"

    if Platform.NPCUI.view=="SEARCH" and Platform.NPCUI.selectedSearch then
      reportName=Platform.NPCUI.selectedSearch.name or reportName
      reportEntry=Platform.NPCUI.selectedSearch.entry or reportEntry
    end

    local lines={"AZERCORE OPS — NPC REPORT",string.format("%s  |  Entry %s",reportName,reportEntry),"View: "..Platform.NPCUI.view,""}
    if Platform.NPCUI.view=="SEARCH" then
      table.insert(lines,"Search query: "..tostring(Platform.NPCUI.searchQuery or ""))

      if Platform.NPCUI.selectedSearch then
        local selected=Platform.NPCUI.selectedSearch

        table.insert(
          lines,
          string.format(
            "Selected: %s (Entry %s)",
            selected.name or "Creature",
            selected.entry or "?"
          )
        )

        table.insert(
          lines,
          string.format(
            "Reported world spawns: %s",
            Platform.NPCUI.spawnTotal or selected.spawns or 0
          )
        )

        for i,spawn in ipairs(Platform.NPCUI.spawns or {}) do
          table.insert(
            lines,
            string.format(
              "%02d. Spawn %s | Map %s | %s, %s, %s | Orientation %s | SpawnMask %s | PhaseMask %s | State %s | Grid %s%s%s",
              i,
              spawn.guid or "?",
              spawn.map or "?",
              spawn.x or "?",
              spawn.y or "?",
              spawn.z or "?",
              spawn.o or "?",
              spawn.spawnmask or "?",
              spawn.phasemask or "?",
              spawn.status or "UNKNOWN",
              spawn.gridloaded=="1" and "LOADED" or "INACTIVE",
              tonumber(spawn.respawn) and tonumber(spawn.respawn)>0
                and (" | Respawn "..tostring(spawn.respawn).."s")
                or "",
              spawn.samemap=="1"
                and (" | Distance "..tostring(spawn.distance or "?"))
                or ""
            )
          )
        end

        if #(Platform.NPCUI.spawns or {})==0 then
          table.insert(
            lines,
            Platform.NPCUI.spawnsLoading
              and "Loading database spawns..."
              or "No database spawns were returned."
          )
        end
      else
        for _,result in ipairs(Platform.NPCUI.searchResults or {}) do
          table.insert(
            lines,
            string.format(
              "%s (Entry %s) | Level %s-%s | Rank %s | Type %s | Spawns %s",
              result.name or "Creature",
              result.entry or "?",
              result.min or "?",
              result.max or "?",
              result.rank or "?",
              result.type or "?",
              result.spawns or "0"
            )
          )
        end

        if #(Platform.NPCUI.searchResults or {})==0 then
          table.insert(
            lines,
            Platform.NPCUI.searchLoading
              and "Searching..."
              or "No NPC search results loaded."
          )
        end
      end

    elseif Platform.NPCUI.view=="QUESTS" then
      for _,q in ipairs(s.quests or {}) do table.insert(lines,string.format("[%s] %s (ID %s) — %s / %s%s",q.relation or "?",q.title or "Quest",q.id or "?",q.status or "?",q.eligibility or "?",q.reason and q.reason~="" and (" — "..q.reason) or "")) end
      if #(s.quests or {})==0 then table.insert(lines,"This NPC has no reported quest relations for this character.") end
    elseif Platform.NPCUI.view=="STORY" then
      table.insert(lines,NPCReportColor("MY STORY PROGRESS","ffd100",formatted))

      for _,q in ipairs(s.quests or {}) do
        local relation=q.relation=="START" and "Begins here" or "Returns here"
        local relationColor=q.relation=="START" and "55ff55" or "5599ff"

        local line=string.format(
          "%s %s — %s%s",
          NPCStoryStatusText(q.eligibility or q.status or "UNKNOWN",formatted),
          NPCReportColor(
            q.title or ("Quest "..tostring(q.id)),
            "ffffff",
            formatted
          ),
          NPCReportColor(relation,relationColor,formatted),
          q.reason and q.reason~="" and
            (" — "..NPCReportColor(q.reason,"aaaaaa",formatted))
            or ""
        )

        table.insert(lines,line)
      end

      if #(s.quests or {})==0 then
        table.insert(
          lines,
          NPCReportColor(
            "No quest chapters are connected to this NPC for the current character.",
            "aaaaaa",
            formatted
          )
        )
      end

      table.insert(lines,"")
      table.insert(lines,NPCReportColor("DATABASE NARRATIVE","ffd100",formatted))

      -- NPC_STORY is deliberately transported in small protocol chunks.
      -- Reassemble each logical story record before presentation so that
      -- transport boundaries never become visible line breaks.
      local storyBlocks={}
      local currentStory

      for _,story in ipairs(s.story or {}) do
        local key=
          tostring(story.category or "STORY")..":"..
          tostring(story.id or "0")..":"..
          tostring(story.title or "")

        local startsBlock=tostring(story.part or "1")=="1"

        if not currentStory or startsBlock or currentStory.key~=key then
          currentStory={
            key=key,
            category=story.category,
            id=story.id,
            title=story.title,
            parts={},
          }
          table.insert(storyBlocks,currentStory)
        end

        table.insert(currentStory.parts,tostring(story.text or ""))
      end

      for _,story in ipairs(storyBlocks) do
        table.insert(lines,"")

        local heading=string.format(
          "%s — %s%s",
          NPCStoryCategoryLabel(story.category,formatted),
          NPCReportColor(story.title or "NPC","ffffff",formatted),
          story.id and story.id~="0"
            and (" "..NPCReportColor("["..story.id.."]","888888",formatted))
            or ""
        )

        table.insert(lines,heading)

        local joined=table.concat(story.parts," ")
        table.insert(
          lines,
          NPCReportColor(
            FormatNPCStoryText(joined,s),
            "dddddd",
            formatted
          )
        )
      end

      if #(s.story or {})==0 then
        table.insert(
          lines,
          NPCReportColor(
            "No database storyline was found for this NPC.",
            "aaaaaa",
            formatted
          )
        )
      end

    elseif Platform.NPCUI.view=="SERVICES" then table.insert(lines,ServicesText(o.npcflags))
    elseif Platform.NPCUI.view=="LOCATION" then
      table.insert(lines,string.format(
        "Map %s  Zone %s  Area %s\nInstance %s  Phase %s\nPosition %s, %s, %s  Orientation %s",
        l.map or "?",
        l.zone or "?",
        l.area or "?",
        l.instance or "?",
        l.phase or "?",
        l.x or "?",
        l.y or "?",
        l.z or "?",
        l.o or "?"
      ))
    elseif Platform.NPCUI.view=="SPAWN" then
      local movementNames={
        ["0"]="Idle",
        ["1"]="Random",
        ["2"]="Waypoint"
      }
      local movementType=tostring(sp.movement or "?")
      local movementName=movementNames[movementType] or "Other"
      local databaseSource=sp.dbspawn=="1" and "Database creature spawn" or "Runtime or summoned creature"
      local distanceText="Unknown"
      local currentX,currentY,currentZ=tonumber(l.x),tonumber(l.y),tonumber(l.z)
      local homeX,homeY,homeZ=tonumber(sp.homex),tonumber(sp.homey),tonumber(sp.homez)

      if currentX and currentY and currentZ and homeX and homeY and homeZ then
        local dx=currentX-homeX
        local dy=currentY-homeY
        local dz=currentZ-homeZ
        distanceText=string.format("%.2f yd",math.sqrt(dx*dx+dy*dy+dz*dz))
      end

      table.insert(lines,string.format(
        "Spawn ID: %s\nSource: %s\nHome position: %s, %s, %s  Orientation %s\nCurrent distance from home: %s\nRespawn delay: %s seconds\nCorpse delay: %s seconds\nMovement: %s (type %s)\nWander distance: %s yd",
        sp.spawnid or "?",
        databaseSource,
        sp.homex or "?",
        sp.homey or "?",
        sp.homez or "?",
        sp.homeo or "?",
        distanceText,
        sp.respawndelay or "?",
        sp.corpsedelay or "?",
        movementName,
        movementType,
        sp.wander or "?"
      ))
    elseif Platform.NPCUI.view=="COMBAT" then table.insert(lines,string.format("Alive: %s\nIn combat: %s\nHealth: %s / %s\nPower: %s / %s (type %s)",st.alive=="1" and "Yes" or "No",st.combat=="1" and "Yes" or "No",st.health or "?",st.maxhealth or "?",st.power or "?",st.maxpower or "?",st.powertype or "?"))
    elseif Platform.NPCUI.view=="LOOT" then
      local loot=s.loot or {}
      local references=s.lootReferences or {}

      table.insert(
        lines,
        string.format(
          "Creature loot template: %s\nPickpocket loot template: %s\nSkinning loot template: %s\nMoney: %s–%s copper",
          t.loot or "0",
          t.pickpocket or "0",
          t.skin or "0",
          t.mingold or "0",
          t.maxgold or "0"
        )
      )

      local function AppendLootSource(label,source)
        table.insert(lines,"\n"..label)

        local count=0

        for _,item in ipairs(loot) do
          local itemSource=item.source or "CREATURE"

          if itemSource==source then
            count=count+1

            local groupId=tonumber(item.group) or 0
            local chanceText=tostring(item.chance or "?")

            if groupId>0 then
              local groupInfo=
                Platform.NPCUI.GroupChanceInfo(
                  item,
                  loot,
                  references
                )

              if
                groupInfo
                and groupInfo.kind=="EQUAL"
                and groupInfo.baseline
              then
                chanceText=
                  "Group "..tostring(groupId)..
                  ", equal remainder, baseline "..
                  string.format("%.2f",groupInfo.baseline)..
                  "%*"

              elseif
                groupInfo
                and groupInfo.kind=="EQUAL"
              then
                chanceText=
                  "Group "..tostring(groupId)..
                  ", equal remainder, DB Chance "..
                  chanceText

              else
                chanceText=
                  "Group "..tostring(groupId)..
                  ", explicit DB chance "..
                  chanceText.."%"
              end
            else
              chanceText=chanceText.."% chance"
            end

            table.insert(
              lines,
              string.format(
                "%s (ID %s) — %s, %s–%s, LootMode %s%s",
                item.name or "Item",
                item.id or "?",
                chanceText,
                item.min or "?",
                item.max or "?",
                item.lootmode or "1",
                item.quest=="1" and " — quest item" or ""
              )
            )
          end
        end

        if count==0 then
          table.insert(lines,"No direct items.")
        end
      end

      AppendLootSource("CREATURE DROPS","CREATURE")

      table.insert(lines,"\nREFERENCE POOLS")

      if #references==0 then
        table.insert(lines,"No top-level reference pools.")
      else
        for _,ref in ipairs(references) do
          table.insert(
            lines,
            string.format(
              "Pool %s — source %s, parent table %s, raw Chance %s, Group %s, Count %s–%s, LootMode %s, %s rows (%s direct, %s nested)%s",
              ref.reference or "?",
              ref.source or "?",
              ref.table or "?",
              ref.chance or "?",
              ref.group or "0",
              ref.min or "?",
              ref.max or "?",
              ref.lootmode or "1",
              ref.rows or "0",
              ref.directrows or "0",
              ref.nestedrows or "0",
              ref.comment and ref.comment~="" and (" — "..ref.comment) or ""
            )
          )
        end
      end

      table.insert(
        lines,
        "\n* Group baseline assumes all shown members are eligible. Conditions, LootMode and script hooks can change the eligible pool."
      )

      AppendLootSource("PICKPOCKET","PICKPOCKET")

      if tonumber(t.skin or 0)>0 then
        AppendLootSource("SKINNING","SKINNING")
      else
        table.insert(lines,"\nSKINNING")
        table.insert(lines,"No skinning loot table configured.")
      end
    elseif Platform.NPCUI.view=="TECHNICAL" then table.insert(lines,string.format("GUID: %s\nEntry: %s\nFaction template: %s\nNPC flags: %s\nUnit flags: %s\nDynamic flags: %s\nAI: %s\nScript ID: %s",s.begin and s.begin.guid or "?",s.begin and s.begin.entry or "?",o.faction or "?",o.npcflags or "?",t.unitflags or "?",t.dynamicflags or "?",t.ai or "None",t.script or "0"))
    else table.insert(lines,string.format("Level: %s (template %s–%s)\nRank: %s  Type: %s  Family: %s\nQuest relations: %d\n\nSelect another Action Bar view for detailed information.",o.level or UnitLevel("target") or "?",o.min or "?",o.max or "?",o.rank or "?",o.type or "?",o.family or "?",#(s.quests or {}))) end
    return table.concat(lines,"\n")
  end
  Platform.NPCUI.GroupChanceInfo=function(entry,loot,references)
    local groupId=tonumber(entry and entry.group) or 0

    if groupId<=0 then
      return nil
    end

    local source=tostring(entry.source or "CREATURE")
    local tableId=tostring(entry.table or "")
    local explicitTotal=0
    local equalCount=0

    local function Include(row)
      if
        tostring(row.source or "CREATURE")==source
        and tostring(row.table or "")==tableId
        and (tonumber(row.group) or 0)==groupId
      then
        local chance=tonumber(row.chance) or 0

        if chance>0 then
          explicitTotal=explicitTotal+chance
        else
          equalCount=equalCount+1
        end
      end
    end

    for _,row in ipairs(loot or {}) do
      Include(row)
    end

    for _,row in ipairs(references or {}) do
      Include(row)
    end

    local rawChance=tonumber(entry.chance) or 0

    if rawChance>0 then
      return {
        kind="EXPLICIT",
        raw=rawChance,
        explicitTotal=explicitTotal,
        equalCount=equalCount
      }
    end

    local remainder=100-explicitTotal

    if remainder<0 then
      remainder=0
    end

    local baseline=nil

    if equalCount>0 and explicitTotal<100 then
      baseline=remainder/equalCount
    end

    return {
      kind="EQUAL",
      raw=rawChance,
      explicitTotal=explicitTotal,
      equalCount=equalCount,
      remainder=remainder,
      baseline=baseline
    }
  end

  Platform.NPCUI.Report=function() return Report(false) end
  Platform.NPCUI.Render=function()
    local s=Platform.NPCUI.server or {}; local title={SEARCH="NPC SEARCH / WORLD SPAWNS",OVERVIEW="NPC OVERVIEW",STORY="NPC STORY",QUESTS="QUEST INTELLIGENCE",SERVICES="SERVICES",SPAWN="SPAWN INFORMATION",LOCATION="LOCATION",COMBAT="COMBAT STATE",LOOT="LOOT",TECHNICAL="TECHNICAL"}
    wt:SetText(title[Platform.NPCUI.view] or "NPC")
    for key,button in pairs(Platform.NPCUI.viewButtons) do
      if key==Platform.NPCUI.view then button:SetBackdropColor(unpack(C.selected)); button:SetBackdropBorderColor(unpack(C.gold))
      else button:SetBackdropColor(unpack(C.button)); button:SetBackdropBorderColor(unpack(C.border)) end
    end
    if Platform.NPCUI.view=="OVERVIEW" then modelViewport:Show(); scroll:Hide() else modelViewport:Hide(); scroll:Show() end
    for _,row in ipairs(Platform.NPCUI.questRows) do row:Hide() end
    for _,row in ipairs(Platform.NPCUI.searchRows or {}) do row:Hide() end
    for _,row in ipairs(Platform.NPCUI.spawnRows or {}) do row:Hide() end

    local searchContentWidth=nil

    if Platform.NPCUI.view=="SEARCH" or Platform.NPCUI.view=="LOOT" then
      local availableWidth=scroll:GetWidth() or 0

      -- During the first frame after /reload WoW can report zero width.
      -- Use the known NPC workspace fallback until layout is resolved.
      if availableWidth<420 then availableWidth=480 end

      searchContentWidth=math.floor(availableWidth-18)

      child:SetWidth(searchContentWidth)
      text:SetWidth(searchContentWidth-12)
    else
      -- Preserve the dimensions used by the validated Quest / Story views.
      child:SetWidth(380)
      text:SetWidth(360)
    end

    if Platform.NPCUI.view=="SEARCH" then
      local selected=Platform.NPCUI.selectedSearch

      if not selected then
        local results=Platform.NPCUI.searchResults or {}

        if Platform.NPCUI.searchLoading then
          text:SetText(
            "Searching for |cffffd100"..
            tostring(Platform.NPCUI.searchQuery or "")..
            "|r..."
          )
        elseif #results==0 then
          text:SetText(
            "Search by creature name or exact Entry ID.\n"..
            "Select a result to load its authoritative database spawns."
          )
        else
          text:SetText(
            string.format(
              "%d search result%s for |cffffd100%s|r\n"..
              "Select an NPC to load its world spawns.",
              #results,
              #results==1 and "" or "s",
              tostring(Platform.NPCUI.searchQuery or "")
            )
          )
        end

        EnsureNPCSearchRows(#results)

        local y=math.max(50,math.ceil(text:GetStringHeight()+16))

        for i,result in ipairs(results) do
          local row=Platform.NPCUI.searchRows[i]

          row:ClearAllPoints()
          row:SetPoint("TOPLEFT",2,-y)
          row:SetWidth(math.max(355,(searchContentWidth or 380)-8))
          row:SetHeight(46)
          row.result=result
          row:SetBackdropColor(unpack(C.button))
          row:SetBackdropBorderColor(unpack(C.border))

          row:SetText(
            string.format(
              "|cffffd100%s|r  |cff888888[Entry %s]|r",
              result.name or "Creature",
              result.entry or "?"
            )
          )

          local minLevel=tostring(result.min or "?")
          local maxLevel=tostring(result.max or "?")
          local levelText=minLevel==maxLevel and minLevel or (minLevel.."–"..maxLevel)

          row.detail:SetText(
            string.format(
              "Level %s  •  Rank %s  •  Type %s  •  %s world spawn%s",
              levelText,
              tostring(result.rank or "?"),
              tostring(result.type or "?"),
              tostring(result.spawns or "0"),
              tonumber(result.spawns)==1 and "" or "s"
            )
          )

          row:Show()
          y=y+52
        end

        child:SetHeight(math.max(360,y+8))

      else
        local spawns=Platform.NPCUI.spawns or {}

        local headerText=string.format(
          "|cffffd100%s|r  |cff888888[Entry %s]|r\n%s",
          selected.name or "Creature",
          selected.entry or "?",
          Platform.NPCUI.spawnsLoading
            and "Loading authoritative database spawns..."
            or string.format(
              "Showing %d of %d database spawn%s. Select one, then use Go to Spawn.",
              #spawns,
              tonumber(Platform.NPCUI.spawnTotal) or #spawns,
              (tonumber(Platform.NPCUI.spawnTotal) or #spawns)==1 and "" or "s"
            )
        )

        text:SetText(headerText)

        EnsureNPCSpawnRows(#spawns)

        local y=math.max(58,math.ceil(text:GetStringHeight()+16))

        for i,spawn in ipairs(spawns) do
          local row=Platform.NPCUI.spawnRows[i]
          local selectedSpawn=
            Platform.NPCUI.selectedSpawn
            and tostring(Platform.NPCUI.selectedSpawn.guid)==tostring(spawn.guid)

          row:ClearAllPoints()
          row:SetPoint("TOPLEFT",2,-y)
          row:SetWidth(math.max(355,(searchContentWidth or 380)-8))
          row:SetHeight(64)
          row.spawn=spawn

          if selectedSpawn then
            row:SetBackdropColor(unpack(C.selected))
            row:SetBackdropBorderColor(unpack(C.gold))
          else
            row:SetBackdropColor(unpack(C.button))
            row:SetBackdropBorderColor(unpack(C.border))
          end

          local nearest=
            i==1 and spawn.samemap=="1"
            and "  |cff55ff55NEAREST|r"
            or ""

          row:SetText(
            string.format(
              "Spawn %s  •  Map %s%s",
              tostring(spawn.guid or "?"),
              tostring(spawn.map or "?"),
              nearest
            )
          )

          local distance=
            spawn.samemap=="1"
            and tonumber(spawn.distance)
            and string.format("Distance %.2f yd",tonumber(spawn.distance))
            or "Different map"

          local spawnStatus=tostring(spawn.status or "UNKNOWN")
          local statusColors={
            ALIVE="|cff55ff55",
            DEAD="|cffff5555",
            RESPAWNING="|cffffaa00",
            NOT_LOADED="|cffaaaaaa",
            NOT_PRESENT="|cffffff55",
            MAP_NOT_ACTIVE="|cff888888",
            UNKNOWN="|cffffffff"
          }

          local statusText=
            (statusColors[spawnStatus] or statusColors.UNKNOWN)
            ..spawnStatus.."|r"

          if tonumber(spawn.respawn) and tonumber(spawn.respawn)>0 then
            statusText=statusText.." ("..tostring(spawn.respawn).."s)"
          end

          local gridText=
            spawn.gridloaded=="1"
            and "|cff55ff55LOADED|r"
            or "|cffaaaaaaINACTIVE|r"

          row.detail:SetText(
            string.format(
              "%s  •  Position %s, %s, %s\nState %s  •  Grid %s  •  SpawnMask %s  •  Phase %s",
              distance,
              tostring(spawn.x or "?"),
              tostring(spawn.y or "?"),
              tostring(spawn.z or "?"),
              statusText,
              gridText,
              tostring(spawn.spawnmask or "?"),
              tostring(spawn.phasemask or "?")
            )
          )

          row:Show()
          y=y+70
        end

        child:SetHeight(math.max(360,y+8))
      end

    elseif Platform.NPCUI.view=="QUESTS" then
      local quests=s.quests or {}
      local displayRows=BuildNPCQuestDisplayRows(quests)

      text:SetText(string.format(
        "%d quest relation%s  •  %d unique quest%s\nShift-click a quest row to insert its link in chat.",
        #quests,
        #quests==1 and "" or "s",
        #displayRows,
        #displayRows==1 and "" or "s"
      ))

      EnsureLinkedRows(#displayRows)

      local y=math.max(42,math.ceil(text:GetStringHeight()+14))

      for i,entry in ipairs(displayRows) do
        local row=Platform.NPCUI.questRows[i]
        if row then
          y=LayoutNPCQuestRow(row,y,entry)
        end
      end

      child:SetHeight(math.max(360,y+6))

    elseif Platform.NPCUI.view=="LOOT" then
      local t=s.technical or {}
      local loot=s.loot or {}
      local references=s.lootReferences or {}

      local creatureLoot={}
      local pickpocketLoot={}
      local skinningLoot={}

      for _,item in ipairs(loot) do
        local source=item.source or "CREATURE"

        if source=="PICKPOCKET" then
          table.insert(pickpocketLoot,item)
        elseif source=="SKINNING" then
          table.insert(skinningLoot,item)
        else
          table.insert(creatureLoot,item)
        end
      end

      text:SetText(
        string.format(
          "Money: %s–%s copper\n"..
          "Shift-click item cards to insert native item links in chat.\n"..
          "|cff888888Grouped items follow AzerothCore group semantics. Baseline equal-remainder chance assumes all shown members are eligible; conditions, LootMode and script hooks can change the pool. Reference pools remain raw DB values.|r",
          t.mingold or "0",
          t.maxgold or "0"
        )
      )

      local cards={}

      local function AddHeader(label,detail)
        table.insert(
          cards,
          {
            kind="HEADER",
            label=label,
            detail=detail
          }
        )
      end

      local function AddItems(items)
        for _,item in ipairs(items) do
          table.insert(
            cards,
            {
              kind="ITEM",
              item=item
            }
          )
        end
      end

      AddHeader(
        "CREATURE DROPS",
        tonumber(t.loot or 0)>0
          and string.format(
            "Template %s  •  %d direct item%s",
            t.loot or "0",
            #creatureLoot,
            #creatureLoot==1 and "" or "s"
          )
          or "No creature loot table configured."
      )

      AddItems(creatureLoot)

      AddHeader(
        "REFERENCE POOLS",
        string.format(
          "%d top-level reference pool%s",
          #references,
          #references==1 and "" or "s"
        )
      )

      for _,ref in ipairs(references) do
        table.insert(
          cards,
          {
            kind="REFERENCE",
            reference=ref
          }
        )
      end

      AddHeader(
        "PICKPOCKET",
        tonumber(t.pickpocket or 0)>0
          and string.format(
            "Template %s  •  %d direct item%s",
            t.pickpocket or "0",
            #pickpocketLoot,
            #pickpocketLoot==1 and "" or "s"
          )
          or "No pickpocket loot table configured."
      )

      AddItems(pickpocketLoot)

      AddHeader(
        "SKINNING",
        tonumber(t.skin or 0)>0
          and string.format(
            "Template %s  •  %d direct item%s",
            t.skin or "0",
            #skinningLoot,
            #skinningLoot==1 and "" or "s"
          )
          or "No skinning loot table configured."
      )

      AddItems(skinningLoot)

      EnsureLinkedRows(#cards)

      local y=math.max(64,math.ceil(text:GetStringHeight()+18))
      local missingLinks=0

      for i,card in ipairs(cards) do
        local row=Platform.NPCUI.questRows[i]

        if row then
          row:ClearAllPoints()
          row:SetPoint("TOPLEFT",2,-y)
          row:SetWidth(math.max(355,(searchContentWidth or 380)-8))

          row.link=nil
          row.linkExpected=false
          row.label:SetWordWrap(false)

          if card.kind=="HEADER" then
            row:SetHeight(38)
            row:SetBackdropColor(unpack(C.panel))
            row:SetBackdropBorderColor(unpack(C.border))

            row:SetText(
              "|cff66ccff"..
              tostring(card.label or "LOOT")..
              "|r"
            )

            row.detail:SetText(
              tostring(card.detail or "")
            )

            row:Show()
            y=y+44

          elseif card.kind=="REFERENCE" then
            local ref=card.reference or {}

            row:SetHeight(
              ref.comment and ref.comment~=""
                and 84
                or 68
            )

            row:SetBackdropColor(unpack(C.button))
            row:SetBackdropBorderColor(unpack(C.border))

            row:SetText(
              string.format(
                "|cffffd100Reference Pool %s|r  |cff888888[%s]|r",
                tostring(ref.reference or "?"),
                tostring(ref.source or "REFERENCE")
              )
            )

            local detail=
              string.format(
                "Parent template %s  •  Raw Chance %s  •  Group %s  •  Count %s–%s  •  LootMode %s\n"..
                "%s rows  •  %s direct items  •  %s child references",
                tostring(ref.table or "?"),
                tostring(ref.chance or "?"),
                tostring(ref.group or "0"),
                tostring(ref.min or "?"),
                tostring(ref.max or "?"),
                tostring(ref.lootmode or "1"),
                tostring(ref.rows or "0"),
                tostring(ref.directrows or "0"),
                tostring(ref.nestedrows or "0")
              )

            if ref.comment and ref.comment~="" then
              detail=detail.."\n"..tostring(ref.comment)
            end

            row.detail:SetText(detail)

            row:Show()
            y=y+row:GetHeight()+6

          elseif card.kind=="ITEM" then
            local item=card.item or {}
            local link=ItemLink(item)

            if not link then
              missingLinks=missingLinks+1
            end

            row.link=link
            row.linkExpected=true

            row:SetHeight(50)
            row:SetBackdropColor(unpack(C.button))
            row:SetBackdropBorderColor(unpack(C.border))

            local displayName

            if link then
              displayName=link
            else
              local quality=tonumber(item.quality) or 1
              local r,g,b=GetItemQualityColor(quality)

              local hex=string.format(
                "ff%02x%02x%02x",
                math.floor((r or 1)*255+.5),
                math.floor((g or 1)*255+.5),
                math.floor((b or 1)*255+.5)
              )

              displayName=
                "|c"..hex..
                tostring(
                  item.name
                  or ("Item "..tostring(item.id))
                )..
                "|r"
            end

            row:SetText(
              string.format(
                "%s  |cff888888[ID %s]|r",
                displayName,
                tostring(item.id or "?")
              )
            )

            local chanceValue=tostring(item.chance or "?")
            local groupId=tonumber(item.group) or 0
            local chanceText

            if groupId>0 then
              local groupInfo=
                Platform.NPCUI.GroupChanceInfo(
                  item,
                  loot,
                  references
                )

              if
                groupInfo
                and groupInfo.kind=="EQUAL"
                and groupInfo.baseline
              then
                chanceText=
                  "Group "..tostring(groupId)..
                  "  •  Equal remainder"..
                  "  •  Baseline "..
                  string.format("%.2f",groupInfo.baseline)..
                  "%*"

              elseif
                groupInfo
                and groupInfo.kind=="EQUAL"
              then
                chanceText=
                  "Group "..tostring(groupId)..
                  "  •  Equal remainder"..
                  "  •  DB Chance "..chanceValue

              else
                chanceText=
                  "Group "..tostring(groupId)..
                  "  •  Explicit DB chance "..chanceValue.."%"
              end
            else
              chanceText=
                chanceValue.."% chance"
            end

            local details={
              chanceText,
              "Count "..
                tostring(item.min or "?")..
                "–"..
                tostring(item.max or "?")
            }

            if tostring(item.lootmode or "1")~="1" then
              table.insert(
                details,
                "LootMode "..tostring(item.lootmode)
              )
            end

            if item.quest=="1" then
              table.insert(
                details,
                "|cffffd100Quest item|r"
              )
            end

            row.detail:SetText(
              table.concat(details,"  •  ")
            )

            row:Show()
            y=y+56
          end
        end
      end

      child:SetHeight(math.max(360,y+8))

      if missingLinks==0 then
        Platform.NPCUI.lootLinkRetry=0
        Platform.NPCUI.lootLinkRetryPending=false

      elseif
        (Platform.NPCUI.lootLinkRetry or 0)<20
        and not Platform.NPCUI.lootLinkRetryPending
      then
        Platform.NPCUI.lootLinkRetryPending=true

        After(.25,function()
          Platform.NPCUI.lootLinkRetryPending=false
          Platform.NPCUI.lootLinkRetry=
            (Platform.NPCUI.lootLinkRetry or 0)+1

          if
            Platform.NPCUI.view=="LOOT"
            and Platform.NPCUI.Render
          then
            Platform.NPCUI.Render()
          end
        end)
      end

    else
      text:SetText(Report(true))
      child:SetHeight(math.max(360,text:GetStringHeight()+16))
    end
  end
  for i,d in ipairs(views) do
    local viewLabel,viewKey=d[1],d[2]
    local b=Button(
      action,
      viewLabel,
      88,
      22,
      function()
        Platform.NPCUI.view=viewKey

        local entry=TargetCreatureEntry()
        local loadedEntry=
          Platform.NPCUI.server
          and Platform.NPCUI.server.begin
          and Platform.NPCUI.server.begin.entry
          or nil

        if
          entry
          and tonumber(loadedEntry)~=tonumber(entry)
          and Platform.NPCUI.Inspect
        then
          Platform.NPCUI.Inspect(true)
        end

        Platform.NPCUI.Render()
      end,
      "Open the NPC "..viewLabel.." workspace"
    )

    b:SetPoint("TOPLEFT",8,-29-(i-1)*27)
    Platform.NPCUI.viewButtons[viewKey]=b
    b:SetScript("OnLeave",function() if Platform.NPCUI.Render then Platform.NPCUI.Render() end; GameTooltip:Hide() end)
  end
  local copyButton=Button(
    workspace,
    "Copy",
    70,
    22,
    function()
      ShowSelectableReport("Copy NPC report",Report(false))
    end,
    "Copy the active NPC workspace report"
  )
  copyButton:SetPoint("BOTTOMRIGHT",-164,7)

  local shareButton=Button(
    workspace,
    "Share",
    70,
    22,
    function()
      local f=EnsureShareFrame()
      f:SetCapturedMessage(
        Report(false),
        "NPC",
        function() return Report(false) end,
        "NPC"
      )
      f:Show()
      f:Raise()
    end,
    "Share the active NPC workspace report"
  )
  shareButton:SetPoint("BOTTOMRIGHT",-86,7)

  local exportButton=Button(
    workspace,
    "Export",
    70,
    22,
    function()
      ShowSelectableReport("Export NPC report",Report(false))
    end,
    "Export the active NPC workspace report"
  )
  exportButton:SetPoint("BOTTOMRIGHT",-8,7)

  Platform.NPCUI.Update=function()
    local valid=UnitExists("target") and not UnitIsPlayer("target")
    local databaseSelection=Platform.NPCUI.selectedSearch

    if valid then
      SetPortraitTexture(portrait,"target")
      model:SetUnit("target")

      iname:SetText(UnitName("target") or "Creature")
      imeta:SetText(
        string.format(
          "Level %s %s\n%s",
          UnitLevel("target") or "?",
          UnitClassification("target") or "Creature",
          UnitIsDeadOrGhost("target") and "Dead" or "Alive"
        )
      )

    elseif databaseSelection then
      portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      model:SetUnit("player")

      iname:SetText(databaseSelection.name or "Creature")
      imeta:SetText(
        string.format(
          "Entry %s  •  Database selection\n%s world spawn%s  •  No live creature targeted",
          tostring(databaseSelection.entry or "?"),
          tostring(
            tonumber(Platform.NPCUI.spawnTotal)
            or tonumber(databaseSelection.spawns)
            or 0
          ),
          (
            tonumber(Platform.NPCUI.spawnTotal)
            or tonumber(databaseSelection.spawns)
            or 0
          )==1 and "" or "s"
        )
      )

    else
      portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      model:SetUnit("player")

      iname:SetText("No creature selected")
      imeta:SetText(
        "Search for an NPC or target a live creature to inspect it."
      )
    end

    RefreshNPCOperationButtons()
    Platform.NPCUI.Render()
  end
  Platform.NPCUI.Inspect=function(silent,force)
    local id,err=TargetCreatureEntry()

    if not id then
      Platform.NPCUI.requestEntry=nil
      Platform.NPCUI.inspectionLoading=false
      if not silent then SetStatus(err,true) end
      Platform.NPCUI.Update()
      return
    end

    if
      not force
      and Platform.NPCUI.inspectionLoading
      and tonumber(Platform.NPCUI.requestEntry)==tonumber(id)
    then
      return
    end

    Platform.NPCUI.requestEntry=id
    Platform.NPCUI.inspectionLoading=true
    Platform.NPCUI.captureEntry=id
    Platform.NPCUI.ignoreStream=false

    SendCommand(CMD.npcInspect)

    if silent then
      SetStatus("Inspecting "..tostring(UnitName("target")).."...")
    end
  end

  Platform.NPCUI.Search=function()
    local query=
      tostring(
        Platform.NPCUI.searchBox
        and Platform.NPCUI.searchBox:GetText()
        or ""
      )

    query=query:gsub("^%s+",""):gsub("%s+$","")

    if query=="" then
      SetStatus("Enter an NPC name or exact Entry ID.",true)
      if Platform.NPCUI.searchBox then Platform.NPCUI.searchBox:SetFocus() end
      return
    end

    Platform.NPCUI.autoInspect=true
    Platform.NPCUI.activeOperation="Search NPC"
    Platform.NPCUI.searchQuery=query
    Platform.NPCUI.searchResults={}
    Platform.NPCUI.spawns={}
    Platform.NPCUI.spawnTotal=0
    Platform.NPCUI.selectedSearch=nil
    Platform.NPCUI.selectedSpawn=nil
    Platform.NPCUI.searchLoading=true
    Platform.NPCUI.spawnsLoading=false
    Platform.NPCUI.view="SEARCH"

    RefreshNPCOperationButtons()
    Platform.NPCUI.Render()

    SendCommand(string.format(CMD.npcSearch,query))
  end

  Platform.NPCUI.LoadSpawns=function(entry)
    entry=tonumber(entry)

    if not entry or entry<=0 then
      SetStatus("Cannot load spawns: invalid NPC Entry ID.",true)
      return
    end

    Platform.NPCUI.spawns={}
    Platform.NPCUI.spawnTotal=0
    Platform.NPCUI.selectedSpawn=nil
    Platform.NPCUI.spawnsLoading=true
    Platform.NPCUI.view="SEARCH"

    Platform.NPCUI.Render()
    SendCommand(string.format(CMD.npcSpawns,entry))
  end

  Platform.NPCUI.SelectSearchResult=function(result)
    if not result or not tonumber(result.entry) then return end

    Platform.NPCUI.selectedSearch=result
    Platform.NPCUI.selectedSpawn=nil
    Platform.NPCUI.spawns={}
    Platform.NPCUI.spawnTotal=tonumber(result.spawns) or 0
    Platform.NPCUI.view="SEARCH"

    Platform.NPCUI.LoadSpawns(tonumber(result.entry))
  end

  Platform.NPCUI.GoToNPC=function()
    local entry,err=TargetCreatureEntry()

    if not entry then
      SetStatus(err or "Select a live creature first.",true)
      return
    end

    local server=Platform.NPCUI.server or {}
    local begin=server.begin or {}
    local location=server.location or {}

    if tonumber(begin.entry)~=tonumber(entry) then
      if Platform.NPCUI.Inspect then Platform.NPCUI.Inspect(true,true) end
      SetStatus("Refreshing the selected NPC. Press Go to NPC again when inspection completes.",true)
      return
    end

    local map=tonumber(location.map)
    local x=tonumber(location.x)
    local y=tonumber(location.y)
    local z=tonumber(location.z)
    local o=tonumber(location.o)

    if not map or not x or not y or not z or not o then
      if Platform.NPCUI.Inspect then Platform.NPCUI.Inspect(true,true) end
      SetStatus("NPC location is not loaded yet. Press Go to NPC again after inspection completes.",true)
      return
    end

    -- Arrive slightly behind the NPC instead of inside its model.
    local arrivalDistance=2.5
    local destinationX=x-math.cos(o)*arrivalDistance
    local destinationY=y-math.sin(o)*arrivalDistance

    SendCommand(
      string.format(
        CMD.movementGo,
        map,
        destinationX,
        destinationY,
        z,
        o
      )
    )

    SetStatus(
      string.format(
        "Going to %s. Emergency Return is available after a successful teleport.",
        tostring(begin.name or UnitName("target") or "selected NPC")
      )
    )
  end

  Platform.NPCUI.GoToSpawn=function()
    local spawn=Platform.NPCUI.selectedSpawn

    if not spawn then
      SetStatus("Select an NPC search result and a world spawn first.",true)
      return
    end

    local map=tonumber(spawn.map)
    local x=tonumber(spawn.x)
    local y=tonumber(spawn.y)
    local z=tonumber(spawn.z)
    local o=tonumber(spawn.o)

    if not map or not x or not y or not z or not o then
      SetStatus("Selected spawn has incomplete coordinates.",true)
      return
    end

    -- Use the authoritative spawn coordinates. The existing Movement
    -- backend stores the current player location before teleporting,
    -- which powers Emergency Return.
    SendCommand(string.format(CMD.movementGo,map,x,y,z,o))

    SetStatus(
      string.format(
        "Going to %s spawn %s. Emergency Return is available after a successful teleport.",
        tostring(
          Platform.NPCUI.selectedSearch
          and Platform.NPCUI.selectedSearch.name
          or "NPC"
        ),
        tostring(spawn.guid or "?")
      )
    )
  end

  Platform.NPCUI.EmergencyReturn=function()
    SendCommand(CMD.movementReturn)
  end

  Platform.NPCUI.Update()
end

local resultRows={quest={},item={}}
local function RenderResults()
  if lookup.kind=="item" and Platform.ItemUI.RenderLookupResults then Platform.ItemUI.RenderLookupResults(); return end
  local rows=resultRows[lookup.kind] or {}
  for i,row in ipairs(rows) do
    local r=lookup.results[i]
    if r then
      row.id=r.id; row.kind=lookup.kind; row.result=r
      row.label:SetText(r.link or r.title or (lookup.kind.." "..r.id))
      row:Show()
    else
      row.id=nil; row.result=nil; row.label:SetText(""); row:Hide()
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
  After(.25,function() if lookup.kind=="item" then RenderResults() end end)
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
      if self.kind=="item" and Platform.ItemUI.Select then Platform.ItemUI.Select(self.id,self.result) end
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

local function QuestChainState(entry)
  local status=tostring(entry and entry.status or "NONE"):upper()
  local eligibility=tostring(entry and entry.eligibility or "UNKNOWN"):upper()
  if status~="" and status~="NONE" and status~="UNKNOWN" then return status end
  return eligibility~="" and eligibility or "UNKNOWN"
end

local function QuestChainStateText(entry,formatted)
  local state=QuestChainState(entry)
  if not formatted then return "["..state.."]" end
  if state=="REWARDED" or state=="COMPLETE" or state=="AVAILABLE" then return "|cff55ff55["..state.."]|r" end
  if state=="ACTIVE" then return "|cffffff55[ACTIVE]|r" end
  if state=="FAILED" or state=="BLOCKED" or state=="INELIGIBLE" then return "|cffff5555["..state.."]|r" end
  return "|cffaaaaaa["..state.."]|r"
end

local function OrderedQuestChain(q)
  if not q then return {},0 end
  local previous,nextQuests={},{}
  for arrival,entry in ipairs(questUI.chain or {}) do
    entry._chainArrival=arrival
    if tostring(entry.direction or ""):upper()=="PREVIOUS" then table.insert(previous,entry) else table.insert(nextQuests,entry) end
  end
  table.sort(previous,function(a,b)
    local ad,bd=tonumber(a.depth) or 0,tonumber(b.depth) or 0
    if ad==bd then return (a._chainArrival or 0)<(b._chainArrival or 0) end
    return ad>bd
  end)
  table.sort(nextQuests,function(a,b)
    local ad,bd=tonumber(a.depth) or 0,tonumber(b.depth) or 0
    if ad==bd then return (a._chainArrival or 0)<(b._chainArrival or 0) end
    return ad<bd
  end)
  local ordered={}
  for _,entry in ipairs(previous) do table.insert(ordered,entry) end
  local selected={id=q.id,title=q.title,status=q.status,eligibility=q.eligibility,reason=q.reason,selected=true,direction="SELECTED"}
  table.insert(ordered,selected)
  local selectedIndex=#ordered
  for _,entry in ipairs(nextQuests) do table.insert(ordered,entry) end
  return ordered,selectedIndex
end

local function QuestChainLines(q,formatted,includeReasons)
  local ordered,selectedIndex=OrderedQuestChain(q)
  local lines={}
  local function heading(text) return formatted and ("|cffffd100"..text.."|r") or text end
  local rewarded,complete,active,available,blocked=0,0,0,0,0
  for _,entry in ipairs(ordered) do
    local state=QuestChainState(entry)
    if state=="REWARDED" then rewarded=rewarded+1 elseif state=="COMPLETE" then complete=complete+1 elseif state=="ACTIVE" then active=active+1 elseif state=="AVAILABLE" then available=available+1 elseif state=="BLOCKED" or state=="FAILED" or state=="INELIGIBLE" then blocked=blocked+1 end
  end
  table.insert(lines,heading(string.format("QUEST CHAIN — %d QUEST%s",#ordered,#ordered==1 and "" or "S")))
  table.insert(lines,string.format("Selected quest: %d of %d",selectedIndex,#ordered))
  table.insert(lines,string.format("Progress: %d rewarded • %d complete • %d active • %d available • %d blocked",rewarded,complete,active,available,blocked))
  table.insert(lines,"")
  for index,entry in ipairs(ordered) do
    local selected=entry.selected and (formatted and " |cffffd100[SELECTED]|r" or " [SELECTED]") or ""
    local alternative=tostring(entry.required or ""):lower()=="alternative" and (formatted and " |cffffff55[ALTERNATIVE]|r" or " [ALTERNATIVE]") or ""
    local title=entry.title or "Unknown quest"
    if formatted and entry.selected then title="|cffffd100"..title.."|r" end
    table.insert(lines,string.format("%02d. %s%s%s  %s [%s]",index,QuestChainStateText(entry,formatted),selected,alternative,title,entry.id or "?"))
    if includeReasons and entry.reason and entry.reason~="" then table.insert(lines,"    "..entry.reason) end
  end
  return lines
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

  for _,line in ipairs(QuestChainLines(q,formatted,false)) do table.insert(lines,line) end
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
      row.id=tonumber(r.id)
      row.title=r.title

      local matchLine=""

      if r.matchkind=="REQUIRED_ITEM" then
        matchLine=string.format(
          "\n|cff66ccffRequires:|r %s |cff888888[%s]|r ×%s",
          r.matchname or "Required item",
          r.matchid or "?",
          r.matchcount or "?"
        )
      end

      row.text:SetText(
        string.format(
          "|cffffd100%s|r\n"..
          "|cffaaaaaaQuest %s|r  •  %s  •  %s  •  Lv %s%s",
          r.title or "Unknown quest",
          r.id or "?",
          FactionText(r.faction),
          EligibilityText(r.eligibility),
          r.min or "?",
          matchLine
        )
      )

      row:Show()

    else
      row.id=nil
      row.title=nil
      row:Hide()
    end
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
    for _,line in ipairs(QuestChainLines(q,true,true)) do table.insert(detailLines,line) end
  else
    table.insert(detailLines,"Choose Quest or Item search mode, enter a name or exact ID, then select a result.")
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
  if type(entry)=="table" then
    return tostring(entry.query or entry.title or entry.id or "")
  end
  return tostring(entry or "")
end

questUI.HistoryMode=function(entry)
  if type(entry)=="table" and entry.mode=="ITEM" then
    return "ITEM"
  end
  return "QUEST"
end

local function PushQuestHistory(value,id,title,mode)
  value=tostring(value or ""):match("^%s*(.-)%s*$")
  if value=="" and not id then return end

  mode=(mode=="ITEM") and "ITEM" or "QUEST"

  local history=QuestHistory()
  local key=mode.."|"..tostring(id or "").."|"..value

  for i=#history,1,-1 do
    local e=history[i]

    local eMode=
      type(e)=="table" and
      ((e.mode=="ITEM") and "ITEM" or "QUEST") or
      "QUEST"

    local ekey=
      type(e)=="table" and
      (eMode.."|"..tostring(e.id or "").."|"..tostring(e.query or "")) or
      ("QUEST||"..tostring(e))

    if ekey==key then
      table.remove(history,i)
    end
  end

  table.insert(
    history,
    1,
    {
      query=value,
      id=tonumber(id),
      title=title,
      mode=mode
    }
  )

  while #history>50 do
    table.remove(history)
  end

  questUI.historyIndex=0
end

local function UpdateLockedQuestHistory()
  if not questUI.lockedQuestId then return end

  PushQuestHistory(
    questSearchBox and questSearchBox:GetText() or questUI.lockedQuestTitle,
    questUI.lockedQuestId,
    questUI.lockedQuestTitle,
    questUI.searchMode or "QUEST"
  )
end

local function ShowQuestHistory(delta)
  local history=QuestHistory()

  if #history==0 then
    SetStatus("Quest search history is empty.",true)
    return
  end

  questUI.historyIndex=math.max(
    1,
    math.min(
      #history,
      (questUI.historyIndex or 0)+delta
    )
  )

  local entry=history[questUI.historyIndex]

  questUI.searchMode=questUI.HistoryMode(entry)

  if questUI.RefreshSearchMode then
    questUI.RefreshSearchMode(false)
  end

  questSearchBox:SetText(HistoryQuery(entry))
  questSearchBox:SetFocus()
  questSearchBox:HighlightText()

  SetStatus(
    string.format(
      "Saved %s search %d of %d",
      questUI.searchMode=="ITEM" and "Item" or "Quest",
      questUI.historyIndex,
      #history
    )
  )
end

local function ShowSavedQuestHistory()
  local history=QuestHistory()
  if #history==0 then SetStatus("Quest search history is empty.",true); return end
  local lines={"AzerCore Ops saved quest searches",""}
  for i,entry in ipairs(history) do
    if type(entry)=="table" then
      local mode=questUI.HistoryMode(entry)

      table.insert(
        lines,
        string.format(
          "%02d. [%s] %s%s",
          i,
          mode,
          entry.query or entry.title or "Quest",
          entry.id and string.format("  [Quest ID: %d]",entry.id) or ""
        )
      )
    else
      table.insert(
        lines,
        string.format(
          "%02d. [QUEST] %s",
          i,
          tostring(entry)
        )
      )
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

  if raw=="" then
    if (questUI.searchMode or "QUEST")=="ITEM" then
      SetStatus("Enter a required item name or exact Item ID.",true)
    else
      SetStatus("Enter a quest title or exact Quest ID.",true)
    end
    return
  end

  PushQuestHistory(
    raw,
    nil,
    nil,
    questUI.searchMode or "QUEST"
  )

  questUI.results={}
  questUI.resultOffset=0
  questUI.info=nil
  questUI.chain={}
  questUI.selectedId=nil
  SetQuestId(nil)
  RenderQuest()

  local mode=questUI.searchMode or "QUEST"
  questUI.pendingSearchMode=mode

  if mode=="ITEM" then
    SendCommand(string.format(CMD.questSearch,"item:"..raw))
    SetStatus("Searching quests by required item...")
  else
    SendCommand(string.format(CMD.questSearch,"quest:"..raw))
    SetStatus("Searching quests by title or Quest ID...")
  end
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
  if questUI.info then for _,line in ipairs(QuestChainLines(questUI.info,false,true)) do table.insert(lines,line) end end
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
  table.insert(lines,"")
  for _,line in ipairs(QuestChainLines(q,false,true)) do table.insert(lines,line) end
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

local function CourierSplitChatText(channel,target,text)
  text=CourierNormalizeText(text):gsub("[\n]+"," | "):gsub("%s+"," ")
  -- In WoW chat, a single pipe starts a colour/link escape sequence.
  -- Courier reports use pipes as plain-text separators, so escape every pipe
  -- before placing the message in Blizzard's chat edit box.
  text=text:gsub("|","||")
  if text=="" then return nil,"Courier message is empty." end
  if channel=="WHISPER" and (not target or target=="") then return nil,"Target a player before posting a Whisper." end
  local prefix=CourierChatPrefix(channel,target)
  -- Reserve enough room for a [part/total] label. Splitting the already escaped
  -- text guarantees that a literal report pipe cannot become a chat escape.
  local limit=math.max(40,255-string.len(prefix)-12)
  local parts={}
  while string.len(text)>limit do
    local cut=limit
    local window=string.sub(text,1,limit)
    local lastSpace=window:match("^.*()%s")
    if lastSpace and lastSpace>math.floor(limit*0.55) then cut=lastSpace-1 end
    local trailing=string.match(string.sub(text,1,cut),"(|+)$") or ""
    if (string.len(trailing)%2)==1 then cut=cut-1 end
    if cut<1 then cut=limit end
    table.insert(parts,string.sub(text,1,cut):match("^%s*(.-)%s*$"))
    text=string.sub(text,cut+1):match("^%s*(.-)%s*$") or ""
  end
  if text~="" then table.insert(parts,text) end
  local total=#parts
  for index,part in ipairs(parts) do parts[index]=string.format("[%d/%d] %s",index,total,part) end
  return parts
end

local function CourierPrepareChat(channel,target,text,partIndex,partTotal)
  if not text or text=="" then SetStatus("Courier message is empty.",true); return false end
  if channel=="WHISPER" and (not target or target=="") then SetStatus("Target a player before posting a Whisper.",true); return false end
  local prefix=CourierChatPrefix(channel,target)
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

    local partStatus=(partIndex and partTotal) and string.format(" Part %d of %d is ready.",partIndex,partTotal) or ""
    SetStatus("Courier prepared for "..(channel=="WHISPER" and ("Whisper to "..target) or channel).."."..partStatus.." Press Enter in Blizzard chat to send.")
    return true
  end
  SetStatus("Could not activate the Blizzard chat input.",true)
  return false
end

EnsureShareFrame=function()
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
    local provider=f.reportProvider or CourierCurrentReportText
    local text,kind,err=provider()
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
    local parts,err=CourierSplitChatText(f.destination,target,f.message)
    if not parts then setLocal(err,true); SetStatus(err,true); return end
    f.chatParts=parts; f.chatPartIndex=1; f.chatTarget=target
    if CourierPrepareChat(f.destination,target,parts[1],1,#parts) then
      f.postPending=true
      refreshHighlights()
      setLocal(string.format("Courier part 1 of %d is ready. Press Enter in Blizzard chat; the next part will be prepared automatically.",#parts))
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
    local provider=self.reportProvider or CourierCurrentReportText
    local text,kind=provider()
    if text then applyMessage(text,kind,false) else setLocal("Waiting for the current target inspection...") end
  end
  function f:SetCapturedMessage(text,kind,provider)
    self.reportProvider=provider
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
      local parts=self.chatParts or {}
      local sent=self.chatPartIndex or 1
      if sent<#parts then
        self.chatPartIndex=sent+1
        local nextIndex=self.chatPartIndex
        setLocal(string.format("Part %d of %d sent. Preparing part %d...",sent,#parts,nextIndex))
        -- Wait until Blizzard has finished closing the chat box used for the
        -- previous part before opening and focusing the continuation.
        local continuation=CreateFrame("Frame")
        local elapsedTotal=0
        continuation:SetScript("OnUpdate",function(frame,elapsed)
          elapsedTotal=elapsedTotal+(elapsed or 0)
          if elapsedTotal<0.08 then return end
          frame:SetScript("OnUpdate",nil); frame:Hide()
          if self.postPending and self.chatParts==parts and self.chatPartIndex==nextIndex then
            if CourierPrepareChat(self.destination,self.chatTarget,parts[nextIndex],nextIndex,#parts) then
              setLocal(string.format("Part %d of %d sent. Part %d is ready; press Enter again.",sent,#parts,nextIndex))
            end
          end
        end)
      else
        self.postPending=false; self.chatParts=nil; self.chatPartIndex=nil; self.chatTarget=nil
        refreshHighlights()
        setLocal(string.format("Complete Courier sent in %d part%s. %s remains selected.",math.max(1,#parts),#parts==1 and "" or "s",self.destination=="WHISPER" and "Whisper" or self.destination))
      end
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
  f:SetCapturedMessage(text,kind,nil)
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
    local identity=ApplyPlayerTargetIdentity(questUI.targetPortrait)
    local name=identity.name
    if questUI.targetLogPlayer and questUI.targetLogPlayer~=name then
      questUI.targetLogEntries={}; questUI.targetLogLoading=false; questUI.targetLogError=nil
    end
    local level,class,guild=identity.level,identity.class,identity.guild
    questUI.targetNameText:SetText(name)
    if questUI.railTargetText then questUI.railTargetText:SetText(name) end
    questUI.targetMetaText:SetText(string.format("Level %s  %s%s",tostring(level),class,guild and ("\nGuild: "..guild) or ""))
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
    ApplyPlayerTargetIdentity(questUI.targetPortrait)
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
    text="Quest Search Help\n\nChoose Quest or Item before searching.\n\nQUEST MODE\nSearch by partial or complete quest title, or enter an exact Quest ID.\nExample: Ghoulish Effigy or 133.\n\nITEM MODE\nSearch by required objective item name, or enter an exact Item ID.\nExample: Ghoul Rib or 884.\n\nItem results show the quest that requires the item and the required quantity.\n\nSearch is not case-sensitive. Press Enter or click Search.",
    button1=OKAY,timeout=0,whileDead=1,hideOnEscape=1,preferredIndex=3,
  }

  local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-8); header:SetPoint("TOPRIGHT",-10,-8); header:SetHeight(48); Backdrop(header,C.bg)
  local title=Label(header,"Quest Inspector","GameFontNormalLarge"); title:SetPoint("TOPLEFT",12,-8)
  local subtitle=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); subtitle:SetPoint("TOPLEFT",12,-28); subtitle:SetTextColor(unpack(C.white)); subtitle:SetText("Quest intelligence and operations framework")
  questUI.workspaceHeader=header:CreateFontString(nil,"OVERLAY","GameFontNormal"); questUI.workspaceHeader:SetPoint("RIGHT",-14,0); questUI.workspaceHeader:SetTextColor(unpack(C.gold))

  local operation=CreateFrame("Frame",nil,p); operation:SetPoint("TOPLEFT",10,-64); operation:SetPoint("BOTTOMLEFT",10,10); operation:SetWidth(150); Backdrop(operation,C.panel)
  local oh=Section(operation,"OPERATIONS",C.gold); oh:SetPoint("TOP",0,-10)

  local explorer=CreateFrame("Frame",nil,p); explorer:SetPoint("TOPLEFT",168,-116); explorer:SetPoint("BOTTOMLEFT",168,10); explorer:SetWidth(218); Backdrop(explorer,C.panel)
  local eh=Section(explorer,"QUEST EXPLORER",C.resolve); eh:SetPoint("TOPLEFT",10,-10)

  local workspace=CreateFrame("Frame",nil,p); workspace:SetPoint("TOPLEFT",394,-116); workspace:SetPoint("BOTTOMRIGHT",-10,10); Backdrop(workspace,C.panel)
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
  local addQuest=Button(operation,"Add Quest",130,27,function() RunSelectedCommand(CMD.questAdd,false) end,"Add the locked quest to the current target"); addQuest:SetPoint("TOPLEFT",10,-218); Platform:RegisterRoleButton(addQuest,"GM_REQUIRED")
  local completeQuest=Button(operation,"Complete Quest",130,27,function() RunSelectedCommand(CMD.questComplete,false) end,"Force-complete the locked quest"); completeQuest:SetPoint("TOPLEFT",10,-251); Platform:RegisterRoleButton(completeQuest,"GM_REQUIRED")
  local rewardQuest=Button(operation,"Reward Quest",130,27,function() RunSelectedCommand(CMD.questReward,true) end,"Reward the locked quest"); rewardQuest:SetPoint("TOPLEFT",10,-284); Platform:RegisterRoleButton(rewardQuest,"GM_REQUIRED")
  local removeQuest=Button(operation,"Remove Quest",130,27,function() RunSelectedCommand(CMD.questRemove,true) end,"Remove the locked quest"); removeQuest:SetPoint("TOPLEFT",10,-317); Platform:RegisterRoleButton(removeQuest,"GM_REQUIRED")
  Button(operation,"Open Quest Log",130,27,OpenQuestLog,"Open the Blizzard Quest Log for the logged-in character"):SetPoint("TOPLEFT",10,-350)
  Button(operation,"Clear Workspace",130,27,ClearQuestSearch,"Clear the locked quest, results and audit data"):SetPoint("TOPLEFT",10,-383)

  local questSearchPanel=CreateFrame("Frame",nil,p)
  questSearchPanel:SetPoint("TOPLEFT",168,-64)
  questSearchPanel:SetPoint("TOPRIGHT",-10,-64)
  questSearchPanel:SetHeight(44)
  Backdrop(questSearchPanel,C.bg)

  questUI.searchMode=questUI.searchMode or "QUEST"

  local searchLabel=Section(
    questSearchPanel,
    "SEARCH",
    C.gold
  )
  searchLabel:SetPoint("LEFT",10,0)
  questUI.searchModeLabel=searchLabel

  questUI.questSearchModeButton=Button(
    questSearchPanel,
    "Quest",
    58,
    22,
    function()
      if questUI.SetSearchMode then
        questUI.SetSearchMode("QUEST")
      end
    end,
    "Search by quest title or exact Quest ID"
  )
  questUI.questSearchModeButton:SetPoint("LEFT",68,0)

  questUI.itemSearchModeButton=Button(
    questSearchPanel,
    "Item",
    52,
    22,
    function()
      if questUI.SetSearchMode then
        questUI.SetSearchMode("ITEM")
      end
    end,
    "Search quests by required item name or exact Item ID"
  )
  questUI.itemSearchModeButton:SetPoint("LEFT",130,0)

  questUI.questSearchModeButton:SetScript(
    "OnLeave",
    function()
      if questUI.RefreshSearchMode then
        questUI.RefreshSearchMode()
      end
      GameTooltip:Hide()
    end
  )

  questUI.itemSearchModeButton:SetScript(
    "OnLeave",
    function()
      if questUI.RefreshSearchMode then
        questUI.RefreshSearchMode()
      end
      GameTooltip:Hide()
    end
  )

  questSearchBox=CreateFrame(
    "EditBox",
    nil,
    questSearchPanel
  )
  questSearchBox:SetHeight(24)
  questSearchBox:SetPoint("LEFT",190,0)
  questSearchBox:SetPoint("RIGHT",-122,0)
  questSearchBox:SetAutoFocus(false)
  questSearchBox:SetMaxLetters(100)
  questSearchBox:SetFontObject(ChatFontNormal)
  questSearchBox:SetTextInsets(7,7,0,0)

  questSearchBox:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8X8",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize=10,
    insets={left=2,right=2,top=2,bottom=2}
  })

  questSearchBox:SetBackdropColor(0.035,0.04,0.05,1)
  questSearchBox:SetBackdropBorderColor(unpack(C.border))
  questSearchBox:SetTextColor(unpack(C.white))

  questSearchBox.azerCoreOpsExpected="quest"
  questSearchBox.azerCoreOpsPlain=true

  questSearchBox:SetScript(
    "OnEditFocusGained",
    function(self)
      activeInput=self
      self:SetBackdropBorderColor(unpack(C.gold))
    end
  )

  questSearchBox:SetScript(
    "OnEditFocusLost",
    function(self)
      if activeInput==self then
        activeInput=nil
      end
      self:SetBackdropBorderColor(unpack(C.border))
      self:HighlightText(0,0)
    end
  )

  local questSearchHelp=Button(
    questSearchPanel,
    "?",
    22,
    20,
    function()
      StaticPopup_Show("AZERCORE_OPS_QUEST_SEARCH_HELP")
    end,
    "Choose Quest or Item search mode"
  )
  questSearchHelp:SetPoint("RIGHT",-88,0)

  local questSearchButton=Button(
    questSearchPanel,
    "Search",
    76,
    22,
    RunQuestSearch,
    "Search using the selected Quest or Item mode"
  )
  questSearchButton:SetPoint("RIGHT",-8,0)

  questUI.RefreshSearchMode=function()
    local questSelected=(questUI.searchMode or "QUEST")=="QUEST"

    if questUI.questSearchModeButton then
      questUI.questSearchModeButton:SetBackdropColor(
        unpack(questSelected and C.selected or C.button)
      )
      questUI.questSearchModeButton:SetBackdropBorderColor(
        unpack(questSelected and C.gold or C.border)
      )
    end

    if questUI.itemSearchModeButton then
      questUI.itemSearchModeButton:SetBackdropColor(
        unpack((not questSelected) and C.selected or C.button)
      )
      questUI.itemSearchModeButton:SetBackdropBorderColor(
        unpack((not questSelected) and C.gold or C.border)
      )
    end

    if questUI.searchModeLabel then
      questUI.searchModeLabel:SetText("SEARCH")
    end
  end

  questUI.SetSearchMode=function(mode)
    mode=(mode=="ITEM") and "ITEM" or "QUEST"

    if questUI.searchMode==mode then
      if questSearchBox then
        questSearchBox:SetFocus()
      end
      return
    end

    questUI.searchMode=mode

    questUI.results={}
    questUI.resultOffset=0

    questUI.RefreshSearchMode()
    RenderQuest()

    if questSearchBox then
      questSearchBox:SetFocus()
      questSearchBox:HighlightText()
    end

    if mode=="ITEM" then
      SetStatus(
        "Item search selected — enter a required item name or exact Item ID."
      )
    else
      SetStatus(
        "Quest search selected — enter a quest title or exact Quest ID."
      )
    end
  end

  questUI.RefreshSearchMode()

  questSearchBox:SetScript(
    "OnEnterPressed",
    function(self)
      self:ClearFocus()
      RunQuestSearch()
    end
  )

  questSearchBox:SetScript(
    "OnEscapePressed",
    function(self)
      self:ClearFocus()
    end
  )

  local matches=CreateFrame("Frame",nil,explorer); matches:SetPoint("TOPLEFT",8,-36); matches:SetPoint("TOPRIGHT",-8,-36); matches:SetHeight(250); Backdrop(matches,C.bg)
  local mh=Section(matches,"QUEST MATCHES",C.gold); mh:SetPoint("TOPLEFT",8,-8)
  questUI.summary=matches:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.summary:SetPoint("TOPRIGHT",-24,-8); questUI.summary:SetTextColor(unpack(C.white))
  local function ScrollResults(delta)
    local maxOffset=math.max(0,#questUI.results-4)
    questUI.resultOffset=math.max(
      0,
      math.min(
        maxOffset,
        (questUI.resultOffset or 0)+delta
      )
    )
    RenderQuest()
  end
  Button(matches,"^",18,18,function() ScrollResults(-1) end,"Scroll results up"):SetPoint("TOPRIGHT",-4,-27)
  Button(matches,"v",18,18,function() ScrollResults(1) end,"Scroll results down"):SetPoint("BOTTOMRIGHT",-4,5)
  matches:EnableMouseWheel(true); matches:SetScript("OnMouseWheel",function(_,delta) ScrollResults(delta>0 and -1 or 1) end)
  questUI.rows={}
  for i=1,4 do
    local row=Button(
      matches,
      "",
      172,
      54,
      function(self)
        if not self.id then return end

        LockQuest(self.id,self.title)
        UpdateLockedQuestHistory()
        RequestQuestInfo(self.id)
        SetOperation("DATABASE","Quest Database")
      end
    )

    row.text=row:CreateFontString(
      nil,
      "OVERLAY",
      "GameFontHighlightSmall"
    )

    row.text:SetPoint("TOPLEFT",5,-3)
    row.text:SetPoint("BOTTOMRIGHT",-5,3)
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("TOP")
    row.text:SetWordWrap(true)

    row:SetPoint(
      "TOPLEFT",
      8,
      -28-(i-1)*56
    )

    row:Hide()
    questUI.rows[i]=row
  end

  local selected=CreateFrame("Frame",nil,explorer); selected:SetPoint("TOPLEFT",8,-294); selected:SetPoint("BOTTOMRIGHT",-8,8); Backdrop(selected,C.bg)
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
  local ui=Platform.MovementUI; AzerCoreOpsDB.movementLocations=AzerCoreOpsDB.movementLocations or {}; ui.saved=AzerCoreOpsDB.movementLocations; ui.serverCatalog=ui.serverCatalog or {}
  local builtin=(AzerCoreOpsTeleportCatalog and AzerCoreOpsTeleportCatalog.regions) or {}
  local p=NewPage("Teleport"); local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-10); header:SetPoint("TOPRIGHT",-10,-10); header:SetHeight(52); Backdrop(header,C.bg)
  local h=Label(header,"Movement Control","GameFontNormalLarge"); h:SetPoint("TOPLEFT",12,-8); local sub=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); sub:SetPoint("TOPLEFT",12,-31); sub:SetText("Named destinations, personal locations and controlled GM movement")
  local ops=CreateFrame("Frame",nil,p); ops:SetPoint("TOPLEFT",10,-70); ops:SetPoint("BOTTOMLEFT",10,36); ops:SetWidth(148); Backdrop(ops,C.panel); local ot=Section(ops,"OPERATIONS",C.gold); ot:SetPoint("TOPLEFT",10,-10)
  local function Op(text,y,fn,tip) local b=Button(ops,text,128,25,fn,tip); b:SetPoint("TOPLEFT",10,y); Platform:RegisterRoleButton(b,"GM_REQUIRED"); return b end
  Op("Teleport",-31,function() local d=ui.selected; if not d then SetStatus("Select a destination first.",true); return end; Confirm(string.format(CMD.movementGo,d.map,d.x,d.y,d.z,d.o)) end,"Teleport to the selected validated destination")
  Op("Save My Location",-64,function() ui.savePending=true; SendCommand(CMD.movementCurrent) end,"Capture the current position and give it a personal name")
  Op("Emergency Return",-97,function() Confirm(CMD.movementReturn) end,"Return to the position recorded before the last custom teleport")
  Op("GPS",-130,function() SendCommand(CMD.movementCurrent) end,"Load the current structured position")
  Op("Appear Target",-163,function() if UnitExists("target") and UnitIsPlayer("target") then Confirm(CMD.appear) else SetStatus("Select a player first.",true) end end,"Teleport to the selected player")
  Op("Summon Target",-196,function() if UnitExists("target") and UnitIsPlayer("target") then Confirm(CMD.summon) else SetStatus("Select a player first.",true) end end,"Summon the selected player")
  local body=CreateFrame("Frame",nil,p); body:SetPoint("TOPLEFT",166,-70); body:SetPoint("BOTTOMRIGHT",-10,36); Backdrop(body,C.panel)
  local identity=CreateFrame("Frame",nil,body); identity:SetPoint("TOPLEFT",8,-8); identity:SetPoint("TOPRIGHT",-8,-8); identity:SetHeight(72); Backdrop(identity,C.bg); local it=Section(identity,"SELECTED DESTINATION",C.inspect); it:SetPoint("TOPLEFT",10,-8)
  local iname=identity:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); iname:SetPoint("TOPLEFT",10,-30); iname:SetText("No destination selected"); local imeta=identity:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); imeta:SetPoint("TOPLEFT",10,-53); imeta:SetPoint("RIGHT",-8,0); ui.nameText=iname; ui.metaText=imeta
  local action=CreateFrame("Frame",nil,body); action:SetPoint("TOPLEFT",8,-88); action:SetPoint("BOTTOMLEFT",8,8); action:SetWidth(104); Backdrop(action,C.bg); local at=Section(action,"ACTION BAR",C.gold); at:SetPoint("TOPLEFT",8,-9)
  local work=CreateFrame("Frame",nil,body); work:SetPoint("TOPLEFT",120,-88); work:SetPoint("BOTTOMRIGHT",-8,8); Backdrop(work,C.bg); local wt=Section(work,"DESTINATIONS",C.inspect); wt:SetPoint("TOPLEFT",10,-10)
  local regionButton=Button(work,"Select region v",120,24,nil,"Choose a continent, instance group, battleground group, or server catalogue"); regionButton:SetPoint("TOPLEFT",10,-32)
  local zoneButton=Button(work,"Select zone v",138,24,nil,"Choose a zone or instance"); zoneButton:SetPoint("LEFT",regionButton,"RIGHT",6,0)
  local destinationButton=Button(work,"Select destination v",158,24,nil,"Choose a named destination and teleport immediately"); destinationButton:SetPoint("LEFT",zoneButton,"RIGHT",6,0); Platform:RegisterRoleButton(destinationButton,"GM_REQUIRED")
  local menu=CreateFrame("Frame",nil,work); menu:SetWidth(210); menu:SetHeight(280); menu:SetPoint("TOPLEFT",regionButton,"BOTTOMLEFT",0,-2); menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetFrameLevel(260); Backdrop(menu,C.panel); menu:Hide(); ui.menu=menu
  local text=work:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); text:SetPoint("TOPLEFT",10,-72); text:SetPoint("BOTTOMRIGHT",-10,10); text:SetJustifyH("LEFT"); text:SetJustifyV("TOP"); text:SetTextColor(unpack(C.white)); ui.text=text
  menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",regionButton,"BOTTOMLEFT",0,-2); menu:EnableMouseWheel(true)
  local menuButtons={}

  for i=1,10 do
    local b=Button(menu,"",200,22,nil)
    b:SetPoint("TOPLEFT",5,-5-(i-1)*24)
    b:SetText("")
    b:SetBackdropColor(.14,.16,.20,1)
    b:SetBackdropBorderColor(.55,.58,.65,1)

    local rowLabel=menu:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    rowLabel:SetAllPoints(b)
    rowLabel:SetJustifyH("CENTER")
    rowLabel:SetJustifyV("MIDDLE")
    rowLabel:SetTextColor(1,.82,0,1)
    rowLabel:SetShadowColor(0,0,0,1)
    rowLabel:SetShadowOffset(1,-1)
    b.menuLabel=rowLabel

    b:SetScript("OnEnter",function(self)
      self:SetBackdropColor(.18,.32,.42,1)
      self:SetBackdropBorderColor(unpack(C.gold))

      if self.menuLabel then
        self.menuLabel:SetTextColor(1,1,1,1)
      end
    end)

    b:SetScript("OnLeave",function(self)
      self:SetBackdropColor(.14,.16,.20,1)
      self:SetBackdropBorderColor(.55,.58,.65,1)

      if self.menuLabel then
        self.menuLabel:SetTextColor(1,.82,0,1)
      end

      GameTooltip:Hide()
    end)

    b:Hide()
    menuButtons[i]=b
  end

  local menuPage=menu:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  menuPage:SetPoint("BOTTOM",0,7)
  menuPage:SetTextColor(1,1,1,1)
  menuPage:SetPoint("BOTTOM",0,7)
  menuPage:SetTextColor(1,1,1,1)
  local menuEntries,menuSelect,menuOffset={},{},0
  local function RenderMenu()
    local maxOffset=math.max(0,#menuEntries-#menuButtons)
    menuOffset=math.max(0,math.min(menuOffset,maxOffset))

    for i,b in ipairs(menuButtons) do
      local entry=menuEntries[menuOffset+i]

      if entry then
        b:SetText("")
        b.menuLabel:SetText(tostring(entry.label or ""))
        b.menuLabel:SetTextColor(1,.82,0,1)

        b:SetScript("OnClick",function()
          menu:Hide()
          menuSelect(entry)
        end)

        b:Show()
      else
        b.menuLabel:SetText("")
        b:Hide()
      end
    end

    menuPage:SetText(
      #menuEntries>#menuButtons
        and string.format(
          "%d-%d of %d  •  mouse wheel",
          menuOffset+1,
          math.min(menuOffset+#menuButtons,#menuEntries),
          #menuEntries
        )
        or tostring(#menuEntries).." entries"
    )
  end
  local function ShowMenu(anchor,entries,onSelect)
    if #entries==0 then SetStatus("No entries are available for this selection.",true); return end
    menuEntries=entries; menuSelect=onSelect; menuOffset=0; menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-2); RenderMenu(); menu:Show()
  end
  menu:SetScript("OnMouseWheel",function(_,delta) if #menuEntries>#menuButtons then menuOffset=menuOffset-(delta>0 and 1 or -1); RenderMenu() end end)
  local function ServerRegion()
    local zonesByName,zoneNames={},{}
    for _,destination in ipairs(ui.serverCatalog or {}) do
      local zone=destination.category or "Instances / Other"; if not zonesByName[zone] then zonesByName[zone]={}; table.insert(zoneNames,zone) end; table.insert(zonesByName[zone],destination)
    end
    if #zoneNames==0 then return nil end
    table.sort(zoneNames); local zones={}; for _,name in ipairs(zoneNames) do table.sort(zonesByName[name],function(a,b) return a.name<b.name end); table.insert(zones,{name=name,destinations=zonesByName[name],source="AzerothCore game_tele"}) end
    return {key="SERVER",name="Server Teleports",zones=zones,source="AzerothCore game_tele"}
  end
  ui.RefreshCatalog=function()
    ui.regions={}; for _,region in ipairs(builtin) do table.insert(ui.regions,region) end; local server=ServerRegion(); if server then table.insert(ui.regions,server) end
  end
  local function ResetSelectors()
    ui.selectedRegion=nil; ui.selectedZone=nil; ui.selected=nil; regionButton:SetText(ui.view=="MY_LOCATIONS" and "My Locations" or "Select region v"); zoneButton:SetText(ui.view=="MY_LOCATIONS" and "Personal" or "Select zone v"); destinationButton:SetText("Select destination v")
  end
  regionButton:SetScript("OnClick",function()
    if ui.view=="MY_LOCATIONS" then SetStatus("Personal locations are already selected."); return end
    local entries={}; for _,region in ipairs(ui.regions or {}) do table.insert(entries,{label=region.name,data=region}) end
    ShowMenu(regionButton,entries,function(e) ui.selectedRegion=e.data; ui.selectedZone=nil; ui.selected=nil; regionButton:SetText(e.label.." v"); zoneButton:SetText("Select zone v"); destinationButton:SetText("Select destination v"); ui.Render() end)
  end)
  zoneButton:SetScript("OnClick",function()
    if ui.view=="MY_LOCATIONS" then SetStatus("Personal locations use the saved zone."); return end
    if not ui.selectedRegion then SetStatus("Select a region first.",true); return end
    local entries={}; for _,zone in ipairs(ui.selectedRegion.zones or {}) do table.insert(entries,{label=zone.name,data=zone}) end
    ShowMenu(zoneButton,entries,function(e) ui.selectedZone=e.data; ui.selected=nil; zoneButton:SetText(e.label.." v"); destinationButton:SetText("Select destination v"); ui.Render() end)
  end)
  local function TeleportToSelectedDestination()
    local d=ui.selected

    if not d then
      SetStatus("Select a destination first.",true)
      return
    end

    local map=tonumber(d.map)
    local x=tonumber(d.x)
    local y=tonumber(d.y)
    local z=tonumber(d.z)
    local o=tonumber(d.o) or 0

    if not map or not x or not y or not z then
      SetStatus("Selected destination has incomplete coordinates.",true)
      return
    end

    SendCommand(string.format(CMD.movementGo,map,x,y,z,o))

    SetStatus(
      "Teleporting to "..tostring(d.name or "selected destination")..
      ". Emergency Return is available after a successful teleport."
    )
  end

  destinationButton:SetScript("OnClick",function()
    local entries={}

    if ui.view=="MY_LOCATIONS" then
      for _,destination in ipairs(ui.saved or {}) do
        table.insert(entries,{label=destination.name,data=destination})
      end
    elseif ui.selectedZone then
      for _,destination in ipairs(ui.selectedZone.destinations or {}) do
        table.insert(entries,{label=destination.name,data=destination})
      end
    else
      SetStatus("Select a region and zone first.",true)
      return
    end

    ShowMenu(destinationButton,entries,function(e)
      local destination=e.data

      ui.selected={
        id=destination.id,
        name=destination.name,
        map=tonumber(destination.map),
        x=tonumber(destination.x),
        y=tonumber(destination.y),
        z=tonumber(destination.z),
        o=tonumber(destination.o) or 0,
        region=ui.selectedRegion
          and ui.selectedRegion.name
          or destination.region
          or "My Locations",
        zone=ui.selectedZone
          and ui.selectedZone.name
          or destination.zone
          or "Personal",
        source=destination.source
          or (ui.selectedRegion and ui.selectedRegion.source)
          or "AzerothAdmin"
      }

      destinationButton:SetText(e.label.." v")
      ui.Render()
      TeleportToSelectedDestination()
    end)
  end)
  StaticPopupDialogs["AZERCORE_OPS_SAVE_LOCATION"]={text="Save current location\nDetected zone: %s\n\nEnter a personal name:",button1=SAVE,button2=CANCEL,hasEditBox=1,maxLetters=60,timeout=0,whileDead=1,hideOnEscape=1,OnShow=function(self) self.editBox:SetText((GetSubZoneText and GetSubZoneText()~="" and GetSubZoneText()) or (GetZoneText and GetZoneText()) or "Saved Location"); self.editBox:HighlightText() end,OnAccept=function(self) local c=ui.current; local name=self.editBox:GetText(); if c and name and name~="" then local saved={name=name,category="My Locations",region="My Locations",map=tonumber(c.map),x=tonumber(c.x),y=tonumber(c.y),z=tonumber(c.z),o=tonumber(c.o),zone=(GetZoneText and GetZoneText()) or tostring(c.zone or "Personal"),area=c.area,source="Personal location"}; table.insert(ui.saved,saved); ui.view="MY_LOCATIONS"; ui.selected=saved; regionButton:SetText("My Locations"); zoneButton:SetText(saved.zone or "Personal"); destinationButton:SetText(name.." v"); ui.Render(); SetStatus("Saved personal location "..name) end end}
  ui.Report=function() local d=ui.selected; return d and string.format("AZERCORE OPS — MOVEMENT\n%s\n%s → %s\nMap %s\nCoordinates %.3f, %.3f, %.3f\nOrientation %.3f\nSource: %s",d.name,d.region or "Unknown region",d.zone or "Unknown zone",d.map,d.x,d.y,d.z,d.o,d.source or "Unknown") or "AZERCORE OPS — MOVEMENT\nNo destination selected." end
  ui.Render=function() wt:SetText(ui.view=="MY_LOCATIONS" and "MY LOCATIONS" or ui.view=="SHARING" and "LOCATION SHARING — DISABLED" or "DESTINATIONS"); local d=ui.selected; iname:SetText(d and d.name or "No destination selected"); imeta:SetText(d and string.format("%s → %s • Map %s • %.2f, %.2f, %.2f",d.region or "Unknown",d.zone or "Unknown",d.map,d.x,d.y,d.z) or "Choose a region, zone and destination."); if ui.view=="SHARING" then text:SetText("Location sharing is disabled in this release.\n\nThe addon and module will not send, receive, publish or group-teleport shared coordinates.") elseif d then text:SetText(ui.Report()) else local count=AzerCoreOpsTeleportCatalog and AzerCoreOpsTeleportCatalog.metadata and AzerCoreOpsTeleportCatalog.metadata.count or 0; text:SetText(string.format("Select a region, then a zone, then a destination.\n\n%d validated built-in destinations are ready.%s\n\nPersonal locations are stored per character. The module records an emergency return point before every custom teleport.",count,ui.loading and " Server teleports are still loading." or "")) end end
  local views={{"Destinations","DESTINATIONS"},{"My Locations","MY_LOCATIONS"},{"Player","PLAYER"},{"Current","CURRENT"},{"History","HISTORY"},{"Sharing","SHARING"}}; for i,d in ipairs(views) do local label,key=d[1],d[2]; local b=Button(action,label,88,22,function() ui.view=key; ResetSelectors(); ui.Render() end); b:SetPoint("TOPLEFT",8,-29-(i-1)*27) end
  Button(action,"Copy",88,22,function() ShowSelectableReport("Copy Movement report",ui.Report()) end):SetPoint("BOTTOMLEFT",8,61); Button(action,"Share",88,22,function() SetStatus("Location sharing is disabled in this release.",true) end):SetPoint("BOTTOMLEFT",8,34); Button(action,"Export",88,22,function() ShowSelectableReport("Export Movement report",ui.Report()) end):SetPoint("BOTTOMLEFT",8,7)
  ui.OnCurrent=function(f) ui.current=f; if ui.savePending then ui.savePending=false; StaticPopup_Show("AZERCORE_OPS_SAVE_LOCATION",tostring(f.zone or "Unknown")) else ui.view="CURRENT"; ui.selected={name="Current Location",region="Current",zone="Zone "..tostring(f.zone or "Unknown"),source="AzerothCore",map=tonumber(f.map),x=tonumber(f.x),y=tonumber(f.y),z=tonumber(f.z),o=tonumber(f.o)}; ui.Render() end end
  ui.RefreshCatalog(); ui.loading=true; SendCommand(CMD.movementCatalog); ui.Render()
end

local function BuildItem()
  local itemUI=Platform.ItemUI
  local p=NewPage("Item")
  local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-10); header:SetPoint("TOPRIGHT",-10,-10); header:SetHeight(52); Backdrop(header,C.bg)
  local h=Label(header,"Item Inspector","GameFontNormalLarge"); h:SetPoint("TOPLEFT",12,-8)
  local sub=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); sub:SetPoint("TOPLEFT",12,-31); sub:SetText("Item search, wearable preview, properties and controlled inventory operations")

  local searchPanel=CreateFrame("Frame",nil,p)
  searchPanel:SetPoint("TOPLEFT",10,-70)
  searchPanel:SetPoint("TOPRIGHT",-10,-70)
  searchPanel:SetHeight(44)
  Backdrop(searchPanel,C.bg)

  local searchTitle=Section(searchPanel,"ITEM SEARCH",C.gold)
  searchTitle:SetPoint("LEFT",10,0)

  local titleBox=Edit(searchPanel,100,false)
  titleBox:ClearAllPoints()
  titleBox:SetPoint("LEFT",105,0)
  titleBox:SetPoint("RIGHT",-178,0)
  titleBox:SetMaxLetters(80)
  titleBox.azerCoreOpsExpected="item"
  titleBox.azerCoreOpsPlain=true

  local function SearchItem()
    local s=NonEmpty(titleBox,"an item name or ID")
    if not s then return end

    local directId=tonumber(s)

    if directId and directId>0 then
      itemIdBox:SetText(directId)
      itemUI.Select(directId)
      SetStatus("Inspecting item ID "..directId)
    else
      itemIdBox:SetText("")
      itemUI.selected=nil
      itemUI.view="OVERVIEW"
      itemUI.Render()
      BeginLookup("item",string.format(CMD.itemLookup,s))
    end
  end

  local lookupButton=Button(
    searchPanel,
    "Search",
    76,
    22,
    SearchItem,
    "Search by item name or inspect an exact item ID"
  )
  lookupButton:SetPoint("RIGHT",-92,0)

  local clearButton=Button(
    searchPanel,
    "Clear",
    76,
    22,
    function() if itemUI.Clear then itemUI.Clear() end end,
    "Clear the item search and selected item"
  )
  clearButton:SetPoint("RIGHT",-10,0)

  titleBox:SetScript("OnEnterPressed",function(self)
    self:ClearFocus()
    SearchItem()
  end)

  titleBox:SetScript("OnEscapePressed",function(self)
    self:ClearFocus()
  end)

  local operations=CreateFrame("Frame",nil,p)
  operations:SetPoint("TOPLEFT",10,-122)
  operations:SetPoint("BOTTOMLEFT",10,36)
  operations:SetWidth(148)
  Backdrop(operations,C.panel)

  local opTitle=Section(operations,"OPERATIONS",C.gold)
  opTitle:SetPoint("TOPLEFT",10,-10)

  local idLabel=Section(operations,"ITEM ID",C.gold)
  idLabel:SetPoint("TOPLEFT",10,-34)
  itemIdBox=Edit(operations,76,true)
  itemIdBox:SetPoint("TOPLEFT",10,-51)
  itemIdBox.azerCoreOpsExpected="item"

  local quantityLabel=Section(operations,"QTY",C.gold)
  quantityLabel:SetPoint("TOPLEFT",94,-34)
  local count=Edit(operations,44,true)
  count:SetPoint("TOPLEFT",94,-51)
  count:SetText("1")

  local function RefreshItemAfterMutation(id)
    id=tonumber(id)
    if not id then return end

    After(.5,function()
      local selected=itemUI.selected
      if not selected or selected.id~=id or not itemUI.Select then return end

      local activeView=itemUI.view
      itemUI.Select(id,{title=selected.name,link=selected.link},0)
      itemUI.view=activeView
      itemUI.Render()
    end)
  end

  local addItem=Button(operations,"Add Item",128,24,function()
    local id=PositiveId(itemIdBox,"item"); local n=PositiveId(count,"quantity")
    if id and n then
      SendCommand(string.format(CMD.itemAdd,id,n))
      RefreshItemAfterMutation(id)
    end
  end,"Add the selected quantity to your inventory"); addItem:SetPoint("TOPLEFT",10,-82); Platform:RegisterRoleButton(addItem,"GM_REQUIRED")

  local removeItem=Button(operations,"Remove Item",128,24,function()
    local id=PositiveId(itemIdBox,"item"); local n=PositiveId(count,"quantity")
    if id and n then
      Confirm(string.format(CMD.itemRemove,id,n),nil,function() RefreshItemAfterMutation(id) end)
    end
  end,"Remove the selected quantity from your inventory"); removeItem:SetPoint("TOPLEFT",10,-113); Platform:RegisterRoleButton(removeItem,"GM_REQUIRED")

  local body=CreateFrame("Frame",nil,p); body:SetPoint("TOPLEFT",166,-122); body:SetPoint("BOTTOMRIGHT",-10,36); Backdrop(body,C.panel)
  local identity=CreateFrame("Frame",nil,body); identity:SetPoint("TOPLEFT",8,-8); identity:SetPoint("TOPRIGHT",-8,-8); identity:SetHeight(82); Backdrop(identity,C.bg)
  local identityTitle=Section(identity,"SELECTED ITEM",C.inspect); identityTitle:SetPoint("TOPLEFT",10,-8)
  local iconFrame=CreateFrame("Frame",nil,identity); iconFrame:SetPoint("TOPLEFT",10,-27); iconFrame:SetWidth(44); iconFrame:SetHeight(44); Backdrop(iconFrame,C.panel)
  local icon=iconFrame:CreateTexture(nil,"ARTWORK"); icon:SetPoint("TOPLEFT",3,-3); icon:SetPoint("BOTTOMRIGHT",-3,3); icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); itemUI.icon=icon
  local selectedName=identity:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); selectedName:SetPoint("TOPLEFT",65,-31); selectedName:SetTextColor(unpack(C.white)); selectedName:SetText("No item selected"); itemUI.nameText=selectedName
  local selectedMeta=identity:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); selectedMeta:SetPoint("TOPLEFT",65,-54); selectedMeta:SetPoint("RIGHT",-8,0); selectedMeta:SetJustifyH("LEFT"); selectedMeta:SetText("Search for an item or enter an item ID."); itemUI.metaText=selectedMeta

  local action=CreateFrame("Frame",nil,body); action:SetPoint("TOPLEFT",8,-98); action:SetPoint("BOTTOMLEFT",8,8); action:SetWidth(104); Backdrop(action,C.bg)
  local actionTitle=Section(action,"ACTION BAR",C.gold); actionTitle:SetPoint("TOPLEFT",8,-9)
  local workspace=CreateFrame("Frame",nil,body); workspace:SetPoint("TOPLEFT",120,-98); workspace:SetPoint("BOTTOMRIGHT",-8,8); Backdrop(workspace,C.bg)
  local workspaceTitle=Section(workspace,"ITEM LOOKUP",C.inspect); workspaceTitle:SetPoint("TOPLEFT",10,-10); itemUI.workspaceTitle=workspaceTitle

  local reportScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_ItemScroll",workspace,"UIPanelScrollFrameTemplate"); reportScroll:SetPoint("TOPLEFT",8,-31); reportScroll:SetPoint("BOTTOMRIGHT",-29,8)
  local reportChild=CreateFrame("Frame",nil,reportScroll); reportChild:SetWidth(380); reportChild:SetHeight(380); reportScroll:SetScrollChild(reportChild)
  local reportText=reportChild:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); reportText:SetPoint("TOPLEFT",4,-4); reportText:SetWidth(360); reportText:SetJustifyH("LEFT"); reportText:SetJustifyV("TOP"); reportText:SetTextColor(unpack(C.white)); itemUI.reportText=reportText

  local resultsTitle=Section(reportChild,"LOOKUP RESULTS — CLICK AN ITEM TO INSPECT IT",C.gold); resultsTitle:SetPoint("TOPLEFT",4,-4); itemUI.resultsTitle=resultsTitle
  for i=1,5 do
    local row=Button(reportChild,"",355,42,function(self) if self.id then itemIdBox:SetText(self.id); itemUI.Select(self.id,self.result) end end,"Select this item and open its preview")
    local rowIcon=row:CreateTexture(nil,"ARTWORK"); rowIcon:SetPoint("LEFT",5,0); rowIcon:SetWidth(32); rowIcon:SetHeight(32); rowIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); row.icon=rowIcon
    local rowLabel=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); rowLabel:SetPoint("TOPLEFT",44,-6); rowLabel:SetPoint("RIGHT",-7,0); rowLabel:SetJustifyH("LEFT"); rowLabel:SetWordWrap(false); row.label=rowLabel
    local rowMeta=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); rowMeta:SetPoint("BOTTOMLEFT",44,6); rowMeta:SetPoint("RIGHT",-7,0); rowMeta:SetJustifyH("LEFT"); rowMeta:SetWordWrap(false); row.meta=rowMeta
    row:SetPoint("TOPLEFT",4,-25-(i-1)*46); row:Hide(); resultRows.item[i]=row
  end

  local previewFrame=CreateFrame("Frame",nil,workspace); previewFrame:SetPoint("TOPLEFT",8,-31); previewFrame:SetPoint("BOTTOMRIGHT",-8,8); previewFrame:Hide(); itemUI.previewFrame=previewFrame
  local model=CreateFrame("DressUpModel",nil,previewFrame); model:SetPoint("TOPLEFT",4,-4); model:SetPoint("BOTTOMRIGHT",-4,4); itemUI.model=model; model.azerFacing=0
  local fallback=CreateFrame("Frame",nil,previewFrame); fallback:SetPoint("CENTER"); fallback:SetWidth(180); fallback:SetHeight(210); fallback:Hide(); itemUI.fallback=fallback
  local fallbackIcon=fallback:CreateTexture(nil,"ARTWORK"); fallbackIcon:SetPoint("TOP",0,-12); fallbackIcon:SetWidth(128); fallbackIcon:SetHeight(128); fallbackIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); itemUI.fallbackIcon=fallbackIcon
  local fallbackText=fallback:CreateFontString(nil,"OVERLAY","GameFontHighlight"); fallbackText:SetPoint("TOP",fallbackIcon,"BOTTOM",0,-12); fallbackText:SetWidth(180); fallbackText:SetJustifyH("CENTER"); fallbackText:SetText("No wearable 3D preview"); itemUI.fallbackText=fallbackText
  Button(previewFrame,"<",26,21,function() model.azerFacing=model.azerFacing-.25; if model.SetFacing then model:SetFacing(model.azerFacing) end end,"Rotate preview left"):SetPoint("TOPLEFT",8,-8)
  Button(previewFrame,">",26,21,function() model.azerFacing=model.azerFacing+.25; if model.SetFacing then model:SetFacing(model.azerFacing) end end,"Rotate preview right"):SetPoint("TOPRIGHT",-8,-8)
  Button(previewFrame,"Reset",50,21,function() if itemUI.RefreshPreview then itemUI.RefreshPreview() end end,"Reset the wearable item preview"):SetPoint("BOTTOM",0,7)
  itemUI.UpdatePreviewCamera=function()
    -- DressUpModel keeps a camera distance in physical pixels while its parent
    -- inherits the addon scale. Compensate so the model remains framed at every
    -- supported window scale instead of clipping at larger values.
    local windowScale=math.max(.75,math.min(1.35,Settings().scale or 1))
    if model.SetCamDistanceScale then model:SetCamDistanceScale(windowScale) end
    if model.SetFacing then model:SetFacing(model.azerFacing or 0) end
  end
  previewFrame:SetScript("OnSizeChanged",function() After(0,function() if itemUI.UpdatePreviewCamera then itemUI.UpdatePreviewCamera() end end) end)

  local function ItemLink(item)
    return Platform.NativeItemLink(item)
  end

  local function QuestLink(id,name)
    if GetQuestLink then local link=GetQuestLink(tonumber(id)); if link then return link end end
    return string.format("|cffffff00|Hquest:%d:0|h[%s]|h|r",tonumber(id) or 0,name or ("Quest "..tostring(id)))
  end
  local function EnsureItemLinkRows(count)
    for i=#itemUI.linkRows+1,count do
      local row=Button(reportChild,"",355,24,function(self) if IsShiftKeyDown() and self.link then Platform.InsertItemLink(self.link) end end,"Shift-click linked entries to insert them into chat")
      local rowLabel=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); rowLabel:SetJustifyH("LEFT"); rowLabel:SetJustifyV("TOP"); rowLabel:SetWordWrap(false); row:SetFontString(rowLabel); row.label=rowLabel
      local rowDetail=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); rowDetail:SetJustifyH("LEFT"); rowDetail:SetJustifyV("TOP"); rowDetail:SetWordWrap(true); rowDetail:SetTextColor(unpack(C.muted)); rowDetail:Hide(); row.detail=rowDetail
      row:SetPoint("TOPLEFT",4,-4-(i-1)*27); row:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover)); if self.link then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.link); GameTooltip:Show() end end); row:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(C.button)); GameTooltip:Hide() end); row:Hide(); itemUI.linkRows[i]=row
    end
  end
  iconFrame:EnableMouse(true)
  iconFrame:SetScript("OnEnter",function() local link=ItemLink(itemUI.selected); if link then GameTooltip:SetOwner(iconFrame,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink(link); GameTooltip:Show() end end)
  iconFrame:SetScript("OnLeave",function() GameTooltip:Hide() end)
  iconFrame:SetScript("OnMouseUp",function(_,button)
    local link=ItemLink(itemUI.selected)
    if button=="LeftButton" and IsShiftKeyDown() and link then
      Platform.InsertItemLink(link)
    end
  end)

  local equipNames={INVTYPE_HEAD="Head",INVTYPE_NECK="Neck",INVTYPE_SHOULDER="Shoulders",INVTYPE_BODY="Shirt",INVTYPE_CHEST="Chest",INVTYPE_ROBE="Robe",INVTYPE_WAIST="Waist",INVTYPE_LEGS="Legs",INVTYPE_FEET="Feet",INVTYPE_WRIST="Wrist",INVTYPE_HAND="Hands",INVTYPE_FINGER="Finger",INVTYPE_TRINKET="Trinket",INVTYPE_CLOAK="Back",INVTYPE_WEAPON="One-hand weapon",INVTYPE_SHIELD="Shield",INVTYPE_2HWEAPON="Two-hand weapon",INVTYPE_WEAPONMAINHAND="Main-hand weapon",INVTYPE_WEAPONOFFHAND="Off-hand weapon",INVTYPE_HOLDABLE="Held in off-hand",INVTYPE_RANGED="Ranged",INVTYPE_THROWN="Thrown",INVTYPE_RANGEDRIGHT="Ranged",INVTYPE_TABARD="Tabard",INVTYPE_BAG="Bag"}
  local visibleEquipLocs={INVTYPE_HEAD=true,INVTYPE_SHOULDER=true,INVTYPE_BODY=true,INVTYPE_CHEST=true,INVTYPE_ROBE=true,INVTYPE_WAIST=true,INVTYPE_LEGS=true,INVTYPE_FEET=true,INVTYPE_WRIST=true,INVTYPE_HAND=true,INVTYPE_CLOAK=true,INVTYPE_WEAPON=true,INVTYPE_SHIELD=true,INVTYPE_2HWEAPON=true,INVTYPE_WEAPONMAINHAND=true,INVTYPE_WEAPONOFFHAND=true,INVTYPE_HOLDABLE=true,INVTYPE_RANGED=true,INVTYPE_THROWN=true,INVTYPE_RANGEDRIGHT=true,INVTYPE_TABARD=true}
  local invisibleEquipLocs={INVTYPE_NECK=true,INVTYPE_FINGER=true,INVTYPE_TRINKET=true,INVTYPE_RELIC=true,INVTYPE_AMMO=true,INVTYPE_BAG=true,INVTYPE_QUIVER=true}
  local scanTooltip=CreateFrame("GameTooltip","AZERCORE_OPS_ItemScanTooltip",UIParent,"GameTooltipTemplate"); scanTooltip:SetOwner(UIParent,"ANCHOR_NONE"); scanTooltip:Hide()
  local function ColorCode(fontString)
    if not fontString or not fontString.GetTextColor then return "ffffffff" end
    local r,g,b=fontString:GetTextColor(); return string.format("ff%02x%02x%02x",math.floor((r or 1)*255+.5),math.floor((g or 1)*255+.5),math.floor((b or 1)*255+.5))
  end
  local function TooltipLines(item)
    local link=ItemLink(item); if not link then return nil end
    scanTooltip:SetOwner(UIParent,"ANCHOR_NONE"); scanTooltip:ClearLines(); scanTooltip:SetHyperlink(link)
    local lines={}
    for i=1,scanTooltip:NumLines() do
      local left=_G["AZERCORE_OPS_ItemScanTooltipTextLeft"..i]; local right=_G["AZERCORE_OPS_ItemScanTooltipTextRight"..i]
      local leftText=left and left:GetText(); local rightText=right and right:GetText()
      if (leftText and leftText~="") or (rightText and rightText~="") then table.insert(lines,{left=leftText,right=rightText,leftColor=ColorCode(left),rightColor=ColorCode(right)}) end
    end
    scanTooltip:Hide()
    return #lines>0 and lines or nil
  end
  local function ColoredTooltipReport(item)
    local tooltipLines=TooltipLines(item); if not tooltipLines then return nil end
    local lines={}
    for _,entry in ipairs(tooltipLines) do
      local line=entry.left and ("|c"..entry.leftColor..entry.left.."|r") or ""
      if entry.right and entry.right~="" then line=line.."    |c"..entry.rightColor..entry.right.."|r" end
      table.insert(lines,line)
    end
    table.insert(lines,""); table.insert(lines,"|cff888888Shift-click the selected-item icon to insert its item link into chat.|r")
    return table.concat(lines,"\n")
  end
  local statNames={RESISTANCE0_NAME="Armor",RESISTANCE1_NAME="Holy Resistance",RESISTANCE2_NAME="Fire Resistance",RESISTANCE3_NAME="Nature Resistance",RESISTANCE4_NAME="Frost Resistance",RESISTANCE5_NAME="Shadow Resistance",RESISTANCE6_NAME="Arcane Resistance",ITEM_MOD_STRENGTH_SHORT="Strength",ITEM_MOD_AGILITY_SHORT="Agility",ITEM_MOD_STAMINA_SHORT="Stamina",ITEM_MOD_INTELLECT_SHORT="Intellect",ITEM_MOD_SPIRIT_SHORT="Spirit",ITEM_MOD_HIT_RATING_SHORT="Hit Rating",ITEM_MOD_CRIT_RATING_SHORT="Critical Strike Rating",ITEM_MOD_HASTE_RATING_SHORT="Haste Rating",ITEM_MOD_ATTACK_POWER_SHORT="Attack Power",ITEM_MOD_RANGED_ATTACK_POWER_SHORT="Ranged Attack Power",ITEM_MOD_SPELL_POWER_SHORT="Spell Power",ITEM_MOD_MANA_REGENERATION_SHORT="Mana per 5 sec",ITEM_MOD_EXPERTISE_RATING_SHORT="Expertise Rating",ITEM_MOD_DODGE_RATING_SHORT="Dodge Rating",ITEM_MOD_PARRY_RATING_SHORT="Parry Rating",ITEM_MOD_BLOCK_RATING_SHORT="Block Rating",ITEM_MOD_RESILIENCE_RATING_SHORT="Resilience Rating",EMPTY_SOCKET_RED="Red Socket",EMPTY_SOCKET_YELLOW="Yellow Socket",EMPTY_SOCKET_BLUE="Blue Socket",EMPTY_SOCKET_META="Meta Socket"}
  local statOrder={"ITEM_MOD_STRENGTH_SHORT","ITEM_MOD_AGILITY_SHORT","ITEM_MOD_STAMINA_SHORT","ITEM_MOD_INTELLECT_SHORT","ITEM_MOD_SPIRIT_SHORT","ITEM_MOD_ATTACK_POWER_SHORT","ITEM_MOD_RANGED_ATTACK_POWER_SHORT","ITEM_MOD_SPELL_POWER_SHORT","ITEM_MOD_HIT_RATING_SHORT","ITEM_MOD_CRIT_RATING_SHORT","ITEM_MOD_HASTE_RATING_SHORT","ITEM_MOD_EXPERTISE_RATING_SHORT","ITEM_MOD_DODGE_RATING_SHORT","ITEM_MOD_PARRY_RATING_SHORT","ITEM_MOD_BLOCK_RATING_SHORT","ITEM_MOD_RESILIENCE_RATING_SHORT","ITEM_MOD_MANA_REGENERATION_SHORT","EMPTY_SOCKET_META","EMPTY_SOCKET_RED","EMPTY_SOCKET_YELLOW","EMPTY_SOCKET_BLUE"}
  local function ColoredStatsReport(item)
    local stats=GetItemStats and GetItemStats(ItemLink(item)); if not stats then return "|cffaaaaaaNo numeric item stats are available from the client cache.|r" end
    local lines={"|cffffd100ITEM STATS|r",""}; local used={}
    for _,key in ipairs(statOrder) do
      local value=stats[key]
      if value then
        local socket=key:find("EMPTY_SOCKET",1,true); local label=statNames[key] or key
        table.insert(lines,string.format("%s%s|r  %s%s|r",socket and "|cffffcc00" or "|cff00ccff",label,socket and "|cffffcc00" or "|cff55ff55",socket and ("× "..value) or ("+"..value))); used[key]=true
      end
    end
    local extras={}; for key,value in pairs(stats) do if not used[key] then table.insert(extras,{key=key,value=value}) end end; table.sort(extras,function(a,b) return a.key<b.key end)
    for _,entry in ipairs(extras) do table.insert(lines,string.format("|cff00ccff%s|r  |cff55ff55+%s|r",statNames[entry.key] or entry.key:gsub("^ITEM_MOD_",""):gsub("_SHORT$",""):gsub("_"," "),entry.value)) end
    return table.concat(lines,"\n")
  end
  local function ColoredRequirementsReport(item)
    local lines={"|cffffd100ITEM REQUIREMENTS|r",""}
    local level=tonumber(item.minLevel) or 0; local playerLevel=UnitLevel("player") or 0
    table.insert(lines,string.format("|cff00ccffMinimum Level:|r  %s%d|r",playerLevel>=level and "|cff55ff55" or "|cffff5555",level))
    table.insert(lines,"|cff00ccffType:|r  |cffffffff"..tostring(item.itemType or "Unknown").."|r")
    table.insert(lines,"|cff00ccffSubtype:|r  |cffffffff"..tostring(item.subType or "Unknown").."|r")
    table.insert(lines,"|cff00ccffEquipment Slot:|r  |cffffffff"..tostring(equipNames[item.equipLoc] or "Not equippable").."|r")
    local found={}
    for _,entry in ipairs(TooltipLines(item) or {}) do
      local text=entry.left
      if text and (text:find("^Requires ") or text:find("^Classes:") or text:find("^Races:") or text:find("^Unique") or text:find("^You may only") or text:find("Only$") or text:find("^Only usable")) and text~=((ITEM_MIN_LEVEL or "Requires Level %d"):format(level)) then
        local red=entry.leftColor and tonumber(entry.leftColor:sub(3,4),16)>180 and tonumber(entry.leftColor:sub(5,6),16)<120
        local color=text:find("^Unique") and "ffffaa00" or (red and "ffff5555" or "ff55ff55")
        if not found[text] then table.insert(lines,"|c"..color..text.."|r"); found[text]=true end
      end
    end
    local access=itemUI.server and itemUI.server.access
    if access then
      table.insert(lines,"")
      local factionColor=access.faction=="Alliance" and "ff3399ff" or (access.faction=="Horde" and "ffff5555" or "ff55ff55")
      table.insert(lines,"|cff00ccffFaction:|r  |c"..factionColor..tostring(access.faction or "Both").."|r")
      table.insert(lines,"|cff00ccffRaces:|r  |cffffffff"..tostring(access.races or "Unknown").."|r")
      table.insert(lines,"|cff00ccffClasses:|r  |cffffffff"..tostring(access.classes or "Unknown").."|r")
      local allowed=tonumber(access.usable)==1
      table.insert(lines,string.format("|cff00ccffUsable by %s:|r  %s%s|r",UnitName("player") or "this character",allowed and "|cff55ff55" or "|cffff5555",allowed and "Yes" or "No"))
      if access.reason and access.reason~="" then table.insert(lines,"|cffaaaaaa"..access.reason.."|r") end
      local requirements=itemUI.server and itemUI.server.requirements or {}
      local extra=false
      for _,requirement in ipairs(requirements) do
        if requirement.kind~="FACTION_RACE" and requirement.kind~="CLASS" and not tostring(requirement.kind or ""):find("^ACQUISITION_") then
          if not extra then table.insert(lines,""); table.insert(lines,"|cffffd100CHARACTER CHECKS|r"); extra=true end
          if requirement.kind=="LEGACY_HONOR" then
            table.insert(lines,string.format("|cffffaa00%s:|r  |cffffffffRequired %s|r  |cffffaa00(%s)|r",tostring(requirement.name or "Legacy honor rank"),tostring(requirement.required or "?"),tostring(requirement.current or "Informational")))
            if requirement.detail and requirement.detail~="" then table.insert(lines,"  |cff888888"..requirement.detail.."|r") end
          else
            local passed=tonumber(requirement.passed)==1
            table.insert(lines,string.format("%s%s:|r  |cffffffffRequired %s|r  |cffaaaaaa(Current: %s)|r",passed and "|cff55ff55" or "|cffff5555",tostring(requirement.name or requirement.kind or "Requirement"),tostring(requirement.required or "?"),tostring(requirement.current or "?")))
            if not passed and requirement.detail and requirement.detail~="" then table.insert(lines,"  |cffff5555"..requirement.detail.."|r") end
          end
        end
      end
      local generalAcquisition={}; local paths={}; local pathOrder={}
      for _,requirement in ipairs(requirements) do
        if tostring(requirement.kind or ""):find("^ACQUISITION_") then
          local pathId=tonumber(requirement.pathid) or 0
          if pathId>0 then
            if not paths[pathId] then paths[pathId]={name=requirement.pathname or ("Quest "..pathId),requirements={}}; table.insert(pathOrder,pathId) end
            table.insert(paths[pathId].requirements,requirement)
          else table.insert(generalAcquisition,requirement) end
        end
      end
      local function AddAcquisitionLine(requirement,prefix)
        local passed=tonumber(requirement.passed)==1
        table.insert(lines,string.format("  %s%s%s:|r  |cffffffffRequired %s|r  |cffaaaaaa(Current: %s)|r",passed and "|cff55ff55" or "|cffffaa00",prefix or "",tostring(requirement.name or "Requirement"),tostring(requirement.required or "?"),tostring(requirement.current or "?")))
        if requirement.detail and requirement.detail~="" then table.insert(lines,"    |cff888888"..requirement.detail.."|r") end
      end
      if #generalAcquisition>0 then
        table.insert(lines,""); table.insert(lines,"|cffffd100GENERAL ACQUISITION LIMITS|r")
        for _,requirement in ipairs(generalAcquisition) do AddAcquisitionLine(requirement) end
      end
      if #pathOrder>0 then
        table.sort(pathOrder)
        table.insert(lines,""); table.insert(lines,"|cffffd100ALTERNATIVE ACQUISITION PATHS — COMPLETE ONE|r")
        for index,pathId in ipairs(pathOrder) do
          local path=paths[pathId]; table.insert(lines,string.format("|cff00ccffPath %d:|r  |cffffffff%s|r  |cff888888[%d]|r",index,tostring(path.name),pathId))
          for _,requirement in ipairs(path.requirements) do AddAcquisitionLine(requirement) end
        end
      end
    elseif not next(found) then table.insert(lines,""); table.insert(lines,"|cffaaaaaaWaiting for authoritative server race and class requirements...|r") end
    return table.concat(lines,"\n")
  end
  local function CompanionPreview(item)
    if not GetNumCompanions or not GetCompanionInfo or not model.SetCreature then return nil end
    local spellName=GetItemSpell and GetItemSpell(ItemLink(item)) or nil
    local function CompanionKey(value)
      value=tostring(value or ""):lower(); value=value:gsub("^reins of the ",""):gsub("^reins of ",""):gsub("^whistle of the ",""):gsub("^whistle of ",""):gsub(" mount$",""):gsub(" companion$",""):gsub(" pet$",""):gsub("[^%w]","")
      return value
    end
    local itemKey=CompanionKey(item.name); local spellKey=CompanionKey(spellName)
    for _,kind in ipairs({"MOUNT","CRITTER"}) do
      local count=GetNumCompanions(kind) or 0
      for i=1,count do
        local creatureID,creatureName,creatureSpellID=GetCompanionInfo(kind,i)
        local knownSpellName=creatureSpellID and GetSpellInfo(creatureSpellID)
        local creatureKey=CompanionKey(creatureName); local knownSpellKey=CompanionKey(knownSpellName)
        if creatureID and ((spellName and (spellName==knownSpellName or spellName==creatureName)) or (itemKey~="" and (itemKey==creatureKey or itemKey==knownSpellKey)) or (spellKey~="" and (spellKey==creatureKey or spellKey==knownSpellKey))) then return creatureID,kind,creatureName or spellName end
      end
    end
    return nil
  end
  local function Money(copper)
    copper=tonumber(copper) or 0; return string.format("%dg %ds %dc",math.floor(copper/10000),math.floor((copper%10000)/100),copper%100)
  end
  local function ItemReport()
    local item=itemUI.selected
    if not item then return "AZERCORE OPS — ITEM REPORT\nNo item selected." end
    local lines={"AZERCORE OPS — ITEM REPORT",string.format("%s  |  Item ID %s",item.name or "Unknown item",item.id or "?"),"View: "..itemUI.view,""}
    if itemUI.view=="STATS" then
      table.insert(lines,"ITEM STATS")
      local found=false
      if GetItemStats and item.link then local stats=GetItemStats(item.link); if stats then for stat,value in pairs(stats) do local label=statNames[stat] or stat:gsub("^ITEM_MOD_",""):gsub("_SHORT$",""):gsub("_"," "); table.insert(lines,string.format("%s: %s",label,value)); found=true end end end
      if not found then table.insert(lines,"No numeric item stats are available from the client cache.") end
    elseif itemUI.view=="CRAFTING" then
      local server=itemUI.server or {}; table.insert(lines,"CRAFTING METHODS")
      if #(server.crafts or {})==0 then table.insert(lines,"No crafting method was reported for this item.") end
      for _,craft in ipairs(server.crafts or {}) do
        table.insert(lines,string.format("%s — Spell %s\nProfession: %s (%s), required skill %s\nProduces: %s\nResult: %s; probability: %s",craft.spellname or "Craft item",craft.spell or "?",craft.profession or "Unknown",craft.skill or "?",craft.rank or "?",craft.produced or "1",craft.resulttype or "DIRECT",craft.chance or "UNKNOWN"))
        for _,reagent in ipairs(server.reagents or {}) do if reagent.spell==craft.spell then table.insert(lines,string.format("  Reagent: %sx %s [Item %s]",reagent.count or "?",reagent.name or "Unknown",reagent.id or "?")) end end
        for _,recipe in ipairs(server.recipes or {}) do if recipe.spell==craft.spell then table.insert(lines,string.format("  Recipe: %s [Item %s]",recipe.name or "Unknown",recipe.id or "?")) end end
      end
      if #(server.uses or {})>0 then table.insert(lines,""); table.insert(lines,"USED AS A REAGENT") end
      for _,use in ipairs(server.uses or {}) do table.insert(lines,string.format("%s — %s skill %s — creates %sx %s [Item %s]",use.spellname or ("Spell "..tostring(use.spell)),use.profession or "Unknown",use.rank or "?",use.count or "1",use.resultname or "Unknown",use.resultid or "?")) end
    elseif itemUI.view=="SOURCES" then
      local sources=itemUI.server and itemUI.server.sources or {}; table.insert(lines,"KNOWN SOURCES")
      if #sources==0 then table.insert(lines,"No vendor, creature-drop, gameobject-loot or quest-reward source was reported.") end
      for _,source in ipairs(sources) do table.insert(lines,string.format("%s — %s [%s]%s",source.type or "SOURCE",source.name or "Unknown",source.id or "?",source.detail and source.detail~="" and (" — "..source.detail) or "")) end
    elseif itemUI.view=="REQUIREMENTS" then
      table.insert(lines,string.format("Minimum level: %s\nItem level: %s\nEquipment slot: %s\nType: %s\nSubtype: %s",item.minLevel or "0",item.itemLevel or "?",equipNames[item.equipLoc] or item.equipLoc or "Not equippable",item.itemType or "?",item.subType or "?"))
    elseif itemUI.view=="TECHNICAL" then
      table.insert(lines,string.format("Item ID: %s\nQuality: %s\nStack size: %s\nEquip location: %s\nTexture: %s\nVendor sell price: %s",item.id or "?",item.quality or "?",item.stack or "?",item.equipLoc~="" and item.equipLoc or "None",item.texture or "?",Money(item.sellPrice)))
    elseif itemUI.view=="PREVIEW" then table.insert(lines,item.equipLoc and item.equipLoc~="" and "Wearable 3D preview available." or "This item is not wearable; the preview uses its large icon and tooltip.")
    else table.insert(lines,string.format("Quality: %s\nItem level: %s\nRequired level: %s\nCategory: %s — %s\nStack size: %s\nSell price: %s\n\nShift-click the selected-item icon to insert its item link into chat.",item.quality or "?",item.itemLevel or "?",item.minLevel or "0",item.itemType or "?",item.subType or "?",item.stack or "?",Money(item.sellPrice))) end
    return table.concat(lines,"\n")
  end
  itemUI.Report=ItemReport
  itemUI.RenderLookupResults=function()
    local enriched={}
    for _,result in ipairs(lookup.results or {}) do
      local name,link,quality,itemLevel,_,itemType,subType,_,equipLoc,texture=GetItemInfo(result.id)
      local category=(itemType=="Armor" or itemType=="Weapon") and "Equipment" or itemType or "Uncached"
      table.insert(enriched,{result=result,id=result.id,name=name or result.title or ("Item "..result.id),link=link or result.link,quality=quality,itemLevel=itemLevel,itemType=itemType,subType=subType,equipLoc=equipLoc,texture=texture or GetItemIcon(result.id),category=category})
    end
    table.sort(enriched,function(a,b) if a.category==b.category then return a.name<b.name end return a.category<b.category end)
    for i,row in ipairs(resultRows.item) do
      local data=enriched[i]
      if data then
        row.id=data.id; row.kind="item"; row.result=data.result; row.icon:SetTexture(data.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        local r,g,b=1,1,1; if data.quality then r,g,b=GetItemQualityColor(data.quality) end; row.label:SetTextColor(r,g,b); row.label:SetText(data.name)
        local heroic=false
        for _,entry in ipairs(TooltipLines({id=data.id,name=data.name,link=data.link,quality=data.quality}) or {}) do if entry.left and entry.left:lower()=="heroic" then heroic=true; break end end
        local difficulty=heroic and "  •  |cff55ff55Heroic|r" or (data.category=="Equipment" and "  •  Normal" or "")
        row.meta:SetText(string.format("|cff00ccff%s|r  •  |cffaaaaaa%s%s%s|r",data.category,data.subType or data.itemType or "Item",data.itemLevel and ("  •  iLvl "..data.itemLevel) or "",difficulty)); row:Show()
      else row.id=nil; row.result=nil; row.label:SetText(""); row.meta:SetText(""); row:Hide() end
    end
  end
  itemUI.Clear=function()
    titleBox:SetText(""); itemIdBox:SetText(""); count:SetText("1"); lookup.kind="item"; lookup.results={}; itemUI.selected=nil; itemUI.server={crafts={},reagents={},recipes={},sources={},uses={},requirements={},access=nil,preview=nil}; itemUI.loading=false; itemUI.view="OVERVIEW"
    selectedName:SetText("No item selected"); selectedName:SetTextColor(unpack(C.white)); selectedMeta:SetText("Search by item name or exact item ID."); icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); iconFrame:SetBackdropBorderColor(unpack(C.border)); itemUI.Render(); RenderResults(); SetStatus("Item Inspector cleared")
  end
  itemUI.RefreshPreview=function()
    local item=itemUI.selected; if not item then model:Hide(); fallback:Show(); return end
    local serverPreview=itemUI.server and itemUI.server.preview
    local serverDisplay=serverPreview and tonumber(serverPreview.display) or 0
    local serverCreature=serverPreview and tonumber(serverPreview.creature) or 0
    local creatureID,companionKind,companionName=CompanionPreview(item)
    if serverDisplay>0 and model.SetDisplayInfo then
      fallback:Hide(); model:Show(); model:SetDisplayInfo(serverDisplay); if model.SetFacing then model:SetFacing(model.azerFacing or 0) end
    elseif serverCreature>0 and model.SetCreature then
      fallback:Hide(); model:Show(); model:SetCreature(serverCreature); if model.SetFacing then model:SetFacing(model.azerFacing or 0) end
    elseif creatureID then
      fallback:Hide(); model:Show(); model:SetCreature(creatureID); if model.SetFacing then model:SetFacing(model.azerFacing or 0) end
    elseif visibleEquipLocs[item.equipLoc] and model.TryOn then
      fallback:Hide(); model:Show(); if model.SetUnit then model:SetUnit("player") end; model:TryOn(ItemLink(item)); if model.SetFacing then model:SetFacing(model.azerFacing or 0) end
    else
      model:Hide(); fallback:Show(); fallbackIcon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      local slot=equipNames[item.equipLoc]
      if invisibleEquipLocs[item.equipLoc] then fallbackText:SetText(string.format("|cffffffff%s|r\n|cff00ccff%s|r\n|cffaaaaaaThis equipment slot has no visible character model.|r",item.name or ("Item "..tostring(item.id)),slot or "Equipment"))
      else fallbackText:SetText(string.format("|cffffffff%s|r\n|cffaaaaaa%s has no available 3D preview.|r",item.name or ("Item "..tostring(item.id)),companionKind or item.itemType or "This item")) end
    end
    if itemUI.UpdatePreviewCamera then itemUI.UpdatePreviewCamera() end
  end
  itemUI.Render=function()
    local titles={OVERVIEW="ITEM OVERVIEW",PREVIEW="ITEM PREVIEW",CRAFTING="CRAFTING",SOURCES="SOURCES",STATS="ITEM STATS",REQUIREMENTS="REQUIREMENTS",TECHNICAL="TECHNICAL"}; workspaceTitle:SetText(titles[itemUI.view] or "ITEM")
    for key,b in pairs(itemUI.viewButtons) do if key==itemUI.view then b:SetBackdropColor(unpack(C.selected)); b:SetBackdropBorderColor(unpack(C.gold)) else b:SetBackdropColor(unpack(C.button)); b:SetBackdropBorderColor(unpack(C.border)) end end
    for _,row in ipairs(itemUI.linkRows) do row:Hide() end
    if itemUI.view=="PREVIEW" then reportScroll:Hide(); previewFrame:Show(); itemUI.RefreshPreview()
    else previewFrame:Hide(); reportScroll:Show(); local showResults=itemUI.view=="OVERVIEW" and not itemUI.selected
      if showResults then resultsTitle:Show(); RenderResults() else resultsTitle:Hide(); for _,row in ipairs(resultRows.item) do row:Hide() end end
      if itemUI.view=="CRAFTING" or itemUI.view=="SOURCES" then
        reportText:SetText(""); local entries={}; local server=itemUI.server or {}
        if itemUI.view=="CRAFTING" then
          for _,craft in ipairs(server.crafts or {}) do
            table.insert(entries,{text=string.format("%s — %s • skill %s • creates %s • %s%s",craft.spellname or ("Spell "..tostring(craft.spell)),craft.profession or "Unknown profession",craft.rank or "?",craft.produced or "1",craft.resulttype or "DIRECT",craft.chance and craft.chance~="UNKNOWN" and (" • "..craft.chance) or "")})
            for _,reagent in ipairs(server.reagents or {}) do if reagent.spell==craft.spell then table.insert(entries,{text=string.format("    %sx %s",reagent.count or "?",reagent.name or ("Item "..tostring(reagent.id))),link=ItemLink(reagent)}) end end
            for _,recipe in ipairs(server.recipes or {}) do if recipe.spell==craft.spell then table.insert(entries,{text="    Recipe: "..tostring(recipe.name or recipe.id),link=ItemLink(recipe)}) end end
          end
          if #(server.uses or {})>0 then table.insert(entries,{text="USED AS A REAGENT"}) end
          for _,use in ipairs(server.uses or {}) do table.insert(entries,{text=string.format("    %s creates %sx %s",use.profession or use.spellname or "Craft",use.count or "1",use.resultname or use.resultid or "Unknown"),link=ItemLink({id=use.resultid,name=use.resultname,quality=1})}) end
          if #entries==0 then table.insert(entries,{text=itemUI.loading and "Loading crafting information..." or "No crafting method was reported for this item."}) end
        else
          for _,source in ipairs(server.sources or {}) do
            local link=source.type=="QUEST_REWARD" and QuestLink(source.id,source.name) or nil
            table.insert(entries,{text=string.format("%s — %s",source.type or "SOURCE",source.name or source.id or "Unknown"),detail=source.detail or "",link=link})
          end
          if #entries==0 then table.insert(entries,{text=itemUI.loading and "Loading item sources..." or "No vendor, creature-drop, gameobject-loot or quest-reward source was reported."}) end
        end
        EnsureItemLinkRows(#entries)
        local y=-4
        for i,entry in ipairs(entries) do
          local row=itemUI.linkRows[i]
          row:ClearAllPoints(); row:SetPoint("TOPLEFT",4,y); row:SetWidth(355); row.link=entry.link
          row.label:ClearAllPoints()
          if itemUI.view=="SOURCES" then
            row.label:SetPoint("TOPLEFT",7,-5); row.label:SetWidth(341); row.label:SetJustifyV("TOP"); row.label:SetWordWrap(true); row:SetText(entry.text or "")
            local titleHeight=math.max(13,math.ceil(row.label:GetStringHeight() or 13)); row.label:SetHeight(titleHeight)
            local detail=tostring(entry.detail or "")
            local detailHeight=0
            if detail~="" then
              row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",row.label,"BOTTOMLEFT",0,-3); row.detail:SetWidth(341); row.detail:SetText(detail); row.detail:SetWordWrap(true); row.detail:Show()
              detailHeight=math.max(13,math.ceil(row.detail:GetStringHeight() or 13)); row.detail:SetHeight(detailHeight)
            else row.detail:SetText(""); row.detail:Hide() end
            row:SetHeight(10+titleHeight+(detailHeight>0 and (3+detailHeight) or 0))
          else
            row.detail:SetText(""); row.detail:Hide(); row.label:SetPoint("LEFT",7,0); row.label:SetPoint("RIGHT",-7,0); row.label:SetJustifyV("MIDDLE"); row.label:SetWordWrap(false); row:SetHeight(24); row:SetText(entry.text or "")
          end
          row:Show(); y=y-row:GetHeight()-3
        end
        reportChild:SetHeight(math.max(370,-y+7))
      else
        if showResults then reportText:SetText("") elseif itemUI.view=="OVERVIEW" then reportText:SetText(ColoredTooltipReport(itemUI.selected) or ItemReport()) elseif itemUI.view=="STATS" then reportText:SetText(ColoredStatsReport(itemUI.selected)) elseif itemUI.view=="REQUIREMENTS" then reportText:SetText(ColoredRequirementsReport(itemUI.selected)) else reportText:SetText(ItemReport()) end
        reportChild:SetHeight(math.max(370,reportText:GetStringHeight()+170))
      end
    end
  end
  itemUI.Select=function(id,result,retry)
    id=tonumber(id); if not id then return end
    local name,link,quality,itemLevel,minLevel,itemType,subType,stack,equipLoc,texture,sellPrice=GetItemInfo(id)
    local fallbackName=result and result.title or ("Item "..id); link=link or (result and result.link); name=name or fallbackName; texture=texture or GetItemIcon(id)
    itemUI.selected={id=id,name=name,link=link,quality=quality,itemLevel=itemLevel,minLevel=minLevel,itemType=itemType,subType=subType,stack=stack,equipLoc=equipLoc or "",texture=texture,sellPrice=sellPrice}
    if not retry or retry==0 then itemUI.server={crafts={},reagents={},recipes={},sources={},uses={},requirements={},access=nil,preview=nil}; itemUI.captureId=id; itemUI.loading=true; SendCommand(string.format(CMD.itemInspect,id)) end
    itemIdBox:SetText(id); selectedName:SetText(name); selectedMeta:SetText(string.format("Item ID %d  •  %s%s",id,itemType or "Loading item data",itemLevel and ("  •  Item level "..itemLevel) or "")); icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    if quality then local r,g,b=GetItemQualityColor(quality); iconFrame:SetBackdropBorderColor(r,g,b); selectedName:SetTextColor(r,g,b) else selectedName:SetTextColor(unpack(C.white)) end
    if not retry or retry==0 then itemUI.view="PREVIEW" end
    itemUI.Render(); SetStatus("Selected item "..name.." ["..id.."]")
    if (not itemType or not texture) and (retry or 0)<20 then After(.25,function() if itemUI.selected and itemUI.selected.id==id then itemUI.Select(id,result,(retry or 0)+1) end end) end
  end
  local views={{"Overview","OVERVIEW"},{"Preview","PREVIEW"},{"Crafting","CRAFTING"},{"Sources","SOURCES"},{"Stats","STATS"},{"Requirements","REQUIREMENTS"},{"Technical","TECHNICAL"}}
  for i,d in ipairs(views) do
    local label,key=d[1],d[2]
    local b=Button(action,label,88,22,function()
      local enteredId=tonumber(itemIdBox:GetText())
      local selectedId=itemUI.selected and itemUI.selected.id

      if not selectedId and (not enteredId or enteredId<=0) then
        local searchText=titleBox:GetText()
        if searchText and searchText~="" then
          local searchId=tonumber(searchText)
          if searchId and searchId>0 then
            SetStatus("No item selected. Click Search to inspect that exact Item ID.",true)
          else
            SetStatus("No item selected. Click Search, then select an item from the results.",true)
          end
        else
          SetStatus("No item selected. Search for an item or enter an exact Item ID.",true)
        end
        return
      end

      if enteredId and enteredId>0 and enteredId~=selectedId then
        itemUI.Select(enteredId,nil,0)
      elseif selectedId then
        local selected=itemUI.selected
        itemUI.Select(selectedId,{title=selected.name,link=selected.link},20)
      end

      itemUI.view=key
      itemUI.Render()
    end,"Open the Item "..label.." workspace")
    b:SetPoint("TOPLEFT",8,-29-(i-1)*27)
    itemUI.viewButtons[key]=b
    b:SetScript("OnLeave",function() itemUI.Render(); GameTooltip:Hide() end)
  end
  Button(action,"Copy",88,22,function() ShowSelectableReport("Copy Item report",ItemReport()) end,"Copy the active Item report"):SetPoint("BOTTOMLEFT",8,61)
  Button(action,"Share",88,22,function() local f=EnsureShareFrame(); f:SetCapturedMessage(ItemReport(),"ITEM",function() return ItemReport(),"ITEM" end); f:Show(); f:Raise() end,"Share the active Item report"):SetPoint("BOTTOMLEFT",8,34)
  Button(action,"Export",88,22,function() ShowSelectableReport("Export Item report",ItemReport()) end,"Export the active Item report"):SetPoint("BOTTOMLEFT",8,7)
  itemUI.Render(); RenderResults()
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

ApplyPlayerTargetIdentity=function(portrait,borderFrame,unit)
  unit=unit or "target"
  if UnitExists(unit) and UnitIsPlayer(unit) then
    local identity={
      name=UnitName(unit) or "Unknown",level=UnitLevel(unit) or "?",
      class=select(1,UnitClass(unit)) or "Player",classToken=select(2,UnitClass(unit)),
      race=UnitRace(unit) or "Unknown",guild=GetGuildInfo(unit),unit=unit,
    }
    if portrait then SetPortraitTexture(portrait,unit) end
    if borderFrame then
      local color=identity.classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[identity.classToken]
      borderFrame:SetBackdropBorderColor(color and color.r or C.gold[1],color and color.g or C.gold[2],color and color.b or C.gold[3],1)
    end
    return identity
  end
  if portrait then portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
  if borderFrame then borderFrame:SetBackdropBorderColor(unpack(C.border)) end
end

local function UpdateInstanceTargetIdentity()
  local frame=instanceUI.targetPortraitFrame
  if not frame or not instanceUI.targetPortrait then return end
  instanceUI.targetIdentity=ApplyPlayerTargetIdentity(instanceUI.targetPortrait,frame)
  local t=instanceUI.targetIdentity
  if instanceUI.targetIdentityName then instanceUI.targetIdentityName:SetText(t and t.name or "No player selected") end
  if instanceUI.targetIdentityMeta then instanceUI.targetIdentityMeta:SetText(t and string.format("Level %s  %s%s",tostring(t.level),t.class,t.guild and ("\nGuild: "..t.guild) or "") or "Select a player target") end
  frame:Show()
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

local function BindDifficultyName(id,isRaid)
  id=tonumber(id)
  if isRaid then return ({[0]="10 Player Normal",[1]="25 Player Normal",[2]="10 Player Heroic",[3]="25 Player Heroic"})[id] or ("Difficulty "..tostring(id or "?")) end
  return ({[0]="Normal",[1]="Heroic"})[id] or ("Difficulty "..tostring(id or "?"))
end

local function BindResettable(r)
  local value=tostring(r and (r.canReset or r.locked) or ""):lower()
  return value=="yes" or value=="true" or value=="1"
end

local function BindPermanent(r)
  local value=tostring(r and (r.perm or r.permanent) or ""):lower()
  return value=="yes" or value=="true" or value=="1"
end

local function BindApplicable(r) return tostring(r and r.applicable or "1")=="1" or r and r.applicable==true end
local function SelectedTargetBinds()
  local out={}; for _,r in ipairs(instanceUI.target or {}) do if r.selected then table.insert(out,r) end end; return out
end
local function UnbindSelectionCommands(rows)
  local commands,chunk={},{}
  local function flush() if #chunk>0 then table.insert(commands,string.format(CMD.instanceUnbind,table.concat(chunk,","))); chunk={} end end
  for _,r in ipairs(rows or {}) do
    local spec=string.format("%s:%s:%s",tostring(r.map),tostring(tonumber(r.difficulty) or 0),tostring(r.instance))
    local candidate=table.concat(chunk,","); if candidate~="" then candidate=candidate.."," end; candidate=candidate..spec
    if string.len(string.format(CMD.instanceUnbind,candidate))>210 then flush() end
    table.insert(chunk,spec)
  end
  flush(); return commands
end
local function ConfirmUnbindRows(rows,enabled)
  local commands=UnbindSelectionCommands(rows); if #commands==0 then return end
  instanceUI.pendingUnbindCommands=#commands
  local function sendRemaining(index)
    if index>#commands then return end
    SendCommand(commands[index]); After(.25,function() sendRemaining(index+1) end)
  end
  Confirm(commands[1],enabled,function() sendRemaining(2) end)
end
local function BossProgress(r)
  local total,defeated=tonumber(r and r.bosstotal) or 0,tonumber(r and r.bossdefeated) or 0
  return total>0 and string.format("Bosses %d/%d",defeated,total) or "Boss names unavailable"
end

local function BindVisible(r)
  local filter=instanceUI.filter or "ALL"
  if filter=="ALL" then return true end
  if filter=="RAID" then return r.isRaid or (tonumber(r.difficulty) or 0)>=2 end
  if filter=="DUNGEON" then return not (r.isRaid or (tonumber(r.difficulty) or 0)>=2) end
  if filter=="PERMANENT" then return BindPermanent(r) end
  if filter=="RESETTABLE" then return BindResettable(r) end
  return true
end

local function FilterBinds(source)
  local out={}; for _,r in ipairs(source or {}) do if BindVisible(r) and (instanceUI.view~="LOCKED" or BindPermanent(r)) then table.insert(out,r) end end; return out
end

local function BindComparison(r)
  if not r then return "No comparison" end
  if MyHasInstance(r.instance) then return "SAME AS MINE" end
  for _,mine in ipairs(instanceUI.my or {}) do if tonumber(mine.map)==tonumber(r.map) then return "DIFFERENT ID" end end
  return "NO PERSONAL BIND"
end

local function BindReportText(selectedOnly)
  local lines={"AZERCORE OPS — BINDS / RESET",""}
  if instanceUI.inspectedPlayer then table.insert(lines,"Target: "..instanceUI.inspectedPlayer) end
  local function add(title,rows)
    table.insert(lines,""); table.insert(lines,title.." ("..#rows..")")
    if #rows==0 then table.insert(lines,"No binds found") end
    for i,r in ipairs(rows) do
      table.insert(lines,string.format("%02d. %s | Map %s | Instance %s | %s | %s | Expires %s | Standard reset %s | GM unbind %s | %s | Mask %s",i,r.name or "Unknown",r.map or "?",r.instance or r.id or "?",r.difficultyName or r.difficulty or "?",BindPermanent(r) and "Boss lockout" or "Temporary bind",r.ttr or ShortTime(r.reset),BindResettable(r) and "Available" or "Not available",BindApplicable(r) and "Available" or "Not available",BossProgress(r),r.encountermask or "0"))
      for _,boss in ipairs(r.bosses or {}) do table.insert(lines,string.format("    %s %s",tostring(boss.defeated)=="1" and "DEFEATED" or "REMAINING",boss.name or "Unknown boss")) end
    end
  end
  local locked=instanceUI.view=="LOCKED"; local myTitle=locked and "MY LOCKED BINDS" or "MY BINDS"; local targetTitle=locked and "TARGET LOCKED BINDS" or "TARGET BINDS"
  if selectedOnly and instanceUI.selectedBind then add("SELECTED BIND",{instanceUI.selectedBind}) else
    add(myTitle,FilterBinds(instanceUI.my)); add(targetTitle,FilterBinds(instanceUI.target)); if instanceUI.selectedBind then add("SELECTED BIND DETAILS",{instanceUI.selectedBind}) end
  end
  return table.concat(lines,"\n")
end

local function BindDetailText()
  local r=instanceUI.selectedBind
  if not r then return "No bind is selected." end
  local player
  if instanceUI.selectedBindOwner=="SELF" then player=UnitName("player") or "Player"
  else player=instanceUI.inspectedPlayer or SelectedPlayerName() or "Target" end
  local lines={
    "AZERCORE OPS — SELECTED BIND DETAILS","",
    "Player: "..tostring(player),
    "Instance: "..tostring(r.name or "Unknown"),
    "Map ID: "..tostring(r.map or "?"),
    "Instance ID: "..tostring(r.instance or r.id or "?"),
    "Difficulty: "..tostring(r.difficultyName or BindDifficultyName(r.difficulty)),
    "Lockout: "..(BindPermanent(r) and "Saved until scheduled reset" or "Temporary bind"),
    "Expires in: "..tostring(r.ttr or ShortTime(r.reset)),
    "Technical bind type: "..(BindPermanent(r) and "Permanent" or "Temporary"),
    "Standard reset: "..(BindResettable(r) and "Available" or "Not available"),
    "GM unbind: "..(BindApplicable(r) and "Available" or "Not available"),
    "Reason: "..tostring(r.reason or "Not reported"),
    "Encounter mask: "..tostring(r.encountermask or 0),
    "Boss progress: "..BossProgress(r),
    "Comparison: "..(instanceUI.selectedBindOwner=="SELF" and "MY BIND" or BindComparison(r)),
  }
  if #(r.bosses or {})>0 then
    table.insert(lines,""); table.insert(lines,"ENCOUNTERS")
    for i,boss in ipairs(r.bosses) do
      table.insert(lines,string.format("%02d. %s — %s",i,boss.name or "Unknown boss",tostring(boss.defeated)=="1" and "DEFEATED" or "REMAINING"))
    end
  else table.insert(lines,""); table.insert(lines,"Boss names unavailable") end
  return table.concat(lines,"\n")
end

local function ShowBindDetails()
  if not instanceUI.selectedBind then SetStatus("Select a bind first.",true); return end
  ShowSelectableReport("Selected bind details",BindDetailText())
end

local function LogBindActivity(text,kind)
  instanceUI.activity=instanceUI.activity or {}; table.insert(instanceUI.activity,1,{time=date("%H:%M:%S"),kind=kind or "STATUS",text=tostring(text or "")})
  while #instanceUI.activity>80 do table.remove(instanceUI.activity) end
end

local function BindActivityText()
  local lines={"AzerCore Ops — Bind activity and module output",string.format("Generated: %s",date("%Y-%m-%d %H:%M:%S")),""}
  if #instanceUI.activity==0 then table.insert(lines,"No bind activity recorded in this session.") end
  for i=#instanceUI.activity,1,-1 do local r=instanceUI.activity[i]; table.insert(lines,string.format("[%s] %-8s %s",r.time,r.kind,r.text)) end
  return table.concat(lines,"\n")
end

local function ShowBindActivity()
  ShowSelectableReport("Bind activity and module output",BindActivityText(),"Clear",function()
    instanceUI.activity={}
    local cleared="AzerCore Ops — Bind activity and module output\nGenerated: "..date("%Y-%m-%d %H:%M:%S").."\n\nBind activity cleared.\nNo bind activity recorded in this session."
    if exportEdit then exportEdit:SetText(cleared); exportEdit:SetHeight(310); exportEdit:SetFocus(); exportEdit:HighlightText() end
    SetStatus("Bind activity cleared.")
  end)
end

local function CopyBindReport() ShowSelectableReport("Copy Binds / Reset report",BindReportText(false)) end
local function ExportBindReport() ShowSelectableReport("Export Binds / Reset report",BindReportText(false)) end
local function ShareBindReport()
  local text=BindReportText(false); local f=EnsureShareFrame(); f:SetCapturedMessage(text,"INSTANCE BINDS",function() return BindReportText(false),"INSTANCE BINDS" end); f:Show(); f:Raise(); SetStatus("Courier opened with the Binds / Reset report.")
end

local function UpdateBindControls()
  local function normalized(name) local base=tostring(name or ""):match("^[^-]+") or ""; return base:lower() end
  local selectedTarget=SelectedPlayerName(); local targetCurrent=selectedTarget and normalized(instanceUI.inspectedPlayer)==normalized(selectedTarget)
  local function state(button,enabled)
    if not button then return end
    if enabled then button:Enable(); button:SetAlpha(1); button:SetBackdropColor(unpack(C.button)); button:SetBackdropBorderColor(unpack(C.border))
    else button:Disable(); button:SetAlpha(.45); button:SetBackdropColor(unpack(C.bg)); button:SetBackdropBorderColor(unpack(C.border)) end
  end
  state(instanceUI.inspectButton,selectedTarget~=nil)
  if instanceUI.inspectButton and selectedTarget and instanceUI.autoInspect then instanceUI.inspectButton:SetBackdropColor(unpack(C.selected)); instanceUI.inspectButton:SetBackdropBorderColor(unpack(C.gold)) end
  local unbindAllowed=EffectiveCharacterMode()=="GM"
  state(instanceUI.unbindSelectedButton,unbindAllowed and targetCurrent and #SelectedTargetBinds()>0)
  if instanceUI.unbindSelectedButton then
    if not unbindAllowed then instanceUI.unbindSelectedButton.disabledReason="Unavailable in Player Mode. Removing instance binds requires server-authorized GM Mode."
    elseif not targetCurrent then instanceUI.unbindSelectedButton.disabledReason="Inspect the current player target before selecting binds."
    elseif #SelectedTargetBinds()==0 then instanceUI.unbindSelectedButton.disabledReason="Select one or more applicable target binds first."
    else instanceUI.unbindSelectedButton.disabledReason=nil end
  end
  state(instanceUI.bindDetailsButton,instanceUI.selectedBind~=nil)
end

local function BindRow(parent,y,click,checkClick)
  local row=CreateFrame("Button",nil,parent); row:SetPoint("TOPLEFT",2,y); row:SetWidth(410); row:SetHeight(64)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.075,.08,.095,.96)
  row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",6,-4); row.text:SetPoint("BOTTOMRIGHT",-6,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP"); row.text:SetWordWrap(true); row.text:SetTextColor(unpack(C.white))
  row:SetScript("OnClick",click)
  if checkClick then
    row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT",30,-4); row.text:SetPoint("BOTTOMRIGHT",-6,3)
    row.check=CreateFrame("Button",nil,row); row.check:SetPoint("TOPLEFT",4,-4); row.check:SetWidth(20); row.check:SetHeight(20); row.check:SetFrameLevel(row:GetFrameLevel()+5); Backdrop(row.check,C.bg)
    row.check.label=row.check:CreateFontString(nil,"OVERLAY","GameFontNormal"); row.check.label:SetPoint("CENTER",0,0); row.check.label:SetTextColor(unpack(C.gold))
    row.check.checked=false
    row.check.SetChecked=function(self,value) self.checked=value and true or false; self.label:SetText(self.checked and "x" or "") end
    row.check.GetChecked=function(self) return self.checked end
    row.check:SetScript("OnClick",function(self) local wanted=not self:GetChecked(); self:SetChecked(wanted); checkClick(row,wanted) end)
  end
  row:Hide(); return row
end

local function RenderInstances()
  local selectedName=SelectedPlayerName() or "none"; local targetName=instanceUI.inspectedPlayer or selectedName; local lockedView=instanceUI.view=="LOCKED"
  if instanceUI.targetLabel then instanceUI.targetLabel:SetText((lockedView and "TARGET LOCKED BINDS — " or "TARGET BINDS — ").."|cffffffff"..targetName.."|r") end
  if instanceUI.myHeading then instanceUI.myHeading:SetText(lockedView and "MY LOCKED BINDS" or "MY BINDS") end
  if instanceUI.targetHeader then instanceUI.targetHeader:SetText("SELECTED TARGET") end
  local mine=FilterBinds(instanceUI.my); local target=FilterBinds(instanceUI.target)
  for i,row in ipairs(instanceUI.myRows) do
    local r=mine[instanceUI.myOffset+i]
    if r then
      local state=BindPermanent(r) and "Boss lockout" or "Temporary bind"
      row.data=r; row.text:SetText(string.format("|cffffcc33%s|r\nMap %s  •  Instance %s  •  %s\n%s  •  Standard reset: %s  •  %s",r.name or "Unknown",r.map or "?",r.instance or r.id or "?",r.difficultyName or BindDifficultyName(r.difficulty,r.isRaid),state,BindResettable(r) and "Yes" or "No",BossProgress(r))); row:SetBackdropColor(unpack(instanceUI.selectedBind==r and C.selected or C.button)); row:Show()
    else row.data=nil; row:Hide() end
  end
  for i,row in ipairs(instanceUI.targetRows) do
    local r=target[instanceUI.targetOffset+i]
    if r then
      local match=BindComparison(r)
      row.data=r; row.text:SetText(string.format("|cffffcc33%s|r\nMap %s  •  Instance %s  •  %s\n%s  •  GM unbind: %s  •  %s",r.name or ("Map "..tostring(r.map or "?")),r.map or "?",r.instance or "?",r.difficultyName or BindDifficultyName(r.difficulty,r.isRaid),BindPermanent(r) and "Boss lockout" or "Temporary bind",BindApplicable(r) and "Yes" or "No",BossProgress(r))); row:SetBackdropColor(unpack(instanceUI.selectedBind==r and C.selected or C.button)); row.match=match; if row.check then row.check:SetChecked(r.selected and true or false) end; row:Show()
    else row.data=nil; if row.check then row.check:SetChecked(false) end; row:Hide() end
  end
  if instanceUI.myEmpty then instanceUI.myEmpty:SetText(instanceUI.myLoadState=="LOADING" and "Loading personal binds..." or instanceUI.myLoadState=="LOADED" and "No binds found" or "Personal binds not loaded"); if #mine==0 then instanceUI.myEmpty:Show() else instanceUI.myEmpty:Hide() end end
  if instanceUI.targetEmpty then instanceUI.targetEmpty:SetText(instanceUI.targetLoadState=="LOADING" and "Loading target binds..." or instanceUI.targetLoadState=="LOADED" and "No binds found" or selectedName=="none" and "No player selected" or "Target binds not loaded"); if #target==0 then instanceUI.targetEmpty:Show() else instanceUI.targetEmpty:Hide() end end
  local playerKey=tostring(UnitName("player") or ""):lower(); local targetKey=tostring(instanceUI.inspectedPlayer or ""):match("^[^-]+") or ""; targetKey=targetKey:lower()
  local countedSets=targetKey~="" and targetKey==playerKey and {mine} or {mine,target}
  local total,permanent,temporary,resettable=0,0,0,0
  for _,set in ipairs(countedSets) do for _,r in ipairs(set) do total=total+1; if BindPermanent(r) then permanent=permanent+1 else temporary=temporary+1 end; if BindResettable(r) then resettable=resettable+1 end end end
  if instanceUI.summaryText then instanceUI.summaryText:SetText(string.format("Total  %d        Boss lockouts  %d        Temporary  %d        Resettable  %d",total,permanent,temporary,resettable)) end
  for name,b in pairs(instanceUI.filterButtons) do b:SetBackdropColor(unpack(name==instanceUI.filter and C.selected or C.button)); b:SetBackdropBorderColor(unpack(name==instanceUI.filter and C.gold or C.border)) end
  for name,b in pairs(instanceUI.viewButtons) do local active=(name==instanceUI.view); b:SetBackdropColor(unpack(active and C.selected or C.button)); b:SetBackdropBorderColor(unpack(active and C.gold or C.border)) end
  if instanceUI.detailText then
    local r=instanceUI.selectedBind
    if r then
      local bossLines={BossProgress(r).."  •  Encounter mask "..tostring(r.encountermask or 0)}; for _,boss in ipairs(r.bosses or {}) do table.insert(bossLines,(tostring(boss.defeated)=="1" and "[DEFEATED] " or "[REMAINING] ")..(boss.name or "Unknown boss")) end
      instanceUI.detailText:SetText(string.format("|cffffcc33Player|r\n%s\n\n|cffffcc33Instance|r\n%s\n\n|cffffcc33Identifiers|r\nMap ID        %s\nInstance ID   %s\n\n|cffffcc33Details|r\nDifficulty    %s\nStatus        %s\nReset in      %s\nStandard reset %s\nGM unbind     %s\nReason        %s\n\n|cffffcc33Encounter progress|r\n%s\n\n|cffffcc33Comparison|r\n%s",instanceUI.inspectedPlayer or SelectedPlayerName() or "Target",r.name or "Unknown",r.map or "?",r.instance or r.id or "?",r.difficultyName or BindDifficultyName(r.difficulty,r.isRaid),BindPermanent(r) and "Permanent" or "Temporary",r.ttr or ShortTime(r.reset),BindResettable(r) and "Available" or "Not available",BindApplicable(r) and "Available" or "Not available",r.reason or "Not reported",table.concat(bossLines,"\n"),BindComparison(r)))
    else instanceUI.detailText:SetText("Select a target bind to inspect its complete details.") end
  end
  if instanceUI.inspectionText then instanceUI.inspectionText:SetText(instanceUI.inspectedPlayer and ("Inspected: "..instanceUI.inspectedPlayer.."  •  "..(instanceUI.inspectedAt or "just now")) or "No target inspected") end
  if instanceUI.statusText then
    local scope=lockedView and "My Locked Binds" or "My Binds"; if instanceUI.inspectedPlayer then scope=scope.." + "..(lockedView and "Target Locked Binds" or "Target Binds").." — "..instanceUI.inspectedPlayer end
    instanceUI.statusText:SetText("Report: "..scope)
  end
  UpdateBindControls()
end

local function RefreshMyInstances(skipRequest)
  instanceUI.my={}; instanceUI.myOffset=0; instanceUI.myLoadState="LOADING"; instanceUI.bindScope="SELF"; RenderInstances(); SendCommand(CMD.instanceBindsSelf); SetStatus("Collecting structured personal binds...")
end

local function InspectTargetInstances(activateMode)
  if activateMode then instanceUI.autoInspect=true end
  if not RequireSelectedPlayer() then return end
  instanceUI.target={}; instanceUI.targetOffset=0; instanceUI.targetLoadState="LOADING"; instanceUI.selectedBind=nil; instanceUI.inspectedPlayer=SelectedPlayerName(); instanceUI.inspectedAt=date("%H:%M:%S"); instanceUI.bindScope="TARGET"; RenderInstances(); LogBindActivity("Inspecting target "..instanceUI.inspectedPlayer,"INSPECT"); SendCommand(CMD.instanceBindsTarget); SetStatus("Collecting structured binds for "..instanceUI.inspectedPlayer.."...")
end

local function BindSystemChatFilter(_,event,message)
  if event~="CHAT_MSG_SYSTEM" or not instanceUI.captureUntil or GetTime()>instanceUI.captureUntil then return false end
  local plain=tostring(message or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  if plain:match("map:%s*%d+,%s*inst:%s*%d+") or plain:lower():match("player binds:%s*%d+") then return true end
  return false
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",BindSystemChatFilter)

local RenderAudit

local function InstanceHistory()
  AzerCoreOpsDB.instanceSearchHistory=AzerCoreOpsDB.instanceSearchHistory or {}
  return AzerCoreOpsDB.instanceSearchHistory
end

local function PushInstanceHistory(query,mapId,name,instanceType,maxPlayers)
  query=tostring(query or ""):match("^%s*(.-)%s*$")
  if query=="" and not mapId then return end
  local history=InstanceHistory(); local key=tostring(mapId or "").."|"..query
  for i=#history,1,-1 do
    local e=history[i]; if tostring(e.map or "").."|"..tostring(e.query or "")==key then table.remove(history,i) end
  end
  table.insert(history,1,{query=query,map=tonumber(mapId),name=name,type=instanceType,max=tonumber(maxPlayers)})
  while #history>50 do table.remove(history) end
  auditUI.historyIndex=0
end

local function ShowInstanceHistory(delta)
  local history=InstanceHistory(); if #history==0 then SetStatus("Instance search history is empty.",true); return end
  auditUI.historyIndex=math.max(1,math.min(#history,(auditUI.historyIndex or 0)+delta))
  local entry=history[auditUI.historyIndex]
  if auditUI.searchBox then auditUI.searchBox:SetText(entry.query or entry.name or entry.map or ""); auditUI.searchBox:SetFocus(); auditUI.searchBox:HighlightText() end
  if entry.map then
    auditUI.selectedMap=entry.map; auditUI.selectedName=entry.name; auditUI.selectedType=entry.type; auditUI.selectedMaxPlayers=entry.max
    auditUI.difficulty=0; auditUI.difficultyLabel=(entry.type=="raid" and "10-player Normal" or "Normal")
    if auditUI.difficultyButton then auditUI.difficultyButton:SetText(auditUI.difficultyLabel.."  v") end
  end
  RenderAudit(); SetStatus("Saved instance search "..auditUI.historyIndex.." of "..#history)
end

local function ShowSavedInstanceHistory()
  local history=InstanceHistory(); if #history==0 then SetStatus("Instance search history is empty.",true); return end
  local lines={"AzerCore Ops saved instance searches",""}
  for i,e in ipairs(history) do table.insert(lines,string.format("%02d. %s%s",i,e.query or e.name or "Instance",e.map and string.format("  [Map ID: %d]",e.map) or "")) end
  ShowSelectableReport("Saved instance search history",table.concat(lines,"\n"),"Delete History",function() StaticPopup_Show("AZERCORE_OPS_CLEAR_INSTANCE_HISTORY") end)
end

StaticPopupDialogs["AZERCORE_OPS_CLEAR_INSTANCE_HISTORY"]={
  text="Delete all saved Instance Access search history?\n\nThis cannot be undone.",button1=YES,button2=NO,timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function() AzerCoreOpsDB.instanceSearchHistory={}; auditUI.historyIndex=0; if exportFrame then exportFrame:Hide() end; SetStatus("Saved instance search history deleted.") end
}

local function PrepareAuditMember(r)
  local raw=tostring(r.reason or "No details"); local reference=tonumber(auditUI.referenceId) or 0
  local same=raw:match("Already bound to requester's instance ID (%d+)")
  local playerConflict,requesterConflict=raw:match("Permanent lockout conflict: player ID (%d+), requester ID (%d+)")
  local noReference=raw:match("Player has instance ID (%d+); requester has no reference ID")
  local insideDifferent=raw:match("Currently inside different instance ID (%d+)")
  local temporaryPlayer,temporaryRequester=raw:match("Different temporary instance ID: player ID (%d+), requester ID (%d+)")
  r.bindId=tonumber(r.bind or playerConflict or temporaryPlayer or same or noReference or insideDifferent) or 0
  if r.bindId==0 and tonumber(r.map)==tonumber(auditUI.lastMap) then r.bindId=tonumber(r.instance) or 0 end
  r.referenceId=tonumber(requesterConflict or temporaryRequester) or reference
  r.outsideMap=tonumber(raw:match("Currently outside target map %(on map (%d+)%)"))
  r.permanentConflict=playerConflict~=nil or (tostring(r.permanent)=="1" and r.bindId>0 and reference>0 and r.bindId~=reference)
  local structuredMismatch=r.bindId>0 and reference>0 and r.bindId~=reference
  if r.result=="OFFLINE" then r.verdict="OFFLINE"
  elseif playerConflict or temporaryPlayer or structuredMismatch or insideDifferent or noReference then r.verdict="CONFLICT"
  elseif r.result=="FAIL" then r.verdict="BLOCKED"
  else r.verdict="GRANTED" end

  local friendly=raw
  friendly=friendly:gsub("Missing quest (%d+) %[(.-)%]%s*%-?%s*[^;]*","Quest %1 [%2] must be rewarded/turned in")
  friendly=friendly:gsub("Leader missing quest (%d+) %[(.-)%]%s*%-?%s*[^;]*","Leader must reward/turn in Quest %1 [%2]")
  friendly=friendly:gsub("Already bound to requester's instance ID (%d+)","Same as group Instance ID %1")
  friendly=friendly:gsub("Currently outside target map %(on map (%d+)%)","Outside the instance (map %1)")
  if tonumber(r.bosstotal) and tonumber(r.bosstotal)>0 then friendly=friendly..string.format("; Boss progress %s/%s",r.bossdefeated or 0,r.bosstotal) end
  if r.verdict=="GRANTED" then
    if r.bindId==0 and reference>0 then friendly="No personal bind; will join group Instance ID "..reference..(r.outsideMap and ("; Outside the instance (map "..r.outsideMap..")") or "") end
    r.displayReason="Access granted; "..friendly
  elseif r.verdict=="CONFLICT" then
    if r.permanentConflict then r.displayReason=string.format("Instance ID conflict: player %s, group %s; Permanent bind cannot be reset; the complete group cannot raid this saved instance together",r.bindId,r.referenceId)
    elseif noReference then r.displayReason="Instance ID "..r.bindId.." exists but the group has no reference ID; choose the intended group save and re-audit"
    else r.displayReason="Instance ID conflict; "..friendly end
  elseif r.verdict=="BLOCKED" then r.displayReason="Access blocked; "..friendly
  else r.displayReason="Player is offline; live bind and access data unavailable" end
  return r
end

local function FilteredAuditMembers(filterOverride)
  local activeFilter=filterOverride or auditUI.filter
  local out={}
  for _,r in ipairs(auditUI.members) do
    PrepareAuditMember(r)
    local include=activeFilter=="ALL"
      or (activeFilter=="CAN_JOIN" and r.verdict=="GRANTED")
      or (activeFilter=="CANNOT_JOIN" and (r.verdict=="BLOCKED" or r.verdict=="CONFLICT"))
      or (activeFilter=="OFFLINE" and r.verdict=="OFFLINE")
      or (activeFilter=="SAME_ID" and r.bindId>0 and r.bindId==auditUI.referenceId)
      or (activeFilter=="DIFFERENT_ID" and r.verdict=="CONFLICT")
      or (activeFilter=="NO_BIND" and r.verdict~="OFFLINE" and r.bindId==0)
    if include then table.insert(out,r) end
  end
  table.sort(out,function(a,b)
    local ar=(a.bindId>0 and a.bindId==auditUI.referenceId and 0) or (a.bindId>0 and a.bindId) or (a.verdict=="OFFLINE" and 99999998 or 99999997)
    local br=(b.bindId>0 and b.bindId==auditUI.referenceId and 0) or (b.bindId>0 and b.bindId) or (b.verdict=="OFFLINE" and 99999998 or 99999997)
    if ar==br then return (a.name or "")<(b.name or "") end; return ar<br
  end)
  return out
end

local function ComputeGroupVerdict()
  local issue,permanent,offline=false,false,0
  for _,r in ipairs(auditUI.members) do PrepareAuditMember(r); if r.verdict=="BLOCKED" or r.verdict=="CONFLICT" then issue=true end; if r.permanentConflict then permanent=true end; if r.verdict=="OFFLINE" then offline=offline+1 end end
  if permanent then auditUI.groupVerdict="GROUP CANNOT PROCEED"; auditUI.groupReason="Permanent Instance ID conflict"
  elseif issue then auditUI.groupVerdict="ACTION REQUIRED"; auditUI.groupReason="Resolve blocked access or Instance ID conflicts"
  else auditUI.groupVerdict="GROUP READY"; auditUI.groupReason="All inspected online members can enter together" end
  if offline>0 then auditUI.groupReason=auditUI.groupReason.."; "..offline.." offline member(s) not inspected" end
end

local function BuildAuditDisplay(members)
  local groups,order={},{ }
  for _,r in ipairs(members) do
    local key,label
    if r.verdict=="OFFLINE" then key="OFFLINE"; label="OFFLINE / NOT INSPECTED"
    elseif r.bindId>0 then key="ID:"..r.bindId; label="INSTANCE ID "..r.bindId..(r.bindId==auditUI.referenceId and " — GROUP REFERENCE" or "")
    else key="NO_BIND"; label="NO PERSONAL BIND"..((auditUI.referenceId or 0)>0 and (" — WILL JOIN ID "..auditUI.referenceId) or "") end
    if not groups[key] then groups[key]={label=label,rows={}}; table.insert(order,key) end; table.insert(groups[key].rows,r)
  end
  local display={}; for _,key in ipairs(order) do local g=groups[key]; table.insert(display,{isHeader=true,label=g.label.." — "..#g.rows.." PLAYER"..(#g.rows==1 and "" or "S")}); for _,r in ipairs(g.rows) do table.insert(display,r) end end
  return display
end

RenderAudit=function()
  for i,row in ipairs(auditUI.searchRows) do
    local r=auditUI.search[(auditUI.searchOffset or 0)+i]
    if r then
      row.id=tonumber(r.map); row.data=r
      row.label:SetText(string.format("%s  %s",r.map or "?",r.name or "Unknown")); row:Show()
      row:SetBackdropColor(unpack(tonumber(r.map)==tonumber(auditUI.selectedMap) and C.selected or C.button))
      row:SetBackdropBorderColor(unpack(tonumber(r.map)==tonumber(auditUI.selectedMap) and C.gold or C.border))
    else row.id=nil; row.data=nil; row:Hide() end
  end
  auditUI.filtered=FilteredAuditMembers(); if #auditUI.members>0 then ComputeGroupVerdict() end; auditUI.display=BuildAuditDisplay(auditUI.filtered)
  local rowHeight=Settings().compactAuditRows and 24 or 28
  if auditUI.scrollChild then auditUI.scrollChild:SetWidth(820); auditUI.scrollChild:SetHeight(math.max(1,#auditUI.display)*rowHeight) end
  for i,row in ipairs(auditUI.memberRows) do
    local r=auditUI.display[i]
    if r then
      row.data=r.isHeader and nil or r; row:SetPoint("TOPLEFT",0,-(i-1)*rowHeight); row:SetPoint("TOPRIGHT",0,-(i-1)*rowHeight); row:SetHeight(rowHeight-1)
      if r.isHeader then row.status:SetText(""); row.name:SetText(""); row.reason:SetText(""); row.header:SetText(r.label); row.header:Show(); row:SetBackdropColor(.035,.04,.05,1)
      else
        row.header:Hide(); row:SetBackdropColor(.075,.08,.095,.96)
        local color=r.verdict=="GRANTED" and C.resolve or (r.verdict=="CONFLICT" and C.diagnose or (r.verdict=="OFFLINE" and C.muted or C.red))
        row.status:SetText(r.verdict or "?"); row.status:SetTextColor(unpack(color)); row.name:SetText(r.name or "Unknown"); row.reason:SetText("ID "..(r.bindId>0 and r.bindId or "—").."  •  "..(r.displayReason or r.reason or "No reason"))
      end
      row:Show()
    else row.data=nil; row:Hide() end
  end
  if auditUI.scroll then auditUI.scroll:SetVerticalScroll(0); auditUI.scroll:SetHorizontalScroll(0) end
  if auditUI.horizontal then auditUI.horizontal:SetValue(0) end
  if auditUI.summary then
    local stale=auditUI.stale and "  •  STALE — RE-AUDIT" or ""; auditUI.summary:SetText(string.format("%s  •  Showing %d of %d%s",auditUI.groupVerdict,#auditUI.filtered,#auditUI.members,stale))
    auditUI.summary:SetTextColor(unpack(auditUI.groupVerdict=="GROUP READY" and C.resolve or (auditUI.groupVerdict=="GROUP CANNOT PROCEED" and C.red or C.diagnose)))
  end
  for name,button in pairs(auditUI.filterButtons) do button:SetBackdropColor(unpack(name==auditUI.filter and C.selected or C.button)) end
  if auditUI.lockedText then
    if auditUI.selectedMap then
      local maximum=tonumber(auditUI.selectedMaxPlayers) or 0
      if maximum<1 then maximum=(auditUI.selectedType=="raid" and 25 or 5) end
      auditUI.lockedText:SetText(string.format("|cffffd100%s|r\n\nMap ID: %s\nType: %s\nMaximum players: %s",auditUI.selectedName or "Unknown",auditUI.selectedMap,auditUI.selectedType or "Instance",maximum))
    else
      auditUI.lockedText:SetText("|cffaaaaaaNo instance locked.|r\n\nSelect an instance match to lock it into the workspace.")
    end
  end
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

local function InstanceAuditReportText()
  if #auditUI.members==0 then SetStatus("Run an instance audit before exporting.",true); return end
  local lines={"AzerCore Ops — Instance access group audit",string.format("Generated: %s",auditUI.generatedAt or date("%Y-%m-%d %H:%M:%S")),string.format("Instance: %s",auditUI.selectedName or "Unknown"),string.format("Map ID: %s  |  Difficulty: %s",auditUI.lastMap or "?",auditUI.difficultyLabel or auditUI.lastDifficulty or "?"),string.format("Reference Instance ID: %s",(auditUI.referenceId or 0)>0 and auditUI.referenceId or "None"),string.format("Group verdict: %s",auditUI.groupVerdict),"Reason: "..tostring(auditUI.groupReason or "No group summary"),auditUI.stale and "Snapshot status: STALE — run Re-audit" or "Snapshot status: Current",""}
  local members=FilteredAuditMembers("ALL"); local display=BuildAuditDisplay(members)
  for _,r in ipairs(display) do
    if r.isHeader then table.insert(lines,r.label); table.insert(lines,string.rep("-",math.min(72,#r.label)))
    else table.insert(lines,string.format("%-9s | %-16s | Bind ID %-6s | %s",r.verdict or "?",r.name or "Unknown",r.bindId>0 and r.bindId or "—",r.displayReason or r.reason or "No reason")) end
  end
  if auditUI.groupVerdict~="GROUP READY" then
    table.insert(lines,""); table.insert(lines,"POSSIBLE NEXT STEPS")
    table.insert(lines,"1. Resolve BLOCKED quest, level, item or achievement requirements, then re-audit.")
    table.insert(lines,"2. In Binds / Reset, select only incompatible resettable binds and review the batch preview.")
    table.insert(lines,"3. Do not reset permanent binds; wait for reset, change the roster, or separate incompatible Instance ID groups.")
    table.insert(lines,"4. Reinspect binds and run Group Audit again before entering.")
  end
  return table.concat(lines,"\n")
end

local function ShowAuditExport()
  local text=InstanceAuditReportText(); if not text then return end
  ShowSelectableReport("AzerCore Ops Instance access audit",text)
end

local function ShowAuditCopy()
  local text=InstanceAuditReportText(); if not text then return end
  ShowSelectableReport("Copy Instance access audit",text)
end

local function ShareAuditReport()
  local text=InstanceAuditReportText(); if not text then return end
  local f=EnsureShareFrame(); f:SetCapturedMessage(text,"INSTANCE",function() return InstanceAuditReportText(),"INSTANCE" end); f:Show(); f:Raise()
  SetStatus("Courier opened with the locked Instance Access report.")
end

local function AuditResultRow(parent)
  local row=CreateFrame("Button",nil,parent); row:SetHeight(27)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.075,.08,.095,.96)
  row.status=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.status:SetPoint("LEFT",6,0); row.status:SetWidth(66); row.status:SetJustifyH("LEFT")
  row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.name:SetPoint("LEFT",row.status,"RIGHT",6,0); row.name:SetWidth(92); row.name:SetJustifyH("LEFT"); row.name:SetTextColor(unpack(C.white))
  row.reason=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.reason:SetPoint("LEFT",row.name,"RIGHT",6,0); row.reason:SetPoint("RIGHT",-6,0); row.reason:SetJustifyH("LEFT"); row.reason:SetTextColor(unpack(C.white)); row.reason:SetWordWrap(false)
  row.header=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); row.header:SetPoint("LEFT",8,0); row.header:SetPoint("RIGHT",-8,0); row.header:SetJustifyH("LEFT"); row.header:SetTextColor(unpack(C.gold)); row.header:Hide()
  row:SetScript("OnEnter",function(self) if Settings().auditTooltips and self.data then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText((self.data.verdict or self.data.result or "?").." — "..(self.data.name or "Unknown"),1,.82,0); GameTooltip:AddLine(self.data.displayReason or self.data.reason or "No details",1,1,1,true); GameTooltip:AddLine("Raw module result: "..tostring(self.data.result or "?"),.65,.65,.65,true); GameTooltip:Show() end end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end); row:Hide(); return row
end

local function BuildInstances()
  local p=NewPage("Instances")
  local header=CreateFrame("Frame",nil,p); header:SetPoint("TOPLEFT",10,-8); header:SetPoint("TOPRIGHT",-10,-8); header:SetHeight(48); Backdrop(header,C.bg)
  local title=Label(header,"Instance Access","GameFontNormalLarge"); title:SetPoint("TOPLEFT",12,-8)
  local subtitle=header:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); subtitle:SetPoint("TOPLEFT",12,-28); subtitle:SetTextColor(unpack(C.white)); subtitle:SetText("Instance eligibility, prerequisites and group diagnostics")
  local context=header:CreateFontString(nil,"OVERLAY","GameFontNormal"); context:SetPoint("RIGHT",-14,0); context:SetTextColor(unpack(C.gold)); context:SetText("Group Audit")

  local auditPage=CreateFrame("Frame",nil,p); auditPage:SetPoint("TOPLEFT",0,-94); auditPage:SetPoint("BOTTOMRIGHT")
  local bindPage=CreateFrame("Frame",nil,p); bindPage:SetPoint("TOPLEFT",0,-94); bindPage:SetPoint("BOTTOMRIGHT"); bindPage:Hide(); instanceUI.bindPage=bindPage
  local diagnosticPage=CreateFrame("Frame",nil,p); diagnosticPage:SetPoint("TOPLEFT",0,-94); diagnosticPage:SetPoint("BOTTOMRIGHT"); diagnosticPage:Hide()
  local troubleshootingPage=CreateFrame("Frame",nil,p); troubleshootingPage:SetPoint("TOPLEFT",0,-94); troubleshootingPage:SetPoint("BOTTOMRIGHT"); troubleshootingPage:Hide()
  local auditTab,bindTab,diagnosticTab,troubleshootingTab
  local function ShowInstanceMode(mode)
    local access=mode=="ACCESS"; local binds=mode=="BINDS"; local diagnostics=mode=="DIAGNOSTICS"; local troubleshooting=mode=="TROUBLESHOOTING"
    if access then auditPage:Show() else auditPage:Hide() end
    if binds then bindPage:Show() else bindPage:Hide() end
    if diagnostics then diagnosticPage:Show() else diagnosticPage:Hide() end
    if troubleshooting then troubleshootingPage:Show() else troubleshootingPage:Hide() end
    instanceUI.autoInspect=binds
    auditTab:SetBackdropColor(unpack(access and C.selected or C.button)); auditTab:SetBackdropBorderColor(unpack(access and C.gold or C.border))
    bindTab:SetBackdropColor(unpack(binds and C.selected or C.button)); bindTab:SetBackdropBorderColor(unpack(binds and C.gold or C.border))
    diagnosticTab:SetBackdropColor(unpack(diagnostics and C.selected or C.button)); diagnosticTab:SetBackdropBorderColor(unpack(diagnostics and C.gold or C.border))
    troubleshootingTab:SetBackdropColor(unpack(troubleshooting and C.selected or C.button)); troubleshootingTab:SetBackdropBorderColor(unpack(troubleshooting and C.gold or C.border))
    context:SetText(access and "Group Audit" or (binds and "Binds / Reset" or (diagnostics and "Read-only Diagnostics" or "Reference Troubleshooting")))
    if binds then
      UpdateInstanceTargetIdentity()
      RenderInstances()
      if instanceUI.myLoadState=="UNLOADED" then RefreshMyInstances() end
      if SelectedPlayerName() and instanceUI.targetLoadState=="UNLOADED" then After(.30,function() InspectTargetInstances(false) end) end
    end
  end
  auditTab=Button(p,"Instance Access",140,24,function() ShowInstanceMode("ACCESS") end,"Check group and raid access to an instance"); auditTab:SetPoint("TOPLEFT",12,-65)
  bindTab=Button(p,"Binds / Reset",120,24,function() ShowInstanceMode("BINDS") end,"Inspect and safely remove instance binds"); bindTab:SetPoint("LEFT",auditTab,"RIGHT",8,0)
  diagnosticTab=Button(p,"Diagnostics",110,24,function() ShowInstanceMode("DIAGNOSTICS") end,"Inspect live encounter, boss, door and progression state without changing it"); diagnosticTab:SetPoint("LEFT",bindTab,"RIGHT",8,0)
  troubleshootingTab=Button(p,"Troubleshooting",125,24,function() ShowInstanceMode("TROUBLESHOOTING") end,"Research a WotLK raid or dungeon without entering it"); troubleshootingTab:SetPoint("LEFT",diagnosticTab,"RIGHT",8,0)
  auditTab:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(auditPage:IsShown() and C.selected or C.button)); self:SetBackdropBorderColor(unpack(auditPage:IsShown() and C.gold or C.border)); GameTooltip:Hide() end)
  bindTab:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(bindPage:IsShown() and C.selected or C.button)); self:SetBackdropBorderColor(unpack(bindPage:IsShown() and C.gold or C.border)); GameTooltip:Hide() end)
  diagnosticTab:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(diagnosticPage:IsShown() and C.selected or C.button)); self:SetBackdropBorderColor(unpack(diagnosticPage:IsShown() and C.gold or C.border)); GameTooltip:Hide() end)
  troubleshootingTab:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(troubleshootingPage:IsShown() and C.selected or C.button)); self:SetBackdropBorderColor(unpack(troubleshootingPage:IsShown() and C.gold or C.border)); GameTooltip:Hide() end)

  StaticPopupDialogs["AZERCORE_OPS_INSTANCE_SEARCH_HELP"]={
    text="Instance Search Help\n\nSearch using an exact Map ID, for example: 668\n\nOr enter a partial or complete instance title, for example: Halls or Halls of Reflection.\n\nSearch is not case-sensitive. Press Enter or click Search.",
    button1=OKAY,timeout=0,whileDead=1,hideOnEscape=1,preferredIndex=3,
  }

  local searchLabel=Section(auditPage,"Instance title or Map ID",C.gold); searchLabel:SetPoint("TOPLEFT",12,-5)
  Button(auditPage,"?",22,20,function() StaticPopup_Show("AZERCORE_OPS_INSTANCE_SEARCH_HELP") end,"How to search by instance title or Map ID"):SetPoint("TOPLEFT",172,-1)
  local searchBox=Edit(auditPage,305,false); searchBox:SetPoint("TOPLEFT",12,-23); searchBox.azerCoreOpsPlain=true; auditUI.searchBox=searchBox
  local function SearchInstances()
    local query=NonEmpty(searchBox,"an instance title or Map ID")
    if query then PushInstanceHistory(query); auditUI.search={}; auditUI.searchOffset=0; RenderAudit(); SendCommand(string.format(CMD.auditSearch,query)); SetStatus("Searching server instance maps...") end
  end
  Button(auditPage,"Search",70,24,SearchInstances,"Search by partial title or exact Map ID"):SetPoint("TOPLEFT",325,-23)
  searchBox:SetScript("OnEnterPressed",function(self) self:ClearFocus(); SearchInstances() end)

  local function ClearInstanceWorkspace()
    searchBox:SetText(""); auditUI.search={}; auditUI.searchOffset=0; auditUI.selectedMap=nil; auditUI.selectedName=nil; auditUI.selectedType=nil; auditUI.selectedMaxPlayers=nil
    auditUI.members={}; auditUI.filtered={}; auditUI.display={}; auditUI.lastMap=nil; auditUI.lastDifficulty=nil; auditUI.difficulty=0; auditUI.difficultyLabel="Normal"; auditUI.filter="ALL"; auditUI.referenceId=0; auditUI.generatedAt=nil; auditUI.stale=false; auditUI.groupVerdict="NOT AUDITED"; auditUI.groupReason="Run Group Audit"
    if auditUI.difficultyButton then auditUI.difficultyButton:SetText("Normal  v") end
    RenderAudit(); SetStatus("Instance Access workspace cleared.")
  end
  Button(auditPage,"Clear Workspace",108,24,ClearInstanceWorkspace,"Clear the search, locked instance and audit results"):SetPoint("TOPLEFT",403,-23)

  local function RunAudit()
    local map=tonumber(auditUI.selectedMap); local diff=tonumber(auditUI.difficulty)
    if not map then SetStatus("Search for and lock an instance before auditing the group.",true); return end
    auditUI.lastMap=map; auditUI.lastDifficulty=diff; auditUI.members={}; auditUI.display={}; auditUI.generatedAt=nil; auditUI.stale=false; auditUI.groupVerdict="AUDITING"; auditUI.groupReason="Collecting live group access data"; RenderAudit(); SendCommand(string.format(CMD.auditGroup,map,diff)); SetStatus("Auditing group access to "..(auditUI.selectedName or ("map "..map)).."...")
  end

  local searchPanel=CreateFrame("Frame",nil,auditPage); searchPanel:SetPoint("TOPLEFT",12,-57); searchPanel:SetPoint("BOTTOMLEFT",12,10); searchPanel:SetWidth(215); Backdrop(searchPanel,C.panel)
  local sh=Section(searchPanel,"INSTANCE MATCHES",C.gold); sh:SetPoint("TOPLEFT",8,-8)
  local function ScrollInstanceMatches(delta)
    local maxOffset=math.max(0,#auditUI.search-5); auditUI.searchOffset=math.max(0,math.min(maxOffset,(auditUI.searchOffset or 0)+delta)); RenderAudit()
  end
  Button(searchPanel,"^",18,18,function() ScrollInstanceMatches(-1) end,"Scroll matches up"):SetPoint("TOPRIGHT",-4,-28)
  Button(searchPanel,"v",18,18,function() ScrollInstanceMatches(1) end,"Scroll matches down"):SetPoint("TOPRIGHT",-4,-225)
  searchPanel:EnableMouseWheel(true); searchPanel:SetScript("OnMouseWheel",function(_,delta) ScrollInstanceMatches(delta>0 and -1 or 1) end)
  for i=1,5 do
    local row=Button(searchPanel,"",183,38,function(self)
      local r=self.data; if not r then return end
      auditUI.selectedMap=tonumber(r.map); auditUI.selectedName=r.name; auditUI.selectedType=r.type; auditUI.selectedMaxPlayers=r.max; auditUI.difficulty=0; auditUI.difficultyLabel=(r.type=="raid" and "10-player Normal" or "Normal")
      if #auditUI.members>0 and tonumber(auditUI.lastMap)~=tonumber(r.map) then auditUI.stale=true end
      if auditUI.difficultyButton then auditUI.difficultyButton:SetText(auditUI.difficultyLabel.."  v") end
      searchBox:SetText(r.name or tostring(r.map)); PushInstanceHistory(searchBox:GetText(),r.map,r.name,r.type,r.max); RenderAudit(); SetStatus("Locked "..(r.name or "instance").." — Map "..tostring(r.map))
    end)
    row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.label:SetPoint("TOPLEFT",6,-3); row.label:SetPoint("BOTTOMRIGHT",-6,3); row.label:SetJustifyH("LEFT"); row.label:SetJustifyV("TOP"); row.label:SetWordWrap(true); row.label:SetTextColor(unpack(C.gold))
    row:SetScript("OnLeave",function(self) local selected=tonumber(self.id)==tonumber(auditUI.selectedMap); self:SetBackdropColor(unpack(selected and C.selected or C.button)); self:SetBackdropBorderColor(unpack(selected and C.gold or C.border)); GameTooltip:Hide() end)
    row:SetPoint("TOPLEFT",8,-29-(i-1)*40); row:Hide(); auditUI.searchRows[i]=row
  end
  local locked=CreateFrame("Frame",nil,searchPanel); locked:SetPoint("TOPLEFT",7,-249); locked:SetPoint("BOTTOMRIGHT",-7,7); Backdrop(locked,C.bg)
  local lh=Section(locked,"LOCKED INSTANCE",C.gold); lh:SetPoint("TOPLEFT",8,-8)
  auditUI.lockedText=locked:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); auditUI.lockedText:SetPoint("TOPLEFT",8,-34); auditUI.lockedText:SetPoint("BOTTOMRIGHT",-8,38); auditUI.lockedText:SetJustifyH("LEFT"); auditUI.lockedText:SetJustifyV("TOP"); auditUI.lockedText:SetWordWrap(true); auditUI.lockedText:SetTextColor(unpack(C.white))
  Button(locked,"History",68,22,ShowSavedInstanceHistory,"Open saved instance searches and Map IDs"):SetPoint("BOTTOMLEFT",8,8)
  Button(locked,"<",24,22,function() ShowInstanceHistory(1) end,"Previous saved instance search"):SetPoint("BOTTOMLEFT",80,8)
  Button(locked,">",24,22,function() ShowInstanceHistory(-1) end,"Next saved instance search"):SetPoint("BOTTOMLEFT",108,8)

  local resultPanel=CreateFrame("Frame",nil,auditPage); resultPanel:SetPoint("TOPLEFT",235,-57); resultPanel:SetPoint("BOTTOMRIGHT",-12,10); Backdrop(resultPanel,C.panel)
  local rh=Section(resultPanel,"GROUP ACCESS",C.gold); rh:SetPoint("TOPLEFT",10,-10)

  local diffLabel=Label(resultPanel,"Difficulty","GameFontNormalSmall"); diffLabel:SetPoint("TOPLEFT",10,-34)
  local difficultyButtons={}
  local diffButton=Button(resultPanel,"Normal  v",132,22,function()
    if auditUI.difficultyMenu:IsShown() then auditUI.difficultyMenu:Hide() else
      for _,b in ipairs(difficultyButtons) do local label=(auditUI.selectedType=="raid" and b.raidLabel or b.normalLabel); b.display=label; b:SetText(label or "Unavailable"); b:SetEnabled(label~=nil) end
      auditUI.difficultyMenu:Show(); auditUI.difficultyMenu:Raise()
    end
  end,"Choose a readable dungeon or raid difficulty"); diffButton:SetPoint("TOPLEFT",72,-29); auditUI.difficultyButton=diffButton
  local diffMenu=CreateFrame("Frame",nil,resultPanel); diffMenu:SetWidth(170); diffMenu:SetHeight(112); diffMenu:SetPoint("TOPLEFT",diffButton,"BOTTOMLEFT",0,-2); diffMenu:SetFrameStrata("FULLSCREEN_DIALOG"); diffMenu:SetFrameLevel(250); Backdrop(diffMenu,C.panel); diffMenu:Hide(); auditUI.difficultyMenu=diffMenu
  local difficultyOptions={{0,"Normal","10-player Normal"},{1,"Heroic","25-player Normal"},{2,nil,"10-player Heroic"},{3,nil,"25-player Heroic"}}
  for i,opt in ipairs(difficultyOptions) do
    local b=Button(diffMenu,"",158,22,function(self)
      if #auditUI.members>0 and tonumber(auditUI.lastDifficulty)~=tonumber(self.value) then auditUI.stale=true end
      auditUI.difficulty=self.value; auditUI.difficultyLabel=self.display; diffButton:SetText(self.display.."  v"); diffMenu:Hide(); RenderAudit(); SetStatus("Difficulty set to "..self.display)
    end); b:SetPoint("TOPLEFT",6,-6-(i-1)*25); b.value=opt[1]; b.normalLabel=opt[2]; b.raidLabel=opt[3]
    table.insert(difficultyButtons,b)
  end
  Button(resultPanel,"Audit Group",92,22,RunAudit,"Check every party or raid member"):SetPoint("TOPLEFT",212,-29)
  Button(resultPanel,"Re-audit",70,20,function() if auditUI.lastMap then RunAudit() else SetStatus("Run an audit first.",true) end end,"Repeat the last group audit"):SetPoint("TOPRIGHT",-10,-29)

  auditUI.summary=resultPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); auditUI.summary:SetPoint("TOPLEFT",10,-82); auditUI.summary:SetPoint("TOPRIGHT",-10,-82); auditUI.summary:SetJustifyH("RIGHT"); auditUI.summary:SetTextColor(unpack(C.white))
  local auditFilters={
    {"ALL","ALL",38,"Show every inspected member"},
    {"CAN JOIN","CAN_JOIN",64,"Show players who can enter with the group"},
    {"CANNOT JOIN","CANNOT_JOIN",80,"Show blocked players and Instance ID conflicts"},
    {"OFFLINE","OFFLINE",54,"Show players who could not be inspected"},
    {"SAME ID","SAME_ID",56,"Show players already saved to the group Instance ID"},
    {"DIFFERENT ID","DIFFERENT_ID",76,"Show players saved to a conflicting Instance ID"},
    {"NO BIND","NO_BIND",58,"Show online players without a personal bind"},
  }
  local auditFilterX=10
  for _,spec in ipairs(auditFilters) do
    local label,filterName,width,tip=spec[1],spec[2],spec[3],spec[4]
    local filterButton=Button(resultPanel,label,width,18,function() auditUI.filter=filterName; if Settings().rememberAuditFilter then AzerCoreOpsDB.auditFilter=filterName end; RenderAudit() end,tip)
    filterButton:SetPoint("TOPLEFT",auditFilterX,-58); auditFilterX=auditFilterX+width+4; auditUI.filterButtons[filterName]=filterButton
    filterButton:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(filterName==auditUI.filter and C.selected or C.button)); GameTooltip:Hide() end)
  end
  local columns=CreateFrame("Frame",nil,resultPanel); columns:SetPoint("TOPLEFT",8,-101); columns:SetPoint("TOPRIGHT",-28,-101); columns:SetHeight(20); Backdrop(columns,C.bg)
  local cs=Label(columns,"VERDICT","GameFontNormalSmall"); cs:SetPoint("LEFT",6,0)
  local cn=Label(columns,"PLAYER","GameFontNormalSmall"); cn:SetPoint("LEFT",78,0)
  local cr=Label(columns,"INSTANCE ID / ACCESS RESULT / SOLUTION","GameFontNormalSmall"); cr:SetPoint("LEFT",176,0)
  local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_AuditResultScroll",resultPanel,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",8,-123); scroll:SetPoint("BOTTOMRIGHT",-28,58); auditUI.scroll=scroll
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(820); child:SetHeight(1); scroll:SetScrollChild(child); auditUI.scrollChild=child
  auditUI.memberRows={}
  for i=1,60 do auditUI.memberRows[i]=AuditResultRow(child); auditUI.memberRows[i]:Hide() end
  scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) if Settings().mouseWheelAudit then self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*80)) end end)
  local hs=CreateFrame("Slider","AZERCORE_OPS_InstanceAuditHorizontalScroll",resultPanel,"OptionsSliderTemplate"); hs:SetPoint("BOTTOMLEFT",resultPanel,"BOTTOMLEFT",12,39); hs:SetPoint("BOTTOMRIGHT",resultPanel,"BOTTOMRIGHT",-12,39); hs:SetHeight(16); hs:SetMinMaxValues(0,455); hs:SetValueStep(10); hs:SetValue(0); auditUI.horizontal=hs
  _G[hs:GetName().."Low"]:SetText(""); _G[hs:GetName().."High"]:SetText(""); _G[hs:GetName().."Text"]:SetText("")
  hs:SetScript("OnValueChanged",function(_,value) if auditUI.scroll then auditUI.scroll:SetHorizontalScroll(value) end end)
  local footer=CreateFrame("Frame",nil,resultPanel); footer:SetPoint("BOTTOMLEFT",8,7); footer:SetPoint("BOTTOMRIGHT",-8,7); footer:SetHeight(28); Backdrop(footer,C.bg)
  local legend=Label(footer,"GRANTED allowed  •  CONFLICT ID mismatch  •  BLOCKED denied","GameFontHighlightSmall"); legend:SetTextColor(unpack(C.white)); legend:SetPoint("LEFT",7,0); legend:SetWidth(330); legend:SetJustifyH("LEFT")
  Button(footer,"Copy",48,20,ShowAuditCopy,"Open the full audit as selected text"):SetPoint("RIGHT",-128,0)
  Button(footer,"Share",54,20,ShareAuditReport,"Open the Quest-style Courier share window with this audit"):SetPoint("RIGHT",-70,0)
  Button(footer,"Export",62,20,ShowAuditExport,"Open the complete selectable audit report"):SetPoint("RIGHT",-4,0)

  local operations=CreateFrame("Frame",nil,bindPage); operations:SetPoint("TOPLEFT",12,-4); operations:SetPoint("BOTTOMLEFT",12,33); operations:SetWidth(130); Backdrop(operations,C.panel)
  local oh=Section(operations,"OPERATIONS",C.gold); oh:SetPoint("TOPLEFT",8,-9)
  Button(operations,"Refresh Binds",114,24,function()
    LogBindActivity("Bind refresh requested","REFRESH"); RefreshMyInstances(); if SelectedPlayerName() then After(.15,InspectTargetInstances) else SetStatus("My Binds refreshed; select a player to refresh Target Binds.") end
  end,"Refresh My Binds and, when a player is selected, Target Binds"):SetPoint("TOPLEFT",8,-31)
  instanceUI.inspectButton=Button(operations,"Inspect Target",114,24,function() InspectTargetInstances(true); UpdateBindControls() end,"Keep target inspection active while moving through party or raid members"); instanceUI.inspectButton:SetPoint("TOPLEFT",8,-63)
  instanceUI.inspectButton:SetScript("OnLeave",function() UpdateBindControls(); GameTooltip:Hide() end)
  instanceUI.unbindSelectedButton=Button(operations,"Unbind Selected",114,24,function()
    local rows=SelectedTargetBinds(); if #rows==0 then SetStatus("Select one or more target binds using their checkboxes.",true); return end
    if not RequireSelectedPlayer() then return end
    LogBindActivity("Batch preview: "..#rows.." selected bind(s) for "..tostring(SelectedPlayerName()),"PREVIEW"); ConfirmUnbindRows(rows,Settings().confirmResetSelected)
  end,"Remove the selected target bind after confirmation"); instanceUI.unbindSelectedButton:SetPoint("TOPLEFT",8,-95)
  instanceUI.bindDetailsButton=Button(operations,"Bind Details",114,24,ShowBindDetails,"Open the complete details for the selected personal or target bind"); instanceUI.bindDetailsButton:SetPoint("TOPLEFT",8,-127)
  Button(operations,"Bind Activity",114,24,ShowBindActivity,"View bind inspection, selection, filtering and operation activity"):SetPoint("TOPLEFT",8,-159)
  local future=Button(operations,"Bind to ID",114,24,function() end,"Not enabled — under consideration. Assigning an Instance ID requires additional safety validation."); future:SetPoint("TOPLEFT",8,-191); future:SetEnabled(false)
  local futureNote=Label(operations,"Not enabled\nUnder consideration","GameFontHighlightSmall"); futureNote:SetTextColor(unpack(C.muted)); futureNote:SetPoint("TOPLEFT",8,-222); futureNote:SetWidth(114); futureNote:SetJustifyH("CENTER")

  local summary=CreateFrame("Frame",nil,bindPage); summary:SetPoint("TOPLEFT",150,-4); summary:SetPoint("TOPRIGHT",-12,-4); summary:SetHeight(82); Backdrop(summary,C.bg)
  instanceUI.targetHeader=Section(summary,"SELECTED TARGET",C.gold); instanceUI.targetHeader:SetPoint("TOPRIGHT",-9,-7); instanceUI.targetHeader:SetWidth(210); instanceUI.targetHeader:SetJustifyH("RIGHT")
  instanceUI.targetPortraitFrame=CreateFrame("Frame",nil,summary); instanceUI.targetPortraitFrame:SetPoint("TOPRIGHT",-9,-25); instanceUI.targetPortraitFrame:SetWidth(210); instanceUI.targetPortraitFrame:SetHeight(52); Backdrop(instanceUI.targetPortraitFrame,C.bg)
  instanceUI.targetPortrait=instanceUI.targetPortraitFrame:CreateTexture(nil,"ARTWORK"); instanceUI.targetPortrait:SetWidth(42); instanceUI.targetPortrait:SetHeight(42); instanceUI.targetPortrait:SetPoint("LEFT",5,0); instanceUI.targetPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  instanceUI.targetIdentityName=instanceUI.targetPortraitFrame:CreateFontString(nil,"OVERLAY","GameFontNormal"); instanceUI.targetIdentityName:SetPoint("TOPLEFT",54,-8); instanceUI.targetIdentityName:SetPoint("TOPRIGHT",-8,-8); instanceUI.targetIdentityName:SetJustifyH("LEFT"); instanceUI.targetIdentityName:SetTextColor(unpack(C.white)); instanceUI.targetIdentityName:SetText("No player selected")
  instanceUI.targetIdentityMeta=instanceUI.targetPortraitFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); instanceUI.targetIdentityMeta:SetPoint("TOPLEFT",54,-25); instanceUI.targetIdentityMeta:SetPoint("BOTTOMRIGHT",-8,5); instanceUI.targetIdentityMeta:SetJustifyH("LEFT"); instanceUI.targetIdentityMeta:SetJustifyV("TOP"); instanceUI.targetIdentityMeta:SetTextColor(unpack(C.muted)); instanceUI.targetIdentityMeta:SetText("Select a player target")
  instanceUI.targetPortraitFrame:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    local t=instanceUI.targetIdentity
    if t then
      GameTooltip:SetText(t.name,1,.82,0); GameTooltip:AddLine(string.format("Level %s %s %s",tostring(t.level),t.race,t.class),1,1,1)
      if t.guild then GameTooltip:AddLine("Guild: "..t.guild,.7,.85,1) end
      GameTooltip:AddLine("Selected target",.65,.65,.65)
    else GameTooltip:SetText("No player selected",1,.82,0); GameTooltip:AddLine("Select a player to inspect their instance binds.",1,1,1,true) end
    GameTooltip:Show()
  end); instanceUI.targetPortraitFrame:SetScript("OnLeave",function() GameTooltip:Hide() end)
  UpdateInstanceTargetIdentity()
  local function SetBindView(view) instanceUI.view=view; instanceUI.selectedBind=nil; instanceUI.myOffset=0; instanceUI.targetOffset=0; LogBindActivity("Workspace changed to "..(view=="LOCKED" and "Locked Binds" or "Binds Overview"),"VIEW"); RenderInstances() end
  instanceUI.viewButtons={}
  instanceUI.viewButtons.OVERVIEW=Button(summary,"Binds Overview",112,24,function() SetBindView("OVERVIEW") end,"Show personal and target bind overviews"); instanceUI.viewButtons.OVERVIEW:SetPoint("TOPLEFT",9,-7)
  instanceUI.viewButtons.LOCKED=Button(summary,"Locked Binds",100,24,function() SetBindView("LOCKED") end,"Hide the overview and show personal and target locked binds"); instanceUI.viewButtons.LOCKED:SetPoint("LEFT",instanceUI.viewButtons.OVERVIEW,"RIGHT",7,0)
  instanceUI.summaryText=Label(summary,"Total  0        Boss lockouts  0        Temporary  0        Resettable  0","GameFontHighlightSmall"); instanceUI.summaryText:SetTextColor(unpack(C.white)); instanceUI.summaryText:SetPoint("TOPLEFT",9,-38); instanceUI.summaryText:SetWidth(390); instanceUI.summaryText:SetJustifyH("LEFT")
  local bindFilters={{"ALL","ALL",54},{"RAID","RAID",54},{"DUNGEON","DUNGEON",76},{"LOCKOUT","PERMANENT",76},{"RESETTABLE","RESETTABLE",88}}
  local filterX=9
  for _,spec in ipairs(bindFilters) do
    local label,filterName,width=spec[1],spec[2],spec[3]
    local b=Button(summary,label,width,20,function() instanceUI.filter=filterName; instanceUI.myOffset=0; instanceUI.targetOffset=0; LogBindActivity("Filter changed to "..filterName,"FILTER"); RenderInstances() end,"Show "..label:lower().." binds"); b:SetPoint("TOPLEFT",filterX,-57); instanceUI.filterButtons[filterName]=b; filterX=filterX+width+5
    b:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(filterName==instanceUI.filter and C.selected or C.button)); self:SetBackdropBorderColor(unpack(filterName==instanceUI.filter and C.gold or C.border)); GameTooltip:Hide() end)
  end

  local bindContent=CreateFrame("Frame",nil,bindPage); bindContent:SetPoint("TOPLEFT",150,-91); bindContent:SetPoint("BOTTOMRIGHT",-12,33)
  local myBox=CreateFrame("Frame",nil,bindContent); myBox:SetPoint("TOPLEFT",0,0); myBox:SetPoint("BOTTOMRIGHT",bindContent,"BOTTOM",-4,0); Backdrop(myBox,C.panel)
  instanceUI.myHeading=Section(myBox,"MY BINDS",C.gold); instanceUI.myHeading:SetPoint("TOPLEFT",8,-8)
  local myScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_MyBindScroll",myBox,"UIPanelScrollFrameTemplate"); myScroll:SetPoint("TOPLEFT",7,-28); myScroll:SetPoint("BOTTOMRIGHT",-27,29); instanceUI.myScroll=myScroll
  local myChild=CreateFrame("Frame",nil,myScroll); myChild:SetWidth(430); myChild:SetHeight(1200); myScroll:SetScrollChild(myChild)
  instanceUI.myRows={}; for i=1,20 do instanceUI.myRows[i]=BindRow(myChild,-2-(i-1)*66,
    function(self) if self.data then instanceUI.selectedBind=self.data; instanceUI.selectedBindOwner="SELF"; LogBindActivity("Opened personal bind ID "..tostring(self.data.instance or "?"),"SELECT"); RenderInstances(); SetStatus("Selected personal bind ID "..tostring(self.data.instance or "?")..". Click Bind Details for the complete report.") end end) end
  instanceUI.myEmpty=Label(myBox,"No binds found","GameFontHighlightSmall"); instanceUI.myEmpty:SetPoint("CENTER",0,0); instanceUI.myEmpty:SetTextColor(unpack(C.muted))

  local targetBox=CreateFrame("Frame",nil,bindContent); targetBox:SetPoint("TOPLEFT",bindContent,"TOP",4,0); targetBox:SetPoint("BOTTOMRIGHT",0,0); Backdrop(targetBox,C.panel)
  instanceUI.targetLabel=Section(targetBox,"TARGET BINDS — none",C.gold); instanceUI.targetLabel:SetPoint("TOPLEFT",8,-8)
  local targetScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_TargetBindScroll",targetBox,"UIPanelScrollFrameTemplate"); targetScroll:SetPoint("TOPLEFT",7,-28); targetScroll:SetPoint("BOTTOMRIGHT",-27,29); instanceUI.targetScroll=targetScroll
  local targetChild=CreateFrame("Frame",nil,targetScroll); targetChild:SetWidth(430); targetChild:SetHeight(1200); targetScroll:SetScrollChild(targetChild)
  instanceUI.targetRows={}; for i=1,20 do instanceUI.targetRows[i]=BindRow(targetChild,-2-(i-1)*66,
    function(self) if self.data then instanceUI.selectedBind=self.data; instanceUI.selectedBindOwner="TARGET"; LogBindActivity("Opened target bind ID "..tostring(self.data.instance or "?"),"SELECT"); RenderInstances(); SetStatus("Selected target bind ID "..tostring(self.data.instance or "?")..". Click Bind Details for the complete report.") end end,
    function(row,checked)
      local r=row.data; if not r then return end
      if checked and not BindApplicable(r) then r.selected=false; row.check:SetChecked(false); StaticPopup_Show("AZERCORE_OPS_BIND_NOT_APPLICABLE",r.reason or "The module reported that unbinding is not applicable."); LogBindActivity("Selection refused for ID "..tostring(r.instance)..": "..tostring(r.reason),"BLOCKED")
      else r.selected=checked and true or false; LogBindActivity((r.selected and "Selected " or "Unselected ").."bind ID "..tostring(r.instance),"SELECT") end
      UpdateBindControls()
    end) end
  instanceUI.targetEmpty=Label(targetBox,"No binds found","GameFontHighlightSmall"); instanceUI.targetEmpty:SetPoint("CENTER",0,0); instanceUI.targetEmpty:SetTextColor(unpack(C.muted))

  local function BindPanelSlider(parent,name,scroll,bottom,maxValue)
    local slider=CreateFrame("Slider",name,parent,"OptionsSliderTemplate"); slider:SetPoint("BOTTOMLEFT",10,bottom); slider:SetPoint("BOTTOMRIGHT",-10,bottom); slider:SetHeight(14); slider:SetMinMaxValues(0,maxValue); slider:SetValueStep(5); slider:SetValue(0)
    _G[name.."Low"]:SetText(""); _G[name.."High"]:SetText(""); _G[name.."Text"]:SetText("")
    slider:SetScript("OnValueChanged",function(_,value) scroll:SetHorizontalScroll(value) end); table.insert(instanceUI.horizontals,slider); return slider
  end
  instanceUI.horizontals={}
  BindPanelSlider(myBox,"AZERCORE_OPS_MyBindHorizontalScroll",myScroll,7,110)
  BindPanelSlider(targetBox,"AZERCORE_OPS_TargetBindHorizontalScroll",targetScroll,7,110)

  local bindFooter=CreateFrame("Frame",nil,bindPage); bindFooter:SetPoint("BOTTOMLEFT",150,2); bindFooter:SetPoint("BOTTOMRIGHT",-12,2); bindFooter:SetHeight(27); Backdrop(bindFooter,C.bg)
  instanceUI.statusText=Label(bindFooter,"Personal binds ready","GameFontHighlightSmall"); instanceUI.statusText:SetTextColor(unpack(C.white)); instanceUI.statusText:SetPoint("LEFT",7,0); instanceUI.statusText:SetWidth(300); instanceUI.statusText:SetJustifyH("LEFT")
  Button(bindFooter,"Copy",48,20,CopyBindReport,"Open the complete bind report as selectable text"):SetPoint("RIGHT",-128,0)
  Button(bindFooter,"Share",54,20,ShareBindReport,"Open the Courier share window with the bind report"):SetPoint("RIGHT",-70,0)
  Button(bindFooter,"Export",62,20,ExportBindReport,"Export the complete visible bind report"):SetPoint("RIGHT",-4,0)

  local diagnosticScroll, diagnosticScan, diagnosticHistoryButton, diagnosticClear, diagnosticOlder, diagnosticNewer, recoveryButton
  local diagnosticControls=CreateFrame("Frame",nil,diagnosticPage); diagnosticControls:SetPoint("TOPLEFT",12,-5); diagnosticControls:SetPoint("BOTTOMLEFT",12,10); diagnosticControls:SetWidth(180); Backdrop(diagnosticControls,C.panel)
  local diagnosticHeading=Section(diagnosticControls,"ENCOUNTER SCAN",C.gold); diagnosticHeading:SetPoint("TOPLEFT",10,-10)
  local diagnosticHelp=diagnosticControls:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); diagnosticHelp:SetPoint("TOPLEFT",10,-39); diagnosticHelp:SetPoint("TOPRIGHT",-10,-39); diagnosticHelp:SetJustifyH("LEFT"); diagnosticHelp:SetJustifyV("TOP"); diagnosticHelp:SetWordWrap(true); diagnosticHelp:SetTextColor(unpack(C.white)); diagnosticHelp:SetText("Enter the affected dungeon or raid. Target the boss or event NPC for extra evidence, then run the scan.\n\nThis workspace never changes encounter state, doors, creatures or lockouts.")
  diagnosticScan=Button(diagnosticControls,"Scan Current Instance",156,28,function()
    instanceUI.diagnostics={findings={},recoveries={},loading=true,header=nil,summary=nil,error=nil,generatedAt=nil,historyIndex=0,mode="SCAN"}
    if diagnosticScroll then diagnosticScroll:SetVerticalScroll(0) end
    if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
    SendCommand(CMD.instanceDiagnose); SetStatus("Collecting live encounter evidence...")
  end,"Run a read-only server scan of the current instance"); diagnosticScan:SetPoint("TOPLEFT",12,-145)

  diagnosticHistoryButton=Button(diagnosticControls,"Encounter History",156,28,function()
    instanceUI.diagnostics.mode="HISTORY"
    instanceUI.encounterHistory={entries={},stats={},loading=true,header=nil,summary=nil,error=nil,generatedAt=nil}
    if diagnosticScroll then diagnosticScroll:SetVerticalScroll(0) end
    if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
    SendCommand(CMD.instanceHistory); SetStatus("Loading server encounter-state history...")
  end,"Show server-captured encounter state transitions for the current live instance"); diagnosticHistoryButton:SetPoint("TOPLEFT",12,-181)

  diagnosticClear=Button(diagnosticControls,"Clear",72,22,function()
    instanceUI.diagnostics={findings={},recoveries={},loading=false,header=nil,summary=nil,error=nil,generatedAt=nil,historyIndex=0,mode="SCAN"}
    instanceUI.encounterHistory={entries={},stats={},loading=false,header=nil,summary=nil,error=nil,generatedAt=nil}
    if diagnosticScroll then diagnosticScroll:SetVerticalScroll(0) end
    instanceUI.RenderDiagnostics()
    SetStatus("Encounter diagnostics cleared.")
  end,"Clear the displayed encounter evidence"); diagnosticClear:SetPoint("TOPLEFT",12,-217)

  local function LoadDiagnosticHistory(delta)
    AzerCoreOpsDB.diagnosticHistory=AzerCoreOpsDB.diagnosticHistory or {}
    if #AzerCoreOpsDB.diagnosticHistory==0 then SetStatus("No saved diagnostic scans yet.",true); return end
    local index=math.max(1,math.min(#AzerCoreOpsDB.diagnosticHistory,(instanceUI.diagnostics.historyIndex or 0)+delta))
    local saved=AzerCoreOpsDB.diagnosticHistory[index]
    instanceUI.diagnostics={findings=saved.findings or {},recoveries=saved.recoveries or {},loading=false,header=saved.header,summary=saved.summary,error=saved.error,generatedAt=saved.generatedAt,historyIndex=index,historical=true,mode="SCAN"}
    if diagnosticScroll then diagnosticScroll:SetVerticalScroll(0) end
    instanceUI.RenderDiagnostics()
    SetStatus(string.format("Viewing diagnostic history %d of %d — %s",index,#AzerCoreOpsDB.diagnosticHistory,saved.generatedAt or "unknown time"))
  end
  diagnosticOlder=Button(diagnosticControls,"< Older",72,22,function() LoadDiagnosticHistory(1) end,"Open an older saved diagnostic scan"); diagnosticOlder:SetPoint("TOPLEFT",12,-249)
  diagnosticNewer=Button(diagnosticControls,"Newer >",72,22,function() LoadDiagnosticHistory(-1) end,"Open a newer saved diagnostic scan"); diagnosticNewer:SetPoint("TOPLEFT",90,-249)

  local diagnosticPanel=CreateFrame("Frame",nil,diagnosticPage); diagnosticPanel:SetPoint("TOPLEFT",200,-5); diagnosticPanel:SetPoint("BOTTOMRIGHT",-12,10); Backdrop(diagnosticPanel,C.panel)
  local diagnosticTitle=Section(diagnosticPanel,"LIVE ENCOUNTER EVIDENCE",C.gold); diagnosticTitle:SetPoint("TOPLEFT",10,-10)
  diagnosticScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_EncounterDiagnosticScroll",diagnosticPanel,"UIPanelScrollFrameTemplate"); diagnosticScroll:SetPoint("TOPLEFT",10,-32); diagnosticScroll:SetPoint("BOTTOMRIGHT",-28,36)
  local diagnosticChild=CreateFrame("Frame",nil,diagnosticScroll); diagnosticChild:SetWidth(650); diagnosticChild:SetHeight(500); diagnosticScroll:SetScrollChild(diagnosticChild)
  local diagnosticText=diagnosticChild:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); diagnosticText:SetPoint("TOPLEFT",2,-2); diagnosticText:SetWidth(640); diagnosticText:SetJustifyH("LEFT"); diagnosticText:SetJustifyV("TOP"); diagnosticText:SetWordWrap(true)

  local function EncounterHistoryTime(value)
    local milliseconds=tonumber(value)
    if not milliseconds then return "unknown" end
    return date("%m-%d %H:%M:%S",math.floor(milliseconds/1000))
  end

  local function EncounterHistoryClassLabel(classification,plain)
    local colors={
      NORMAL="|cff40ff40",
      INITIALIZATION="|cff80dfff",
      RESET_STEP="|cffffff00",
      WIPE_CHAIN="|cffff8030",
      SUSPICIOUS="|cffff4040",
      INFO="|cffb0b0b0"
    }
    classification=tostring(classification or "INFO")
    if plain then return "["..classification.."]" end
    return (colors[classification] or "|cffffffff").."["..classification.."]|r"
  end

  local function EncounterHistoryStateLabel(name,id,plain)
    name=tostring(name or "UNKNOWN")
    id=tostring(id or "?")
    local text=name.." ["..id.."]"

    if plain then return text end

    local colors={
      DONE="|cff40ff40",
      FAIL="|cffff4040",
      IN_PROGRESS="|cff00bfff",
      NOT_STARTED="|cffc0c0c0",
      TO_BE_DECIDED="|cff80dfff"
    }

    return (colors[name] or "|cffffffff")..text.."|r"
  end

  local function EncounterHistoryEventLabel(entry,plain)
    local event=tostring(entry.event or "STATE")
    local label=nil
    local color="|cffffffff"

    if event=="PULL" then
      local n=tonumber(entry.attempt) or 0
      label=n>0 and ("PULL #"..n) or "PULL"
      color="|cff00bfff"

    elseif event=="WIPE" then
      local n=tonumber(entry.wipes) or 0
      label=n>0 and ("WIPE #"..n) or "WIPE"
      color="|cffff8030"

    elseif event=="RESET" then
      label="RESET"
      color="|cffffff00"

    elseif event=="KILL" then
      label="KILL"
      color="|cff40ff40"
    end

    if not label then
      return EncounterHistoryClassLabel(entry.class,plain)
    end

    if plain then return "["..label.."]" end
    return color.."["..label.."]|r"
  end

  local function EncounterHistoryReport(plain)
    local h=instanceUI.encounterHistory or {}
    local entries=h.entries or {}
    local stats=h.stats or {}
    local initial,live={},{}
    local lines={}
    local function add(value) table.insert(lines,value) end

    for _,entry in ipairs(entries) do
      if tostring(entry.class or "") == "INITIALIZATION" then
        table.insert(initial,entry)
      else
        table.insert(live,entry)
      end
    end

    if h.header then
      add(string.format("%s — Map %s, Instance %s, Difficulty %s",
        h.header.name or "Current instance",
        h.header.map or "?",
        h.header.instance or "?",
        h.header.difficulty or "?"))
    end

    local count=h.summary and (tonumber(h.summary.count) or #entries) or #entries
    local anomalies=h.summary and (tonumber(h.summary.anomalies) or 0) or 0

    if h.header or h.summary then
      add(string.format("%d state signals  |  %d suspicious",count,anomalies))
      add(plain and
        "Server-captured SetBossState signals." or
        "|cffb0b0b0Server-captured SetBossState signals.|r")
      add("")
    end

    if h.loading then
      add(plain and
        "Loading encounter history..." or
        "|cffffff00Loading encounter history...|r")
      add("")
    end

    if h.error then
      add((plain and "ERROR: " or "|cffff4040ERROR: |r")..tostring(h.error))
      add("")
    end

    if not h.loading and not h.error and #entries==0 then
      add("No encounter state transitions have been captured for this live instance yet.")
      add("")
      add("History is captured server-side from state changes that occur after the updated worldserver starts.")
      return table.concat(lines,"\n")
    end

    if #stats>0 then
      add(plain and
        "ATTEMPT SUMMARY" or
        "|cffffd100ATTEMPT SUMMARY|r")

      for _,s in ipairs(stats) do
        local name=tostring(
          s.name or
          ("Encounter "..tostring(s.id or "?")))

        local attempts=tonumber(s.attempts) or 0
        local wipes=tonumber(s.wipes) or 0
        local kills=tonumber(s.kills) or 0

        if plain then
          add(string.format(
            "%s — Attempts %d  |  Wipes %d  |  Kills %d",
            name,attempts,wipes,kills))
        else
          add(string.format(
            "%s — |cff00bfffAttempts %d|r  |  |cffff8030Wipes %d|r  |  |cff40ff40Kills %d|r",
            name,attempts,wipes,kills))
        end
      end

      add("")
    end

    add(plain and
      "LIVE TRANSITIONS" or
      "|cffffd100LIVE TRANSITIONS|r")

    if #live==0 then
      add("No live encounter transitions captured yet.")
    else
      for _,entry in ipairs(live) do
        local classification=tostring(entry.class or "INFO")

        add(string.format(
          "#%s  %s  %s",
          tostring(entry.seq or "?"),
          EncounterHistoryTime(entry.time),
          tostring(entry.name or
            ("Encounter "..tostring(entry.id or "?")))))

        add(string.format(
          "  %s  %s  ->  %s",
          EncounterHistoryEventLabel(entry,plain),
          EncounterHistoryStateLabel(
            entry.oldname,entry.old,plain),
          EncounterHistoryStateLabel(
            entry.newname,entry.new,plain)))

        if classification~="NORMAL" and
           entry.detail and
           entry.detail~="" then
          add("  "..tostring(entry.detail))
        end

        add("")
      end
    end

    if #initial>0 then
      add(plain and
        "INITIAL STATE" or
        "|cffffd100INITIAL STATE|r")

      for _,entry in ipairs(initial) do
        add(string.format(
          "#%s  %s  %s  ->  %s",
          tostring(entry.seq or "?"),
          EncounterHistoryTime(entry.time),
          tostring(entry.name or
            ("Encounter "..tostring(entry.id or "?"))),
          EncounterHistoryStateLabel(
            entry.newname,entry.new,plain)))
      end

      add("")
    end

    if h.generatedAt then
      add("Retrieved: "..tostring(h.generatedAt))
    end

    return table.concat(lines,"\n")
  end

  local function DiagnosticReport(plain)
    if (instanceUI.diagnostics or {}).mode=="HISTORY" then
      return EncounterHistoryReport(plain)
    end

    local d=instanceUI.diagnostics or {}; local lines={}
    local function add(value) table.insert(lines,value) end
    if d.historical then add(plain and "HISTORICAL SCAN" or "|cffffd100HISTORICAL SCAN|r") end
    if d.header then add(string.format("%s — Map %s, Instance %s, Difficulty %s",d.header.name or "Current instance",d.header.map or "?",d.header.instance or "?",d.header.difficulty or "?")); add("Script: "..tostring(d.header.script or "Unknown")); add("") end
    if d.loading then add(plain and "Collecting live encounter evidence..." or "|cffffff00Collecting live encounter evidence...|r") end
    if d.error then add((plain and "ERROR: " or "|cffff4040ERROR: |r")..tostring(d.error)) end
    if not d.loading and not d.error and #(d.findings or {})==0 then add("No scan loaded. Enter an instance and click Scan Current Instance.") end
    local colors={PASS="|cff40ff40",EXPECTED="|cff80dfff",INFO="|cffb0b0b0",WARN="|cffffb020",FAIL="|cffff4040"}
    for _,finding in ipairs(d.findings or {}) do
      local prefix=plain and ("["..tostring(finding.severity).."]") or ((colors[finding.severity] or "|cffffffff").."["..tostring(finding.severity).."]|r")
      add(string.format("%s  %s — %s",prefix,tostring(finding.category or "CHECK"),tostring(finding.subject or "Unknown")))
      add("  Expected: "..tostring(finding.expected or "—")); add("  Actual: "..tostring(finding.actual or "—")); add("  Why: "..tostring(finding.detail or "—")); add("  Recommendation: "..tostring(finding.recommendation or "—")); add("")
    end
    for _,recovery in ipairs(d.recoveries or {}) do
      local heading=plain and "TEMPORARY GM RECOVERY" or "|cffffd100TEMPORARY GM RECOVERY|r"
      local confidence=plain and tostring(recovery.confidence or "UNKNOWN") or "|cff00bfff"..tostring(recovery.confidence or "UNKNOWN").."|r"
      local actions=tostring(recovery.actions or "—"):gsub(";;","\n")
      add(heading.." — "..tostring(recovery.title or "Recovery guidance")); add("  Confidence: "..confidence); add("")
      add(plain and "Evidence:" or "|cffffd100Evidence:|r"); add("  "..tostring(recovery.evidence or "—")); add("")
      add(plain and "1. Verify the saved state:" or "|cffffd1001. Verify the saved state:|r"); add(tostring(recovery.verify or ".instance getbossstate")); add("")
      add(plain and "2. Before proceeding:" or "|cffff40402. Before proceeding:|r"); add("  "..tostring(recovery.safety or "Confirm the encounter was legitimately completed.")); add("")
      add(plain and "3. Apply the temporary repair:" or "|cffffd1003. Apply the temporary repair:|r"); add(actions); add("")
      add(plain and "4. Verify the repair:" or "|cffffd1004. Verify the repair:|r"); add(tostring(recovery.recheck or ".instance getbossstate")); add("")
      add(plain and "Expected result:" or "|cff40ff40Expected result:|r"); add("  "..tostring(recovery.expected or "Run Diagnostics again.")); add("")
    end
    if d.summary then add(string.format("SUMMARY — %s passed, %s warnings, %s failures",d.summary.passed or 0,d.summary.warnings or 0,d.summary.failures or 0)); if d.generatedAt then add("Generated: "..d.generatedAt) end end
    return table.concat(lines,"\n")
  end
  instanceUI.RenderDiagnostics=function()
    local historyMode=(instanceUI.diagnostics or {}).mode=="HISTORY"
    if historyMode then
      diagnosticHeading:SetText("ENCOUNTER HISTORY")
      diagnosticTitle:SetText("ENCOUNTER HISTORY")
      diagnosticHelp:SetText("Server-captured encounter state changes for the current live instance.\n\nUse Refresh History after a pull, wipe or kill. No encounter state is changed by this view.")
      if diagnosticHistoryButton then diagnosticHistoryButton:SetText("Refresh History") end
      if diagnosticOlder then diagnosticOlder:Hide() end
      if diagnosticNewer then diagnosticNewer:Hide() end
      if recoveryButton then recoveryButton:Hide() end
    else
      diagnosticHeading:SetText("ENCOUNTER SCAN")
      diagnosticTitle:SetText("LIVE ENCOUNTER EVIDENCE")
      diagnosticHelp:SetText("Enter the affected dungeon or raid. Target the boss or event NPC for extra evidence, then run the scan.\n\nThis workspace never changes encounter state, doors, creatures or lockouts.")
      if diagnosticHistoryButton then diagnosticHistoryButton:SetText("Encounter History") end
      if diagnosticOlder then diagnosticOlder:Show() end
      if diagnosticNewer then diagnosticNewer:Show() end
      if recoveryButton then recoveryButton:Show() end
    end
    local report=DiagnosticReport(false)
    diagnosticText:SetText(report)
    diagnosticChild:SetHeight(math.max(500,diagnosticText:GetStringHeight()+20))
  end
  local diagnosticFooter=CreateFrame("Frame",nil,diagnosticPage); diagnosticFooter:SetPoint("BOTTOMLEFT",200,12); diagnosticFooter:SetPoint("BOTTOMRIGHT",-12,12); diagnosticFooter:SetHeight(28)
  local function RecoveryCommands()
    local lines={}
    for _,recovery in ipairs((instanceUI.diagnostics or {}).recoveries or {}) do
      table.insert(lines,"# "..tostring(recovery.title or "Temporary GM Recovery"))
      table.insert(lines,tostring(recovery.verify or ".instance getbossstate"))
      table.insert(lines,tostring(recovery.actions or ""):gsub(";;","\n"))
      table.insert(lines,tostring(recovery.recheck or ".instance getbossstate"))
      table.insert(lines,"")
    end
    return table.concat(lines,"\n")
  end
  recoveryButton=Button(diagnosticFooter,"Copy Recovery Commands",154,22,function()
    local commands=RecoveryCommands(); if commands=="" then SetStatus("No recovery guidance was generated for this scan.",true); return end
    ShowSelectableReport("Temporary GM recovery commands",commands)
  end,"Copy verification, repair and recheck commands without executing them"); recoveryButton:SetPoint("LEFT",0,0)
  Button(diagnosticFooter,"Copy",54,22,function()
    local title=(instanceUI.diagnostics or {}).mode=="HISTORY" and "Encounter history" or "Encounter diagnostic report"
    ShowSelectableReport(title,DiagnosticReport(true))
  end,"Copy the complete visible report"):SetPoint("RIGHT",-126,0)
  Button(diagnosticFooter,"Share",58,22,function() local f=EnsureShareFrame(); f:SetCapturedMessage(DiagnosticReport(true),"INSTANCE",function() return DiagnosticReport(true) end,"INSTANCE"); f:Show(); f:Raise() end,"Share the visible report through Courier"):SetPoint("RIGHT",-64,0)
  Button(diagnosticFooter,"Export",60,22,function()
    local title=(instanceUI.diagnostics or {}).mode=="HISTORY" and "Export encounter history" or "Export encounter diagnostic report"
    ShowSelectableReport(title,DiagnosticReport(true))
  end,"Export the complete visible report"):SetPoint("RIGHT",0,0)
  instanceUI.RenderDiagnostics()

  local wotlkInstances={
    {533,"Naxxramas","Raid"},{615,"The Obsidian Sanctum","Raid"},{616,"The Eye of Eternity","Raid"},{624,"Vault of Archavon","Raid"},{603,"Ulduar","Raid"},{649,"Trial of the Crusader","Raid"},{249,"Onyxia's Lair","Raid"},{631,"Icecrown Citadel","Raid"},{724,"The Ruby Sanctum","Raid"},
    {574,"Utgarde Keep","Dungeon"},{576,"The Nexus","Dungeon"},{601,"Azjol-Nerub","Dungeon"},{619,"Ahn'kahet: The Old Kingdom","Dungeon"},{600,"Drak'Tharon Keep","Dungeon"},{608,"The Violet Hold","Dungeon"},{604,"Gundrak","Dungeon"},{599,"Halls of Stone","Dungeon"},{602,"Halls of Lightning","Dungeon"},{578,"The Oculus","Dungeon"},{595,"The Culling of Stratholme","Dungeon"},{575,"Utgarde Pinnacle","Dungeon"},{650,"Trial of the Champion","Dungeon"},{632,"The Forge of Souls","Dungeon"},{658,"Pit of Saron","Dungeon"},{668,"Halls of Reflection","Dungeon"}
  }
  local troubleControls=CreateFrame("Frame",nil,troubleshootingPage); troubleControls:SetPoint("TOPLEFT",12,-5); troubleControls:SetPoint("BOTTOMLEFT",12,10); troubleControls:SetWidth(205); Backdrop(troubleControls,C.panel)
  local troubleHeading=Section(troubleControls,"MANUAL RESEARCH",C.gold); troubleHeading:SetPoint("TOPLEFT",10,-10)
  local troubleLabel=Label(troubleControls,"Instance name or Map ID","GameFontNormalSmall"); troubleLabel:SetPoint("TOPLEFT",10,-39)
  local troubleBox=Edit(troubleControls,181,false); troubleBox:SetPoint("TOPLEFT",10,-57); troubleBox.azerCoreOpsPlain=true
  local troublePanel=CreateFrame("Frame",nil,troubleshootingPage); troublePanel:SetPoint("TOPLEFT",225,-5); troublePanel:SetPoint("BOTTOMRIGHT",-12,10); Backdrop(troublePanel,C.panel)
  local troubleTitle=Section(troublePanel,"WOTLK TROUBLESHOOTING LIBRARY",C.gold); troubleTitle:SetPoint("TOPLEFT",10,-10)
  local troubleScroll=CreateFrame("ScrollFrame","AZERCORE_OPS_TroubleshootingScroll",troublePanel,"UIPanelScrollFrameTemplate"); troubleScroll:SetPoint("TOPLEFT",10,-32); troubleScroll:SetPoint("BOTTOMRIGHT",-28,10)
  local troubleChild=CreateFrame("Frame",nil,troubleScroll); troubleChild:SetWidth(620); troubleChild:SetHeight(500); troubleScroll:SetScrollChild(troubleChild)
  local troubleText=troubleChild:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); troubleText:SetPoint("TOPLEFT",2,-2); troubleText:SetWidth(610); troubleText:SetJustifyH("LEFT"); troubleText:SetJustifyV("TOP"); troubleText:SetWordWrap(true)
  local function ShowTroubleshooting()
    local query=tostring(troubleBox:GetText() or ""):lower(); local selected
    for _,entry in ipairs(wotlkInstances) do if query==tostring(entry[1]) or tostring(entry[2]):lower():find(query,1,true) then selected=entry; break end end
    if not selected or query=="" then troubleText:SetText("Enter a WotLK instance name or exact Map ID.\n\nThe library works outside the instance. Live creature, door and script evidence requires a Diagnostics scan inside the loaded instance."); troubleChild:SetHeight(500); return end
    local special=selected[1]==631 and "\n|cffffd100ICC PROFILE|r\nDetailed live rules currently cover Deathbringer Saurfang, his event NPC, passage door and transporter, upper-wing access, Blood Prince trash initialization, the Council state and Crimson Hall door. Additional ICC encounter profiles are being expanded." or "\n|cffffd100PROFILE STATUS|r\nUniversal encounter-state and selected-target diagnostics are available. Specialized door, transport and scripted-event rules will be added from verified core relationships."
    local report=string.format("|cff00bfff%s|r\nMap ID: %d  •  Type: %s\n\n|cffffd100WHAT CAN BE CHECKED REMOTELY|r\n• Instance identity, difficulty and saved lockout\n• Recorded encounter progression and previous scan history\n• Known symptoms, prerequisites and recovery guidance\n\n|cffffd100WHAT REQUIRES A LIVE SCAN|r\n• Physical door, gate, elevator and transporter state\n• Boss and event-NPC presence, flags, combat and AI\n• Loaded instance script and active encounter state\n\n|cffffd100SAFE INVESTIGATION ORDER|r\n1. Review the character bind and previous scans.\n2. Enter the same difficulty and lockout.\n3. Stand beside the affected object.\n4. Target the boss or event NPC when possible.\n5. Run Diagnostics and export the evidence.\n6. Correct saved state only after the controlling encounter is verified.\n\n|cffff4040SAFETY|r\nDo not use .die, .kill, respawn, delete or manual door activation before capturing evidence.%s",selected[2],selected[1],selected[3],special)
    troubleText:SetText(report); troubleChild:SetHeight(math.max(500,troubleText:GetStringHeight()+20)); SetStatus("Loaded troubleshooting reference for "..selected[2])
  end
  Button(troubleControls,"Open Reference",181,24,ShowTroubleshooting,"Research this instance without entering it"):SetPoint("TOPLEFT",10,-91)
  troubleBox:SetScript("OnEnterPressed",function(self) self:ClearFocus(); ShowTroubleshooting() end)
  local troubleList=troubleControls:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); troubleList:SetPoint("TOPLEFT",10,-132); troubleList:SetPoint("TOPRIGHT",-10,-132); troubleList:SetJustifyH("LEFT"); troubleList:SetJustifyV("TOP"); troubleList:SetWordWrap(true); troubleList:SetTextColor(unpack(C.muted)); troubleList:SetText("Examples:\n631 — Icecrown Citadel\n668 — Halls of Reflection\n603 — Ulduar\n533 — Naxxramas\n\nSupports all WotLK raid and dungeon maps in the catalogue.")
  ShowTroubleshooting()
  auditUI.filter=(Settings().rememberAuditFilter and AzerCoreOpsDB.auditFilter) or "ALL"; if not ({ALL=true,CAN_JOIN=true,CANNOT_JOIN=true,OFFLINE=true,SAME_ID=true,DIFFERENT_ID=true,NO_BIND=true})[auditUI.filter] then auditUI.filter="ALL" end
  ShowInstanceMode("ACCESS")
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
  if characterUI.UpdateEquipmentCamera then characterUI.UpdateEquipmentCamera() end
  if Platform.ItemUI.UpdatePreviewCamera then Platform.ItemUI.UpdatePreviewCamera() end
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
    if compatUI.informationOverviewText then compatUI.informationOverviewText:SetText(initial) end
    if compatUI.informationCapabilitiesText then compatUI.informationCapabilitiesText:SetText("Capabilities and permissions have not been requested from the server.") end
    if compatUI.informationBuildText then compatUI.informationBuildText:SetText("Build and revision information has not been requested from the server.") end
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
  local overviewText=string.format(
    "Compatibility\n%s\n|cffaaaaaa%s|r\n\nSoftware\nAddon      |cffffffff%s|r\nModule     |cffffffff%s|r\nProtocol   v%s\nSchema     v%s\nRelease    %s (%s)",
    status,compatibilityReason,ADDON_VERSION,f.module or "unknown",f.protocol or "?",f.capschema or "?",release,f.release or "unknown")
  local capabilitiesViewText=string.format(
    "Capabilities\n|cffffffff%s|r\n\nPermissions\n|cffffffff%s|r",
    capabilityText,permissionText)
  local buildViewText=string.format(
    "Commits\nAzerCore Ops |cffffffff%s|r\nCore         |cffffffff%s|r\nPlayerbots   |cffffffff%s|r\n\nWorkspace\nAzerCore Ops %s\nCore         %s\nPlayerbots   %s\n\nBuild\n|cffffffff%s|r\nBuilt |cffffffff%s|r",
    f.modulegit or "unknown",f.core or "unknown",f.playerbots or "unknown",
    Workspace(f.moduledirty),Workspace(f.coredirty),Workspace(f.playerbotsdirty),f.build or "unknown",f.built or "unknown")
  local text=string.format(
    "Compatibility\n%s\n|cffaaaaaa%s|r\n\nSoftware\nAddon      |cffffffff%s|r\nModule     |cffffffff%s|r\nProtocol   v%s\nSchema     v%s\nRelease    %s (%s)\n\nCapabilities\n|cffffffff%s|r\n\nPermissions\n|cffffffff%s|r\n\nCommits\nAzerCore Ops |cffffffff%s|r\nCore         |cffffffff%s|r\nPlayerbots   |cffffffff%s|r\n\nWorkspace\nAzerCore Ops %s\nCore         %s\nPlayerbots   %s\n\nBuild\n%s\nBuilt %s",
    status,compatibilityReason,ADDON_VERSION,f.module or "unknown",f.protocol or "?",f.capschema or "?",release,f.release or "unknown",
    capabilityText,permissionText,f.modulegit or "unknown",f.core or "unknown",f.playerbots or "unknown",
    Workspace(f.moduledirty),Workspace(f.coredirty),Workspace(f.playerbotsdirty),f.build or "unknown",f.built or "unknown")
  if target then target:SetText(text) end
  if compatUI.informationText then compatUI.informationText:SetText(text) end
  if compatUI.informationOverviewText then compatUI.informationOverviewText:SetText(overviewText) end
  if compatUI.informationCapabilitiesText then compatUI.informationCapabilitiesText:SetText(capabilitiesViewText) end
  if compatUI.informationBuildText then compatUI.informationBuildText:SetText(buildViewText) end
end

local function RequestCompatibility()
  compatUI.data=nil; compatUI.received={}; RenderCompatibility(); SendCommand(CMD.version); SetStatus("Checking compatibility: contacting the AzerCore Ops server module...")
end

local function BuildOptions()
  local p=CreateFrame("Frame","AZERCORE_OPS_OptionsPanel",UIParent); p.name="AzerCore Ops"; optionsPanel=p
  local function ScrollContent(panel,name,height)
    local scroll=CreateFrame("ScrollFrame",name,panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",0,0); scroll:SetPoint("BOTTOMRIGHT",-28,22)
    local child=CreateFrame("Frame",nil,scroll); child:SetWidth(640); child:SetHeight(height); scroll:SetScrollChild(child)
    local horizontal=CreateFrame("Slider",name.."Horizontal",panel,"OptionsSliderTemplate")
    horizontal:SetPoint("BOTTOMLEFT",18,4); horizontal:SetPoint("BOTTOMRIGHT",-18,4); horizontal:SetHeight(14); horizontal:SetValueStep(5); horizontal:SetValue(0)
    _G[horizontal:GetName().."Low"]:SetText(""); _G[horizontal:GetName().."High"]:SetText(""); _G[horizontal:GetName().."Text"]:SetText("")
    horizontal:SetScript("OnValueChanged",function(_,value) scroll:SetHorizontalScroll(value) end)
    local function UpdateHorizontal()
      local maximum=math.max(0,child:GetWidth()-scroll:GetWidth())
      horizontal:SetMinMaxValues(0,maximum)
      if maximum>0 then horizontal:Show() else horizontal:SetValue(0); horizontal:Hide() end
    end
    panel:SetScript("OnSizeChanged",UpdateHorizontal)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(self,delta)
      local maximum=math.max(0,child:GetHeight()-self:GetHeight())
      self:SetVerticalScroll(math.max(0,math.min(maximum,self:GetVerticalScroll()-delta*32)))
    end)
    return child,scroll,horizontal,UpdateHorizontal
  end
  local pc,pScroll,pHorizontal,pUpdateHorizontal=ScrollContent(p,"AZERCORE_OPS_OptionsScroll",505)
  local title=pc:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetText("AzerCore Ops")
  local version=pc:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); version:SetPoint("LEFT",title,"RIGHT",8,0); version:SetText(ADDON_VERSION)
  local note=pc:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); note:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-8); note:SetText("Settings are saved separately for each character.")
  local controls={}
  local function Check(parent,store,name,label,key,y,tip)
    local c=CreateFrame("CheckButton","AZERCORE_OPS_Opt"..name,parent,"InterfaceOptionsCheckButtonTemplate"); c:SetPoint("TOPLEFT",16,y)
    _G[c:GetName().."Text"]:SetText(label); c.tooltipText=tip; c:SetScript("OnClick",function(self) Settings()[key]=self:GetChecked() and true or false; ApplySettings() end)
    store[key]=c; return c
  end
  Check(pc,controls,"StartMinimized","Start minimized after login or reload","startMinimized",-70,"Apply on the next login or /reload.")
  Check(pc,controls,"Minimap","Show AzerCoreOps minimap button","showMinimap",-102,"Show the AzerCoreOps button around the minimap.")
  Check(pc,controls,"Mini","Show floating AzerCoreOps button when minimized","showMini",-134,"Show the movable AzerCoreOps button when the main window is hidden.")
  Check(pc,controls,"MBF","Keep AzerCoreOps outside Minimap Button Frame","mbfCompatibility",-166,"Enabled: MBF cannot collect AzerCoreOps. Disabled: AzerCoreOps can be added to MBF with /mbf scan.")
  Check(pc,controls,"Confirm","Confirm destructive commands","confirmCommands",-198,"Ask before delete, remove, reset, reward, and other risky commands.")
  Check(pc,controls,"Chat","Hide AzerCore Ops command echoes from chat","hideAuditChat",-230,"Hide dot-command echoes sent by AzerCore Ops. Structured protocol traffic is always hidden.")

  local roleLabel=pc:CreateFontString(nil,"ARTWORK","GameFontNormal"); roleLabel:SetPoint("TOPLEFT",22,-278); roleLabel:SetText("Operation mode")
  local roleButtons={}
  local function UpdateRoleButtons()
    local selected=tostring(Settings().roleMode or "AUTOMATIC"):upper(); local gmGranted=tostring(Platform:PermissionFor("CHARACTER_MODE") or "PLAYER"):upper()=="GM"
    for role,button in pairs(roleButtons) do
      local enabled=role~="GM" or gmGranted; if enabled then button:Enable(); button:SetNormalFontObject(GameFontNormalSmall) else button:Disable(); button:SetNormalFontObject(GameFontDisableSmall) end
      button:SetBackdropColor(unpack(role==selected and C.selected or C.button)); button:SetBackdropBorderColor(unpack(role==selected and C.gold or C.border))
    end
  end
  compatUI.roleButtons=roleButtons; compatUI.updateRoleButtons=UpdateRoleButtons
  for index,definition in ipairs({{"AUTOMATIC","Automatic"},{"PLAYER","Player"},{"GM","GM"}}) do
    local role,label=definition[1],definition[2]
    local b=Button(pc,label,84,24,function()
      if role=="GM" and tostring(Platform:PermissionFor("CHARACTER_MODE") or "PLAYER"):upper()~="GM" then SetStatus("GM mode is unavailable until the module advertises GM authorization.",true); return end
      Settings().roleMode=role; UpdateRoleButtons(); Platform:UpdateWorkspaceMode(); Platform:ApplyRoleButtonPolicies(); UpdateBindControls(); if characterUI.Update then characterUI.Update() end; SetStatus("Operation mode set to "..label..". Effective mode: "..EffectiveCharacterMode()..".")
    end,"Automatic follows module authorization; Player is always available; GM requires server authorization")
    b:SetPoint("TOPLEFT",22+(index-1)*92,-298); b:SetScript("OnLeave",function(self) UpdateRoleButtons(); GameTooltip:Hide() end); roleButtons[role]=b
  end
  local roleHelp=pc:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); roleHelp:SetPoint("TOPLEFT",22,-326); roleHelp:SetText("GM mode cannot be granted by the addon; the server module remains authoritative."); roleHelp:SetTextColor(unpack(C.muted))

  local scaleLabel=pc:CreateFontString(nil,"ARTWORK","GameFontNormal"); scaleLabel:SetPoint("TOPLEFT",22,-356); scaleLabel:SetText("AzerCoreOps window scale")
  local slider=CreateFrame("Slider","AZERCORE_OPS_OptScale",pc,"OptionsSliderTemplate"); slider:SetPoint("TOPLEFT",22,-380); slider:SetWidth(240); slider:SetMinMaxValues(.75,1.35); slider:SetValueStep(.05)
  _G[slider:GetName().."Low"]:SetText("75%"); _G[slider:GetName().."High"]:SetText("135%"); _G[slider:GetName().."Text"]:SetText("100%")
  slider:SetScript("OnValueChanged",function(self,value) value=math.floor(value*20+.5)/20; Settings().scale=value; _G[self:GetName().."Text"]:SetText(math.floor(value*100+.5).."%"); ApplySettings() end)

  local resetPos=CreateFrame("Button",nil,pc,"UIPanelButtonTemplate"); resetPos:SetWidth(135); resetPos:SetHeight(24); resetPos:SetText("Reset positions"); resetPos:SetPoint("TOPLEFT",16,-448); resetPos:SetScript("OnClick",ResetPositions)
  local resetAll=CreateFrame("Button",nil,pc,"UIPanelButtonTemplate"); resetAll:SetWidth(135); resetAll:SetHeight(24); resetAll:SetText("Restore defaults"); resetAll:SetPoint("LEFT",resetPos,"RIGHT",12,0)
  resetAll:SetScript("OnClick",function() AzerCoreOpsDB.settings={}; AzerCoreOpsDB.auditFilter=nil; Settings(); slider:SetValue(Settings().scale); ApplySettings(); p:GetScript("OnShow")(p); Print("Settings restored to defaults.") end)

  local diagnostics=CreateFrame("Frame",nil,pc); diagnostics:SetPoint("TOPLEFT",330,-62); diagnostics:SetWidth(290); diagnostics:SetHeight(382); Backdrop(diagnostics,C.panel)
  local diagTitle=Label(diagnostics,"Compatibility diagnostics"); diagTitle:SetPoint("TOPLEFT",10,-10)
  compatUI.text=diagnostics:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.text:SetPoint("TOPLEFT",10,-38); compatUI.text:SetPoint("BOTTOMRIGHT",-10,44); compatUI.text:SetJustifyH("LEFT"); compatUI.text:SetJustifyV("TOP"); compatUI.text:SetWordWrap(true); compatUI.text:SetNonSpaceWrap(true); compatUI.text:SetTextColor(unpack(C.white))
  local check=CreateFrame("Button",nil,diagnostics,"UIPanelButtonTemplate"); check:SetWidth(150); check:SetHeight(24); check:SetText("Check compatibility"); check:SetPoint("BOTTOMLEFT",10,10); check:SetScript("OnClick",RequestCompatibility)
  RenderCompatibility()

  p:SetScript("OnShow",function()
    local s=Settings(); for key,c in pairs(controls) do c:SetChecked(s[key] and true or false) end
    slider:SetValue(s.scale); UpdateRoleButtons(); pScroll:SetVerticalScroll(0); pHorizontal:SetValue(0); pUpdateHorizontal()
  end)
  InterfaceOptions_AddCategory(p)

  local a=CreateFrame("Frame","AZERCORE_OPS_AuditOptionsPanel",UIParent); a.name="Audit & Instances"; a.parent="AzerCore Ops"
  local ac,aScroll,aHorizontal,aUpdateHorizontal=ScrollContent(a,"AZERCORE_OPS_AuditOptionsScroll",535)
  local at=ac:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); at:SetPoint("TOPLEFT",16,-16); at:SetText("AzerCoreOps — Audit & Instances")
  local an=ac:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); an:SetPoint("TOPLEFT",at,"BOTTOMLEFT",0,-8); an:SetText("Display, filtering, bind-reset safety, and instance defaults.")
  local auditControls={}
  Check(ac,auditControls,"AuditTips","Show complete audit reason tooltips","auditTooltips",-70,"Show the complete diagnostic reason while hovering.")
  Check(ac,auditControls,"WrapAudit","Wrap long audit reasons","wrapAuditReasons",-102,"Use a narrower result canvas for easier reading.")
  Check(ac,auditControls,"AuditWheel","Enable mouse-wheel audit scrolling","mouseWheelAudit",-134,"Scroll raid results with the mouse wheel.")
  Check(ac,auditControls,"ProblemsFirst","Sort problems first","problemsFirst",-166,"Order FAIL, OFFLINE, WARN, then PASS.")
  Check(ac,auditControls,"RememberFilter","Remember the selected audit filter","rememberAuditFilter",-198,"Restore the last selected result filter.")
  Check(ac,auditControls,"AutoAudit","Automatically re-audit after selected binds are removed","autoReaudit",-230,"Repeat the last audit after an accepted bind removal.")
  Check(ac,auditControls,"ConfirmMapReset","Confirm Unbind Selected","confirmResetSelected",-262,"Confirm before removing the explicitly selected instance binds.")
  Check(ac,auditControls,"WarnTarget","Warn when no player is selected","warnNoTarget",-294,"Prevent bind commands from accidentally applying to yourself.")
  Check(ac,auditControls,"CompactRows","Use compact audit result rows","compactAuditRows",-326,"Fit more member results into the audit view.")
  Check(ac,auditControls,"ShiftClick","Enable Shift-click link insertion","shiftClickInsert",-358,"With a AzerCoreOps field focused, Shift-click an item, quest, spell, or player link to insert it.")

  local diffLabel=ac:CreateFontString(nil,"ARTWORK","GameFontNormal"); diffLabel:SetPoint("TOPLEFT",22,-438); diffLabel:SetText("Default instance difficulty")
  local diff=CreateFrame("Slider","AZERCORE_OPS_OptDifficulty",ac,"OptionsSliderTemplate"); diff:SetPoint("TOPLEFT",22,-462); diff:SetWidth(200); diff:SetMinMaxValues(0,3); diff:SetValueStep(1)
  _G[diff:GetName().."Low"]:SetText("0"); _G[diff:GetName().."High"]:SetText("3")
  diff:SetScript("OnValueChanged",function(self,value) value=math.floor(value+.5); Settings().defaultDifficulty=value; _G[self:GetName().."Text"]:SetText(tostring(value)); if auditUI.diffBox then auditUI.diffBox:SetText(tostring(value)) end end)

  local fontLabel=ac:CreateFontString(nil,"ARTWORK","GameFontNormal"); fontLabel:SetPoint("TOPLEFT",270,-438); fontLabel:SetText("Audit font size")
  local font=CreateFrame("Slider","AZERCORE_OPS_OptAuditFont",ac,"OptionsSliderTemplate"); font:SetPoint("TOPLEFT",270,-462); font:SetWidth(200); font:SetMinMaxValues(8,14); font:SetValueStep(1)
  _G[font:GetName().."Low"]:SetText("8"); _G[font:GetName().."High"]:SetText("14")
  font:SetScript("OnValueChanged",function(self,value) value=math.floor(value+.5); Settings().auditFontSize=value; _G[self:GetName().."Text"]:SetText(tostring(value)); ApplySettings() end)

  a:SetScript("OnShow",function()
    local s=Settings(); for key,c in pairs(auditControls) do c:SetChecked(s[key] and true or false) end
    diff:SetValue(s.defaultDifficulty); font:SetValue(s.auditFontSize); aScroll:SetVerticalScroll(0); aHorizontal:SetValue(0); aUpdateHorizontal()
  end)
  InterfaceOptions_AddCategory(a)
end

local PROJECT_LINKS = {
  {label="AzerCoreOps repository", url="https://github.com/Fersantos1975/AzerCore-Ops"},
  {label="AzerothCore", url="https://github.com/azerothcore/azerothcore-wotlk"},
  {label="mod-playerbots", url="https://github.com/mod-playerbots/mod-playerbots"},
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
  local intro=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); intro:SetPoint("TOPLEFT",18,-48); intro:SetPoint("TOPRIGHT",-18,-48); intro:SetJustifyH("LEFT"); intro:SetTextColor(unpack(C.white)); intro:SetText("A server-authorized operations and gameplay platform for players, administrators and Game Masters.")
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
  local note=quick:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); note:SetPoint("TOPLEFT",12,-92); note:SetPoint("BOTTOMRIGHT",-12,12); note:SetJustifyH("LEFT"); note:SetJustifyV("TOP"); note:SetWordWrap(true); note:SetTextColor(unpack(C.white)); note:SetText("Release: v0.7.1\n\nAzerCore Ops 0.7.1 aligns Item search, streamlines Movement destination navigation, expands authoritative NPC Spawn diagnostics, adds Go to NPC, and integrates live NPC targets with search. Courier remains under construction and is not included as an active release feature.")
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
  local unavailable=CreateFrame("Frame",nil,p); unavailable:SetPoint("TOPLEFT",14,-70); unavailable:SetPoint("BOTTOMRIGHT",-14,14); unavailable:SetFrameLevel(p:GetFrameLevel()+40); unavailable:EnableMouse(true); Backdrop(unavailable,C.bg)
  local unavailableTitle=unavailable:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); unavailableTitle:SetPoint("CENTER",0,42); unavailableTitle:SetText("Courier — Under Construction"); unavailableTitle:SetTextColor(unpack(C.gold))
  local unavailableText=unavailable:CreateFontString(nil,"OVERLAY","GameFontHighlight"); unavailableText:SetPoint("TOP",unavailableTitle,"BOTTOM",0,-18); unavailableText:SetWidth(500); unavailableText:SetJustifyH("CENTER"); unavailableText:SetTextColor(unpack(C.white)); unavailableText:SetText("Courier transport, inbox, delivery and user-management features are not active in this release.\n\nThe preview is intentionally locked until its protocol, permissions, privacy and delivery safeguards are complete.")
  courierUI.unavailable=unavailable
end

local function BuildInformation()
  local p=NewPage("Information")
  local title=Label(p,"Platform Information & Credits","GameFontNormalLarge"); title:SetPoint("TOPLEFT",18,-18)

  local actions=CreateFrame("Frame",nil,p); actions:SetPoint("TOPLEFT",18,-55); actions:SetPoint("BOTTOMLEFT",18,18); actions:SetWidth(150); Backdrop(actions,C.panel)
  local ah=Label(actions,"INFORMATION","GameFontNormalSmall"); ah:SetPoint("TOPLEFT",12,-12)
  local content=CreateFrame("Frame",nil,p); content:SetPoint("TOPLEFT",178,-55); content:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(content,C.panel)
  local views,buttons={},{ }

  local function ScrollView(key,heading,height)
    local view=CreateFrame("Frame",nil,content); view:SetAllPoints(); view:Hide(); views[key]=view
    local vh=Label(view,heading); vh:SetPoint("TOPLEFT",14,-14)
    local scroll=CreateFrame("ScrollFrame","AZERCORE_OPS_InfoScroll_"..key,view,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",12,-42); scroll:SetPoint("BOTTOMRIGHT",-30,12)
    local child=CreateFrame("Frame",nil,scroll); child:SetWidth(520); child:SetHeight(height or 520); scroll:SetScrollChild(child)
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) local maximum=math.max(0,child:GetHeight()-self:GetHeight()); self:SetVerticalScroll(math.max(0,math.min(maximum,self:GetVerticalScroll()-delta*32))) end)
    return child
  end

  local overview=ScrollView("OVERVIEW","Platform overview",440)
  compatUI.informationOverviewText=overview:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.informationOverviewText:SetPoint("TOPLEFT",4,-4); compatUI.informationOverviewText:SetPoint("TOPRIGHT",-4,-4); compatUI.informationOverviewText:SetJustifyH("LEFT"); compatUI.informationOverviewText:SetJustifyV("TOP"); compatUI.informationOverviewText:SetWordWrap(true); compatUI.informationOverviewText:SetTextColor(unpack(C.white))

  local capabilities=ScrollView("CAPABILITIES","Capabilities & permissions",760)
  compatUI.informationCapabilitiesText=capabilities:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.informationCapabilitiesText:SetPoint("TOPLEFT",4,-4); compatUI.informationCapabilitiesText:SetPoint("TOPRIGHT",-4,-4); compatUI.informationCapabilitiesText:SetJustifyH("LEFT"); compatUI.informationCapabilitiesText:SetJustifyV("TOP"); compatUI.informationCapabilitiesText:SetWordWrap(true); compatUI.informationCapabilitiesText:SetTextColor(unpack(C.white))

  local build=ScrollView("BUILD","Build information",520)
  compatUI.informationBuildText=build:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.informationBuildText:SetPoint("TOPLEFT",4,-4); compatUI.informationBuildText:SetPoint("TOPRIGHT",-4,-4); compatUI.informationBuildText:SetJustifyH("LEFT"); compatUI.informationBuildText:SetJustifyV("TOP"); compatUI.informationBuildText:SetWordWrap(true); compatUI.informationBuildText:SetTextColor(unpack(C.white))

  local credits=ScrollView("CREDITS","Project & credits",620)
  local ct=credits:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ct:SetPoint("TOPLEFT",4,-4); ct:SetPoint("TOPRIGHT",-4,-4); ct:SetHeight(560); ct:SetJustifyH("LEFT"); ct:SetJustifyV("TOP"); ct:SetWordWrap(true); ct:SetTextColor(unpack(C.white)); ct:SetText("AzerCore Ops is an open-source operations and gameplay companion for AzerothCore players, administrators and Game Masters.\n\nPlayer Mode provides permitted gameplay, inspection and reporting features for regular players. It cannot grant administrative authority; privileged operations remain authorized and enforced by the server module.\n\nCreated and maintained by |cffffd100Fernando Santos|r.\n\nBuilt with AzerothCore, mod-playerbots, and AI-assisted development from OpenAI ChatGPT.\n\nMovement destination data adapted from AzerothAdmin under GPLv3 and derived from TrinityAdmin/MangAdmin. Our thanks to their contributors and the wider open-source community.\n\nAzerothCore and its contributors provide the server platform on which AzerCore Ops operates. mod-playerbots is acknowledged for the Playerbot integration and development environment.\n\nLicense\n|cffffffffGNU General Public License v3.0|r")

  local resources=ScrollView("RESOURCES","Project resources",420)
  for i,item in ipairs(PROJECT_LINKS) do local entry=item; Button(resources,entry.label,390,28,function() ShowCopyLink(entry.label,entry.url) end,"Open a selectable copy box for this address"):SetPoint("TOPLEFT",4,-4-(i-1)*36) end

  local function Select(key)
    for name,view in pairs(views) do if name==key then view:Show() else view:Hide() end end
    for name,button in pairs(buttons) do button:SetBackdropColor(unpack(name==key and C.selected or C.button)); button:SetBackdropBorderColor(unpack(name==key and C.gold or C.border)) end
  end
  for i,definition in ipairs({{"OVERVIEW","Overview"},{"CAPABILITIES","Capabilities"},{"BUILD","Build Information"},{"CREDITS","Credits"},{"RESOURCES","Resources"}}) do
    local key,label=definition[1],definition[2]; local b=Button(actions,label,126,26,function() Select(key) end); b:SetPoint("TOPLEFT",12,-38-(i-1)*32); buttons[key]=b
  end
  Button(actions,"Check Compatibility",126,28,RequestCompatibility,"Query module, registry, permissions, and build information"):SetPoint("BOTTOMLEFT",12,14)
  Select("OVERVIEW")
  RenderCompatibility()
end

local function BuildUI()
  main=CreateFrame("Frame","AZERCORE_OPS_MainFrame",UIParent); main:SetWidth(980); main:SetHeight(650); main:SetClampedToScreen(true); main:SetFrameStrata("DIALOG"); Backdrop(main); RestorePoint(main,"main","CENTER",0,0); Movable(main,"main")
  local logo=main:CreateTexture(nil,"ARTWORK"); logo:SetTexture("Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"); logo:SetWidth(30); logo:SetHeight(30); logo:SetPoint("TOPLEFT",12,-7)
  local title=Label(main,"AzerCore Ops  |cffaaaaaa".."0.7.1".."|r"); title:SetPoint("TOPLEFT",50,-15)
  compatUI.workspaceModeText=main:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); compatUI.workspaceModeText:SetPoint("TOPRIGHT",-104,-16); compatUI.workspaceModeText:SetJustifyH("RIGHT")
  Button(main,"?",22,20,OpenOptions,"Open AzerCoreOps options"):SetPoint("TOPRIGHT",-66,-10)
  Button(main,"_",22,20,HideMain,"Minimize to floating button"):SetPoint("TOPRIGHT",-38,-10)
  Button(main,"X",22,20,HideMain,"Close"):SetPoint("TOPRIGHT",-10,-10)

  local resizeGrip=CreateFrame("Button","AZERCORE_OPS_ResizeGrip",main)
  resizeGrip:SetWidth(22); resizeGrip:SetHeight(22); resizeGrip:SetPoint("BOTTOMRIGHT",-2,2); resizeGrip:SetFrameLevel(main:GetFrameLevel()+20)
  local gripTexture=resizeGrip:CreateTexture(nil,"OVERLAY"); gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); gripTexture:SetAllPoints()
  resizeGrip:RegisterForDrag("LeftButton")
  resizeGrip:SetScript("OnEnter",function(self) gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight"); GameTooltip:SetOwner(self,"ANCHOR_TOPLEFT"); GameTooltip:SetText("Resize AzerCore Ops"); GameTooltip:AddLine("Drag to scale the complete window between 75% and 135%.",1,1,1,true); GameTooltip:Show() end)
  resizeGrip:SetScript("OnLeave",function() gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); GameTooltip:Hide() end)
  resizeGrip:SetScript("OnDragStart",function(self)
    local px,py=GetCursorPosition(); local uiScale=UIParent:GetEffectiveScale()
    self.startX=px/uiScale; self.startY=py/uiScale; self.startScale=Settings().scale or 1
    self:SetScript("OnUpdate",function(grip)
      local x,y=GetCursorPosition(); x=x/uiScale; y=y/uiScale
      local delta=((x-grip.startX)/main:GetWidth()+(grip.startY-y)/main:GetHeight())/2
      local value=math.max(.75,math.min(1.35,grip.startScale+delta)); value=math.floor(value*100+.5)/100
      Settings().scale=value; main:SetScale(value); if characterUI.UpdateEquipmentCamera then characterUI.UpdateEquipmentCamera() end; if Platform.ItemUI.UpdatePreviewCamera then Platform.ItemUI.UpdatePreviewCamera() end; SetStatus("Window scale: "..math.floor(value*100+.5).."%")
    end)
  end)
  resizeGrip:SetScript("OnDragStop",function(self)
    self:SetScript("OnUpdate",nil); self.startX=nil; self.startY=nil; self.startScale=nil
    local value=Settings().scale or 1; SetStatus("Window scale saved: "..math.floor(value*100+.5).."%")
  end)

  local sidebar=CreateFrame("Frame",nil,main); sidebar:SetPoint("TOPLEFT",10,-48); sidebar:SetPoint("BOTTOMLEFT",10,32); sidebar:SetWidth(160); Backdrop(sidebar,C.panel)
  local navTitle=Label(sidebar,"NAVIGATION","GameFontNormalSmall"); navTitle:SetPoint("TOPLEFT",14,-14)
  local nav={
    {"Dashboard","Dashboard"}, {"Character","Character"}, {"Quests","Quest"},
    {"Instance Access","Instances"}, {"NPCs","NPC"}, {"Items","Item"},
    {"Movement","Teleport"}, {"Courier","Courier"}, {"Information","Information"},
  }
  for i,item in ipairs(nav) do
    local label,pageName=item[1],item[2]
    local b=Button(sidebar,label,132,30,function() SelectTab(pageName) end); b:SetPoint("TOPLEFT",14,-38-(i-1)*36); tabs[pageName]=b
    b:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(activeTab==pageName and C.selected or C.button)); self:SetBackdropBorderColor(unpack(activeTab==pageName and C.gold or C.border)); GameTooltip:Hide() end)
  end
  local build=sidebar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); build:SetPoint("BOTTOMLEFT",14,14); build:SetPoint("BOTTOMRIGHT",-14,14); build:SetJustifyH("LEFT"); build:SetTextColor(.65,.65,.65,1); build:SetText("Protocol v"..PROTOCOL_VERSION.."\nDevelopment build")

  content=CreateFrame("Frame",nil,main); content:SetPoint("TOPLEFT",180,-48); content:SetPoint("BOTTOMRIGHT",-10,32); Backdrop(content,C.panel)
  statusText=main:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); statusText:SetPoint("BOTTOMLEFT",14,11); statusText:SetPoint("BOTTOMRIGHT",-14,11); statusText:SetJustifyH("LEFT")
  BuildDashboard(); BuildCharacter(); BuildNPC(); BuildQuest(); BuildTeleport(); BuildItem(); BuildInstances(); BuildCourier(); BuildInformation(); Platform:UpdateWorkspaceMode(); SelectTab(AzerCoreOpsDB.activeTab or "Dashboard")

  mini=CreateFrame("Button","AZERCORE_OPS_MiniButton",UIParent); mini:SetWidth(36); mini:SetHeight(28); mini:SetClampedToScreen(true); mini:SetFrameStrata("HIGH"); mini:SetFrameLevel(100); Backdrop(mini); RestorePoint(mini,"mini","CENTER",290,0); Movable(mini,"mini")
  local mi=mini:CreateTexture(nil,"ARTWORK"); mi:SetTexture("Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"); mi:SetAllPoints()
  local mt=mini:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); mt:SetPoint("CENTER"); mt:SetText(""); mt:SetTextColor(unpack(C.gold))
  mini:SetScript("OnClick",function(self) if self._dragged then self._dragged=nil; return end; ShowMain() end); mini:Hide()

  minimapButton=CreateFrame("Button","AZERCORE_OPS_MinimapButton",Settings().mbfCompatibility and UIParent or Minimap); minimapButton:SetWidth(24); minimapButton:SetHeight(22); minimapButton:SetFrameStrata("HIGH"); minimapButton:SetFrameLevel(100); minimapButton:RegisterForClicks("LeftButtonUp","RightButtonUp"); minimapButton:RegisterForDrag("LeftButton")
  local bg=minimapButton:CreateTexture(nil,"BACKGROUND"); bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); bg:SetAllPoints()
  local bd=minimapButton:CreateTexture(nil,"OVERLAY"); bd:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); bd:SetPoint("TOPLEFT",-6,6); bd:SetPoint("BOTTOMRIGHT",6,-6)
  local minimapIconPath="Interface\\AddOns\\AzerCoreOps\\Media\\azercoreops-icon.tga"
  minimapButton:SetNormalTexture(minimapIconPath); local icon=minimapButton:GetNormalTexture(); icon:SetDrawLayer("ARTWORK",2); icon:ClearAllPoints(); icon:SetPoint("TOPLEFT",2,-2); icon:SetPoint("BOTTOMRIGHT",-2,2); icon:SetTexCoord(.06,.94,.06,.94); icon:SetVertexColor(1,1,1,1); icon:SetAlpha(1); icon:Show(); minimapButton.icon=icon
  minimapButton:SetPushedTexture(minimapIconPath); local pushed=minimapButton:GetPushedTexture(); pushed:SetDrawLayer("ARTWORK",3); pushed:ClearAllPoints(); pushed:SetPoint("TOPLEFT",3,-3); pushed:SetPoint("BOTTOMRIGHT",-1,1); pushed:SetTexCoord(.06,.94,.06,.94); pushed:SetVertexColor(1,1,1,1); pushed:SetAlpha(1)
  minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight","ADD"); local highlight=minimapButton:GetHighlightTexture(); highlight:ClearAllPoints(); highlight:SetPoint("TOPLEFT",-2,2); highlight:SetPoint("BOTTOMRIGHT",2,-2)
  minimapButton.tooltipText="AzerCore Ops"; minimapButton.tooltip="AzerCore Ops"
  local tx=minimapButton:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); tx:SetPoint("CENTER"); tx:SetText(""); tx:SetTextColor(unpack(C.gold))
  minimapButton:SetScript("OnClick",function(_,button) if button=="RightButton" then HideMain() elseif main:IsShown() then HideMain() else ShowMain() end end)
  minimapButton:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:SetText("AzerCore Ops",1,.82,0); GameTooltip:AddLine("Operations and gameplay companion",1,1,1); GameTooltip:AddLine("Left-click: open or hide",.75,.75,.75); GameTooltip:AddLine("Right-click: hide",.75,.75,.75); GameTooltip:Show() end)
  minimapButton:SetScript("OnLeave",function() GameTooltip:Hide() end)
  local function MaintainMinimapIcon(self)
    local parent=self:GetParent(); local inMBF=parent and parent.GetName and parent:GetName()=="MinimapButtonFrame"
    if inMBF then
      if self.icon:GetDrawLayer()~="OVERLAY" then self.icon:SetDrawLayer("OVERLAY",7) end
      if not self.icon:IsShown() then self.icon:Show() end
      if self.icon:GetAlpha()~=1 then self.icon:SetAlpha(1) end
    elseif self.icon:GetDrawLayer()~="ARTWORK" then
      self.icon:SetDrawLayer("ARTWORK",2); self.icon:Show(); self.icon:SetAlpha(1)
    end
  end
  minimapButton:SetScript("OnUpdate",MaintainMinimapIcon)
  minimapButton:SetScript("OnDragStart",function(self) self:SetScript("OnUpdate",function(button) MaintainMinimapIcon(button); local mx,my=Minimap:GetCenter(); local px,py=GetCursorPosition(); local s=Minimap:GetEffectiveScale(); AzerCoreOpsDB.minimapAngle=math.deg(math.atan2(py/s-my,px/s-mx)); PositionMinimap() end) end)
  minimapButton:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",MaintainMinimapIcon) end); PositionMinimap(); ApplySettings()
  if Settings().startMinimized then HideMain() end
end

local events=CreateFrame("Frame"); events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_ENTERING_WORLD"); events:RegisterEvent("CHAT_MSG_SYSTEM"); events:RegisterEvent("UPDATE_INSTANCE_INFO"); events:RegisterEvent("PLAYER_TARGET_CHANGED"); events:RegisterEvent("PARTY_MEMBERS_CHANGED"); events:RegisterEvent("RAID_ROSTER_UPDATE"); events:RegisterEvent("INSPECT_TALENT_READY")
local compatibilityRequested=false
events:SetScript("OnEvent",function(_,event,arg1)
  if event=="ADDON_LOADED" then if arg1~=ADDON then return end; AzerCoreOpsDB=AzerCoreOpsDB or {}; Settings(); BuildOptions(); BuildUI(); Print("v".."0.7.1".." loaded. Type /azercoreops help")
  elseif event=="PLAYER_ENTERING_WORLD" and not compatibilityRequested then compatibilityRequested=true; SendChatMessage(CMD.version,"SAY")
  elseif event=="UPDATE_INSTANCE_INFO" and activeTab=="Instances" and instanceUI.bindPage and instanceUI.bindPage:IsShown() then RefreshMyInstances()
  elseif event=="INSPECT_TALENT_READY" then
    if characterUI.inspectionRequestSent and characterUI.OnInspectionReady and (not arg1 or arg1==characterUI.inspectionGuid) then characterUI.OnInspectionReady() end
  elseif event=="PLAYER_TARGET_CHANGED" then
    characterUI.server={professions={},raid={}}; characterUI.capturePlayer=nil; characterUI.ignoreStream=false
    characterUI.inspectionGeneration=(characterUI.inspectionGeneration or 0)+1; characterUI.inspectionRequestSent=false; characterUI.inspectionState="UNLOADED"; characterUI.inspectionGuid=nil
    if characterUI.Update then characterUI.Update() end
    if activeTab=="Character" and characterUI.autoInspect and characterUI.Inspect then
      if characterUI.equipmentSummary then characterUI.equipmentSummary:SetText("Target changed — preparing inspection...") end
      After(.35,function() if activeTab=="Character" and characterUI.autoInspect then characterUI.Inspect(true) end end)
    end
    Platform.NPCUI.server={quests={},loot={},story={}}; Platform.NPCUI.captureEntry=nil; Platform.NPCUI.ignoreStream=false
    Platform.NPCUI.requestEntry=nil; Platform.NPCUI.inspectionLoading=false
    if Platform.NPCUI.Update then Platform.NPCUI.Update() end
    local targetEntry=TargetCreatureEntry()
    local npcSearchBox=Platform.NPCUI.searchBox

    if targetEntry and npcSearchBox and not npcSearchBox:HasFocus() then
      local targetName=UnitName("target")

      if targetName and targetName~="" then
        npcSearchBox:SetText(targetName)
      end
    end
    if activeTab=="NPC" and Platform.NPCUI.autoInspect and Platform.NPCUI.Inspect then
      After(.35,function() if activeTab=="NPC" and Platform.NPCUI.autoInspect then Platform.NPCUI.Inspect(true) end end)
    end
    UpdateInstanceTargetIdentity()
    After(.08,UpdateInstanceTargetIdentity)
    if activeTab=="Instances" and instanceUI.bindPage and instanceUI.bindPage:IsShown() then
      instanceUI.target={}; instanceUI.targetOffset=0; instanceUI.selectedBind=nil; instanceUI.selectedBindOwner=nil; instanceUI.inspectedAt=nil
      if UnitExists("target") and UnitIsPlayer("target") then
        instanceUI.inspectedPlayer=SelectedPlayerName(); instanceUI.targetLoadState="LOADING"; RenderInstances(); SetStatus("Loading binds for "..tostring(instanceUI.inspectedPlayer).."...")
        After(.05,function() InspectTargetInstances(false) end)
      else
        instanceUI.inspectedPlayer=nil; instanceUI.targetLoadState="UNLOADED"; RenderInstances(); SetStatus("No player selected; Target Binds cleared.")
      end
    end
    RenderInstances(); UpdateQuestContextLabel()
    if shareFrame and shareFrame:IsShown() and shareFrame.RefreshLive then shareFrame:RefreshLive() end
    if questUI.activeWorkspace=="TARGET" and questUI.targetLogActive and UnitExists("target") and UnitIsPlayer("target") then
      UpdateQuestInspectorTarget(false); OpenTargetQuestLog()
    elseif questUI.activeWorkspace=="TARGET" and questUI.lockedQuestId and UnitExists("target") and UnitIsPlayer("target") then
      UpdateQuestInspectorTarget(true)
    else
      UpdateQuestInspectorTarget(false)
    end
  elseif event=="PARTY_MEMBERS_CHANGED" or event=="RAID_ROSTER_UPDATE" then
    if #auditUI.members>0 then auditUI.stale=true; RenderAudit(); SetStatus("Group roster changed; the Instance Access audit is stale. Run Re-audit.") end
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
      Platform:ApplyVersion(compatUI.data)
      RenderCompatibility(); SetStatus("Capability registry loaded; reading permissions...")
    elseif kind=="PERMISSIONS" then
      compatUI.data=compatUI.data or {}; compatUI.received.PERMISSIONS=true
      compatUI.data.permissions=f.values or ""
      Platform:ApplyVersion(compatUI.data); if compatUI.updateRoleButtons then compatUI.updateRoleButtons() end; Platform:UpdateWorkspaceMode(); Platform:ApplyRoleButtonPolicies(); UpdateBindControls(); if characterUI.Update then characterUI.Update() end
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
    elseif kind=="CHARACTER_BEGIN" then
      local selected=CharacterContextName()
      characterUI.ignoreStream=not selected or selected~=f.player
      if not characterUI.ignoreStream then characterUI.capturePlayer=f.player; characterUI.server={begin=f,professions={},raid={}}; characterUI.statusText:SetText("Receiving Character data for "..tostring(f.player).."...") end
    elseif kind=="CHARACTER_OVERVIEW" then
      if not characterUI.ignoreStream then characterUI.server.overview=f end
    elseif kind=="CHARACTER_STATE" then
      if not characterUI.ignoreStream then characterUI.server.state=f end
    elseif kind=="CHARACTER_LOCATION" then
      if not characterUI.ignoreStream then characterUI.server.location=f end
    elseif kind=="CHARACTER_INVENTORY" then
      if not characterUI.ignoreStream then characterUI.server.inventory=f end
    elseif kind=="CHARACTER_PROFESSION" then
      if not characterUI.ignoreStream then table.insert(characterUI.server.professions,f) end
    elseif kind=="CHARACTER_RAID" then
      local settings=Settings()
      if f.raidkey==settings.characterRaid and f.difficultykey==settings.characterRaidDifficulty then table.insert(characterUI.server.raid,f) end
    elseif kind=="CHARACTER_RAID_END" then
      local settings=Settings(); local selected=CharacterContextName()
      if selected==f.player and f.raidkey==settings.characterRaid and f.difficultykey==settings.characterRaidDifficulty then
        characterUI.server.raidSelection=f; if characterUI.Update then characterUI.Update() end
        characterUI.statusText:SetText("Raid Experience loaded for "..tostring(f.player)..".")
      end
    elseif kind=="CHARACTER_END" then
      if not characterUI.ignoreStream and f.player==characterUI.capturePlayer then characterUI.Update(); characterUI.Log("Inspect","Authoritative Character data loaded for "..tostring(f.player)); characterUI.statusText:SetText("Module Character data loaded for "..tostring(f.player)) end
      characterUI.ignoreStream=false
    elseif kind=="CHARACTER_SAVE_RESULT" then
      local success=tostring(f.result):upper()=="SUCCESS"; characterUI.Log("Save Target",tostring(f.result).." — "..tostring(f.player)..": "..tostring(f.reason)); SetStatus((success and "Target saved: " or "Target save failed: ")..tostring(f.player).." — "..tostring(f.reason),not success)
    elseif kind=="CHARACTER_ERROR" then
      characterUI.Log("Character","ERROR — "..tostring(f.reason)); SetStatus(f.reason or "Character inspection failed",true)
    elseif kind=="NPC_SEARCH_BEGIN" then
      Platform.NPCUI.searchQuery=f.query or Platform.NPCUI.searchQuery or ""
      Platform.NPCUI.searchResults={}
      Platform.NPCUI.spawns={}
      Platform.NPCUI.spawnTotal=0
      Platform.NPCUI.selectedSearch=nil
      Platform.NPCUI.selectedSpawn=nil
      Platform.NPCUI.searchLoading=true
      Platform.NPCUI.spawnsLoading=false
      Platform.NPCUI.view="SEARCH"
      if Platform.NPCUI.Render then Platform.NPCUI.Render() end

    elseif kind=="NPC_SEARCH_RESULT" then
      table.insert(Platform.NPCUI.searchResults,f)
      if Platform.NPCUI.Render then Platform.NPCUI.Render() end

    elseif kind=="NPC_SEARCH_END" then
      Platform.NPCUI.searchLoading=false

      local results=Platform.NPCUI.searchResults or {}
      local query=tostring(Platform.NPCUI.searchQuery or "")
      query=query:gsub("^%s+",""):gsub("%s+$","")

      local autoResult=nil

      -- A unique search result is unambiguous.
      if #results==1 then
        autoResult=results[1]

      -- If several partial matches were returned, auto-select only when
      -- exactly one result is an exact Entry ID or exact creature name.
      elseif #results>1 and query~="" then
        local exactResult=nil
        local exactCount=0
        local numericQuery=query:match("^%d+$") and tonumber(query) or nil
        local lowerQuery=string.lower(query)

        for _,result in ipairs(results) do
          local exact=false

          if numericQuery then
            exact=tonumber(result.entry)==numericQuery
          else
            exact=string.lower(tostring(result.name or ""))==lowerQuery
          end

          if exact then
            exactResult=result
            exactCount=exactCount+1
          end
        end

        if exactCount==1 then
          autoResult=exactResult
        end
      end

      if autoResult and Platform.NPCUI.SelectSearchResult then
        SetStatus(
          string.format(
            "Selected %s [Entry %s] automatically — loading database spawns.",
            tostring(autoResult.name or "NPC"),
            tostring(autoResult.entry or "?")
          )
        )

        Platform.NPCUI.SelectSearchResult(autoResult)

      else
        if Platform.NPCUI.Render then
          Platform.NPCUI.Render()
        end

        SetStatus(
          string.format(
            "NPC search completed — %d result%s%s",
            tonumber(f.count) or #results,
            (tonumber(f.count) or #results)==1 and "" or "s",
            #results>1 and "; select the intended creature." or "."
          )
        )
      end

    elseif kind=="NPC_SPAWNS_BEGIN" then
      Platform.NPCUI.spawns={}
      Platform.NPCUI.spawnTotal=tonumber(f.total) or 0
      Platform.NPCUI.selectedSpawn=nil
      Platform.NPCUI.spawnsLoading=true
      Platform.NPCUI.view="SEARCH"

      if not Platform.NPCUI.selectedSearch
        or tonumber(Platform.NPCUI.selectedSearch.entry)~=tonumber(f.entry)
      then
        Platform.NPCUI.selectedSearch={
          entry=f.entry,
          name=f.name,
          spawns=f.total
        }
      end

      if Platform.NPCUI.Render then Platform.NPCUI.Render() end

    elseif kind=="NPC_SPAWN" then
      table.insert(Platform.NPCUI.spawns,f)
      if Platform.NPCUI.Render then Platform.NPCUI.Render() end

    elseif kind=="NPC_SPAWNS_END" then
      Platform.NPCUI.spawnsLoading=false

      -- Server order is authoritative: same-map spawns first and then
      -- nearest distance. Preselect the first row but never teleport
      -- until the user explicitly presses Go to Spawn.
      Platform.NPCUI.selectedSpawn=Platform.NPCUI.spawns[1]

      if Platform.NPCUI.Render then Platform.NPCUI.Render() end

      SetStatus(
        string.format(
          "Found %d of %d database spawn%s for %s.",
          tonumber(f.count) or #(Platform.NPCUI.spawns or {}),
          tonumber(Platform.NPCUI.spawnTotal) or #(Platform.NPCUI.spawns or {}),
          (tonumber(Platform.NPCUI.spawnTotal) or #(Platform.NPCUI.spawns or {}))==1 and "" or "s",
          tostring(
            Platform.NPCUI.selectedSearch
            and Platform.NPCUI.selectedSearch.name
            or "NPC"
          )
        )
      )

    elseif kind=="NPC_BEGIN" then
      local selected=TargetCreatureEntry()
      Platform.NPCUI.ignoreStream=
        not selected
        or tonumber(selected)~=tonumber(f.entry)
        or tonumber(Platform.NPCUI.requestEntry)~=tonumber(f.entry)
      if not Platform.NPCUI.ignoreStream then
        Platform.NPCUI.captureEntry=tonumber(f.entry)
        Platform.NPCUI.server={begin=f,quests={},loot={},lootReferences={},story={}}
        Platform.NPCUI.lootLinkRetry=0
        Platform.NPCUI.lootLinkRetryPending=false
        SetStatus("Receiving NPC data for "..tostring(f.name).."...")
      end
    elseif kind=="NPC_OVERVIEW" then
      if not Platform.NPCUI.ignoreStream then Platform.NPCUI.server.overview=f end
    elseif kind=="NPC_STATE" then
      if not Platform.NPCUI.ignoreStream then Platform.NPCUI.server.state=f end
    elseif kind=="NPC_LOCATION" then
      if not Platform.NPCUI.ignoreStream then Platform.NPCUI.server.location=f end
    elseif kind=="NPC_SPAWN_INFO" then
      if not Platform.NPCUI.ignoreStream then
        Platform.NPCUI.server.spawn=f
      end
    elseif kind=="NPC_TECHNICAL" then
      if not Platform.NPCUI.ignoreStream then Platform.NPCUI.server.technical=f end
    elseif kind=="NPC_QUEST" then
      if not Platform.NPCUI.ignoreStream then table.insert(Platform.NPCUI.server.quests,f) end
    elseif kind=="NPC_LOOT" then
      if not Platform.NPCUI.ignoreStream then
        table.insert(Platform.NPCUI.server.loot,f)
      end
    elseif kind=="NPC_LOOT_REFERENCE" then
      if not Platform.NPCUI.ignoreStream then
        Platform.NPCUI.server.lootReferences=
          Platform.NPCUI.server.lootReferences or {}

        table.insert(
          Platform.NPCUI.server.lootReferences,
          f
        )
      end
    elseif kind=="NPC_STORY" then
      if not Platform.NPCUI.ignoreStream then table.insert(Platform.NPCUI.server.story,f) end
    elseif kind=="NPC_STORY_END" then
      if not Platform.NPCUI.ignoreStream then Platform.NPCUI.server.storyCount=tonumber(f.count) or 0 end
    elseif kind=="NPC_END" then
      if tonumber(f.entry)==tonumber(Platform.NPCUI.requestEntry) then
        Platform.NPCUI.requestEntry=nil
        Platform.NPCUI.inspectionLoading=false
      end
      local selected=TargetCreatureEntry()
      if not Platform.NPCUI.ignoreStream and tonumber(f.entry)==tonumber(Platform.NPCUI.captureEntry) and tonumber(selected)==tonumber(f.entry) then
        Platform.NPCUI.Update(); SetStatus(string.format("NPC inspection loaded for %s — %s quest relation(s)",f.name or "creature",f.quests or 0))
      end
      Platform.NPCUI.ignoreStream=false
    elseif kind=="NPC_ERROR" then
      Platform.NPCUI.requestEntry=nil
      Platform.NPCUI.inspectionLoading=false
      Platform.NPCUI.searchLoading=false
      Platform.NPCUI.spawnsLoading=false
      if Platform.NPCUI.Render then Platform.NPCUI.Render() end
      SetStatus(f.reason or "NPC operation failed",true)
    elseif kind=="ITEM_BEGIN" then
      if tonumber(f.id)==tonumber(Platform.ItemUI.captureId) then
        Platform.ItemUI.server={begin=f,crafts={},reagents={},recipes={},sources={},uses={},requirements={},access=nil,preview=nil}; Platform.ItemUI.loading=true
      end
    elseif kind=="ITEM_ACCESS" then
      if Platform.ItemUI.loading then Platform.ItemUI.server.access=f; if Platform.ItemUI.Render then Platform.ItemUI.Render() end end
    elseif kind=="ITEM_PREVIEW" then
      if Platform.ItemUI.loading then Platform.ItemUI.server.preview=f; if Platform.ItemUI.Render then Platform.ItemUI.Render() end end
    elseif kind=="ITEM_REQUIREMENT" then
      if Platform.ItemUI.loading then table.insert(Platform.ItemUI.server.requirements,f); if Platform.ItemUI.Render then Platform.ItemUI.Render() end end
    elseif kind=="ITEM_CRAFT" then
      if Platform.ItemUI.loading then table.insert(Platform.ItemUI.server.crafts,f) end
    elseif kind=="ITEM_REAGENT" then
      if Platform.ItemUI.loading then table.insert(Platform.ItemUI.server.reagents,f) end
    elseif kind=="ITEM_RECIPE" then
      if Platform.ItemUI.loading then table.insert(Platform.ItemUI.server.recipes,f) end
    elseif kind=="ITEM_SOURCE" then
      if Platform.ItemUI.loading then table.insert(Platform.ItemUI.server.sources,f) end
    elseif kind=="ITEM_USE" then
      if Platform.ItemUI.loading then table.insert(Platform.ItemUI.server.uses,f) end
    elseif kind=="ITEM_END" then
      if tonumber(f.id)==tonumber(Platform.ItemUI.captureId) then Platform.ItemUI.loading=false; if Platform.ItemUI.Render then Platform.ItemUI.Render() end; SetStatus(string.format("Item inspection loaded — %s crafting method(s)",f.crafts or 0)) end
    elseif kind=="ITEM_ERROR" then
      Platform.ItemUI.loading=false; SetStatus(f.reason or "Item inspection failed",true); if Platform.ItemUI.Render then Platform.ItemUI.Render() end
    elseif kind=="MOVEMENT_CATALOG_BEGIN" then
      Platform.MovementUI.serverCatalog={}; Platform.MovementUI.loading=true
    elseif kind=="MOVEMENT_DESTINATION" then
      local d={id=tonumber(f.id),name=f.name,category=f.category,map=tonumber(f.map),x=tonumber(f.x),y=tonumber(f.y),z=tonumber(f.z),o=tonumber(f.o),source="AzerothCore game_tele"}; table.insert(Platform.MovementUI.serverCatalog,d)
    elseif kind=="MOVEMENT_CATALOG_END" then
      Platform.MovementUI.loading=false; if Platform.MovementUI.RefreshCatalog then Platform.MovementUI.RefreshCatalog() end; if Platform.MovementUI.Render then Platform.MovementUI.Render() end; SetStatus("Loaded "..tostring(f.count or #Platform.MovementUI.serverCatalog).." server destinations plus the validated built-in catalogue")
    elseif kind=="MOVEMENT_CURRENT" then
      if Platform.MovementUI.OnCurrent then Platform.MovementUI.OnCurrent(f) end
    elseif kind=="MOVEMENT_RESULT" then
      SetStatus((f.result or "Movement").." — "..tostring(f.reason or ""),f.result~="SUCCESS")
    elseif kind=="MOVEMENT_ERROR" then
      SetStatus(f.reason or "Movement operation failed",true)
    elseif kind=="ERROR" then
      SetStatus(f.reason or "AzerCore Ops server-module error",true)
    elseif kind=="QUEST_SEARCH" then
      if #questUI.results<50 then
        table.insert(questUI.results,f)
      end

      RenderQuest()

      local mode=questUI.pendingSearchMode or questUI.searchMode or "QUEST"

      if mode=="ITEM" then
        SetStatus(#questUI.results.." quest(s) matched the required item")
      else
        SetStatus(#questUI.results.." quest match(es)")
      end

    elseif kind=="QUEST_SEARCH_END" then
      local mode=questUI.pendingSearchMode or questUI.searchMode or "QUEST"

      if #questUI.results==0 then
        if mode=="ITEM" then
          SetStatus("No quests requiring that item were found.",true)
        else
          SetStatus("No matching quests found.",true)
        end
      else
        if mode=="ITEM" then
          SetStatus(
            #questUI.results..
            " item-related quest result(s); select one for details"
          )
        else
          SetStatus(
            #questUI.results..
            " quest result(s); select one for details"
          )
        end
      end

      questUI.pendingSearchMode=nil
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
      if f.title and questSearchBox and questUI.activeWorkspace=="DATABASE" and (questSearchBox:GetText() or "")=="" then questSearchBox:SetText(f.title) end
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
    elseif kind=="ENCOUNTER_DIAG_BEGIN" then
      instanceUI.diagnostics={findings={},recoveries={},loading=true,header=f,summary=nil,error=nil,generatedAt=nil,historyIndex=0,mode="SCAN"}; if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end; SetStatus("Diagnosing "..tostring(f.name or "current instance").."...")
    elseif kind=="ENCOUNTER_DIAG_FINDING" then
      table.insert(instanceUI.diagnostics.findings,f); if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
    elseif kind=="ENCOUNTER_DIAG_RECOVERY" then
      instanceUI.diagnostics.recoveries=instanceUI.diagnostics.recoveries or {}; table.insert(instanceUI.diagnostics.recoveries,f); if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
    elseif kind=="ENCOUNTER_DIAG_END" then
      instanceUI.diagnostics.loading=false; instanceUI.diagnostics.summary={passed=tonumber(f.passed) or 0,warnings=tonumber(f.warnings) or 0,failures=tonumber(f.failures) or 0}; instanceUI.diagnostics.generatedAt=date("%Y-%m-%d %H:%M:%S")
      AzerCoreOpsDB.diagnosticHistory=AzerCoreOpsDB.diagnosticHistory or {}; local snapshot={header=instanceUI.diagnostics.header,summary=instanceUI.diagnostics.summary,error=instanceUI.diagnostics.error,generatedAt=instanceUI.diagnostics.generatedAt,findings={},recoveries={}}
      for _,finding in ipairs(instanceUI.diagnostics.findings or {}) do local copy={}; for key,value in pairs(finding) do copy[key]=value end; table.insert(snapshot.findings,copy) end
      for _,recovery in ipairs(instanceUI.diagnostics.recoveries or {}) do local copy={}; for key,value in pairs(recovery) do copy[key]=value end; table.insert(snapshot.recoveries,copy) end
      table.insert(AzerCoreOpsDB.diagnosticHistory,1,snapshot); while #AzerCoreOpsDB.diagnosticHistory>100 do table.remove(AzerCoreOpsDB.diagnosticHistory) end
      if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end; SetStatus(string.format("Encounter scan complete: %d passed, %d warnings, %d failures",instanceUI.diagnostics.summary.passed,instanceUI.diagnostics.summary.warnings,instanceUI.diagnostics.summary.failures),instanceUI.diagnostics.summary.failures>0)
    elseif kind=="ENCOUNTER_DIAG_ERROR" then
      instanceUI.diagnostics.loading=false; instanceUI.diagnostics.error=f.reason or "Encounter diagnostic failed"; if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end; SetStatus(instanceUI.diagnostics.error,true)
    elseif kind=="ENCOUNTER_HISTORY_BEGIN" then
      instanceUI.diagnostics.mode="HISTORY"
      instanceUI.encounterHistory={entries={},stats={},loading=true,header=f,summary=nil,error=nil,generatedAt=nil}
      if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
      SetStatus("Receiving encounter history for "..tostring(f.name or "current instance").."...")
    elseif kind=="ENCOUNTER_HISTORY_ENTRY" then
      instanceUI.encounterHistory.entries=instanceUI.encounterHistory.entries or {}
      table.insert(instanceUI.encounterHistory.entries,f)
      if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
    elseif kind=="ENCOUNTER_HISTORY_STATS" then
      instanceUI.encounterHistory.stats=instanceUI.encounterHistory.stats or {}
      table.insert(instanceUI.encounterHistory.stats,f)
      if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
    elseif kind=="ENCOUNTER_HISTORY_END" then
      instanceUI.encounterHistory.loading=false
      instanceUI.encounterHistory.summary={count=tonumber(f.count) or 0,anomalies=tonumber(f.anomalies) or 0}
      instanceUI.encounterHistory.generatedAt=date("%Y-%m-%d %H:%M:%S")
      if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
      SetStatus(string.format("Encounter history loaded: %d signals, %d suspicious",instanceUI.encounterHistory.summary.count,instanceUI.encounterHistory.summary.anomalies),instanceUI.encounterHistory.summary.anomalies>0)
    elseif kind=="ENCOUNTER_HISTORY_ERROR" then
      instanceUI.diagnostics.mode="HISTORY"
      instanceUI.encounterHistory.loading=false
      instanceUI.encounterHistory.error=f.reason or "Encounter history request failed"
      if instanceUI.RenderDiagnostics then instanceUI.RenderDiagnostics() end
      SetStatus(instanceUI.encounterHistory.error,true)
    elseif kind=="BIND_BEGIN" then
      instanceUI.bindScope=f.scope or instanceUI.bindScope or "TARGET"
      instanceUI.ignoreBindStream=false
      if instanceUI.bindScope=="TARGET" then
        local current=tostring(SelectedPlayerName() or ""):match("^[^-]+") or ""
        local received=tostring(f.player or ""):match("^[^-]+") or ""
        if current=="" or received:lower()~=current:lower() then
          instanceUI.ignoreBindStream=true; LogBindActivity("Ignored stale target bind response for "..tostring(f.player or "unknown"),"STALE"); return
        end
      end
      if instanceUI.bindScope=="SELF" then instanceUI.my={}; instanceUI.myLoadState="LOADING" else instanceUI.target={}; instanceUI.targetLoadState="LOADING"; instanceUI.inspectedPlayer=f.player or instanceUI.inspectedPlayer end
      RenderInstances(); SetStatus("Receiving "..tostring(f.count or 0).." structured bind(s) for "..tostring(f.player or "player").."...")
    elseif kind=="BIND_ENTRY" then
      if instanceUI.ignoreBindStream then return end
      local row={name=f.name,map=tonumber(f.map),instance=tonumber(f.instance),id=tonumber(f.instance),difficulty=tonumber(f.difficulty),difficultyName=BindDifficultyName(f.difficulty,f.type=="raid"),perm=f.permanent,permanent=f.permanent,extended=f.extended,canReset=f.canreset,applicable=f.applicable,reset=tonumber(f.reset),ttr=ShortTime(f.reset),encountermask=tonumber(f.encountermask) or 0,bosstotal=tonumber(f.bosstotal) or 0,bossdefeated=tonumber(f.bossdefeated) or 0,reason=f.reason,isRaid=f.type=="raid",bosses={}}
      table.insert(instanceUI.bindScope=="SELF" and instanceUI.my or instanceUI.target,row); RenderInstances()
    elseif kind=="BIND_BOSS" then
      if instanceUI.ignoreBindStream then return end
      local rows=instanceUI.bindScope=="SELF" and instanceUI.my or instanceUI.target
      for index=#rows,1,-1 do local r=rows[index]; if tonumber(r.map)==tonumber(f.map) and tonumber(r.instance)==tonumber(f.instance) and tonumber(r.difficulty)==tonumber(f.difficulty) then table.insert(r.bosses,{index=tonumber(f.index),defeated=f.defeated,name=f.name}); break end end
      RenderInstances()
    elseif kind=="BIND_END" then
      if instanceUI.ignoreBindStream then instanceUI.ignoreBindStream=false; return end
      if instanceUI.bindScope=="TARGET" then instanceUI.targetLoadState="LOADED"; instanceUI.inspectedPlayer=f.player or instanceUI.inspectedPlayer; instanceUI.inspectedAt=date("%H:%M:%S") else instanceUI.myLoadState="LOADED" end
      LogBindActivity(string.format("Structured %s binds loaded for %s: %s",instanceUI.bindScope or "",f.player or "player",f.count or 0),"RESULT"); RenderInstances(); SetStatus(tostring(f.count or 0).." structured bind(s) loaded for "..tostring(f.player or "player"))
    elseif kind=="UNBIND_BEGIN" then
      instanceUI.unbindOperation=f.operation; LogBindActivity("Operation "..tostring(f.operation).." started for "..tostring(f.player).." — "..tostring(f.requested).." bind(s)","UNBIND"); SetStatus("Batch unbind started for "..tostring(f.player).."...")
    elseif kind=="UNBIND_RESULT" then
      LogBindActivity(string.format("%s — Map %s, Difficulty %s, ID %s: %s",f.result or "RESULT",f.map or "?",f.difficulty or "?",f.instance or "?",f.reason or "No reason"),f.result=="SUCCESS" and "SUCCESS" or "FAILED")
    elseif kind=="UNBIND_END" then
      LogBindActivity(string.format("Operation %s complete: %s succeeded, %s failed",f.operation or "?",f.succeeded or 0,f.failed or 0),tonumber(f.failed)==0 and "SUCCESS" or "RESULT"); instanceUI.unbindOperation=nil; instanceUI.pendingUnbindCommands=math.max(0,(instanceUI.pendingUnbindCommands or 1)-1)
      if instanceUI.pendingUnbindCommands==0 then SetStatus(string.format("Batch unbind complete: %s succeeded, %s failed. Verifying target...",f.succeeded or 0,f.failed or 0)); After(.25,function() InspectTargetInstances(false) end) else SetStatus("Unbind batch segment complete; continuing...") end
    elseif kind=="SEARCH" then
      if #auditUI.search<8 then table.insert(auditUI.search,f) end; RenderAudit(); SetStatus(#auditUI.search.." instance match(es)")
    elseif kind=="SEARCH_END" then
      local count=tonumber(f.count) or #auditUI.search
      if count==0 then SetStatus("No matching instance found.",true) else SetStatus(count.." instance match(es) found.") end
    elseif kind=="BEGIN" then
      auditUI.members={}; auditUI.referenceId=tonumber(f.reference) or 0; auditUI.expectedMembers=tonumber(f.members) or 0; auditUI.stale=false; auditUI.generatedAt=nil; auditUI.groupVerdict="AUDITING"; auditUI.groupReason="Collecting live group access data"; RenderAudit(); SetStatus("Auditing "..(f.name or "instance").."...")
    elseif kind=="MEMBER" then
      table.insert(auditUI.members,f); RenderAudit()
    elseif kind=="END" then
      auditUI.generatedAt=date("%Y-%m-%d %H:%M:%S"); auditUI.stale=false; ComputeGroupVerdict(); RenderAudit()
      local granted,conflict,blocked,offline=0,0,0,0; for _,r in ipairs(auditUI.members) do PrepareAuditMember(r); if r.verdict=="GRANTED" then granted=granted+1 elseif r.verdict=="CONFLICT" then conflict=conflict+1 elseif r.verdict=="BLOCKED" then blocked=blocked+1 else offline=offline+1 end end
      SetStatus(string.format("%s: %d granted, %d conflict, %d blocked, %d offline",auditUI.groupVerdict,granted,conflict,blocked,offline))
    elseif kind=="ERROR" then SetStatus(f.reason or "Instance audit error",true) end
  elseif event=="CHAT_MSG_SYSTEM" and instanceUI.captureUntil>0 and GetTime()<=instanceUI.captureUntil then
    local plain=tostring(arg1):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local map,inst,perm,diff,canReset,ttr=plain:match("map:%s*(%d+),%s*inst:%s*(%d+),%s*perm:%s*(%a+),%s*diff:%s*(%d+),%s*canReset:%s*(%a+),%s*TTR:%s*(.-)%s*$")
    if map then
      local mapNumber=tonumber(map); local bindName=(GetMapNameByID and GetMapNameByID(mapNumber)) or ("Map "..map)
      table.insert(instanceUI.target,{name=bindName,map=mapNumber,instance=tonumber(inst),perm=perm,difficulty=tonumber(diff),difficultyName=BindDifficultyName(diff),canReset=canReset,ttr=ttr})
      LogBindActivity("Captured "..bindName.." — ID "..inst,"RESULT")
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
  ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,event,message)
    if event~="CHAT_MSG_SYSTEM" or not lookup.kind or GetTime()>lookup.expires then return false end
    local raw=tostring(message or "")
    local plain=raw:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local expectedLink=lookup.kind=="quest" and "|Hquest:" or "|Hitem:"
    if raw:find(expectedLink,1,true) or plain:match("^%s*%d+%s*%-%s*%b[]") then return true end
    if plain:lower():find("could not parse",1,true) or plain:lower():find("no ",1,true) and plain:lower():find("found",1,true) then return true end
    return false
  end)
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
