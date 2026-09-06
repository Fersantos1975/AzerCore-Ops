#ifndef AZERCORE_OPS_INSTANCE_DIAGNOSTIC_ENGINE_H
#define AZERCORE_OPS_INSTANCE_DIAGNOSTIC_ENGINE_H

#include "RecoveryGuidanceEngine.h"

#include <string>

namespace AzerCoreOps
{
struct ProgressionGate;
struct ProfilePrerequisiteCreature;

struct EncounterAssessment
{
    std::string severity;
    std::string detail;
    std::string recommendation;
};

struct GateAssessment
{
    std::string severity;
    std::string actual;
    std::string detail;
    std::string recommendation;
};

struct PrerequisiteCreatureObservation
{
    bool progressionDone{false};
    bool spawnDefined{false};
    std::uint32_t actualEntry{0};
    bool locationMatches{false};
    bool gridLoaded{false};
    bool loaded{false};
    bool alive{false};
    bool dead{false};
    std::uint32_t respawnSeconds{0};
};

struct PrerequisiteCreatureAssessment
{
    std::string severity;
    std::string status;
    std::string detail;
    std::string recommendation;
};

class InstanceDiagnosticEngine
{
public:
    static bool IsFresh(RecoveryContext const& context);
    static bool HasCompletedDependant(RecoveryContext const& context, std::uint32_t prerequisite);
    static EncounterAssessment AssessEncounter(RecoveryContext const& context, RecoveryEncounter const& encounter);
    static GateAssessment AssessGate(RecoveryContext const& context, ProgressionGate const& gate);
    static PrerequisiteCreatureAssessment AssessPrerequisiteCreature(ProfilePrerequisiteCreature const& definition, PrerequisiteCreatureObservation const& observation);
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSTANCE_DIAGNOSTIC_ENGINE_H
