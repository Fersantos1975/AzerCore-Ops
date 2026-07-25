#ifndef AZERCORE_OPS_INSTANCE_PROTOCOL_FORMATTER_H
#define AZERCORE_OPS_INSTANCE_PROTOCOL_FORMATTER_H

#include "Reports/Report.h"

#include <string>

namespace AzerCoreOps
{
class InstanceProtocolFormatter
{
public:
    static std::string ResultName(Report const& report);
    static std::string Reasons(Report const& report);
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSTANCE_PROTOCOL_FORMATTER_H
