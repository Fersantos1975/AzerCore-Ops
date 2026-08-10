#ifndef AZERCORE_OPS_RECOVERY_GUIDANCE_ENGINE_H
#define AZERCORE_OPS_RECOVERY_GUIDANCE_ENGINE_H

#include "InstanceScript.h"

#include <cstdint>
#include <string>
#include <vector>

namespace AzerCoreOps
{
struct RecoveryEncounter
{
    std::uint32_t id{0};
    std::string name;
    EncounterState state{TO_BE_DECIDED};
    std::uint32_t creditType{0};
    std::uint32_t creditEntry{0};
};

struct RecoveryContext
{
    std::uint32_t mapId{0};
    std::string scriptName;
    std::vector<RecoveryEncounter> encounters;
    std::uint32_t selectedCreatureEntry{0};
    bool selectedCreatureAlive{false};
    bool selectedCreatureInCombat{false};
    bool instanceEncounterInProgress{false};
};

struct RecoveryGuidance
{
    std::string id;
    std::string title;
    std::string confidence;
    std::string evidence;
    std::string verificationCommand;
    std::string actionCommands;
    std::string recheckCommand;
    std::string expectedResult;
    std::string safety;
};

class RecoveryGuidanceEngine
{
public:
    static std::vector<RecoveryGuidance> Evaluate(RecoveryContext const& context);
};
}

#endif
