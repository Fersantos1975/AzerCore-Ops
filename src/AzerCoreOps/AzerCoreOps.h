#ifndef AZERCORE_OPS_AZERCORE_OPS_H
#define AZERCORE_OPS_AZERCORE_OPS_H

#include "Diagnostics/DiagnosticRegistry.h"
#include "Inspectors/InspectorRegistry.h"

namespace AzerCoreOps
{
class Application
{
public:
    static Application& Instance();

    DiagnosticRegistry& Diagnostics() noexcept { return _diagnostics; }
    DiagnosticRegistry const& Diagnostics() const noexcept { return _diagnostics; }

    InspectorRegistry& Inspectors() noexcept { return _inspectors; }
    InspectorRegistry const& Inspectors() const noexcept { return _inspectors; }

    void Reset() noexcept;

private:
    Application() = default;

    DiagnosticRegistry _diagnostics;
    InspectorRegistry _inspectors;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_AZERCORE_OPS_H
