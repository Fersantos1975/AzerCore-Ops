#include "InstanceDiagnosticEngine.h"

#include "InstanceProfile.h"

#include <algorithm>
#include <sstream>

namespace AzerCoreOps
{
namespace
{
RecoveryEncounter const* FindEncounter(RecoveryContext const& context, std::uint32_t id)
{
    auto found = std::find_if(context.encounters.begin(), context.encounters.end(), [id](RecoveryEncounter const& encounter) { return encounter.id == id; });
    return found == context.encounters.end() ? nullptr : &*found;
}

InitialStateAllowance const* FindInitialAllowance(InstanceProfile const* profile, std::uint32_t id, EncounterState state)
{
    if (!profile)
        return nullptr;
    for (InitialStateAllowance const& allowance : profile->initialStates)
        if (allowance.encounter == id && std::find(allowance.states.begin(), allowance.states.end(), state) != allowance.states.end())
            return &allowance;
    return nullptr;
}

bool AllowanceApplies(RecoveryContext const& context, InitialStateAllowance const* allowance)
{
    if (!allowance)
        return false;
    if (InstanceDiagnosticEngine::IsFresh(context) || allowance->strictAfter.empty())
        return true;
    return std::any_of(allowance->strictAfter.begin(), allowance->strictAfter.end(), [&context](std::uint32_t id)
    {
        RecoveryEncounter const* prerequisite = FindEncounter(context, id);
        return !prerequisite || prerequisite->state != DONE;
    });
}
}

bool InstanceDiagnosticEngine::IsFresh(RecoveryContext const& context)
{
    return std::none_of(context.encounters.begin(), context.encounters.end(), [](RecoveryEncounter const& encounter)
    {
        return encounter.state == DONE || encounter.state == IN_PROGRESS || encounter.state == SPECIAL;
    });
}

bool InstanceDiagnosticEngine::HasCompletedDependant(RecoveryContext const& context, std::uint32_t prerequisite)
{
    InstanceProfile const* profile = InstanceProfileCatalog::Find(context.mapId);
    if (!profile)
        return false;
    for (EncounterDependency const& dependency : profile->dependencies)
        if (dependency.prerequisite == prerequisite)
            if (RecoveryEncounter const* dependant = FindEncounter(context, dependency.dependant); dependant && dependant->state == DONE)
                return true;
    return false;
}

EncounterAssessment InstanceDiagnosticEngine::AssessEncounter(RecoveryContext const& context, RecoveryEncounter const& encounter)
{
    bool contradiction = encounter.state != DONE && HasCompletedDependant(context, encounter.id);
    if (contradiction)
        return {"FAIL", "A verified dependant encounter is DONE while this prerequisite is not complete", "Verify the saved state and inspect the generated recovery evidence before changing anything"};

    switch (encounter.state)
    {
        case DONE:
            return {"PASS", "The instance save records this encounter as completed", "No action required"};
        case NOT_STARTED:
            return {"EXPECTED", "The encounter has not been reached or started in this progression", "Continue the instance normally; no recovery action is required"};
        case IN_PROGRESS:
            if (context.instanceEncounterInProgress)
                return {"INFO", "The encounter is active and the instance confirms combat progression", "Complete or wipe the encounter normally, then rescan"};
            return {"WARN", "The encounter is IN_PROGRESS while the instance reports no active encounter", "Allow the scripted reset to finish and rescan before considering recovery"};
        case FAIL:
        {
            InitialStateAllowance const* allowance = FindInitialAllowance(InstanceProfileCatalog::Find(context.mapId), encounter.id, encounter.state);
            if (AllowanceApplies(context, allowance))
                return {"EXPECTED", allowance->reason, "Continue normal progression; only investigate if this state remains stuck when its wing is reached"};
            return {"WARN", "The encounter recorded a failed or reset transition", "Allow the scripted reset to complete; escalate only if the state remains stuck"};
        }
        case SPECIAL:
            return {"INFO", "The encounter is using a script-specific transitional state", "Collect nearby creature, event and door evidence before judging this state"};
        case TO_BE_DECIDED:
        {
            InitialStateAllowance const* allowance = FindInitialAllowance(InstanceProfileCatalog::Find(context.mapId), encounter.id, encounter.state);
            if (AllowanceApplies(context, allowance))
                return {"EXPECTED", allowance->reason, "Continue normal progression; initialization will occur through the encounter script"};
            return {"INFO", "The encounter has not yet been initialized by its script", "Do not force DONE; inspect its verified prerequisites and initialization event"};
        }
        default:
            return {"WARN", "The instance returned an unknown encounter state", "Export this scan for investigation"};
    }
}

GateAssessment InstanceDiagnosticEngine::AssessGate(RecoveryContext const& context, ProgressionGate const& gate)
{
    std::vector<std::uint32_t> missing;
    for (std::uint32_t prerequisite : gate.prerequisites)
    {
        RecoveryEncounter const* encounter = FindEncounter(context, prerequisite);
        if (!encounter || encounter->state != DONE)
            missing.push_back(prerequisite);
    }

    RecoveryEncounter const* dependant = FindEncounter(context, gate.dependant);
    bool dependantDone = dependant && dependant->state == DONE;
    std::ostringstream actual;
    if (missing.empty())
        actual << "All prerequisites DONE";
    else
    {
        actual << "Waiting for IDs ";
        for (std::size_t i = 0; i < missing.size(); ++i)
        {
            if (i) actual << ", ";
            actual << missing[i];
        }
    }

    if (dependantDone && !missing.empty())
        return {"FAIL", actual.str() + "; dependant ID " + std::to_string(gate.dependant) + " is DONE", "A dependant encounter is complete while this verified multi-prerequisite gate is incomplete", "Verify the saved state and profile evidence before applying recovery"};
    if (missing.empty())
        return {"PASS", actual.str(), gate.consequence, "Gate prerequisites passed; verify its controlled objects if access is still blocked"};
    return {"EXPECTED", actual.str(), gate.consequence, "Normal progression lock; complete the missing prerequisites through their scripts"};
}
} // namespace AzerCoreOps
