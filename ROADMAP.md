# AzerCore Ops Platform Roadmap

## 0.5.x — Quest foundation and stabilization

- Align the C++ Quest backend with the completed Quest Intelligence frontend.
- Provide a structured active Quest Log inventory for the selected online player. *(Added in 0.5.1.)*
- Complete objectives, requirements, rewards, NPC, and richer diagnostics payloads.
- Replace visible chat transport with a dedicated addon communication channel.
- Stabilize target-context and group-audit handling.
- Present complete quest chains in sequence with the selected quest's position and every linked quest's player-specific status. *(Added in 0.5.1 alpha testing.)*
- Add compile and field-test verification.

## 0.6.0 — Quest Log integration

- Introduce the centralized UI State Manager for consistent, event-driven
  navigation, workspace, filter, and selection highlighting without permanent
  `OnUpdate` polling.
- Extend target Quest Log inspection with live objective progress and richer diagnostics.
- Open and highlight the selected quest in Blizzard's Quest Log.
- Synchronize selection between AzerCore Ops and the Blizzard Quest Log.
- Display live objective progress for self and module-supplied progress for targets.
- Add Quest Log actions for objectives, rewards, requirements, chain, NPCs, comparison, diagnostics, and export.

## Role-aware operating modes

- Add Automatic, Player, and GM operating modes before the wider 0.6.x workspace expansion. *(Added in 0.5.3.)*
- Default to Automatic and derive the effective mode from the module permissions handshake. *(Added in 0.5.3.)*
- Always allow a GM to select the safer read-only Player Mode. *(Added in 0.5.3.)*
- Never allow an addon setting to grant GM authority; the server remains authoritative for every command. *(Added in 0.5.3.)*
- Hide mutation and administrative operations in Player Mode while retaining permitted inspection, readiness, and report tools. *(Added in 0.5.3.)*
- Immediately downgrade the interface if permissions are lost. *(Added in 0.5.3; a persistent global mode badge remains under consideration.)*
- Maintain a documented feature/permission matrix and apply it through centralized UI state rather than per-frame polling. *(Initial implementation added in 0.5.3.)*

## 0.5.3 — Character Intelligence

- Add role-aware Character inspection with Overview, Inventory, Professions, Raid Experience, and Technical Details.
- Treat recorded raid achievements as experience evidence, never as proof of player mastery.
- Keep Technical Details and target-save operations server-authorized and GM-only.
- Clear stale target records immediately when the selected player changes or disappears.
- Keep copied, shared, and exported Character reports free of sensitive technical identifiers.
- Preserve self-only character saving while offering a separately confirmed GM target-save operation.
- Provide a persistent raid/difficulty selector for Wrath raid-achievement evidence, with only valid difficulties per raid and event-driven target refresh. *(Added in 0.5.3.)*

## Future intelligence workspaces

- Character Intelligence *(initial workspace added in 0.5.3)*
- Instance Intelligence
- Group Intelligence
- Guild Intelligence
- Item Intelligence
- Spell Intelligence
- Creature Intelligence
- GameObject Intelligence
- Database Intelligence
