#include "RecoveryGuidanceEngine.h"

#include <algorithm>
#include <sstream>
#include <utility>

namespace AzerCoreOps
{
namespace
{
constexpr std::uint32_t MapIcecrownCitadel = 631;

struct ProgressionRule
{
    std::string id;
    std::uint32_t mapId;
    std::uint32_t prerequisite;
    std::string prerequisiteName;
    std::vector<std::uint32_t> dependants;
    std::string consequence;
};

std::vector<ProgressionRule> const& Rules()
{
    static std::vector<ProgressionRule> const rules{
        {
            "icc-saurfang-stale-state",
            MapIcecrownCitadel,
            3,
            "Deathbringer Saurfang",
            {4, 5, 6, 7, 8, 9, 10, 11},
            "Saurfang passage door OPEN and upper-wing prerequisite PASSED"
        }
    };
    return rules;
}

bool HasState(RecoveryContext const& context, std::uint32_t index, EncounterState state)
{
    auto found = std::find_if(context.encounters.begin(), context.encounters.end(), [index](RecoveryEncounter const& encounter) { return encounter.id == index; });
    return found != context.encounters.end() && found->state == state;
}

RecoveryEncounter const* FindEncounter(RecoveryContext const& context, std::uint32_t index)
{
    auto found = std::find_if(context.encounters.begin(), context.encounters.end(), [index](RecoveryEncounter const& encounter) { return encounter.id == index; });
    return found == context.encounters.end() ? nullptr : &*found;
}

std::vector<std::uint32_t> CompletedDependants(RecoveryContext const& context, ProgressionRule const& rule)
{
    std::vector<std::uint32_t> completed;
    for (std::uint32_t index : rule.dependants)
        if (HasState(context, index, DONE))
            completed.push_back(index);
    return completed;
}

std::string JoinIds(std::vector<std::uint32_t> const& values)
{
    std::ostringstream out;
    for (std::size_t i = 0; i < values.size(); ++i)
    {
        if (i) out << ", ";
        out << values[i];
    }
    return out.str();
}
}

std::vector<RecoveryGuidance> RecoveryGuidanceEngine::Evaluate(RecoveryContext const& context)
{
    std::vector<RecoveryGuidance> result;

    // Universal rule: DBC encounter credit ties the selected creature to an encounter on any map.
    // A dead credit creature with a non-DONE state is authoritative runtime evidence of an
    // incomplete save transition. The GM must still confirm that the kill was legitimate.
    if (context.selectedCreatureEntry)
        for (RecoveryEncounter const& encounter : context.encounters)
            if (encounter.creditType == 0 && encounter.creditEntry == context.selectedCreatureEntry && !context.selectedCreatureAlive && encounter.state != DONE)
            {
                RecoveryGuidance guidance;
                guidance.id = "universal-dead-credit-creature-" + std::to_string(context.mapId) + "-" + std::to_string(encounter.id);
                guidance.title = encounter.name;
                guidance.confidence = "HIGH";
                guidance.evidence = "Selected encounter creature " + std::to_string(context.selectedCreatureEntry) + " is dead, but " + encounter.name + " [ID " + std::to_string(encounter.id) + "] is " + InstanceScript::GetBossStateName(encounter.state) + ".";
                guidance.verificationCommand = ".instance getbossstate";
                guidance.actionCommands = ".instance setbossstate " + std::to_string(encounter.id) + " 3;;.instance save";
                guidance.recheckCommand = ".instance getbossstate";
                guidance.expectedResult = encounter.name + " [ID " + std::to_string(encounter.id) + "] DONE; controlling doors and progression reevaluated by the instance script";
                guidance.safety = "Confirm that this boss was legitimately defeated in the current lockout. A dead target alone is not permission to skip an encounter.";
                result.push_back(std::move(guidance));
            }

    // Universal rule: when the selected DBC credit creature is alive and out of combat but its
    // encounter remains IN_PROGRESS, the runtime and saved state disagree. This works on any map
    // without assuming that encounter indexes imply a linear kill order.
    if (context.selectedCreatureEntry && context.selectedCreatureAlive && !context.selectedCreatureInCombat)
        for (RecoveryEncounter const& encounter : context.encounters)
            if (encounter.creditType == 0 && encounter.creditEntry == context.selectedCreatureEntry && encounter.state == IN_PROGRESS)
            {
                RecoveryGuidance guidance;
                guidance.id = "universal-stale-in-progress-" + std::to_string(context.mapId) + "-" + std::to_string(encounter.id);
                guidance.title = "Stale " + encounter.name;
                guidance.confidence = "MEDIUM";
                guidance.evidence = encounter.name + " [ID " + std::to_string(encounter.id) + "] is IN_PROGRESS while the instance reports no active encounter.";
                guidance.verificationCommand = ".instance getbossstate";
                guidance.actionCommands = ".instance setbossstate " + std::to_string(encounter.id) + " 0;;.instance save";
                guidance.recheckCommand = ".instance getbossstate";
                guidance.expectedResult = encounter.name + " [ID " + std::to_string(encounter.id) + "] NOT_STARTED and available for a normal scripted attempt";
                guidance.safety = "Confirm that the group wiped or abandoned the pull and that nobody remains in combat. Never reset a legitimately active encounter.";
                result.push_back(std::move(guidance));
            }

    // Verified dependency profiles enrich the universal rules with doors, transports and
    // branching progression relationships that cannot be inferred safely from encounter order.
    for (ProgressionRule const& rule : Rules())
    {
        RecoveryEncounter const* prerequisite = FindEncounter(context, rule.prerequisite);
        if (context.mapId != rule.mapId || !prerequisite)
            continue;

        EncounterState prerequisiteState = prerequisite->state;
        std::vector<std::uint32_t> completed = CompletedDependants(context, rule);
        if (prerequisiteState == DONE || completed.empty())
            continue;

        std::string stateName = InstanceScript::GetBossStateName(prerequisiteState);
        RecoveryGuidance guidance;
        guidance.id = rule.id;
        guidance.title = rule.prerequisiteName;
        guidance.confidence = completed.size() >= 3 ? "HIGH" : "MEDIUM";
        guidance.evidence = rule.prerequisiteName + " [ID " + std::to_string(rule.prerequisite) + "] is " + stateName +
            ", while dependant encounter IDs " + JoinIds(completed) + " are DONE. This saved progression is inconsistent.";
        guidance.verificationCommand = ".instance getbossstate";
        guidance.actionCommands = ".instance setbossstate " + std::to_string(rule.prerequisite) + " 3;;.instance save";
        guidance.recheckCommand = ".instance getbossstate";
        guidance.expectedResult = rule.prerequisiteName + " [ID " + std::to_string(rule.prerequisite) + "] DONE; " + rule.consequence;
        guidance.safety = "Confirm that the encounter was legitimately completed in this lockout. Do not apply the repair when the boss was never defeated.";
        bool duplicate = std::any_of(result.begin(), result.end(), [&guidance](RecoveryGuidance const& existing) { return existing.actionCommands == guidance.actionCommands; });
        if (!duplicate)
            result.push_back(std::move(guidance));
    }
    return result;
}
}
