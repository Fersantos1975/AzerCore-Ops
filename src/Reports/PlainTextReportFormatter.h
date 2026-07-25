#ifndef AZERCORE_OPS_PLAIN_TEXT_REPORT_FORMATTER_H
#define AZERCORE_OPS_PLAIN_TEXT_REPORT_FORMATTER_H

#include "Report.h"

#include <string>

namespace AzerCoreOps
{
class PlainTextReportFormatter
{
public:
    std::string Format(Report const& report) const;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_PLAIN_TEXT_REPORT_FORMATTER_H
