#ifndef AZERCORE_OPS_INSTANCE_PROFILE_H
#define AZERCORE_OPS_INSTANCE_PROFILE_H

#include "InstanceScript.h"

#include <cstdint>
#include <string>
#include <vector>

namespace AzerCoreOps
{
struct EncounterDependency
{
    std::uint32_t prerequisite{0};
    std::uint32_t dependant{0};
    std::string consequence;
};

struct InitialStateAllowance
{
    std::uint32_t encounter{0};
    std::vector<EncounterState> states;
    std::string reason;
    std::vector<std::uint32_t> strictAfter;
};

struct EncounterIdMapping
{
    std::uint32_t catalogueId{0};
    std::uint32_t scriptId{0};
};

struct RuntimeStateDefinition
{
    std::uint32_t scriptId{0};
    std::string name;
};

enum class ProfileSignalKind
{
    State,
    Count,
    Boolean
};

struct ProfileSignal
{
    std::uint32_t dataId{0};
    std::string name;
    ProfileSignalKind kind{ProfileSignalKind::Count};
    bool heroicOnly{false};
};

struct ProgressionGate
{
    std::string id;
    std::string name;
    std::vector<std::uint32_t> prerequisites;
    std::uint32_t dependant{0};
    std::string consequence;
};

enum class ProfileObjectPolicy
{
    Observe,
    OpenWhenReady,
    SelectableWhenReady
};

struct ProfileObject
{
    std::uint32_t entry{0};
    std::string name;
    std::string category;
    ProfileObjectPolicy policy{ProfileObjectPolicy::Observe};
    std::vector<std::uint32_t> prerequisites;
};

struct InstanceProfile
{
    std::uint32_t mapId{0};
    std::string id;
    std::string name;
    std::vector<std::uint32_t> difficulties;
    std::vector<EncounterIdMapping> encounterMappings;
    std::vector<EncounterDependency> dependencies;
    std::vector<ProgressionGate> gates;
    std::vector<InitialStateAllowance> initialStates;
    std::vector<RuntimeStateDefinition> runtimeStates;
    std::vector<ProfileSignal> signals;
    std::vector<ProfileObject> objects;
};

class InstanceProfileCatalog
{
public:
    static InstanceProfile const* Find(std::uint32_t mapId);
    static std::vector<InstanceProfile> const& All();
    static std::uint32_t ScriptEncounterId(std::uint32_t mapId, std::uint32_t catalogueId);
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSTANCE_PROFILE_H
