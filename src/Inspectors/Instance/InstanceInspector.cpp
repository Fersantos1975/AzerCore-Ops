#include "InstanceInspector.h"

#include "Chat.h"
#include "DBCStores.h"
#include "DisableMgr.h"
#include "Group.h"
#include "GameTime.h"
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

#include <algorithm>
#include <cctype>
#include <sstream>
#include <set>
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

struct BindSnapshot
{
    uint32 id{0};
    bool permanent{false};
    bool extended{false};
    bool canReset{false};
    uint32 encounterMask{0};
    uint32 bossTotal{0};
    uint32 bossDefeated{0};
};

std::vector<DungeonEncounter const*> EncountersFor(uint32 mapId, Difficulty difficulty)
{
    DungeonEncounterList const* source = nullptr;
    if ((mapId == 631 || mapId == 724) && (difficulty == RAID_DIFFICULTY_10MAN_HEROIC || difficulty == RAID_DIFFICULTY_25MAN_HEROIC))
        source = sObjectMgr->GetDungeonEncounterList(mapId, difficulty == RAID_DIFFICULTY_10MAN_HEROIC ? RAID_DIFFICULTY_10MAN_NORMAL : RAID_DIFFICULTY_25MAN_NORMAL);
    else
        source = sObjectMgr->GetDungeonEncounterList(mapId, IsSharedDifficultyMap(mapId) ? Difficulty(difficulty % 2) : difficulty);
    std::vector<DungeonEncounter const*> result;
    if (source) result.assign(source->begin(), source->end());
    std::sort(result.begin(), result.end(), [](DungeonEncounter const* a, DungeonEncounter const* b) { return a->dbcEntry->encounterIndex < b->dbcEntry->encounterIndex; });
    return result;
}

BindSnapshot SnapshotBind(InstancePlayerBind const* bind)
{
    BindSnapshot snapshot;
    if (!bind || !bind->save) return snapshot;
    snapshot.id = bind->save->GetInstanceId();
    snapshot.permanent = bind->perm;
    snapshot.extended = bind->extended;
    snapshot.canReset = bind->save->CanReset();
    snapshot.encounterMask = bind->save->GetCompletedEncounterMask();
    std::set<uint32> indexes;
    for (DungeonEncounter const* encounter : EncountersFor(bind->save->GetMapId(), bind->save->GetDifficulty()))
        if (encounter && encounter->dbcEntry && indexes.insert(encounter->dbcEntry->encounterIndex).second)
        {
            ++snapshot.bossTotal;
            if (encounter->dbcEntry->encounterIndex < 32 && (snapshot.encounterMask & (1u << encounter->dbcEntry->encounterIndex))) ++snapshot.bossDefeated;
        }
    return snapshot;
}

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

BindSnapshot AuditPlayer(Player* player, Player* requester, Player* leader, MapEntry const* entry, Difficulty difficulty, uint32 referenceId, AuditResult& audit)
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
    BindSnapshot snapshot = SnapshotBind(bind);
    uint32 playerBindId = snapshot.id;
    if (bind && bind->perm && referenceId && playerBindId != referenceId)
        audit.Fail("Permanent lockout conflict: player ID " + std::to_string(playerBindId) + ", requester ID " + std::to_string(referenceId));
    else if (playerBindId && referenceId && playerBindId != referenceId)
        audit.Warn("Different temporary instance ID: player ID " + std::to_string(playerBindId) + ", requester ID " + std::to_string(referenceId));
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
    return snapshot;
}
}

bool InstanceInspector::Search(ChatHandler* handler, Tail search)
{
    if (search.empty())
        return false;

    std::string query(search);
    if (Optional<uint32> mapId = Acore::StringTo<uint32>(query, 10))
    {
        uint32 count = 0;
        if (MapEntry const* entry = sMapStore.LookupEntry(*mapId); entry && entry->IsDungeon())
        {
            Protocol::SendInstanceSearch(handler, entry->MapID, LocalizedMapName(entry, handler), entry->IsRaid() ? "raid" : "dungeon", entry->maxPlayers);
            count = 1;
        }
        Protocol::SendInstanceSearchEnd(handler, count);
        return true;
    }

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

bool InstanceInspector::Binds(ChatHandler* handler, Tail scopeArg)
{
    std::string scope(scopeArg);
    std::transform(scope.begin(), scope.end(), scope.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    Player* player = scope == "target" ? handler->getSelectedPlayer() : handler->GetSession()->GetPlayer();
    if (!player) { Protocol::SendError(handler, "Select an online player before inspecting target binds"); return true; }
    if (handler->HasLowerSecurity(player)) { Protocol::SendError(handler, "You cannot inspect binds for a player with higher security"); return true; }
    scope = scope == "target" ? "TARGET" : "SELF";
    uint32 count = 0;
    for (uint8 i = 0; i < MAX_DIFFICULTY; ++i) count += sInstanceSaveMgr->PlayerGetBoundInstances(player->GetGUID(), Difficulty(i)).size();
    Protocol::SendBindBegin(handler, player->GetName(), scope, count);
    uint32 emitted = 0;
    for (uint8 i = 0; i < MAX_DIFFICULTY; ++i)
        for (auto const& [mapId, bind] : sInstanceSaveMgr->PlayerGetBoundInstances(player->GetGUID(), Difficulty(i)))
        {
            if (!bind.save) continue;
            InstanceSave const* save = bind.save;
            MapEntry const* entry = sMapStore.LookupEntry(mapId);
            uint32 resetTime = bind.extended ? save->GetExtendedResetTime() : save->GetResetTime();
            uint32 now = uint32(GameTime::GetGameTime().count());
            bool applicable = player->GetMapId() != mapId;
            std::string reason = applicable ? (bind.perm ? "Permanent bind; GM unbind will discard this character lockout" : "Bind may be unbound") : "Player is currently inside this map; leave the instance before unbinding";
            BindSnapshot snapshot = SnapshotBind(&bind);
            Protocol::SendBindEntry(handler, mapId, entry ? LocalizedMapName(entry, handler) : ("Map " + std::to_string(mapId)), entry && entry->IsRaid() ? "raid" : "dungeon", snapshot.id, uint32(save->GetDifficulty()), snapshot.permanent, snapshot.extended, snapshot.canReset, applicable, resetTime >= now ? resetTime - now : 0, snapshot.encounterMask, snapshot.bossTotal, snapshot.bossDefeated, reason);
            std::set<uint32> sent;
            for (DungeonEncounter const* encounter : EncountersFor(mapId, save->GetDifficulty()))
            {
                if (!encounter || !encounter->dbcEntry || !sent.insert(encounter->dbcEntry->encounterIndex).second) continue;
                uint32 index = encounter->dbcEntry->encounterIndex;
                char const* name = encounter->dbcEntry->encounterName[0];
                Protocol::SendBindBoss(handler, mapId, snapshot.id, uint32(save->GetDifficulty()), index, index < 32 && (snapshot.encounterMask & (1u << index)) != 0, name ? name : "Unknown boss");
            }
            ++emitted;
        }
    Protocol::SendBindEnd(handler, player->GetName(), emitted);
    return true;
}

bool InstanceInspector::Unbind(ChatHandler* handler, Tail selectionsArg)
{
    Player* player = handler->getSelectedPlayer();
    if (!player) { Protocol::SendError(handler, "Select an online player before unbinding instances"); return true; }
    if (handler->HasLowerSecurity(player)) { Protocol::SendError(handler, "You cannot change binds for a player with higher security"); return true; }
    struct Selection { uint32 map; uint32 difficulty; uint32 instance; };
    std::vector<Selection> selections;
    std::stringstream stream{std::string(selectionsArg)};
    std::string token;
    while (std::getline(stream, token, ','))
    {
        Selection selection{}; char first = 0, second = 0; std::stringstream item(token);
        if ((item >> selection.map >> first >> selection.difficulty >> second >> selection.instance) && first == ':' && second == ':' && selection.map && selection.difficulty < MAX_DIFFICULTY && selection.instance) selections.push_back(selection);
    }
    if (selections.empty()) { Protocol::SendError(handler, "No valid bind selections supplied; expected map:difficulty:instance entries"); return true; }
    std::string operation = std::to_string(GameTime::GetGameTime().count()) + "-" + player->GetName();
    Protocol::SendUnbindBegin(handler, operation, player->GetName(), selections.size());
    uint32 succeeded = 0, failed = 0;
    for (Selection const& selection : selections)
    {
        Difficulty difficulty = Difficulty(selection.difficulty);
        InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(player->GetGUID(), selection.map, difficulty);
        if (!bind || !bind->save) { Protocol::SendUnbindResult(handler, operation, selection.map, selection.difficulty, selection.instance, "FAILED", "Bind no longer exists; refresh and try again"); ++failed; continue; }
        if (bind->save->GetInstanceId() != selection.instance) { Protocol::SendUnbindResult(handler, operation, selection.map, selection.difficulty, selection.instance, "FAILED", "Instance ID changed since selection; no action taken"); ++failed; continue; }
        if (player->GetMapId() == selection.map) { Protocol::SendUnbindResult(handler, operation, selection.map, selection.difficulty, selection.instance, "FAILED", "Player is currently inside this map"); ++failed; continue; }
        sInstanceSaveMgr->PlayerUnbindInstance(player->GetGUID(), selection.map, difficulty, true, player);
        if (sInstanceSaveMgr->PlayerGetBoundInstance(player->GetGUID(), selection.map, difficulty)) { Protocol::SendUnbindResult(handler, operation, selection.map, selection.difficulty, selection.instance, "FAILED", "Server verification found the bind still present"); ++failed; }
        else { Protocol::SendUnbindResult(handler, operation, selection.map, selection.difficulty, selection.instance, "SUCCESS", "Bind removed and verified"); ++succeeded; }
    }
    Protocol::SendUnbindEnd(handler, operation, succeeded, failed);
    return true;
}

bool InstanceInspector::Audit(ChatHandler* handler, uint32 mapId, Optional<uint8> difficultyArg)
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
            Protocol::SendInstanceMember(handler, fallbackName, "OFFLINE", 0, 0, 0, 0, false, false, false, 0, 0, 0, "Player is offline");
            return;
        }

        AuditResult audit;
        BindSnapshot bind = AuditPlayer(player, requester, leader, entry, difficulty, referenceId, audit);
        Protocol::SendInstanceMember(handler, player->GetName(), audit.Result(), player->GetMapId(), player->GetInstanceId(), player->GetPhaseMask(), bind.id, bind.permanent, bind.extended, bind.canReset, bind.encounterMask, bind.bossTotal, bind.bossDefeated, audit.Reasons());
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
