#ifndef AZERCORE_OPS_INSPECTOR_H
#define AZERCORE_OPS_INSPECTOR_H

#include "InspectorContext.h"
#include "Reports/Report.h"

#include <string_view>

namespace AzerCoreOps
{
class Inspector
{
public:
    virtual ~Inspector() = default;

    virtual std::string_view GetId() const noexcept = 0;
    virtual std::string_view GetName() const noexcept = 0;
    virtual Report Inspect(InspectorContext& context) const = 0;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSPECTOR_H
