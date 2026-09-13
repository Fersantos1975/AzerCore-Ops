#ifndef AZERCORE_OPS_ENCOUNTER_HISTORY_H
#define AZERCORE_OPS_ENCOUNTER_HISTORY_H

#include "Chat.h"

#include <cstdint>
#include <string>

class ChatHandler;

namespace AzerCoreOps
{
class EncounterHistory
{
public:
    static bool Show(ChatHandler* handler, Acore::ChatCommands::Tail requestArg);
    static bool LatestTransition(
        std::uint32_t instanceId,
        std::uint32_t encounterId,
        std::uint32_t currentState,
        std::string& classification,
        std::string& event,
        std::string& detail);
};
}

void AddSC_azercore_ops_encounter_history();

#endif // AZERCORE_OPS_ENCOUNTER_HISTORY_H
