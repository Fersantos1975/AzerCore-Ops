#ifndef AZERCORE_OPS_ENCOUNTER_HISTORY_H
#define AZERCORE_OPS_ENCOUNTER_HISTORY_H

#include "Chat.h"

class ChatHandler;

namespace AzerCoreOps
{
class EncounterHistory
{
public:
    static bool Show(ChatHandler* handler, Acore::ChatCommands::Tail requestArg);
};
}

void AddSC_azercore_ops_encounter_history();

#endif // AZERCORE_OPS_ENCOUNTER_HISTORY_H
