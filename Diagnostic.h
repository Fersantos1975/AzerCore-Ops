#ifndef AZERCORE_OPS_DIAGNOSTIC_H
#define AZERCORE_OPS_DIAGNOSTIC_H

#include "Core/AzerCoreOpsResult.h"
#include "DiagnosticContext.h"

#include <string_view>

namespace AzerCoreOps
{
class Diagnostic
{
public:
    virtual ~Diagnostic() = default;

    virtual std::string_view GetId() const noexcept = 0;
    virtual std::string_view GetName() const noexcept = 0;
    virtual Result Evaluate(DiagnosticContext const& context) const = 0;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_DIAGNOSTIC_H
