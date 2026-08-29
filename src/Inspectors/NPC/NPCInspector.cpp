#include "NPCInspector.h"

#include "Chat.h"
#include "Creature.h"
#include "CreatureData.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "QuestDef.h"
#include "Util.h"

#include <cmath>
#include <cstdlib>
#include <limits>
#include <string>
#include <unordered_map>
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

bool NPCInspector::Search(ChatHandler* handler, Acore::ChatCommands::Tail search)
{
    if (!handler || !handler->GetSession() || search.empty())
        return false;

    std::string query(search.data(), search.size());
    Protocol::SendNPCSearchBegin(handler, query);

    char* parseEnd = nullptr;
    unsigned long parsed = std::strtoul(query.c_str(), &parseEnd, 10);
    bool exactEntry =
        parseEnd &&
        *parseEnd == '\0' &&
        parsed > 0 &&
        parsed <= std::numeric_limits<uint32>::max();

    std::wstring needle;
    if (!exactEntry)
    {
        if (!Utf8toWStr(query, needle))
        {
            Protocol::SendNPCSearchEnd(handler, 0);
            return true;
        }
        wstrToLower(needle);
    }

    uint32 count = 0;
    constexpr uint32 MaxResults = 12;

    auto emit = [&](CreatureTemplate const& creatureTemplate)
    {
        if (count >= MaxResults)
            return;

        uint32 entry = creatureTemplate.Entry;
        std::string displayName = creatureTemplate.Name;
        bool matched = exactEntry;

        uint8 localeIndex = handler->GetSessionDbLocaleIndex();
        if (CreatureLocale const* locale = sObjectMgr->GetCreatureLocale(entry))
        {
            if (locale->Name.size() > localeIndex && !locale->Name[localeIndex].empty())
            {
                std::string const& localized = locale->Name[localeIndex];

                if (!exactEntry && Utf8FitTo(localized, needle))
                    matched = true;

                displayName = localized;
            }
        }

        if (!exactEntry && !matched && !creatureTemplate.Name.empty())
            matched = Utf8FitTo(creatureTemplate.Name, needle);

        if (!matched)
            return;

        uint32 spawnCount = 0;
        QueryResult spawnResult =
            WorldDatabase.Query("SELECT COUNT(*) FROM creature WHERE id = {}", entry);

        if (spawnResult)
            spawnCount = static_cast<uint32>(spawnResult->Fetch()[0].Get<uint64>());

        Protocol::SendNPCSearchResult(
            handler,
            entry,
            displayName,
            creatureTemplate.minlevel,
            creatureTemplate.maxlevel,
            creatureTemplate.rank,
            creatureTemplate.type,
            spawnCount);

        ++count;
    };

    if (exactEntry)
    {
        if (CreatureTemplate const* creatureTemplate =
                sObjectMgr->GetCreatureTemplate(static_cast<uint32>(parsed)))
        {
            emit(*creatureTemplate);
        }
    }
    else
    {
        for (auto const& [entry, creatureTemplate] : *sObjectMgr->GetCreatureTemplates())
        {
            (void)entry;
            emit(creatureTemplate);

            if (count >= MaxResults)
                break;
        }
    }

    Protocol::SendNPCSearchEnd(handler, count);
    return true;
}

bool NPCInspector::Spawns(ChatHandler* handler, uint32 entry)
{
    if (!handler || !handler->GetSession())
        return false;

    Player* player = handler->GetSession()->GetPlayer();
    if (!player)
        return false;

    CreatureTemplate const* creatureTemplate = sObjectMgr->GetCreatureTemplate(entry);
    if (!creatureTemplate)
    {
        Protocol::SendNPCError(handler, "Creature entry was not found");
        return true;
    }

    uint32 total = 0;
    QueryResult totalResult =
        WorldDatabase.Query("SELECT COUNT(*) FROM creature WHERE id = {}", entry);

    if (totalResult)
        total = static_cast<uint32>(totalResult->Fetch()[0].Get<uint64>());

    Protocol::SendNPCSpawnsBegin(
        handler,
        entry,
        creatureTemplate->Name,
        total);

    uint32 playerMap = player->GetMapId();

    QueryResult result = WorldDatabase.Query(
        "SELECT guid, map, position_x, position_y, position_z, orientation, spawnMask, phaseMask "
        "FROM creature "
        "WHERE id = {} "
        "ORDER BY (map = {}) DESC, "
        "CASE WHEN map = {} THEN "
        "((position_x - {}) * (position_x - {})) + "
        "((position_y - {}) * (position_y - {})) + "
        "((position_z - {}) * (position_z - {})) "
        "ELSE 999999999999.0 END ASC, guid ASC "
        "LIMIT 50",
        entry,
        playerMap,
        playerMap,
        player->GetPositionX(), player->GetPositionX(),
        player->GetPositionY(), player->GetPositionY(),
        player->GetPositionZ(), player->GetPositionZ());

    uint32 count = 0;

    if (result)
    {
        do
        {
            Field* fields = result->Fetch();

            uint32 guid = fields[0].Get<uint32>();
            uint32 map = fields[1].Get<uint16>();
            float x = fields[2].Get<float>();
            float y = fields[3].Get<float>();
            float z = fields[4].Get<float>();
            float orientation = fields[5].Get<float>();
            uint32 spawnMask = fields[6].Get<uint8>();
            uint32 phaseMask = fields[7].Get<uint32>();

            bool sameMap = map == playerMap;
            float distance = -1.0f;

            if (sameMap)
            {
                float dx = x - player->GetPositionX();
                float dy = y - player->GetPositionY();
                float dz = z - player->GetPositionZ();
                distance = std::sqrt(dx * dx + dy * dy + dz * dz);
            }

            // Runtime spawn state must be observational only:
            // never create a map and never force-load a grid.
            Map* statusMap = sameMap
                ? player->GetMap()
                : sMapMgr->FindMap(map, 0);

            std::string spawnStatus = "MAP_NOT_ACTIVE";
            bool gridLoaded = false;
            uint32 respawnSeconds = 0;

            if (statusMap)
            {
                gridLoaded = statusMap->IsGridLoaded(x, y);

                bool loadedCreature = false;
                bool aliveCreature = false;
                bool deadCreature = false;

                auto const bounds =
                    statusMap->GetCreatureBySpawnIdStore().equal_range(guid);

                for (auto itr = bounds.first; itr != bounds.second; ++itr)
                {
                    Creature* creature = itr->second;
                    if (!creature)
                        continue;

                    loadedCreature = true;

                    if (creature->IsAlive())
                        aliveCreature = true;
                    else
                        deadCreature = true;
                }

                time_t const now = GameTime::GetGameTime().count();
                time_t const respawnTime =
                    statusMap->GetCreatureRespawnTime(guid);

                if (respawnTime > now)
                {
                    uint64 const remaining =
                        static_cast<uint64>(respawnTime - now);

                    respawnSeconds =
                        remaining > std::numeric_limits<uint32>::max()
                            ? std::numeric_limits<uint32>::max()
                            : static_cast<uint32>(remaining);
                }

                if (aliveCreature)
                {
                    spawnStatus = "ALIVE";
                }
                else if (deadCreature || loadedCreature)
                {
                    spawnStatus = "DEAD";
                }
                else if (respawnSeconds > 0)
                {
                    spawnStatus = "RESPAWNING";
                }
                else if (!gridLoaded)
                {
                    spawnStatus = "NOT_LOADED";
                }
                else
                {
                    // Grid is active but this DB spawn has no currently
                    // loaded Creature and no future respawn timer.
                    // Keep this neutral: pools/events/conditions may apply.
                    spawnStatus = "NOT_PRESENT";
                }
            }

            Protocol::SendNPCSpawn(
                handler,
                entry,
                guid,
                map,
                x,
                y,
                z,
                orientation,
                spawnMask,
                phaseMask,
                sameMap,
                distance,
                spawnStatus,
                gridLoaded,
                respawnSeconds);

            ++count;
        }
        while (result->NextRow());
    }

    Protocol::SendNPCSpawnsEnd(handler, entry, count);
    return true;
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
    Protocol::SendNPCOverview(handler, creature->GetLevel(), data ? data->minlevel : creature->GetLevel(), data ? data->maxlevel : creature->GetLevel(), data ? data->rank : 0, data ? data->type : 0, data ? data->family : 0, data ? data->faction : 0, data ? data->npcflag : 0);
    Protocol::SendNPCState(handler, creature->IsAlive(), creature->IsInCombat(), creature->GetHealth(), creature->GetMaxHealth(), creature->getPowerType(), creature->GetPower(creature->getPowerType()), creature->GetMaxPower(creature->getPowerType()));
    Protocol::SendNPCLocation(handler, creature->GetMapId(), creature->GetZoneId(), creature->GetAreaId(), creature->GetInstanceId(), creature->GetPhaseMask(), creature->GetPositionX(), creature->GetPositionY(), creature->GetPositionZ(), creature->GetOrientation());

    ObjectGuid::LowType const spawnId = creature->GetSpawnId();
    CreatureData const* spawnData = spawnId ? sObjectMgr->GetCreatureData(spawnId) : nullptr;
    Position const& home = creature->GetHomePosition();

    Protocol::SendNPCSpawnInfo(
        handler,
        static_cast<std::uint64_t>(spawnId),
        spawnData != nullptr,
        home.GetPositionX(),
        home.GetPositionY(),
        home.GetPositionZ(),
        home.GetOrientation(),
        creature->GetRespawnDelay(),
        creature->GetCorpseDelay(),
        static_cast<std::uint32_t>(creature->GetDefaultMovementType()),
        spawnData ? spawnData->wander_distance : 0.0f);
    if (data)
        Protocol::SendNPCTechnical(handler, data->unit_flags, data->dynamicflags, data->lootid, data->pickpocketLootId, data->SkinLootId, data->mingold, data->maxgold, data->AIName, data->ScriptID);

    uint32 questCount = 0;
    uint32 storyCount = 0;

    struct StoryQuestRelation
    {
        Quest const* quest = nullptr;
        bool startsHere = false;
        bool endsHere = false;
    };

    std::vector<StoryQuestRelation> storyQuests;
    std::unordered_map<uint32, std::size_t> storyQuestIndex;

    auto emitRelations = [&](QuestRelations* relations, char const* relation, bool startsHere)
    {
        for (auto const& pair : *relations)
        {
            if (pair.first != entry) continue;

            Quest const* quest = sObjectMgr->GetQuestTemplate(pair.second);
            if (!quest) continue;

            std::string reason;
            std::string eligibility = QuestEligibility(player, quest, reason);

            Protocol::SendNPCQuest(
                handler,
                relation,
                quest->GetQuestId(),
                quest->GetTitle(),
                QuestStatus(player, quest),
                eligibility,
                reason,
                quest->GetMinLevel(),
                quest->GetQuestLevel(),
                QuestType(quest),
                quest->IsRepeatable());

            uint32 questId = quest->GetQuestId();
            auto indexIt = storyQuestIndex.find(questId);

            if (indexIt == storyQuestIndex.end())
            {
                std::size_t index = storyQuests.size();
                storyQuestIndex.emplace(questId, index);
                storyQuests.push_back({quest, startsHere, !startsHere});
            }
            else
            {
                StoryQuestRelation& story = storyQuests[indexIt->second];
                if (startsHere)
                    story.startsHere = true;
                else
                    story.endsHere = true;
            }

            ++questCount;
        }
    };

    emitRelations(sObjectMgr->GetCreatureQuestRelationMap(), "START", true);
    emitRelations(sObjectMgr->GetCreatureQuestInvolvedRelationMap(), "END", false);

    for (StoryQuestRelation const& story : storyQuests)
    {
        Quest const* quest = story.quest;
        if (!quest) continue;

        if (story.startsHere)
        {
            storyCount += Protocol::SendNPCStory(
                handler, "QUEST_DETAILS", quest->GetQuestId(),
                quest->GetTitle(), quest->GetDetails());

            storyCount += Protocol::SendNPCStory(
                handler, "QUEST_OBJECTIVES", quest->GetQuestId(),
                quest->GetTitle(), quest->GetObjectives());
        }

        if (story.endsHere)
        {
            storyCount += Protocol::SendNPCStory(
                handler, "QUEST_REQUEST", quest->GetQuestId(),
                quest->GetTitle(), quest->GetRequestItemsText());

            storyCount += Protocol::SendNPCStory(
                handler, "QUEST_REWARD", quest->GetQuestId(),
                quest->GetTitle(), quest->GetOfferRewardText());

            storyCount += Protocol::SendNPCStory(
                handler, "QUEST_COMPLETED", quest->GetQuestId(),
                quest->GetTitle(), quest->GetCompletedText());
        }
    }

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

    if (data)
    {
        auto emitLootTable =
            [&](char const* tableName, char const* source, uint32 lootId)
        {
            if (!lootId)
                return;

            QueryResult result = WorldDatabase.Query(
                "SELECT Item, Reference, Chance, QuestRequired, LootMode, GroupId, "
                "MinCount, MaxCount, COALESCE(Comment, '') "
                "FROM {} "
                "WHERE Entry = {} "
                "ORDER BY GroupId, Chance DESC, Item, Reference "
                "LIMIT 100",
                tableName,
                lootId);

            if (!result)
                return;

            do
            {
                Field* fields = result->Fetch();

                uint32 itemId = fields[0].Get<uint32>();
                int32 referenceValue = fields[1].Get<int32>();
                float chance = fields[2].Get<float>();
                bool questRequired = fields[3].Get<bool>();
                uint32 lootMode = fields[4].Get<uint16>();
                uint32 groupId = fields[5].Get<uint8>();
                uint32 minCount = fields[6].Get<uint8>();
                uint32 maxCount = fields[7].Get<uint8>();
                std::string comment = fields[8].Get<std::string>();

                if (referenceValue != 0)
                {
                    uint32 referenceId =
                        static_cast<uint32>(
                            referenceValue < 0
                                ? -static_cast<int64>(referenceValue)
                                : referenceValue);

                    uint32 rowCount = 0;
                    uint32 directRows = 0;
                    uint32 nestedRows = 0;

                    QueryResult referenceSummary = WorldDatabase.Query(
                        "SELECT "
                        "COUNT(*), "
                        "COALESCE(SUM(CASE WHEN Reference = 0 AND Item > 0 THEN 1 ELSE 0 END), 0), "
                        "COALESCE(SUM(CASE WHEN Reference <> 0 THEN 1 ELSE 0 END), 0) "
                        "FROM reference_loot_template "
                        "WHERE Entry = {}",
                        referenceId);

                    if (referenceSummary)
                    {
                        Field* summary = referenceSummary->Fetch();
                        rowCount = static_cast<uint32>(summary[0].Get<uint64>());
                        directRows = static_cast<uint32>(summary[1].Get<uint64>());
                        nestedRows = static_cast<uint32>(summary[2].Get<uint64>());
                    }

                    Protocol::SendNPCLootReference(
                        handler,
                        source,
                        lootId,
                        referenceId,
                        chance,
                        minCount,
                        maxCount,
                        lootMode,
                        groupId,
                        rowCount,
                        directRows,
                        nestedRows,
                        comment);

                    continue;
                }

                if (!itemId)
                    continue;

                ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
                if (!item)
                    continue;

                Protocol::SendNPCLoot(
                    handler,
                    itemId,
                    item->Name1,
                    item->Quality,
                    chance,
                    minCount,
                    maxCount,
                    questRequired,
                    source,
                    lootId,
                    lootMode,
                    groupId);
            }
            while (result->NextRow());
        };

        emitLootTable(
            "creature_loot_template",
            "CREATURE",
            data->lootid);

        emitLootTable(
            "pickpocketing_loot_template",
            "PICKPOCKET",
            data->pickpocketLootId);

        emitLootTable(
            "skinning_loot_template",
            "SKINNING",
            data->SkinLootId);
    }
    Protocol::SendNPCStoryEnd(handler, storyCount);
    Protocol::SendNPCEnd(handler, creature->GetName(), entry, questCount);
    return true;
}
}
