#include "InspectorRegistry.h"

namespace AzerCoreOps
{
bool InspectorRegistry::Register(std::unique_ptr<Inspector> inspector)
{
    if (!inspector || inspector->GetId().empty())
        return false;

    std::string id(inspector->GetId());
    return _inspectors.emplace(std::move(id), std::move(inspector)).second;
}

Inspector const* InspectorRegistry::Find(std::string_view id) const noexcept
{
    auto itr = _inspectors.find(std::string(id));
    return itr == _inspectors.end() ? nullptr : itr->second.get();
}

std::vector<Inspector const*> InspectorRegistry::List() const
{
    std::vector<Inspector const*> result;
    result.reserve(_inspectors.size());

    for (auto const& pair : _inspectors)
        result.push_back(pair.second.get());

    return result;
}

void InspectorRegistry::Clear() noexcept
{
    _inspectors.clear();
}
} // namespace AzerCoreOps
