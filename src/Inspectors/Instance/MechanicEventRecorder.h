#ifndef AZERCORE_OPS_MECHANIC_EVENT_RECORDER_H
#define AZERCORE_OPS_MECHANIC_EVENT_RECORDER_H

#include <cstdint>

class ChatHandler;
class Creature;
class Map;
class Player;
class Unit;

enum EncounterState : std::uint8_t;

namespace AzerCoreOps
{
class MechanicEventRecorder
{
public:
    static void OnEncounterState(Map* map, std::uint32_t encounterId, EncounterState newState, EncounterState oldState);
    static void OnCreatureSpawn(Creature* creature);
    static void OnUnitDeath(Unit* unit);
    static void OnPlayerEnter(Map* map, Player* player);
    static void OnPlayerLeave(Map* map, Player* player);
    static void OnPlayerReleasedGhost(Player* player);
    static void OnPlayerResurrect(Player* player);
    static void Clear(std::uint32_t instanceId);
    static std::uint32_t Show(ChatHandler* handler, std::uint32_t requestId, Map* map, std::uint64_t afterSequence = 0);
};
}

void AddSC_azercore_ops_mechanic_event_recorder();

#endif // AZERCORE_OPS_MECHANIC_EVENT_RECORDER_H
