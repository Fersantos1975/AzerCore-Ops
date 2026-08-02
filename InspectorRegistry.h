#ifndef AZERCORE_OPS_INSPECTOR_REGISTRY_H
#define AZERCORE_OPS_INSPECTOR_REGISTRY_H

#include "Inspector.h"

#include <memory>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace AzerCoreOps
{
class InspectorRegistry
{
public:
    bool Register(std::unique_ptr<Inspector> inspector);
    Inspector const* Find(std::string_view id) const noexcept;
    std::vector<Inspector const*> List() const;
    void Clear() noexcept;

private:
    std::unordered_map<std::string, std::unique_ptr<Inspector>> _inspectors;
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSPECTOR_REGISTRY_H
