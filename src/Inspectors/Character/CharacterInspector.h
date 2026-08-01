#ifndef AZERCORE_OPS_CHARACTER_INSPECTOR_H
#define AZERCORE_OPS_CHARACTER_INSPECTOR_H

class ChatHandler;

namespace AzerCoreOps
{
class CharacterInspector
{
public:
    static bool Inspect(ChatHandler* handler);
    static bool SaveTarget(ChatHandler* handler);
};
}

#endif
