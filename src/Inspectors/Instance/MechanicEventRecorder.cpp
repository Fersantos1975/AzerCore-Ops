#include "MechanicEventRecorder.h"

#include "AllCreatureScript.h"
#include "AllGameObjectScript.h"
#include "AllSpellScript.h"
#include "AllMapScript.h"
#include "SpellAuras.h"
#include "Chat.h"
#include "Creature.h"
#include "GameObject.h"
#include "InstanceProfile.h"
#include "InstanceScript.h"
#include "Map.h"
#include "Player.h"
#include "PlayerScript.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "Protocol/ChatProtocol.h"
#include "Unit.h"
#include "UnitScript.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <deque>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace AzerCoreOps
{
namespace
{
constexpr std::size_t MaxEventsPerInstance = 4096;
constexpr std::uint32_t SignalSampleIntervalMs = 500;

struct ActiveEncounter
{
    std::uint32_t mapId{0};
    std::uint32_t encounterId{0};
    std::uint64_t startedAtMs{0};
};

struct InstanceJourney
{
    std::uint32_t mapId{0};
    std::uint64_t startedAtMs{0};
    std::unordered_set<std::uint64_t> seenPlayers;
    std::unordered_set<std::uint64_t> presentPlayers;
};

struct MechanicEvent
{
    std::uint64_t sequence{0};
    std::uint64_t timestampMs{0};
    std::uint64_t elapsedMs{0};
    std::uint32_t encounterId{0};
    std::string type;
    std::uint32_t creatureEntry{0};
    std::uint64_t creatureGuid{0};
    std::string creatureName;
    std::string mechanicId;
    std::string mechanicName;
    std::string phase;
    std::string detail;
};

std::unordered_map<std::uint32_t, ActiveEncounter> ActiveByInstance;
std::unordered_map<std::uint32_t, InstanceJourney> JourneyByInstance;
std::unordered_map<std::uint64_t, std::uint32_t> LastInstanceByPlayer;
std::unordered_map<std::uint32_t, std::deque<MechanicEvent>> EventsByInstance;
std::unordered_map<std::uint32_t, std::unordered_map<std::uint64_t, std::uint32_t>> ObjectStatesByInstance;
std::unordered_map<std::uint32_t, std::unordered_map<std::uint32_t, std::string>> PhasesByInstance;
std::unordered_map<std::uint32_t, std::unordered_map<std::uint32_t, std::uint32_t>> SignalsByInstance;
std::unordered_map<std::uint32_t, std::uint32_t> SignalSampleElapsedByInstance;
std::mutex EventMutex;
std::uint64_t NextMechanicSequence = 0;

std::uint64_t CurrentTimeMs()
{
    return static_cast<std::uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
}

void Append(std::uint32_t instanceId, ActiveEncounter const& active, MechanicEvent event)
{
    event.sequence = ++NextMechanicSequence;
    event.timestampMs = CurrentTimeMs();
    event.elapsedMs = event.timestampMs >= active.startedAtMs
        ? event.timestampMs - active.startedAtMs
        : 0;
    event.encounterId = active.encounterId;

    std::deque<MechanicEvent>& events = EventsByInstance[instanceId];
    events.push_back(std::move(event));
    while (events.size() > MaxEventsPerInstance)
        events.pop_front();
}

bool IsProfiledInstance(Map* map)
{
    return map &&
        map->GetInstanceId() &&
        map->Instanceable() &&
        InstanceProfileCatalog::Find(map->GetId());
}

// Player-owned combat helpers are useful gameplay context, but they are not
// instance mechanics. Keep boss-owned summons: only reject units controlled
// by, created by, owned by, or charmed by a player (plus all totems).
bool IsPlayerControlledHelper(Unit const* unit)
{
    if (!unit)
        return false;

    Creature const* creature = unit->ToCreature();
    return unit->IsControlledByPlayer() ||
        unit->IsCreatedByPlayer() ||
        unit->GetOwnerGUID().IsPlayer() ||
        unit->GetCharmerGUID().IsPlayer() ||
        (creature && creature->IsTotem());
}

void AppendJourneyEventLocked(
    std::uint32_t instanceId,
    Player* player,
    char const* type,
    char const* detail)
{
    auto journeyItr = JourneyByInstance.find(instanceId);
    if (journeyItr == JourneyByInstance.end())
        return;

    ActiveEncounter context;
    context.mapId = journeyItr->second.mapId;
    context.startedAtMs = journeyItr->second.startedAtMs;

    MechanicEvent event;
    event.type = type;
    if (player)
    {
        event.creatureGuid = player->GetGUID().GetCounter();
        event.creatureName = player->GetName();
    }
    event.mechanicId = "instance-journey";
    event.mechanicName = "Instance Journey";
    event.phase = "Instance";
    event.detail = detail;
    Append(instanceId, context, std::move(event));
}

void RecordPlayerLifecycle(Player* player, char const* type, char const* detail)
{
    if (!player)
        return;

    std::uint64_t playerGuid = player->GetGUID().GetCounter();
    std::lock_guard<std::mutex> lock(EventMutex);

    std::uint32_t instanceId = 0;
    if (Map* map = player->GetMap(); IsProfiledInstance(map))
        instanceId = map->GetInstanceId();
    else if (auto found = LastInstanceByPlayer.find(playerGuid);
             found != LastInstanceByPlayer.end())
        instanceId = found->second;

    if (!instanceId || JourneyByInstance.find(instanceId) == JourneyByInstance.end())
        return;

    AppendJourneyEventLocked(instanceId, player, type, detail);
}

EncounterMechanic const* FindObservedMechanic(
    Map* map,
    std::uint32_t encounterId,
    std::uint32_t creatureEntry)
{
    if (!map)
        return nullptr;

    InstanceProfile const* profile = InstanceProfileCatalog::Find(map->GetId());
    if (!profile)
        return nullptr;

    auto found = std::find_if(
        profile->mechanics.begin(),
        profile->mechanics.end(),
        [map, encounterId, creatureEntry](EncounterMechanic const& mechanic)
        {
            return mechanic.encounter == encounterId &&
                (!mechanic.heroicOnly || map->IsHeroic()) &&
                std::find(
                    mechanic.observedCreatureEntries.begin(),
                    mechanic.observedCreatureEntries.end(),
                    creatureEntry) != mechanic.observedCreatureEntries.end();
        });

    return found == profile->mechanics.end() ? nullptr : &*found;
}

void RecordSpellCast(Unit* caster, SpellInfo const* spellInfo)
{
    if (!caster || !spellInfo || IsPlayerControlledHelper(caster))
        return;
    Map* map = caster->FindMap();
    if (!IsProfiledInstance(map))
        return;
    InstanceProfile const* profile = InstanceProfileCatalog::Find(map->GetId());
    std::uint32_t instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(EventMutex);
    auto active = ActiveByInstance.find(instanceId);
    if (active == ActiveByInstance.end())
        return;

    bool profileMatched = false;
    for (EncounterMechanic const& mechanic : profile->mechanics)
    {
        if (mechanic.encounter != active->second.encounterId ||
            (mechanic.heroicOnly && !map->IsHeroic()))
            continue;

        bool matched = std::any_of(mechanic.spellIds.begin(), mechanic.spellIds.end(),
            [caster, spellInfo](std::uint32_t id)
            {
                return spellInfo->Id == id ||
                    spellInfo->Id == sSpellMgr->GetSpellIdForDifficulty(id, caster);
            });
        if (!matched)
            continue;

        MechanicEvent event;
        event.type = "MECHANIC_CAST";
        event.creatureEntry = caster->ToCreature() ? caster->ToCreature()->GetEntry() : 0;
        event.creatureGuid = caster->GetGUID().GetCounter();
        event.creatureName = caster->GetName();
        event.mechanicId = mechanic.id;
        event.mechanicName = mechanic.name;
        event.phase = mechanic.phase;
        event.detail = "Observed spell cast ID " + std::to_string(spellInfo->Id);
        Append(instanceId, active->second, std::move(event));
        profileMatched = true;

        // A mechanic's phase is an observed hint, not proof of the script's
        // private phase transition. Emit only when its label changes.
        if (!mechanic.phase.empty() && PhasesByInstance[instanceId][mechanic.encounter] != mechanic.phase)
        {
            PhasesByInstance[instanceId][mechanic.encounter] = mechanic.phase;
            MechanicEvent phase;
            phase.type = "PHASE_HINT";
            phase.mechanicId = mechanic.id;
            phase.mechanicName = mechanic.name;
            phase.phase = mechanic.phase;
            phase.detail = "Phase inferred from an observed mechanic cast; script phase was not sampled";
            Append(instanceId, active->second, std::move(phase));
        }
        break;
    }

    if (!profileMatched && caster->ToCreature() && !caster->ToCreature()->IsTrigger())
    {
        MechanicEvent event;
        event.type = "SCRIPT_CAST";
        event.creatureEntry = caster->ToCreature()->GetEntry();
        event.creatureGuid = caster->GetGUID().GetCounter();
        event.creatureName = caster->GetName();
        event.mechanicId = "profile-spell-" + std::to_string(spellInfo->Id);
        event.mechanicName = "Profiled Instance Script Spell";
        auto phase = PhasesByInstance[instanceId].find(active->second.encounterId);
        if (phase != PhasesByInstance[instanceId].end())
            event.phase = phase->second;
        event.detail = "Observed profiled-instance encounter cast not yet assigned to a named profile mechanic; spell ID " +
            std::to_string(spellInfo->Id);
        Append(instanceId, active->second, std::move(event));
    }
}

void RecordAura(Unit* target, SpellInfo const* spellInfo, char const* type)
{
    if (!target || !spellInfo)
        return;

    Map* map = target->FindMap();
    if (!IsProfiledInstance(map))
        return;

    InstanceProfile const* profile = InstanceProfileCatalog::Find(map->GetId());
    std::uint32_t instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(EventMutex);
    auto active = ActiveByInstance.find(instanceId);
    if (active == ActiveByInstance.end())
        return;

    for (EncounterMechanic const& mechanic : profile->mechanics)
    {
        if (mechanic.encounter != active->second.encounterId ||
            (mechanic.heroicOnly && !map->IsHeroic()))
            continue;

        bool matched = std::any_of(
            mechanic.spellIds.begin(),
            mechanic.spellIds.end(),
            [target, spellInfo](std::uint32_t id)
            {
                return spellInfo->Id == id ||
                    spellInfo->Id == sSpellMgr->GetSpellIdForDifficulty(id, target);
            });
        if (!matched)
            continue;

        MechanicEvent event;
        event.type = type;
        event.creatureEntry = target->ToCreature() ? target->ToCreature()->GetEntry() : 0;
        event.creatureGuid = target->GetGUID().GetCounter();
        event.creatureName = target->GetName();
        event.mechanicId = mechanic.id;
        event.mechanicName = mechanic.name;
        event.phase = mechanic.phase;
        event.detail = "Observed aura spell ID " + std::to_string(spellInfo->Id);
        Append(instanceId, active->second, std::move(event));
        break;
    }
}

void RecordRuntimeSignals(Map* map, std::uint32_t diff)
{
    if (!IsProfiledInstance(map))
        return;

    InstanceProfile const* profile = InstanceProfileCatalog::Find(map->GetId());
    InstanceMap* instanceMap = map->ToInstanceMap();
    InstanceScript* script = instanceMap ? instanceMap->GetInstanceScript() : nullptr;
    if (!profile || !script || profile->signals.empty())
        return;

    std::uint32_t instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(EventMutex);
    std::uint32_t& elapsed = SignalSampleElapsedByInstance[instanceId];
    elapsed += diff;
    if (elapsed < SignalSampleIntervalMs)
        return;
    elapsed = 0;

    auto journey = JourneyByInstance.find(instanceId);
    ActiveEncounter context;
    context.mapId = map->GetId();
    context.startedAtMs = journey != JourneyByInstance.end()
        ? journey->second.startedAtMs : CurrentTimeMs();
    auto active = ActiveByInstance.find(instanceId);
    if (active != ActiveByInstance.end())
        context = active->second;

    auto& previous = SignalsByInstance[instanceId];
    for (ProfileSignal const& signal : profile->signals)
    {
        if (signal.heroicOnly && !map->IsHeroic())
            continue;

        std::uint32_t value = script->GetData(signal.dataId);
        auto old = previous.find(signal.dataId);
        if (old == previous.end())
        {
            previous[signal.dataId] = value;
            continue;
        }
        if (old->second == value)
            continue;

        std::uint32_t before = old->second;
        old->second = value;
        MechanicEvent event;
        event.type = "INSTANCE_SIGNAL";
        event.mechanicId = "profile-runtime-signal-" + std::to_string(signal.dataId);
        event.mechanicName = signal.name;
        event.phase = "Instance Progression";
        event.detail = "Observed authoritative instance signal " +
            std::to_string(signal.dataId) + ": " +
            std::to_string(before) + " -> " + std::to_string(value);
        Append(instanceId, context, std::move(event));
    }
}

void RecordObject(GameObject* object, std::uint32_t state)
{
    if (!object || !IsProfiledInstance(object->FindMap()))
        return;
    Map* map = object->FindMap();
    InstanceProfile const* profile = InstanceProfileCatalog::Find(map->GetId());
    auto found = std::find_if(profile->objects.begin(), profile->objects.end(),
        [object](ProfileObject const& candidate) { return candidate.entry == object->GetEntry(); });
    if (found == profile->objects.end())
        return;

    std::uint32_t instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(EventMutex);
    auto& previous = ObjectStatesByInstance[instanceId];
    std::uint64_t guid = object->GetGUID().GetCounter();
    auto old = previous.find(guid);
    if (old != previous.end() && old->second == state)
        return;
    bool initial = old == previous.end();
    previous[guid] = state;

    ActiveEncounter context;
    context.mapId = map->GetId();
    auto journey = JourneyByInstance.find(instanceId);
    context.startedAtMs = journey != JourneyByInstance.end()
        ? journey->second.startedAtMs : CurrentTimeMs();
    auto active = ActiveByInstance.find(instanceId);
    if (active != ActiveByInstance.end())
        context = active->second;

    MechanicEvent event;
    event.type = initial ? "OBJECT_OBSERVED" : "OBJECT_STATE";
    event.creatureEntry = object->GetEntry();
    event.creatureGuid = guid;
    event.creatureName = found->name;
    event.mechanicId = "profile-object";
    event.mechanicName = found->category;
    event.phase = "Instance Progression";
    event.detail = "Observed physical gameobject state " + std::to_string(state) +
        (initial ? " on load" : " after a state change") +
        "; 0=active/open for a standard door, 1=ready/closed; other object types may differ";
    Append(instanceId, context, std::move(event));
}

bool HasEncounter(
    std::vector<std::uint32_t> const& encounters,
    std::uint32_t encounterId)
{
    return std::find(encounters.begin(), encounters.end(), encounterId) !=
        encounters.end();
}

void AppendProfileObjectStateEvents(
    Map* map,
    std::uint32_t encounterId,
    EncounterState newState,
    ActiveEncounter const& context)
{
    InstanceProfile const* profile =
        map ? InstanceProfileCatalog::Find(map->GetId()) : nullptr;
    if (!profile)
        return;

    for (ProfileObject const& object : profile->objects)
    {
        bool passage = HasEncounter(
            object.passageEncounters,
            encounterId);
        bool room = HasEncounter(
            object.roomEncounters,
            encounterId);
        if (!passage && !room)
            continue;

        char const* type = nullptr;
        char const* detail = nullptr;
        char const* phase = nullptr;

        if (passage)
        {
            phase = "Progression Gate";
            if (newState == IN_PROGRESS)
            {
                type = "DOOR_BLOCKED";
                detail = "Passage remains locked by this prerequisite; physical gameobject state was not sampled";
            }
            else if (newState == DONE)
            {
                type = "DOOR_OPENED";
                detail = "Script-linked passage should open after prerequisite completion; "
                    "physical gameobject state was not sampled";
            }
        }
        else if (room)
        {
            phase = "Encounter Room";
            if (newState == IN_PROGRESS)
            {
                type = "DOOR_CLOSED";
                detail = "Script-linked room door should close for combat; physical gameobject state was not sampled";
            }
            else if (newState == DONE ||
                     newState == FAIL ||
                     newState == NOT_STARTED)
            {
                type = "DOOR_OPENED";
                detail = newState == DONE
                    ? "Script-linked room door should reopen after completion; "
                        "physical gameobject state was not sampled"
                    : "Script-linked room door should reopen after combat ended; "
                        "physical gameobject state was not sampled";
            }
        }

        if (!type)
            continue;

        MechanicEvent event;
        event.type = type;
        event.creatureEntry = object.entry;
        event.creatureName = object.name;
        event.mechanicId = "profile-object-state";
        event.mechanicName = "Instance Door";
        event.phase = phase;
        event.detail = detail;
        Append(map->GetInstanceId(), context, std::move(event));
    }
}

struct ProgressionCreature
{
    std::uint32_t entry;
    std::uint32_t encounter;
    char const* stage;
};

constexpr ProgressionCreature IccProgressionCreatures[] = {
    {37126, 9, "Sister Svalna"},
    {37129, 9, "Crok Scourgebane"},
    {37228, 13, "Frostwing gauntlet"},
    {37229, 13, "Frostwing gauntlet"},
    {37232, 13, "Frostwing gauntlet"},
    {37531, 13, "Frostwyrm trash"},
    {37533, 11, "Rimefang"},
    {37534, 11, "Spinestalker"}
};

void RecordCreatureEvent(Creature* creature, char const* type, char const* detail)
{
    if (!creature || !creature->FindMap())
        return;

    Map* map = creature->FindMap();
    std::uint32_t instanceId = map->GetInstanceId();
    if (!instanceId)
        return;

    std::lock_guard<std::mutex> lock(EventMutex);
    auto activeItr = ActiveByInstance.find(instanceId);
    EncounterMechanic const* mechanic = activeItr != ActiveByInstance.end()
        ? FindObservedMechanic(map, activeItr->second.encounterId, creature->GetEntry()) : nullptr;

    std::uint32_t stageId = 0;
    std::string stage;
    InstanceProfile const* profile = InstanceProfileCatalog::Find(map->GetId());
    if (!profile)
        return;
    if (!mechanic && map->GetId() == 631)
    {
        for (ProfilePrerequisiteCreature const& candidate : profile->prerequisiteCreatures)
            if (candidate.creatureEntry == creature->GetEntry() &&
                candidate.spawnId == creature->GetSpawnId())
            {
                stageId = candidate.progressionState;
                stage = "Blood Prince trash";
                break;
            }
        if (!stageId)
            for (ProgressionCreature const& candidate : IccProgressionCreatures)
                if (candidate.entry == creature->GetEntry())
                {
                    stageId = candidate.encounter;
                    stage = candidate.stage;
                    break;
                }
    }
    bool genericProfileDeath =
        !mechanic &&
        !stageId &&
        std::string(type) == "NPC_DEATH" &&
        !creature->IsTrigger() &&
        !creature->IsPet() &&
        !creature->IsCritter() &&
        !IsPlayerControlledHelper(creature);

    bool genericProfileSpawn =
        !mechanic &&
        !stageId &&
        activeItr != ActiveByInstance.end() &&
        std::string(type) == "NPC_SPAWN" &&
        !creature->IsTrigger() &&
        !creature->IsPet() &&
        !creature->IsCritter() &&
        !IsPlayerControlledHelper(creature);

    if (!mechanic && !stageId && !genericProfileDeath && !genericProfileSpawn)
        return;

    if (genericProfileDeath || genericProfileSpawn)
        stage = profile->name +
            (creature->IsSummon() ? " Encounter Add" : " Trash Progression");

    ActiveEncounter context;
    if (activeItr != ActiveByInstance.end())
        context = activeItr->second;
    else
    {
        auto journey = JourneyByInstance.find(instanceId);
        context.mapId = map->GetId();
        context.encounterId = stageId;
        context.startedAtMs = journey != JourneyByInstance.end()
            ? journey->second.startedAtMs : CurrentTimeMs();
    }

    MechanicEvent event;
    event.type = type;
    event.creatureEntry = creature->GetEntry();
    event.creatureGuid = creature->GetGUID().GetCounter();
    event.creatureName = creature->GetName();
    event.mechanicId = mechanic ? mechanic->id : "profile-progression-creature";
    event.mechanicName = mechanic ? mechanic->name : stage;
    event.phase = mechanic ? mechanic->phase : stage;
    event.detail = mechanic ? detail : "Observed progression NPC lifecycle; completion is determined by the instance script";
    Append(instanceId, context, std::move(event));
}

void RecordValveInteraction(GameObject* object, std::uint32_t state, Unit* user)
{
    if (!object || state != GO_ACTIVATED ||
        (object->GetEntry() != 201616 && object->GetEntry() != 201615) ||
        !IsProfiledInstance(object->FindMap()))
        return;

    std::uint32_t instanceId = object->FindMap()->GetInstanceId();
    std::lock_guard<std::mutex> lock(EventMutex);
    ActiveEncounter context;
    context.mapId = object->FindMap()->GetId();
    auto journey = JourneyByInstance.find(instanceId);
    context.startedAtMs = journey != JourneyByInstance.end()
        ? journey->second.startedAtMs : CurrentTimeMs();

    MechanicEvent event;
    event.type = "VALVE_ACTIVATED";
    event.creatureEntry = object->GetEntry();
    event.creatureGuid = object->GetGUID().GetCounter();
    event.creatureName = object->GetEntry() == 201616 ? "Gas release valve" : "Ooze release valve";
    event.mechanicId = "icc-plagueworks-valve";
    event.mechanicName = "Putricide airlock";
    event.phase = "Plagueworks";
    event.detail = "Observed gameobject activation" +
        std::string(user ? " by " + user->GetName() : "; activating unit unavailable");
    Append(instanceId, context, std::move(event));
}

class MechanicSpellScript : public AllSpellScript
{
public:
    MechanicSpellScript()
        : AllSpellScript("AzerCoreOpsMechanicSpellScript", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* /*spell*/, Unit* caster, SpellInfo const* info, bool /*skipCheck*/) override
    {
        RecordSpellCast(caster, info);
    }
};

class MechanicObjectScript : public AllGameObjectScript
{
public:
    MechanicObjectScript() : AllGameObjectScript("AzerCoreOpsMechanicObjectScript") { }

    void OnGameObjectAddWorld(GameObject* object) override
    {
        RecordObject(object, object->GetGoState());
    }

    void OnGameObjectStateChanged(GameObject* object, std::uint32_t state) override
    {
        RecordObject(object, state);
    }

    void OnGameObjectLootStateChanged(GameObject* object, std::uint32_t state, Unit* user) override
    {
        RecordValveInteraction(object, state, user);
    }

    void OnGameObjectRemoveWorld(GameObject* object) override
    {
        if (!object || !IsProfiledInstance(object->FindMap()))
            return;
        std::lock_guard<std::mutex> lock(EventMutex);
        auto found = ObjectStatesByInstance.find(object->FindMap()->GetInstanceId());
        if (found != ObjectStatesByInstance.end())
            found->second.erase(object->GetGUID().GetCounter());
    }
};

class MechanicCreatureScript : public AllCreatureScript
{
public:
    MechanicCreatureScript() : AllCreatureScript("AzerCoreOpsMechanicCreatureScript") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        MechanicEventRecorder::OnCreatureSpawn(creature);
    }
};

class MechanicUnitScript : public UnitScript
{
public:
    MechanicUnitScript()
        : UnitScript(
            "AzerCoreOpsMechanicUnitScript",
            true,
            {
                UNITHOOK_ON_AURA_APPLY,
                UNITHOOK_ON_AURA_REMOVE,
                UNITHOOK_ON_UNIT_DEATH
            })
    {
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        RecordAura(unit, aura ? aura->GetSpellInfo() : nullptr, "AURA_APPLIED");
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode /*mode*/) override
    {
        RecordAura(
            unit,
            application && application->GetBase()
                ? application->GetBase()->GetSpellInfo()
                : nullptr,
            "AURA_REMOVED");
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        MechanicEventRecorder::OnUnitDeath(unit);
    }
};

class MechanicMapScript : public AllMapScript
{
public:
    MechanicMapScript()
        : AllMapScript(
            "AzerCoreOpsMechanicMapScript",
            {
                ALLMAPHOOK_ON_PLAYER_ENTER_ALL,
                ALLMAPHOOK_ON_PLAYER_LEAVE_ALL,
                ALLMAPHOOK_ON_MAP_UPDATE
            })
    {
    }

    void OnPlayerEnterAll(Map* map, Player* player) override
    {
        MechanicEventRecorder::OnPlayerEnter(map, player);
    }

    void OnPlayerLeaveAll(Map* map, Player* player) override
    {
        MechanicEventRecorder::OnPlayerLeave(map, player);
    }

    void OnMapUpdate(Map* map, std::uint32_t diff) override
    {
        RecordRuntimeSignals(map, diff);
    }
};

class MechanicPlayerScript : public PlayerScript
{
public:
    MechanicPlayerScript()
        : PlayerScript(
            "AzerCoreOpsMechanicPlayerScript",
            {
                PLAYERHOOK_ON_PLAYER_RELEASED_GHOST,
                PLAYERHOOK_ON_PLAYER_RESURRECT
            })
    {
    }

    void OnPlayerReleasedGhost(Player* player) override
    {
        MechanicEventRecorder::OnPlayerReleasedGhost(player);
    }

    void OnPlayerResurrect(
        Player* player,
        float /*restorePercent*/,
        bool& /*applySickness*/) override
    {
        MechanicEventRecorder::OnPlayerResurrect(player);
    }
};
}

void MechanicEventRecorder::OnEncounterState(
    Map* map,
    std::uint32_t encounterId,
    EncounterState newState,
    EncounterState oldState)
{
    if (!map || !map->GetInstanceId() || newState == oldState)
        return;

    std::uint32_t instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(EventMutex);

    if (newState == IN_PROGRESS)
    {
        ActiveEncounter active;
        active.mapId = map->GetId();
        active.encounterId = encounterId;
        active.startedAtMs = CurrentTimeMs();
        ActiveByInstance[instanceId] = active;
        PhasesByInstance[instanceId].erase(encounterId);

        MechanicEvent event;
        event.type = "ENCOUNTER_START";
        event.detail = "Automatic detailed recording started from the encounter state transition";
        Append(instanceId, active, std::move(event));
        AppendProfileObjectStateEvents(
            map,
            encounterId,
            newState,
            active);
        return;
    }

    auto activeItr = ActiveByInstance.find(instanceId);
    if (activeItr == ActiveByInstance.end() ||
        activeItr->second.encounterId != encounterId)
        return;

    if (oldState == IN_PROGRESS &&
        (newState == DONE || newState == FAIL || newState == NOT_STARTED))
    {
        MechanicEvent event;
        event.type = newState == DONE ? "ENCOUNTER_KILL" : "ENCOUNTER_END";
        event.detail = newState == DONE
            ? "Automatic detailed recording completed with a kill"
            : "Automatic detailed recording stopped after a wipe or reset";
        Append(instanceId, activeItr->second, std::move(event));
        AppendProfileObjectStateEvents(
            map,
            encounterId,
            newState,
            activeItr->second);
        ActiveByInstance.erase(activeItr);
    }
}

void MechanicEventRecorder::OnCreatureSpawn(Creature* creature)
{
    RecordCreatureEvent(
        creature,
        "NPC_SPAWN",
        "Profile-matched encounter NPC spawned");
}

void MechanicEventRecorder::OnUnitDeath(Unit* unit)
{
    if (!unit)
        return;

    if (Player* player = unit->ToPlayer())
    {
        RecordPlayerLifecycle(
            player,
            "PLAYER_DIED",
            "Player died; the instance journey remains active");
        return;
    }

    RecordCreatureEvent(
        unit->ToCreature(),
        "NPC_DEATH",
        "Profile-matched encounter NPC died");
}

void MechanicEventRecorder::OnPlayerEnter(Map* map, Player* player)
{
    if (!IsProfiledInstance(map) || !player)
        return;

    std::uint32_t instanceId = map->GetInstanceId();
    std::uint64_t playerGuid = player->GetGUID().GetCounter();
    std::lock_guard<std::mutex> lock(EventMutex);

    auto [journeyItr, inserted] =
        JourneyByInstance.try_emplace(instanceId);
    InstanceJourney& journey = journeyItr->second;
    if (inserted)
    {
        journey.mapId = map->GetId();
        journey.startedAtMs = CurrentTimeMs();
    }

    bool returning = journey.seenPlayers.find(playerGuid) !=
        journey.seenPlayers.end();
    journey.seenPlayers.insert(playerGuid);
    journey.presentPlayers.insert(playerGuid);
    LastInstanceByPlayer[playerGuid] = instanceId;

    AppendJourneyEventLocked(
        instanceId,
        player,
        returning ? "PLAYER_RETURNED" : "INSTANCE_ENTER",
        returning
            ? "Player returned to the same profiled Instance ID; recording can resume"
            : "Player entered a profiled instance; instance journey context created");
}

void MechanicEventRecorder::OnPlayerLeave(Map* map, Player* player)
{
    if (!map || !player || !map->GetInstanceId())
        return;

    std::uint32_t instanceId = map->GetInstanceId();
    std::uint64_t playerGuid = player->GetGUID().GetCounter();
    std::lock_guard<std::mutex> lock(EventMutex);

    auto journeyItr = JourneyByInstance.find(instanceId);
    if (journeyItr == JourneyByInstance.end())
        return;

    AppendJourneyEventLocked(
        instanceId,
        player,
        "PLAYER_LEFT",
        "Player left the instance; the journey is suspended rather than finalized");
    journeyItr->second.presentPlayers.erase(playerGuid);
    LastInstanceByPlayer[playerGuid] = instanceId;
}

void MechanicEventRecorder::OnPlayerReleasedGhost(Player* player)
{
    RecordPlayerLifecycle(
        player,
        "SPIRIT_RELEASED",
        "Player released spirit; recording remains attached to the same instance journey");
}

void MechanicEventRecorder::OnPlayerResurrect(Player* player)
{
    RecordPlayerLifecycle(
        player,
        "PLAYER_RESURRECTED",
        "Player resurrected; instance journey recording continues");
}

void MechanicEventRecorder::Clear(std::uint32_t instanceId)
{
    std::lock_guard<std::mutex> lock(EventMutex);
    ActiveByInstance.erase(instanceId);
    ObjectStatesByInstance.erase(instanceId);
    PhasesByInstance.erase(instanceId);
    SignalsByInstance.erase(instanceId);
    SignalSampleElapsedByInstance.erase(instanceId);
    JourneyByInstance.erase(instanceId);
    EventsByInstance.erase(instanceId);
    for (auto itr = LastInstanceByPlayer.begin();
         itr != LastInstanceByPlayer.end();)
    {
        if (itr->second == instanceId)
            itr = LastInstanceByPlayer.erase(itr);
        else
            ++itr;
    }
}

std::uint32_t MechanicEventRecorder::Show(
    ChatHandler* handler,
    std::uint32_t requestId,
    Map* map)
{
    if (!handler || !map || !map->GetInstanceId())
        return 0;

    std::vector<MechanicEvent> snapshot;
    {
        std::lock_guard<std::mutex> lock(EventMutex);
        auto found = EventsByInstance.find(map->GetInstanceId());
        if (found != EventsByInstance.end())
            snapshot.assign(found->second.begin(), found->second.end());
    }

    std::uint64_t requesterGuid = handler->GetPlayer()
        ? handler->GetPlayer()->GetGUID().GetCounter()
        : 0;
    std::uint32_t visibleCount = 0;

    for (MechanicEvent const& event : snapshot)
    {
        if (event.mechanicId == "instance-journey" &&
            event.creatureGuid &&
            event.creatureGuid != requesterGuid)
            continue;

        ++visibleCount;
        Protocol::SendMechanicEvent(
            handler,
            requestId,
            event.sequence,
            event.timestampMs,
            event.elapsedMs,
            event.encounterId,
            event.type,
            event.creatureEntry,
            event.creatureGuid,
            event.creatureName,
            event.mechanicId,
            event.mechanicName,
            event.phase,
            event.detail);
    }

    return visibleCount;
}

} // namespace AzerCoreOps

void AddSC_azercore_ops_mechanic_event_recorder()
{
    new AzerCoreOps::MechanicCreatureScript();
    new AzerCoreOps::MechanicSpellScript();
    new AzerCoreOps::MechanicObjectScript();
    new AzerCoreOps::MechanicUnitScript();
    new AzerCoreOps::MechanicMapScript();
    new AzerCoreOps::MechanicPlayerScript();
}
