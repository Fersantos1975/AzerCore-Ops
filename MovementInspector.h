#ifndef AZERCORE_OPS_MOVEMENT_INSPECTOR_H
#define AZERCORE_OPS_MOVEMENT_INSPECTOR_H

#include "Define.h"

class ChatHandler;

namespace AzerCoreOps
{
class MovementInspector
{
public:
    static bool Catalog(ChatHandler* handler);
    static bool Current(ChatHandler* handler);
    static bool Go(ChatHandler* handler, uint32 map, float x, float y, float z, float orientation);
    static bool Return(ChatHandler* handler);
};
}
#endif
