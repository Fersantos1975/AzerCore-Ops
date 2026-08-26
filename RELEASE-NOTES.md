# AzerCore Ops 0.6.2

AzerCore Ops 0.6.2 is a validation and hardening release focused on encounter-attempt tracking and the Item Inspector.

The platform continues to consist of both the AzerothCore server module and the matching World of Warcraft 3.3.5a client addon.

## Highlights

- Correct `FAIL -> IN_PROGRESS` pull accounting for encounter history
- Automatic exact-ID Item Inspector workflow
- Item mutation refresh after Add Item and Remove Item
- Hardened Item UI state and delayed-cache refresh handling
- Server-resolved mount and companion display metadata
- WoW 3.3.5 creature-cache priming for fully textured 3D previews
- Legacy PvP honor requirements presented as informational rather than false usability failures
- Friendly Armor and resistance stat names
- Correct equal-chance creature-loot reporting
- GameObject direct and reference-loot source reporting
- Wrapped, dynamically sized Item Source rows

## Encounter tracking

AzerCore Ops now treats:

`FAIL -> IN_PROGRESS`

as a valid new pull. Attempts increment immediately and the history records `PULL #N` rather than a generic informational transition.

This complements the existing handling for:

- `NOT_STARTED -> IN_PROGRESS`
- `IN_PROGRESS -> FAIL`
- `IN_PROGRESS -> NOT_STARTED`
- `FAIL -> NOT_STARTED`
- `IN_PROGRESS -> DONE`

The validated Saurfang sequence completed with:

`Attempts 4 | Wipes 3 | Kills 1`

and zero suspicious transitions.

## Item Inspector

Exact item IDs can now flow directly into the selected Item Action Bar workspace without a redundant Inspect Item operation. Name searches remain deliberate.

The Item Inspector also refreshes authoritative server data after item mutations, preserving the active view while ownership-dependent requirements update.

Requirements now distinguish legacy `RequiredHonorRank` from requirements actually enforced by AzerothCore 3.3.5.

Sources now report:

- Creature drops with truthful equal-chance group details
- GameObject direct loot
- GameObject reference loot
- Existing vendor and quest-reward sources

Source rows wrap long detail text and size themselves dynamically.

## 3D mount and companion previews

Mount and companion preview metadata is resolved from AzerothCore creature data.

For WoW 3.3.5 clients that do not yet know the referenced creature entry, the server sends the normal creature-query response before the AzerCore Ops preview record. This primes the client creature cache so `DressUpModel:SetCreature()` can render the correct display and textures.

The final Swift Alliance Steed test rendered the complete textured mount without hard-coded item IDs, creature IDs, display IDs, or model paths in production code.

## Validation

The 0.6.2 regression pass covered:

- Encounter pull/wipe/kill accounting
- Exact-ID and name-based Item workflows
- Client-cache retries
- Add/remove ownership refresh
- Armor and resistance stats
- Profession, reputation, unique-item, faction/race/class, and legacy honor requirements
- Creature equal-chance loot
- GameObject loot
- Server-backed mount preview
- Final BugGrabber review

## Versions

- Server module: 0.6.2
- Client addon: 0.6.2
- Protocol: v1
- Release tag: 0.6.2

## Installation

Install the repository as `mod-azercore-ops` in the AzerothCore modules directory and rebuild the core.

Copy `addon/AzerCoreOps` into the WoW client's `Interface/AddOns` directory.

The addon and server module should use matching release versions.
