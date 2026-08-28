# AzerCore Ops 0.7.0

AzerCore Ops 0.7.0 expands the platform with authoritative NPC inspection and comprehensive Quest intelligence for the AzerothCore server module and matching World of Warcraft 3.3.5a client addon.

## Highlights

- Authoritative NPC search by name or exact Entry ID
- Database world-spawn discovery and nearest-spawn navigation
- Live NPC state, grid activity, and respawn reporting
- Automatic target-aware NPC inspection
- Expanded NPC Story, Quest, Service, Combat, Loot, and Technical intelligence
- Recursive loot references, grouped loot, pickpocket, and skinning information
- Quest search by ID, title, partial title, and required item
- Player-specific quest eligibility and blocker explanations
- Ordered quest-chain analysis with progression summaries
- Target Player Quest Log inspection and group quest auditing
- Safer request tracking and stale-response rejection
- Clear actions for resetting NPC and Quest workspaces

## NPC Inspector

NPC search now returns authoritative creature templates and their database world spawns. Spawn results include map, coordinates, orientation, SpawnMask, PhaseMask, same-map distance, grid activity, and available runtime state.

Runtime spawn states include:

- `ALIVE`
- `DEAD`
- `RESPAWNING`
- `NOT_PRESENT`
- `NOT_LOADED`
- `MAP_NOT_ACTIVE`

Same-map spawns are listed first and ordered by distance. Selecting a spawn never teleports automatically; Go to Spawn remains an explicit operation, with Emergency Return available for safe navigation.

NPC inspection now follows selected creatures automatically. Changing the target or opening an Action Bar view loads current server data when required, while duplicate requests and late responses for an earlier target are rejected.

The NPC workspace includes Story, Quests, Services, Spawn, Location, Combat, Loot, and Technical views. Loot intelligence covers direct creature drops, recursive reference pools, grouped and equal-remainder loot, pickpocket tables, and skinning tables.

A Clear action resets search, spawn, selection, and loaded inspection state without moving or modifying the selected creature.

## Quest Inspector

Quest search supports exact Quest IDs, full or partial titles, and required-item relationships. Selected quests report authoritative metadata, player-specific eligibility, current status, blocker explanations, starters, enders, required items, and ordered chain progression.

Target Player analysis supports online selected players and provides:

- Current quest eligibility and blocker reasoning
- Ordered chain status in the selected player context
- Complete active Quest Log inspection
- Safe handling of empty logs, target changes, missing targets, and invalid targets
- Refresh, copy, share, and export reporting

Group Analysis compares the selected quest across party or raid members and reports pass, warning, or failure results with the status and reason for each player.

Existing Add Quest, Complete Quest, Reward Quest, and Remove Quest operations remain server-authorized GM actions.

## Reliability and protocol

NPC and Quest streams use structured, bounded protocol records. The addon tracks the requested Entry ID, Quest ID, player, and active workspace so unrelated or late responses cannot overwrite current results.

Protocol compatibility remains `v1`. The server module and client addon must use matching release versions.

## Validation

The 0.7.0 regression pass covered:

- NPC search by exact ID and name
- Multiple-result and zero-result NPC searches
- Database world spawns and nearest-distance ordering
- ALIVE, NOT_PRESENT, NOT_LOADED, and MAP_NOT_ACTIVE states
- Loaded and inactive grid reporting
- Explicit spawn navigation and Emergency Return
- Live NPC Overview, Story, Quests, Services, Spawn, Location, Combat, Loot, and Technical views
- Direct, grouped, referenced, pickpocket, and skinning loot
- Quest search by ID, title, partial title, and item
- Zero-result Quest searches
- Quest eligibility, blocker explanations, and ordered chains
- Target changes, missing targets, empty and populated Quest Logs
- Party and raid Quest group analysis
- Automatic NPC inspection, duplicate-request suppression, and stale-response rejection
- NPC and Quest copy, share, export, history, and activity reporting

The completed regression pass produced no reported AzerCore Ops Lua runtime errors.

## Known limitations

- The NPC Spawn report currently repeats live Location fields rather than exposing additional spawn-specific runtime fields.
- Creature templates using gossip menu ID 0 can expose generic database conversation options that are not necessarily available on that NPC.
- Target Quest Log reports do not yet include objective-level progress.
- Some Quest scaling and status labels remain presentation improvements for a future release.
- Courier remains under construction and is not included as an active release feature.

## Versions

- Server module: 0.7.0
- Client addon: 0.7.0
- Protocol: v1
- Release tag: 0.7.0

## Installation

Install the repository as `mod-azercore-ops` inside the AzerothCore modules directory and rebuild the core.

Copy the ready-to-install `addon/AzerCoreOps` directory into the WoW client `Interface/AddOns` directory.

The addon and running server module must use matching release versions.
