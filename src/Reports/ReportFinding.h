#ifndef AZERCORE_OPS_REPORT_FINDING_H
#define AZERCORE_OPS_REPORT_FINDING_H

#include "Core/AzerCoreOpsResult.h"

#include <string>
#include <utility>

namespace AzerCoreOps
{
class ReportFinding
{
public:
    ReportFinding(std::string diagnosticId, Result result)
        : _diagnosticId(std::move(diagnosticId)), _result(std::move(result))
    {
    }

    std::string const& GetDiagnosticId() const noexcept { return _diagnosticId; }
    Result const& GetResult() const noexcept { return _result; }

private:
    std::string _diagnosticId;
    Result _result;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_REPORT_FINDING_H
