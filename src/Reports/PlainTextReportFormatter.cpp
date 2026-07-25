#include "PlainTextReportFormatter.h"

#include <sstream>

namespace AzerCoreOps
{
std::string PlainTextReportFormatter::Format(Report const& report) const
{
    std::ostringstream output;

    output << report.GetTitle() << '\n';
    output << "Inspector: " << report.GetInspectorId() << '\n';
    output << "Subject: " << report.GetSubjectId() << '\n';
    output << "Status: " << ToString(report.GetOverallStatus()) << '\n';

    if (!report.GetSummary().empty())
        output << "Summary: " << report.GetSummary() << '\n';

    for (auto const& metadata : report.GetMetadata())
        output << metadata.first << ": " << metadata.second << '\n';

    for (ReportSection const& section : report.GetSections())
    {
        if (section.Empty())
            continue;

        output << '\n' << '[' << section.GetTitle() << "]\n";

        for (ReportFinding const& finding : section.GetFindings())
        {
            Result const& result = finding.GetResult();

            output << "- " << ToString(result.GetStatus())
                   << " | " << finding.GetDiagnosticId()
                   << " | " << result.GetSummary() << '\n';

            for (Evidence const& evidence : result.GetEvidence())
                output << "  " << evidence.key << ": " << evidence.value << '\n';

            if (!result.GetDetails().empty())
                output << "  Details: " << result.GetDetails() << '\n';

            if (!result.GetRecommendation().empty())
                output << "  Recommendation: " << result.GetRecommendation() << '\n';
        }
    }

    return output.str();
}
} // namespace AzerCoreOps
