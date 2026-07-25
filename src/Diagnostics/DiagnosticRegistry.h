#ifndef AZERCORE_OPS_DIAGNOSTIC_REGISTRY_H
#define AZERCORE_OPS_DIAGNOSTIC_REGISTRY_H

#include "Diagnostic.h"

#include <memory>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace AzerCoreOps
{
class DiagnosticRegistry
{
public:
    bool Register(std::unique_ptr<Diagnostic> diagnostic);
    Diagnostic const* Find(std::string_view id) const noexcept;
    std::vector<Diagnostic const*> List() const;
    void Clear() noexcept;

private:
    std::unordered_map<std::string, std::unique_ptr<Diagnostic>> _diagnostics;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_DIAGNOSTIC_REGISTRY_H
