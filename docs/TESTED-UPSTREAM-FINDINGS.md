# Tested AzerothCore and Playerbots findings

Last updated: 20 September 2026

This register preserves defects found while developing and testing AzerCore Ops when the defective code belongs to AzerothCore or mod-playerbots rather than this module. It records what was observed, how the source was audited, the original and corrected behavior, local validation, upstream reports and responses, and whether a local patch is still required.

Do not copy these fixes blindly after an update. First compare the installed upstream revision with the referenced resolution.

## Status summary

| Finding | Repository | Report | Current upstream status | Local status |
|---|---|---|---|---|
| Blood Prince Council becomes `FAIL` during initial spawn | AzerothCore | [Issue #27383](https://github.com/azerothcore/azerothcore-wotlk/issues/27383) | Fixed by merged [PR #27665](https://github.com/azerothcore/azerothcore-wotlk/pull/27665) on 19 September 2026 | Our original local patch is retained on backup branches only |
| Crimson Hall trash deaths do not advance the controller/open door 201376 | AzerothCore | Upstream [PR #26850](https://github.com/azerothcore/azerothcore-wotlk/pull/26850) | Fix is present in the current Playerbot core source | Tested locally; no additional local patch currently required |
| Gunship bots continue toward the enemy captain after encounter `DONE` | mod-playerbots | [Issue #2757](https://github.com/mod-playerbots/mod-playerbots/issues/2757) | Open; no maintainer comment or resolution as of 20 September 2026 | Reproduced and reported; no unverified local fix is claimed |
| ICC attempts world-state shown outside Heroic | AzerothCore/Playerbot branch | Not submitted upstream | Current source still contains the hard-coded display value | Local adjustment was built during testing; must be re-evaluated before reapplying |

## 1. Blood Prince Council incorrectly enters FAIL on spawn

### Finding

In a fresh ICC instance, Valanar's initial spawn invoked encounter failure logic before any pull. AzerCore Ops exposed the unexpected transition/state while the raid was still initializing.

Affected source:

`src/server/scripts/Northrend/IcecrownCitadel/boss_blood_prince_council.cpp`

Official source revision inspected:

`2fed8b96e46609df69edb5c189d87947379cc71c`

### Root cause

The original `JustRespawned()` delegated to `JustReachedHome()`:

```cpp
void JustRespawned() override
{
    BossAI::JustRespawned();
    JustReachedHome();
}
```

The home/evade path included:

```cpp
instance->SetBossState(DATA_BLOOD_PRINCE_COUNCIL, FAIL);
```

Spawn initialization and a genuine evade therefore shared a path even though only the latter should record `FAIL`.

### Our tested local approach

We separated initial spawn setup from the home/evade failure path:

```cpp
void JustRespawned() override
{
    BossAI::JustRespawned();
    _canDie = true;
    me->setActive(false);
    instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
    me->SetHealth(me->GetMaxHealth());
    DoAction(ACTION_CAST_INVOCATION);
}
```

This initialized the prince without calling the method that writes `FAIL`.

Local tested commits:

- `7f45e2688fff6475839b60164d79a94f7a93fb3d`
- Equivalent preserved commit after later branch movement: `8ee121627fc605869a0ae5d1dd1be2680f208a58`

The patched server was rebuilt and run with the Playerbot branch and the active modules. A fresh Council state remained `NOT_STARTED` rather than being changed to `FAIL` on spawn.

### Our upstream report

Fernando reported the defect to AzerothCore as [issue #27383](https://github.com/azerothcore/azerothcore-wotlk/issues/27383) on 29 August 2026. The report included:

- the exact call path;
- original and locally patched code;
- the official AzerothCore revision;
- reproduction steps using `.instance getbossstate`;
- the local tested commit;
- server build/runtime information;
- the enabled module list.

Another community member confirmed the same failure and reported that the door could remain blocked.

### AzerothCore response and resolution

Our investigation tracked two independent defects:

1. Blood Prince trash deaths did not reliably complete the trash controller, leaving Crimson Hall access door `201376` closed.
2. Valanar's initial spawn wrote Council state `FAIL` before any pull.

The initial contributor response on 3 September mixed the two symptoms. It accepted that `FAIL` appeared before combat, but treated later `IN_PROGRESS -> DONE` progression and a door opening as evidence that the report could not be reproduced. That did not answer the actual spawn-state defect, and the door observed after Council completion was not necessarily Crimson Hall access door `201376`.

We replied with the exact separation:

- door `201376` is controlled by Blood Prince trash;
- passage doors `201377` and `201378` are controlled by Council progression;
- issue #27383 concerns the invalid pre-pull `FAIL`, independently of whether the encounter can later recover;
- on our locally patched server, the same fresh encounter remained `NOT_STARTED`.

GitHub provenance also needs to remain precise. Under the `Fersantos1975` account, issue #27383 is the published AzerothCore issue for the spawn-state defect. The door/trash defect was separately tracked and tested in our project and corresponds to the earlier upstream PR #26850; GitHub does not show a second AzerothCore issue authored by that account for the door.

EricksOliveira later opened [PR #27665](https://github.com/azerothcore/azerothcore-wotlk/pull/27665), confirming the root cause described in #27383. Their refined fix moved shared prince initialization into a reset helper, called it from both lifecycle paths, and kept the `FAIL` write only in the genuine `JustReachedHome()` path.

Their in-game validation covered:

- fresh spawn remains `NOT_STARTED`;
- pull becomes `IN_PROGRESS`;
- trash completion opens the relevant door;
- Council kill becomes `DONE`;
- a genuine wipe/home transition becomes `FAIL`.

Maintainer Nyeriah approved the PR. It was merged on 19 September 2026 as merge commit:

`7838cd733b2fd6a2c09cb9decaaae76eb13f8c12`

The merge closed our issue #27383. This upstream solution supersedes our local implementation once it reaches the installed Playerbot core branch.

### Current installation note

The current Playerbot core HEAD does not contain our local commit as an ancestor; it is preserved on backup branches. Before reapplying it, check whether the upstream PR #27665 has already been merged into the installed Playerbot branch. Prefer the upstream helper-based solution when available.

## 2. Crimson Hall trash controller and access door

### Finding

The four entrance Darkfallen could be killed without reliably feeding `DATA_BPC_TRASH_DIED`. As a result, Blood Prince Trash could remain undecided and Crimson Hall access door `201376` could stay closed.

### Root cause

The relevant creatures had received C++ `ScriptName` handlers. That takes precedence over their old SmartAI, so the SmartAI death actions that updated instance data no longer executed. Additional problems affected pack discovery and combat assistance:

- a 10-yard object visit could omit spawn 201479 because it occupied the adjacent grid cell;
- calling `DoZoneInCombat(darkfallen)` with the puller did not make the entire pack assist the puller's target;
- the C++ AI lacked the old SmartAI death notification.

### Upstream code correction tested on our server

Upstream PR #26850 and commit `ee1b306f8855b632d3557eabac74c28f2e3d4e8d` implemented the correction. Important code changes included:

```cpp
float const ORB_CONTROLLER_MINION_RANGE = 15.0f;
float const CALL_FOR_HELP_RADIUS = 19.0f;
```

The searcher received the configured range, and `Cell::VisitObjects` used 15 yards so all four entrance mobs were discovered.

Pack assistance changed from passing the pulled creature back into zone combat to engaging the actual target:

```cpp
Unit* target = darkfallen->GetVictim();
if (!target)
    target = darkfallen->GetThreatMgr().GetAnyTarget();

if (target)
    for (ObjectGuid minionGuid : _minionGuids)
        if (Creature* minion = ObjectAccessor::GetCreature(*me, minionGuid))
            if (minion->IsAIEnabled && !minion->IsInCombat())
                minion->EngageWithTarget(target);
```

The scripted Darkfallen AI restored the missing instance notification:

```cpp
void JustDied(Unit* /*killer*/) override
{
    switch (me->GetSpawnId())
    {
        case GUID_DARKFALLEN_ADVISOR:
        case GUID_DARKFALLEN_ARCHMAGE:
        case GUID_DARKFALLEN_BLOOD_KNIGHT:
        case GUID_DARKFALLEN_NOBLE:
            if (InstanceScript* instance = me->GetInstanceScript())
                instance->SetData(DATA_BPC_TRASH_DIED, 1);
            break;
        default:
            break;
    }
}
```

The update also removed the superseded SmartAI and related conditions from the database, preventing two competing definitions.

### Validation and current status

This code was compiled, installed, and exercised during ICC progression. The access sequence and door behavior were then included in the AzerCore Ops ICC audit/profile. The current Playerbot core source still contains the important constants and `DATA_BPC_TRASH_DIED` death notification, so no extra local patch is presently required.

This finding must remain distinct from the Council spawn-state issue: door `201376` follows the trash controller, while passage doors `201377` and `201378` follow the Council encounter.

## 3. Playerbots continue Gunship behavior after DONE

### Finding

After the Gunship Battle completed, bots continued moving toward the enemy ship/captain and had to be manually summoned back. AzerCore Ops recorded the authoritative transition:

`Icecrown Gunship Battle: NOT_STARTED -> DONE`

The capture contained two transitions and zero suspicious state transitions, showing that the encounter state completed normally while Playerbot behavior remained active.

### Technical lead

`IccGunshipMultiplier::GetValue()` appeared to determine whether Gunship behavior was active from the nearby enemy captain remaining alive and hostile. If that NPC remains available after the instance reports `DONE`, the Gunship actions can remain enabled.

The proposed direction is an authoritative exit guard: when the instance Gunship state is `DONE`, Gunship-specific movement/combat multipliers must return inactive and normal follow behavior must resume.

No local source modification is recorded as tested for this issue, so this document deliberately does not invent a before/after patch.

### Our upstream report

Fernando reported the problem to mod-playerbots as [issue #2757](https://github.com/mod-playerbots/mod-playerbots/issues/2757). The report contains:

- exact reproduction steps;
- reproduction date, 6 September 2026;
- before/after diagnostic timestamps;
- Playerbots revision `b949b50bf`;
- AzerothCore Playerbot revision `413bea61a85e`;
- the authoritative `DONE` evidence from AzerCore Ops;
- the suspected multiplier/encounter-state mismatch;
- distinction from the older general Gunship issue #1219.

### Response status

As of 20 September 2026, issue #2757 remains open and its GitHub timeline contains no maintainer comment, linked fix, or closure event. The response received yesterday concerned AzerothCore issue #27383/PR #27665, not this Gunship report.
