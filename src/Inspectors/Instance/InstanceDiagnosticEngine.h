#ifndef AZERCORE_OPS_INSTANCE_DIAGNOSTIC_ENGINE_H
#define AZERCORE_OPS_INSTANCE_DIAGNOSTIC_ENGINE_H

#include "RecoveryGuidanceEngine.h"

#include <string>

namespace AzerCoreOps
{
struct ProgressionGate;

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

class InstanceDiagnosticEngine
{
public:
    static bool IsFresh(RecoveryContext const& context);
    static bool HasCompletedDependant(RecoveryContext const& context, std::uint32_t prerequisite);
    static EncounterAssessment AssessEncounter(RecoveryContext const& context, RecoveryEncounter const& encounter);
    static GateAssessment AssessGate(RecoveryContext const& context, ProgressionGate const& gate);
};
} // namespace AzerCoreOps

#endif // AZERCORE_OPS_INSTANCE_DIAGNOSTIC_ENGINE_H
