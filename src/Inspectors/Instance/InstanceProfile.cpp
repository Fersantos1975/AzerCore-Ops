#include "InstanceProfile.h"

#include <algorithm>

namespace AzerCoreOps
{
std::vector<InstanceProfile> const& InstanceProfileCatalog::All()
{
    // Profiles contain relationships verified from the authoritative instance scripts.
    // They intentionally describe dependencies rather than assuming encounter ID order.
    static std::vector<InstanceProfile> const profiles{
        {
            631,
            "icecrown-citadel",
            "Icecrown Citadel",
            {0, 1, 2, 3},
            {
                {0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6},
                {7, 7}, {8, 8}, {9, 10}, {10, 11}, {11, 12}
            },
            {
                {0, 1, "Lord Marrowgar completion unlocks progression to Lady Deathwhisper"},
                {1, 2, "Lady Deathwhisper completion initializes the Gunship Battle"},
                {2, 3, "Gunship Battle completion unlocks Deathbringer's Rise"},
                {3, 4, "Deathbringer Saurfang completion unlocks the upper Plague Wing"},
                {3, 5, "Deathbringer Saurfang completion unlocks the upper Plague Wing"},
                {3, 7, "Deathbringer Saurfang completion unlocks the Blood Wing"},
                {3, 10, "Deathbringer Saurfang completion unlocks the Frost Wing"},
                {4, 6, "Festergut completion enables the gas valve required for Putricide"},
                {5, 6, "Rotface completion enables the ooze valve required for Putricide"},
                {14, 7, "Blood Prince trash completion initializes the Blood Council encounter"},
                {7, 8, "Blood Prince Council completion unlocks Blood-Queen Lana'thel"},
                {9, 10, "Sister Svalna's gauntlet unlocks Valithria Dreamwalker"},
                {10, 11, "Valithria Dreamwalker progression leads to Sindragosa's wing"},
                {6, 12, "Professor Putricide is one of three Frozen Throne sigil prerequisites"},
                {8, 12, "Blood-Queen Lana'thel is one of three Frozen Throne sigil prerequisites"},
                {11, 12, "Sindragosa is one of three Frozen Throne sigil prerequisites"}
            },
            {
                {"putricide-access", "Professor Putricide access", {4, 5}, 6, "Both Festergut and Rotface unlock the airlock; the trap/gauntlet must finish before the Professor Putricide entrance opens", 254, {DONE}},
                {"frozen-throne-access", "Frozen Throne access", {6, 8, 11}, 12, "Putricide, Lana'thel and Sindragosa remove the three sigils and enable the Lich King transporter", 0, {}}
            },
            {
                {2, {NOT_STARTED, TO_BE_DECIDED}, "Gunship is initialized by the post-Deathwhisper script", {1}},
                {7, {NOT_STARTED, TO_BE_DECIDED}, "Blood Council is initialized after its trash event completes", {14}},
                {11, {NOT_STARTED, TO_BE_DECIDED}, "Sindragosa is initialized by the Frostwing gauntlet and frostwyrm events", {13}},
                {12, {NOT_STARTED, TO_BE_DECIDED}, "The Lich King is initialized after all three wing sigils are complete", {6, 8, 11}},
                {13, {NOT_STARTED, TO_BE_DECIDED}, "Sindragosa's gauntlet is initialized after Frostwing progression", {10}},
                {14, {NOT_STARTED, FAIL, TO_BE_DECIDED}, "Blood Prince trash is initialized by the Crimson Hall event", {7}}
            },
            {
                {9, "Sister Svalna"},
                {13, "Sindragosa Gauntlet"},
                {14, "Blood Prince Trash"}
            },
            {
                {254, "Putricide trap/airlock", ProfileSignalKind::State, false},
                {26, "Coldflame jet trap", ProfileSignalKind::State, false},
                {28, "Blood Quickening", ProfileSignalKind::State, false},
                {251, "ICC zone buff available", ProfileSignalKind::Boolean, false},
                {252, "Weekly quest selection", ProfileSignalKind::Count, false},
                {23, "Remaining Frostwyrms", ProfileSignalKind::Count, false},
                {24, "Spinestalker trash remaining", ProfileSignalKind::Count, false},
                {25, "Rimefang trash remaining", ProfileSignalKind::Count, false},
                {257, "Sindragosa introduction completed", ProfileSignalKind::Boolean, false},
                {255, "Limited attempts enabled", ProfileSignalKind::Boolean, false},
                {29, "Heroic attempts remaining", ProfileSignalKind::Count, true},
                {256, "Heroic Lich King available", ProfileSignalKind::Boolean, true}
            },
            {
                {201857, "Marrowgar entrance", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {0}, {}, {0}},
                {202242, "First Scourge transporter", "TRANSPORT", ProfileObjectPolicy::Observe, {0}, {0}},
                {202244, "Deathbringer's Rise transporter", "TRANSPORT", ProfileObjectPolicy::Observe, {3}, {3}},
                {201911, "Marrowgar icewall", "DOOR", ProfileObjectPolicy::Observe, {0}, {0}},
                {201910, "Marrowgar second icewall", "DOOR", ProfileObjectPolicy::Observe, {0}, {0}},
                {201563, "Deathwhisper entrance", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {1}, {}, {1}},
                {201825, "Saurfang passage", "DOOR", ProfileObjectPolicy::Observe, {3}, {3}},
                {201371, "Festergut entrance", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {4}, {}, {4}},
                {201376, "Crimson Hall entrance", "DOOR", ProfileObjectPolicy::Observe, {14, 7}, {14}, {7}},
                {201755, "Blood-Queen grate", "DOOR", ProfileObjectPolicy::Observe, {8}, {8}},
                {201369, "Sindragosa shortcut entrance", "DOOR", ProfileObjectPolicy::Observe, {11}, {11}},
                {201379, "Sindragosa shortcut exit", "DOOR", ProfileObjectPolicy::Observe, {11}, {11}},
                {202396, "Sindragosa ice wall", "DOOR", ProfileObjectPolicy::Observe, {11}, {}, {11}},
                {201380, "Valithria spawn hole 1", "SPAWN_HOLE", ProfileObjectPolicy::Observe, {10}},
                {201381, "Valithria spawn hole 2", "SPAWN_HOLE", ProfileObjectPolicy::Observe, {10}},
                {201382, "Valithria spawn hole 3", "SPAWN_HOLE", ProfileObjectPolicy::Observe, {10}},
                {201383, "Valithria spawn hole 4", "SPAWN_HOLE", ProfileObjectPolicy::Observe, {10}},
                {201616, "Gas release valve", "VALVE", ProfileObjectPolicy::OneShotSelectableWhenReady, {4}},
                {201615, "Ooze release valve", "VALVE", ProfileObjectPolicy::OneShotSelectableWhenReady, {5}},
                {201370, "Rotface room entrance", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {5}},
                {201618, "Rotface green plague pipe", "MECHANIC", ProfileObjectPolicy::Observe, {5}},
                {201612, "Putricide airlock collision", "AIRLOCK", ProfileObjectPolicy::OpenWhenReady, {4, 5}},
                {201613, "Putricide orange airlock gate", "AIRLOCK", ProfileObjectPolicy::OpenWhenReady, {4, 5}},
                {201614, "Putricide green airlock gate", "AIRLOCK", ProfileObjectPolicy::OpenWhenReady, {4, 5}},
                {201372, "Professor Putricide entrance", "DOOR", ProfileObjectPolicy::Observe, {6}},
                {201378, "Blood Council left passage", "DOOR", ProfileObjectPolicy::OpenWhenReady, {7}},
                {201377, "Blood Council right passage", "DOOR", ProfileObjectPolicy::OpenWhenReady, {7}},
                {201746, "Blood-Queen room door", "DOOR", ProfileObjectPolicy::Observe, {8}},
                {201375, "Valithria entrance", "DOOR", ProfileObjectPolicy::Observe, {9, 10}, {9}, {10}},
                {201374, "Valithria exit", "DOOR", ProfileObjectPolicy::OpenWhenReady, {10}},
                {201373, "Sindragosa entrance", "DOOR", ProfileObjectPolicy::Observe, {13, 11}, {13}, {11}},
                {202182, "Plague Wing sigil", "SIGIL", ProfileObjectPolicy::Observe, {6}},
                {202183, "Blood Wing sigil", "SIGIL", ProfileObjectPolicy::Observe, {8}},
                {202181, "Frost Wing sigil", "SIGIL", ProfileObjectPolicy::Observe, {11}},
                {202223, "Frozen Throne transporter", "TRANSPORT", ProfileObjectPolicy::OpenWhenReady, {6, 8, 11}}
            },
            {
                {"icc-blood-advisor-201479", "Darkfallen Advisor", 37571, 201479, {4536.01f, 2768.77f, 351.184f, 8.0f}, 14, "This exact DB spawn feeds the Blood Prince Trash event", {0, 1, 2, 3}},
                {"icc-blood-archmage-201482", "Darkfallen Archmage", 37664, 201482, {4512.50f, 2769.94f, 351.184f, 8.0f}, 14, "This exact DB spawn feeds the Blood Prince Trash event", {0, 1, 2, 3}},
                {"icc-blood-knight-201646", "Darkfallen Blood Knight", 37595, 201646, {4529.09f, 2761.50f, 351.184f, 8.0f}, 14, "This exact DB spawn feeds the Blood Prince Trash event", {0, 1, 2, 3}},
                {"icc-blood-noble-201659", "Darkfallen Noble", 37663, 201659, {4530.15f, 2776.29f, 351.184f, 8.0f}, 14, "This exact DB spawn feeds the Blood Prince Trash event", {0, 1, 2, 3}}
            },
            {
                {0, {36612}, "marrowgar-bone-slice", "Bone Slice", "Ground", {69055}, false, "Scheduled after pull and re-enabled after Bone Storm; damage is split across valid targets"},
                {0, {36612}, "marrowgar-bone-spike", "Bone Spike Graveyard", "Ground / Bone Storm", {69057, 69065}, false, "Impales players on Bone Spike creatures; scheduled repeatedly and also permitted during Bone Storm"},
                {0, {36612}, "marrowgar-coldflame", "Coldflame", "Ground / Bone Storm", {69140, 72705, 69147}, false, "Uses a targeted ground line normally and a Bone Storm-specific variant while storming"},
                {0, {36612}, "marrowgar-bone-storm", "Bone Storm", "Transition", {69076}, false, "Warn, cast, movement cycle and end events form a bounded storm phase before normal abilities resume"},
                {0, {36612}, "marrowgar-berserk", "Berserk", "Enrage", {}, false, "Ten-minute encounter enrage"},

                {1, {36855}, "deathwhisper-mana-barrier", "Mana Barrier", "Phase 1", {70842}, false, "Phase 1 converts incoming health loss into mana loss; phase 2 starts when the remaining mana is consumed"},
                {1, {36855}, "deathwhisper-cultist-waves", "Cultist Waves", "Phase 1 / heroic phase 2", {70895, 70896, 70897, 70900, 70901, 70903}, false, "Fanatic and Adherent waves can transform, empower, martyr and reanimate; heroic mode continues wave pressure in phase 2"},
                {1, {36855}, "deathwhisper-death-and-decay", "Death and Decay", "All combat phases", {71001}, false, "Recurring ground-area mechanic"},
                {1, {36855}, "deathwhisper-dominate-mind", "Dominate Mind", "All combat phases", {71289}, false, "25-player mechanic controlling raid members"},
                {1, {36855}, "deathwhisper-phase2-caster-kit", "Phase 2 caster kit", "Phase 2", {71420, 72905, 71204, 71363}, false, "Mana Barrier ends; Frostbolt, Frostbolt Volley, Touch of Insignificance and Vengeful Shades become active"},

                {2, {36939, 36948, 37540, 37215}, "gunship-hull-victory", "Gunship hull race", "Combat", {72134, 72137}, false, "Encounter completion is driven by friendly/enemy ship hull death and distinguishes victory from wipe"},
                {2, {36939, 36948, 37540, 37215}, "gunship-cannons", "Cannons and Overheat", "Combat", {69487}, false, "Players operate ship cannons until the freeze cycle interrupts them"},
                {2, {36939, 36948, 37540, 37215}, "gunship-freeze-mage", "Below Zero mage freeze", "Combat", {69705, 43897}, false, "Enemy mage/sorcerer channels the cannon-freeze mechanic and forces boarding to remove it"},
                {2, {36939, 36948, 37540, 37215}, "gunship-boarding", "Enemy boarding waves", "Combat", {70104, 71201, 71188, 71193, 71195}, false, "Portal/teleport boarders gain battle experience tiers while attacking the player ship"},
                {2, {36939, 36948, 37540, 37215}, "gunship-rocket-artillery", "Rocket Artillery", "Combat", {70609, 69678}, false, "Ranged ship adds fire artillery across transports"},
                {2, {36939, 36948, 37540, 37215}, "gunship-rocket-pack", "Rocket Pack traversal", "Combat", {70055, 69192, 70348}, false, "Rocket packs provide player traversal between the two transports"},

                {3, {37813}, "saurfang-blood-power", "Blood Power / Blood Link", "Combat", {72178, 72371, 72195, 72202}, false, "Damage mechanics feed Blood Power through Blood Link and drive Mark casts"},
                {3, {37813}, "saurfang-boiling-blood", "Boiling Blood", "Combat", {72385}, false, "Recurring raid debuff that contributes Blood Power"},
                {3, {37813}, "saurfang-blood-nova", "Blood Nova", "Combat", {72378, 72380}, false, "Ranged-target blood nova contributes Blood Power"},
                {3, {37813}, "saurfang-rune-of-blood", "Rune of Blood", "Combat", {72410}, false, "Tank debuff and healing/Blood Power interaction"},
                {3, {37813}, "saurfang-blood-beasts", "Blood Beasts", "Combat", {72172, 72356}, false, "Periodic Blood Beast waves are core encounter adds", {38508}},
                {3, {37813}, "saurfang-mark", "Mark of the Fallen Champion", "Blood Power threshold", {72293}, false, "Blood Power threshold triggers persistent Mark casts"},
                {3, {37813}, "saurfang-scent-of-blood", "Scent of Blood", "Heroic", {72769}, true, "Heroic Blood Beasts gain Scent of Blood"},
                {3, {37813}, "saurfang-frenzy", "Frenzy", "Low health", {72737}, false, "Low-health frenzy accelerates the final part of the fight"},

                {4, {36626}, "festergut-gaseous-blight", "Gaseous Blight / Inhale cycle", "Combat", {69157, 69162, 69164, 69165}, false, "Three inhalations progressively reduce room blight before the cycle resets"},
                {4, {36626}, "festergut-pungent-blight", "Pungent Blight", "After third Inhale", {69195}, false, "Triggered after the inhale cycle and checked against player Inoculated stacks"},
                {4, {36626}, "festergut-gas-spore", "Gas Spore / Inoculated", "Combat", {69278, 69291}, false, "Gas Spores produce Inoculated protection for Pungent Blight"},
                {4, {36626}, "festergut-vile-gas", "Vile Gas", "Combat", {69240}, false, "Recurring ranged-group disruption mechanic"},
                {4, {36626}, "festergut-gastric-bloat", "Gastric Bloat / Explosion", "Tank", {72219, 72227}, false, "Tank stacks can culminate in Gastric Explosion"},
                {4, {36626}, "festergut-malleable-goo", "Malleable Goo", "Heroic", {72296}, true, "Heroic-only Putricide balcony mechanic"},

                {5, {36627}, "rotface-slime-spray", "Slime Spray", "Combat", {69508}, false, "Recurring directional spray"},
                {5, {36627}, "rotface-mutated-infection", "Mutated Infection", "Combat", {69674}, false, "Infection cadence accelerates as the fight progresses and creates ooze pressure"},
                {5, {36627}, "rotface-ooze-combine", "Ooze combination", "Combat", {69537, 69552, 69611, 69889}, false, "Small and Large Oozes merge through scripted combine spells"},
                {5, {36627}, "rotface-unstable-ooze", "Unstable Ooze Explosion", "Ooze threshold", {69558, 69839, 69832}, false, "Large Ooze stack progression culminates in Unstable Ooze Explosion"},
                {5, {36627}, "rotface-sticky-ooze", "Sticky Ooze", "Large Ooze", {69774}, false, "Large Oozes periodically leave Sticky Ooze"},
                {5, {36627}, "rotface-ooze-flood", "Ooze Flood", "Room mechanic", {69785, 69788, 69782, 69796, 69798, 69801}, false, "Professor-controlled flood rotates among four room sectors"},
                {5, {36627}, "rotface-vile-gas", "Vile Gas", "Heroic", {69240}, true, "Heroic-only Putricide balcony mechanic"},

                {6, {36678}, "putricide-slime-puddle", "Slime Puddle", "All combat phases", {70341, 70343, 70345, 70347}, false, "Persistent puddles grow and are consumed by the Mutated Abomination"},
                {6, {36678}, "putricide-unstable-experiment", "Unstable Experiment", "Phases 1-2", {70351, 70447, 70492, 70672, 70701}, false, "Alternating Volatile Ooze and Gas Cloud experiment cycle"},
                {6, {36678}, "putricide-transition", "80% / 35% phase transitions", "Transitions", {71617, 71618, 71620, 71621, 71893}, false, "Source health gates are 80% and 35%; transition events change the active ability set"},
                {6, {36678}, "putricide-abomination", "Mutated Abomination", "Phases 1-2", {70311, 70385, 70405}, false, "Player vehicle consumes puddles and supports ooze control"},
                {6, {36678}, "putricide-malleable-goo", "Malleable Goo", "Phases 2-3", {70852}, false, "Ranged-target projectile mechanic"},
                {6, {36678}, "putricide-choking-gas", "Choking Gas Bomb", "Phases 2-3", {71255, 71259, 71280}, false, "Bomb objects apply periodic choking gas and later explode"},
                {6, {36678}, "putricide-unbound-plague", "Unbound Plague", "Heroic", {70911, 70917, 70953, 70955}, true, "Heroic-only transferable plague with sickness/protection handling"},
                {6, {36678}, "putricide-mutated-plague", "Mutated Plague", "Phase 3", {72451, 72618}, false, "Phase 3 tank stacking mechanic"},

                {7, {37972, 37973, 37970}, "council-invocation", "Invocation of Blood", "Combat", {70981, 70982, 70952, 71596}, false, "Empowerment rotates among Keleseth, Taldaram and Valanar on a timed event"},
                {7, {37972, 37973, 37970}, "council-keleseth", "Keleseth: Shadow Lance / Dark Nuclei", "Keleseth empowered cycle", {71405, 71815, 71943, 72980, 71822}, false, "Shadow Resonance summons Dark Nuclei; empowered Keleseth upgrades Shadow Lance"},
                {7, {37972, 37973, 37970}, "council-taldaram", "Taldaram: Glittering Sparks / Flame Sphere", "Taldaram empowered cycle", {71806, 71718, 72040, 71714, 71393}, false, "Empowered Taldaram uses the empowered Flame Sphere path"},
                {7, {37972, 37973, 37970}, "council-valanar", "Valanar: Kinetic Bomb / Shock Vortex", "Valanar empowered cycle", {72053, 72080, 72037, 72039}, false, "Valanar manages Kinetic Bombs and upgrades Shock Vortex while empowered"},
                {7, {37972, 37973, 37970}, "council-shadow-prison", "Shadow Prison", "Heroic", {72998, 72999, 73001}, true, "Heroic-only movement punishment aura is applied to all three princes' combat context"},

                {8, {37955}, "lana-vampiric-bite", "Vampiric Bite / Bloodthirst", "Combat", {71726, 70867, 70879, 70877, 70923}, false, "Initial bite creates vampire propagation; failure to bite progresses to Uncontrollable Frenzy"},
                {8, {37955}, "lana-blood-mirror", "Blood Mirror", "Tank", {70821, 71510, 70838}, false, "Links the primary and secondary tank targets"},
                {8, {37955}, "lana-pact", "Pact of the Darkfallen", "Ground", {71336, 71340, 71341}, false, "Links selected players until they converge"},
                {8, {37955}, "lana-swarming-shadows", "Swarming Shadows", "Ground", {71264}, false, "Targeted movement trail mechanic"},
                {8, {37955}, "lana-air-phase", "Air Phase / Bloodbolt Whirl", "Air", {73070, 71772, 71445, 71818, 71446}, false, "Incite Terror precedes flight and Bloodbolt Whirl during the air cycle"},

                {10, {36789}, "valithria-healing-objective", "Healing objective", "Encounter", {70904, 71189, 71196}, false, "Encounter succeeds by restoring Valithria rather than damaging a conventional boss"},
                {10, {36789}, "valithria-portals", "Dream Portals", "Normal", {72224, 71305, 70873}, false, "Normal mode pre-summons Dream Portals leading to Emerald Vigor clouds"},
                {10, {36789}, "valithria-nightmare-portals", "Nightmare Portals", "Heroic", {72480, 71987, 71970, 71941}, true, "Heroic mode replaces the portal/cloud package with Nightmare variants"},
                {10, {36789}, "valithria-add-waves", "Lich King add waves", "Encounter", {70915, 70912, 70914, 70916, 70913, 70936}, false, "Timed summon channels produce Abominations, Suppressers, Zombies, Archmages and Blazing Skeletons"},
                {10, {36789}, "valithria-suppression", "Suppression", "Add mechanic", {70588}, false, "Suppressers reduce healing effectiveness on Valithria"},
                {10, {36789}, "valithria-add-abilities", "Encounter add abilities", "Add mechanic", {70759, 71179, 70704, 70754, 69325, 70744, 70633}, false, "Archmages, Skeletons, Zombies and Abominations contribute the scripted raid pressure"},

                {11, {36853}, "sindragosa-ground-kit", "Ground phase kit", "Ground", {70084, 69649, 69762, 70117, 70123, 19983, 71077}, false, "Ground phase combines Frost Aura/Breath, Unchained Magic, Icy Grip into Blistering Cold, Cleave and Tail Smash"},
                {11, {36853}, "sindragosa-air-phase", "Air Phase", "Air", {70126, 69712, 69675, 69846, 69845}, false, "Frost Beacons become Ice Tombs while Frost Bombs resolve around tomb line-of-sight"},
                {11, {36853}, "sindragosa-phase3", "Mystic Buffet phase", "Final ground phase", {70128, 73061}, false, "Final phase adds Mystic Buffet and phase-2 Frost Breath while Ice Tomb continues"},
                {11, {36853}, "sindragosa-ice-tomb", "Ice Tomb", "Air / final phase", {69712, 69675, 69700, 70157, 71665}, false, "Script summons Ice Tomb creatures/gameobjects and tracks the trapped player"},

                {12, {36597}, "lk-phase1", "Phase 1: adds, Infest and Necrotic Plague", "Phase 1", {70372, 70358, 70541, 70337, 70338}, false, "Phase 1 combines Shambling Horrors, Drudge Ghouls, Infest and transferable Necrotic Plague"},
                {12, {36597}, "lk-shadow-trap", "Shadow Trap", "Heroic phase 1", {73539, 73525, 73529}, true, "Heroic phase 1 ground trap with knockback"},
                {12, {36597}, "lk-transition", "Remorseless Winter transition", "Transitions", {68981, 72259, 72262, 72133, 69104, 69200}, false, "Transition phase uses Remorseless Winter, Pain and Suffering, Ice Spheres, Raging Spirits and Quake"},
                {12, {36597}, "lk-phase2", "Phase 2: Defile, Soul Reaper and Val'kyr", "Phase 2", {72762, 72743, 69409, 69037, 69030, 74445}, false, "Core phase-2 package including Val'kyr pickup/drop behavior"},
                {12, {36597}, "lk-phase3", "Phase 3: Vile Spirits / Harvest Soul", "Phase 3", {70498, 70501, 70502, 70503, 68980, 68984}, false, "Vile Spirits and Harvest Soul replace the Val'kyr package in phase 3"},
                {12, {36597}, "lk-frostmourne-normal", "Frostmourne room", "Normal phase 3", {72546, 72597, 69382, 69397, 72595}, false, "Normal Harvest Soul sends one player into Frostmourne for the Terenas encounter and return path"},
                {12, {36597}, "lk-frostmourne-heroic", "Heroic Frostmourne realm", "Heroic phase 3", {73654, 73655, 73650, 73581, 74299, 73582, 73576}, true, "Heroic Harvest Souls sends the raid into the Frostmourne phase with Spirit Bomb/Vile Spirit mechanics"},
                {12, {36597}, "lk-outro", "Fury of Frostmourne scripted outro", "Outro", {72350, 71769, 71797, 72420, 72429, 72423}, false, "The encounter ends through the scripted Fury of Frostmourne/Tirion/Terenas resurrection sequence rather than a simple death event"}
            }
        },
        {
            603,
            "ulduar",
            "Ulduar",
            {0, 1},
            {
                {0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6},
                {7, 7}, {8, 8}, {9, 9}, {10, 10}, {11, 11}, {12, 12}, {13, 13}
            },
            {
                {0, 1, "Flame Leviathan completion opens the Ulduar courtyard and Ignis approach"},
                {0, 2, "Flame Leviathan completion opens the Ulduar courtyard and Razorscale approach"},
                {0, 3, "Flame Leviathan completion opens progression toward XT-002"},
                {3, 4, "XT-002 completion opens the Antechamber progression route"},
                {4, 5, "Assembly of Iron completion opens the Archivum and inner Antechamber"},
                {5, 6, "Kologarn completion forms the bridge into the inner complex"},
                {5, 7, "Kologarn completion gives access toward the Conservatory of Life"},
                {5, 8, "Kologarn completion gives access toward the Halls of Winter"},
                {5, 9, "Kologarn completion gives access toward the Spark of Imagination"},
                {5, 10, "Kologarn completion gives access toward the Clash of Thunder"},
                {7, 11, "Freya is one of four Keeper prerequisites for the Ancient Gate"},
                {8, 11, "Hodir is one of four Keeper prerequisites for the Ancient Gate"},
                {9, 11, "Mimiron is one of four Keeper prerequisites for the Ancient Gate"},
                {10, 11, "Thorim is one of four Keeper prerequisites for the Ancient Gate"},
                {11, 12, "General Vezax completion opens the passage to Yogg-Saron"}
            },
            {
                {"ulduar-courtyard", "Ulduar courtyard access", {0}, 3, "Flame Leviathan completion opens the forward courtyard route", 0, {}},
                {"ulduar-ancient-gate", "Ancient Gate", {7, 8, 9, 10}, 11, "All four Keepers must be defeated before the Ancient Gate unlocks", 0, {}},
                {"ulduar-descent", "Descent into Madness", {11}, 12, "General Vezax completion opens the way to Yogg-Saron", 0, {}}
            },
            {},
            {},
            {
                {21030, "Tower of Life active", ProfileSignalKind::Boolean, false},
                {21031, "Tower of Storms active", ProfileSignalKind::Boolean, false},
                {21032, "Tower of Frost active", ProfileSignalKind::Boolean, false},
                {21033, "Tower of Flames active", ProfileSignalKind::Boolean, false},
                {710, "Mimiron tram used", ProfileSignalKind::Boolean, false},
                {800, "Expedition Base Camp mage barrier", ProfileSignalKind::State, false}
            },
            {
                {194630, "Flame Leviathan gate", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {0}, {}, {0}},
                {194905, "Courtyard lightning wall", "DOOR", ProfileObjectPolicy::Observe, {0}, {0}},
                {194416, "Secondary lightning wall", "DOOR", ProfileObjectPolicy::Observe, {0}},
                {194262, "Salvaged vehicle repair station", "REPAIR_STATION", ProfileObjectPolicy::Observe, {0}},
                {194704, "Freya targeting crystal", "TOWER_CRYSTAL", ProfileObjectPolicy::Observe, {}},
                {194705, "Mimiron targeting crystal", "TOWER_CRYSTAL", ProfileObjectPolicy::Observe, {}},
                {194706, "Thorim targeting crystal", "TOWER_CRYSTAL", ProfileObjectPolicy::Observe, {}},
                {194707, "Hodir targeting crystal", "TOWER_CRYSTAL", ProfileObjectPolicy::Observe, {}},
                {194663, "Freya tower generator", "TOWER_GENERATOR", ProfileObjectPolicy::Observe, {}},
                {194664, "Mimiron tower generator", "TOWER_GENERATOR", ProfileObjectPolicy::Observe, {}},
                {194665, "Hodir tower generator", "TOWER_GENERATOR", ProfileObjectPolicy::Observe, {}},
                {194666, "Thorim tower generator", "TOWER_GENERATOR", ProfileObjectPolicy::Observe, {}},
                {194398, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194399, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194400, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194401, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194402, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194403, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194404, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194405, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194406, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194407, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194408, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194409, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194410, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194411, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194412, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194413, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194414, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194415, "Storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194506, "Formation Grounds storm beacon", "TOWER_BEACON", ProfileObjectPolicy::Observe, {}},
                {194519, "Razorscale harpoon 1", "HARPOON", ProfileObjectPolicy::Observe, {2}},
                {194541, "Razorscale harpoon 2", "HARPOON", ProfileObjectPolicy::Observe, {2}},
                {194542, "Razorscale harpoon 3", "HARPOON", ProfileObjectPolicy::Observe, {2}},
                {194543, "Razorscale harpoon 4", "HARPOON", ProfileObjectPolicy::Observe, {2}},
                {194565, "Broken Razorscale harpoon", "HARPOON", ProfileObjectPolicy::Observe, {2}},
                {194316, "Razorscale mole machine", "SPAWNER", ProfileObjectPolicy::Observe, {2}},
                {194631, "XT-002 gate", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {3}, {}, {3}},
                {194554, "Assembly of Iron gate", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {4}, {}, {4}},
                {194556, "Archivum gate", "DOOR", ProfileObjectPolicy::Observe, {4}, {4}},
                {194232, "Kologarn bridge", "BRIDGE", ProfileObjectPolicy::Observe, {5}, {5}},
                {195046, "Kologarn cache 10", "LOOT_CACHE", ProfileObjectPolicy::Observe, {5}},
                {195047, "Kologarn cache 25", "LOOT_CACHE", ProfileObjectPolicy::Observe, {5}},
                {194255, "Ancient Gate", "DOOR", ProfileObjectPolicy::OpenWhenReady, {7, 8, 9, 10}, {7, 8, 9, 10}},
                {194441, "Hodir frozen passage", "DOOR", ProfileObjectPolicy::Observe, {8}, {8}},
                {194634, "Hodir exit", "DOOR", ProfileObjectPolicy::Observe, {8}, {8}},
                {194442, "Hodir entrance", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {8}, {}, {8}},
                {194307, "Hodir cache 10", "LOOT_CACHE", ProfileObjectPolicy::Observe, {8}},
                {194308, "Hodir cache 25", "LOOT_CACHE", ProfileObjectPolicy::Observe, {8}},
                {194200, "Hodir rare cache 10", "HARD_MODE_CACHE", ProfileObjectPolicy::Observe, {8}},
                {194201, "Hodir rare cache 25", "HARD_MODE_CACHE", ProfileObjectPolicy::Observe, {8}},
                {194907, "Hodir snow mound", "SAFE_ZONE", ProfileObjectPolicy::Observe, {8}},
                {194675, "Mimiron tram", "TRANSPORT", ProfileObjectPolicy::Observe, {5}},
                {194437, "Mimiron tram activation", "CONTROL", ProfileObjectPolicy::Observe, {5}},
                {194914, "Call tram at center", "CONTROL", ProfileObjectPolicy::Observe, {5}},
                {194912, "Call tram at Mimiron", "CONTROL", ProfileObjectPolicy::Observe, {5}},
                {194904, "Mimiron tram rocket booster", "TRANSPORT", ProfileObjectPolicy::Observe, {5}},
                {194915, "Tram turnaround center", "TRANSPORT", ProfileObjectPolicy::Observe, {5}},
                {194913, "Tram turnaround Mimiron", "TRANSPORT", ProfileObjectPolicy::Observe, {5}},
                {194749, "Mimiron elevator", "ELEVATOR", ProfileObjectPolicy::Observe, {9}},
                {194776, "Mimiron door 1", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {9}, {}, {9}},
                {194774, "Mimiron door 2", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {9}, {}, {9}},
                {194775, "Mimiron door 3", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {9}, {}, {9}},
                {194739, "Mimiron emergency button", "HARD_MODE_CONTROL", ProfileObjectPolicy::Observe, {9}},
                {194789, "Mimiron cache 10", "LOOT_CACHE", ProfileObjectPolicy::Observe, {9}},
                {194956, "Mimiron cache 25", "LOOT_CACHE", ProfileObjectPolicy::Observe, {9}},
                {194957, "Mimiron hard-mode cache 10", "HARD_MODE_CACHE", ProfileObjectPolicy::Observe, {9}},
                {194958, "Mimiron hard-mode cache 25", "HARD_MODE_CACHE", ProfileObjectPolicy::Observe, {9}},
                {194560, "Thorim arena gate", "DOOR", ProfileObjectPolicy::Observe, {10}},
                {194264, "Thorim arena lever", "CONTROL", ProfileObjectPolicy::Observe, {10}},
                {194559, "Thorim arena fence", "DOOR", ProfileObjectPolicy::Observe, {10}},
                {194557, "Thorim first colossus door", "DOOR", ProfileObjectPolicy::Observe, {10}},
                {194558, "Thorim second colossus door", "DOOR", ProfileObjectPolicy::Observe, {10}},
                {194312, "Thorim cache 10", "LOOT_CACHE", ProfileObjectPolicy::Observe, {10}},
                {194314, "Thorim cache 25", "LOOT_CACHE", ProfileObjectPolicy::Observe, {10}},
                {194750, "Vezax passage", "DOOR", ProfileObjectPolicy::Observe, {11}, {11}},
                {194773, "Yogg-Saron doors", "DOOR", ProfileObjectPolicy::Observe, {12}, {}, {12}},
                {194462, "Dragon Soul vision object", "VISION_OBJECT", ProfileObjectPolicy::Observe, {12}},
                {194625, "Flee to the Surface portal", "VISION_PORTAL", ProfileObjectPolicy::Observe, {12}},
                {194635, "Chamber vision doors", "VISION_DOOR", ProfileObjectPolicy::Observe, {12}},
                {194636, "Icecrown vision doors", "VISION_DOOR", ProfileObjectPolicy::Observe, {12}},
                {194637, "Stormwind vision doors", "VISION_DOOR", ProfileObjectPolicy::Observe, {12}},
                {194628, "Celestial Planetarium access 10", "ACCESS_CONTROL", ProfileObjectPolicy::Observe, {}},
                {194752, "Celestial Planetarium access 25", "ACCESS_CONTROL", ProfileObjectPolicy::Observe, {}},
                {194767, "Planetarium sigil door 1", "DOOR", ProfileObjectPolicy::Observe, {13}},
                {194911, "Planetarium sigil door 2", "DOOR", ProfileObjectPolicy::Observe, {13}},
                {194910, "Planetarium sigil door 3", "DOOR", ProfileObjectPolicy::EncounterRoomDoor, {13}, {}, {13}},
                {194715, "Planetarium universe floor 1", "ENCOUNTER_FLOOR", ProfileObjectPolicy::EncounterRoomDoor, {13}, {}, {13}},
                {194716, "Planetarium universe floor 2", "SPAWN_HOLE", ProfileObjectPolicy::Observe, {13}},
                {194148, "Planetarium universe globe", "ENCOUNTER_OBJECT", ProfileObjectPolicy::Observe, {13}},
                {194253, "Planetarium trapdoor", "SPAWN_HOLE", ProfileObjectPolicy::Observe, {13}},
                {194821, "Gift of the Observer 10", "LOOT_CACHE", ProfileObjectPolicy::Observe, {13}},
                {194822, "Gift of the Observer 25", "LOOT_CACHE", ProfileObjectPolicy::Observe, {13}}
            },
            {},
            {
                {0, {33113}, "leviathan-pursuit", "Pursuit and vehicle pressure", "Vehicle combat", {62374, 62375, 62376, 62396, 62400, 63666, 65026}, false, "Pursuit, Gathering Speed, Battering Ram, Flame Vents, Missile Barrage and Napalm form the base vehicle encounter"},
                {0, {33113}, "leviathan-shutdown", "Systems Shutdown", "Overload window", {62399, 62475}, false, "Players launched onto Leviathan destroy turrets and overload circuits to force a shutdown"},
                {0, {33113}, "leviathan-towers", "Active tower support", "Tower hard mode", {65076, 65075, 65077, 64482, 62533, 62297, 62906, 62909, 62911, 62402, 63575, 62292}, false, "Undestroyed towers add Storm, Flames, Frost and Life mechanics"},
                {0, {33113}, "leviathan-vehicles", "Salvaged vehicles and pyrite", "Vehicle combat", {62472, 62494, 62323, 62336, 67372, 67393, 62340, 62705, 62496}, false, "Siege Engines, Demolishers and Choppers provide encounter actions and passenger launching", {33060, 33062, 33109}},

                {1, {33118}, "ignis-core", "Flame Jets, Scorch and Slag Pot", "Combat", {62680, 62546, 62717, 62707, 62708, 62711}, false, "Ignis controls movement, creates Scorched ground and carries players through Slag Pot"},
                {1, {33118}, "ignis-constructs", "Iron Construct heat cycle", "Construct cycle", {62488, 64473, 62548, 62343, 65667, 62373, 62382, 62383}, false, "Constructs activate, heat to Molten, cool to Brittle and shatter", {33121, 33123}},

                {2, {33186}, "razorscale-air", "Air phase fire and add waves", "Air", {63815, 63236, 64709, 64734, 62899, 62926, 63135, 63968, 63970, 63969, 63798}, false, "Razorscale attacks from the air while mole machines deploy Dark Rune waves", {33388, 33453, 33846}},
                {2, {33186}, "razorscale-harpoons", "Harpoon repair and grounding", "Grounding transition", {62696, 63658, 63657, 63659, 63524, 62505, 62794}, false, "Engineers repair harpoons; completed harpoons pull Razorscale into temporary ground phases"},
                {2, {33186}, "razorscale-ground", "Ground and permanent-ground kit", "Ground / final", {63317, 64021, 62666, 62669, 64821, 64774, 64016}, false, "Ground phases use breath and Wing Buffet; below 50 percent Razorscale remains grounded and applies Fuse Armor"},

                {3, {33293}, "xt-core", "Tantrum, Searing Light and Gravity Bomb", "Phase 1", {62776, 63018, 63024}, false, "Core raid-pressure mechanics run between heart exposures"},
                {3, {33293}, "xt-heart", "Heart exposure", "Heart phase", {63313, 63849, 63852, 62789, 62791, 64799}, false, "Health thresholds expose the Heart of the Deconstructor and pause the normal kit", {33329}},
                {3, {33293}, "xt-hard-mode", "Heartbreak hard mode", "Hard mode", {65737, 64210, 64203, 64209, 64227, 64230}, false, "Destroying the exposed heart activates Heartbreak plus Life Spark and Void Zone mechanics"},
                {3, {33293}, "xt-adds", "Toy-pile add waves", "Heart phase", {62832, 62831, 62828, 62835, 62790, 62826, 65032, 62834}, false, "Toy piles produce Scrapbots, Boombots and Pummelers during heart phases", {33343}},

                {4, {32867, 32927, 32857}, "assembly-supercharge", "Supercharge and kill order", "Council progression", {61920, 47008}, false, "Each council death heals and supercharges survivors, making kill order the hard-mode selector"},
                {4, {32867}, "assembly-steelbreaker", "Steelbreaker abilities", "Council", {61890, 61903, 61911, 64637, 61902}, false, "Fusion Punch and Static Disruption lead into Overwhelming Power and Electrical Charge when Steelbreaker survives"},
                {4, {32927}, "assembly-molgeim", "Runemaster Molgeim abilities", "Council", {62277, 62274, 61973, 62269, 62273, 62020, 62054}, false, "Power, Death and Summoning runes expand as Molgeim is supercharged", {32958, 33051}},
                {4, {32857}, "assembly-brundir", "Stormcaller Brundir abilities", "Council", {61879, 61869, 61915, 61916, 61887, 61883, 64187}, false, "Chain Lightning, Overload, Lightning Whirl and airborne Tendrils expand as Brundir is supercharged"},

                {5, {32930}, "kologarn-arms", "Stone Grip and arm destruction", "Body and arms", {62166, 63766, 63629, 63821, 64753}, false, "The right arm grips players, the left sweeps, and destroyed arms damage Kologarn before respawning", {32933, 32934, 33768}},
                {5, {32930}, "kologarn-eye-beams", "Focused Eyebeams", "Combat", {63342, 63347, 63702, 63676}, false, "Paired eye entities chase selected players with Focused Eyebeams", {33632, 33802}},
                {5, {32930}, "kologarn-body", "Smash, Stone Shout and breath", "Combat", {63356, 63573, 62030, 63716}, false, "Available body attacks change with arm state and target positioning"},

                {6, {33515}, "auriaya-sentries", "Sanctum Sentries", "Pull", {64666, 64375, 64369}, false, "Sentries use pounce and Rip Flesh while Strength of the Pack rewards clustered sentries", {34014}},
                {6, {33515}, "auriaya-core", "Screeches, Sentinel Blast and swarm", "Combat", {64386, 64389, 64422, 64396}, false, "Auriaya fears the raid, follows with Sentinel Blast and summons guardians"},
                {6, {33515}, "auriaya-defender", "Feral Defender lives", "Defender cycle", {64449, 64455, 64456, 64457, 64478, 64496, 64489, 64458}, false, "The Feral Defender repeatedly dies, loses Feral Essence and leaves Seeping Feral Essence", {34035, 34098}},

                {7, {32906}, "freya-attunement", "Attuned to Nature and add waves", "Wave phase", {62519, 62524, 62525, 62521, 62685, 62686, 62687}, false, "Six scripted add waves remove Attuned to Nature stacks as their members die"},
                {7, {32906}, "freya-wave-trio", "Ancient Water Spirit, Storm Lasher and Snaplasher", "Wave phase", {62653, 62654, 62655, 62648, 62649, 62664}, false, "The elemental trio must die together or revive", {33202, 32919, 32916}},
                {7, {32906}, "freya-conservator", "Ancient Conservator", "Wave phase", {62532, 62589, 62541, 62538, 62566}, false, "Conservator's Grip and Nature's Fury are countered by Healthy Spores", {33203, 33215}},
                {7, {32906}, "freya-lashers", "Detonating Lashers", "Wave phase", {62598, 62608}, false, "Detonating Lashers pressure the raid when killed", {32918}},
                {7, {32906}, "freya-final", "Sunbeam and Nature Bombs", "Final phase", {62623, 64648, 64587, 62528, 62559, 62619, 62579, 62584, 62572}, false, "After Attuned to Nature is removed, Nature Bombs join Sunbeam"},
                {7, {32906, 32913, 32914, 32915}, "freya-elders", "Elder-assisted hard mode", "Elder hard mode", {62437, 62862, 62861, 62450, 62451, 62216, 62386, 62483, 62484, 62485, 62239, 62240, 62211, 62209, 62217, 62275, 62283, 62285, 62310, 62325, 62337, 62344}, false, "Living elders grant Freya extra abilities and determine one-, two- or three-elder hard-mode rewards", {32913, 32914, 32915}},

                {8, {32845}, "hodir-cold", "Biting Cold, Freeze and Frozen Blows", "Combat", {62038, 62039, 62188, 62469, 62478}, false, "Movement manages Biting Cold while Freeze and Frozen Blows shape the combat cycle"},
                {8, {32845}, "hodir-flash-freeze", "Flash Freeze and snowdrifts", "Flash Freeze", {61968, 62226, 61969, 61990, 62148, 62463, 65705, 62464, 62227, 63545, 62476, 62477, 62236, 62460, 62457, 65370}, false, "Falling icicles create snowdrifts that protect players and helpers from Flash Freeze", {32926, 32938, 33169, 33173}},
                {8, {32845}, "hodir-helpers", "Freed helper abilities", "Combat support", {63499, 62809, 61923, 62793, 62807, 61924, 65123, 63711, 65134, 61909, 64528, 62823, 62819, 62821, 65280}, false, "Freed NPC helpers provide Starlight, Storm Power and Toasty Fire support"},
                {8, {32845}, "hodir-cache", "Rare Cache timer", "Timed hard mode", {62501, 65272}, false, "The hard-mode cache survives only if Hodir is defeated before the Shatter Chest timer resolves"},

                {9, {33350, 33432}, "mimiron-phase1", "Leviathan Mk II", "Phase 1", {63666, 62997, 63631, 63027, 66351}, false, "Leviathan Mk II uses mines, Napalm, Plasma Blast and Shock Blast", {34362}},
                {9, {33350, 33651}, "mimiron-phase2", "VX-001", "Phase 2", {64533, 64064, 64402, 65034, 63681, 63036, 63041, 63382, 63387, 64019, 63414}, false, "VX-001 uses Rapid Burst, Heat Wave, Rocket Strike and Laser Barrage", {34047, 34050}},
                {9, {33350, 33670}, "mimiron-phase3", "Aerial Command Unit", "Phase 3", {63689, 65647, 64436, 64438, 64444, 63811, 63801}, false, "The aerial unit deploys bots and can be grounded with a Magnetic Core", {33836, 34057, 33855, 34068}},
                {9, {33350, 33432, 33651, 33670}, "mimiron-voltron", "V-07-TR-0N", "Phase 4", {64352, 64348, 64383}, false, "All three machine sections fight together and must be destroyed inside their self-repair window"},
                {9, {33350, 33432, 33651, 33670}, "mimiron-firefighter", "Emergency Mode", "Hard mode", {64582, 64610, 64563, 64564, 64561, 64623, 64624, 64627, 64626, 65333, 64619, 64616}, false, "The emergency button starts the Firefighter timer and adds spreading flames, Frost Bombs and emergency fire bots", {34363, 34121, 34149, 34147}},

                {10, {32865}, "thorim-arena", "Arena and gauntlet split", "Phase 1", {62042, 62016, 63238, 62186, 64972, 62241, 63540, 62560, 62334, 62335, 62333, 61965, 61967, 61964, 62318, 40652, 16496, 62317, 62444, 57807, 62315, 62316}, false, "The raid splits between an arena add defense and a trapped gauntlet route", {32886, 32885, 32883, 32908, 32907, 32882, 32877, 32878, 32876, 32904}},
                {10, {32865}, "thorim-gauntlet", "Runic Colossus and Ancient Rune Giant", "Gauntlet", {62613, 62338, 62339, 62057, 62058, 62465, 62526, 62942, 62411, 62331, 64151, 62332, 62320, 62322, 62327, 62328, 62321}, false, "Colossus and Rune Giant gate the route to Thorim", {32874, 32872, 32873, 33110, 32875}},
                {10, {32865}, "thorim-ring", "Thorim ground combat", "Phase 2", {62130, 62279, 62466, 62131, 62976, 26662}, false, "Thorim enters the ring and uses Unbalancing Strike, Lightning Charge and Chain Lightning"},
                {10, {32865}, "thorim-sif", "Sif joins the fight", "Timed hard mode", {62507, 64778, 62601, 62604, 62577, 62605}, false, "Reaching Thorim before Sif's domination timer expires activates the hard mode"},

                {11, {33271}, "vezax-core", "Aura of Despair and caster pressure", "Combat", {62692, 64848, 62660, 62659, 63277, 65269, 62661, 62662, 63276, 63278}, false, "Aura of Despair changes resource rules while Shadow Crash, Searing Flames, Surge and Mark pressure the raid"},
                {11, {33271}, "vezax-vapors", "Saronite Vapors", "Normal resource mechanic", {63081, 63338, 63337, 63323, 63322}, false, "Vapors create Saronite pools when killed; preserving all vapors enables Animus formation", {33488}},
                {11, {33271}, "vezax-animus", "Saronite Animus", "Hard mode", {63319, 63145, 63364, 63420}, false, "Unkilled vapors merge into the Animus; its barrier protects Vezax while Profound Darkness stacks", {33524}},

                {12, {33134}, "yogg-phase1", "Sara and Guardians", "Phase 1", {63084, 63031, 62714, 65719, 63038, 63138, 63747, 63134, 63745, 63147, 63744}, false, "Ominous Clouds summon Guardians whose deaths damage Sara", {33292, 33136}},
                {12, {33134, 33288}, "yogg-phase2-mind", "Sanity, Psychosis, Malady and Brain Link", "Phase 2", {63786, 63050, 63120, 64464, 64554, 63795, 65301, 63830, 63881, 63802, 63803, 63804}, false, "Phase 2 attacks player sanity while Brain Link and Malady constrain movement"},
                {12, {33134, 33288}, "yogg-phase2-tentacles", "Tentacle pressure", "Phase 2", {64022, 64384, 64017, 64144, 64146, 64145, 64148, 64132, 64133, 64123, 64125, 64156, 64153, 64157, 64152}, false, "Crusher, Constrictor and Corruptor tentacles control the surface arena", {33966, 33983, 33985}},
                {12, {33890}, "yogg-visions", "Brain portals and visions", "Phase 2 brain room", {64416, 63997, 63998, 63989, 63992, 63993, 64059, 64173, 64361}, false, "Portals select Dragon, Icecrown or Stormwind visions; killing influence tentacles exposes the Brain", {33943, 34072}},
                {12, {33288}, "yogg-phase3", "Lunatic Gaze and Immortal Guardians", "Phase 3", {64167, 64166, 63305, 64039, 57688, 64163, 64189, 64465, 65294, 64161, 64159, 64468, 64486}, false, "Yogg becomes attackable while Lunatic Gaze and Immortal Guardians pressure the raid", {33988, 36064}},
                {12, {33288, 33410, 33411, 33412, 33413}, "yogg-keepers", "Keeper assistance / Alone in the Darkness", "Keeper selection", {62647, 62671, 62702, 62650, 62670, 65206, 65210, 64169, 64174, 64175, 64170, 64171, 64162}, false, "Zero to four selected Keepers determine Yogg difficulty and assistance mechanics", {33410, 33411, 33412, 33413}},

                {13, {32871}, "algalon-core", "Quantum Strike, Phase Punch and Cosmic Smash", "Normal phase", {64395, 64412, 62301, 62304, 62300}, false, "Algalon's repeating tank and ground mechanics define the normal combat cycle"},
                {13, {32871}, "algalon-big-bang", "Big Bang and Ascend", "Big Bang cycle", {64443, 64487, 65508, 65509, 65311}, false, "Players use black holes to phase out for Big Bang; Ascend resolves failure states"},
                {13, {32871}, "algalon-stars", "Collapsing Stars and Black Holes", "Normal phase", {62018, 62003, 62189, 62185, 64122, 62169}, false, "Collapsing Stars create Black Holes and interact with Living Constellations", {32955, 32953, 33052}},
                {13, {32871}, "algalon-phase2", "Unleashed Dark Matter", "Final phase", {65251, 64450, 64599}, false, "At low health, worm holes summon Unleashed Dark Matter", {34099, 34097}},
                {13, {32871}, "algalon-timer-outro", "One-hour observation window and scripted outro", "Access / outro", {64997, 64986, 64994, 64996}, false, "Keyed access starts a persistent one-hour window; defeat runs a scripted planetary reorigination verdict and gift sequence"}
            }
        }
    };
    return profiles;
}

InstanceProfile const* InstanceProfileCatalog::Find(std::uint32_t mapId)
{
    std::vector<InstanceProfile> const& profiles = All();
    auto found = std::find_if(profiles.begin(), profiles.end(), [mapId](InstanceProfile const& profile) { return profile.mapId == mapId; });
    return found == profiles.end() ? nullptr : &*found;
}

std::uint32_t InstanceProfileCatalog::ScriptEncounterId(std::uint32_t mapId, std::uint32_t catalogueId)
{
    if (InstanceProfile const* profile = Find(mapId))
        for (EncounterIdMapping const& mapping : profile->encounterMappings)
            if (mapping.catalogueId == catalogueId)
                return mapping.scriptId;
    return catalogueId;
}
} // namespace AzerCoreOps
