date=os.date
dofile("addon/AzerCoreOps/IssueReportFramework.lua")

local Report=AzerCoreOpsIssueReport
local passed=0
local failed=0

local function Equal(actual,expected,message)
  if actual~=expected then
    error(string.format(
      "%s: expected %s, got %s",
      message or "values differ",tostring(expected),tostring(actual)))
  end
end

local function Contains(text,expected,message)
  if not tostring(text):find(expected,1,true) then
    error((message or "text missing value")..": "..expected)
  end
end

local function Test(name,fn)
  local ok,reason=pcall(fn)
  if ok then
    passed=passed+1
    print("PASS "..name)
  else
    failed=failed+1
    print("FAIL "..name..": "..tostring(reason))
  end
end

local function Diagnostics(addonBuild,actual,instanceId,difficulty,mapId)
  return {
    loading=false,
    requestId=101,
    header={
      name="Icecrown Citadel",
      map=mapId or 631,
      instance=instanceId or 1,
      difficulty=difficulty or 0,
      script="instance_icecrown_citadel",
    },
    summary={passed=1,warnings=0,failures=0},
    generatedAt="2026-09-05 11:00:00",
    evidence={
      addon=addonBuild or "0.7.1d",
      module="0.7.1",
      protocol="1",
      capschema="1",
      release="stable",
      modulegit="6cb5e9497",
      moduledirty="no",
      core="abcdef123456",
      coredate="2026-09-05 11:00:00 +0000",
      coredirty="no",
      playerbots="5397110cb",
      playerbotsdirty="no",
      build="RelWithDebInfo",
      built="Sep 5 2026 11:00:00",
    },
    findings={{
      category="BOSS_STATE",
      subject="Blood Council",
      severity="EXPECTED",
      actual=actual or "NOT_STARTED",
    }},
    recoveries={},
  }
end

local function History(instanceId,difficulty,mapId)
  return {
    loading=false,
    requestId=202,
    header={
      name="Icecrown Citadel",
      map=mapId or 631,
      instance=instanceId or 1,
      difficulty=difficulty or 0,
    },
    summary={count=1,anomalies=0},
    generatedAt="2026-09-05 11:00:01",
    entries={},
    stats={},
  }
end

Test("Capture makes a deep copy",function()
  local source=Diagnostics()
  local snapshot=Report.Capture(source,{})
  source.findings[1].actual="FAIL"
  Equal(snapshot.diagnostics.findings[1].actual,"NOT_STARTED",
    "captured finding changed with source")
end)

Test("CanCapture accepts completed diagnostics",function()
  local ready=Report.CanCapture(Diagnostics())
  Equal(ready,true,"completed diagnostics rejected")
end)

Test("CanCapture rejects loading diagnostics",function()
  local diagnostics=Diagnostics()
  diagnostics.loading=true
  local ready,reason=Report.CanCapture(diagnostics)
  Equal(ready,false,"loading diagnostics accepted")
  Contains(reason,"Wait","loading rejection reason")
end)

Test("MarkBefore clears stale After evidence",function()
  local evidence={
    after=Report.Capture(Diagnostics("0.7.1d","FAIL"),{}),
  }

  local ready,snapshot=Report.MarkBefore(
    evidence,Diagnostics("0.7.1d","NOT_STARTED"),History())

  Equal(ready,true,"Before capture rejected")
  if evidence.before~=snapshot then
    error("stored Before snapshot does not match returned snapshot")
  end
  Equal(evidence.after,nil,"stale After evidence was retained")
end)

Test("MarkAfter requires Before evidence",function()
  local evidence={}
  local ready,reason=Report.MarkAfter(evidence,Diagnostics(),History())

  Equal(ready,false,"After capture accepted without Before")
  Contains(reason,"Before","missing-Before rejection reason")
  Equal(evidence.after,nil,"After evidence was stored unexpectedly")
end)

Test("MarkAfter captures evidence after Before",function()
  local evidence={}
  local ready=Report.MarkBefore(evidence,Diagnostics(),History())
  Equal(ready,true,"Before capture rejected")

  local afterReady,snapshot=Report.MarkAfter(
    evidence,Diagnostics("0.7.1d","FAIL"),History())

  Equal(afterReady,true,"After capture rejected")
  if evidence.after~=snapshot then
    error("stored After snapshot does not match returned snapshot")
  end
  Equal(snapshot.diagnostics.findings[1].actual,"FAIL",
    "After snapshot content")
end)

Test("CanCaptureContext rejects scan/history instance mismatch",function()
  local ready,reason=Report.CanCaptureContext(Diagnostics(),History(2))
  Equal(ready,false,"mismatched scan/history context accepted")
  Contains(reason,"instance","scan/history mismatch reason")
end)

Test("MarkAfter rejects a different instance",function()
  local evidence={}
  local ready=Report.MarkBefore(evidence,Diagnostics(),History())
  Equal(ready,true,"Before capture rejected")
  local afterReady,reason=Report.MarkAfter(
    evidence,Diagnostics(nil,nil,2),History(2))
  Equal(afterReady,false,"different instance accepted")
  Contains(reason,"instance ID changed","instance mismatch reason")
  Equal(evidence.after,nil,"mismatched After evidence was stored")
end)

Test("MarkAfter rejects a different map",function()
  local evidence={}
  local ready=Report.MarkBefore(evidence,Diagnostics(),History())
  Equal(ready,true,"Before capture rejected")
  local afterReady,reason=Report.MarkAfter(
    evidence,Diagnostics(nil,nil,1,0,632),History(1,0,632))
  Equal(afterReady,false,"different map accepted")
  Contains(reason,"map changed","map mismatch reason")
end)

Test("MarkAfter rejects a different difficulty",function()
  local evidence={}
  local ready=Report.MarkBefore(evidence,Diagnostics(),History())
  Equal(ready,true,"Before capture rejected")
  local afterReady,reason=Report.MarkAfter(
    evidence,Diagnostics(nil,nil,1,1),History(1,1))
  Equal(afterReady,false,"different difficulty accepted")
  Contains(reason,"difficulty changed","difficulty mismatch reason")
end)

Test("Evidence session stores correlated request IDs",function()
  local evidence={}
  local ready,snapshot=Report.MarkBefore(evidence,Diagnostics(),History())
  Equal(ready,true,"Before capture rejected")
  Equal(snapshot.schema,2,"evidence schema")
  Equal(snapshot.session.map,631,"session map")
  Equal(snapshot.session.instance,1,"session instance")
  Equal(snapshot.session.difficulty,0,"session difficulty")
  Equal(snapshot.session.diagnosticRequestId,101,"diagnostic request ID")
  Equal(snapshot.session.historyRequestId,202,"history request ID")
end)

Test("MarkAfter scopes encounter history after Before",function()
  local evidence={}
  local beforeHistory=History()
  beforeHistory.entries={
    {seq=10,class="INFO",event="STATE"},
  }
  local ready=Report.MarkBefore(evidence,Diagnostics(),beforeHistory)
  Equal(ready,true,"Before capture rejected")

  local afterHistory=History()
  afterHistory.requestId=203
  afterHistory.entries={
    {seq=9,class="INFO",event="STATE"},
    {seq=10,class="INFO",event="STATE"},
    {seq=11,class="SUSPICIOUS",event="STATE"},
    {seq=12,class="INFO",event="PULL"},
  }
  local afterReady,snapshot=Report.MarkAfter(
    evidence,Diagnostics("0.7.1d","FAIL"),afterHistory)
  Equal(afterReady,true,"After capture rejected")
  Equal(#snapshot.encounterHistory.entries,4,"full history was not preserved")
  Equal(snapshot.historyWindow.startSequence,10,"history window start")
  Equal(snapshot.historyWindow.endSequence,12,"history window end")
  Equal(snapshot.historyWindow.count,2,"history window count")
  Equal(snapshot.historyWindow.anomalies,1,"history window anomaly count")
  Equal(tonumber(snapshot.historyWindow.entries[1].seq),11,"first scoped sequence")
  Equal(tonumber(snapshot.historyWindow.entries[2].seq),12,"second scoped sequence")
end)

Test("MarkAfter scopes mechanic activity after Before",function()
  local evidence={}
  local beforeHistory=History()
  beforeHistory.mechanics={{seq=40,event="ENCOUNTER_START",elapsed=1200000}}
  local ready=Report.MarkBefore(evidence,Diagnostics(),beforeHistory)
  Equal(ready,true,"Before capture rejected")

  local afterHistory=History()
  afterHistory.requestId=203
  afterHistory.mechanics={
    {seq=40,event="ENCOUNTER_START",elapsed=1200000},
    {seq=41,event="NPC_SPAWN",entry=38508,elapsed=1215000},
    {seq=42,event="NPC_DEATH",entry=38508,elapsed=1245000},
  }
  local afterReady,snapshot=Report.MarkAfter(evidence,Diagnostics(),afterHistory)
  Equal(afterReady,true,"After capture rejected")
  Equal(snapshot.historyWindow.startMechanicSequence,40,"mechanic window start")
  Equal(snapshot.historyWindow.endMechanicSequence,42,"mechanic window end")
  Equal(snapshot.historyWindow.mechanicCount,2,"mechanic window count")
  Equal(snapshot.historyWindow.mechanics[1].event,"NPC_SPAWN","first mechanic event")
  Equal(snapshot.historyWindow.mechanics[2].event,"NPC_DEATH","second mechanic event")
  Equal(snapshot.historyWindow.startMechanicElapsed,1200000,"mechanic elapsed baseline")
  Equal(snapshot.historyWindow.mechanics[1].sessionElapsed,15000,"first session-relative mechanic time")
  Equal(snapshot.historyWindow.mechanics[2].sessionElapsed,45000,"second session-relative mechanic time")
end)

Test("HistoryWindow preserves elapsed after encounter counter reset",function()
  local evidence={}
  local beforeHistory=History()
  beforeHistory.mechanics={{seq=50,event="NPC_DEATH",elapsed=78000}}
  Equal(Report.MarkBefore(evidence,Diagnostics(),beforeHistory),true,"Before capture rejected")

  local afterHistory=History()
  afterHistory.requestId=204
  afterHistory.mechanics={
    {seq=50,event="NPC_DEATH",elapsed=78000},
    {seq=51,event="ENCOUNTER_START",elapsed=0},
    {seq=52,event="MECHANIC_CAST",elapsed=17000},
    {seq=53,event="ENCOUNTER_KILL",elapsed=96000},
  }
  local ready,snapshot=Report.MarkAfter(evidence,Diagnostics(),afterHistory)
  Equal(ready,true,"After capture rejected")
  Equal(snapshot.historyWindow.mechanics[1].sessionElapsed,0,"reset start time")
  Equal(snapshot.historyWindow.mechanics[2].sessionElapsed,17000,"reset mechanic time")
  Equal(snapshot.historyWindow.mechanics[3].sessionElapsed,96000,"post-reset mechanic time")
end)

Test("Compare detects changed findings",function()
  local before=Report.Capture(Diagnostics("0.7.1d","FAIL"),{})
  local after=Report.Capture(Diagnostics("0.7.1d","NOT_STARTED"),{})
  local changes=Report.Compare(before,after)
  Equal(#changes,1,"change count")
  Equal(changes[1].kind,"CHANGED","change kind")
  Equal(changes[1].before.actual,"FAIL","before value")
  Equal(changes[1].after.actual,"NOT_STARTED","after value")
end)

Test("ComparisonText exposes severity-only changes",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Capture(Diagnostics(),{})
  after.diagnostics.findings[1].severity="WARNING"

  local changes=Report.Compare(before,after)
  Equal(#changes,1,"severity-only change count")
  Equal(changes[1].kind,"CHANGED","severity-only change kind")

  local report=Report.ComparisonText(before,after)
  Contains(
    report,
    "severity EXPECTED -> WARNING; actual NOT_STARTED -> NOT_STARTED",
    "severity-only comparison detail")
end)

Test("ComparisonText reports no changes",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Capture(Diagnostics(),{})
  local report=Report.ComparisonText(before,after)
  Contains(report,"Detected changes: 0","comparison count")
  Contains(report,"No diagnostic state changes were detected.",
    "no-change explanation")
end)

Test("Evidence fingerprint changes with evidence",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Copy(before)
  after.captured="2026-09-05 11:01:00"
  local first=Report.EvidenceFingerprint(before,nil)
  local second=Report.EvidenceFingerprint(before,after)
  if first==second then error("fingerprints should differ") end
end)

Test("Evidence fingerprint includes finding content",function()
  local first=Report.Capture(Diagnostics("0.7.1d","NOT_STARTED"),{})
  local changed=Report.Copy(first)
  changed.diagnostics.findings[1].actual="FAIL"

  Equal(changed.captured,first.captured,
    "test requires matching capture timestamps")
  Equal(changed.diagnostics.generatedAt,first.diagnostics.generatedAt,
    "test requires matching diagnostic timestamps")

  local originalFingerprint=Report.EvidenceFingerprint(first,nil)
  local changedFingerprint=Report.EvidenceFingerprint(changed,nil)

  if originalFingerprint==changedFingerprint then
    error("finding content did not affect evidence fingerprint")
  end
end)

Test("Historical evidence is labelled",function()
  local before=Report.Capture(Diagnostics("0.7.1b"),{})
  local report=Report.Template(before,nil,"0.7.1d")
  Contains(report,"Historical evidence:","historical warning")
  Contains(report,"`0.7.1b`","captured build")
  Contains(report,"`0.7.1d`","active build")
end)

Test("Compose exposes severity-only comparison changes",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Copy(before)
  after.diagnostics.findings[1].severity="WARNING"

  local report=Report.Compose({
    current="The diagnostic state changes unexpectedly.",
    expected="The diagnostic state should remain stable.",
    source="Verified in the instance diagnostic profile.",
    steps="1. Enter the instance. 2. Run the diagnostic scan.",
    notes="None provided.",
    operatingSystem="Debian GNU/Linux.",
    customChanges="No relevant custom changes.",
  },before,after)

  Contains(
    report,
    "severity `EXPECTED` → `WARNING`; actual `NOT_STARTED` → `NOT_STARTED`",
    "composed severity-only comparison detail")
end)

Test("Review names unfinished sections",function()
  local before=Report.Capture(Diagnostics(),{})
  local draft=Report.Template(before,nil,"0.7.1d")
  local state,issues=Report.ReviewText(draft)
  Equal(state,"DRAFT","template review state")
  Equal(#issues,6,"unfinished section count")
  Equal(issues[1],"Complete Current Behaviour.",
    "first unfinished section")
  Equal(issues[6],"Complete Custom changes or Modules.",
    "last unfinished section")
end)

Test("Review accepts a completed safe draft",function()
  local text=[[
### Current Behaviour
The encounter starts in an incorrect state.

### Expected Behaviour
The encounter remains NOT_STARTED before combat.

### Source
Verified in the encounter script.

### Steps to reproduce the problem
1. Enter a fresh instance.
2. Inspect the state.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]
  local state,issues=Report.ReviewText(text)
  Equal(state,"READY_FOR_REVIEW","completed review state")
  Equal(#issues,0,"completed review issues")
end)

Test("Compose preserves four-part version numbers",function()
  local before=Report.Capture(Diagnostics(),{})

  local report=Report.Compose({
    current="The problem occurs with component version 1.2.3.4.",
    expected="The component should behave normally.",
    source="Verified in the component source.",
    steps="1. Start the instance. 2. Reproduce the issue.",
    notes="None provided.",
    operatingSystem="Debian GNU/Linux.",
    customChanges="No relevant custom changes.",
  },before,nil)

  Contains(
    report,
    "component version 1.2.3.4",
    "four-part version was redacted")

  if report:find(
    "component version [REDACTED_IP]",1,true)
  then
    error("four-part version was treated as an IPv4 address")
  end
end)

Test("Compose redacts genuine IPv4 addresses",function()
  local before=Report.Capture(Diagnostics(),{})

  local report=Report.Compose({
    current="The server reported address 192.168.1.42.",
    expected="No server address should appear in the report.",
    source="Verified during reproduction.",
    steps="1. Start the instance. 2. Reproduce the issue.",
    notes="None provided.",
    operatingSystem="Debian GNU/Linux.",
    customChanges="No relevant custom changes.",
  },before,nil)

  Contains(report,"[REDACTED_IP]","IPv4 address was not redacted")

  if report:find("192.168.1.42",1,true) then
    error("IPv4 address remained in composed report")
  end
end)

Test("Review allows four-part version numbers",function()
  local text=[[
### Current Behaviour
The problem occurs with component version 1.2.3.4.

### Expected Behaviour
The component should behave normally.

### Source
Verified in the component source.

### Steps to reproduce the problem
1. Start the instance.
2. Reproduce the issue.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"READY_FOR_REVIEW","four-part version rejected")
  Equal(#issues,0,"four-part version produced review issues")
end)

Test("Review allows version label with linking verb",function()
  local text=[[
### Current Behaviour
The component version is 1.2.3.4.

### Expected Behaviour
The component should behave normally.

### Source
Verified in the component source.

### Steps to reproduce the problem
1. Start the instance.
2. Reproduce the issue.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"READY_FOR_REVIEW","version label with linking verb rejected")
  Equal(#issues,0,"version label with linking verb produced review issues")
end)

Test("Review rejects genuine IPv4 addresses",function()
  local text=[[
### Current Behaviour
The server reported address 192.168.1.42.

### Expected Behaviour
No server address should appear in the report.

### Source
Verified during reproduction.

### Steps to reproduce the problem
1. Start the instance.
2. Reproduce the issue.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"DRAFT","IPv4 address accepted")
  Equal(#issues,1,"IPv4 review issue count")
  Equal(
    issues[1],
    "Review or remove the detected IPv4 address.",
    "IPv4 review warning")
end)

Test("Compose redacts sensitive local paths",function()
  local before=Report.Capture(Diagnostics(),{})

  local report=Report.Compose({
    current="Logs were written under /home/cura/azerothcore/server.log.",
    expected="Local paths should not appear in the report.",
    source="Verified during reproduction.",
    steps="1. Start the instance. 2. Reproduce the issue.",
    notes="None provided.",
    operatingSystem="Debian GNU/Linux.",
    customChanges="No relevant custom changes.",
  },before,nil)

  Contains(report,"[REDACTED_PATH]","Unix home path was not redacted")

  if report:find("/home/cura/",1,true) then
    error("Unix home path remained in composed report")
  end
end)

Test("Review rejects sensitive local paths",function()
  local text=[[
### Current Behaviour
The file was written to C:\Users\cura\server.log.

### Expected Behaviour
Local paths should not appear in the report.

### Source
Verified during reproduction.

### Steps to reproduce the problem
1. Start the instance.
2. Reproduce the issue.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"DRAFT","sensitive Windows path accepted")
  Equal(#issues,1,"local-path review issue count")
  Equal(
    issues[1],
    "Review or remove the detected local path.",
    "local-path review warning")
end)

Test("Review allows bare path syntax examples",function()
  local text=[[
### Current Behaviour
The documentation mentions C:\ and /home/ as path syntax examples.

### Expected Behaviour
Documentation examples should remain valid.

### Source
Verified in documentation.

### Steps to reproduce the problem
1. Open the documentation.
2. Review the path syntax examples.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"READY_FOR_REVIEW","bare path syntax example rejected")
  Equal(#issues,0,"bare path syntax example produced review issues")
end)

Test("Review allows unknown in legitimate prose",function()
  local text=[[
### Current Behaviour
The root cause is currently unknown, but the encounter state changes unexpectedly.

### Expected Behaviour
The encounter state should remain stable.

### Source
Verified in the instance diagnostic profile.

### Steps to reproduce the problem
1. Enter the instance.
2. Run the diagnostic scan.

### Extra Notes
None provided.

### AC rev. hash/commit
`abcdef123456`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"READY_FOR_REVIEW","legitimate unknown prose rejected")
  Equal(#issues,0,"legitimate unknown prose produced review issues")
end)

Test("Review rejects generated unknown metadata",function()
  local text=[[
### Current Behaviour
The encounter state changes unexpectedly.

### Expected Behaviour
The encounter state should remain stable.

### Source
Verified in the instance diagnostic profile.

### Steps to reproduce the problem
1. Enter the instance.
2. Run the diagnostic scan.

### Extra Notes
None provided.

### AC rev. hash/commit
`unknown`

### Operating system
Debian GNU/Linux.

### Custom changes or Modules
No relevant custom changes.
]]

  local state,issues=Report.ReviewText(text)
  Equal(state,"DRAFT","generated unknown metadata accepted")
  Equal(#issues,1,"generated unknown metadata issue count")
  Equal(
    issues[1],
    "Replace or explain remaining unknown values.",
    "generated unknown metadata warning")
end)

Test("Draft is bound to its evidence fingerprint",function()
  AzerCoreOpsDB={}
  local before=Report.Capture(Diagnostics(),{})
  local ready=Report.NewDraft(before,nil,"0.7.1d")
  Equal(ready,true,"new draft rejected")
  Equal(
    AzerCoreOpsDB.issueReportDraftFingerprint,
    Report.EvidenceFingerprint(before,nil),
    "stored fingerprint")
end)

Test("Legacy evidence fingerprint migrates saved draft",function()
  AzerCoreOpsDB={}
  local before=Report.Capture(Diagnostics(),{})
  local diagnostics=before.diagnostics
  local evidence=diagnostics.evidence
  local header=diagnostics.header

  local legacyBefore=table.concat({
    tostring(before.captured or ""),
    tostring(diagnostics.generatedAt or ""),
    tostring(header.map or ""),
    tostring(header.instance or ""),
    tostring(header.difficulty or ""),
    tostring(evidence.addon or ""),
    tostring(evidence.core or ""),
  },"|")
  local legacyAfter=table.concat({"","","","","","",""},"|")

  AzerCoreOpsDB.issueReportDraftText="preserved legacy draft"
  AzerCoreOpsDB.issueReportDraftFingerprint=
    legacyBefore.."=>"..legacyAfter

  local shown=false
  local shownText=""
  local status=""

  Report.OpenDraft(
    before,nil,"0.7.1d",
    function(title,text)
      shown=true
      shownText=text
    end,
    function(message)
      status=message
    end)

  Equal(shown,true,"legacy saved draft was rejected")
  Equal(shownText,"preserved legacy draft",
    "legacy saved draft was replaced")
  Equal(
    AzerCoreOpsDB.issueReportDraftFingerprint,
    Report.EvidenceFingerprint(before,nil),
    "legacy fingerprint was not migrated")
  Equal(status,"","legacy migration produced an error status")
end)

Test("Different evidence cannot reuse a saved draft",function()
  AzerCoreOpsDB={}
  local before=Report.Capture(Diagnostics(),{})
  Report.NewDraft(before,nil,"0.7.1d")

  local after=Report.Copy(before)
  after.captured="2026-09-05 11:02:00"
  local shown=false
  local status=""
  Report.OpenDraft(
    before,after,"0.7.1d",
    function() shown=true end,
    function(message) status=message end)

  Equal(shown,false,"stale draft was shown")
  Contains(status,"different evidence","stale-draft warning")
end)

Test("Matching evidence reopens the saved draft",function()
  AzerCoreOpsDB={}
  local before=Report.Capture(Diagnostics(),{})
  Report.NewDraft(before,nil,"0.7.1d")

  local shown=false
  Report.OpenDraft(
    before,nil,"0.7.1d",
    function(title,text,label,callback)
      shown=true
      Contains(title,"upstream issue draft","draft title")
      Contains(text,"### Current Behaviour","draft content")
      Equal(label,"Review Draft","draft action")
      if type(callback)~="function" then
        error("review callback missing")
      end
    end,
    function() end)

  Equal(shown,true,"matching draft was not shown")
end)

Test("Compare ignores prerequisite respawn countdown-only changes",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Capture(Diagnostics(),{})
  before.diagnostics.findings={{
    category="PREREQUISITE_CREATURE",subject="Darkfallen Advisor [Entry 37571; Spawn 201479]",
    severity="PASS",actual="DEAD; expected Entry 37571; Spawn ID 201479; actual Entry 37571; DB position 4538.97, 2768.97, 350.963; respawn 82795s",
  }}
  after.diagnostics.findings={{
    category="PREREQUISITE_CREATURE",subject="Darkfallen Advisor [Entry 37571; Spawn 201479]",
    severity="PASS",actual="DEAD; expected Entry 37571; Spawn ID 201479; actual Entry 37571; DB position 4538.97, 2768.97, 350.963; respawn 82339s",
  }}
  Equal(#Report.Compare(before,after),0,"respawn countdown created noise")
end)

Test("Compare labels locality loss as not observed",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Capture(Diagnostics(),{})
  before.diagnostics.findings={{
    category="DOOR",subject="Blood Council left passage [201378]",
    severity="EXPECTED",actual="CLOSED/READY",
  }}
  after.diagnostics.findings={}
  local changes=Report.Compare(before,after)
  Equal(#changes,1,"not-observed change count")
  Equal(changes[1].kind,"NOT_OBSERVED","locality loss change kind")
  Contains(changes[1].after.actual,"Not observed","not-observed explanation")
end)

Test("Compare ignores mechanic profile context",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Capture(Diagnostics(),{})
  before.diagnostics.findings={{
    category="MECHANIC_PROFILE",subject="Bone Storm",
    severity="INFO",actual="Transition; encounter script ID 0; spell IDs 69076",
  }}
  after.diagnostics.findings={}
  Equal(#Report.Compare(before,after),0,
    "static mechanic profile created a removed finding")
end)

Test("Compare ignores final target deselection",function()
  local before=Report.Capture(Diagnostics(),{})
  local after=Report.Capture(Diagnostics(),{})
  before.diagnostics.findings={{
    category="TARGET",subject="Deathbringer Saurfang",
    severity="PASS",actual="Entry 37813; alive; out of combat",
  }}
  after.diagnostics.findings={{
    category="TARGET",subject="Selected creature",
    severity="INFO",actual="No creature selected",
  }}
  local changes=Report.Compare(before,after)
  Equal(#changes,1,"unexpected final target deselection noise")
  Equal(changes[1].kind,"NOT_OBSERVED","boss target should become not observed")
end)

print(string.format(
  "\nIssue report framework tests: %d passed, %d failed",
  passed,failed))

if failed>0 then os.exit(1) end
