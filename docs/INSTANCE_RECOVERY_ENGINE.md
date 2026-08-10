# Instance Recovery Guidance Engine

The recovery guidance engine implements the AzerCore Ops workflow:

> Inspect. Diagnose. Resolve. Operate.

It is a read-only decision-support layer. It never executes a GM command or changes an
instance, creature, door, transporter, bind or saved encounter state.

## Dynamic evidence

For every loaded dungeon and raid, the engine receives the runtime map and script identity,
the encounter catalogue, each encounter ID, localized name, state and official completion
credit, plus the selected creature's entry, life and combat state.

This allows universal rules to work without hard-coded boss names:

- a selected encounter-credit creature is dead while its encounter is not `DONE`;
- a selected encounter-credit creature is alive and out of combat while its encounter is
  stuck `IN_PROGRESS`.

The generated verification, repair and recheck commands use the discovered encounter ID.

## Verified relationship profiles

Boss order alone is not a safe dependency model because many raids branch or contain optional
encounters. Profiles therefore add only relationships verified in the core script, such as a
boss controlling a door, transporter or later wing. The first relationship profile detects an
inconsistent Deathbringer Saurfang prerequisite in Icecrown Citadel.

Adding a profile does not require addon UI changes. All rules emit the same structured recovery
record through the chat protocol.

## Safety contract

Every recovery record contains:

1. evidence and confidence;
2. `.instance getbossstate` verification;
3. an explicit warning to confirm legitimate encounter completion or a genuine wipe;
4. suggested commands, displayed but never executed;
5. a second state check and expected result.

When evidence is insufficient, the engine emits no recovery command. Normal diagnostic findings
remain available to guide further inspection.
