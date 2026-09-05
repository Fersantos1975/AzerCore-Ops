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

local function Diagnostics(addonBuild,actual)
  return {
    loading=false,
    header={
      name="Icecrown Citadel",
      map=631,
      instance=1,
      difficulty=0,
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

Test("Compare detects changed findings",function()
  local before=Report.Capture(Diagnostics("0.7.1d","FAIL"),{})
  local after=Report.Capture(Diagnostics("0.7.1d","NOT_STARTED"),{})
  local changes=Report.Compare(before,after)
  Equal(#changes,1,"change count")
  Equal(changes[1].kind,"CHANGED","change kind")
  Equal(changes[1].before.actual,"FAIL","before value")
  Equal(changes[1].after.actual,"NOT_STARTED","after value")
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

Test("Historical evidence is labelled",function()
  local before=Report.Capture(Diagnostics("0.7.1b"),{})
  local report=Report.Template(before,nil,"0.7.1d")
  Contains(report,"Historical evidence:","historical warning")
  Contains(report,"`0.7.1b`","captured build")
  Contains(report,"`0.7.1d`","active build")
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

print(string.format(
  "\nIssue report framework tests: %d passed, %d failed",
  passed,failed))

if failed>0 then os.exit(1) end
