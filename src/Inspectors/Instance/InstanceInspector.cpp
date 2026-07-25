#include "InstanceInspector.h"

#include "Chat.h"
#include "DBCStores.h"
#include "DisableMgr.h"
#include "Group.h"
#include "InstanceSaveMgr.h"
#include "InstanceScript.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "Utilities/AzerCoreOpsText.h"
#include "Util.h"
#include "World.h"

#include <sstream>
#include <string>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace AzerCoreOps
{
namespace
{
std::string QuestName(uint32 id)
{
    if (Quest const* quest = sObjectMgr->GetQuestTemplate(id))
        return Clean(quest->GetTitle());
    return "Unknown quest";
}

std::string ItemName(uint32 id)
{
    if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(id))
        return Clean(item->Name1);
    return "Unknown item";
}

std::string AchievementName(uint32 id)
{
    if (AchievementEntry const* achievement = sAchievementStore.LookupEntry(id))
        return Clean(achievement->name[LOCALE_enUS]);
    return "Unknown achievement";
}

struct AuditResult
{
    std::vector<std::string> failures;
    std::vector<std::string> warnings;

    void Fail(std::string value) { failures.push_back(Clean(std::move(value))); }
    void Warn(std::string value) { warnings.push_back(Clean(std::move(value))); }

    std::string Result() const
    {
        if (!failures.empty()) return "FAIL";
        if (!warnings.empty()) return "WARN";
        return "PASS";
    }

    std::string Reasons() const
    {
        std::ostringstream out;
        auto append = [&out](std::vector<std::string> const& values)
        {
            for (std::string const& value : values)
            {
                if (out.tellp() > 0) out << "; ";
                out << value;
            }
        };
        append(failures);
        append(warnings);
        return out.str().empty() ? "All checked requirements passed" : out.str();
    }
};

bool AppliesTo(Player* player, ProgressionRequirement const* requirement)
{
    return requirement->faction == TEAM_NEUTRAL || requirement->faction == player->GetTeamId(true);
}

void CheckAccessRequirements(Player* player, Player* leader, DungeonProgressionRequirements const* requirements, AuditResult& audit)
{
    if (!requirements || player->IsGameMaster())
        return;

    if (!sWorld->getBoolConfig(CONFIG_INSTANCE_IGNORE_LEVEL))
    {
        if (requirements->levelMin && player->GetLevel() < requirements->levelMin)
            audit.Fail("Level " + std::to_string(player->GetLevel()) + "; requires at least " + std::to_string(requirements->levelMin));
        if (requirements->levelMax && player->GetLevel() > requirements->levelMax)
            audit.Fail("Level " + std::to_string(player->GetLevel()) + "; maximum is " + std::to_string(requirements->levelMax));
    }

    if (sWorld->getBoolConfig(CONFIG_DUNGEON_ACCESS_REQUIREMENTS_PORTAL_CHECK_ILVL))
    {
        uint32 itemLevel = uint32(player->GetAverageItemLevelForDF());
        if (requirements->reqItemLevel > itemLevel)
            audit.Fail("Average item level " + std::to_string(itemLevel) + "; requires " + std::to_string(requirements->reqItemLevel));
    }

    for (ProgressionRequirement const* requirement : requirements->quests)
    {
        Player* checked = requirement->checkLeaderOnly ? leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->GetQuestRewardStatus(requirement->id))
            audit.Fail(std::string(requirement->checkLeaderOnly ? "Leader missing quest " : "Missing quest ") + std::to_string(requirement->id) + " [" + QuestName(requirement->id) + "]" + (requirement->note.empty() ? "" : " - " + requirement->note));
    }

    for (ProgressionRequirement const* requirement : requirements->items)
    {
        Player* checked = requirement->checkLeaderOnly ? leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->HasItemCount(requirement->id, 1))
            audit.Fail(std::string(requirement->checkLeaderOnly ? "Leader missing item " : "Missing item ") + std::to_string(requirement->id) + " [" + ItemName(requirement->id) + "]" + (requirement->note.empty() ? "" : " - " + requirement->note));
    }

    for (ProgressionRequirement const* requirement : requirements->achievements)
    {
        Player* checked = requirement->checkLeaderOnly ? leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->HasAchieved(requirement->id))
            audit.Fail(std::string(requirement->checkLeaderOnly ? "Leader missing achievement " : "Missing achievement ") + std::to_string(requirement->id) + " [" + AchievementName(requirement->id) + "]" + (requirement->note.empty() ? "" : " - " + requirement->note));
    }
}

uint32 ReferenceInstanceId(Player* requester, uint32 mapId, Difficulty difficulty)
{
    if (requester->GetMapId() == mapId && requester->GetMap()->IsDungeon() && requester->GetMap()->GetDifficulty() == difficulty)
        return requester->GetInstanceId();

    if (InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(requester->GetGUID(), mapId, difficulty))
        return bind->save ? bind->save->GetInstanceId() : 0;

    return 0;
}

void AuditPlayer(Player* player, Player* requester, Player* leader, MapEntry const* entry, Difficulty difficulty, uint32 referenceId, AuditResult& audit)
{
    uint32 mapId = entry->MapID;

    if (player->IsGameMaster())
        audit.Warn("GM mode bypasses normal entrance requirements");

    if (entry->IsRaid() && (!player->GetGroup() || !player->GetGroup()->isRaidGroup()) && !sWorld->getBoolConfig(CONFIG_INSTANCE_IGNORE_RAID))
        audit.Fail("Raid group required");

    if (!GetMapDifficultyData(mapId, difficulty))
        audit.Fail("Difficulty " + std::to_string(uint32(difficulty)) + " is unavailable");

    if (sDisableMgr->IsDisabledFor(DISABLE_TYPE_MAP, mapId, player))
        audit.Fail("Instance is disabled for this player");

    if (!player->IsAlive())
    {
        if (!player->HasCorpse())
            audit.Fail("Dead with no corpse");
        else if (player->GetCorpseLocation().GetMapId() != mapId)
            audit.Fail("Corpse is on map " + std::to_string(player->GetCorpseLocation().GetMapId()));
    }

    CheckAccessRequirements(player, leader, sObjectMgr->GetAccessRequirement(mapId, difficulty), audit);

    InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(player->GetGUID(), mapId, difficulty);
    uint32 playerBindId = bind && bind->save ? bind->save->GetInstanceId() : 0;
    if (bind && bind->perm && referenceId && playerBindId != referenceId)
        audit.Fail("Permanent lockout conflict: player ID " + std::to_string(playerBindId) + ", requester ID " + std::to_string(referenceId));
    else if (playerBindId && referenceId && playerBindId == referenceId)
        audit.Warn("Already bound to requester's instance ID " + std::to_string(referenceId));
    else if (playerBindId && !referenceId)
        audit.Warn("Player has instance ID " + std::to_string(playerBindId) + "; requester has no reference ID");

    uint32 countCheckId = playerBindId ? playerBindId : referenceId;
    if (entry->IsNonRaidDungeon() && !player->CheckInstanceCount(countCheckId))
        audit.Fail("Five-instances-per-hour limit reached");

    if (referenceId)
    {
        if (Map* destination = sMapMgr->FindMap(mapId, referenceId))
        {
            if (InstanceMap* instance = destination->ToInstanceMap())
            {
                if (instance->GetPlayersCountExceptGMs() >= instance->GetMaxPlayers())
                    audit.Fail("Reference instance is full");
                if ((instance->IsRaid() || mapId == 668) && instance->GetInstanceScript() && instance->GetInstanceScript()->IsEncounterInProgress() && player->GetInstanceId() != referenceId)
                    audit.Fail("Boss encounter is in progress");
            }
        }
    }

    if (player->GetMapId() == mapId)
    {
        if (referenceId && player->GetInstanceId() != referenceId)
            audit.Fail("Currently inside different instance ID " + std::to_string(player->GetInstanceId()));
        if (requester->GetMapId() == mapId && requester->GetInstanceId() == player->GetInstanceId() && !(requester->GetPhaseMask() & player->GetPhaseMask()))
            audit.Fail("Same instance but phase masks do not overlap (you " + std::to_string(requester->GetPhaseMask()) + ", player " + std::to_string(player->GetPhaseMask()) + ")");
        if (!player->isGMVisible())
            audit.Fail("Player is GM-invisible");
    }
    else
        audit.Warn("Currently outside target map (on map " + std::to_string(player->GetMapId()) + ")");
}
}

bool InstanceInspector::Search(ChatHandler* handler, Tail search)
{
    if (search.empty())
        return false;

    std::wstring needle;
    if (!Utf8toWStr(search, needle))
        return false;
    wstrToLower(needle);

    uint32 count = 0;
    for (MapEntry const* entry : sMapStore)
    {
        if (!entry || !entry->IsDungeon())
            continue;
        std::string name = LocalizedMapName(entry, handler);
        if (!Utf8FitTo(name, needle))
            continue;
        Protocol::SendInstanceSearch(handler, entry->MapID, name, entry->IsRaid() ? "raid" : "dungeon", entry->maxPlayers);
        if (++count >= 12)
            break;
    }
    Protocol::SendInstanceSearchEnd(handler, count);
    return true;
}

bool InstanceInspector::Audit(ChatHandler* handler, uint32 mapId, Acore::ChatCommands::Optional<uint8> difficultyArg)
{
    Player* requester = handler->GetSession()->GetPlayer();
    MapEntry const* entry = sMapStore.LookupEntry(mapId);
    if (!entry || !entry->IsDungeon())
    {
        Protocol::SendError(handler, "Map " + std::to_string(mapId) + " is not an instance");
        return true;
    }

    Difficulty difficulty = difficultyArg ? Difficulty(*difficultyArg) : requester->GetDifficulty(entry->IsRaid());
    Group* group = requester->GetGroup();
    Player* leader = group ? group->GetLeader() : requester;
    if (!leader)
        leader = requester;
    uint32 referenceId = ReferenceInstanceId(requester, mapId, difficulty);

    Protocol::SendInstanceBegin(handler, mapId, LocalizedMapName(entry, handler), uint32(difficulty), referenceId, group ? group->GetMembersCount() : 1);

    auto emit = [&](Player* player, std::string const& fallbackName)
    {
        if (!player)
        {
            Protocol::SendInstanceMember(handler, fallbackName, "OFFLINE", 0, 0, 0, "Player is offline");
            return;
        }

        AuditResult audit;
        AuditPlayer(player, requester, leader, entry, difficulty, referenceId, audit);
        Protocol::SendInstanceMember(handler, player->GetName(), audit.Result(), player->GetMapId(), player->GetInstanceId(), player->GetPhaseMask(), audit.Reasons());
    };

    if (group)
        for (Group::MemberSlot const& member : group->GetMemberSlots())
            emit(ObjectAccessor::FindConnectedPlayer(member.guid), member.name);
    else
        emit(requester, requester->GetName());

    Protocol::SendInstanceEnd(handler);
    return true;
}
}
