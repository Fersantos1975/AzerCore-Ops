# ICC Normal and Heroic script audit

Source: this AzerothCore 3.3.5a checkout in src/server/scripts/Northrend/IcecrownCitadel. Map 631 uses difficulty IDs 0/1/2/3 for 10N, 25N, 10H, 25H.

Status: source relationship audit and complete local event-symbol inventory. Runtime verification across all four modes remains open. A mechanic listed in InstanceProfile.cpp is a rule description; it does not prove the recorder observed that action.

## What the current engine measures

MechanicEventRecorder.cpp observes encounter state, profiled creature spawn/death, and player instance/death/release/resurrection lifecycle. It does not observe spell casts, auras, scripted phase changes, GO state, valve use, transporter use, or unprofiled trash. FindObservedMechanic selects only the first matching mechanic for a creature. Events are retained in a 256-entry per-instance ring; a second active encounter may replace the single active encounter slot.

Existing door timeline entries are inferred from encounter states. The DOOR_BLOCKED passage event at IN_PROGRESS is an inferred prerequisite state, not evidence of a physical transition: the passage can have been closed before the pull. Door OPENED/CLOSED labels from encounter states likewise require direct GO-state verification.

## Verified progression

| Stage | Source behavior | Reference |
|---|---|---|
| Lower Spire | Marrowgar DONE unlocks first transporter and icewalls; Deathwhisper DONE spawns Gunship; Gunship DONE unlocks armory; Saurfang DONE unlocks cache/upper access. | instance_icecrown_citadel.cpp:96-101,1059-1109 |
| Plagueworks | Festergut and Rotface DONE enable separate valves. Valve interactions change airlock flags. Putricide trap start closes collision/gates and completion opens Putricide entrance. Putricide DONE changes plague sigil. | instance_icecrown_citadel.cpp:1111-1136,1265-1314,1830-1870 |
| Crimson Hall | Four Blood Prince trash deaths set encounter 14 DONE; Crimson Hall door has trash-passage and Council-room controllers. Council DONE opens two passages; Blood-Queen controls her room/grate/sigil. | icecrown_citadel.cpp:2224-2235; instance_icecrown_citadel.cpp:104-109,1368-1380 |
| Svalna | Crok pauses for tracked Vrykul packs and resumes after their deaths. Svalna DONE unlocks Valithria entrance 201375, also used as Valithria room door. | icecrown_citadel.cpp:795-925; instance_icecrown_citadel.cpp:110-111 |
| Valithria | Healing objective DONE unlocks rear exit 201374; 201380-201383 are encounter spawn holes. | instance_icecrown_citadel.cpp:110-116,1150-1155 |
| Sindragosa gauntlet | Area trigger starts encounter 13. Controller runs three waves; non-broodling summon deaths advance them; controller death marks DONE and opens 201373. | icecrown_citadel.cpp:4038-4235,4345-4355; instance_icecrown_citadel.cpp:117-118 |
| Frostwyrms | Tracked whelp kills release Spinestalker/Rimefang; both deaths summon Sindragosa, subject to attempt/completion guards. | instance_icecrown_citadel.cpp:613-657 |
| Frozen Throne | Putricide, Blood-Queen and Sindragosa DONE activate the LK transporter; Heroic attempts/availability restrict some access. | instance_icecrown_citadel.cpp:1124-1168,1575-1594 |

## All DoorData bindings

Entries from instance_icecrown_citadel.cpp:94-123. One object with two rows has two controllers, not two doors. Spawn holes require separate treatment.

| Object | Entry | Controller | Type | Line |
|---|---:|---|---|---:|
| GO_LORD_MARROWGAR_S_ENTRANCE | 201857 | DATA_LORD_MARROWGAR | DOOR_TYPE_ROOM | 96 |
| GO_SCOURGE_TRANSPORTER_FIRST | 202242 | DATA_LORD_MARROWGAR | DOOR_TYPE_PASSAGE | 97 |
| GO_ICEWALL | 201911 | DATA_LORD_MARROWGAR | DOOR_TYPE_PASSAGE | 98 |
| GO_DOODAD_ICECROWN_ICEWALL02 | 201910 | DATA_LORD_MARROWGAR | DOOR_TYPE_PASSAGE | 99 |
| GO_ORATORY_OF_THE_DAMNED_ENTRANCE | 201563 | DATA_LADY_DEATHWHISPER | DOOR_TYPE_ROOM | 100 |
| GO_SAURFANG_S_DOOR | 201825 | DATA_DEATHBRINGER_SAURFANG | DOOR_TYPE_PASSAGE | 101 |
| GO_ORANGE_PLAGUE_MONSTER_ENTRANCE | 201371 | DATA_FESTERGUT | DOOR_TYPE_ROOM | 102 |
| GO_GREEN_PLAGUE_MONSTER_ENTRANCE | 201370 | DATA_ROTFACE | DOOR_TYPE_ROOM | 103 |
| GO_CRIMSON_HALL_DOOR | 201376 | DATA_BLOOD_PRINCE_COUNCIL | DOOR_TYPE_ROOM | 104 |
| GO_CRIMSON_HALL_DOOR | 201376 | DATA_BLOOD_PRINCE_TRASH | DOOR_TYPE_PASSAGE | 105 |
| GO_BLOOD_ELF_COUNCIL_DOOR | 201378 | DATA_BLOOD_PRINCE_COUNCIL | DOOR_TYPE_PASSAGE | 106 |
| GO_BLOOD_ELF_COUNCIL_DOOR_RIGHT | 201377 | DATA_BLOOD_PRINCE_COUNCIL | DOOR_TYPE_PASSAGE | 107 |
| GO_DOODAD_ICECROWN_BLOODPRINCE_DOOR_01 | 201746 | DATA_BLOOD_QUEEN_LANA_THEL | DOOR_TYPE_ROOM | 108 |
| GO_DOODAD_ICECROWN_GRATE_01 | 201755 | DATA_BLOOD_QUEEN_LANA_THEL | DOOR_TYPE_PASSAGE | 109 |
| GO_GREEN_DRAGON_BOSS_ENTRANCE | 201375 | DATA_SISTER_SVALNA | DOOR_TYPE_PASSAGE | 110 |
| GO_GREEN_DRAGON_BOSS_ENTRANCE | 201375 | DATA_VALITHRIA_DREAMWALKER | DOOR_TYPE_ROOM | 111 |
| GO_GREEN_DRAGON_BOSS_EXIT | 201374 | DATA_VALITHRIA_DREAMWALKER | DOOR_TYPE_PASSAGE | 112 |
| GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_01 | 201380 | DATA_VALITHRIA_DREAMWALKER | DOOR_TYPE_SPAWN_HOLE | 113 |
| GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_02 | 201381 | DATA_VALITHRIA_DREAMWALKER | DOOR_TYPE_SPAWN_HOLE | 114 |
| GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_03 | 201382 | DATA_VALITHRIA_DREAMWALKER | DOOR_TYPE_SPAWN_HOLE | 115 |
| GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_04 | 201383 | DATA_VALITHRIA_DREAMWALKER | DOOR_TYPE_SPAWN_HOLE | 116 |
| GO_SINDRAGOSA_ENTRANCE_DOOR | 201373 | DATA_SINDRAGOSA | DOOR_TYPE_ROOM | 117 |
| GO_SINDRAGOSA_ENTRANCE_DOOR | 201373 | DATA_SINDRAGOSA_GAUNTLET | DOOR_TYPE_PASSAGE | 118 |
| GO_SINDRAGOSA_SHORTCUT_ENTRANCE_DOOR | 201369 | DATA_SINDRAGOSA | DOOR_TYPE_PASSAGE | 119 |
| GO_SINDRAGOSA_SHORTCUT_EXIT_DOOR | 201379 | DATA_SINDRAGOSA | DOOR_TYPE_PASSAGE | 120 |
| GO_ICE_WALL | 202396 | DATA_SINDRAGOSA | DOOR_TYPE_ROOM | 121 |
| GO_ICE_WALL | 202396 | DATA_SINDRAGOSA | DOOR_TYPE_ROOM | 122 |

## Encounter checklist: source actions vs recording gaps

| Encounter | Source event areas | Difficulty and missing instrumentation |
|---|---|---|
| Marrowgar | Bone Slice, Spikes, Coldflame, Bone Storm, first icewalls | Heroic Bone Storm; 10/25 targets. Cast, phase, GO state missing. |
| Deathwhisper | Barrier, cultist waves/transform, phase 2, Gunship spawn | Heroic phase-2 waves; 10/25 Mind Control. Wave/phase missing. |
| Gunship | Hull victory, boarding, mage freeze, cannons, armory | Faction and 10/25/heroic branches; hull/transport/loot missing. |
| Saurfang | Intro, door, beasts, Blood Power, Mark, frenzy, cache | Heroic Scent of Blood and berserk timing; intro/casts missing. |
| Festergut | Inhale cycles, blight, spores, gas valve | Heroic Malleable Goo; valve use/state missing. |
| Rotface | Ooze combine/explosion, flood, ooze valve | Heroic Vile Gas; ooze phase/valve use missing. |
| Putricide | Two valves, trap, airlock, experiments, 80/35% phases, sigil | Heroic Unbound Plague/transitions; phase/GO state missing. |
| Council | Four prerequisite trash kills, princes, invocation, passages | Heroic Shadow Prison; fourth-kill/phase missing. |
| Blood-Queen | Bites, air phase, Blood Quickening, room/grate/sigil | 10/25 targets and heroic parameters; phase missing. |
| Svalna | Crok packs, captains, encounter and Valithria entrance | Tracked pack/captain actions missing. |
| Valithria | Healing, portals, suppressers, waves, exit | Normal Dream vs Heroic Nightmare portals; portal/heal missing. |
| Sindragosa gauntlet | Trigger, three waves, final controller death and entrance | Wave/controller/physical gate observation missing. |
| Sindragosa | Whelps, frostwyrms, ground/air/final phases, sigil | 10/25 tombs and Heroic attempts; phase missing. |
| Lich King | Wing access, platform, phases, Frostmourne, outro | Heroic Shadow Trap/Frostmourne vs Normal solo; outro/phase missing. |

## Complete local event symbol and difficulty branch index

Each distinct EVENT_ symbol in each listed file appears below at its first line. A symbol is a candidate event, not proof it ran. Explicit difficulty branch lines are included; called helpers, database scripts and spell scripts outside this folder need separate cross-reference.

### boss_blood_prince_council.cpp (1736 lines, 12 event symbols)

Events: EVENT_NONE (120), EVENT_INTRO_1 (121), EVENT_INTRO_2 (122), EVENT_INVOCATION_OF_BLOOD (124), EVENT_BERSERK (125), EVENT_SHADOW_RESONANCE (128), EVENT_GLITTERING_SPARKS (131), EVENT_CONJURE_FLAME (132), EVENT_KINETIC_BOMB (135), EVENT_SHOCK_VORTEX (136), EVENT_BOMB_DESPAWN (137), EVENT_CONTINUE_FALLING (138)

Difficulty branches: 282: if (IsHeroic()); 542: if (IsHeroic()); 834: if (IsHeroic()); 1036: events.ScheduleEvent(EVENT_KINETIC_BOMB, me->GetMap()->Is25ManRaid() ? 20s + 500ms : 30s + 500ms);

State/object writes: 355: instance->SetData(DATA_ORB_WHISPERER_ACHIEVEMENT, 0);; 625: instance->SetData(DATA_ORB_WHISPERER_ACHIEVEMENT, 0);; 785: instance->SetBossState(DATA_BLOOD_PRINCE_COUNCIL, NOT_STARTED);; 806: instance->SetBossState(DATA_BLOOD_PRINCE_COUNCIL, IN_PROGRESS);; 807: instance->SetData(DATA_ORB_WHISPERER_ACHIEVEMENT, 1);; 861: instance->SetBossState(DATA_BLOOD_PRINCE_COUNCIL, DONE);; 884: instance->SetBossState(DATA_BLOOD_PRINCE_COUNCIL, FAIL);; 923: instance->SetData(DATA_ORB_WHISPERER_ACHIEVEMENT, 0);; 1354: _instance->SetData(DATA_ORB_WHISPERER_ACHIEVEMENT, 0);

### boss_blood_queen_lana_thel.cpp (942 lines, 11 event symbols)

Events: EVENT_NONE (99), EVENT_BERSERK (100), EVENT_VAMPIRIC_BITE (101), EVENT_BLOOD_MIRROR (102), EVENT_DELIRIOUS_SLASH (103), EVENT_PACT_OF_THE_DARKFALLEN (104), EVENT_SWARMING_SHADOWS (105), EVENT_TWILIGHT_BLOODBOLT (106), EVENT_AIR_PHASE (107), EVENT_AIR_START_FLYING (108), EVENT_AIR_FLY_DOWN (109)

Difficulty branches: 222: events.ScheduleEvent(EVENT_AIR_PHASE, Is25ManRaid() ? 127s : 124s);; 241: if (Is25ManRaid() && me->HasAura(SPELL_SHADOWS_FATE)); 252: p->KilledMonsterCredit(Is25ManRaid() ? NPC_BLOOD_QUICKENING_CREDIT_25 : NPC_INFILTRATOR_MINCHAR_BQ);; 305: events.ScheduleEvent(EVENT_AIR_PHASE, Is25ManRaid() ? 100s : 120s);; 402: if (Is25ManRaid() && target->GetQuestStatus(QUEST_BLOOD_INFUSION) == QUEST_STATUS_INCOMPLETE &&; 441: Acore::Containers::RandomResize(myList, Is25ManRaid() ? 3 : 2);; 489: Acore::Containers::RandomResize(myList, uint32(Is25ManRaid() ? 4 : 2));; 612: float herobonus = ((GetTarget()->FindMap() && GetTarget()->FindMap()->IsHeroic()) ? 0.2f : 0.0f);

State/object writes: 195: instance->SetBossState(DATA_BLOOD_QUEEN_LANA_THEL, FAIL);; 199: instance->SetBossState(DATA_BLOOD_QUEEN_LANA_THEL, NOT_STARTED);; 230: instance->SetBossState(DATA_BLOOD_QUEEN_LANA_THEL, IN_PROGRESS);; 248: instance->SetData(DATA_BLOOD_QUICKENING_STATE, DONE);; 268: instance->SetData(DATA_BLOOD_QUICKENING_STATE, DONE);

### boss_deathbringer_saurfang.cpp (1339 lines, 49 event symbols)

Events: EVENT_INTRO_ALLIANCE_1 (123), EVENT_INTRO_ALLIANCE_2 (124), EVENT_INTRO_ALLIANCE_3 (125), EVENT_INTRO_ALLIANCE_4 (126), EVENT_INTRO_ALLIANCE_5 (127), EVENT_INTRO_ALLIANCE_6 (128), EVENT_INTRO_ALLIANCE_7 (129), EVENT_INTRO_HORDE_1 (131), EVENT_INTRO_HORDE_2 (132), EVENT_INTRO_HORDE_3 (133), EVENT_INTRO_HORDE_4 (134), EVENT_INTRO_HORDE_5 (135), EVENT_INTRO_HORDE_6 (136), EVENT_INTRO_HORDE_7 (137), EVENT_INTRO_HORDE_8 (138), EVENT_INTRO_HORDE_9 (139), EVENT_INTRO_FINISH (141), EVENT_BERSERK (143), EVENT_SUMMON_BLOOD_BEAST (144), EVENT_BLOOD_BEAST_SCENT_OF_BLOOD (145), EVENT_BOILING_BLOOD (146), EVENT_BLOOD_NOVA (147), EVENT_RUNE_OF_BLOOD (148), EVENT_OUTRO_ALLIANCE_1 (150), EVENT_OUTRO_ALLIANCE_2 (151), EVENT_OUTRO_ALLIANCE_3 (152), EVENT_OUTRO_ALLIANCE_4 (153), EVENT_OUTRO_ALLIANCE_5 (154), EVENT_OUTRO_ALLIANCE_6 (155), EVENT_OUTRO_ALLIANCE_7 (156), EVENT_OUTRO_ALLIANCE_8 (157), EVENT_OUTRO_ALLIANCE_9 (158), EVENT_OUTRO_ALLIANCE_10 (159), EVENT_OUTRO_ALLIANCE_11 (160), EVENT_OUTRO_ALLIANCE_12 (161), EVENT_OUTRO_ALLIANCE_13 (162), EVENT_OUTRO_ALLIANCE_14 (163), EVENT_OUTRO_ALLIANCE_15 (164), EVENT_OUTRO_ALLIANCE_16 (165), EVENT_OUTRO_ALLIANCE_17 (166), EVENT_OUTRO_ALLIANCE_18 (167), EVENT_OUTRO_ALLIANCE_19 (168), EVENT_OUTRO_ALLIANCE_20 (169), EVENT_OUTRO_ALLIANCE_21 (170), EVENT_OUTRO_HORDE_1 (172), EVENT_OUTRO_HORDE_2 (173), EVENT_OUTRO_HORDE_3 (174), EVENT_OUTRO_HORDE_4 (175), EVENT_OUTRO_HORDE_5 (176)

Difficulty branches: 298: events.ScheduleEvent(EVENT_BERSERK, (IsHeroic() ? 6min : 8min));; 361: //if (IsHeroic()); 425: if (Is25ManRaid()); 430: if (IsHeroic())

State/object writes: 305: instance->SetBossState(DATA_DEATHBRINGER_SAURFANG, IN_PROGRESS);; 337: instance->SetBossState(DATA_DEATHBRINGER_SAURFANG, FAIL);; 380: instance->HandleGameObject(instance->GetGuidData(GO_SAURFANG_S_DOOR), false);; 559: (*itr)->AI()->SetData(0, x++);; 566: _instance->HandleGameObject(_instance->GetGuidData(GO_SAURFANG_S_DOOR), true);; 570: _instance->HandleGameObject(ObjectGuid::Empty, false, teleporter);; 820: (*itr)->AI()->SetData(0, x++);; 828: _instance->HandleGameObject(_instance->GetGuidData(GO_SAURFANG_S_DOOR), true);; 832: _instance->HandleGameObject(ObjectGuid::Empty, false, teleporter);; 1007: void SetData(uint32 type, uint32 data) override

### boss_festergut.cpp (496 lines, 9 event symbols)

Events: EVENT_NONE (71), EVENT_BERSERK (72), EVENT_INHALE_BLIGHT (73), EVENT_VILE_GAS (74), EVENT_GAS_SPORE (75), EVENT_GASTRIC_BLOAT (76), EVENT_FESTERGUT_GOO (77), EVENT_DECIMATE (80), EVENT_MORTAL_WOUND (81)

Difficulty branches: 128: if (IsHeroic()); 389: uint32 questId = map->Is25ManRaid() ? QUEST_RESIDUE_RENDEZVOUS_25 : QUEST_RESIDUE_RENDEZVOUS_10;

State/object writes: 154: instance->SetBossState(DATA_FESTERGUT, FAIL);; 254: void SetData(uint32 type, uint32 data) override; 340: festergut->AI()->SetData(DATA_INOCULATED_STACK, inoculatedStack);

### boss_icecrown_gunship_battle.cpp (2657 lines, 25 event symbols)

Events: EVENT_INTRO_H_1 (79), EVENT_INTRO_H_2 (80), EVENT_INTRO_SUMMON_SKYBREAKER (81), EVENT_INTRO_H_3 (82), EVENT_INTRO_H_4 (83), EVENT_INTRO_H_5 (84), EVENT_INTRO_H_6 (85), EVENT_INTRO_A_1 (88), EVENT_INTRO_A_2 (89), EVENT_INTRO_SUMMON_ORGRIMS_HAMMER (90), EVENT_INTRO_A_3 (91), EVENT_INTRO_A_4 (92), EVENT_INTRO_A_5 (93), EVENT_INTRO_A_6 (94), EVENT_INTRO_A_7 (95), EVENT_KEEP_PLAYER_IN_COMBAT (97), EVENT_SUMMON_MAGE (98), EVENT_ADDS (99), EVENT_ADDS_BOARD_YELL (100), EVENT_CHECK_RIFLEMAN (101), EVENT_CHECK_MORTAR (102), EVENT_CLEAVE (103), EVENT_BLADESTORM (104), EVENT_WOUNDING_STRIKE (105), EVENT_CHARGE_PREPATH (108)

Difficulty branches: 389: if (_level < (_creature->GetMap()->IsHeroic() ? 4 : 3)); 731: if (me->GetMap()->Is25ManRaid()); 860: if (Is25ManRaid()); 995: _controller.SummonCreatures(me, SLOT_MARINE_1, Is25ManRaid() ? SLOT_MARINE_4 : SLOT_MARINE_2);; 996: _controller.SummonCreatures(me, SLOT_SERGEANT_1, Is25ManRaid() ? SLOT_SERGEANT_2 : SLOT_SERGEANT_1);; 1022: if (_controller.SummonCreatures(me, SLOT_RIFLEMAN_1, Is25ManRaid() ? SLOT_RIFLEMAN_8 : SLOT_RIFLEMAN; 1033: if (_controller.SummonCreatures(me, SLOT_MORTAR_1, Is25ManRaid() ? SLOT_MORTAR_4 : SLOT_MORTAR_2)); 1196: if (Is25ManRaid()); 1334: _controller.SummonCreatures(me, SLOT_MARINE_1, Is25ManRaid() ? SLOT_MARINE_4 : SLOT_MARINE_2);; 1335: _controller.SummonCreatures(me, SLOT_SERGEANT_1, Is25ManRaid() ? SLOT_SERGEANT_2 : SLOT_SERGEANT_1);; 1361: if (_controller.SummonCreatures(me, SLOT_RIFLEMAN_1, Is25ManRaid() ? SLOT_RIFLEMAN_8 : SLOT_RIFLEMAN; 1372: if (_controller.SummonCreatures(me, SLOT_MORTAR_1, Is25ManRaid() ? SLOT_MORTAR_4 : SLOT_MORTAR_2))

State/object writes: 460: passenger->AI()->SetData(ACTION_SET_SLOT, i);; 590: _instance->SetBossState(DATA_ICECROWN_GUNSHIP_BATTLE, isVictory ? DONE : FAIL);; 828: _instance->SetBossState(DATA_ICECROWN_GUNSHIP_BATTLE, IN_PROGRESS);; 888: void SetData(uint32 type, uint32 data) override; 1164: _instance->SetBossState(DATA_ICECROWN_GUNSHIP_BATTLE, IN_PROGRESS);; 1224: void SetData(uint32 type, uint32 data) override; 1511: void SetData(uint32 type, uint32 data) override; 1540: captain->AI()->SetData(ACTION_CLEAR_SLOT, Index);; 1577: void SetData(uint32 type, uint32 data) override

### boss_lady_deathwhisper.cpp (1200 lines, 32 event symbols)

Events: EVENT_INTRO_2 (121), EVENT_INTRO_3 (122), EVENT_INTRO_4 (123), EVENT_INTRO_5 (124), EVENT_INTRO_6 (125), EVENT_INTRO_7 (126), EVENT_BERSERK (128), EVENT_SPELL_DEATH_AND_DECAY (129), EVENT_SPELL_DOMINATE_MIND_25 (130), EVENT_SPELL_SHADOW_BOLT (133), EVENT_SUMMON_WAVE_P1 (134), EVENT_EMPOWER_CULTIST (135), EVENT_SPELL_FROSTBOLT (138), EVENT_SPELL_FROSTBOLT_VOLLEY (139), EVENT_SPELL_TOUCH_OF_INSIGNIFICANCE (140), EVENT_SPELL_SUMMON_SHADE (141), EVENT_SUMMON_WAVE_P2 (142), EVENT_SPELL_CULTIST_DARK_MARTYRDOM (145), EVENT_CULTIST_DARK_MARTYRDOM_REVIVE (146), EVENT_SPELL_FANATIC_NECROTIC_STRIKE (149), EVENT_SPELL_FANATIC_SHADOW_CLEAVE (150), EVENT_SPELL_FANATIC_VAMPIRIC_MIGHT (151), EVENT_SPELL_ADHERENT_FROST_FEVER (154), EVENT_SPELL_ADHERENT_DEATHCHILL (155), EVENT_SPELL_ADHERENT_CURSE_OF_TORPOR (156), EVENT_SPELL_ADHERENT_SHROUD_OF_THE_OCCULT (157), EVENT_DARNAVAN_BLADESTORM (160), EVENT_DARNAVAN_CHARGE (161), EVENT_DARNAVAN_INTIMIDATING_SHOUT (162), EVENT_DARNAVAN_MORTAL_STRIKE (163), EVENT_DARNAVAN_SHATTERING_THROW (164), EVENT_DARNAVAN_SUNDER_ARMOR (165)

Difficulty branches: 286: if (GetDifficulty() != RAID_DIFFICULTY_10MAN_NORMAL); 324: if (IsHeroic()); 419: events.Repeat(IsHeroic() ? 45s : 60s);; 444: if (GetDifficulty() == RAID_DIFFICULTY_25MAN_NORMAL); 446: else if (GetDifficulty() == RAID_DIFFICULTY_25MAN_HEROIC); 583: if (Is25ManRaid()); 596: if (Is25ManRaid())

State/object writes: 296: instance->SetBossState(DATA_LADY_DEATHWHISPER, IN_PROGRESS);

### boss_lord_marrowgar.cpp (669 lines, 9 event symbols)

Events: EVENT_ENABLE_BONE_SLICE (62), EVENT_SPELL_BONE_SPIKE_GRAVEYARD (63), EVENT_SPELL_COLDFLAME (64), EVENT_SPELL_COLDFLAME_BONE_STORM (65), EVENT_WARN_BONE_STORM (66), EVENT_BEGIN_BONE_STORM (67), EVENT_BONE_STORM_MOVE (68), EVENT_END_BONE_STORM (69), EVENT_ENRAGE (70)

Difficulty branches: 178: if (IsHeroic() || !a); 221: SelectTargetList(targets, Is25ManRaid() ? 2 : 1, SelectTargetMethod::MaxDistance, 0, BoneStormMoveTa; 247: if (!IsHeroic())

State/object writes: 128: instance->SetData(DATA_BONED_ACHIEVEMENT, uint32(true));; 136: instance->SetBossState(DATA_LORD_MARROWGAR, IN_PROGRESS);; 288: instance->SetBossState(DATA_LORD_MARROWGAR, FAIL);; 473: instance->SetData(DATA_BONED_ACHIEVEMENT, uint32(false));

### boss_professor_putricide.cpp (1619 lines, 13 event symbols)

Events: EVENT_NONE (126), EVENT_BERSERK (127), EVENT_SLIME_PUDDLE (128), EVENT_UNSTABLE_EXPERIMENT (129), EVENT_GO_TO_TABLE (130), EVENT_TABLE_DRINK_STUFF (131), EVENT_PHASE_TRANSITION (132), EVENT_RESUME_ATTACK (133), EVENT_UNBOUND_PLAGUE (134), EVENT_MALLEABLE_GOO (135), EVENT_CHOKING_GAS_BOMB (136), EVENT_MUTATED_PLAGUE (137), EVENT_GROUP_ABILITIES (140)

Difficulty branches: 310: if (IsHeroic()); 347: if (Is25ManRaid() && me->HasAura(SPELL_SHADOWS_FATE)); 463: events.ScheduleEvent(EVENT_TABLE_DRINK_STUFF, IsHeroic() ? 25s : 0ms);; 631: if (Is25ManRaid()); 634: SelectTargetList(targets, (IsHeroic() ? 3 : 2), SelectTargetMethod::Random, 0, MalleableGooSelector(; 680: Milliseconds heroicDelay = (IsHeroic() ? 25s : 0ms);; 683: if (!IsHeroic()); 694: if (Is25ManRaid())

State/object writes: 277: void SetData(uint32 id, uint32 data) override; 319: instance->SetBossState(DATA_PROFESSOR_PUTRICIDE, IN_PROGRESS);; 320: instance->SetData(DATA_NAUSEA_ACHIEVEMENT, uint32(true));; 329: instance->SetBossState(DATA_PROFESSOR_PUTRICIDE, FAIL);; 430: instance->SetBossState(DATA_FESTERGUT, IN_PROGRESS);; 446: instance->SetBossState(DATA_ROTFACE, IN_PROGRESS);; 1004: creature->AI()->SetData(DATA_EXPERIMENT_STAGE, stage ? 0 : 1);; 1559: instance->SetData(DATA_NAUSEA_ACHIEVEMENT, uint32(false));

### boss_rotface.cpp (913 lines, 11 event symbols)

Events: EVENT_NONE (77), EVENT_UNROOT (79), EVENT_SLIME_SPRAY (80), EVENT_HASTEN_INFECTIONS (81), EVENT_MUTATED_INFECTION (82), EVENT_ROTFACE_OOZE_FLOOD (83), EVENT_ROTFACE_VILE_GAS (84), EVENT_STICKY_OOZE (86), EVENT_DECIMATE (89), EVENT_MORTAL_WOUND (90), EVENT_SUMMON_ZOMBIES (91)

Difficulty branches: 164: if (IsHeroic())

State/object writes: 174: instance->SetData(DATA_OOZE_DANCE_ACHIEVEMENT, uint32(true)); // reset; 204: instance->SetBossState(DATA_ROTFACE, FAIL);; 661: instance->SetData(DATA_OOZE_DANCE_ACHIEVEMENT, uint32(false));; 718: instance->SetData(DATA_OOZE_DANCE_ACHIEVEMENT, uint32(false));

### boss_sindragosa.cpp (1834 lines, 28 event symbols)

Events: EVENT_NONE (106), EVENT_BERSERK (109), EVENT_CLEAVE (110), EVENT_TAIL_SMASH (111), EVENT_FROST_BREATH (112), EVENT_UNROOT (113), EVENT_UNCHAINED_MAGIC (114), EVENT_ICY_GRIP (115), EVENT_BLISTERING_COLD (116), EVENT_BLISTERING_COLD_YELL (117), EVENT_AIR_PHASE (118), EVENT_AIR_MOVEMENT (119), EVENT_AIR_MOVEMENT_FAR (120), EVENT_LAND (121), EVENT_LAND_GROUND (122), EVENT_FROST_BOMB (123), EVENT_THIRD_PHASE_CHECK (124), EVENT_ICE_TOMB (125), EVENT_BELLOWING_ROAR (128), EVENT_CLEAVE_SPINESTALKER (129), EVENT_TAIL_SWEEP (130), EVENT_FROST_BREATH_RIMEFANG (133), EVENT_ICY_BLAST (134), EVENT_ICY_BLAST_CAST (135), EVENT_FROSTWARDEN_ORDER_WHELP (138), EVENT_CONCUSSIVE_SHOCK (139), EVENT_WHELP_FROST_BLAST (140), EVENT_GROUP_LAND_PHASE (143)

Difficulty branches: 309: if (Is25ManRaid() && me->HasAura(SPELL_SHADOWS_FATE)); 1152: if (GetStackAmount() >= (s->GetMap()->Is25ManRaid() ? 75 : 30))

State/object writes: 346: instance->SetBossState(DATA_SINDRAGOSA, IN_PROGRESS);; 360: instance->SetBossState(DATA_SINDRAGOSA, FAIL);; 1195: _instance->SetData(DATA_SINDRAGOSA_FROSTWYRMS, me->GetSpawnId());  // this cannot be in Reset becaus; 1226: _instance->SetData(DATA_SINDRAGOSA_FROSTWYRMS, me->GetSpawnId());  // this cannot be in Reset becaus; 1326: _instance->SetData(DATA_SINDRAGOSA_FROSTWYRMS, me->GetSpawnId());  // this cannot be in Reset becaus; 1357: _instance->SetData(DATA_SINDRAGOSA_FROSTWYRMS, me->GetSpawnId());  // this cannot be in Reset becaus; 1567: _instance->SetData(_frostwyrmId, me->GetSpawnId());  // this cannot be in Reset because reset also h; 1610: _instance->SetData(_frostwyrmId, me->GetSpawnId());  // this cannot be in Reset because reset also h; 1613: void SetData(uint32 type, uint32 data) override; 1737: GetCaster()->GetAI()->SetData(DATA_WHELP_MARKER, 1);; 1756: caster->GetAI()->SetData(DATA_WHELP_MARKER, 0);

### boss_the_lich_king.cpp (3593 lines, 76 event symbols)

Events: EVENT_NONE (193), EVENT_INTRO_LK_MOVE (196), EVENT_INTRO_LK_TALK_1 (197), EVENT_INTRO_LK_EMOTE_CAST_SHOUT (198), EVENT_INTRO_LK_EMOTE_1 (199), EVENT_INTRO_LK_CAST_FREEZE (200), EVENT_INTRO_FORDRING_TALK_1 (201), EVENT_INTRO_FORDRING_TALK_2 (202), EVENT_INTRO_FORDRING_EMOTE_1 (203), EVENT_INTRO_FORDRING_CHARGE (204), EVENT_INTRO_FINISH (205), EVENT_OUTRO_LK_TALK_1 (208), EVENT_OUTRO_LK_TALK_2 (209), EVENT_OUTRO_LK_EMOTE_TALK (210), EVENT_OUTRO_LK_TALK_3 (211), EVENT_OUTRO_LK_EMOTE_CAST_SHOUT (212), EVENT_OUTRO_LK_MOVE_CENTER (213), EVENT_OUTRO_LK_TALK_4 (214), EVENT_OUTRO_LK_RAISE_DEAD (215), EVENT_OUTRO_LK_TALK_5 (216), EVENT_OUTRO_LK_TALK_6 (217), EVENT_OUTRO_LK_TALK_7 (218), EVENT_OUTRO_LK_TALK_8 (219), EVENT_OUTRO_FORDRING_TALK_1 (220), EVENT_OUTRO_FORDRING_BLESS (221), EVENT_OUTRO_FORDRING_REMOVE_ICE (222), EVENT_OUTRO_FORDRING_MOVE_1 (223), EVENT_OUTRO_FORDRING_JUMP (224), EVENT_OUTRO_AFTER_SUMMON_BROKEN_FROSTMOURNE (225), EVENT_OUTRO_KNOCK_BACK (226), EVENT_OUTRO_SOUL_BARRAGE (227), EVENT_OUTRO_AFTER_SOUL_BARRAGE (228), EVENT_OUTRO_SUMMON_TERENAS (229), EVENT_OUTRO_TERENAS_TALK_1 (230), EVENT_OUTRO_TERENAS_TALK_2 (231), EVENT_BERSERK (234), EVENT_START_ATTACK (235), EVENT_QUAKE (236), EVENT_QUAKE_2 (237), EVENT_SUMMON_SHAMBLING_HORROR (240), EVENT_SUMMON_DRUDGE_GHOUL (241), EVENT_INFEST (242), EVENT_NECROTIC_PLAGUE (243), EVENT_SHADOW_TRAP (244), EVENT_PAIN_AND_SUFFERING (245), EVENT_SUMMON_ICE_SPHERE (246), EVENT_SUMMON_RAGING_SPIRIT (247), EVENT_DEFILE (248), EVENT_SOUL_REAPER (249), EVENT_SUMMON_VALKYR (250), EVENT_VILE_SPIRITS (251), EVENT_HARVEST_SOUL (252), EVENT_HARVEST_SOULS (253), EVENT_FROSTMOURNE_HEROIC (254), EVENT_SHOCKWAVE (257), EVENT_ENRAGE (258), EVENT_SOUL_SHRIEK (261), EVENT_RAGING_SPIRIT_UNROOT (262), EVENT_GRAB_PLAYER (265), EVENT_MOVE_TO_DROP_POS (266), EVENT_MOVE_TO_SIPHON_POS (267), EVENT_LIFE_SIPHON (268), EVENT_TELEPORT (271), EVENT_MOVE_TO_LICH_KING (272), EVENT_DESPAWN_SELF (273), EVENT_FROSTMOURNE_TALK_1 (276), EVENT_FROSTMOURNE_TALK_2 (277), EVENT_FROSTMOURNE_TALK_3 (278), EVENT_DESTROY_SOUL (279), EVENT_TELEPORT_BACK (280), EVENT_SOUL_RIP (281), EVENT_GROUP_NONE (286), EVENT_GROUP_ABILITIES (287), EVENT_GROUP_BERSERK (288), EVENT_GROUP_VILE_SPIRITS (289), EVENT_CHARGE (2462)

Difficulty branches: 706: if (IsHeroic()); 750: if (!IsHeroic() && _phase != PHASE_OUTRO && me->IsInCombat() && _lastTalkTimeBuff + 5 <= GameTime::G; 910: if (spell->Id == sSpellMgr->GetSpellIdForDifficulty(SPELL_HARVESTED_SOUL_LK_BUFF, me) && me->IsInCom; 1034: events.ScheduleEvent(IsHeroic() ? EVENT_HARVEST_SOULS : EVENT_HARVEST_SOUL, 14s, EVENT_GROUP_ABILITI; 1080: events.Repeat((IsHeroic() ? randtime(1250ms, 1750ms) : randtime(1750ms, 2250ms)));; 1103: events.ScheduleEvent(EVENT_DEFILE, t + (Is25ManRaid() ? 5s : 4s), EVENT_GROUP_ABILITIES);; 1140: DoCastSelf(Is25ManRaid() ? SPELL_SUMMON_VALKYR_PERIODIC : SPELL_SUMMON_VALKYR);; 1145: Milliseconds minTime = (Is25ManRaid() ? 5s : 4s);; 1289: if (_instance->GetBossState(DATA_THE_LICH_KING) == DONE || (me->GetMap()->IsHeroic() && !_instance->; 1361: if (!(_instance->GetBossState(DATA_THE_LICH_KING) == DONE || (me->GetMap()->IsHeroic() && !_instance; 1371: if (me->GetMap()->IsHeroic() && !_instance->GetData(DATA_LK_HC_AVAILABLE)); 1791: if (!_frenzied && IsHeroic() && me->HealthBelowPctDamaged(20, damage)); 2417: bool IsHeroic() { return me->GetMap()->IsHeroic(); }; 2443: if (IsHeroic()); 2451: if (IsHeroic() && !didbelow50pct && !dropped && me->HealthBelowPctDamaged(50, damage)); 2513: if (IsHeroic()); 2782: _is25Man = GetUnitOwner()->GetMap()->Is25ManRaid();; 2960: bool IsHeroic() { return me->GetMap()->IsHeroic(); }; 2988: summoner->RemoveAurasDueToSpell(IsHeroic() ? SPELL_HARVEST_SOULS_TELEPORT : SPELL_HARVEST_SOUL_TELEP; 3020: if (!IsHeroic()); 3083: if (!IsHeroic()); 3106: if (IsHeroic()); 3138: if (IsHeroic()); 3235: target->RemoveAurasDueToSpell(target->GetMap()->IsHeroic() ? SPELL_HARVEST_SOULS_TELEPORT : SPELL_HA

State/object writes: 696: instance->SetBossState(DATA_THE_LICH_KING, IN_PROGRESS);; 1239: void SetData(uint32 type, uint32 value) override; 1261: instance->SetBossState(DATA_THE_LICH_KING, FAIL);; 1982: caster->GetAI()->SetData(DATA_PLAGUE_STACK, GetStackAmount());; 2872: summoner->GetAI()->SetData(DATA_VILE, 1);

### boss_valithria_dreamwalker.cpp (1409 lines, 18 event symbols)

Events: EVENT_INTRO_TALK (107), EVENT_BERSERK (108), EVENT_DREAM_PORTAL (109), EVENT_DREAM_SLIP (110), EVENT_GLUTTONOUS_ABOMINATION_SUMMONER (113), EVENT_SUPPRESSER_SUMMONER (114), EVENT_BLISTERING_ZOMBIE_SUMMONER (115), EVENT_RISEN_ARCHMAGE_SUMMONER (116), EVENT_BLAZING_SKELETON_SUMMONER (117), EVENT_FROSTBOLT_VOLLEY (120), EVENT_MANA_VOID (121), EVENT_COLUMN_OF_FROST (122), EVENT_FIREBALL (125), EVENT_LEY_WASTE (126), EVENT_SUPPRESSION (129), EVENT_GUT_SPRAY (132), EVENT_CHECK_PLAYER (136), EVENT_EXPLODE (137)

Difficulty branches: 321: if (IsHeroic()); 440: if (!IsHeroic()); 497: if (Is25ManRaid())

State/object writes: 395: _instance->SetData(DATA_WEEKLY_QUEST_ID, 0); // show hidden npc if necessary; 522: instance->SetBossState(DATA_VALITHRIA_DREAMWALKER, IN_PROGRESS);; 551: instance->SetBossState(DATA_VALITHRIA_DREAMWALKER, NOT_STARTED);

### icecrown_citadel.cpp (4463 lines, 64 event symbols)

Events: EVENT_TIRION_INTRO_2 (225), EVENT_TIRION_INTRO_3 (226), EVENT_TIRION_INTRO_4 (227), EVENT_TIRION_INTRO_5 (228), EVENT_LK_INTRO_1 (229), EVENT_TIRION_INTRO_6 (230), EVENT_LK_INTRO_2 (231), EVENT_LK_INTRO_3 (232), EVENT_LK_INTRO_4 (233), EVENT_BOLVAR_INTRO_1 (234), EVENT_LK_INTRO_5 (235), EVENT_SAURFANG_INTRO_1 (236), EVENT_TIRION_INTRO_H_7 (237), EVENT_SAURFANG_INTRO_2 (238), EVENT_SAURFANG_INTRO_3 (239), EVENT_SAURFANG_INTRO_4 (240), EVENT_SAURFANG_RUN (241), EVENT_MURADIN_INTRO_1 (242), EVENT_MURADIN_INTRO_2 (243), EVENT_MURADIN_INTRO_3 (244), EVENT_TIRION_INTRO_A_7 (245), EVENT_MURADIN_INTRO_4 (246), EVENT_MURADIN_INTRO_5 (247), EVENT_MURADIN_RUN (248), EVENT_DEATH_PLAGUE (251), EVENT_STOMP (252), EVENT_ARCTIC_BREATH (253), EVENT_ACTIVATE_TRAP (256), EVENT_SCOURGE_STRIKE (259), EVENT_DEATH_STRIKE (260), EVENT_HEALTH_CHECK (261), EVENT_CROK_INTRO_3 (262), EVENT_START_PATHING (263), EVENT_ARNATH_INTRO_2 (266), EVENT_SVALNA_START (267), EVENT_SVALNA_RESURRECT (268), EVENT_SVALNA_COMBAT (269), EVENT_IMPALING_SPEAR (270), EVENT_AETHER_SHIELD (271), EVENT_ARNATH_FLASH_HEAL (274), EVENT_ARNATH_PW_SHIELD (275), EVENT_ARNATH_SMITE (276), EVENT_ARNATH_DOMINATE_MIND (277), EVENT_BRANDON_CRUSADER_STRIKE (280), EVENT_BRANDON_DIVINE_SHIELD (281), EVENT_BRANDON_JUDGEMENT_OF_COMMAND (282), EVENT_BRANDON_HAMMER_OF_BETRAYAL (283), EVENT_GRONDEL_CHARGE_CHECK (286), EVENT_GRONDEL_MORTAL_STRIKE (287), EVENT_GRONDEL_SUNDER_ARMOR (288), EVENT_GRONDEL_CONFLAGRATION (289), EVENT_RUPERT_FEL_IRON_BOMB (292), EVENT_RUPERT_MACHINE_GUN (293), EVENT_RUPERT_ROCKET_LAUNCH (294), EVENT_SOUL_MISSILE (297), EVENT_AWAKEN_WARD_1 (321), EVENT_AWAKEN_WARD_2 (322), EVENT_AWAKEN_WARD_3 (323), EVENT_AWAKEN_WARD_4 (324), EVENT_CHECK_FIGHT (4060), EVENT_GAUNTLET_PHASE1 (4061), EVENT_GAUNTLET_PHASE2 (4062), EVENT_GAUNTLET_PHASE3 (4063), EVENT_SUMMON_BROODLING (4064)

Difficulty branches: 1410: if (Is25ManRaid() && IsUndead); 1734: if (me->GetMap()->Is25ManRaid()); 3517: uint8 count = me->GetMap()->Is25ManRaid() ? 4 : 2;

State/object writes: 454: void SetData(uint32 type, uint32 data) override; 2233: instance->SetData(DATA_BPC_TRASH_DIED, 1);; 2738: (*itr)->AI()->SetData(1, 1);; 2969: instance->SetData(DATA_COLDFLAME_JETS, IN_PROGRESS);; 2998: instance->SetData(DATA_COLDFLAME_JETS, DONE);; 3011: instance->SetData(DATA_BLOOD_QUICKENING_STATE, IN_PROGRESS);; 3938: inst->SetData(DATA_BUFF_AVAILABLE, 0);; 4142: instance->SetBossState(DATA_SINDRAGOSA_GAUNTLET, IN_PROGRESS);; 4152: instance->SetBossState(DATA_SINDRAGOSA_GAUNTLET, NOT_STARTED);; 4164: instance->SetBossState(DATA_SINDRAGOSA_GAUNTLET, DONE);; 4266: instance->SetData(DATA_PUTRICIDE_TRAP_STATE, IN_PROGRESS);; 4280: instance->SetData(DATA_PUTRICIDE_TRAP_STATE, NOT_STARTED);; 4329: instance->SetData(DATA_PUTRICIDE_TRAP_STATE, DONE);

### icecrown_citadel_teleport.cpp (137 lines, 0 event symbols)

Events: none

Difficulty branches: none in this file

State/object writes: none using these APIs

### instance_icecrown_citadel.cpp (1984 lines, 15 event symbols)

Events: EVENT_PLAYERS_GUNSHIP_SPAWN (36), EVENT_PLAYERS_GUNSHIP_COMBAT (37), EVENT_PLAYERS_GUNSHIP_SAURFANG (38), EVENT_ENEMY_GUNSHIP_COMBAT (39), EVENT_ENEMY_GUNSHIP_DESPAWN (40), EVENT_QUAKE (42), EVENT_SECOND_REMORSELESS_WINTER (43), EVENT_TELEPORT_TO_FROSMOURNE (44), EVENT_FESTERGUT_VALVE_USED (45), EVENT_ROTFACE_VALVE_USED (46), EVENT_UPDATE_EXECUTION_TIME (51), EVENT_QUAKE_SHATTER (52), EVENT_REBUILD_PLATFORM (53), EVENT_RESPAWN_GUNSHIP (54), EVENT_RESPAWN_SINDRAGOSA (55)

Difficulty branches: 240: packet.Worldstates.emplace_back(WORLD_STATE_ICECROWN_CITADEL_SHOW_ATTEMPTS, instance->IsHeroic() ? 1; 714: if (instance->Is25ManRaid()); 917: return (instance->IsHeroic() ? 1 : 0);; 1133: if (state == DONE && !instance->IsHeroic() && LichKingHeroicAvailable); 1145: if (state == DONE && !instance->IsHeroic() && LichKingHeroicAvailable); 1164: if (state == DONE && !instance->IsHeroic() && LichKingHeroicAvailable)

State/object writes: 709: HandleGameObject(PutricideEnteranceDoorGUID, PutricideEventProgress & PUTRICIDE_EVENT_FLAG_TRAP_FINI; 750: HandleGameObject(PlagueSigilGUID, false, go);; 755: HandleGameObject(BloodwingSigilGUID, false, go);; 760: HandleGameObject(FrostwingSigilGUID, false, go);; 764: HandleGameObject(PutricideCollisionGUID, ((PutricideEventProgress & PUTRICIDE_EVENT_FLAG_FESTERGUT_V; 771: HandleGameObject(PutricideGateGUIDs[0], !(PutricideEventProgress & PUTRICIDE_EVENT_FLAG_FESTERGUT_VA; 778: HandleGameObject(PutricideGateGUIDs[1], !(PutricideEventProgress & PUTRICIDE_EVENT_FLAG_ROTFACE_VALV; 783: HandleGameObject(PutricidePipeGUIDs[0], true, go);; 788: HandleGameObject(PutricidePipeGUIDs[1], true, go);; 1053: bool SetBossState(uint32 type, EncounterState state) override; 1055: if (!InstanceScript::SetBossState(type, state)); 1064: SetData(DATA_WEEKLY_QUEST_ID, 0); // show required hidden npcs; 1100: HandleGameObject(SaurfangTeleportGUID, true, teleporter);; 1127: HandleGameObject(PutricideEnteranceDoorGUID, (PutricideEventProgress & PUTRICIDE_EVENT_FLAG_TRAP_FIN; 1128: HandleGameObject(PlagueSigilGUID, state != DONE);; 1140: HandleGameObject(BloodwingSigilGUID, state != DONE);; 1153: SetData(DATA_WEEKLY_QUEST_ID, GetData(DATA_WEEKLY_QUEST_ID)); // will show weekly quest npc if neces; 1156: HandleGameObject(FrostwingSigilGUID, state != DONE);; 1210: SetBossState(DATA_ICECROWN_GUNSHIP_BATTLE, NOT_STARTED);; 1220: void SetData(uint32 type, uint32 data) override; 1273: HandleGameObject(PutricideCollisionGUID, ((PutricideEventProgress & PUTRICIDE_EVENT_FLAG_FESTERGUT_V; 1282: HandleGameObject(PutricideGateGUIDs[0], !(PutricideEventProgress & PUTRICIDE_EVENT_FLAG_FESTERGUT_VA; 1283: HandleGameObject(PutricideGateGUIDs[1], !(PutricideEventProgress & PUTRICIDE_EVENT_FLAG_ROTFACE_VALV; 1290: HandleGameObject(PutricideCollisionGUID, false);; 1291: HandleGameObject(PutricideGateGUIDs[0], false);; 1292: HandleGameObject(PutricideGateGUIDs[1], false);; 1299: HandleGameObject(PutricideEnteranceDoorGUID, true);; 1300: HandleGameObject(PutricideCollisionGUID, ((PutricideEventProgress & PUTRICIDE_EVENT_FLAG_FESTERGUT_V; 1309: HandleGameObject(PutricideGateGUIDs[0], !(PutricideEventProgress & PUTRICIDE_EVENT_FLAG_FESTERGUT_VA; 1310: HandleGameObject(PutricideGateGUIDs[1], !(PutricideEventProgress & PUTRICIDE_EVENT_FLAG_ROTFACE_VALV; 1375: SetBossState(DATA_BLOOD_PRINCE_TRASH, NOT_STARTED);; 1376: SetBossState(DATA_BLOOD_PRINCE_TRASH, DONE);; 1630: SetData(DATA_BUFF_AVAILABLE, IsBuffAvailable);; 1839: HandleGameObject(PutricideCollisionGUID, true);; 1845: HandleGameObject(PutricideGateGUIDs[0], false);; 1846: HandleGameObject(PutricidePipeGUIDs[0], true);; 1859: HandleGameObject(PutricideCollisionGUID, true);; 1865: HandleGameObject(PutricideGateGUIDs[1], false);; 1866: HandleGameObject(PutricidePipeGUIDs[1], true);

## Gates before complete engine coverage

1. Add measured GO/valve/transport and spell/phase hooks, preserving inferred-vs-observed labels and GO spawn identity.
2. Handle overlapping scripted encounters and preserve full journey data beyond the 256-event buffer.
3. Test fresh 10N/25N/10H/25H lockouts, wipes, re-entry, auto/manual sessions against in-game actions and server traces. Individual scenarios remain unverified until exercised.

## Full local spell, creature and object symbol index

This is a complete lexical list of distinct SPELL_, NPC_ and GO_ symbols referenced in the ICC .cpp files, with first line of occurrence. Declarations, comments, spells from other scripts, dynamically selected difficulty variants, and database rows require follow-up. A listed symbol does not prove a cast, spawn, kill or usable object.

### boss_blood_prince_council.cpp

SPELL (43):

- SPELL_AURA_PERIODIC_DUMMY (line 1471)
- SPELL_BALL_OF_FLAMES (line 91)
- SPELL_BALL_OF_FLAMES_PERIODIC (line 97)
- SPELL_BALL_OF_FLAMES_PROC (line 96)
- SPELL_BALL_OF_FLAMES_VISUAL (line 90)
- SPELL_BERSERK (line 415)
- SPELL_CLEAR_ALL_STATUS_AILMENTS (line 105)
- SPELL_CONJURE_EMPOWERED_FLAME (line 86)
- SPELL_CONJURE_FLAME (line 85)
- SPELL_DIRECT_DAMAGE (line 1215)
- SPELL_EFFECT_DUMMY (line 1534)
- SPELL_EFFECT_SCRIPT_EFFECT (line 1508)
- SPELL_EFFECT_SUMMON (line 1584)
- SPELL_EMPOWERED_SHADOW_LANCE (line 77)
- SPELL_EMPOWERED_SHOCK_VORTEX (line 103)
- SPELL_FEIGN_DEATH (line 62)
- SPELL_FLAMES (line 92)
- SPELL_FLAME_SPHERE_DEATH_EFFECT (line 93)
- SPELL_FLAME_SPHERE_SPAWN_EFFECT (line 89)
- SPELL_GLITTERING_SPARKS (line 84)
- SPELL_INVOCATION_OF_BLOOD_KELESETH (line 65)
- SPELL_INVOCATION_OF_BLOOD_TALDARAM (line 66)
- SPELL_INVOCATION_OF_BLOOD_VALANAR (line 67)
- SPELL_INVOCATION_VISUAL_ACTIVE (line 64)
- SPELL_KINETIC_BOMB (line 101)
- SPELL_KINETIC_BOMB_EXPLOSION (line 110)
- SPELL_KINETIC_BOMB_KNOCKBACK (line 111)
- SPELL_KINETIC_BOMB_TARGET (line 100)
- SPELL_KINETIC_BOMB_VISUAL (line 109)
- SPELL_MISS_NONE (line 1641)
- SPELL_OOC_INVOCATION_VISUAL (line 63)
- SPELL_REMOVE_EMPOWERED_BLOOD (line 104)
- SPELL_SHADOW_LANCE (line 76)
- SPELL_SHADOW_PRISON (line 70)
- SPELL_SHADOW_PRISON_DAMAGE (line 71)
- SPELL_SHADOW_PRISON_DUMMY (line 72)
- SPELL_SHADOW_RESONANCE (line 75)
- SPELL_SHADOW_RESONANCE_AURA (line 80)
- SPELL_SHADOW_RESONANCE_RESIST (line 81)
- SPELL_SHOCK_VORTEX (line 102)
- SPELL_SHOCK_VORTEX_DUMMY (line 115)
- SPELL_SHOCK_VORTEX_PERIODIC (line 114)
- SPELL_UNSTABLE (line 108)

NPC (5):

- NPC_BALL_OF_INFERNO_FLAME (line 598)
- NPC_FLOATING_TRIGGER (line 1124)
- NPC_KINETIC_BOMB (line 1603)
- NPC_KINETIC_BOMB_TARGET (line 895)
- NPC_SHOCK_VORTEX (line 899)

GO (0):

- None

### boss_blood_queen_lana_thel.cpp

SPELL (44):

- SPELL_ANNIHILATE (line 73)
- SPELL_AURA_DUMMY (line 791)
- SPELL_AURA_OVERRIDE_SPELLS (line 760)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 620)
- SPELL_BERSERK (line 347)
- SPELL_BLOODBOLT_WHIRL (line 72)
- SPELL_BLOOD_INFUSION_CREDIT (line 80)
- SPELL_BLOOD_MIRROR_DAMAGE (line 60)
- SPELL_BLOOD_MIRROR_DUMMY (line 62)
- SPELL_BLOOD_MIRROR_VISUAL (line 61)
- SPELL_CAST_OK (line 820)
- SPELL_CLEAR_ALL_STATUS_AILMENTS (line 74)
- SPELL_CUSTOM_ERROR_CANT_TARGET_VAMPIRES (line 815)
- SPELL_DELIRIOUS_SLASH (line 63)
- SPELL_EFFECT_FORCE_CAST (line 903)
- SPELL_EFFECT_SCRIPT_EFFECT (line 721)
- SPELL_EFFECT_TRIGGER_SPELL (line 868)
- SPELL_ESSENCE_OF_BLOOD_QUEEN (line 52)
- SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_HEAL (line 54)
- SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_PLR (line 53)
- SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW (line 812)
- SPELL_FAILED_CUSTOM_ERROR (line 816)
- SPELL_FRENZIED_BLOODTHIRST (line 55)
- SPELL_FRENZIED_BLOODTHIRST_VISUAL (line 49)
- SPELL_GUSHING_WOUND (line 81)
- SPELL_INCITE_TERROR (line 71)
- SPELL_MISS_NONE (line 827)
- SPELL_PACT_OF_THE_DARKFALLEN (line 65)
- SPELL_PACT_OF_THE_DARKFALLEN_DAMAGE (line 66)
- SPELL_PACT_OF_THE_DARKFALLEN_TARGET (line 64)
- SPELL_PRESENCE_OF_THE_DARKFALLEN_DUMMY (line 57)
- SPELL_PRESENCE_OF_THE_DARKFALLEN_EFFECT (line 58)
- SPELL_PRESENCE_OF_THE_DARKFALLEN_SE (line 59)
- SPELL_SHADOWS_FATE (line 241)
- SPELL_SHROUD_OF_SORROW (line 48)
- SPELL_SWARMING_SHADOWS (line 67)
- SPELL_THIRST_QUENCHED (line 82)
- SPELL_TWILIGHT_BLOODBOLT (line 69)
- SPELL_TWILIGHT_BLOODBOLT_FROM_WHIRL (line 70)
- SPELL_TWILIGHT_BLOODBOLT_TARGET (line 68)
- SPELL_UNCONTROLLABLE_FRENZY (line 56)
- SPELL_UNSATED_CRAVING (line 403)
- SPELL_VAMPIRIC_BITE (line 50)
- SPELL_VAMPIRIC_BITE_DUMMY (line 51)

NPC (3):

- NPC_BLOOD_QUEEN_LANA_THEL (line 699)
- NPC_BLOOD_QUICKENING_CREDIT_25 (line 252)
- NPC_INFILTRATOR_MINCHAR_BQ (line 252)

GO (0):

- None

### boss_deathbringer_saurfang.cpp

SPELL (27):

- SPELL_ACHIEVEMENT (line 118)
- SPELL_AURA_MOD_DAMAGE_PERCENT_DONE (line 1151)
- SPELL_AURA_MOD_SCALE (line 1150)
- SPELL_AURA_PERIODIC_DUMMY (line 1095)
- SPELL_AURA_PROC_TRIGGER_SPELL (line 1094)
- SPELL_BERSERK (line 267)
- SPELL_BLOOD_LINK (line 96)
- SPELL_BLOOD_LINK_BEAST (line 113)
- SPELL_BLOOD_LINK_DUMMY (line 107)
- SPELL_BLOOD_LINK_POWER (line 106)
- SPELL_BLOOD_NOVA (line 104)
- SPELL_BLOOD_NOVA_TRIGGER (line 103)
- SPELL_BLOOD_POWER (line 105)
- SPELL_BOILING_BLOOD (line 109)
- SPELL_EFFECT_DUMMY (line 1118)
- SPELL_FRENZY (line 102)
- SPELL_GRIP_OF_AGONY (line 95)
- SPELL_MARK_OF_THE_FALLEN_CHAMPION (line 108)
- SPELL_MARK_OF_THE_FALLEN_CHAMPION_S (line 97)
- SPELL_RESISTANT_SKIN (line 114)
- SPELL_RIDE_VEHICLE (line 117)
- SPELL_RUNE_OF_BLOOD (line 110)
- SPELL_RUNE_OF_BLOOD_S (line 98)
- SPELL_SCENT_OF_BLOOD (line 115)
- SPELL_SUMMON_BLOOD_BEAST (line 100)
- SPELL_SUMMON_BLOOD_BEAST_25_MAN (line 101)
- SPELL_ZERO_POWER (line 94)

NPC (2):

- NPC_SE_KOR_KRON_REAVER (line 554)
- NPC_SE_SKYBREAKER_MARINE (line 815)

GO (3):

- GO_FLAG_IN_USE (line 571)
- GO_SAURFANG_S_DOOR (line 380)
- GO_SCOURGE_TRANSPORTER_SAURFANG (line 568)

### boss_festergut.cpp

SPELL (16):

- SPELL_AURA_PERIODIC_DAMAGE (line 345)
- SPELL_BERSERK2 (line 193)
- SPELL_DECIMATE (line 59)
- SPELL_EFFECT_SCHOOL_DAMAGE (line 310)
- SPELL_EFFECT_SCRIPT_EFFECT (line 311)
- SPELL_GASTRIC_BLOAT (line 50)
- SPELL_GASTRIC_EXPLOSION (line 51)
- SPELL_GAS_SPORE (line 52)
- SPELL_INHALE_BLIGHT (line 48)
- SPELL_INOCULATED (line 54)
- SPELL_MALLABLE_GOO_H (line 55)
- SPELL_MORTAL_WOUND (line 58)
- SPELL_ORANGE_BLIGHT_RESIDUE (line 380)
- SPELL_PLAGUE_STENCH (line 60)
- SPELL_PUNGENT_BLIGHT (line 49)
- SPELL_VILE_GAS (line 53)

NPC (1):

- NPC_GAS_DUMMY (line 106)

GO (0):

- None

### boss_icecrown_gunship_battle.cpp

SPELL (52):

- SPELL_ACHIEVEMENT (line 119)
- SPELL_ADDS_BERSERK (line 165)
- SPELL_AURA_DUMMY (line 2047)
- SPELL_AURA_PERIODIC_DUMMY (line 2009)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 2165)
- SPELL_AWARD_REPUTATION_BOSS_KILL (line 120)
- SPELL_BATTLE_EXPERIENCE (line 161)
- SPELL_BATTLE_FURY (line 134)
- SPELL_BELOW_ZERO (line 147)
- SPELL_BLADESTORM (line 169)
- SPELL_BURNING_PITCH (line 127)
- SPELL_BURNING_PITCH_A (line 125)
- SPELL_BURNING_PITCH_DAMAGE_A (line 128)
- SPELL_BURNING_PITCH_DAMAGE_H (line 129)
- SPELL_BURNING_PITCH_H (line 126)
- SPELL_CHECK_FOR_PLAYERS (line 114)
- SPELL_CLEAVE (line 133)
- SPELL_CREATE_ROCKET_PACK (line 179)
- SPELL_DESPERATE_RESOLVE (line 171)
- SPELL_EFFECT_DUMMY (line 2111)
- SPELL_EFFECT_ENERGIZE (line 2323)
- SPELL_EFFECT_SCRIPT_EFFECT (line 2512)
- SPELL_EFFECT_TELEPORT_UNITS (line 2071)
- SPELL_EFFECT_TRIGGER_MISSILE (line 2390)
- SPELL_EJECT_ALL_PASSENGERS (line 187)
- SPELL_ELITE (line 164)
- SPELL_EXPERIENCED (line 162)
- SPELL_EXPLOSION_VICTORY (line 124)
- SPELL_EXPLOSION_WIPE (line 123)
- SPELL_FRIENDLY_BOSS_DAMAGE_MOD (line 113)
- SPELL_GUNSHIP_FALL_TELEPORT (line 115)
- SPELL_HURL_AXE (line 143)
- SPELL_LOCK_PLAYERS_AND_TAP_CHEST (line 174)
- SPELL_MISS_NONE (line 2548)
- SPELL_ON_ORGRIMS_HAMMER_DECK (line 176)
- SPELL_ON_SKYBREAKER_DECK (line 175)
- SPELL_OVERHEAT (line 186)
- SPELL_RENDING_THROW (line 156)
- SPELL_ROCKET_ARTILLERY_A (line 151)
- SPELL_ROCKET_ARTILLERY_H (line 152)
- SPELL_ROCKET_BURST (line 181)
- SPELL_ROCKET_PACK_DAMAGE (line 180)
- SPELL_ROCKET_PACK_USEABLE (line 182)
- SPELL_SHADOW_CHANNELING (line 138)
- SPELL_SHOOT (line 142)
- SPELL_TASTE_OF_BLOOD (line 157)
- SPELL_TELEPORT_PLAYERS_ON_RESET_A (line 116)
- SPELL_TELEPORT_PLAYERS_ON_RESET_H (line 117)
- SPELL_TELEPORT_PLAYERS_ON_VICTORY (line 118)
- SPELL_TELEPORT_TO_ENEMY_SHIP (line 160)
- SPELL_VETERAN (line 163)
- SPELL_WOUNDING_STRIKE (line 170)

NPC (20):

- NPC_ALLIANCE_GUNSHIP_CANNON (line 615)
- NPC_GUNSHIP_HULL (line 609)
- NPC_HORDE_GUNSHIP_CANNON (line 615)
- NPC_IGB_HIGH_OVERLORD_SAURFANG (line 579)
- NPC_IGB_MURADIN_BRONZEBEARD (line 579)
- NPC_KOR_KRON_AXETHROWER (line 345)
- NPC_KOR_KRON_BATTLE_MAGE (line 340)
- NPC_KOR_KRON_REAVER (line 361)
- NPC_KOR_KRON_ROCKETEER (line 355)
- NPC_KOR_KRON_SERGEANT (line 367)
- NPC_ORGRIMS_HAMMER (line 593)
- NPC_SKYBREAKER_DECKHAND (line 1481)
- NPC_SKYBREAKER_MARINE (line 327)
- NPC_SKYBREAKER_MORTAR_SOLDIER (line 321)
- NPC_SKYBREAKER_RIFLEMAN (line 311)
- NPC_SKYBREAKER_SERGEANT (line 333)
- NPC_SKYBREAKER_SORCERER (line 306)
- NPC_TELEPORT_EXIT (line 1011)
- NPC_TELEPORT_PORTAL (line 1002)
- NPC_THE_SKYBREAKER (line 2584)

GO (4):

- GO_ORGRIMS_HAMMER_A (line 572)
- GO_ORGRIMS_HAMMER_H (line 2423)
- GO_THE_SKYBREAKER_A (line 2423)
- GO_THE_SKYBREAKER_H (line 572)

### boss_lady_deathwhisper.cpp

SPELL (54):

- SPELL_ADHERENT_S_DETERMINATION (line 92)
- SPELL_AURA_MOD_TAUNT (line 260)
- SPELL_AURA_PERIODIC_DUMMY (line 1166)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 1140)
- SPELL_BERSERK (line 366)
- SPELL_BLADESTORM (line 103)
- SPELL_CHARGE (line 104)
- SPELL_CLEAR_ALL_DEBUFFS (line 113)
- SPELL_CURSE_OF_TORPOR (line 86)
- SPELL_DARK_EMPOWERMENT (line 93)
- SPELL_DARK_EMPOWERMENT_T (line 65)
- SPELL_DARK_MARTYRDOM_ADHERENT (line 88)
- SPELL_DARK_MARTYRDOM_ADHERENT_10H (line 90)
- SPELL_DARK_MARTYRDOM_ADHERENT_25H (line 91)
- SPELL_DARK_MARTYRDOM_ADHERENT_25N (line 89)
- SPELL_DARK_MARTYRDOM_FANATIC (line 75)
- SPELL_DARK_MARTYRDOM_FANATIC_10H (line 77)
- SPELL_DARK_MARTYRDOM_FANATIC_25H (line 78)
- SPELL_DARK_MARTYRDOM_FANATIC_25N (line 76)
- SPELL_DARK_MARTYRDOM_T (line 63)
- SPELL_DARK_TRANSFORMATION (line 80)
- SPELL_DARK_TRANSFORMATION_T (line 64)
- SPELL_DEATHCHILL_BLAST (line 85)
- SPELL_DEATHCHILL_BOLT (line 84)
- SPELL_DEATH_AND_DECAY (line 60)
- SPELL_DOMINATE_MIND_25 (line 61)
- SPELL_EFFECT_ATTACK_ME (line 261)
- SPELL_FANATIC_S_DETERMINATION (line 79)
- SPELL_FROSTBOLT (line 66)
- SPELL_FROSTBOLT_VOLLEY (line 67)
- SPELL_FROST_FEVER (line 83)
- SPELL_FULL_HEAL (line 114)
- SPELL_FULL_HOUSE (line 111)
- SPELL_INTIMIDATING_SHOUT (line 105)
- SPELL_MANA_BARRIER (line 59)
- SPELL_MORTAL_STRIKE (line 106)
- SPELL_NECROTIC_STRIKE (line 72)
- SPELL_PERMANENT_FEIGN_DEATH (line 115)
- SPELL_SCHOOL_MASK_NORMAL (line 1069)
- SPELL_SHADOW_BOLT (line 62)
- SPELL_SHADOW_CHANNELING (line 58)
- SPELL_SHADOW_CLEAVE (line 73)
- SPELL_SHATTERING_THROW (line 107)
- SPELL_SHORUD_OF_THE_OCCULT (line 87)
- SPELL_SUMMON_SHADE (line 69)
- SPELL_SUNDER_ARMOR (line 108)
- SPELL_TELEPORT_VISUAL (line 112)
- SPELL_TOUCH_OF_INSIGNIFICANCE (line 68)
- SPELL_VAMPIRIC_MIGHT (line 74)
- SPELL_VENGEFUL_BLAST_10H (line 99)
- SPELL_VENGEFUL_BLAST_10N (line 97)
- SPELL_VENGEFUL_BLAST_25H (line 100)
- SPELL_VENGEFUL_BLAST_25N (line 98)
- SPELL_VENGEFUL_BLAST_PASSIVE (line 96)

NPC (13):

- NPC_CULT_ADHERENT (line 199)
- NPC_CULT_FANATIC (line 199)
- NPC_DARNAVAN (line 195)
- NPC_DARNAVAN_10 (line 181)
- NPC_DARNAVAN_25 (line 182)
- NPC_DARNAVAN_CREDIT (line 196)
- NPC_DARNAVAN_CREDIT_10 (line 183)
- NPC_DARNAVAN_CREDIT_25 (line 184)
- NPC_DEFORMED_FANATIC (line 695)
- NPC_EMPOWERED_ADHERENT (line 808)
- NPC_REANIMATED_ADHERENT (line 872)
- NPC_REANIMATED_FANATIC (line 751)
- NPC_VENGEFUL_SHADE (line 473)

GO (0):

- None

### boss_lord_marrowgar.cpp

SPELL (13):

- SPELL_AURA_CONTROL_VEHICLE (line 396)
- SPELL_BERSERK (line 251)
- SPELL_BONE_SLICE (line 45)
- SPELL_BONE_SPIKE_GRAVEYARD (line 47)
- SPELL_BONE_STORM (line 46)
- SPELL_COLDFLAME_BONE_STORM (line 49)
- SPELL_COLDFLAME_NORMAL (line 48)
- SPELL_COLDFLAME_PASSIVE (line 56)
- SPELL_COLDFLAME_SUMMON (line 57)
- SPELL_EFFECT_APPLY_AURA (line 575)
- SPELL_EFFECT_SCRIPT_EFFECT (line 524)
- SPELL_IMPALED (line 52)
- SPELL_RIDE_VEHICLE (line 53)

NPC (1):

- NPC_BONE_SPIKE (line 423)

GO (0):

- None

### boss_professor_putricide.cpp

SPELL (62):

- SPELL_ABOMINATION_VEHICLE_POWER_DRAIN (line 107)
- SPELL_AURA_DUMMY (line 1399)
- SPELL_AURA_PERIODIC_DAMAGE (line 1072)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 987)
- SPELL_AURA_PROC_TRIGGER_SPELL (line 1588)
- SPELL_BERSERK2 (line 543)
- SPELL_CAST_OK (line 1356)
- SPELL_CHOKING_GAS_BOMB (line 75)
- SPELL_CHOKING_GAS_BOMB_PERIODIC (line 103)
- SPELL_CHOKING_GAS_EXPLOSION_TRIGGER (line 104)
- SPELL_CREATE_CONCOCTION (line 72)
- SPELL_CUSTOM_ERROR_ALL_POTIONS_USED (line 1346)
- SPELL_CUSTOM_ERROR_NONE (line 1367)
- SPELL_CUSTOM_ERROR_TOO_MANY_ABOMINATIONS (line 1352)
- SPELL_EFFECT_APPLY_AURA (line 945)
- SPELL_EFFECT_DUMMY (line 1163)
- SPELL_EFFECT_SCRIPT_EFFECT (line 1028)
- SPELL_EFFECT_SUMMON (line 1469)
- SPELL_EXPUNGED_GAS (line 94)
- SPELL_FAILED_BAD_TARGETS (line 1362)
- SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW (line 1338)
- SPELL_FAILED_CUSTOM_ERROR (line 1347)
- SPELL_FAILED_NO_VALID_TARGETS (line 1101)
- SPELL_FAILED_TARGET_NOT_PLAYER (line 1365)
- SPELL_GASEOUS_BLIGHT_LARGE (line 57)
- SPELL_GASEOUS_BLIGHT_MEDIUM (line 58)
- SPELL_GASEOUS_BLIGHT_SMALL (line 59)
- SPELL_GASEOUS_BLOAT (line 92)
- SPELL_GASEOUS_BLOAT_PROC (line 91)
- SPELL_GASEOUS_BLOAT_PROTECTION (line 93)
- SPELL_GAS_VARIABLE (line 77)
- SPELL_GROW (line 87)
- SPELL_GROW_STACKER (line 86)
- SPELL_GUZZLE_POTIONS (line 73)
- SPELL_MALLEABLE_GOO (line 66)
- SPELL_MALLEABLE_GOO_BALCONY (line 65)
- SPELL_MUTATED_PLAGUE (line 82)
- SPELL_MUTATED_PLAGUE_CLEAR (line 83)
- SPELL_MUTATED_TRANSFORMATION (line 108)
- SPELL_MUTATED_TRANSFORMATION_DAMAGE (line 109)
- SPELL_MUTATED_TRANSFORMATION_NAME (line 110)
- SPELL_OOZE_ERUPTION (line 97)
- SPELL_OOZE_ERUPTION_SEARCH_PERIODIC (line 99)
- SPELL_OOZE_TANK_PROTECTION (line 74)
- SPELL_OOZE_VARIABLE (line 76)
- SPELL_PLAGUE_SICKNESS (line 80)
- SPELL_RELEASE_GAS_VISUAL (line 56)
- SPELL_SHADOWS_FATE (line 347)
- SPELL_SLIME_PUDDLE_AURA (line 88)
- SPELL_SLIME_PUDDLE_TRIGGER (line 64)
- SPELL_TEAR_GAS (line 68)
- SPELL_TEAR_GAS_CANCEL (line 70)
- SPELL_TEAR_GAS_CREATURE (line 69)
- SPELL_TEAR_GAS_PERIODIC_TRIGGER (line 71)
- SPELL_UNBOUND_PLAGUE (line 78)
- SPELL_UNBOUND_PLAGUE_PROTECTION (line 81)
- SPELL_UNBOUND_PLAGUE_SEARCHER (line 79)
- SPELL_UNHOLY_INFUSION (line 113)
- SPELL_UNHOLY_INFUSION_CREDIT (line 114)
- SPELL_UNSTABLE_EXPERIMENT (line 67)
- SPELL_VOLATILE_OOZE_ADHESIVE (line 98)
- SPELL_VOLATILE_OOZE_PROTECTION (line 100)

NPC (8):

- NPC_ABOMINATION_WING_MAD_SCIENTIST_STALKER (line 1008)
- NPC_CHOKING_GAS_BOMB (line 382)
- NPC_GAS_CLOUD (line 370)
- NPC_GROWING_OOZE_PUDDLE (line 365)
- NPC_MUTATED_ABOMINATION_10 (line 163)
- NPC_MUTATED_ABOMINATION_25 (line 163)
- NPC_TEAR_GAS_TARGET_STALKER (line 590)
- NPC_VOLATILE_OOZE (line 376)

GO (0):

- None

### boss_rotface.cpp

SPELL (25):

- SPELL_AURA_PERIODIC_DAMAGE (line 569)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 804)
- SPELL_AWAKEN_PLAGUED_ZOMBIES (line 72)
- SPELL_DECIMATE (line 71)
- SPELL_EFFECT_FORCE_CAST (line 755)
- SPELL_EFFECT_SCRIPT_EFFECT (line 599)
- SPELL_EFFECT_TRIGGER_MISSILE (line 781)
- SPELL_GREEN_ABOMINATION_HITTIN__YA_PROC (line 64)
- SPELL_GREEN_BLIGHT_RESIDUE (line 243)
- SPELL_LARGE_OOZE_BUFF_COMBINE (line 59)
- SPELL_LARGE_OOZE_COMBINE (line 58)
- SPELL_LITTLE_OOZE_COMBINE (line 57)
- SPELL_MORTAL_WOUND (line 70)
- SPELL_MUTATED_INFECTION (line 48)
- SPELL_OOZE_FLOOD_PERIODIC (line 54)
- SPELL_OOZE_FLOOD_VISUAL (line 53)
- SPELL_OOZE_MERGE (line 60)
- SPELL_RADIATING_OOZE (line 62)
- SPELL_SLIME_SPRAY (line 47)
- SPELL_STICKY_OOZE (line 66)
- SPELL_UNSTABLE_OOZE (line 63)
- SPELL_UNSTABLE_OOZE_EXPLOSION (line 65)
- SPELL_UNSTABLE_OOZE_EXPLOSION_TRIGGER (line 67)
- SPELL_VILE_GAS_H (line 50)
- SPELL_WEAK_RADIATING_OOZE (line 61)

NPC (3):

- NPC_OOZE_SPRAY_STALKER (line 277)
- NPC_PUDDLE_STALKER (line 179)
- NPC_UNSTABLE_EXPLOSION_STALKER (line 749)

GO (0):

- None

### boss_sindragosa.cpp

SPELL (53):

- SPELL_ASPHYXIATION (line 72)
- SPELL_AURA_DUMMY (line 920)
- SPELL_AURA_HASTE_SPELLS (line 282)
- SPELL_AURA_MOD_STUN (line 1094)
- SPELL_AURA_PERIODIC_DUMMY (line 1163)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 996)
- SPELL_BACKLASH (line 63)
- SPELL_BELLOWING_ROAR (line 80)
- SPELL_BERSERK (line 515)
- SPELL_BIRTH_NO_VISUAL (line 75)
- SPELL_BLISTERING_COLD (line 66)
- SPELL_CLEAVE (line 57)
- SPELL_CLEAVE_SPINESTALKER (line 81)
- SPELL_CONCUSSIVE_SHOCK (line 93)
- SPELL_EFFECT_DUMMY (line 828)
- SPELL_EFFECT_FORCE_CAST (line 1724)
- SPELL_EFFECT_JUMP (line 974)
- SPELL_EFFECT_SCRIPT_EFFECT (line 944)
- SPELL_EFFECT_TRIGGER_MISSILE (line 1515)
- SPELL_FOCUS_FIRE (line 91)
- SPELL_FROST_AURA (line 55)
- SPELL_FROST_AURA_RIMEFANG (line 86)
- SPELL_FROST_BEACON (line 67)
- SPELL_FROST_BOMB (line 76)
- SPELL_FROST_BOMB_TRIGGER (line 73)
- SPELL_FROST_BOMB_VISUAL (line 74)
- SPELL_FROST_BREATH (line 85)
- SPELL_FROST_BREATH_P1 (line 59)
- SPELL_FROST_BREATH_P2 (line 60)
- SPELL_FROST_IMBUED_BLADE (line 100)
- SPELL_FROST_INFUSION (line 101)
- SPELL_FROST_INFUSION_CREDIT (line 99)
- SPELL_ICE_TOMB_DAMAGE (line 71)
- SPELL_ICE_TOMB_DUMMY (line 69)
- SPELL_ICE_TOMB_TARGET (line 68)
- SPELL_ICE_TOMB_UNTARGETABLE (line 70)
- SPELL_ICY_BLAST (line 87)
- SPELL_ICY_BLAST_AREA (line 88)
- SPELL_ICY_GRIP (line 64)
- SPELL_ICY_GRIP_JUMP (line 65)
- SPELL_INSTABILITY (line 62)
- SPELL_MYSTIC_BUFFET (line 77)
- SPELL_ORDER_WHELP (line 92)
- SPELL_PERMAEATING_CHILL (line 56)
- SPELL_SCHOOL_MASK_ALL (line 263)
- SPELL_SHADOWS_FATE (line 309)
- SPELL_SINDRAGOSA_S_FURY (line 52)
- SPELL_TAIL_SMASH (line 58)
- SPELL_TAIL_SWEEP (line 82)
- SPELL_TANK_MARKER (line 53)
- SPELL_TANK_MARKER_AURA (line 54)
- SPELL_UNCHAINED_MAGIC (line 61)
- SPELL_UNSATED_CRAVING (line 1772)

NPC (7):

- NPC_CROK_SCOURGEBANE (line 355)
- NPC_FROSTWARDEN_HANDLER (line 1576)
- NPC_FROSTWING_WHELP (line 1566)
- NPC_FROST_BOMB (line 480)
- NPC_ICE_TOMB (line 226)
- NPC_ICY_BLAST (line 1509)
- NPC_SINDRAGOSA (line 894)

GO (1):

- GO_ICE_BLOCK (line 230)

### boss_the_lich_king.cpp

SPELL (106):

- SPELL_AURA_DUMMY (line 2054)
- SPELL_AURA_MOD_DAMAGE_PERCENT_DONE (line 3212)
- SPELL_AURA_MOD_TAUNT (line 2401)
- SPELL_AURA_PERIODIC_DAMAGE (line 1861)
- SPELL_AURA_PERIODIC_DUMMY (line 2794)
- SPELL_AURA_PERIODIC_HEAL (line 3211)
- SPELL_BERSERK2 (line 996)
- SPELL_BOSS_HITTIN_YA (line 85)
- SPELL_BOSS_HITTIN_YA_AURA (line 86)
- SPELL_BROKEN_FROSTMOURNE (line 102)
- SPELL_BROKEN_FROSTMOURNE_KNOCK (line 103)
- SPELL_CHARGE (line 148)
- SPELL_DARK_HUNGER (line 176)
- SPELL_DARK_HUNGER_HEAL (line 177)
- SPELL_DEFILE (line 138)
- SPELL_DEFILE_AURA (line 139)
- SPELL_DEFILE_GROW (line 140)
- SPELL_DESTROY_SOUL (line 175)
- SPELL_EFFECT_ATTACK_ME (line 2402)
- SPELL_EFFECT_DUMMY (line 2813)
- SPELL_EFFECT_SCRIPT_EFFECT (line 1721)
- SPELL_EFFECT_SEND_EVENT (line 1696)
- SPELL_EFFECT_SUMMON (line 2651)
- SPELL_EFFECT_TELEPORT_UNITS (line 2671)
- SPELL_EJECT_ALL_PASSENGERS (line 150)
- SPELL_EMOTE_QUESTION_NO_SHEATH (line 93)
- SPELL_EMOTE_SHOUT_NO_SHEATH (line 87)
- SPELL_EMOTE_SIT_NO_SHEATH (line 84)
- SPELL_ENRAGE (line 187)
- SPELL_EXPLOSION (line 183)
- SPELL_FRENZY (line 188)
- SPELL_FURY_OF_FROSTMOURNE (line 91)
- SPELL_FURY_OF_FROSTMOURNE_NO_REZ (line 92)
- SPELL_HARVESTED_SOUL_LK_BUFF (line 165)
- SPELL_HARVEST_SOUL (line 159)
- SPELL_HARVEST_SOULS (line 166)
- SPELL_HARVEST_SOULS_TELEPORT (line 167)
- SPELL_HARVEST_SOUL_TELEPORT (line 162)
- SPELL_HARVEST_SOUL_TELEPORT_BACK (line 163)
- SPELL_HARVEST_SOUL_VALKYR (line 147)
- SPELL_HARVEST_SOUL_VEHICLE (line 160)
- SPELL_HARVEST_SOUL_VISUAL (line 161)
- SPELL_ICE_BURST (line 119)
- SPELL_ICE_BURST_TARGET_SEARCH (line 117)
- SPELL_ICE_LOCK (line 88)
- SPELL_ICE_PULSE (line 118)
- SPELL_ICE_SPHERE (line 116)
- SPELL_INFEST (line 129)
- SPELL_IN_FROSTMOURNE_ROOM (line 168)
- SPELL_JUMP (line 96)
- SPELL_JUMP_2 (line 98)
- SPELL_JUMP_TRIGGERED (line 97)
- SPELL_KILL_FROSTMOURNE_PLAYERS (line 164)
- SPELL_LIFE_SIPHON (line 151)
- SPELL_LIFE_SIPHON_HEAL (line 152)
- SPELL_LIGHTS_BLESSING (line 95)
- SPELL_LIGHTS_FAVOR (line 171)
- SPELL_MASS_RESURRECTION (line 106)
- SPELL_MASS_RESURRECTION_REAL (line 107)
- SPELL_MISS_NONE (line 1926)
- SPELL_NECROTIC_PLAGUE (line 130)
- SPELL_NECROTIC_PLAGUE_JUMP (line 131)
- SPELL_PAIN_AND_SUFFERING (line 114)
- SPELL_PLAGUE_AVOIDANCE (line 83)
- SPELL_PLAGUE_SIPHON (line 132)
- SPELL_PLAY_MOVIE (line 108)
- SPELL_QUAKE (line 113)
- SPELL_RAGING_SPIRIT (line 120)
- SPELL_RAGING_SPIRIT_VISUAL (line 121)
- SPELL_RAGING_SPIRIT_VISUAL_CLONE (line 122)
- SPELL_RAISE_DEAD (line 94)
- SPELL_REMORSELESS_WINTER_1 (line 111)
- SPELL_REMORSELESS_WINTER_2 (line 112)
- SPELL_RESTORE_SOUL (line 172)
- SPELL_RESTORE_SOULS (line 173)
- SPELL_RISEN_WITCH_DOCTOR_SPAWN (line 126)
- SPELL_SHADOW_TRAP (line 133)
- SPELL_SHADOW_TRAP_AURA (line 134)
- SPELL_SHADOW_TRAP_KNOCKBACK (line 135)
- SPELL_SHOCKWAVE (line 186)
- SPELL_SOUL_BARRAGE (line 104)
- SPELL_SOUL_REAPER (line 141)
- SPELL_SOUL_REAPER_BUFF (line 142)
- SPELL_SOUL_RIP (line 178)
- SPELL_SOUL_RIP_DAMAGE (line 179)
- SPELL_SOUL_SHRIEK (line 123)
- SPELL_SPIRIT_BURST (line 158)
- SPELL_SUMMON_BROKEN_FROSTMOURNE (line 99)
- SPELL_SUMMON_BROKEN_FROSTMOURNE_2 (line 100)
- SPELL_SUMMON_BROKEN_FROSTMOURNE_3 (line 101)
- SPELL_SUMMON_DRUDGE_GHOULS (line 128)
- SPELL_SUMMON_ICE_SPHERE (line 115)
- SPELL_SUMMON_SHAMBLING_HORROR (line 127)
- SPELL_SUMMON_SPIRIT_BOMB_1 (line 180)
- SPELL_SUMMON_SPIRIT_BOMB_2 (line 181)
- SPELL_SUMMON_TERENAS (line 105)
- SPELL_SUMMON_VALKYR (line 143)
- SPELL_SUMMON_VALKYR_PERIODIC (line 144)
- SPELL_TERENAS_LOSES_INSIDE (line 174)
- SPELL_TRIGGER_VILE_SPIRIT_HEROIC (line 182)
- SPELL_VALKYR_CARRY (line 149)
- SPELL_VALKYR_TARGET_SEARCH (line 146)
- SPELL_VILE_SPIRITS (line 155)
- SPELL_VILE_SPIRIT_DAMAGE_SEARCH (line 157)
- SPELL_VILE_SPIRIT_MOVE_SEARCH (line 156)
- SPELL_WINGS_OF_THE_DAMNED (line 145)

NPC (19):

- NPC_DEFILE (line 873)
- NPC_DRUDGE_GHOUL (line 852)
- NPC_FROSTMOURNE_TRIGGER (line 820)
- NPC_HIGHLORD_TIRION_FORDRING_LK (line 676)
- NPC_ICE_SPHERE (line 896)
- NPC_RAGING_SPIRIT (line 859)
- NPC_SHADOW_TRAP_TRIGGER (line 874)
- NPC_SHAMBLING_HORROR (line 851)
- NPC_SPIRIT_BOMB (line 2633)
- NPC_SPIRIT_WARDEN (line 3112)
- NPC_STRANGULATE_VEHICLE (line 748)
- NPC_TERENAS_MENETHIL_FROSTMOURNE_H (line 1201)
- NPC_TERENAS_MENETHIL_OUTRO (line 822)
- NPC_THE_LICH_KING (line 1658)
- NPC_VALKYR_SHADOWGUARD (line 879)
- NPC_VILE_SPIRIT (line 862)
- NPC_WICKED_SPIRIT (line 3245)
- NPC_WORLD_TRIGGER (line 2470)
- NPC_WORLD_TRIGGER_INFINITE_AOI (line 1204)

GO (11):

- GO_ARTHAS_PLATFORM (line 467)
- GO_DESTRUCTIBLE_INTACT (line 468)
- GO_DOODAD_ICECROWN_SNOWEDGEWARNING01 (line 476)
- GO_DOODAD_ICECROWN_THRONEFROSTYEDGE01 (line 473)
- GO_DOODAD_ICECROWN_THRONEFROSTYWIND01 (line 470)
- GO_DOODAD_ICESHARD_STANDING01 (line 480)
- GO_DOODAD_ICESHARD_STANDING02 (line 479)
- GO_DOODAD_ICESHARD_STANDING03 (line 481)
- GO_DOODAD_ICESHARD_STANDING04 (line 482)
- GO_STATE_ACTIVE (line 471)
- GO_STATE_READY (line 474)

### boss_valithria_dreamwalker.cpp

SPELL (42):

- SPELL_ACHIEVEMENT_CHECK (line 61)
- SPELL_ACID_BURST (line 91)
- SPELL_AURA_MOD_HEALING_PCT (line 1369)
- SPELL_AURA_OBS_MOD_HEALTH (line 297)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 1162)
- SPELL_AWARD_REPUTATION_BOSS_KILL (line 63)
- SPELL_CLEAR_ALL (line 62)
- SPELL_COLUMN_OF_FROST (line 80)
- SPELL_COLUMN_OF_FROST_DAMAGE (line 81)
- SPELL_COPY_DAMAGE (line 50)
- SPELL_CORRUPTION (line 77)
- SPELL_CORRUPTION_VALITHRIA (line 64)
- SPELL_DREAMWALKERS_RAGE (line 59)
- SPELL_DREAM_PORTAL_VISUAL_PRE (line 51)
- SPELL_DREAM_SLIP (line 60)
- SPELL_EFFECT_FORCE_CAST (line 1140)
- SPELL_EFFECT_HEAL_PCT (line 298)
- SPELL_EFFECT_SCRIPT_EFFECT (line 1120)
- SPELL_EMERALD_VIGOR (line 98)
- SPELL_FIREBALL (line 84)
- SPELL_FROSTBOLT_VOLLEY (line 78)
- SPELL_GUT_SPRAY (line 94)
- SPELL_LEY_WASTE (line 85)
- SPELL_MANA_VOID (line 79)
- SPELL_NIGHTMARE_CLOUD (line 53)
- SPELL_NIGHTMARE_CLOUD_VISUAL (line 54)
- SPELL_NIGHTMARE_PORTAL_VISUAL_PRE (line 52)
- SPELL_PRE_SUMMON_DREAM_PORTAL (line 55)
- SPELL_PRE_SUMMON_NIGHTMARE_PORTAL (line 56)
- SPELL_RECENTLY_SPAWNED (line 73)
- SPELL_ROT_WORM_SPAWNER (line 95)
- SPELL_SPAWN_CHEST (line 74)
- SPELL_SUMMON_DREAM_PORTAL (line 57)
- SPELL_SUMMON_NIGHTMARE_PORTAL (line 58)
- SPELL_SUMMON_SUPPRESSER (line 72)
- SPELL_SUPPRESSION (line 88)
- SPELL_TIMER_BLAZING_SKELETON (line 71)
- SPELL_TIMER_BLISTERING_ZOMBIE (line 69)
- SPELL_TIMER_GLUTTONOUS_ABOMINATION (line 67)
- SPELL_TIMER_RISEN_ARCHMAGE (line 70)
- SPELL_TIMER_SUPPRESSER (line 68)
- SPELL_TWISTED_NIGHTMARE (line 101)

NPC (15):

- NPC_BLAZING_SKELETON (line 239)
- NPC_BLISTERING_ZOMBIE (line 241)
- NPC_COLUMN_OF_FROST (line 244)
- NPC_DREAM_PORTAL (line 415)
- NPC_DREAM_PORTAL_PRE_EFFECT (line 401)
- NPC_GLUTTONOUS_ABOMINATION (line 242)
- NPC_MANA_VOID (line 243)
- NPC_NIGHTMARE_PORTAL (line 415)
- NPC_NIGHTMARE_PORTAL_PRE_EFFECT (line 406)
- NPC_RISEN_ARCHMAGE (line 248)
- NPC_ROT_WORM (line 245)
- NPC_SUPPRESSER (line 240)
- NPC_THE_LICH_KING_VALITHRIA (line 235)
- NPC_VALITHRIA_DREAMWALKER (line 231)
- NPC_WORLD_TRIGGER (line 1277)

GO (0):

- None

### icecrown_citadel.cpp

SPELL (93):

- SPELL_AETHER_SHIELD (line 131)
- SPELL_AMPLIFY_MAGIC (line 189)
- SPELL_ARCTIC_BREATH (line 111)
- SPELL_AURA_DUMMY (line 2688)
- SPELL_AURA_MOD_DAMAGE_PERCENT_DONE (line 2533)
- SPELL_AURA_MOD_ROOT (line 2581)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL (line 3103)
- SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE (line 3131)
- SPELL_BLAST_WAVE (line 190)
- SPELL_BLIZZARD (line 3668)
- SPELL_BLOOD_MIRROR (line 178)
- SPELL_BLOOD_MIRROR_2 (line 179)
- SPELL_BLOOD_MIRROR_DAMAGE_SHARE (line 180)
- SPELL_BLOOD_ORB_VISUAL (line 173)
- SPELL_BLOOD_SAP (line 204)
- SPELL_CARESS_OF_DEATH (line 126)
- SPELL_CHAINS_OF_SHADOW (line 185)
- SPELL_CHARGE (line 150)
- SPELL_CLEAVE (line 3669)
- SPELL_COLDFLAME_JETS (line 114)
- SPELL_CONFLAGRATION (line 153)
- SPELL_CRUSADER_STRIKE (line 144)
- SPELL_DEATH_PLAGUE (line 106)
- SPELL_DEATH_PLAGUE_AURA (line 107)
- SPELL_DEATH_PLAGUE_KILL (line 109)
- SPELL_DEATH_STRIKE (line 123)
- SPELL_DISEASE_CLOUD (line 199)
- SPELL_DIVINE_SHIELD (line 145)
- SPELL_DOMINATE_MIND (line 135)
- SPELL_EFFECT_DUMMY (line 2631)
- SPELL_EFFECT_QUEST_COMPLETE (line 2860)
- SPELL_EFFECT_SCHOOL_DAMAGE (line 2838)
- SPELL_EFFECT_SCRIPT_EFFECT (line 2656)
- SPELL_EFFECT_SEND_EVENT (line 2746)
- SPELL_EMPOWERED_BLOOD (line 2470)
- SPELL_EMPOWERED_BLOOD_2 (line 167)
- SPELL_EMPOWERED_BLOOD_3 (line 168)
- SPELL_EMPOWERED_BLOOD_4 (line 169)
- SPELL_FEL_IRON_BOMB (line 214)
- SPELL_FEL_IRON_BOMB_NORMAL (line 156)
- SPELL_FEL_IRON_BOMB_UNDEAD (line 159)
- SPELL_FIREBALL (line 188)
- SPELL_FLASH_HEAL (line 209)
- SPELL_FLASH_HEAL_NORMAL (line 136)
- SPELL_FLASH_HEAL_UNDEAD (line 139)
- SPELL_FROSTBREATH (line 3670)
- SPELL_GIANT_INSECT_SWARM (line 4267)
- SPELL_GREEN_BLIGHT_RESIDUE (line 1941)
- SPELL_HAMMER_OF_BETRAYAL (line 147)
- SPELL_HARVEST_BLIGHT_SPECIMEN (line 117)
- SPELL_HARVEST_BLIGHT_SPECIMEN25 (line 118)
- SPELL_HURL_SPEAR (line 132)
- SPELL_ICEBOUND_ARMOR (line 121)
- SPELL_IMPALING_SPEAR (line 130)
- SPELL_IMPALING_SPEAR_KILL (line 127)
- SPELL_JUDGEMENT_OF_COMMAND (line 146)
- SPELL_LEAP_TO_A_RANDOM_LOCATION (line 4291)
- SPELL_LEECHING_ROOT (line 200)
- SPELL_LICH_SLAP (line 195)
- SPELL_MACHINE_GUN (line 215)
- SPELL_MACHINE_GUN_NORMAL (line 157)
- SPELL_MACHINE_GUN_UNDEAD (line 160)
- SPELL_MORTAL_STRIKE (line 151)
- SPELL_ORANGE_BLIGHT_RESIDUE (line 1941)
- SPELL_ORB_CONTROLLER_ACTIVE (line 170)
- SPELL_POLYMORPH (line 192)
- SPELL_POLYMORPH_ALLY (line 191)
- SPELL_POWER_WORD_SHIELD (line 210)
- SPELL_POWER_WORD_SHIELD_NORMAL (line 137)
- SPELL_POWER_WORD_SHIELD_UNDEAD (line 140)
- SPELL_RECENTLY_INFECTED (line 108)
- SPELL_REVIVE_CHAMPION (line 128)
- SPELL_ROCKET_LAUNCH (line 216)
- SPELL_ROCKET_LAUNCH_NORMAL (line 158)
- SPELL_ROCKET_LAUNCH_UNDEAD (line 161)
- SPELL_SCOURGE_STRIKE (line 122)
- SPELL_SHADOWSTEP (line 203)
- SPELL_SHADOW_BOLT (line 184)
- SPELL_SHROUD_OF_SPELL_WARDING (line 196)
- SPELL_SIPHON_ESSENCE (line 174)
- SPELL_SMITE (line 211)
- SPELL_SMITE_NORMAL (line 138)
- SPELL_SMITE_UNDEAD (line 141)
- SPELL_SOUL_MISSILE (line 164)
- SPELL_SPIRIT_STREAM (line 1675)
- SPELL_STOMP (line 110)
- SPELL_STONEFORM (line 2699)
- SPELL_SUNDER_ARMOR (line 152)
- SPELL_UNDEATH (line 129)
- SPELL_UNHOLY_STRIKE (line 181)
- SPELL_VAMPIRIC_AURA (line 177)
- SPELL_WEB_BEAM (line 3989)
- SPELL_WEB_BEAM2 (line 4095)

NPC (45):

- NPC_ALLIANCE_COMMANDER (line 599)
- NPC_CAPTAIN_ARNATH (line 387)
- NPC_CAPTAIN_ARNATH_UNDEAD (line 1359)
- NPC_CAPTAIN_BRANDON (line 388)
- NPC_CAPTAIN_BRANDON_UNDEAD (line 1362)
- NPC_CAPTAIN_GRONDEL (line 389)
- NPC_CAPTAIN_GRONDEL_UNDEAD (line 1365)
- NPC_CAPTAIN_RUPERT (line 390)
- NPC_CAPTAIN_RUPERT_UNDEAD (line 1368)
- NPC_CROK_SCOURGEBANE (line 386)
- NPC_DARKFALLEN_ADVISOR (line 2025)
- NPC_DARKFALLEN_ARCHMAGE (line 2024)
- NPC_DARKFALLEN_BLOOD_KNIGHT (line 2022)
- NPC_DARKFALLEN_NOBLE (line 2023)
- NPC_DARKFALLEN_TACTICIAN (line 2026)
- NPC_DEATHBOUND_WARD (line 2730)
- NPC_FLASH_EATING_INSECT (line 4325)
- NPC_FROSTWARDEN_SORCERESS (line 4104)
- NPC_FROSTWARDEN_WARRIOR (line 4104)
- NPC_FROST_FREEZE_TRAP (line 2971)
- NPC_GARROSH_HELLSCREAM (line 3928)
- NPC_HIGHLORD_BOLVAR_FORDRAGON_LH (line 462)
- NPC_HIGH_OVERLORD_SAURFANG_DUMMY (line 464)
- NPC_IMPALING_SPEAR (line 1213)
- NPC_INVISIBLE_STALKER (line 4322)
- NPC_INVISIBLE_STALKER_3_0 (line 1677)
- NPC_KING_VARIAN_WRYNN (line 3928)
- NPC_KOR_KRON_GENERAL (line 599)
- NPC_MURADIN_BRONZEBEARD_DUMMY (line 464)
- NPC_NERUBAR_BROODLING (line 4093)
- NPC_NERUBAR_CHAMPION (line 4111)
- NPC_NERUBAR_WEBWEAVER (line 4112)
- NPC_ORB_VISUAL_STALKER (line 2462)
- NPC_PUTRICADES_TRAP (line 4367)
- NPC_SINDRAGOSA_GAUNTLET (line 4352)
- NPC_SISTER_SVALNA (line 393)
- NPC_SPIRE_FROSTWYRM (line 4388)
- NPC_THE_LICH_KING_LH (line 460)
- NPC_VAMPIRIC_FIEND (line 2331)
- NPC_VENGEFUL_FLESHREAPER (line 2760)
- NPC_YMIRJAR_BATTLE_MAIDEN (line 352)
- NPC_YMIRJAR_DEATHBRINGER (line 353)
- NPC_YMIRJAR_FROSTBINDER (line 354)
- NPC_YMIRJAR_HUNTRESS (line 355)
- NPC_YMIRJAR_WARLORD (line 356)

GO (8):

- GO_EMPOWERING_BLOOD_ORB (line 2116)
- GO_FLAG_IN_USE (line 2477)
- GO_FLAG_NOT_SELECTABLE (line 2162)
- GO_SPIRIT_ALARM_1 (line 2709)
- GO_SPIRIT_ALARM_2 (line 2712)
- GO_SPIRIT_ALARM_3 (line 2715)
- GO_SPIRIT_ALARM_4 (line 2718)
- GO_STATE_ACTIVE_ALTERNATIVE (line 2479)

### icecrown_citadel_teleport.cpp

SPELL (1):

- SPELL_FAILED_AFFECTING_COMBAT (line 97)

NPC (0):

- None

GO (1):

- GO_SCOURGE_TRANSPORTER_FIRST (line 48)

### instance_icecrown_citadel.cpp

SPELL (5):

- SPELL_ARTHAS_TELEPORTER_CEREMONY (line 486)
- SPELL_AURA_MOD_INCREASE_HEALTH_PERCENT (line 284)
- SPELL_FROSTMOURNE_TELEPORT_VISUAL (line 1820)
- SPELL_GAS_VARIABLE (line 60)
- SPELL_OOZE_VARIABLE (line 61)

NPC (88):

- NPC_ALANA_MOONSTRIKE (line 349)
- NPC_ALCHEMIST_ADRIANNA (line 148)
- NPC_ALLIANCE_COMMANDER (line 341)
- NPC_ALLIANCE_GUNSHIP_CANNON (line 551)
- NPC_ALRIN_THE_AGILE (line 141)
- NPC_BLOOD_ORB_CONTROLLER (line 433)
- NPC_BLOOD_QUEEN_LANA_THEL (line 436)
- NPC_CAPTAIN_ARNATH (line 445)
- NPC_CAPTAIN_BRANDON (line 446)
- NPC_CAPTAIN_GRONDEL (line 447)
- NPC_CAPTAIN_RUPERT (line 448)
- NPC_CROK_SCOURGEBANE (line 441)
- NPC_DEATHBRINGER_SAURFANG (line 387)
- NPC_DEATHSPEAKER_SERVANT (line 659)
- NPC_FESTERGUT (line 413)
- NPC_FROSTWING_WHELP (line 623)
- NPC_GARROSH_HELLSCREAM (line 371)
- NPC_GERARDO_THE_SUAVE (line 351)
- NPC_GREEN_DRAGON_COMBAT_TRIGGER (line 463)
- NPC_HARAGG_THE_UNSEEN (line 367)
- NPC_HIGHLORD_TIRION_FORDRING_LK (line 493)
- NPC_HIGH_CAPTAIN_JUSTIN_BARTLETT (line 553)
- NPC_HIGH_OVERLORD_SAURFANG_DUMMY (line 402)
- NPC_HORDE_GUNSHIP_CANNON (line 545)
- NPC_IGB_HIGH_OVERLORD_SAURFANG (line 1774)
- NPC_IGB_MURADIN_BRONZEBEARD (line 563)
- NPC_IKFIRUS_THE_VILE (line 359)
- NPC_INFILTRATOR_MINCHAR (line 144)
- NPC_INFILTRATOR_MINCHAR_BQ (line 150)
- NPC_INVISIBLE_STALKER (line 483)
- NPC_JEDEBIA (line 365)
- NPC_KING_VARIAN_WRYNN (line 373)
- NPC_KOR_KRON_GENERAL (line 339)
- NPC_KOR_KRON_LIEUTENANT (line 145)
- NPC_LADY_DEATHWHISPER (line 384)
- NPC_LADY_JAINA_PROUDMOORE_QUEST (line 378)
- NPC_LADY_SYLVANAS_WINDRUNNER_QUEST (line 381)
- NPC_MALFUS_GRIMFROST (line 357)
- NPC_MINCHAR_BEAM_STALKER (line 151)
- NPC_MURADIN_BRONZEBEARD_DUMMY (line 405)
- NPC_MURADIN_BRONZEBEARD_QUEST (line 379)
- NPC_NIBY_THE_ALMIGHTY (line 369)
- NPC_ORGRIMS_HAMMER (line 130)
- NPC_ORGRIMS_HAMMER_CREW (line 520)
- NPC_PRINCE_KELESETH (line 424)
- NPC_PRINCE_TALDARAM (line 427)
- NPC_PRINCE_VALANAR (line 430)
- NPC_PROFESSOR_PUTRICIDE (line 419)
- NPC_PUTRICADES_TRAP (line 466)
- NPC_RIMEFANG (line 480)
- NPC_RISEN_DEATHSPEAKER_SERVANT (line 663)
- NPC_ROTFACE (line 416)
- NPC_ROTTING_FROST_GIANT_10 (line 146)
- NPC_ROTTING_FROST_GIANT_25 (line 147)
- NPC_SE_HIGH_OVERLORD_SAURFANG (line 390)
- NPC_SE_KOR_KRON_REAVER (line 409)
- NPC_SE_MURADIN_BRONZEBEARD (line 393)
- NPC_SE_SKYBREAKER_MARINE (line 411)
- NPC_SINDRAGOSA (line 128)
- NPC_SINDRAGOSA_GAUNTLET (line 469)
- NPC_SISTER_SVALNA (line 451)
- NPC_SKYBREAKER_DECKHAND (line 519)
- NPC_SKYBREAKER_LIEUTENANT (line 345)
- NPC_SKY_REAVER_KORM_BLACKSCAR (line 547)
- NPC_SPINESTALKER (line 477)
- NPC_SPIRE_FROSTWYRM (line 568)
- NPC_SPIRIT_WARDEN (line 1823)
- NPC_TALAN_MOONSTRIKE (line 353)
- NPC_TERENAS_MENETHIL_FROSTMOURNE (line 496)
- NPC_TERENAS_MENETHIL_FROSTMOURNE_H (line 497)
- NPC_THE_LICH_KING (line 488)
- NPC_THE_LICH_KING_LH (line 460)
- NPC_THE_LICH_KING_VALITHRIA (line 457)
- NPC_THE_SKYBREAKER (line 129)
- NPC_TORTUNOK (line 347)
- NPC_UTHER_THE_LIGHTBRINGER_QUEST (line 380)
- NPC_UVLUS_BANEFIRE (line 355)
- NPC_VALITHRIA_DREAMWALKER (line 454)
- NPC_VALITHRIA_DREAMWALKER_QUEST (line 152)
- NPC_VOL_GUK (line 363)
- NPC_WORLD_TRIGGER_INFINITE_AOI (line 1815)
- NPC_YILI (line 361)
- NPC_YMIRJAR_BATTLE_MAIDEN (line 615)
- NPC_YMIRJAR_DEATHBRINGER (line 616)
- NPC_YMIRJAR_FROSTBINDER (line 617)
- NPC_YMIRJAR_HUNTRESS (line 618)
- NPC_YMIRJAR_WARLORD (line 619)
- NPC_ZAFOD_BOOMBOX (line 557)

GO (83):

- GO_ARTHAS_PLATFORM (line 816)
- GO_ARTHAS_PRECIPICE (line 822)
- GO_BLOODWING_SIGIL (line 752)
- GO_BLOOD_ELF_COUNCIL_DOOR (line 106)
- GO_BLOOD_ELF_COUNCIL_DOOR_RIGHT (line 107)
- GO_CACHE_OF_THE_DREAMWALKER_10H (line 805)
- GO_CACHE_OF_THE_DREAMWALKER_10N (line 803)
- GO_CACHE_OF_THE_DREAMWALKER_25H (line 806)
- GO_CACHE_OF_THE_DREAMWALKER_25N (line 804)
- GO_CRIMSON_HALL_DOOR (line 104)
- GO_DEATHBRINGER_S_CACHE_10H (line 740)
- GO_DEATHBRINGER_S_CACHE_10N (line 738)
- GO_DEATHBRINGER_S_CACHE_25H (line 741)
- GO_DEATHBRINGER_S_CACHE_25N (line 739)
- GO_DESTRUCTIBLE_DAMAGED (line 1714)
- GO_DESTRUCTIBLE_DESTROYED (line 1806)
- GO_DESTRUCTIBLE_REBUILDING (line 1727)
- GO_DOODAD_ICECROWN_BLOODPRINCE_DOOR_01 (line 108)
- GO_DOODAD_ICECROWN_GRATE_01 (line 109)
- GO_DOODAD_ICECROWN_GREENTUBES02 (line 785)
- GO_DOODAD_ICECROWN_ICEWALL02 (line 99)
- GO_DOODAD_ICECROWN_ORANGETUBES02 (line 780)
- GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_01 (line 113)
- GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_02 (line 114)
- GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_03 (line 115)
- GO_DOODAD_ICECROWN_ROOSTPORTCULLIS_04 (line 116)
- GO_DOODAD_ICECROWN_SNOWEDGEWARNING01 (line 832)
- GO_DOODAD_ICECROWN_THRONEFROSTYEDGE01 (line 826)
- GO_DOODAD_ICECROWN_THRONEFROSTYWIND01 (line 829)
- GO_DRINK_ME (line 800)
- GO_FLAG_INTERACT_COND (line 793)
- GO_FLAG_IN_USE (line 1101)
- GO_FLAG_LOCKED (line 809)
- GO_FLAG_NODESPAWN (line 809)
- GO_FLAG_NOT_SELECTABLE (line 793)
- GO_FROZEN_LAVAMAN (line 835)
- GO_GAS_RELEASE_VALVE (line 790)
- GO_GEIST_ALARM_1 (line 682)
- GO_GEIST_ALARM_2 (line 683)
- GO_GREEN_DRAGON_BOSS_ENTRANCE (line 110)
- GO_GREEN_DRAGON_BOSS_EXIT (line 112)
- GO_GREEN_PLAGUE_MONSTER_ENTRANCE (line 103)
- GO_GUNSHIP_ARMORY_A_10H (line 590)
- GO_GUNSHIP_ARMORY_A_10N (line 588)
- GO_GUNSHIP_ARMORY_A_25H (line 591)
- GO_GUNSHIP_ARMORY_A_25N (line 589)
- GO_GUNSHIP_ARMORY_H_10H (line 583)
- GO_GUNSHIP_ARMORY_H_10N (line 581)
- GO_GUNSHIP_ARMORY_H_25H (line 584)
- GO_GUNSHIP_ARMORY_H_25N (line 582)
- GO_ICEWALL (line 98)
- GO_ICE_WALL (line 121)
- GO_LADY_DEATHWHISPER_ELEVATOR (line 717)
- GO_LAVAMAN_PILLARS_CHAINED (line 840)
- GO_LAVAMAN_PILLARS_UNCHAINED (line 845)
- GO_LORD_MARROWGAR_S_ENTRANCE (line 96)
- GO_OOZE_RELEASE_VALVE (line 795)
- GO_ORANGE_PLAGUE_MONSTER_ENTRANCE (line 102)
- GO_ORATORY_OF_THE_DAMNED_ENTRANCE (line 100)
- GO_ORGRIMS_HAMMER_A (line 721)
- GO_ORGRIMS_HAMMER_H (line 892)
- GO_PLAGUE_SIGIL (line 747)
- GO_SAURFANG_S_DOOR (line 101)
- GO_SCIENTIST_AIRLOCK_DOOR_COLLISION (line 762)
- GO_SCIENTIST_AIRLOCK_DOOR_GREEN (line 773)
- GO_SCIENTIST_AIRLOCK_DOOR_ORANGE (line 766)
- GO_SCIENTIST_ENTRANCE (line 707)
- GO_SCOURGE_TRANSPORTER_FIRST (line 97)
- GO_SCOURGE_TRANSPORTER_LK (line 811)
- GO_SCOURGE_TRANSPORTER_SAURFANG (line 744)
- GO_SIGIL_OF_THE_FROSTWING (line 757)
- GO_SINDRAGOSA_ENTRANCE_DOOR (line 117)
- GO_SINDRAGOSA_SHORTCUT_ENTRANCE_DOOR (line 119)
- GO_SINDRAGOSA_SHORTCUT_EXIT_DOOR (line 120)
- GO_SPIRIT_ALARM_1 (line 676)
- GO_SPIRIT_ALARM_2 (line 677)
- GO_SPIRIT_ALARM_3 (line 678)
- GO_SPIRIT_ALARM_4 (line 679)
- GO_STATE_ACTIVE (line 814)
- GO_STATE_ACTIVE_ALTERNATIVE (line 769)
- GO_STATE_READY (line 1674)
- GO_THE_SKYBREAKER_A (line 558)
- GO_THE_SKYBREAKER_H (line 720)
