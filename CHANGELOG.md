# Changelog

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
