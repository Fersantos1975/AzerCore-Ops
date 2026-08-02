#ifndef AZERCORE_OPS_REPORT_SECTION_H
#define AZERCORE_OPS_REPORT_SECTION_H

#include "ReportFinding.h"

#include <string>
#include <utility>
#include <vector>

namespace AzerCoreOps
{
class ReportSection
{
public:
    explicit ReportSection(std::string id, std::string title = {})
        : _id(std::move(id)), _title(std::move(title))
    {
    }

    std::string const& GetId() const noexcept { return _id; }
    std::string const& GetTitle() const noexcept { return _title; }
    std::vector<ReportFinding> const& GetFindings() const noexcept { return _findings; }

    ReportSection& SetTitle(std::string title)
    {
        _title = std::move(title);
        return *this;
    }

    ReportSection& AddFinding(ReportFinding finding)
    {
        _findings.push_back(std::move(finding));
        return *this;
    }

    bool Empty() const noexcept { return _findings.empty(); }

private:
    std::string _id;
    std::string _title;
    std::vector<ReportFinding> _findings;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_REPORT_SECTION_H
