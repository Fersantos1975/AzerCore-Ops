/*
 * AzerCoreOps
 * Operational Diagnostics Platform for AzerothCore
 *
 * Inspect. Diagnose. Resolve.
 */

#ifndef AZERCORE_OPS_STATUS_H
#define AZERCORE_OPS_STATUS_H

#include <cstdint>
#include <string_view>

namespace AzerCoreOps
{
enum class Status : std::uint8_t
{
    Pass,
    Information,
    Warning,
    Blocked,
    Unsupported,
    Error
};

constexpr std::string_view ToString(Status status) noexcept
{
    switch (status)
    {
        case Status::Pass:        return "PASS";
        case Status::Information: return "INFORMATION";
        case Status::Warning:     return "WARNING";
        case Status::Blocked:     return "BLOCKED";
        case Status::Unsupported: return "UNSUPPORTED";
        case Status::Error:       return "ERROR";
    }

    return "ERROR";
}

constexpr bool IsProblem(Status status) noexcept
{
    return status == Status::Warning ||
           status == Status::Blocked ||
           status == Status::Error;
}

constexpr bool IsTerminalProblem(Status status) noexcept
{
    return status == Status::Blocked || status == Status::Error;
}

constexpr std::uint8_t SeverityRank(Status status) noexcept
{
    switch (status)
    {
        case Status::Pass:        return 0;
        case Status::Information: return 1;
        case Status::Unsupported: return 2;
        case Status::Warning:     return 3;
        case Status::Blocked:     return 4;
        case Status::Error:       return 5;
    }

    return 5;
}
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_STATUS_H
