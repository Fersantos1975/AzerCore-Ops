# AzerCore Ops Platform 0.5.3 — Character Intelligence

AzerCore Ops Platform 0.5.3 adds a role-aware Character Inspector while retaining the completed Instance Access, Quest Intelligence, and Target Quest Log workflows.

## Included

- Quest Intelligence workspace with search, inspection, context switching, group analysis, history, activity logging, and export workflows
- Inspection of every active quest in the selected online player's Quest Log
- Structured target-log status, level, type, faction, copy, share, export, refresh, and empty/error reporting
- C++ foundations for inspectors, diagnostics, reports, protocol messages, manifest data, and build information
- Shared addon design, UI, platform, search, and report frameworks
- Structured SELF and TARGET bind inventories with map, difficulty, Instance ID, permanence, extension, reset, applicability, and exact reset duration
- Encounter masks, defeated-boss totals, and defeated/remaining boss names where AzerothCore DBC data is available
- Structured bind IDs and encounter progress in group access audits
- Explicit multi-select batch unbinding with stale-ID protection, per-bind results, operation IDs, server verification, activity logging, and automatic target reinspection
- Direct instance search by exact numeric Map ID or partial title, with explicit zero-result completion reporting
- Quest-style target identity card with synchronized portrait, name, level, class, guild, and class-colored context border
- Boss-lockout terminology and scheduled-reset information that avoids presenting technical permanent binds as lifetime lockouts
- Numbered quest chains with selected-quest position and player-specific status
- Numbered Courier chunks for complete long-report delivery through Blizzard chat
- Repository architecture, design-system documentation, contribution guidance, and release validation tooling
- Server-authoritative Automatic, Player, and GM operation modes
- Character Overview, Inventory, Professions, Raid Experience, restricted Technical Details, and Character Activity
- Guarded target saving with structured success or denial results and no logout side effect

## Verification state

The addon workspaces have passed Lua parsing and repository preflight validation. The combined 0.5.3 repository still requires a clean AzerothCore compilation and the Character Intelligence smoke tests in `RELEASE-CHECKLIST.md` before publication.

## Known limitation

Protocol responses still use server system messages internally. The addon consumes and hides them, while a dedicated addon communication transport remains planned.
