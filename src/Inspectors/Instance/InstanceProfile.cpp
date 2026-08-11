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
                {"putricide-access", "Professor Putricide access", {4, 5}, 6, "Both Festergut and Rotface plus their valve sequence unlock Putricide"},
                {"frozen-throne-access", "Frozen Throne access", {6, 8, 11}, 12, "Putricide, Lana'thel and Sindragosa remove the three sigils and enable the Lich King transporter"}
            },
            {
                {2, {NOT_STARTED, TO_BE_DECIDED}, "Gunship is initialized by the post-Deathwhisper script", {1}},
                {7, {NOT_STARTED, FAIL, TO_BE_DECIDED}, "Blood Council may enter a reset/initialization state before its trash event completes", {14}},
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
                {201616, "Gas release valve", "VALVE", ProfileObjectPolicy::SelectableWhenReady, {4}},
                {201615, "Ooze release valve", "VALVE", ProfileObjectPolicy::SelectableWhenReady, {5}},
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
