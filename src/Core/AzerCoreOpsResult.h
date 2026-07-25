/*
 * AzerCoreOps
 * Operational Diagnostics Platform for AzerothCore
 */

#ifndef AZERCORE_OPS_RESULT_H
#define AZERCORE_OPS_RESULT_H

#include "AzerCoreOpsStatus.h"

#include <string>
#include <utility>
#include <vector>

namespace AzerCoreOps
{
struct Evidence
{
    std::string key;
    std::string value;
};

class Result
{
public:
    Result() = default;

    Result(Status status, std::string code, std::string summary)
        : _status(status), _code(std::move(code)), _summary(std::move(summary))
    {
    }

    static Result Pass(std::string code, std::string summary)
    {
        return Result(Status::Pass, std::move(code), std::move(summary));
    }

    static Result Information(std::string code, std::string summary)
    {
        return Result(Status::Information, std::move(code), std::move(summary));
    }

    static Result Warning(std::string code, std::string summary)
    {
        return Result(Status::Warning, std::move(code), std::move(summary));
    }

    static Result Blocked(std::string code, std::string summary)
    {
        return Result(Status::Blocked, std::move(code), std::move(summary));
    }

    static Result Unsupported(std::string code, std::string summary)
    {
        return Result(Status::Unsupported, std::move(code), std::move(summary));
    }

    static Result Error(std::string code, std::string summary)
    {
        return Result(Status::Error, std::move(code), std::move(summary));
    }

    Status GetStatus() const noexcept { return _status; }
    std::string const& GetCode() const noexcept { return _code; }
    std::string const& GetSummary() const noexcept { return _summary; }
    std::string const& GetDetails() const noexcept { return _details; }
    std::string const& GetRecommendation() const noexcept { return _recommendation; }
    std::vector<Evidence> const& GetEvidence() const noexcept { return _evidence; }

    bool HasProblem() const noexcept { return IsProblem(_status); }
    bool IsTerminalProblem() const noexcept { return AzerCoreOps::IsTerminalProblem(_status); }

    Result& SetDetails(std::string details)
    {
        _details = std::move(details);
        return *this;
    }

    Result& SetRecommendation(std::string recommendation)
    {
        _recommendation = std::move(recommendation);
        return *this;
    }

    Result& AddEvidence(std::string key, std::string value)
    {
        _evidence.push_back({ std::move(key), std::move(value) });
        return *this;
    }

private:
    Status _status = Status::Information;
    std::string _code;
    std::string _summary;
    std::string _details;
    std::string _recommendation;
    std::vector<Evidence> _evidence;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_RESULT_H
