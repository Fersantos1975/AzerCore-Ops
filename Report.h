#ifndef AZERCORE_OPS_REPORT_H
#define AZERCORE_OPS_REPORT_H

#include "Core/AzerCoreOpsStatus.h"
#include "ReportSection.h"

#include <cstddef>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace AzerCoreOps
{
class Report
{
public:
    using Metadata = std::map<std::string, std::string>;

    Report(std::string inspectorId, std::string subjectId)
        : _inspectorId(std::move(inspectorId)), _subjectId(std::move(subjectId))
    {
    }

    std::string const& GetInspectorId() const noexcept { return _inspectorId; }
    std::string const& GetSubjectId() const noexcept { return _subjectId; }
    std::string const& GetTitle() const noexcept { return _title; }
    std::string const& GetSummary() const noexcept { return _summary; }
    Metadata const& GetMetadata() const noexcept { return _metadata; }
    std::vector<ReportSection> const& GetSections() const noexcept { return _sections; }

    Report& SetTitle(std::string title)
    {
        _title = std::move(title);
        return *this;
    }

    Report& SetSummary(std::string summary)
    {
        _summary = std::move(summary);
        return *this;
    }

    Report& SetMetadata(std::string key, std::string value)
    {
        _metadata[std::move(key)] = std::move(value);
        return *this;
    }

    ReportSection& AddSection(std::string id, std::string title = {})
    {
        _sections.emplace_back(std::move(id), std::move(title));
        return _sections.back();
    }

    std::optional<std::reference_wrapper<ReportSection>> FindSection(std::string const& id)
    {
        for (ReportSection& section : _sections)
            if (section.GetId() == id)
                return section;

        return std::nullopt;
    }

    std::size_t Count(Status status) const noexcept
    {
        std::size_t count = 0;

        for (ReportSection const& section : _sections)
            for (ReportFinding const& finding : section.GetFindings())
                if (finding.GetResult().GetStatus() == status)
                    ++count;

        return count;
    }

    Status GetOverallStatus() const noexcept
    {
        Status overall = Status::Pass;

        for (ReportSection const& section : _sections)
            for (ReportFinding const& finding : section.GetFindings())
                if (SeverityRank(finding.GetResult().GetStatus()) > SeverityRank(overall))
                    overall = finding.GetResult().GetStatus();

        return overall;
    }

private:
    std::string _inspectorId;
    std::string _subjectId;
    std::string _title;
    std::string _summary;
    Metadata _metadata;
    std::vector<ReportSection> _sections;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_REPORT_H
