#ifndef AZERCORE_OPS_INSPECTOR_CONTEXT_H
#define AZERCORE_OPS_INSPECTOR_CONTEXT_H

#include "Diagnostics/DiagnosticContext.h"

#include <string>
#include <utility>

namespace AzerCoreOps
{
class InspectorContext
{
public:
    InspectorContext(std::string subjectId, DiagnosticContext diagnosticContext)
        : _subjectId(std::move(subjectId)), _diagnosticContext(std::move(diagnosticContext))
    {
    }

    std::string const& GetSubjectId() const noexcept { return _subjectId; }
    DiagnosticContext const& GetDiagnosticContext() const noexcept { return _diagnosticContext; }
    DiagnosticContext& GetDiagnosticContext() noexcept { return _diagnosticContext; }

private:
    std::string _subjectId;
    DiagnosticContext _diagnosticContext;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSPECTOR_CONTEXT_H
