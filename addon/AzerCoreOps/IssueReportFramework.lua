-- AzerCore Ops upstream issue-report framework.
-- Creates reviewable reports only. It never submits or modifies GitHub issues.

AzerCoreOpsIssueReport = AzerCoreOpsIssueReport or {}
local Report = AzerCoreOpsIssueReport
Report.FrameworkBuild="0.7.5f"
Report.FrameworkSchema=1

local function Trim(value)
  return tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function Copy(value, seen)
  if type(value)~="table" then return value end
  seen=seen or {}
  if seen[value] then return seen[value] end
  local result={}
  seen[value]=result
  for key,item in pairs(value) do result[Copy(key,seen)]=Copy(item,seen) end
  return result
end

local function FindingKey(finding)
  return tostring(finding.category or "UNKNOWN").."|"..
    tostring(finding.subject or "UNKNOWN")
end

local function IsIPv4(value)
  local a,b,c,d=value:match(
    "^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
  if not a then return false end

  for _,octet in ipairs({a,b,c,d}) do
    local number=tonumber(octet)
    if not number or number<0 or number>255 then
      return false
    end
  end

  return true
end

local function IsVersionContext(text, position)
  local before=text:sub(1,position-1):lower()
  local tail=before:sub(math.max(1,#before-40))

  if tail:match("%f[%a]version%s*[:=]?%s*$")
    or tail:match("%f[%a]version%s+is%s*$")
    or tail:match("%f[%a]ver%s*[:=]?%s*$")
    or tail:match("%f[%a]ver%s+is%s*$")
  then
    return true
  end

  return tail:match("%f[%a]v%s*$")~=nil
end

local function FindSensitiveIPv4(text, startPosition)
  local position=startPosition or 1

  while true do
    local first,last=text:find(
      "%d+%.%d+%.%d+%.%d+",position)

    if not first then return nil end

    local candidate=text:sub(first,last)
    local previous=first>1 and text:sub(first-1,first-1) or ""
    local following=last<#text and text:sub(last+1,last+1) or ""
    local beforePrevious=
      first>2 and text:sub(first-2,first-2) or ""
    local afterFollowing=
      last+1<#text and text:sub(last+2,last+2) or ""
    local extendsLeft=
      previous=="." and beforePrevious:match("%d")~=nil
    local extendsRight=
      following=="." and afterFollowing:match("%d")~=nil
    local bounded=
      not previous:match("%d") and
      not following:match("%d") and
      not extendsLeft and
      not extendsRight

    if bounded and IsIPv4(candidate)
      and not IsVersionContext(text,first)
    then
      return first,last
    end

    position=last+1
  end
end

local function ContainsSensitiveIPv4(value)
  value=tostring(value or "")
  return FindSensitiveIPv4(value,1)~=nil
end

local function RedactIPv4(value)
  value=tostring(value or "")
  local result={}
  local position=1

  while true do
    local first,last=FindSensitiveIPv4(value,position)
    if not first then
      table.insert(result,value:sub(position))
      break
    end

    table.insert(result,value:sub(position,first-1))
    table.insert(result,"[REDACTED_IP]")
    position=last+1
  end

  return table.concat(result)
end

local function ContainsSensitivePath(value)
  value=tostring(value or "")

  if value:find("[A-Za-z]:\\[^%s\\]") then
    return true
  end

  if value:find("/home/[^%s/]") then
    return true
  end

  return false
end

local function RedactSensitivePaths(value)
  value=tostring(value or "")
  value=value:gsub(
    "[A-Za-z]:\\[^%s\\][^%s]*",
    "[REDACTED_PATH]")
  value=value:gsub(
    "/home/[^%s/][^%s]*",
    "[REDACTED_PATH]")
  return value
end

local function Safe(value)
  value=RedactIPv4(value)
  value=RedactSensitivePaths(value)
  return value
end

function Report.Copy(value)
  return Copy(value)
end

local function HistorySequence(entry)
  return tonumber(entry and (entry.seq or entry.sequence)) or 0
end

local function LastHistorySequence(encounterHistory)
  local last=0
  for _,entry in ipairs(encounterHistory and encounterHistory.entries or {}) do
    last=math.max(last,HistorySequence(entry))
  end
  return last
end

local function LastMechanicSequence(encounterHistory)
  local last=0
  for _,entry in ipairs(encounterHistory and encounterHistory.mechanics or {}) do
    last=math.max(last,HistorySequence(entry))
  end
  return last
end

local function LastMechanicElapsed(encounterHistory)
  local last=0
  for _,entry in ipairs(encounterHistory and encounterHistory.mechanics or {}) do
    last=math.max(last,tonumber(entry and entry.elapsed) or 0)
  end
  return last
end

local function SessionIdentity(diagnostics, encounterHistory)
  diagnostics=diagnostics or {}
  encounterHistory=encounterHistory or {}
  local diagnosticHeader=diagnostics.header or {}
  return {
    schema=1,
    map=diagnosticHeader.map,
    instance=diagnosticHeader.instance,
    difficulty=diagnosticHeader.difficulty,
    diagnosticRequestId=diagnostics.requestId,
    historyRequestId=encounterHistory.requestId,
    diagnosticGeneratedAt=diagnostics.generatedAt,
    historyGeneratedAt=encounterHistory.generatedAt,
    historyLastSequence=LastHistorySequence(encounterHistory),
    mechanicLastSequence=LastMechanicSequence(encounterHistory),
    mechanicLastElapsed=LastMechanicElapsed(encounterHistory),
  }
end

function Report.Capture(diagnostics, encounterHistory)
  local snapshot={
    schema=2,
    captured=date("%Y-%m-%d %H:%M:%S"),
    session=SessionIdentity(diagnostics,encounterHistory),
    diagnostics=Copy(diagnostics or {}),
    encounterHistory=Copy(encounterHistory or {}),
  }
  return snapshot
end

local function ComparableActual(finding)
  local actual=tostring(finding and finding.actual or "")
  if finding and finding.category=="PREREQUISITE_CREATURE" then
    actual=actual:gsub("respawn%s+%d+%s*s","respawn <countdown>")
  end
  return actual
end

local NotObservedCategories={
  TARGET=true,DOOR=true,AIRLOCK=true,VALVE=true,MECHANIC=true,
  SIGIL=true,TRANSPORT=true,
}

local NonComparableCategories={
  MECHANIC_PROFILE=true,
}

local function IsFinalTargetDeselection(finding)
  return finding
    and tostring(finding.category or "")=="TARGET"
    and tostring(finding.subject or "")=="Selected creature"
    and tostring(finding.actual or "")=="No creature selected"
end

function Report.Compare(before, after)
  local result={}
  local beforeFindings=
    before and before.diagnostics and before.diagnostics.findings or {}
  local afterFindings=
    after and after.diagnostics and after.diagnostics.findings or {}
  local previous={}

  for _,finding in ipairs(beforeFindings) do
    if not NonComparableCategories[tostring(finding.category or "")] then
      previous[FindingKey(finding)]=finding
    end
  end

  for _,finding in ipairs(afterFindings) do
    if not NonComparableCategories[tostring(finding.category or "")] then
      local key=FindingKey(finding)
      local old=previous[key]
      if not old and IsFinalTargetDeselection(finding) then
        -- Losing the selected boss after a kill is expected UI/runtime context,
        -- not a meaningful diagnostic change.
      elseif not old then
        table.insert(result,{kind="ADDED",key=key,after=Copy(finding)})
      elseif tostring(old.severity)~=tostring(finding.severity)
        or ComparableActual(old)~=ComparableActual(finding)
      then
        table.insert(result,{
          kind="CHANGED",
          key=key,
          before=Copy(old),
          after=Copy(finding),
        })
      end
      previous[key]=nil
    end
  end

  for key,finding in pairs(previous) do
    if NotObservedCategories[tostring(finding.category or "")] then
      table.insert(result,{
        kind="NOT_OBSERVED",
        key=key,
        before=Copy(finding),
        after={
          severity="NOT_OBSERVED",
          actual="Not observed in final scan (possibly outside loaded grid/range)",
        },
      })
    else
      table.insert(result,{kind="REMOVED",key=key,before=Copy(finding)})
    end
  end

  table.sort(result,function(a,b)
    return tostring(a.key)<tostring(b.key)
  end)

  return result
end

function Report.CanCapture(diagnostics)
  if type(diagnostics)~="table" then
    return false,"Run a diagnostic scan first."
  end
  if diagnostics.loading then
    return false,"Wait for the diagnostic scan to finish."
  end
  if diagnostics.error then
    return false,"The diagnostic scan failed: "..tostring(diagnostics.error)
  end
  if not diagnostics.header or not diagnostics.summary
    or not diagnostics.generatedAt
  then
    return false,"A completed diagnostic scan is required."
  end
  return true
end

local function IdentityValueEqual(left,right)
  return tostring(left or "")==tostring(right or "")
end

local function SnapshotSession(snapshot)
  if type(snapshot)~="table" then return {} end
  if type(snapshot.session)=="table" then return snapshot.session end
  return SessionIdentity(snapshot.diagnostics or {},snapshot.encounterHistory or {})
end

function Report.CanCaptureContext(diagnostics, encounterHistory)
  local ready,reason=Report.CanCapture(diagnostics)
  if not ready then return false,reason end

  if type(encounterHistory)~="table" then
    return false,"Refresh encounter history before capturing evidence."
  end
  if encounterHistory.loading then
    return false,"Wait for encounter history to finish refreshing."
  end
  if encounterHistory.error then
    return false,"Encounter history failed: "..tostring(encounterHistory.error)
  end
  if not encounterHistory.header or not encounterHistory.summary
    or not encounterHistory.generatedAt
  then
    return false,"Fresh encounter history is required for evidence capture."
  end
  if not diagnostics.requestId or not encounterHistory.requestId then
    return false,"Fresh diagnostic and history request IDs are required."
  end

  local diagnosticHeader=diagnostics.header or {}
  local historyHeader=encounterHistory.header or {}
  for _,field in ipairs({"map","instance","difficulty"}) do
    if not IdentityValueEqual(diagnosticHeader[field],historyHeader[field]) then
      return false,"Diagnostic scan and encounter history describe different "..
        field.." values."
    end
  end

  return true
end

function Report.HistoryWindow(before, after)
  local previous=SnapshotSession(before)
  local startSequence=tonumber(previous.historyLastSequence) or
    LastHistorySequence(before and before.encounterHistory or {})
  local history=after and after.encounterHistory or {}
  local startMechanicSequence=tonumber(previous.mechanicLastSequence) or
    LastMechanicSequence(before and before.encounterHistory or {})
  local startMechanicElapsed=tonumber(previous.mechanicLastElapsed) or
    LastMechanicElapsed(before and before.encounterHistory or {})
  local window={
    schema=2,
    startSequence=startSequence,
    endSequence=LastHistorySequence(history),
    startMechanicSequence=startMechanicSequence,
    endMechanicSequence=LastMechanicSequence(history),
    startMechanicElapsed=startMechanicElapsed,
    entries={},
    mechanics={},
    count=0,
    mechanicCount=0,
    anomalies=0,
  }

  for _,entry in ipairs(history.entries or {}) do
    if HistorySequence(entry)>startSequence then
      local copy=Copy(entry)
      table.insert(window.entries,copy)
      if tostring(copy.classification or copy.class)=="SUSPICIOUS" then
        window.anomalies=window.anomalies+1
      end
    end
  end
  window.count=#window.entries
  local mechanicCounterReset=false
  for _,entry in ipairs(history.mechanics or {}) do
    if HistorySequence(entry)>startMechanicSequence then
      local copy=Copy(entry)
      local rawElapsed=tonumber(copy.elapsed) or 0
      -- Encounter elapsed resets when a new boss pull starts. Once a reset is
      -- detected, the complete new window uses the new counter directly.
      if rawElapsed<startMechanicElapsed then mechanicCounterReset=true end
      copy.sessionElapsed=mechanicCounterReset and rawElapsed or
        (rawElapsed-startMechanicElapsed)
      table.insert(window.mechanics,copy)
    end
  end
  window.mechanicCount=#window.mechanics
  return window
end

function Report.ValidateSameSession(before, diagnostics)
  local previous=SnapshotSession(before)
  local current=SessionIdentity(diagnostics,{})
  local labels={map="map",instance="instance ID",difficulty="difficulty"}
  for _,field in ipairs({"map","instance","difficulty"}) do
    if not IdentityValueEqual(previous[field],current[field]) then
      return false,string.format(
        "After evidence does not match Before: %s changed from %s to %s.",
        labels[field],tostring(previous[field] or "unknown"),
        tostring(current[field] or "unknown"))
    end
  end
  return true
end

function Report.MarkBefore(evidence, diagnostics, encounterHistory)
  if type(evidence)~="table" then
    return false,"Evidence storage is unavailable."
  end

  local ready,reason=Report.CanCaptureContext(diagnostics,encounterHistory)
  if not ready then return false,reason end

  evidence.before=Report.Capture(diagnostics,encounterHistory)
  evidence.after=nil
  return true,evidence.before
end

function Report.MarkAfter(evidence, diagnostics, encounterHistory)
  if type(evidence)~="table" then
    return false,"Evidence storage is unavailable."
  end

  if not evidence.before then
    return false,"Capture Before evidence first."
  end

  local ready,reason=Report.CanCaptureContext(diagnostics,encounterHistory)
  if not ready then return false,reason end

  ready,reason=Report.ValidateSameSession(evidence.before,diagnostics)
  if not ready then return false,reason end

  local snapshot=Report.Capture(diagnostics,encounterHistory)
  snapshot.historyWindow=Report.HistoryWindow(evidence.before,snapshot)
  snapshot.session.historyStartSequence=snapshot.historyWindow.startSequence
  snapshot.session.historyEndSequence=snapshot.historyWindow.endSequence
  evidence.after=snapshot
  return true,evidence.after
end

function Report.ComparisonText(before, after)
  local lines={"AzerCore Ops — Before/After Evidence"}
  table.insert(lines,"")
  table.insert(lines,"Before captured: "..tostring(
    before and before.captured or "not captured"))
  table.insert(lines,"After captured: "..tostring(
    after and after.captured or "not captured"))
  table.insert(lines,"")

  if not before or not after then
    table.insert(lines,
      "Both Before and After snapshots are required before comparison.")
    return table.concat(lines,"\n")
  end

  local changes=Report.Compare(before,after)
  table.insert(lines,"Detected changes: "..tostring(#changes))
  local historyWindow=after.historyWindow or Report.HistoryWindow(before,after)
  table.insert(lines,string.format(
    "Encounter transitions during run: %d (%d suspicious)",
    tonumber(historyWindow.count) or 0,
    tonumber(historyWindow.anomalies) or 0))
  table.insert(lines,"")

  if #changes==0 then
    table.insert(lines,"No diagnostic state changes were detected.")
  else
    for _,change in ipairs(changes) do
      local old=change.before or {}
      local new=change.after or {}
      table.insert(lines,string.format(
        "[%s] %s: severity %s -> %s; actual %s -> %s",
        tostring(change.kind),tostring(change.key),
        tostring(old.severity or "not present"),
        tostring(new.severity or "not present"),
        tostring(old.actual or "not present"),
        tostring(new.actual or "not present")))
    end
  end

  return table.concat(lines,"\n")
end

local function IdentityValue(value)
  value=tostring(value or "")
  return tostring(#value)..":"..value
end

local function FindingsIdentity(snapshot)
  local diagnostics=snapshot and snapshot.diagnostics or {}
  local findings=diagnostics.findings or {}
  local result={}

  for _,finding in ipairs(findings) do
    table.insert(result,table.concat({
      IdentityValue(finding.category),
      IdentityValue(finding.subject),
      IdentityValue(finding.severity),
      IdentityValue(finding.actual),
    },"|"))
  end

  table.sort(result)
  return table.concat(result,";")
end

local function SnapshotIdentity(snapshot)
  local diagnostics=snapshot and snapshot.diagnostics or {}
  local evidence=diagnostics.evidence or {}
  local header=diagnostics.header or {}
  return table.concat({
    IdentityValue(snapshot and snapshot.captured or ""),
    IdentityValue(diagnostics.generatedAt),
    IdentityValue(header.map),
    IdentityValue(header.instance),
    IdentityValue(header.difficulty),
    IdentityValue(evidence.addon),
    IdentityValue(evidence.core),
    IdentityValue(FindingsIdentity(snapshot)),
  },"|")
end

local function CapturedAddonBuild(before, after)
  local snapshot=after or before
  local diagnostics=snapshot and snapshot.diagnostics or {}
  local evidence=diagnostics.evidence or {}
  return Trim(evidence.addon)
end

local function LegacySnapshotIdentity(snapshot)
  local diagnostics=snapshot and snapshot.diagnostics or {}
  local evidence=diagnostics.evidence or {}
  local header=diagnostics.header or {}
  return table.concat({
    tostring(snapshot and snapshot.captured or ""),
    tostring(diagnostics.generatedAt or ""),
    tostring(header.map or ""),
    tostring(header.instance or ""),
    tostring(header.difficulty or ""),
    tostring(evidence.addon or ""),
    tostring(evidence.core or ""),
  },"|")
end

local function LegacyEvidenceFingerprint(before, after)
  return LegacySnapshotIdentity(before).."=>"..
    LegacySnapshotIdentity(after)
end

function Report.EvidenceFingerprint(before, after)
  return "v2|"..SnapshotIdentity(before).."=>"..SnapshotIdentity(after)
end

function Report.Template(before, after, activeBuild)
  local report=Report.Compose({
    current="[Describe what currently happens.]",
    expected="[Describe what should happen instead.]",
    source="[Provide the relevant source file, script, or database evidence.]",
    steps="[List the exact reproduction steps in order.]",
    notes="None provided.",
    operatingSystem="[Provide the server operating system and version.]",
    customChanges="[List enabled modules and disclose relevant custom changes.]",
  },before,after)

  local capturedBuild=CapturedAddonBuild(before,after)
  activeBuild=Trim(activeBuild)
  if capturedBuild~="" and activeBuild~=""
    and capturedBuild~=activeBuild
  then
    report=string.format(
      "> **Historical evidence:** captured with AzerCore Ops `%s`; current addon build is `%s`.\n\n%s",
      Safe(capturedBuild),Safe(activeBuild),report)
  end

  return report
end

function Report.ReviewText(text)
  text=tostring(text or "")
  local issues={}
  local headings={
    "### Current Behaviour",
    "### Expected Behaviour",
    "### Source",
    "### Steps to reproduce the problem",
    "### Extra Notes",
    "### AC rev. hash/commit",
    "### Operating system",
    "### Custom changes or Modules",
  }
  local instructions={
    {
      "[Describe what currently happens.]",
      "Complete Current Behaviour.",
    },
    {
      "[Describe what should happen instead.]",
      "Complete Expected Behaviour.",
    },
    {
      "[Provide the relevant source file, script, or database evidence.]",
      "Complete Source.",
    },
    {
      "[List the exact reproduction steps in order.]",
      "Complete Steps to reproduce.",
    },
    {
      "[Provide the server operating system and version.]",
      "Complete Operating system.",
    },
    {
      "[List enabled modules and disclose relevant custom changes.]",
      "Complete Custom changes or Modules.",
    },
  }

  for _,heading in ipairs(headings) do
    if not text:find(heading,1,true) then
      table.insert(issues,"Missing heading: "..heading)
    end
  end

  for _,instruction in ipairs(instructions) do
    if text:find(instruction[1],1,true) then
      table.insert(issues,instruction[2])
    end
  end

  if ContainsSensitiveIPv4(text) then
    table.insert(issues,"Review or remove the detected IPv4 address.")
  end
  if ContainsSensitivePath(text) then
    table.insert(issues,"Review or remove the detected local path.")
  end
  local unresolvedGeneratedValues={
    "Evidence captured: `unknown`",
    "Instance script: `unknown`",
    "AzerCore Ops addon `unknown`",
    "module `unknown`",
    "module commit `unknown`",
    "build `unknown`",
    "Core workspace: `unknown`",
    "core date: `unknown`",
    "AzerCore Ops workspace: `unknown`",
    "Playerbots commit: `unknown`",
    "Playerbots workspace: `unknown`",
  }

  local unresolved=false
  for _,marker in ipairs(unresolvedGeneratedValues) do
    if text:find(marker,1,true) then
      unresolved=true
      break
    end
  end

  if not unresolved
    and text:find("### AC rev%. hash/commit%s+`unknown`")
  then
    unresolved=true
  end

  if unresolved then
    table.insert(issues,"Replace or explain remaining unknown values.")
  end

  return #issues==0 and "READY_FOR_REVIEW" or "DRAFT",issues
end

function Report.NewDraft(before, after, activeBuild)
  if not before and not after then
    return false,"Capture Before or After evidence before starting a draft."
  end

  AzerCoreOpsDB.issueReportDraftFingerprint=
    Report.EvidenceFingerprint(before,after)
  AzerCoreOpsDB.issueReportDraftText=
    Report.Template(before,after,activeBuild)
  return true
end

function Report.OpenDraft(
  before, after, activeBuild, showReport, setStatus
)
  if not before and not after then
    setStatus("Capture Before or After evidence before building a report.",true)
    return
  end

  local fingerprint=Report.EvidenceFingerprint(before,after)
  if AzerCoreOpsDB.issueReportDraftText
    and not AzerCoreOpsDB.issueReportDraftFingerprint
  then
    setStatus(
      "Existing draft predates evidence tracking. Click New Issue Draft to bind a fresh draft to this evidence.",
      true)
    return
  end

  if AzerCoreOpsDB.issueReportDraftText
    and AzerCoreOpsDB.issueReportDraftFingerprint~=fingerprint
  then
    local legacyFingerprint=LegacyEvidenceFingerprint(before,after)
    if AzerCoreOpsDB.issueReportDraftFingerprint==legacyFingerprint then
      AzerCoreOpsDB.issueReportDraftFingerprint=fingerprint
    else
      setStatus(
        "Saved draft belongs to different evidence. Click New Issue Draft to replace it deliberately.",
        true)
      return
    end
  end

  if not AzerCoreOpsDB.issueReportDraftText then
    local ready,reason=Report.NewDraft(before,after,activeBuild)
    if not ready then setStatus(reason,true); return end
  end

  showReport(
    "AzerothCore upstream issue draft",
    AzerCoreOpsDB.issueReportDraftText,
    "Review Draft",
    function(editedText)
      AzerCoreOpsDB.issueReportDraftText=tostring(editedText or "")
      local state,issues=Report.ReviewText(
        AzerCoreOpsDB.issueReportDraftText)
      if state=="READY_FOR_REVIEW" then
        setStatus(
          "Issue draft saved and ready for human review before submission.")
      else
        setStatus(
          "Issue draft saved — "..table.concat(issues," "),true)
      end
    end)
end

local function AddFindings(lines, snapshot)
  local diagnostics=snapshot and snapshot.diagnostics or nil
  if not diagnostics then return end

  table.insert(lines,"")
  table.insert(lines,"#### AzerCore Ops diagnostic evidence")
  local header=diagnostics.header or {}
  table.insert(lines,string.format(
    "- Map: `%s` — %s",
    Safe(header.map or "?"),
    Safe(header.name or "Unknown instance")))
  table.insert(lines,"- Instance script: `"..Safe(header.script or "unknown").."`")
  table.insert(lines,"- Difficulty: `"..Safe(header.difficulty or "?").."`")

  for _,finding in ipairs(diagnostics.findings or {}) do
    if finding.severity=="FAIL" or finding.severity=="WARN" then
      table.insert(lines,string.format(
        "- **%s** `%s` — %s: expected `%s`; actual `%s`",
        Safe(finding.severity),
        Safe(finding.category),
        Safe(finding.subject),
        Safe(finding.expected),
        Safe(finding.actual)))
    end
  end
end

local function AddComparison(lines, before, after)
  if not before or not after then return end
  local changes=Report.Compare(before,after)
  table.insert(lines,"")
  table.insert(lines,"#### Before/after state changes")
  if #changes==0 then
    table.insert(lines,"- No diagnostic state changes were detected.")
    return
  end

  for _,change in ipairs(changes) do
    local old=change.before or {}
    local new=change.after or {}
    table.insert(lines,string.format(
      "- **%s** `%s`: severity `%s` → `%s`; actual `%s` → `%s`",
      Safe(change.kind),
      Safe(change.key),
      Safe(old.severity or "not present"),
      Safe(new.severity or "not present"),
      Safe(old.actual or "not present"),
      Safe(new.actual or "not present")))
  end
end

function Report.Compose(draft, before, after)
  draft=draft or {}
  local snapshot=after or before or {}
  local diagnostics=snapshot.diagnostics or {}
  local evidence=diagnostics.evidence or {}
  local lines={}

  table.insert(lines,"### Current Behaviour")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.current)))
  AddFindings(lines,snapshot)
  AddComparison(lines,before,after)

  table.insert(lines,"")
  table.insert(lines,"### Expected Behaviour")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.expected)))

  table.insert(lines,"")
  table.insert(lines,"### Source")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.source)))

  table.insert(lines,"")
  table.insert(lines,"### Steps to reproduce the problem")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.steps)))

  table.insert(lines,"")
  table.insert(lines,"### Extra Notes")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.notes)))
  table.insert(lines,"")
  table.insert(lines,"Evidence captured: `"..Safe(snapshot.captured or "unknown").."`")
  table.insert(lines,string.format(
    "AzerCore Ops addon `%s`; module `%s`; module commit `%s`; build `%s`.",
    Safe(evidence.addon or "unknown"),
    Safe(evidence.module or "unknown"),
    Safe(evidence.modulegit or "unknown"),
    Safe(evidence.build or "unknown")))

  table.insert(lines,"")
  table.insert(lines,"### AC rev. hash/commit")
  table.insert(lines,"")
  table.insert(lines,"`"..Safe(evidence.core or "unknown").."`")
  table.insert(lines,"")
  table.insert(lines,string.format(
    "Core workspace: `%s`; core date: `%s`.",
    Safe(evidence.coredirty or "unknown"),
    Safe(evidence.coredate or "unknown")))

  table.insert(lines,"")
  table.insert(lines,"### Operating system")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.operatingSystem)))

  table.insert(lines,"")
  table.insert(lines,"### Custom changes or Modules")
  table.insert(lines,"")
  table.insert(lines,Safe(Trim(draft.customChanges)))
  table.insert(lines,"")
  table.insert(lines,string.format(
    "AzerCore Ops workspace: `%s`; Playerbots commit: `%s`; Playerbots workspace: `%s`.",
    Safe(evidence.moduledirty or "unknown"),
    Safe(evidence.playerbots or "unknown"),
    Safe(evidence.playerbotsdirty or "unknown")))

  return table.concat(lines,"\n")
end
