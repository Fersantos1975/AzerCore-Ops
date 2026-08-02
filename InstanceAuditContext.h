#ifndef AZERCORE_OPS_INSTANCE_AUDIT_CONTEXT_H
#define AZERCORE_OPS_INSTANCE_AUDIT_CONTEXT_H

#include "SharedDefines.h"

#include <cstdint>

class MapEntry;
class Player;

namespace AzerCoreOps
{
struct InstanceAuditContext
{
    Player* player = nullptr;
    Player* requester = nullptr;
    Player* leader = nullptr;
    MapEntry const* mapEntry = nullptr;
    Difficulty difficulty = REGULAR_DIFFICULTY;
    std::uint32_t referenceInstanceId = 0;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSTANCE_AUDIT_CONTEXT_H
