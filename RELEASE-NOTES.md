# AzerCore Ops 0.6.1

AzerCore Ops 0.6.1 expands the Instance Diagnostics system with server-backed encounter history, anomaly detection, and live attempt/wipe/kill tracking.

The platform continues to consist of both the AzerothCore server module and the matching World of Warcraft 3.3.5a client addon.

## Highlights

- Server-backed Encounter History
- Encounter-state anomaly detection
- Per-encounter Attempts, Wipes, and Kills counters
- PULL #N and WIPE #N event numbering
- RESET and KILL event tracking
- Color-coded encounter events and states
- Attempt Summary presentation in the addon
- Improved Encounter History layout and readability

## Wipe detection

AzerCore Ops now correctly recognizes encounters that reset directly from:

`IN_PROGRESS -> NOT_STARTED`

as failed pulls and records them as wipes.

Related follow-up reset/failure transitions are protected against double counting.

## Validation

Lord Marrowgar:

`Attempts 1 | Wipes 0 | Kills 1`

Lady Deathwhisper:

`Attempts 2 | Wipes 1 | Kills 1`

Testing completed with zero false-positive suspicious encounter transitions.

## Versions

- Server module: 0.6.1
- Client addon: 0.6.1
- Protocol: v1
- Release revision: 9a3f7d2

## Installation

Install the repository as `mod-azercore-ops` in the AzerothCore modules directory and rebuild the core.

Copy `addon/AzerCoreOps` into the WoW client's `Interface/AddOns` directory.

The addon and server module should use matching release versions.