# AzerCore Ops project status and handoff

Last updated: 20 September 2026

This is the continuity document for the active module and Windows addon work. Update it with every revision so a new development session can identify what is complete, what changed, what was validated, and what remains.

## Current release candidate

- Revision: **0.7.5j**
- Server branch: `feat/instance-intelligence-0.7.4`
- Publication state: prepared locally; not committed, pushed, tagged, or released
- Release rule: test first, publish only after the Export responsiveness and encounter-filter regressions pass
- Publication method: GitHub Desktop on Windows; the server does not need GitHub credentials

## 0.7.5j objective

Preserve the verified hitch-free live recorder while preventing very large Export reports from blocking the WoW client and excluding unrelated instance creatures from the active encounter trace.

### Module changes

- Encounter-history requests accept an optional mechanic sequence cursor.
- `MechanicEventRecorder::Show` returns only mechanic events newer than that cursor.
- Existing full-history behavior remains available when no cursor is supplied.
- Unnamed fallback `SCRIPT_CAST` events are accepted only when the caster belongs to an `observedCreatureEntries` list for the active encounter.
- Blood Council `FAIL` is allowed during pre-initialization only while Blood Prince Trash runtime state 14 remains incomplete; after completion the same state remains anomalous.
- Module version is synchronized to `0.7.5j`.

### Windows addon changes

- Tracks the most recently received mechanic sequence.
- Requests only new mechanic activity during live refresh.
- Preserves already received encounter and mechanic evidence.
- Batches streamed history, mechanic, and statistic updates.
- Renders the evidence workspace once at the end of a response instead of once per received row.
- Preserves the live view and scroll position during refresh.
- Splits selectable reports into 12,000-character parts with Previous/Next navigation.
- Does not automatically focus and select a multi-part report; the user selects only the current bounded part.
- Keeps report actions attached to the complete report, not only the visible part.
- Derives and displays Current Encounter State from the newest received transition per encounter.
- Renames initialization rows to Session Start Snapshot (Historical) and explicitly says they are not current state.
- Addon, configuration, TOC, and issue-report framework versions are synchronized to `0.7.5j`.

### Expected improvement

The 0.7.5g in-game test confirmed that incremental retrieval and batched rendering removed the live Full Trace hitches. A later blocker appeared when Export placed a 359,127-byte, 6,941-line report into one approximately 111,000-pixel EditBox and immediately selected it, leaving WoW unresponsive for about ten seconds. The bounded paged Export removed that stall. During 0.7.5j testing, loading the complete report into one EditBox through Copy Full or Courier Share still caused roughly 20-second stalls. Copy Full was therefore removed and Courier now renders a bounded 12,000-character preview while retaining the complete normalized report internally for posting. The corrected Share path was confirmed working in game.

The same Rotface export contained unrelated Blood Prince Council, Darkfallen, and Gunship actors. The module now retains named mechanics and unknown spells from profiled active-encounter creatures while rejecting generic casts from other creatures merely present in map 631.

A later live-progress snapshot contained 16 SetBossState signals. Rotface was correctly recorded as `IN_PROGRESS -> DONE`, but the historical initialization list still displayed its earlier `NOT_STARTED` value under the ambiguous heading `INITIAL STATE`. The addon now displays a derived current-state section and clearly labels that earlier list as historical. The sole suspicious signal was Blood Council `NOT_STARTED -> FAIL` before Blood Prince Trash completed; the dependency-aware allowance now classifies that pre-initialization transition as expected without weakening post-prerequisite anomaly detection.

## Completed foundation through 0.7.5f

- Profile-driven instance intelligence engine.
- Icecrown Citadel source audit and detailed encounter evidence coverage.
- Ulduar source audit and profile coverage.
- Boss state transitions, pulls, kills, wipes, resets, phases, doors, gates, valves, trash, spawns, deaths, releases, resurrection, and relevant spell/mechanic evidence where authoritative hooks exist.
- Manual, automatic, and configurable recording modes.
- Standard and full-trace evidence views.
- Live-progress review without stopping a recording.
- Automatic completed-session saving and saved-report recall.
- Persistent recording settings, movable settings interface, tooltip option, and floating recording control.
- Compatibility based on protocol/capabilities rather than requiring identical addon and module display versions.
- Issue-report evidence capture, correlation, comparison, redaction, and fingerprint binding.

Detailed implementation history remains in `CHANGELOG.md`, `RELEASE-NOTES.md`, `ROADMAP.md`, and the instance audit documents.

## Core and Playerbots findings

Tested changes and upstream reports that are outside the AzerCore Ops module are preserved in `docs/TESTED-UPSTREAM-FINDINGS.md`. This includes original and corrected code, reproduction evidence, local test results, upstream responses, and present patch status.

## Current validation

- Lua 5.1 syntax: passed
- Issue-report regression suite: 41 passed, 0 failed
- `tools/azercoreops-check`: passed
- `git diff --check`: passed
- Focused Export/filter/current-state assertions: passed
- Targeted `worldserver` compile: passed
- Current candidate: 14 tracked files changed plus 2 new documentation files

The 0.7.5g rebuild and live Full Trace test passed without the earlier recording hitches. The 0.7.5j source validation passes Lua 5.1 syntax, git diff checks, 41/41 issue-report regression tests, and AzerCore Ops preflight. Paged Export is responsive, and the corrected bounded Courier Share path has been confirmed working in game. The final 0.7.5j publication workflow remains.

## Required before publication

1. Complete the final 0.7.5j build/install verification.
2. Start the AzerothCore services and confirm the worldserver loads the module without errors.
3. Copy the matching addon files to the Windows WoW addon directory.
4. Confirm the addon reports 0.7.5j and completes the capability handshake.
5. Open the same large completed recording and verify Export opens promptly, reports `Part 1 of N`, and Previous/Next navigation remains responsive.
6. Record a representative ICC boss and verify Full Trace contains that boss and its profiled adds but no unrelated wing or encounter actors.
7. Confirm live progress remains hitch-free and stopping still saves the complete report.
8. Run the release checklist.
9. Commit the tested tree, transfer it to Windows, and publish through GitHub Desktop.
10. Create the pull request, merge it, tag 0.7.5j, and attach the Windows addon ZIP.

## Windows addon files

Copy these four matching files from the server:

- `addon/AzerCoreOps/AzerCoreOps_Config.lua`
- `addon/AzerCoreOps/AzerCoreOps.lua`
- `addon/AzerCoreOps/AzerCoreOps.toc`
- `addon/AzerCoreOps/IssueReportFramework.lua`

Destination:
