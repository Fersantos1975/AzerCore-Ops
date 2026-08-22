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

struct EncounterCounters
{
    std::uint32_t attempts{0};
    std::uint32_t wipes{0};
    std::uint32_t kills{0};
};

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
    std::string event;
    std::uint32_t attempt{0};
    std::uint32_t wipes{0};
    std::uint32_t kills{0};
    std::string detail;
};

using EncounterCounterMap =
    std::unordered_map<std::uint32_t, EncounterCounters>;

std::unordered_map<
    std::uint32_t,
    std::deque<EncounterHistoryEntry>> HistoryByInstance;

std::unordered_map<
    std::uint32_t,
    EncounterCounterMap> CountersByInstance;

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
    EncounterHistoryEntry const* previous =
        PreviousFor(entries, encounterId);

    if (oldState == TO_BE_DECIDED)
        return {
            "INITIALIZATION",
            "Initial instance-state assignment while the encounter is being loaded"
        };

    if ((oldState == NOT_STARTED || oldState == FAIL) &&
        newState == IN_PROGRESS)
        return {
            "NORMAL",
            "Encounter entered combat from a valid pull-start state"
        };

    if (oldState == IN_PROGRESS && newState == DONE)
        return {
            "NORMAL",
            "Encounter completed after an active pull"
        };

    if (oldState == IN_PROGRESS && newState == FAIL)
        return {
            "NORMAL",
            "Encounter failed directly from an active pull"
        };

    if (oldState == FAIL && newState == NOT_STARTED)
        return {
            "RESET_STEP",
            "Encounter returned to the not-started state after a failed attempt"
        };

    if (oldState == IN_PROGRESS && newState == NOT_STARTED)
        return {
            "RESET_STEP",
            "Encounter reset directly from an active pull; counted as a wipe"
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

EncounterCounters CurrentCounters(
    std::uint32_t instanceId,
    std::uint32_t encounterId)
{
    auto instanceItr = CountersByInstance.find(instanceId);
    if (instanceItr == CountersByInstance.end())
        return {};

    auto encounterItr = instanceItr->second.find(encounterId);
    if (encounterItr == instanceItr->second.end())
        return {};

    return encounterItr->second;
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

    std::deque<EncounterHistoryEntry>& entries =
        HistoryByInstance[instanceId];

    std::uint64_t timestampMs = CurrentTimeMs();

    auto classification =
        ClassifyTransition(
            entries,
            encounterId,
            oldState,
            newState,
            timestampMs);

    EncounterCounters counters =
        CurrentCounters(instanceId, encounterId);

    std::string event = "STATE";

    if (classification.first == "INITIALIZATION")
    {
        event = "INITIALIZATION";
    }
    else if ((oldState == NOT_STARTED || oldState == FAIL) &&
             newState == IN_PROGRESS)
    {
        EncounterCounters& current =
            CountersByInstance[instanceId][encounterId];

        ++current.attempts;
        counters = current;
        event = "PULL";
    }
    else if (oldState == IN_PROGRESS &&
             newState == FAIL)
    {
        EncounterCounters& current =
            CountersByInstance[instanceId][encounterId];

        // If recording started in the middle of an already-active
        // pull, preserve a sensible attempt count.
        if (current.attempts <= current.wipes + current.kills)
            ++current.attempts;

        ++current.wipes;
        counters = current;
        event = "WIPE";
    }
    else if (oldState == IN_PROGRESS &&
             newState == NOT_STARTED)
    {
        EncounterCounters& current =
            CountersByInstance[instanceId][encounterId];

        // Many encounter scripts reset directly from IN_PROGRESS
        // to NOT_STARTED without emitting FAIL. For attempt tracking
        // this is still a failed pull and therefore counts as a wipe.
        if (current.attempts <= current.wipes + current.kills)
            ++current.attempts;

        ++current.wipes;
        counters = current;
        event = "WIPE";
    }
    else if (classification.first == "WIPE_CHAIN")
    {
        // The preceding IN_PROGRESS -> NOT_STARTED transition already
        // counted this failed attempt. Do not increment the wipe twice.
        counters =
            CurrentCounters(instanceId, encounterId);
        event = "RESET";
    }
    else if (oldState == IN_PROGRESS &&
             newState == DONE)
    {
        EncounterCounters& current =
            CountersByInstance[instanceId][encounterId];

        if (current.attempts <= current.wipes + current.kills)
            ++current.attempts;

        ++current.kills;
        counters = current;
        event = "KILL";
    }
    else if (oldState == FAIL &&
             newState == NOT_STARTED)
    {
        counters =
            CurrentCounters(instanceId, encounterId);
        event = "RESET";
    }

    EncounterHistoryEntry entry;
    entry.sequence = ++NextSequence;
    entry.timestampMs = timestampMs;
    entry.mapId = map->GetId();
    entry.instanceId = instanceId;
    entry.difficulty =
        static_cast<std::uint32_t>(map->GetDifficulty());
    entry.encounterId = encounterId;
    entry.oldState = oldState;
    entry.newState = newState;
    entry.classification =
        std::move(classification.first);
    entry.event = std::move(event);
    entry.attempt = counters.attempts;
    entry.wipes = counters.wipes;
    entry.kills = counters.kills;
    entry.detail =
        std::move(classification.second);

    entries.push_back(std::move(entry));

    while (entries.size() > MaxEntriesPerInstance)
        entries.pop_front();
}

void ClearInstance(std::uint32_t instanceId)
{
    std::lock_guard<std::mutex> lock(HistoryMutex);

    HistoryByInstance.erase(instanceId);
    CountersByInstance.erase(instanceId);
}

struct EncounterHistorySnapshot
{
    std::vector<EncounterHistoryEntry> entries;

    std::vector<
        std::pair<
            std::uint32_t,
            EncounterCounters>> counters;
};

EncounterHistorySnapshot Snapshot(
    std::uint32_t instanceId)
{
    std::lock_guard<std::mutex> lock(HistoryMutex);

    EncounterHistorySnapshot snapshot;

    auto historyItr =
        HistoryByInstance.find(instanceId);

    if (historyItr != HistoryByInstance.end())
    {
        snapshot.entries.assign(
            historyItr->second.begin(),
            historyItr->second.end());
    }

    auto countersItr =
        CountersByInstance.find(instanceId);

    if (countersItr != CountersByInstance.end())
    {
        snapshot.counters.reserve(
            countersItr->second.size());

        for (auto const& pair : countersItr->second)
            snapshot.counters.push_back(pair);

        std::sort(
            snapshot.counters.begin(),
            snapshot.counters.end(),
            [](auto const& left, auto const& right)
            {
                return left.first < right.first;
            });
    }

    return snapshot;
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

    if (!map ||
        !map->Instanceable() ||
        !map->GetInstanceId())
    {
        Protocol::SendEncounterHistoryError(
            handler,
            "Enter a dungeon or raid instance before requesting encounter history");
        return true;
    }

    EncounterHistorySnapshot snapshot =
        Snapshot(map->GetInstanceId());

    Protocol::SendEncounterHistoryBegin(
        handler,
        map->GetId(),
        map->GetInstanceId(),
        static_cast<std::uint32_t>(
            map->GetDifficulty()),
        map->GetMapName(),
        static_cast<std::uint32_t>(
            snapshot.entries.size()));

    std::uint32_t anomalies = 0;

    for (EncounterHistoryEntry const& entry :
         snapshot.entries)
    {
        if (entry.classification == "SUSPICIOUS")
            ++anomalies;

        Protocol::SendEncounterHistoryEntry(
            handler,
            entry.sequence,
            entry.timestampMs,
            entry.encounterId,
            ResolveEncounterName(
                map,
                entry.encounterId),
            static_cast<std::uint32_t>(
                entry.oldState),
            InstanceScript::GetBossStateName(
                entry.oldState),
            static_cast<std::uint32_t>(
                entry.newState),
            InstanceScript::GetBossStateName(
                entry.newState),
            entry.classification,
            entry.event,
            entry.attempt,
            entry.wipes,
            entry.kills,
            entry.detail);
    }

    for (auto const& pair :
         snapshot.counters)
    {
        Protocol::SendEncounterHistoryStats(
            handler,
            pair.first,
            ResolveEncounterName(map, pair.first),
            pair.second.attempts,
            pair.second.wipes,
            pair.second.kills);
    }

    Protocol::SendEncounterHistoryEnd(
        handler,
        static_cast<std::uint32_t>(
            snapshot.entries.size()),
        anomalies);

    return true;
}

} // namespace AzerCoreOps

void AddSC_azercore_ops_encounter_history()
{
    new AzerCoreOps::EncounterHistoryScript();
}
