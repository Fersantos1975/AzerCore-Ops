# AzerCore Ops Platform Roadmap

AzerCore Ops is an operational intelligence platform for AzerothCore built from a
server-side C++ module and a matching World of Warcraft 3.3.5a addon.

The current stable baseline is `0.6.1`.

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

- Validate Encounter History across additional Wrath raids and dungeons.
- Test both common wipe-state patterns:
  - `IN_PROGRESS -> FAIL -> NOT_STARTED`
  - `IN_PROGRESS -> NOT_STARTED`
- Verify attempt, wipe, and kill counters across repeated pulls and resets.
- Verify unusual encounter scripts do not create false suspicious transitions.
- Review whether Encounter History should remain session-memory only or gain optional persistence.
- Run a systematic Item and NPC regression pass against the current server module.
- Re-test wearable previews, access requirements, faction/race restrictions, and fallback presentation.
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
