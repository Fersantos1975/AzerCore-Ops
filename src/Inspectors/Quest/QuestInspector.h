#ifndef AZERCORE_OPS_QUEST_INSPECTOR_H
#define AZERCORE_OPS_QUEST_INSPECTOR_H

#include "Chat.h"
#include "Define.h"
class ChatHandler;

namespace AzerCoreOps
{
class QuestInspector
{
public:
    static bool Search(ChatHandler* handler, Acore::ChatCommands::Tail search);
    static bool Info(ChatHandler* handler, uint32 questId);
    static bool Audit(ChatHandler* handler, uint32 questId);
};
}

#endif
