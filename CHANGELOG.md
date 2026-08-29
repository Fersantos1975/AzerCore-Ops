# Changelog

## 0.7.1 — Navigation and Spawn Diagnostics

### Added

- Added authoritative live NPC Spawn information: Spawn ID, database/runtime source, home position, distance from home, respawn delay, corpse delay, movement type, and wander distance.
- Added Go to NPC navigation through the existing Movement backend, arriving near the live target while preserving an Emergency Return point.
- Added automatic NPC target-name insertion into NPC Search without overwriting a search field that is actively being edited.

### Changed

- Aligned Item Search with the NPC Search layout and retained controlled Add Item and Remove Item operations in the Operations panel.
- Streamlined Movement destination selection so choosing a destination teleports immediately and records the Emergency Return point.
- Increased Movement menu-label visibility and preserved clear region, zone, and destination selection states.
- Made NPC world-spawn row clicks select database records only; they no longer claim to change the visible WoW target.

### Fixed

- Removed unreliable same-name NPC targeting that always selected the nearest matching creature instead of the chosen Spawn ID.
- Removed the protected targeting path that could trigger Blizzard blocked-action warnings.
- Separated live NPC Location information from authoritative Spawn information.

### Validation

- Validated Item Search layout and input rendering in the WoW 3.3.5a client.
- Validated automatic Movement teleport and Emergency Return.
- Validated Go to NPC arrival and return behavior.
- Validated Spawn Information against live database-backed NPCs.
- Validated database-spawn row selection without unintended target changes.
- Validated automatic target-name insertion and manual-edit protection.
- Completed configure, build, install, compatibility, clean-build, and BugGrabber regression checks.

## 0.7.0 — NPC and Quest Intelligence

### Added

- Added authoritative NPC search by creature name or exact Entry ID.
- Added world-spawn discovery with map, coordinates, orientation, SpawnMask, PhaseMask, and distance ordering.
- Added live spawn states including ALIVE, DEAD, RESPAWNING, NOT_PRESENT, NOT_LOADED, and MAP_NOT_ACTIVE.
- Added grid activity and remaining respawn-time reporting for NPC spawns.
- Added automatic inspection when the selected creature changes or an NPC Action Bar view requires current runtime data.
- Added an NPC workspace Clear action that safely removes search, selection, spawn, and inspection state.
- Added expanded NPC Story, Quest, Service, Spawn, Location, Combat, Loot, and Technical reporting.
- Added recursive creature loot-reference reporting, grouped loot interpretation, pickpocket loot, and skinning loot.
- Added Quest search by exact ID, title, and required item.
- Added player-specific quest eligibility, blocker explanations, chain ordering, and progression summaries.
- Added Target Player quest analysis, complete target Quest Log inspection, and group quest auditing.

### Changed

- NPC search results now distinguish database spawn definitions from loaded runtime creatures.
- NPC spawn results are ordered with same-map spawns first and then by nearest distance.
- NPC reports now retain the selected search creature name and Entry ID even without a live target.
- Quest and NPC workspaces now reject stale or unrelated streamed responses.
- Quest reports now provide AVAILABLE, BLOCKED, ACTIVE, COMPLETE, REWARDED, and FAILED context where applicable.
- Protocol transport was expanded with bounded and structured NPC and Quest records while remaining on protocol v1.

### Fixed

- Prevented NPC Action Bar views from displaying stale data belonging to a previously selected creature.
- Prevented repeated automatic inspection requests while the matching request is already loading.
- Corrected NPC spawn-state presentation so runtime state appears on the visible spawn cards and exported reports.
- Corrected selected NPC report headers that previously displayed Entry unknown during database searches.
- Preserved safe explicit navigation: selecting a spawn does not teleport until Go to Spawn is pressed.
- Improved Quest target handling for target changes, empty Quest Logs, missing targets, and offline or invalid selections.

### Validation

- Completed NPC regression coverage for exact-ID, name, multiple-result, zero-result, world-spawn, live-state, navigation, Story, Quest, Service, Combat, Location, Technical, and Loot workflows.
- Validated ALIVE, NOT_PRESENT, NOT_LOADED, MAP_NOT_ACTIVE, grid-loaded, and grid-inactive spawn reporting.
- Validated direct creature loot, recursive reference pools, grouped and equal-remainder loot, pickpocket tables, and skinning tables.
- Completed Quest regression coverage for ID, title, partial-title, item, zero-result, chain, eligibility, target, Quest Log, and group-analysis workflows.
- Validated automatic NPC target changes, forced refresh, duplicate-request suppression, stale-response rejection, and workspace clearing.
- Completed the regression pass without reported AzerCore Ops Lua runtime errors.

### Known limitations

- The NPC Spawn report currently repeats live Location fields rather than exposing additional spawn-specific runtime fields.
- Creature templates using gossip menu ID 0 can expose generic database conversation options that are not necessarily available on that NPC.
- Target Quest Log reports do not yet include objective-level progress.
- Some Quest status and scaling labels remain presentation improvements for a future release.
- Courier remains under construction and is not included as an active release feature.

## 0.6.2 — Validation and Item Hardening

### Changed

- Treat `FAIL -> IN_PROGRESS` as a valid encounter pull start, incrementing Attempts and emitting `PULL #N`.
- Removed the redundant explicit Inspect Item step for exact item IDs; Item Action Bar views now inspect the selected item automatically.
- Kept fuzzy/name searches deliberate while preserving the active Item workspace during client-cache refreshes and retries.
- Improved Item Sources presentation with wrapped detail rows and dynamic row heights.

### Fixed

- Hardened Item UI state handling during settings updates, window resizing, and delayed item refreshes.
- Refresh Item Inspector data automatically after Add Item and Remove Item operations so ownership-dependent requirements remain current.
- Resolve mount and companion creature entries through AzerothCore creature data and prime the WoW 3.3.5 client creature cache before model preview.
- Preserve fully textured mount/companion previews without relying on hard-coded creature IDs or raw model paths.
- Report legacy `RequiredHonorRank` as informational because AzerothCore 3.3.5 does not enforce it through `Player::CanUseItem`.
- Added readable Armor and resistance stat names from the client item-stat API.
- Distinguish equal-chance creature loot groups whose raw database Chance is zero instead of reporting a misleading `0%`.
- Added GameObject loot sources, including direct and one-level reference loot paths.

### Validation

- Validated Saurfang encounter tracking across four attempts, three wipes, one kill, and zero suspicious transitions.
- Validated automatic item inspection, delayed refresh behavior, and ownership mutation refresh.
- Validated armor/stat, profession, reputation, unique-item, faction/race/class, and legacy honor requirement presentation.
- Validated creature-drop equal-chance sources and GameObject loot sources.
- Validated a fully textured server-backed Swift Alliance Steed preview after client creature-cache priming.
- Completed the final Item Inspector regression pass without AzerCore Ops Lua runtime errors.

## 0.6.1 — Encounter History and Attempt Tracking

### Added

- Added server-backed encounter history for dungeon and raid encounters.
- Added encounter-state anomaly detection for suspicious transitions.
- Added per-encounter Attempts, Wipes, and Kills statistics.
- Added PULL, WIPE, RESET, and KILL event classification.
- Added numbered PULL #N and WIPE #N events.
- Added color-coded encounter states and event presentation.
- Added an Attempt Summary to the Encounter History workspace.

### Fixed

- Correctly count direct `IN_PROGRESS -> NOT_STARTED` encounter resets as wipes.
- Prevent alternate wipe/reset chains from counting the same failed attempt twice.
- Preserve correct attempt counts when encounter recording starts during an active pull.

### Validation

- Validated normal pull and kill tracking with Lord Marrowgar.
- Validated direct-reset wipe tracking with Lady Deathwhisper.
- Validated a second Deathwhisper pull followed by a successful kill.
- Completed validation with zero false-positive suspicious transitions.

## 0.6.0 — First Public Release

### Fixed

- Redirected NPC Info from AzerothCore's raw chat output to the structured Technical workspace inside AzerCore Ops.
- Prevented Courier preview controls from appearing active before the transport and authorization design is complete.
- Replaced long development build names with a short release-candidate version.
- Updated the in-game Credits description to include Player Mode and ensured the complete credits and license remain visible.
- Forced the MBF-collected minimap logo above its background layer while preserving the working tooltip and click handlers.
- Added compatibility for MBF 3.1.1's repeated overlay hiding and reskinning behavior.

### Release notes

- Release builds use short semantic versions, beginning with `0.6.0`.
- Courier is explicitly excluded from the active `0.6.0` feature set.

## 0.5.6-alpha4 — Minimap and MBF Compatibility

### Fixed

- Exposed the AzerCore Ops logo through standard normal and pushed button textures so Minimap Button Frame can retain the icon when collecting the button.
- Added the missing AzerCore Ops minimap-button tooltip with concise click instructions.

### Documentation

- Expanded the project description to include the safe, server-authorized Player Mode for regular players.

## 0.5.6-alpha3 — Information Workspace

### Changed

- Reorganized Information into Overview, Capabilities, Build Information, Credits, and Resources workspaces.
- Added consistent Information action navigation and scrollable content regions.
- Separated compatibility data into readable status, capability/permission, and build/revision reports.

### Fixed

- Prevented long capability lists, credits, and resource buttons from being clipped or extending outside their panels.
- Added an in-project working backlog for pending operational verification, Movement tests, and repository cleanup.

## 0.5.6-alpha2 — Validated Movement Catalogue

### Added

- An attributed GPLv3 Movement catalogue adapted from AzerothAdmin with three-level Region → Zone → Destination navigation.
- A deterministic catalogue importer and validation report covering every source teleport entry.
- Mouse-wheel scrolling for long region, zone, and destination menus.
- Separate built-in, AzerothCore `game_tele`, and personal-location sources.
- Project-wide `CREDITS.md` acknowledgements.

### Fixed

- Restored the Movement inspector, command registration, and protocol messages to the canonical `src/` tree compiled by CMake.
- Removed the indefinite catalogue-loading state caused by Movement sources existing only in legacy root-level copies.

### Safety

- Rejected seven malformed coordinate records and one unverified all-zero landing point from the imported catalogue.
- Preserved server-side coordinate validation, confirmation, Emergency Return, GM permissions, and disabled location sharing.

## 0.5.3 — Character Intelligence

### Added

- Server-authoritative Automatic, Player, and GM operation modes; local settings cannot grant GM access.
- Structured Character overview, state, location, inventory summary, professions, ICC raid-achievement evidence, and restricted technical records.
- A guarded Save Target operation that verifies authorization, names the selected online character, persists without logout, and returns a structured result.
- Character sub-workspaces for Overview, Inventory, Professions, Raid Experience, and Technical Details.
- Character Activity plus privacy-safe Copy, Share, and Export reports.
- A selectable Wrath raid catalog with raid-specific difficulty choices and structured achievement evidence for the locked selection.

### Updated

- Updated the bundled addon to `0.5.3-alpha4-raid-experience`.
- Raid Experience now preserves its raid and difficulty selection across target changes and reloads, automatically refreshes the selected target, and rejects stale responses from an earlier selection.
- Added a persistent effective-mode indicator across every workspace and explanatory tooltips for operations disabled by Player Mode or missing target context.
- Character automatically activates Inspect Character when opened with a player target or when a player is subsequently selected; target changes refresh authoritative data without polling.
- Added a shared role-policy registry and applied GM-required state to Character mutations, Quest mutations, NPC commands, Item mutations, Movement commands, and instance unbinding.
- Moved role-policy helpers and mode presentation onto the shared platform object to remain safely below WoW 3.3.5 Lua 5.1's 200-local limit.
- Character target changes clear stale server records immediately; authoritative responses are accepted only for the currently selected player.
- Account, email, and network identifiers are intentionally excluded from Character reports.

## 0.5.2 — Instance Access

### Added

- Structured SELF and TARGET bind inventories with exact map, difficulty, Instance ID, permanence, extension, reset, and applicability fields.
- Encounter masks, defeated/total boss progress, and individual defeated/remaining boss records.
- Structured bind metadata in group access audits.
- Multi-select bind checkboxes and safe batch unbinding with operation IDs, stale-selection protection, per-bind results, and server verification.
- Automatic target reinspection and Bind Activity results after every batch operation.
- Exact numeric Map ID lookup with explicit search-completion results.
- Event-driven Quest-style target identity cards for bind inspection.

### Updated

- Preserved the AzerothCore `Optional<uint8>` command-argument compatibility patch in `InstanceInspector.cpp` and `.h`.
- Updated the bundled addon to `0.5.2-alpha4-character-workspace`, including numbered quest chains, complete chunked Courier reports, truthful bind loading states, safe explicit bind selection, boss-lockout terminology, stale-target protection, and shared target identity presentation.
- Added clipped, mouse-wheel-scrollable Interface settings pages so lower controls remain available at smaller resolutions and UI scales.
- Added horizontal settings scrolling when the Blizzard Interface panel is narrower than the settings content.
- Added a proportional main-window resize grip that saves the selected 75–135% scale without continuously polling outside an active drag.
- Reordered navigation by operational workflow: Dashboard, Character, Quests, Instance Access, NPCs, Items, Movement, Courier, and Information.
- Rebuilt Character as an addon-first inspector with shared target identity, client-visible overview and state, explicit operation context, guarded target operations, activity reporting, and Copy, Share, and Export actions.
- Removed the broad Unbind All control; every affected bind must now be explicitly selected and confirmed.

## 0.5.1 — Target Quest Log

### Added

- Server-side inspection of the selected online player's active quest log.
- Structured `QUEST_LOG_BEGIN`, `QUEST_LOG_ENTRY`, and `QUEST_LOG_END` protocol messages.
- Quest-log entry metadata for slot, ID, title, status, level, minimum level, type, and faction.
- Addon Target Player report with loading, empty-log, error, copy, share, export, refresh, and target-change handling.
- `QUEST_TARGET_LOG` module capability.

### Updated

- Synchronized the repository addon with the latest in-game-tested Quest workspace.
- Renamed the former Eligibility workspace to Instance Access.
- Added safe plain-text Quest References for the current client/core quest-link limitation.
- Added saved-search history navigation and confirmed history deletion.
- Added numbered quest-chain progress to Quest Database and Target Player, including the selected quest's position, per-quest status, progress totals, and alternative-prerequisite labels.
- Synchronized the numbered quest-chain presentation with Copy, Share, and Export reports.
- Replaced Courier's single-message truncation with numbered, chat-safe report parts that advance after each Enter press.

## 0.5.0 — Foundation Release

### Added

- AzerCore Ops Platform branding and product direction.
- Quest Intelligence as the flagship operational workspace.
- Unified quest search by ID or title.
- Persistent search history and navigation.
- Quest information, objectives, requirements, rewards, chain, and diagnostics panels.
- Group Analysis and Audit Target workflows.
- SELF/TARGET current-context switching.
- Activity log, counters, filters, copy, and export tools.
- Reusable platform, search, UI, and report framework files.
- C++ module framework for inspectors, diagnostics, protocol, reports, manifest, and build information.

### Known limitation

- Protocol messages may still appear in the General chat channel. This requires a future module-side transport cleanup.
- The module must be compiled and field-tested before this release is marked verified.
