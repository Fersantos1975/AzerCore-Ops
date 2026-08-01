#ifndef AZERCORE_OPS_CHARACTER_INSPECTOR_H
#define AZERCORE_OPS_CHARACTER_INSPECTOR_H

#include "Chat.h"

class ChatHandler;

namespace AzerCoreOps
{
class CharacterInspector
{
public:
    static bool Inspect(ChatHandler* handler);
    static bool Raid(ChatHandler* handler, Acore::ChatCommands::Tail selection);
    static bool SaveTarget(ChatHandler* handler);
};
}

#endif
