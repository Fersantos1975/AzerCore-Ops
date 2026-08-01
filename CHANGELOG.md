# Changelog

## 0.5.2 — Instance Access

### Added

- Structured SELF and TARGET bind inventories with exact map, difficulty, Instance ID, permanence, extension, reset, and applicability fields.
- Encounter masks, defeated/total boss progress, and individual defeated/remaining boss records.
- Structured bind metadata in group access audits.
- Multi-select bind checkboxes and safe batch unbinding with operation IDs, stale-selection protection, per-bind results, and server verification.
- Automatic target reinspection and Bind Activity results after every batch operation.

### Updated

- Preserved the AzerothCore command-argument namespace compatibility patch in `InstanceInspector.cpp` and `.h`.
- Updated the bundled addon to `0.5.2-alpha1-instance-module-sync`, including numbered quest chains and complete chunked Courier reports.

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
