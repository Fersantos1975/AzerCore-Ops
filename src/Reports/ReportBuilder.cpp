#include "ReportBuilder.h"

#include <utility>

namespace AzerCoreOps
{
ReportBuilder::ReportBuilder(std::string inspectorId, std::string subjectId)
    : _report(std::move(inspectorId), std::move(subjectId))
{
}

ReportBuilder& ReportBuilder::Title(std::string title)
{
    _report.SetTitle(std::move(title));
    return *this;
}

ReportBuilder& ReportBuilder::Summary(std::string summary)
{
    _report.SetSummary(std::move(summary));
    return *this;
}

ReportBuilder& ReportBuilder::Metadata(std::string key, std::string value)
{
    _report.SetMetadata(std::move(key), std::move(value));
    return *this;
}

ReportBuilder& ReportBuilder::Finding(std::string sectionId, std::string sectionTitle,
    std::string diagnosticId, Result result)
{
    auto section = _report.FindSection(sectionId);

    if (!section)
        section = _report.AddSection(std::move(sectionId), std::move(sectionTitle));

    section->get().AddFinding(ReportFinding(std::move(diagnosticId), std::move(result)));
    return *this;
}

Report ReportBuilder::Build()
{
    return std::move(_report);
}
} // namespace AzerCoreOps
