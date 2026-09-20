
## 0.7.5j - Evidence Review Usability

Large-report UI handling was finalized during live testing. The experimental Copy Full action was removed because constructing and selecting the complete Full Trace in one WoW 3.3.5 EditBox produced an approximately 20-second stall. Export remains paged at bounded size. Courier Share now renders only a bounded 12,000-character preview while retaining the complete normalized report internally for its chat splitting/posting path; the corrected Share behavior was confirmed working in game.

- Paginate the Encounter Evidence workspace so long Standard and Full Trace recordings remain lightweight and fully navigable.
- Show the active view explicitly as STANDARD or FULL TRACE, with page number and visible mechanic time range.
- Follow the newest evidence page while recording, but preserve an older page when the user navigates back.
- Keep paged selectable exports bounded and responsive; the experimental whole-report EditBox path was removed after live performance testing.
- Preserve the 0.7.5i incremental history/rendering performance fixes and evidence fidelity.

# AzerCore Ops 0.7.5i

AzerCore Ops 0.7.5i retains the hitch-free incremental recording workspace validated in 0.7.5g, makes very large selectable exports responsive through bounded paging, filters fallback spell evidence to the active profiled encounter, and clarifies current versus historical encounter state. It includes source-audited Ulduar coverage, rich Icecrown Citadel evidence, persistent recording controls, and a configurable addon interface while keeping diagnostics observational and bounded.

## Highlights

- Source-audited Ulduar profile covering all fourteen encounters, hard-mode paths, progression gates, tracked objects, and runtime signals.
- Resumable instance-journey recording with Manual, Automatic Instance, and Off modes.
- Standard, Full Trace, and Custom recording detail levels.
- Live progress viewing without stopping or finalizing the active recording.
- Saved completed sessions with configurable retention and recall.
- Movable floating recorder status control with continuously updated mode, state, detail level, and elapsed time.
- Recording controls available directly from the floating control's right-click menu.
- Dedicated configuration file and improved Recording & Interface settings.
- Compatibility decisions based on protocol/capability support rather than requiring identical addon and module display versions.
- Incremental Live Recording refreshes that request only mechanic events newer than the last received sequence.
- Batched addon processing that avoids rebuilding the evidence frame for every streamed event.
- Paged selectable Export for large reports, with Previous/Next navigation and no automatic selection of an entire multi-part trace.
- Active-encounter filtering for unnamed fallback script casts, preventing unrelated ICC actors from polluting a boss recording.
- Dependency-aware Blood Council pre-initialization handling and a clearly derived Current Encounter State.

## Live recording performance

Live Progress now sends the last received mechanic sequence with its history request. The module preserves full-history behavior when no cursor is supplied, but a live refresh returns only newer mechanic events. The addon retains accumulated history, preserves the user's scroll position, collects the streamed batch without per-row rerendering, and refreshes the evidence frame once when the response ends.

These changes reduce duplicate protocol traffic and repeated Lua layout work while preserving complete evidence for diagnostics, completed reports, saved-session recall, Share, and Export. The 0.7.5g in-game Full Trace test confirmed that the earlier live-recording hitches were removed.

## Export responsiveness and evidence scope

A captured 4:26 Rotface Full Trace produced a 359,127-byte, 6,941-line selectable report. The old Export path assigned all text to one EditBox, expanded it to roughly 111,000 pixels, focused it, and selected the complete contents. The video showed the WoW client becoming unresponsive for about ten seconds. Export now divides selectable text into bounded 12,000-character parts and selects only on explicit user request. Previous and Next navigate the complete report without constructing one enormous editable region.

The same trace revealed generic `SCRIPT_CAST` rows from Blood Prince Council, Darkfallen, and Gunship actors. The fallback recorder now accepts unnamed spells only from creatures listed for the active encounter. Named profile mechanics remain unchanged, and unknown spells from the current boss or its profiled adds remain available for auditing.

## Encounter-state clarity

The Rotface trace correctly recorded `NOT_STARTED -> IN_PROGRESS -> DONE`, but a bottom section labeled `INITIAL STATE` repeated Rotface's historical `NOT_STARTED` initialization row and looked current. The addon now derives a Current Encounter State from the latest received transition for each encounter and labels initialization rows `SESSION START SNAPSHOT (HISTORICAL)`.

Blood Council emitted `NOT_STARTED -> FAIL` before the Blood Prince Trash runtime prerequisite completed. The ICC profile already modeled that dependency; it now explicitly allows FAIL during that pre-initialization window. The same transition remains suspicious once Blood Prince Trash is complete, preserving anomaly detection.

## Recording workspace

The Diagnostics workspace is separated into Diagnostic Scan, Live Recording, and Saved Reports. Manual remains the default recording mode. Automatic Instance mode can follow a profiled instance journey, while Off disables recording deliberately.

A session is associated with the active character, map, difficulty, and Instance ID. Supported lifecycle evidence includes entering or leaving an instance, disconnect/re-entry continuity, death, spirit release, resurrection, encounter transitions, profiled creatures, relevant game objects, spells, auras, and phase hints.

The current recording can be inspected through View Live Progress without stopping it. Stopping a manual recording finalizes and saves the session, allowing it to be recalled with the Older and Newer controls.

## Evidence detail and export

Standard view emphasizes encounter milestones and condenses repeated trash or add activity. Full Trace preserves detailed event-by-event evidence. Custom mode lets the user independently include boss events, phase hints, objects, lifecycle events, trash, spells, and auras.

Standard and Full Recording switch inside the Encounter Evidence frame. Share and Export use complete evidence by default, with a setting to use only the visible view. Selectable export remains available for manual copying.

Repeated high-volume events are bounded and condensed for readability without turning the recorder into an unbounded combat-log collector.

## Interface and configuration

The addon now loads `AzerCoreOps_Config.lua` before the main implementation so defaults and migrations have one owner. Recording settings are movable and remember their position.

The floating recorder can be shown or hidden, locked or unlocked, and configured to display elapsed time. Its right-click menu provides Start, Stop & Save, recording mode, detail level, and Custom Settings actions.

Global tooltip control, notification preferences, automatic completion behavior, instance-resume behavior, and saved-session retention are exposed through settings.

## Profile intelligence

Icecrown Citadel evidence includes source-verified encounter mechanics, prerequisite creatures, doors, valves, airlocks, sigils, transports, gauntlet progression, and exported runtime signals.

Ulduar adds all fourteen encounters and their major scripted mechanics, including hard-mode activation paths and instance progression objects. Profile mechanics remain contextual until an observed runtime spell, aura, creature, object, or state transition supplies evidence.

Player-controlled pets, guardians, totems, critters, and similar helpers are excluded from generic mechanic noise while boss-owned summons remain observable.

## Reliability improvements

- Keeps elapsed time and live encounter polling active when the main addon window or Diagnostics page is hidden.
- Uses reset-aware session-relative timestamps so a new encounter does not collapse its timeline to `+00:00`.
- Preserves complete evidence while showing a concise standard summary.
- Keeps addon, issue-report framework, configuration, and module versions synchronized at `0.7.5i`.
- Retains protocol v1 compatibility while evaluating actual compatibility separately from display-version equality.

## Validation

The 0.7.5i release candidate passed:

- Lua 5.1 syntax validation;
- 41 issue-report framework regression tests;
- project preflight;
- whitespace validation;
- full AzerothCore RelWithDebInfo rebuild of 0.7.5g;
- worldserver and authserver installation validation;
- in-game 0.7.5g Full Trace recording without the earlier hitches.

The synchronized 0.7.5i source must pass syntax, regression, preflight, and compile validation. The module must then be rebuilt and the Windows addon must pass the focused paged-Export and active-encounter filtering tests before this release is published.

## Safety and reporting

Recording and diagnostics remain observational. They do not modify encounter state or write recording events to the database. Recovery actions remain separate and require explicit authorization.

Issue reports remain editable local drafts and are never submitted automatically. Privacy validation continues to guard against sensitive local paths and unintended IPv4 addresses.
