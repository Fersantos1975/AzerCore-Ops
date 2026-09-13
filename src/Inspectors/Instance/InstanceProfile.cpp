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
                {23, "Remaining Frostwyrms", ProfileSignalKind::Count, false},
                {24, "Spinestalker trash remaining", ProfileSignalKind::Count, false},
                {25, "Rimefang trash remaining", ProfileSignalKind::Count, false},
                {257, "Sindragosa introduction completed", ProfileSignalKind::Boolean, false},
                {255, "Limited attempts enabled", ProfileSignalKind::Boolean, false},
                {29, "Heroic attempts remaining", ProfileSignalKind::Count, true},
                {256, "Heroic Lich King available", ProfileSignalKind::Boolean, true}
            },
            {
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
                {201375, "Valithria entrance", "DOOR", ProfileObjectPolicy::Observe, {9, 10}},
                {201374, "Valithria exit", "DOOR", ProfileObjectPolicy::OpenWhenReady, {10}},
                {201373, "Sindragosa entrance", "DOOR", ProfileObjectPolicy::Observe, {13, 11}},
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
                {3, {37813}, "saurfang-blood-beasts", "Blood Beasts", "Combat", {72172, 72356}, false, "Periodic Blood Beast waves are core encounter adds"},
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
