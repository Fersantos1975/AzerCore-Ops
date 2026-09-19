# AzerCore Ops 0.7.5f

AzerCore Ops 0.7.5f turns Instance Intelligence into a resumable, profile-driven recording workspace. It adds source-audited Ulduar coverage, richer Icecrown Citadel evidence, persistent recording controls, and a configurable addon interface while keeping diagnostics observational and bounded.

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
- Keeps addon, issue-report framework, configuration, and module versions synchronized at `0.7.5f`.
- Retains protocol v1 compatibility while evaluating actual compatibility separately from display-version equality.

## Validation

The 0.7.5f release candidate passed:

- Lua 5.1 syntax validation;
- 41 issue-report framework regression tests;
- project preflight;
- whitespace validation;
- full AzerothCore RelWithDebInfo rebuild;
- worldserver and authserver installation validation.

The rebuild completed successfully on 19 September 2026 with servers intentionally left offline and maintenance mode enabled.

## Safety and reporting

Recording and diagnostics remain observational. They do not modify encounter state or write recording events to the database. Recovery actions remain separate and require explicit authorization.

Issue reports remain editable local drafts and are never submitted automatically. Privacy validation continues to guard against sensitive local paths and unintended IPv4 addresses.
