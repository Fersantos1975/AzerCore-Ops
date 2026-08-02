#include "InstanceProtocolFormatter.h"

#include <algorithm>
#include <sstream>

namespace AzerCoreOps
{
namespace
{
std::string Clean(std::string value)
{
    std::replace(value.begin(), value.end(), '|', '/');
    std::replace(value.begin(), value.end(), '\n', ' ');
    std::replace(value.begin(), value.end(), '\r', ' ');
    return value;
}
}

std::string InstanceProtocolFormatter::ResultName(Report const& report)
{
    bool warning = false;

    for (ReportSection const& section : report.GetSections())
    {
        for (ReportFinding const& finding : section.GetFindings())
        {
            Status status = finding.GetResult().GetStatus();
            if (status == Status::Blocked || status == Status::Error)
                return "FAIL";
            if (status == Status::Warning)
                warning = true;
        }
    }

    return warning ? "WARN" : "PASS";
}

std::string InstanceProtocolFormatter::Reasons(Report const& report)
{
    std::ostringstream output;

    // Preserve the original protocol ordering: failures first, then warnings.
    for (Status selected : { Status::Blocked, Status::Error, Status::Warning })
    {
        for (ReportSection const& section : report.GetSections())
        {
            for (ReportFinding const& finding : section.GetFindings())
            {
                Result const& result = finding.GetResult();
                if (result.GetStatus() != selected)
                    continue;

                if (output.tellp() > 0)
                    output << "; ";
                output << Clean(result.GetSummary());
            }
        }
    }

    return output.str().empty() ? "All checked requirements passed" : output.str();
}
} // namespace AzerCoreOps
