#include "QuestInspector.h"

#include "Chat.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "QuestDef.h"
#include "Utilities/AzerCoreOpsText.h"
#include "Util.h"

#include <cstdlib>
#include <functional>
#include <set>
#include <sstream>
#include <string>
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

std::string QuestFaction(Quest const* quest)
{
    constexpr uint32 AllianceMask = 0x44D;
    constexpr uint32 HordeMask = 0x2B2;
    uint32 mask = quest->GetAllowableRaces();
    if (!mask)
        return "BOTH";

    bool alliance = (mask & AllianceMask) != 0;
    bool horde = (mask & HordeMask) != 0;
    if (alliance && horde) return "BOTH";
    if (alliance) return "ALLIANCE";
    if (horde) return "HORDE";
    return "UNKNOWN";
}

std::string QuestStatusName(Player* player, Quest const* quest)
{
    if (!quest)
        return "UNKNOWN";
    uint32 id = quest->GetQuestId();
    if (player->GetQuestRewardStatus(id))
        return "REWARDED";

    switch (player->GetQuestStatus(id))
    {
        case QUEST_STATUS_COMPLETE: return "COMPLETE";
        case QUEST_STATUS_INCOMPLETE: return "ACTIVE";
        case QUEST_STATUS_FAILED: return "FAILED";
        default: return "NONE";
    }
}

std::string QuestEligibility(Player* player, Quest const* quest, std::string& reason)
{
    std::string status = QuestStatusName(player, quest);
    if (status == "REWARDED")
    {
        reason = "Already rewarded";
        return "REWARDED";
    }
    if (status == "COMPLETE" || status == "ACTIVE" || status == "FAILED")
    {
        reason = status == "COMPLETE" ? "Ready to reward" : (status == "ACTIVE" ? "Already in quest log" : "Quest is failed");
        return status;
    }
    if (player->CanTakeQuest(quest, false))
    {
        reason = "All checked acceptance requirements passed";
        return "AVAILABLE";
    }

    std::vector<std::string> failures;
    auto check = [&failures](bool passed, char const* text) { if (!passed) failures.emplace_back(text); };
    check(player->SatisfyQuestRace(quest, false), "Wrong faction or race");
    check(player->SatisfyQuestClass(quest, false), "Wrong class");
    check(player->SatisfyQuestLevel(quest, false), "Level requirement not met");
    check(player->SatisfyQuestPreviousQuest(quest, false), "Missing prerequisite quest");
    check(player->SatisfyQuestReputation(quest, false), "Reputation requirement not met");
    check(player->SatisfyQuestStatus(quest, false), "Quest status blocks acceptance");
    check(player->SatisfyQuestExclusiveGroup(quest, false), "Exclusive quest-group conflict");
    check(player->SatisfyQuestBreadcrumb(quest, false), "Breadcrumb quest conflict");
    check(player->SatisfyQuestNextChain(quest, false), "Later chain quest already active or complete");
    check(player->SatisfyQuestPrevChain(quest, false), "Previous chain quest still active");
    check(player->SatisfyQuestDay(quest, false), "Daily quest already completed today");
    check(player->SatisfyQuestWeek(quest, false), "Weekly quest already completed this week");
    check(player->SatisfyQuestMonth(quest, false), "Monthly quest already completed");
    check(player->SatisfyQuestSeasonal(quest, false), "Seasonal quest requirement not met");
    check(player->SatisfyQuestTimed(quest, false), "Another timed quest is active");
    check(player->SatisfyQuestConditions(quest, false), "Additional server condition not met");

    std::ostringstream out;
    for (std::string const& failure : failures)
    {
        if (out.tellp() > 0) out << "; ";
        out << failure;
    }
    reason = out.str().empty() ? "Blocked by an acceptance requirement not exposed by the core" : out.str();
    return "BLOCKED";
}

std::string QuestTypeName(Quest const* quest)
{
    if (quest->IsDaily()) return "Daily";
    if (quest->IsWeekly()) return "Weekly";
    switch (quest->GetType())
    {
        case QUEST_TYPE_ELITE: return "Group/Elite";
        case QUEST_TYPE_PVP: return "PvP";
        case QUEST_TYPE_RAID: return "Raid";
        case QUEST_TYPE_DUNGEON: return "Dungeon";
        case QUEST_TYPE_WORLD_EVENT: return "World event";
        case QUEST_TYPE_LEGENDARY: return "Legendary";
        case QUEST_TYPE_ESCORT: return "Escort";
        case QUEST_TYPE_HEROIC: return "Heroic";
        case QUEST_TYPE_RAID_10: return "Raid 10";
        case QUEST_TYPE_RAID_25: return "Raid 25";
        default: return quest->IsRepeatable() ? "Repeatable" : "Normal";
    }
}

std::string QuestItems(Quest const* quest)
{
    std::ostringstream out;
    for (uint8 i = 0; i < QUEST_ITEM_OBJECTIVES_COUNT; ++i)
    {
        if (!quest->RequiredItemId[i])
            continue;
        if (out.tellp() > 0) out << ", ";
        out << quest->RequiredItemId[i] << " [" << ItemName(quest->RequiredItemId[i]) << "] x" << quest->RequiredItemCount[i];
    }
    return out.str().empty() ? "None" : Clean(out.str());
}

std::string QuestReputation(Quest const* quest)
{
    std::ostringstream out;
    if (quest->GetRequiredMinRepFaction())
        out << "Faction " << quest->GetRequiredMinRepFaction() << " >= " << quest->GetRequiredMinRepValue();
    if (quest->GetRequiredMaxRepFaction())
    {
        if (out.tellp() > 0) out << ", ";
        out << "Faction " << quest->GetRequiredMaxRepFaction() << " < " << quest->GetRequiredMaxRepValue();
    }
    return out.str().empty() ? "None" : out.str();
}

std::string QuestSources(uint32 questId, bool enders)
{
    std::vector<std::string> sources;
    QuestRelations* creatureRelations = enders ? sObjectMgr->GetCreatureQuestInvolvedRelationMap() : sObjectMgr->GetCreatureQuestRelationMap();
    for (auto const& relation : *creatureRelations)
    {
        if (relation.second != questId || sources.size() >= 4)
            continue;
        CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(relation.first);
        sources.push_back((creature ? Clean(creature->Name) : "Creature") + " [" + std::to_string(relation.first) + "]");
    }

    QuestRelations* goRelations = enders ? sObjectMgr->GetGOQuestInvolvedRelationMap() : sObjectMgr->GetGOQuestRelationMap();
    for (auto const& relation : *goRelations)
    {
        if (relation.second != questId || sources.size() >= 4)
            continue;
        GameObjectTemplate const* object = sObjectMgr->GetGameObjectTemplate(relation.first);
        sources.push_back((object ? Clean(object->name) : "GameObject") + " [" + std::to_string(relation.first) + "]");
    }

    std::ostringstream out;
    for (std::string const& source : sources)
    {
        if (out.tellp() > 0) out << ", ";
        out << source;
    }
    return out.str().empty() ? "Not listed" : out.str();
}
}

bool QuestInspector::Search(ChatHandler* handler, Tail search)
{
    if (search.empty())
        return false;

    std::wstring needle;
    if (!Utf8toWStr(search, needle))
        return false;
    wstrToLower(needle);

    Player* player = handler->getSelectedPlayerOrSelf();
    uint32 count = 0;
    for (auto const& pair : sObjectMgr->GetQuestTemplates())
    {
        Quest const* quest = pair.second;
        if (!quest || !Utf8FitTo(quest->GetTitle(), needle))
            continue;

        std::string reason;
        std::string eligibility = QuestEligibility(player, quest, reason);
        Protocol::SendQuestSearch(handler, quest->GetQuestId(), quest->GetTitle(), QuestFaction(quest), eligibility,
            QuestStatusName(player, quest), quest->GetMinLevel(), quest->GetQuestLevel(), QuestTypeName(quest), player->GetName());
        if (++count >= 12)
            break;
    }
    Protocol::SendQuestSearchEnd(handler, count);
    return true;
}

bool QuestInspector::Info(ChatHandler* handler, uint32 questId)
{
    Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
    if (!quest)
    {
        Protocol::SendQuestError(handler, "Quest " + std::to_string(questId) + " does not exist");
        return true;
    }

    Player* player = handler->getSelectedPlayerOrSelf();
    std::string reason;
    std::string eligibility = QuestEligibility(player, quest, reason);
    Protocol::SendQuestInfo(handler, quest->GetQuestId(), quest->GetTitle(), QuestFaction(quest), quest->GetMinLevel(),
        quest->GetQuestLevel(), QuestTypeName(quest), quest->IsRepeatable(), QuestStatusName(player, quest), eligibility,
        reason, QuestItems(quest), QuestReputation(quest), player->GetName(), QuestSources(questId, false), QuestSources(questId, true));

    uint32 emitted = 0;
    std::set<uint32> visited;
    visited.insert(questId);
    std::function<void(Quest const*, uint32)> emitPrevious = [&](Quest const* current, uint32 depth)
    {
        if (!current || depth > 12 || emitted >= 32)
            return;
        for (int32 previous : current->prevQuests)
        {
            uint32 id = uint32(std::abs(previous));
            if (!id || !visited.insert(id).second)
                continue;
            Quest const* linked = sObjectMgr->GetQuestTemplate(id);
            emitPrevious(linked, depth + 1);
            std::string linkedReason;
            std::string linkedEligibility = linked ? QuestEligibility(player, linked, linkedReason) : "UNKNOWN";
            Protocol::SendQuestChain(handler, "PREVIOUS", id, QuestName(id), linked ? QuestStatusName(player, linked) : "UNKNOWN",
                linkedEligibility, linked ? QuestFaction(linked) : "UNKNOWN", previous < 0 ? "alternative" : "required", depth, linkedReason);
            ++emitted;
            if (emitted >= 32)
                return;
        }
    };
    emitPrevious(quest, 1);

    Quest const* current = quest;
    for (uint32 depth = 1; current && depth <= 12 && emitted < 32; ++depth)
    {
        uint32 id = current->GetNextQuestInChain();
        if (!id)
            id = current->GetNextQuestId();
        if (!id || !visited.insert(id).second)
            break;
        Quest const* linked = sObjectMgr->GetQuestTemplate(id);
        std::string linkedReason;
        std::string linkedEligibility = linked ? QuestEligibility(player, linked, linkedReason) : "UNKNOWN";
        Protocol::SendQuestChain(handler, "NEXT", id, QuestName(id), linked ? QuestStatusName(player, linked) : "UNKNOWN",
            linkedEligibility, linked ? QuestFaction(linked) : "UNKNOWN", "next", depth, linkedReason);
        ++emitted;
        current = linked;
    }
    Protocol::SendQuestInfoEnd(handler, questId, emitted);
    return true;
}
bool QuestInspector::Audit(ChatHandler* handler, uint32 questId)
{
    Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
    if (!quest)
    {
        Protocol::SendQuestError(handler, "Quest " + std::to_string(questId) + " does not exist");
        return true;
    }

    Player* requester = handler->GetSession()->GetPlayer();
    Group* group = requester->GetGroup();
    Protocol::SendQuestAuditBegin(handler, questId, quest->GetTitle(), group ? group->GetMembersCount() : 1);

    auto emit = [&](Player* player, std::string const& fallbackName)
    {
        if (!player)
        {
            Protocol::SendQuestAuditMember(handler, fallbackName, "OFFLINE", "UNKNOWN", "UNKNOWN", "Player is offline");
            return;
        }

        std::string reason;
        std::string eligibility = QuestEligibility(player, quest, reason);
        std::string status = QuestStatusName(player, quest);
        std::string result = (eligibility == "AVAILABLE" || status == "ACTIVE" || status == "COMPLETE" || status == "REWARDED") ? "PASS" : "FAIL";
        Protocol::SendQuestAuditMember(handler, player->GetName(), result, status, eligibility, reason);
    };

    if (group)
        for (Group::MemberSlot const& member : group->GetMemberSlots())
            emit(ObjectAccessor::FindConnectedPlayer(member.guid), member.name);
    else
        emit(requester, requester->GetName());

    Protocol::SendQuestAuditEnd(handler);
    return true;
}

bool QuestInspector::Log(ChatHandler* handler)
{
    Player* player = handler->getSelectedPlayer();
    if (!player)
    {
        Protocol::SendQuestError(handler, "Select an online player target before inspecting their quest log");
        return true;
    }
    if (handler->HasLowerSecurity(player))
    {
        Protocol::SendQuestError(handler, "You cannot inspect the quest log of a player with higher security");
        return true;
    }

    uint32 count = 0;
    for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
        if (player->GetQuestSlotQuestId(slot))
            ++count;

    Protocol::SendQuestLogBegin(handler, player->GetName(), count);
    uint32 emitted = 0;
    for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
    {
        uint32 questId = player->GetQuestSlotQuestId(slot);
        if (!questId)
            continue;

        Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
        if (!quest)
        {
            Protocol::SendQuestLogEntry(handler, slot + 1, questId, "Unknown quest", "UNKNOWN", 0, 0, "Unknown", "UNKNOWN");
            ++emitted;
            continue;
        }

        Protocol::SendQuestLogEntry(handler, slot + 1, questId, quest->GetTitle(), QuestStatusName(player, quest),
            quest->GetMinLevel(), quest->GetQuestLevel(), QuestTypeName(quest), QuestFaction(quest));
        ++emitted;
    }
    Protocol::SendQuestLogEnd(handler, player->GetName(), emitted);
    return true;
}

}
