#ifndef AZERCORE_OPS_ITEM_INSPECTOR_H
#define AZERCORE_OPS_ITEM_INSPECTOR_H

#include "Define.h"

class ChatHandler;

namespace AzerCoreOps
{
class ItemInspector
{
public:
    static bool Inspect(ChatHandler* handler, uint32 itemId);
};
}

#endif
