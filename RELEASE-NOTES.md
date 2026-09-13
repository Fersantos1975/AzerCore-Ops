# AzerCore Ops 0.7.4

AzerCore Ops 0.7.4 expands Instance Intelligence into a source-aware encounter investigation workflow for AzerothCore while preserving the existing Quest, Character, Item, NPC, Movement, Instance Access, and evidence-driven reporting capabilities.

## Highlights

- Encounter recording with PULL, WIPE, RESET, KILL, and INITIALIZATION classification.
- Correlated Before/After diagnostic evidence with suspicious-transition counts.
- Source-verified Icecrown Citadel mechanics profiles for all twelve encounters.
- ICC progression diagnostics for bosses, doors, valves, airlocks, sigils, prerequisite creatures, and script runtime signals.
- Improved wipe/reset interpretation and locality-aware evidence handling.
- Cleaner diagnostic comparisons that suppress static mechanic-profile and final target-deselection noise.
- Improved Diagnostics viewport sizing for long encounter reports.

## Instance Intelligence

The Instance Inspector now combines the current instance state with encounter history and verified profile knowledge. ICC profiles describe encounter dependencies, allowed initialization states, runtime state definitions, progression gates, relevant world objects, prerequisite creatures, and source-verified mechanics.

Mechanic profiles are intentionally contextual: they describe mechanics verified from AzerothCore encounter scripts but are not presented as proof that an individual spell or mechanic fired during a recording. Runtime mechanic-event capture remains future work.

## Encounter recording

Encounter recording captures a bounded investigation window and reports:

- start and stop snapshots;
- recording duration;
- encounter-state transitions;
- PULL, WIPE, RESET, KILL, and INITIALIZATION classification;
- suspicious-transition totals;
- final diagnostic changes between the opening and closing snapshots.

The comparison layer now treats locality-sensitive targets as NOT_OBSERVED when appropriate, ignores static MECHANIC_PROFILE context, and suppresses the expected final `Selected creature -> No creature selected` noise after a boss kill.

## Icecrown Citadel progression

ICC-specific diagnostics now correlate progression across encounter states and nearby scripted objects. Validated examples include Saurfang passage progression, Festergut/Rotface valve readiness, plague-wing airlock state, sigils, and Frozen Throne prerequisites.

Professor Putricide access now requires both boss prerequisites and the verified valve/airlock progression signal before the gate is considered PASS. This avoids reporting the gate as complete immediately after Festergut and Rotface die while a required valve sequence is still pending.

## Validation

The 0.7.4 release candidate passed:

- Lua 5.1 syntax validation;
- 39 issue-report framework regression tests;
- project preflight;
- worldserver compile validation;
- live ICC encounter recordings with expected transitions and zero suspicious events in the validated runs;
- live environmental progression checks for gas/ooze valves, plague pipes, Putricide airlock objects, and sigils.

Validated encounter recordings during development include Marrowgar, Lady Deathwhisper, Deathbringer Saurfang, Rotface, Gunship Battle, Blood Prince Council, Valithria Dreamwalker, and Sindragosa. Additional ICC runs remain useful regression coverage but are not required to interpret static mechanic-profile rows as runtime mechanic events.

## Safety and reporting

AzerCore Ops diagnostics remain observational unless a separately authorized recovery operation is explicitly invoked. Issue reports remain editable local drafts and are never submitted automatically. Privacy validation continues to guard against sensitive local paths and unintended IPv4 addresses in generated reports.
