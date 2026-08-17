#include "EncounterHistory.h"

#include "Chat.h"
#include "GlobalScript.h"
#include "InstanceProfile.h"
#include "InstanceScript.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <deque>
#include <mutex>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace AzerCoreOps
{
namespace
{
constexpr std::size_t MaxEntriesPerInstance = 64;
constexpr std::uint64_t WipeChainWindowMs = 10000;

struct EncounterHistoryEntry
{
    std::uint64_t sequence{0};
    std::uint64_t timestampMs{0};
    std::uint32_t mapId{0};
    std::uint32_t instanceId{0};
    std::uint32_t difficulty{0};
    std::uint32_t encounterId{0};
    EncounterState oldState{TO_BE_DECIDED};
    EncounterState newState{TO_BE_DECIDED};
    std::string classification;
    std::string detail;
};

std::unordered_map<std::uint32_t, std::deque<EncounterHistoryEntry>> HistoryByInstance;
std::mutex HistoryMutex;
std::uint64_t NextSequence = 0;

std::uint64_t CurrentTimeMs()
{
    return static_cast<std::uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
}

EncounterHistoryEntry const* PreviousFor(
    std::deque<EncounterHistoryEntry> const& entries,
    std::uint32_t encounterId)
{
    auto itr = std::find_if(
        entries.rbegin(),
        entries.rend(),
        [encounterId](EncounterHistoryEntry const& entry)
        {
            return entry.encounterId == encounterId;
        });

    return itr == entries.rend() ? nullptr : &*itr;
}

std::pair<std::string, std::string> ClassifyTransition(
    std::deque<EncounterHistoryEntry> const& entries,
    std::uint32_t encounterId,
    EncounterState oldState,
    EncounterState newState,
    std::uint64_t timestampMs)
{
    EncounterHistoryEntry const* previous = PreviousFor(entries, encounterId);

    if (oldState == TO_BE_DECIDED)
        return {
            "INITIALIZATION",
            "Initial instance-state assignment while the encounter is being loaded"
        };

    if (oldState == NOT_STARTED && newState == IN_PROGRESS)
        return {
            "NORMAL",
            "Encounter entered combat from the normal not-started state"
        };

    if (oldState == IN_PROGRESS && newState == DONE)
        return {
            "NORMAL",
            "DONE was requested after the encounter had been in progress"
        };

    if (oldState == IN_PROGRESS && newState == FAIL)
        return {
            "NORMAL",
            "Encounter failed directly from an active pull"
        };

    if (oldState == IN_PROGRESS && newState == NOT_STARTED)
        return {
            "RESET_STEP",
            "Encounter left the active state; this may be the first step of normal wipe handling"
        };

    if (oldState == NOT_STARTED && newState == FAIL)
    {
        if (previous &&
            previous->oldState == IN_PROGRESS &&
            previous->newState == NOT_STARTED &&
            timestampMs >= previous->timestampMs &&
            timestampMs - previous->timestampMs <= WipeChainWindowMs)
        {
            return {
                "WIPE_CHAIN",
                "FAIL followed an IN_PROGRESS to NOT_STARTED reset step, consistent with wipe handling"
            };
        }

        return {
            "SUSPICIOUS",
            "FAIL was requested from NOT_STARTED without a preceding active encounter transition"
        };
    }

    if (oldState == DONE && newState != DONE)
        return {
            "SUSPICIOUS",
            "A completed encounter was requested to move back to a non-DONE state"
        };

    return {
        "INFO",
        "State change does not match a universal anomaly rule; review instance-specific scripting if unexpected"
    };
}

void RecordTransition(
    Map* map,
    std::uint32_t encounterId,
    EncounterState newState,
    EncounterState oldState)
{
    if (!map || oldState == newState)
        return;

    std::uint32_t instanceId = map->GetInstanceId();
    if (!instanceId)
        return;

    std::lock_guard<std::mutex> lock(HistoryMutex);

    std::deque<EncounterHistoryEntry>& entries = HistoryByInstance[instanceId];
    std::uint64_t timestampMs = CurrentTimeMs();
    auto classification = ClassifyTransition(entries, encounterId, oldState, newState, timestampMs);

    EncounterHistoryEntry entry;
    entry.sequence = ++NextSequence;
    entry.timestampMs = timestampMs;
    entry.mapId = map->GetId();
    entry.instanceId = instanceId;
    entry.difficulty = static_cast<std::uint32_t>(map->GetDifficulty());
    entry.encounterId = encounterId;
    entry.oldState = oldState;
    entry.newState = newState;
    entry.classification = std::move(classification.first);
    entry.detail = std::move(classification.second);

    entries.push_back(std::move(entry));

    while (entries.size() > MaxEntriesPerInstance)
        entries.pop_front();
}

void ClearInstance(std::uint32_t instanceId)
{
    std::lock_guard<std::mutex> lock(HistoryMutex);
    HistoryByInstance.erase(instanceId);
}

std::vector<EncounterHistoryEntry> Snapshot(std::uint32_t instanceId)
{
    std::lock_guard<std::mutex> lock(HistoryMutex);

    auto itr = HistoryByInstance.find(instanceId);
    if (itr == HistoryByInstance.end())
        return {};

    return {itr->second.begin(), itr->second.end()};
}

std::string ResolveEncounterName(Map* map, std::uint32_t scriptId)
{
    if (!map)
        return "Encounter " + std::to_string(scriptId);

    std::uint32_t mapId = map->GetId();

    if (InstanceProfile const* profile = InstanceProfileCatalog::Find(mapId))
    {
        for (RuntimeStateDefinition const& runtimeState : profile->runtimeStates)
            if (runtimeState.scriptId == scriptId)
                return runtimeState.name;
    }

    Difficulty difficulty = map->GetDifficulty();
    DungeonEncounterList const* source = nullptr;

    if ((mapId == 631 || mapId == 724) &&
        (difficulty == RAID_DIFFICULTY_10MAN_HEROIC ||
         difficulty == RAID_DIFFICULTY_25MAN_HEROIC))
    {
        source = sObjectMgr->GetDungeonEncounterList(
            mapId,
            difficulty == RAID_DIFFICULTY_10MAN_HEROIC
                ? RAID_DIFFICULTY_10MAN_NORMAL
                : RAID_DIFFICULTY_25MAN_NORMAL);
    }
    else
    {
        source = sObjectMgr->GetDungeonEncounterList(mapId, difficulty);
    }

    if (source)
    {
        for (DungeonEncounter const* encounter : *source)
        {
            if (!encounter || !encounter->dbcEntry)
                continue;

            std::uint32_t catalogueId = encounter->dbcEntry->encounterIndex;
            std::uint32_t mappedId =
                InstanceProfileCatalog::ScriptEncounterId(mapId, catalogueId);

            if (mappedId != scriptId)
                continue;

            char const* name = encounter->dbcEntry->encounterName[0];
            if (name && *name)
                return name;
        }
    }

    return "Encounter " + std::to_string(scriptId);
}

class EncounterHistoryScript : public GlobalScript
{
public:
    EncounterHistoryScript()
        : GlobalScript(
            "AzerCoreOpsEncounterHistoryScript",
            {
                GLOBALHOOK_ON_INSTANCEID_REMOVED,
                GLOBALHOOK_ON_BEFORE_SET_BOSS_STATE
            })
    {
    }

    void OnBeforeSetBossState(
        std::uint32_t id,
        EncounterState newState,
        EncounterState oldState,
        Map* instance) override
    {
        RecordTransition(instance, id, newState, oldState);
    }

    void OnInstanceIdRemoved(std::uint32_t instanceId) override
    {
        ClearInstance(instanceId);
    }
};
} // namespace

bool EncounterHistory::Show(ChatHandler* handler)
{
    if (!handler || !handler->GetPlayer())
    {
        Protocol::SendEncounterHistoryError(
            handler,
            "Encounter history requires an in-game player session");
        return true;
    }

    Player* player = handler->GetPlayer();
    Map* map = player->GetMap();

    if (!map || !map->Instanceable() || !map->GetInstanceId())
    {
        Protocol::SendEncounterHistoryError(
            handler,
            "Enter a dungeon or raid instance before requesting encounter history");
        return true;
    }

    std::vector<EncounterHistoryEntry> entries = Snapshot(map->GetInstanceId());

    Protocol::SendEncounterHistoryBegin(
        handler,
        map->GetId(),
        map->GetInstanceId(),
        static_cast<std::uint32_t>(map->GetDifficulty()),
        map->GetMapName(),
        static_cast<std::uint32_t>(entries.size()));

    std::uint32_t anomalies = 0;

    for (EncounterHistoryEntry const& entry : entries)
    {
        if (entry.classification == "SUSPICIOUS")
            ++anomalies;

        Protocol::SendEncounterHistoryEntry(
            handler,
            entry.sequence,
            entry.timestampMs,
            entry.encounterId,
            ResolveEncounterName(map, entry.encounterId),
            static_cast<std::uint32_t>(entry.oldState),
            InstanceScript::GetBossStateName(entry.oldState),
            static_cast<std::uint32_t>(entry.newState),
            InstanceScript::GetBossStateName(entry.newState),
            entry.classification,
            entry.detail);
    }

    Protocol::SendEncounterHistoryEnd(
        handler,
        static_cast<std::uint32_t>(entries.size()),
        anomalies);

    return true;
}
} // namespace AzerCoreOps

void AddSC_azercore_ops_encounter_history()
{
    new AzerCoreOps::EncounterHistoryScript();
}
