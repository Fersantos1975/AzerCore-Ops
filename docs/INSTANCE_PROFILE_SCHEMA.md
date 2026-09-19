# Instance Profile Schema

Instance profiles add source-verified knowledge to the universal diagnostics engine. Evaluator
code must not contain map-specific encounter names, indices or object IDs.

## Identity and difficulty

Each profile declares its map ID, stable profile ID, display name and supported difficulty IDs.
ICC supports `0` (10 Normal), `1` (25 Normal), `2` (10 Heroic) and `3` (25 Heroic).

## Encounter mapping

`DungeonEncounter.dbc` indices are not guaranteed to equal `InstanceScript` boss IDs. Profiles
must declare an explicit mapping when they diverge. ICC maps:

| Catalogue entry | Script state |
| --- | --- |
| 0-8 | 0-8 |
| Valithria 9 | Valithria 10 |
| Sindragosa 10 | Sindragosa 11 |
| Lich King 11 | Lich King 12 |

Sister Svalna (9), Sindragosa Gauntlet (13) and Blood Prince Trash (14) are script-only runtime
states and are reported as `EVENT_STATE` rather than mislabeled public bosses.

## Dependencies and gates

Pair dependencies detect a completed dependant whose prerequisite is incomplete. Multi-prerequisite
gates represent `ALL` relationships such as:

- Festergut + Rotface -> Professor Putricide access;
- Putricide + Lana'thel + Sindragosa -> Frozen Throne access.

Normal incomplete gates are `EXPECTED`. They become `FAIL` only when the dependant is already
complete, proving contradictory progression. Gates may also declare an authoritative completion
signal (`completionSignalDataId` + `completionSignalValue`) when boss completion alone is not enough.
ICC uses this for Professor Putricide access so Festergut and Rotface being `DONE` does not produce
a false `PASS` before the scripted valve/airlock sequence reaches its verified state.

## Runtime signals

Signals expose authoritative `InstanceScript::GetData` values without guessing their meaning.
They may be state, count or boolean values and may be difficulty-restricted. ICC currently exports
Putricide trap/airlock, Frostwing trash, Sindragosa intro and heroic-attempt signals.

## Physical objects

Objects may use one of three policies:

- `OpenWhenReady`: physical GO state should open when all prerequisites are `DONE`;
- `SelectableWhenReady`: interaction flags should clear when prerequisites are `DONE`;
- `Observe`: compound room/event behavior is reported but not judged automatically.

Only objects loaded in the player's current grid are evaluated. An unloaded object is never a
failure.

## Encounter mechanics

Profiles may include source-verified `EncounterMechanic` records containing the owning encounter,
relevant creature entries, stable mechanic ID, display name, phase, spell IDs, heroic-only flag,
and a short description of the behavior verified in the authoritative encounter script.

These rows are contextual knowledge, not proof that a mechanic occurred during a specific scan or
recording. The addon therefore excludes `MECHANIC_PROFILE` rows from Before/After change comparison.
A future bounded event recorder may correlate live spell, summon, game-object and actor events back
to these profile entries.

## Safety

Profiles are diagnostic evidence, not permission to mutate state. Recovery remains read-only,
requires verification and must never be generated for ordinary progression locks.
