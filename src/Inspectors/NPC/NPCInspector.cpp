#include "NPCInspector.h"

#include "Chat.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "QuestDef.h"

#include <string>
#include <unordered_set>
#include <vector>

namespace AzerCoreOps
{
namespace
{
std::string QuestStatus(Player* player, Quest const* quest)
{
    if (!player || !quest) return "UNKNOWN";
    uint32 id = quest->GetQuestId();
    if (player->GetQuestRewardStatus(id)) return "REWARDED";
    switch (player->GetQuestStatus(id))
    {
        case QUEST_STATUS_COMPLETE: return "READY";
        case QUEST_STATUS_INCOMPLETE: return "ACTIVE";
        case QUEST_STATUS_FAILED: return "FAILED";
        default: return "NONE";
    }
}

std::string QuestEligibility(Player* player, Quest const* quest, std::string& reason)
{
    std::string status = QuestStatus(player, quest);
    if (status == "REWARDED") { reason = quest->IsRepeatable() ? "Previously completed; repeat rules apply" : "Previously completed and rewarded"; return "COMPLETED"; }
    if (status == "READY") { reason = "Objectives complete; ready to turn in"; return "READY"; }
    if (status == "ACTIVE") { reason = "Currently in the quest log"; return "ACTIVE"; }
    if (status == "FAILED") { reason = "Quest is currently failed"; return "FAILED"; }
    if (player->CanTakeQuest(quest, false)) { reason = "All checked requirements passed"; return "AVAILABLE"; }

    std::vector<std::string> failures;
    auto check = [&failures](bool passed, char const* text) { if (!passed) failures.emplace_back(text); };
    check(player->SatisfyQuestRace(quest, false), "Wrong faction or race");
    check(player->SatisfyQuestClass(quest, false), "Wrong class");
    check(player->SatisfyQuestLevel(quest, false), "Level requirement not met");
    check(player->SatisfyQuestPreviousQuest(quest, false), "Missing prerequisite quest");
    check(player->SatisfyQuestReputation(quest, false), "Reputation requirement not met");
    check(player->SatisfyQuestExclusiveGroup(quest, false), "Exclusive quest conflict");
    check(player->SatisfyQuestBreadcrumb(quest, false), "Breadcrumb quest conflict");
    check(player->SatisfyQuestDay(quest, false), "Daily quest already completed today");
    check(player->SatisfyQuestWeek(quest, false), "Weekly quest already completed this week");
    check(player->SatisfyQuestConditions(quest, false), "Additional server condition not met");
    reason.clear();
    for (std::string const& failure : failures)
    {
        if (!reason.empty()) reason += "; ";
        reason += failure;
    }
    if (reason.empty()) reason = "Future quest blocked by a requirement not exposed by the core";
    return "FUTURE";
}

std::string QuestType(Quest const* quest)
{
    if (quest->IsDaily()) return "Daily";
    if (quest->IsWeekly()) return "Weekly";
    if (quest->IsRepeatable()) return "Repeatable";
    switch (quest->GetType())
    {
        case QUEST_TYPE_ELITE: return "Group/Elite";
        case QUEST_TYPE_PVP: return "PvP";
        case QUEST_TYPE_RAID: return "Raid";
        case QUEST_TYPE_DUNGEON: return "Dungeon";
        case QUEST_TYPE_LEGENDARY: return "Legendary";
        case QUEST_TYPE_ESCORT: return "Escort";
        case QUEST_TYPE_HEROIC: return "Heroic";
        default: return "Normal";
    }
}
}

bool NPCInspector::Inspect(ChatHandler* handler)
{
    if (!handler || !handler->GetSession()) return false;
    Creature* creature = handler->getSelectedCreature();
    Player* player = handler->GetSession()->GetPlayer();
    if (!creature || !player)
    {
        Protocol::SendNPCError(handler, "Select a creature before using Inspect NPC");
        return true;
    }

    CreatureTemplate const* data = creature->GetCreatureTemplate();
    uint32 entry = creature->GetEntry();
    Protocol::SendNPCBegin(handler, creature->GetName(), entry, std::to_string(creature->GetGUID().GetCounter()), player->GetName());
    Protocol::SendNPCOverview(handler, creature->getLevel(), data ? data->minlevel : creature->getLevel(), data ? data->maxlevel : creature->getLevel(), data ? data->rank : 0, data ? data->type : 0, data ? data->family : 0, data ? data->faction : 0, data ? data->npcflag : 0);
    Protocol::SendNPCState(handler, creature->IsAlive(), creature->IsInCombat(), creature->GetHealth(), creature->GetMaxHealth(), creature->getPowerType(), creature->GetPower(creature->getPowerType()), creature->GetMaxPower(creature->getPowerType()));
    Protocol::SendNPCLocation(handler, creature->GetMapId(), creature->GetZoneId(), creature->GetAreaId(), creature->GetInstanceId(), creature->GetPhaseMask(), creature->GetPositionX(), creature->GetPositionY(), creature->GetPositionZ(), creature->GetOrientation());
    if (data)
        Protocol::SendNPCTechnical(handler, data->unit_flags, data->dynamicflags, data->lootid, data->pickpocketLootId, data->SkinLootId, data->mingold, data->maxgold, data->AIName, data->ScriptID);

    uint32 questCount = 0;
    uint32 storyCount = 0;
    std::unordered_set<uint32> storyQuests;
    auto emitRelations = [&](QuestRelations* relations, char const* relation)
    {
        for (auto const& pair : *relations)
        {
            if (pair.first != entry) continue;
            Quest const* quest = sObjectMgr->GetQuestTemplate(pair.second);
            if (!quest) continue;
            std::string reason;
            std::string eligibility = QuestEligibility(player, quest, reason);
            Protocol::SendNPCQuest(handler, relation, quest->GetQuestId(), quest->GetTitle(), QuestStatus(player, quest), eligibility, reason, quest->GetMinLevel(), quest->GetQuestLevel(), QuestType(quest), quest->IsRepeatable());
            if (storyQuests.insert(quest->GetQuestId()).second)
            {
                storyCount += Protocol::SendNPCStory(handler, "QUEST_DETAILS", quest->GetQuestId(), quest->GetTitle(), quest->GetDetails());
                storyCount += Protocol::SendNPCStory(handler, "QUEST_OBJECTIVES", quest->GetQuestId(), quest->GetTitle(), quest->GetObjectives());
                storyCount += Protocol::SendNPCStory(handler, "QUEST_REQUEST", quest->GetQuestId(), quest->GetTitle(), quest->GetRequestItemsText());
                storyCount += Protocol::SendNPCStory(handler, "QUEST_REWARD", quest->GetQuestId(), quest->GetTitle(), quest->GetOfferRewardText());
                storyCount += Protocol::SendNPCStory(handler, "QUEST_COMPLETED", quest->GetQuestId(), quest->GetTitle(), quest->GetCompletedText());
            }
            ++questCount;
        }
    };
    emitRelations(sObjectMgr->GetCreatureQuestRelationMap(), "START");
    emitRelations(sObjectMgr->GetCreatureQuestInvolvedRelationMap(), "END");

    QueryResult speech = WorldDatabase.Query("SELECT GroupID, ID, Text FROM creature_text WHERE CreatureID = {} ORDER BY GroupID, ID LIMIT 100", entry);
    if (speech)
    {
        do
        {
            Field* fields = speech->Fetch();
            uint32 sourceId = fields[0].Get<uint32>() * 1000 + fields[1].Get<uint32>();
            storyCount += Protocol::SendNPCStory(handler, "SPOKEN_LINE", sourceId, creature->GetName(), fields[2].Get<std::string>());
        } while (speech->NextRow());
    }

    QueryResult gossip = WorldDatabase.Query(
        "SELECT nt.ID, COALESCE(NULLIF(nt.text0_0,''),NULLIF(nt.text0_1,''),''), COALESCE(NULLIF(nt.text1_0,''),NULLIF(nt.text1_1,''),''), COALESCE(NULLIF(nt.text2_0,''),NULLIF(nt.text2_1,''),'') "
        "FROM creature_template ct JOIN gossip_menu gm ON gm.MenuID = ct.gossip_menu_id JOIN npc_text nt ON nt.ID = gm.TextID WHERE ct.entry = {} ORDER BY nt.ID LIMIT 20", entry);
    if (gossip)
    {
        do
        {
            Field* fields = gossip->Fetch();
            uint32 textId = fields[0].Get<uint32>();
            for (uint8 index = 1; index <= 3; ++index)
                storyCount += Protocol::SendNPCStory(handler, "GOSSIP", textId, creature->GetName(), fields[index].Get<std::string>());
        } while (gossip->NextRow());
    }

    QueryResult options = WorldDatabase.Query("SELECT MenuID, OptionID, OptionText FROM gossip_menu_option WHERE MenuID IN (SELECT gossip_menu_id FROM creature_template WHERE entry = {}) ORDER BY MenuID, OptionID LIMIT 50", entry);
    if (options)
    {
        do
        {
            Field* fields = options->Fetch();
            uint32 sourceId = fields[0].Get<uint32>() * 100 + fields[1].Get<uint32>();
            storyCount += Protocol::SendNPCStory(handler, "GOSSIP_OPTION", sourceId, creature->GetName(), fields[2].Get<std::string>());
        } while (options->NextRow());
    }

    if (data && data->lootid)
    {
        QueryResult result = WorldDatabase.Query("SELECT Item, Chance, QuestRequired, MinCount, MaxCount FROM creature_loot_template WHERE Entry = {} AND Item > 0 ORDER BY GroupId, Chance DESC, Item LIMIT 100", data->lootid);
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 itemId = fields[0].Get<uint32>();
                ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
                if (!item) continue;
                Protocol::SendNPCLoot(handler, itemId, item->Name1, item->Quality, fields[1].Get<float>(), fields[3].Get<uint32>(), fields[4].Get<uint32>(), fields[2].Get<bool>());
            } while (result->NextRow());
        }
    }
    Protocol::SendNPCStoryEnd(handler, storyCount);
    Protocol::SendNPCEnd(handler, creature->GetName(), entry, questCount);
    return true;
}
}
