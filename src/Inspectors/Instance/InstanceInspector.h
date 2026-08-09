#ifndef AZERCORE_OPS_INSTANCE_INSPECTOR_H
#define AZERCORE_OPS_INSTANCE_INSPECTOR_H

#include "Chat.h"
#include "Define.h"

class ChatHandler;

namespace AzerCoreOps
{
class InstanceInspector
{
public:
    static bool Search(ChatHandler* handler, Acore::ChatCommands::Tail search);
    static bool Audit(ChatHandler* handler, uint32 mapId, Optional<uint8> difficultyArg);
    static bool Binds(ChatHandler* handler, Acore::ChatCommands::Tail scope);
    static bool Diagnose(ChatHandler* handler);
    static bool Unbind(ChatHandler* handler, Acore::ChatCommands::Tail selections);
};
}

#endif
