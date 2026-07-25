#ifndef AZERCORE_OPS_DIAGNOSTIC_CONTEXT_H
#define AZERCORE_OPS_DIAGNOSTIC_CONTEXT_H

#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>

class Player;
class WorldObject;

namespace AzerCoreOps
{
class DiagnosticContext
{
public:
    DiagnosticContext() = default;

    explicit DiagnosticContext(Player* requester)
        : _requester(requester)
    {
    }

    Player* GetRequester() const noexcept { return _requester; }
    Player* GetSubjectPlayer() const noexcept { return _subjectPlayer; }
    WorldObject* GetSubjectObject() const noexcept { return _subjectObject; }

    void SetRequester(Player* requester) noexcept { _requester = requester; }
    void SetSubjectPlayer(Player* subject) noexcept { _subjectPlayer = subject; }
    void SetSubjectObject(WorldObject* subject) noexcept { _subjectObject = subject; }

    void SetNumber(std::string key, std::uint64_t value)
    {
        _numbers[std::move(key)] = value;
    }

    std::optional<std::uint64_t> GetNumber(std::string const& key) const
    {
        auto itr = _numbers.find(key);
        if (itr == _numbers.end())
            return std::nullopt;

        return itr->second;
    }

    void SetText(std::string key, std::string value)
    {
        _texts[std::move(key)] = std::move(value);
    }

    std::optional<std::string> GetText(std::string const& key) const
    {
        auto itr = _texts.find(key);
        if (itr == _texts.end())
            return std::nullopt;

        return itr->second;
    }

private:
    Player* _requester = nullptr;
    Player* _subjectPlayer = nullptr;
    WorldObject* _subjectObject = nullptr;
    std::unordered_map<std::string, std::uint64_t> _numbers;
    std::unordered_map<std::string, std::string> _texts;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_DIAGNOSTIC_CONTEXT_H
