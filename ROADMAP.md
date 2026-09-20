# AzerCore Ops Platform Roadmap

AzerCore Ops is an operational intelligence platform for AzerothCore built from a
server-side C++ module and a matching World of Warcraft 3.3.5a addon.

The current release candidate is `0.7.5j`. It preserves the verified live-recording performance work, makes very large selectable exports responsive, and prevents unrelated instance actors from entering an active boss trace.

## 0.7.5i — Responsive Export and Active-Encounter Filtering

Release-candidate scope:

- Add an optional mechanic-sequence cursor to Encounter History requests.
- Return only mechanic events newer than the addon's last received sequence during live refreshes.
- Preserve accumulated live history and the user's scroll position while a refresh is in flight.
- Batch streamed entries, mechanics, and statistics and render the evidence frame once when the response completes.
- Preserve full-history behavior for diagnostics, completed reports, Share, Export, and callers that do not provide a sequence cursor.
- Split large selectable Export text into bounded parts with Previous/Next navigation and no automatic whole-report selection.
- Keep action callbacks bound to the complete report rather than the currently visible export part.
- Restrict unnamed fallback script casts to profiled creatures belonging to the active encounter.
- Allow Blood Council's pre-initialization FAIL only while Blood Prince Trash remains incomplete.
- Show a derived Current Encounter State and label initialization rows as a historical session-start snapshot.
- Synchronize module, addon, configuration, reporter, and TOC revisions at `0.7.5i`.
- Complete rebuild, Windows addon deployment, and in-game export/filter regression testing before publication.

Planned after 0.7.5i:

- Add low-cost recorder-health counters for accepted, filtered, evicted, and buffered evidence plus per-category totals.
- Keep telemetry in memory and report it only on request; do not add recording-event database writes or continuous telemetry polling.
- Add the Trial of the Crusader map 649 profile across 10/25-player Normal and Heroic modes.
- Model ToC progression through authoritative `InstanceProgress` signals, encounter creatures, spells, auras, gates, the destructible floor, heroic attempts, and tribute rewards.

## 0.7.5f — Recording Workspace and Ulduar Intelligence

Completed release scope:

- Added resumable Manual, Automatic Instance, and Off recording modes.
- Added Standard, Full Trace, and Custom evidence levels with bounded profile filtering.
- Added live progress inspection without stopping an active session.
- Added saved completed recordings with configurable retention and recall.
- Added a movable floating recorder with continuously updated elapsed time and a right-click control menu.
- Added a dedicated addon configuration layer, movable settings, tooltip control, and share/export preferences.
- Added source-audited Ulduar coverage for all fourteen encounters, hard modes, progression objects, and runtime signals.
- Expanded ICC mechanics, creature, door, valve, airlock, sigil, transport, gauntlet, and phase evidence.
- Filtered player-controlled pets, guardians, totems, critters, and similar helpers while retaining boss-owned summons.
- Synchronized addon, reporter, configuration, and module revisions at `0.7.5f`.
- Passed 41 regression tests, project preflight, whitespace validation, and a full RelWithDebInfo AzerothCore rebuild.

## 0.7.4 — Instance Intelligence

Release scope:

- Correlate encounter history with current diagnostics instead of evaluating snapshots in isolation.
- Maintain source-verified ICC mechanics profiles for all twelve encounters.
- Record and classify encounter transitions as PULL, WIPE, RESET, KILL, or INITIALIZATION.
- Correlate ICC doors, valves, airlocks, sigils, prerequisite creatures, and runtime profile signals.
- Suppress static profile and expected target-deselection noise from Before/After evidence.
- Keep mechanic profiles distinct from future live mechanic-event capture.
- Harden progression gates so compound scripted controls, such as Putricide valve/airlock progression, are not reduced to boss-state prerequisites alone.

Post-0.7.4 direction:

- Continue the bounded live mechanic-event recorder filtered by the verified profile catalog.
- Correlate actor identity, timestamps, spells, summons, game objects, and encounter phases into diagnostic evidence.
- Expand encounter-profile validation beyond ICC without introducing map-specific assumptions into the generic engine.

### Instance journey recording

The recorder evolves from boss-only evidence into a resumable, profile-driven instance
session. Manual recording remains the default; Automatic Instance and Off are explicit
user choices.

Planned lifecycle:

- Bind a session to character, map, exact Instance ID, difficulty, and reset lifetime.
- Start manually by default, or automatically when entering a profiled instance when
  Automatic Instance mode is selected.
- Preserve the session when a player leaves, logs out, dies, releases spirit, or becomes
  a ghost; resume the same session when the same Instance ID is re-entered.
- Distinguish player presence events from shared instance progression so events that
  occur while the player is outside can be labelled accurately.
- Finalize on verified instance completion, reset/expiry, or explicit manual stop.
- Prevent duplicate starts and never overwrite a manual session with automation.

Planned evidence and progress:

- Record profile-relevant prerequisite trash, gauntlets, creatures, game objects, doors,
  valves, transports, boss transitions, summons, deaths, spells, auras, and phases.
- Avoid unbounded combat-log capture; profiles decide which signals are diagnostic.
- Maintain a live checklist with Completed, In Progress, Available, Blocked, Not Reached,
  Failed/Reset, Not Observed, and Recorded While Absent states.
- Allow the current timeline and checklist to be opened at any time without stopping or
  finalizing the recording.
- Retain a bounded configurable number of completed instance sessions.

Planned addon layout:

- Diagnostic Scan: read-only snapshot and Before/After comparison.
- Live Recording: session state, manual controls, live objectives, and chronological
  activity.
- History: server history, saved recordings, export, and retention controls.
- A compact recording-settings control selects Manual, Automatic Instance, or Off and
  exposes resume, completion, notification, and retention preferences.

## Completed foundation

### Quest Intelligence

- Quest search by numeric ID or title.
- Structured quest details, requirements, rewards, NPC relationships, and chains.
- SELF and TARGET inspection contexts.
- Complete active Quest Log inspection for a selected online player.
- Group quest auditing.
- Search history, activity reporting, copy, share, and export workflows.
- Player-specific numbered quest-chain presentation.
- Server-authoritative Player and GM operating modes.

### Character Intelligence

- Overview, Inventory, Professions, Raid Experience, and Technical Details.
- Event-driven target inspection and stale-response protection.
- Privacy-safe copy, share, and export reporting.
- Recorded raid-achievement evidence with raid and difficulty selection.
- Self-only character saving plus separately authorized GM target saving.

### Instance Intelligence

- Structured My Binds and Target Binds inspection.
- Exact Instance IDs, difficulty, reset information, and encounter progress.
- Group access auditing and bind comparison.
- Safe multi-select instance unbinding with confirmation and verification.
- Profile-driven instance diagnostics.
- Dynamic recovery guidance.
- Encounter History.
- Encounter-state anomaly detection.
- Per-encounter Attempts, Wipes, and Kills tracking.
- PULL, WIPE, RESET, and KILL event presentation.
- Direct `IN_PROGRESS -> NOT_STARTED` wipe detection.
- Protection against double-counting alternate wipe/reset chains.

### Item, NPC, and Movement foundations

- Server-backed Item inspection, crafting, sources, uses, and access information.
- NPC overview, quests, loot, story, technical information, and model presentation.
- Validated Movement catalogue.
- Personal saved locations and Emergency Return.
- Server-specific `game_tele` destinations.

## 0.6.2 — Validation and hardening

Completed release scope:

- Corrected pull accounting for encounters that transition directly from `FAIL -> IN_PROGRESS`.
- Revalidated repeated pull, wipe, reset, and kill counters with zero suspicious transitions in the tested Saurfang sequence.
- Simplified exact-ID Item inspection into an automatic workspace-driven workflow.
- Hardened addon Item UI state, delayed cache refreshes, and post-mutation refresh behavior.
- Revalidated equipment stats and authoritative access requirements.
- Added explicit informational handling for legacy PvP honor-rank metadata.
- Corrected equal-chance creature-loot reporting and added GameObject loot sources.
- Hardened Item Source layout for long source details.
- Completed server-backed mount/companion display resolution and WoW 3.3.5 creature-cache priming for textured previews.

Post-0.6.2 hardening:

- Validate Encounter History across additional Wrath raids and dungeons.
- Verify unusual encounter scripts do not create false suspicious transitions.
- Review whether Encounter History should remain session-memory only or gain optional persistence.
- Continue systematic NPC regression coverage.
- Decide whether local dungeon test data belongs under repository test tooling or remains development-only.
- Expand release regression coverage for Instance Intelligence.

## Quest Log integration — remaining work

- Extend target Quest Log inspection with live objective progress.
- Display live objective progress for SELF and module-supplied progress for TARGET.
- Open and highlight the selected quest in Blizzard's Quest Log where client APIs permit.
- Synchronize selection between AzerCore Ops and Blizzard's Quest Log where practical.
- Add richer Quest Log actions for objectives, rewards, requirements, chain, NPCs, comparison, diagnostics, and export.
- Continue reducing dependence on visible chat transport where AzerothCore APIs permit a safer structured channel.

## Deferred and safety-gated work

### Courier

Courier remains an under-construction preview.

Before activation it requires:

- A defined transport model.
- Server-side authorization.
- Recipient and payload validation.
- Abuse prevention and reporting.
- Failure and recovery handling.
- Clear Player Mode and GM permission boundaries.

### Location sharing

Location sharing remains disabled.

Activation requires:

- Explicit authorization and consent.
- Destination verification.
- Safe-landing validation.
- Abuse and reporting controls.
- Clear visibility and revocation behavior.

## Future intelligence workspaces

- Group Intelligence
- Guild Intelligence
- Spell Intelligence
- GameObject Intelligence
- Database Intelligence

Existing Character, Quest, Instance, Item, Creature/NPC, and Movement capabilities
should be hardened before adding broad new workspaces.
