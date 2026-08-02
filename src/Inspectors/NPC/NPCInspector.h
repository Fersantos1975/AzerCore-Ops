#ifndef AZERCORE_OPS_NPC_INSPECTOR_H
#define AZERCORE_OPS_NPC_INSPECTOR_H

class ChatHandler;

namespace AzerCoreOps
{
class NPCInspector
{
public:
    static bool Inspect(ChatHandler* handler);
};
}

#endif
