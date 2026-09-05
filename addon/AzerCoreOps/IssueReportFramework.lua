-- AzerCore Ops upstream issue-report framework.
-- Creates reviewable reports only. It never submits or modifies GitHub issues.

AzerCoreOpsIssueReport = AzerCoreOpsIssueReport or {}
local Report = AzerCoreOpsIssueReport

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

local function Safe(value)
  value=tostring(value or "")
  value=value:gsub("%d+%.%d+%.%d+%.%d+","[REDACTED_IP]")
  value=value:gsub("[A-Za-z]:\\[^%s]+","[REDACTED_PATH]")
  value=value:gsub("/home/[^%s]+","[REDACTED_PATH]")
  return value
end

function Report.Copy(value)
  return Copy(value)
end

function Report.Capture(diagnostics, encounterHistory)
  local snapshot={
    schema=1,
    captured=date("%Y-%m-%d %H:%M:%S"),
    diagnostics=Copy(diagnostics or {}),
    encounterHistory=Copy(encounterHistory or {}),
  }
  return snapshot
end

function Report.Compare(before, after)
  local result={}
  local beforeFindings=
    before and before.diagnostics and before.diagnostics.findings or {}
  local afterFindings=
    after and after.diagnostics and after.diagnostics.findings or {}
  local previous={}

  for _,finding in ipairs(beforeFindings) do
    previous[FindingKey(finding)]=finding
  end

  for _,finding in ipairs(afterFindings) do
    local key=FindingKey(finding)
    local old=previous[key]
    if not old then
      table.insert(result,{kind="ADDED",key=key,after=Copy(finding)})
    elseif tostring(old.severity)~=tostring(finding.severity)
      or tostring(old.actual)~=tostring(finding.actual)
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

  for key,finding in pairs(previous) do
    table.insert(result,{kind="REMOVED",key=key,before=Copy(finding)})
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
  table.insert(lines,"")

  if #changes==0 then
    table.insert(lines,"No diagnostic state changes were detected.")
  else
    for _,change in ipairs(changes) do
      local old=change.before or {}
      local new=change.after or {}
      table.insert(lines,string.format(
        "[%s] %s: %s -> %s",
        tostring(change.kind),tostring(change.key),
        tostring(old.actual or "not present"),
        tostring(new.actual or "not present")))
    end
  end

  return table.concat(lines,"\n")
end

local function SnapshotIdentity(snapshot)
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

local function CapturedAddonBuild(before, after)
  local snapshot=after or before
  local diagnostics=snapshot and snapshot.diagnostics or {}
  local evidence=diagnostics.evidence or {}
  return Trim(evidence.addon)
end

function Report.EvidenceFingerprint(before, after)
  return SnapshotIdentity(before).."=>"..SnapshotIdentity(after)
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

  if text:find("%d+%.%d+%.%d+%.%d+") then
    table.insert(issues,"Review or remove the detected IPv4 address.")
  end
  if text:find("[A-Za-z]:\\") or text:find("/home/",1,true) then
    table.insert(issues,"Review or remove the detected local path.")
  end
  if text:find("unknown",1,true) then
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
    setStatus(
      "Saved draft belongs to different evidence. Click New Issue Draft to replace it deliberately.",
      true)
    return
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

function Report.Readiness(draft, before, after)
  draft=draft or {}
  local missing={}
  local snapshot=after or before
  local diagnostics=snapshot and snapshot.diagnostics or nil
  local evidence=diagnostics and diagnostics.evidence or nil

  if not diagnostics or not diagnostics.header then
    table.insert(missing,"A completed diagnostic snapshot")
  end
  if Trim(draft.current)=="" then
    table.insert(missing,"Current Behaviour")
  end
  if Trim(draft.expected)=="" then
    table.insert(missing,"Expected Behaviour")
  end
  if Trim(draft.source)=="" then
    table.insert(missing,"Source")
  end
  if Trim(draft.steps)=="" then
    table.insert(missing,"Steps to reproduce")
  end
  if not evidence or Trim(evidence.core)=="" or evidence.core=="unknown" then
    table.insert(missing,"AzerothCore revision")
  end
  if Trim(draft.operatingSystem)=="" then
    table.insert(missing,"Operating system")
  end
  if Trim(draft.customChanges)=="" then
    table.insert(missing,"Custom changes or enabled modules")
  end

  local status=#missing==0 and "READY_FOR_REVIEW" or "DRAFT"
  return status,missing
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
      "- **%s** `%s`: `%s` → `%s`",
      Safe(change.kind),
      Safe(change.key),
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
