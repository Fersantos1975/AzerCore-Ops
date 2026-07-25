#ifndef AZERCORE_OPS_REPORT_BUILDER_H
#define AZERCORE_OPS_REPORT_BUILDER_H

#include "Report.h"

#include <string>

namespace AzerCoreOps
{
class ReportBuilder
{
public:
    ReportBuilder(std::string inspectorId, std::string subjectId);

    ReportBuilder& Title(std::string title);
    ReportBuilder& Summary(std::string summary);
    ReportBuilder& Metadata(std::string key, std::string value);
    ReportBuilder& Finding(std::string sectionId, std::string sectionTitle,
        std::string diagnosticId, Result result);

    Report Build();

private:
    Report _report;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_REPORT_BUILDER_H
