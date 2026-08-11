# Universal Instance Diagnostics Engine Checklist

The engine implements the AzerCore Ops workflow:

> Inspect. Diagnose. Resolve. Operate.

ICC is the first verified profile and reference implementation. No evaluator may depend on an
ICC boss name, encounter order or object ID. Instance-specific knowledge belongs in the profile
catalogue so the same engine can support every dungeon and raid.

## 1. Universal runtime engine

- [x] Detect the current map, instance ID, script and difficulty automatically.
- [x] Read the official encounter catalogue and runtime boss states.
- [x] Capture selected-creature entry, life, combat, selectable and attackable state.
- [x] Detect a dead encounter-credit creature whose encounter is not `DONE`.
- [x] Detect an encounter stuck `IN_PROGRESS` while its credit creature is alive and idle.
- [x] Keep recovery guidance read-only; never execute GM commands.
- [x] Separate verified profile relationships from universal evaluator code.
- [ ] Compare the saved `completedEncounters` bitmask with every detailed runtime state.
- [ ] Capture scan age and require persistence across scans before declaring a reset stuck.
- [ ] Record loaded-grid coverage so unloaded objects never produce physical-state failures.
- [ ] Read a selected/offline character's saved encounter state without entering the instance.
- [ ] Add structured diagnostic history filters by map, instance, difficulty and character.

## 2. Context-aware reasoning

- [x] Recognize a fresh instance with no completed or active encounter.
- [x] Classify unreached `NOT_STARTED` encounters as `EXPECTED`.
- [x] Classify legitimate `TO_BE_DECIDED` initialization as `EXPECTED` or `INFO`.
- [x] Treat `FAIL` as a reset transition before calling it stuck.
- [x] Fail only when a verified dependant is complete while its prerequisite is incomplete.
- [x] Distinguish `PASS`, `EXPECTED`, `INFO`, `WARN` and `FAIL` in the report.
- [x] Display `EXPECTED` and `INFO` with dedicated addon colours.
- [ ] Add `RECOVERY AVAILABLE` as a first-class finding state.
- [ ] Distinguish optional encounters from mandatory progression.
- [ ] Distinguish mutually exclusive faction events and difficulty variants.
- [ ] Correlate doors, transports and event NPCs with the state that owns them.
- [ ] Suppress duplicate findings when one root cause explains several symptoms.
- [ ] Rank root causes and evidence confidence.

## 3. Data-driven profile schema

- [x] Map identity and human-readable profile metadata.
- [x] Explicit prerequisite-to-dependant relationships.
- [x] Allowed fresh-instance/transitional encounter states.
- [x] Difficulty catalogue for normal/heroic 10-player and 25-player ICC modes.
- [ ] General difficulty masks covering 5-player and future profile combinations.
- [x] Multi-prerequisite `ALL` gates.
- [ ] Multi-prerequisite `ANY` and count-threshold gates.
- [x] Explicit catalogue-index to script-ID mapping for hidden/script-only encounters.
- [ ] Optional and hard-mode encounter markers.
- [x] Profile runtime signals for trash, gauntlet, valve, trap and scripted counts.
- [x] Reusable object definitions with open/selectable/observe policies.
- [x] Transporter and sigil definitions for the ICC reference profile.
- [ ] General elevator, portal and teleporter definitions for future profiles.
- [ ] Creature/event-NPC definitions with faction alternatives.
- [ ] Limited-attempt counters and lockout exhaustion rules.
- [ ] Profile source reference and verification revision.
- [ ] Profile validation that rejects missing IDs, cycles and unsafe recovery rules.

## 4. Recovery safety

- [x] Verify state before acting with `.instance getbossstate`.
- [x] Require confirmation that the encounter was legitimately completed or reset.
- [x] Generate encounter-ID-specific commands from runtime/profile evidence.
- [x] Save and recheck after a suggested temporary repair.
- [x] Avoid recovery output when evidence is insufficient.
- [ ] Compare completion bitmask and detailed save data before suggesting `DONE`.
- [ ] Warn when a living boss/reset hook may overwrite a state-only repair on restart.
- [ ] Prefer normal scripted replay/reset over state repair when available.
- [ ] Add profile-specific post-repair verification of doors, transports and event NPCs.
- [ ] Never offer direct SQL mutation from the addon.

## 5. ICC reference profile

- [x] Lower Spire chain: Marrowgar -> Deathwhisper -> Gunship -> Saurfang.
- [x] Saurfang upper-wing dependencies.
- [x] Plague Wing boss dependencies.
- [x] Blood Wing boss dependencies.
- [x] Frost Wing boss dependencies.
- [x] Frozen Throne's Putricide + Lana'thel + Sindragosa gate.
- [x] Fresh-state allowances observed for Gunship, Council and Lich King initialization.
- [x] Festergut/Rotface valve and Putricide trap/airlock profile evidence.
- [x] Blood Prince trash and Crimson Hall progression state.
- [x] Sister Svalna, Valithria gauntlet and Frostwing progression states.
- [x] Rimefang, Spinestalker and Sindragosa intro signals.
- [~] Registered ICC wing doors, transports and sigils (compound behavior remains observational).
- [x] Heroic attempt and heroic-Lich-King availability signals.
- [ ] Verify 10N, 10H, 25N and 25H independently.
- [ ] Regression test the Saurfang restart/persistence contradiction.

## 6. WotLK profile rollout

### Raids

- [ ] Naxxramas
- [ ] The Obsidian Sanctum
- [ ] The Eye of Eternity
- [ ] Vault of Archavon
- [ ] Ulduar
- [ ] Trial of the Crusader / Grand Crusader
- [ ] Onyxia's Lair
- [~] Icecrown Citadel (reference profile in progress)
- [ ] The Ruby Sanctum

### Dungeons

- [ ] Utgarde Keep
- [ ] The Nexus
- [ ] Azjol-Nerub
- [ ] Ahn'kahet: The Old Kingdom
- [ ] Drak'Tharon Keep
- [ ] The Violet Hold
- [ ] Gundrak
- [ ] Halls of Stone
- [ ] Halls of Lightning
- [ ] The Oculus
- [ ] The Culling of Stratholme
- [ ] Utgarde Pinnacle
- [ ] Trial of the Champion
- [ ] The Forge of Souls
- [ ] Pit of Saron
- [ ] Halls of Reflection

Each profile must be tested on every supported difficulty in these states:

- [ ] Fresh instance
- [ ] Normal partial progression
- [ ] Encounter actively in progress
- [ ] Legitimate wipe and scripted reset
- [ ] Fully completed instance
- [ ] Contradictory detailed state versus completion bitmask
- [ ] Closed/open door with its controlling state
- [ ] Restart persistence

## 7. Release gate for 0.7.0

- [ ] Universal engine checklist has no unsafe open item.
- [ ] ICC is verified on all four raid difficulties.
- [ ] At least one branching raid and one scripted 5-player dungeon validate the schema.
- [ ] Fresh instances produce zero false failures.
- [ ] Recovery guidance is never emitted for expected progression locks.
- [ ] Module builds on the current AzerothCore Playerbot branch.
- [ ] Addon protocol and UI regression tests pass.
- [ ] Documentation explains evidence, limitations and safety.
