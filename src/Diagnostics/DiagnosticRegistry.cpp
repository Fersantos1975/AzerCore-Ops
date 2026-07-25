#include "DiagnosticRegistry.h"

namespace AzerCoreOps
{
bool DiagnosticRegistry::Register(std::unique_ptr<Diagnostic> diagnostic)
{
    if (!diagnostic || diagnostic->GetId().empty())
        return false;

    std::string id(diagnostic->GetId());
    return _diagnostics.emplace(std::move(id), std::move(diagnostic)).second;
}

Diagnostic const* DiagnosticRegistry::Find(std::string_view id) const noexcept
{
    auto itr = _diagnostics.find(std::string(id));
    return itr == _diagnostics.end() ? nullptr : itr->second.get();
}

std::vector<Diagnostic const*> DiagnosticRegistry::List() const
{
    std::vector<Diagnostic const*> result;
    result.reserve(_diagnostics.size());

    for (auto const& pair : _diagnostics)
        result.push_back(pair.second.get());

    return result;
}

void DiagnosticRegistry::Clear() noexcept
{
    _diagnostics.clear();
}
} // namespace AzerCoreOps
