#ifndef AZERCORE_OPS_NPC_INSPECTOR_H
#define AZERCORE_OPS_NPC_INSPECTOR_H

#include "Chat.h"
#include "Define.h"

class ChatHandler;

namespace AzerCoreOps
{
class NPCInspector
{
public:
    static bool Search(ChatHandler* handler, Acore::ChatCommands::Tail search);
    static bool Spawns(ChatHandler* handler, uint32 entry);
    static bool Inspect(ChatHandler* handler);
};
}

#endif
