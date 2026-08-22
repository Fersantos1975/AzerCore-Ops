# Release checklist

Use this checklist before tagging or publishing any AzerCore Ops release.

## Source and documentation

- [ ] Version matches in `CMakeLists.txt`, `addon/AzerCoreOps/AzerCoreOps.toc`, addon runtime metadata, `CHANGELOG.md`, and `RELEASE-NOTES.md`.
- [ ] Release channel and capability list are accurate.
- [ ] README identifies the correct current release.
- [ ] README installation commands use portable placeholders rather than machine-specific paths.
- [ ] No credentials, personal filesystem paths, private hostnames, or local network addresses are present.
- [ ] Changelog and release notes describe only functionality included in the release.
- [ ] Previous changelog history remains intact.
- [ ] `tools/azercoreops-check` passes.
- [ ] `git diff --check` passes.
- [ ] Repository has no unintended tracked or untracked release files.

## Module build

- [ ] Repository is located at `<azerothcore-root>/modules/mod-azercore-ops`.
- [ ] AzerothCore is reconfigured after module source or build-metadata changes.
- [ ] Static module build succeeds.
- [ ] Dynamic module build is tested only when claimed as supported.
- [ ] Install target completes successfully.
- [ ] Worldserver starts without AzerCore Ops errors.
- [ ] Build information reports the expected module version and revision.
- [ ] Release build reports `dirty=no`.
- [ ] Core and playerbots revisions are reported when available.
- [ ] Addon and server module report matching release versions.

## Addon validation

- [ ] Addon loads without Lua errors on a clean WoW 3.3.5a client profile.
- [ ] Saved settings initialize correctly.
- [ ] Minimap button and Interface Options entries work.
- [ ] Main window opens, closes, minimizes, and restores correctly.
- [ ] Automatic mode follows the module permission handshake.
- [ ] Player Mode cannot expose GM-only operations.
- [ ] Permission loss immediately downgrades the interface without permanent `OnUpdate` polling.
- [ ] Copy, share, and export reports contain no account, email, IP, GUID, or unintended exact-location data.

## Quest validation

- [ ] Quest search works by numeric ID and title.
- [ ] Quest details render without malformed protocol output.
- [ ] SELF and TARGET contexts work as expected.
- [ ] Inspect Quest Log loads every active quest for the selected online player.
- [ ] Target Quest Log handles target changes, refresh, empty logs, no target, copy, share, and export.
- [ ] Group audit handles solo, party, and raid states safely.
- [ ] Search history and activity reporting work.
- [ ] Quest-chain ordering and player-specific status remain correct.

## Character validation

- [ ] Character inspection populates Overview, Inventory, Professions, Raid Experience, and Technical Details.
- [ ] Changing or clearing the selected target immediately removes stale Character records.
- [ ] Technical identifiers and exact location remain unavailable in Player Mode and excluded from shared reports.
- [ ] Raid Experience clearly labels achievements as recorded evidence rather than proof of mastery.
- [ ] Every listed raid exposes only applicable difficulty choices.
- [ ] Selected raid and difficulty survive target changes and `/reload`.
- [ ] Late responses for an earlier raid, difficulty, or target are ignored.
- [ ] Save My Character remains self-only.
- [ ] Save Target requires GM authorization and confirmation.

## Instance Access validation

- [ ] Structured My Binds and Target Binds show exact Instance IDs and reset metadata.
- [ ] Boss progress shows defeated/total counts and defeated/remaining names when available.
- [ ] Group Audit identifies same-ID, different-ID, no-bind, blocked, and offline members correctly.
- [ ] Non-applicable bind selection explains why without selecting the bind.
- [ ] Multi-select batch unbind requires confirmation and reports every result.
- [ ] Post-unbind inspection confirms successfully removed binds are gone.

## Instance Diagnostics and Encounter History

- [ ] Instance Diagnostics loads the correct profile and current encounter state.
- [ ] Expected initialization states do not produce false warnings or failures.
- [ ] Encounter History records `NOT_STARTED -> IN_PROGRESS` as `PULL #N`.
- [ ] `IN_PROGRESS -> DONE` records a KILL and increments Kills exactly once.
- [ ] `IN_PROGRESS -> FAIL` records a WIPE and increments Wipes exactly once.
- [ ] `FAIL -> NOT_STARTED` is treated as reset continuation and does not double-count the wipe.
- [ ] Direct `IN_PROGRESS -> NOT_STARTED` records a WIPE for encounters that do not emit FAIL.
- [ ] A follow-up wipe-chain transition does not count the same failed pull twice.
- [ ] Attempts increment once per pull.
- [ ] Repeated pulls produce correct PULL numbering.
- [ ] Attempt Summary reports correct Attempts, Wipes, and Kills.
- [ ] DONE, FAIL, IN_PROGRESS, PULL, WIPE, RESET, and KILL colors render correctly.
- [ ] Normal tested encounter flows finish with zero false-positive suspicious transitions.
- [ ] Encounter History refresh and report actions remain functional.
- [ ] Restart/session-reset behavior is understood because Encounter History counters are currently memory-resident.

## Item and NPC regression

- [ ] Item inspection returns correct type, stats, requirements, sources, uses, and crafting information where available.
- [ ] Wearable 3D preview works for supported equipment.
- [ ] Unsupported preview types use a clear fallback rather than a broken model.
- [ ] Faction, race, class, reputation, and other access restrictions render when authoritative data exists.
- [ ] NPC inspection, quest relationships, loot, story, technical data, and model presentation remain functional.

## Movement validation

- [ ] Movement catalogue loads successfully.
- [ ] Region, zone/instance, and destination navigation works.
- [ ] Personal saved locations work.
- [ ] Emergency Return works.
- [ ] Invalid coordinates are rejected.
- [ ] Location sharing remains disabled unless its safety and authorization design has been explicitly completed.

## Release publication

- [ ] Commit history is clean and the intended release commit is on `main`.
- [ ] Release tag follows the repository's approved semantic-version convention, currently `X.Y.Z` with an optional prerelease suffix.
- [ ] GitHub release notes match `RELEASE-NOTES.md`.
- [ ] Release tag points to the exact tested module/addon source revision.
- [ ] Client addon ZIP contains only the ready-to-install `AzerCoreOps` addon directory and required addon assets.
- [ ] GitHub source archives contain the server module source and project documentation.
- [ ] Addon ZIP filename clearly identifies it as the client addon package.
- [ ] Installation instructions were tested from a fresh checkout.
- [ ] Published release assets were manually verified after upload.
