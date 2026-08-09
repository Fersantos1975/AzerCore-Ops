#include "ItemInspector.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "QuestDef.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <cstdlib>
#include <sstream>
#include <string>
#include <unordered_set>
#include <vector>

namespace AzerCoreOps
{
namespace
{
constexpr uint32 PlayableRaceMask = 0x000006FF; // WotLK races 1-8, 10 and 11.
constexpr uint32 AllianceRaceMask = 0x0000044D; // Human, Dwarf, Night Elf, Gnome, Draenei.
constexpr uint32 HordeRaceMask = 0x000002B2;    // Orc, Undead, Tauren, Troll, Blood Elf.
constexpr uint32 PlayableClassMask = 0x000005FF; // WotLK classes 1-9 and 11.

struct NamedMask { uint32 mask; char const* name; };

std::string MaskNames(uint32 value, std::vector<NamedMask> const& names, uint32 playableMask, char const* allText)
{
    uint32 allowed = value & playableMask;
    if (!value || value == uint32(-1) || allowed == playableMask) return allText;
    std::string result;
    for (NamedMask const& entry : names)
    {
        if (!(allowed & entry.mask)) continue;
        if (!result.empty()) result += ", ";
        result += entry.name;
    }
    return result.empty() ? "None" : result;
}

std::string ItemFaction(ItemTemplate const* item, uint32 raceMask)
{
    bool allianceFlag = item->HasFlag2(ITEM_FLAG2_FACTION_ALLIANCE);
    bool hordeFlag = item->HasFlag2(ITEM_FLAG2_FACTION_HORDE);
    if (allianceFlag != hordeFlag) return allianceFlag ? "Alliance" : "Horde";
    uint32 allowed = raceMask & PlayableRaceMask;
    if (!raceMask || raceMask == uint32(-1) || allowed == PlayableRaceMask) return "Both";
    bool alliance = (allowed & AllianceRaceMask) != 0;
    bool horde = (allowed & HordeRaceMask) != 0;
    if (alliance && !horde) return "Alliance";
    if (horde && !alliance) return "Horde";
    return "Both";
}

uint32 EffectiveRaceMask(ItemTemplate const* item)
{
    uint32 allowed = item->AllowableRace & PlayableRaceMask;
    if (!item->AllowableRace || item->AllowableRace == uint32(-1)) allowed = PlayableRaceMask;
    bool allianceFlag = item->HasFlag2(ITEM_FLAG2_FACTION_ALLIANCE);
    bool hordeFlag = item->HasFlag2(ITEM_FLAG2_FACTION_HORDE);
    if (allianceFlag && !hordeFlag) allowed &= AllianceRaceMask;
    if (hordeFlag && !allianceFlag) allowed &= HordeRaceMask;
    return allowed;
}

char const* ReputationRankName(uint32 rank)
{
    static char const* const names[] = {"Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted"};
    return rank < 8 ? names[rank] : "Unknown";
}

std::string FactionName(uint32 factionId)
{
    if (FactionEntry const* faction = sFactionStore.LookupEntry(factionId))
        if (faction->name[0] && *faction->name[0]) return faction->Name[0];
    return "Faction " + std::to_string(factionId);
}

std::string SpellName(uint32 spellId)
{
    if (SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId))
        if (spell->SpellName[0] && *spell->SpellName[0]) return spell->SpellName[0];
    return "Spell " + std::to_string(spellId);
}

std::string ProfessionName(uint32 skill);

std::string SkillName(uint32 skillId)
{
    if (SkillLineEntry const* skill = sSkillLineStore.LookupEntry(skillId))
        if (skill->name[0] && *skill->name[0]) return skill->Name[0];
    return ProfessionName(skillId);
}

struct ItemPreviewInfo
{
    std::string type = "NONE";
    uint32 spell = 0;
    uint32 creature = 0;
    uint32 display = 0;
};

void ResolvePreviewSpell(uint32 spellId, ItemPreviewInfo& preview, uint8 depth = 0)
{
    if (!spellId || depth > 3 || preview.display || preview.creature) return;
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
    if (!spell) return;
    if (!preview.spell) preview.spell = spellId;
    for (SpellEffectInfo const& effect : spell->Effects)
    {
        // 36 learns the actual mount/pet spell; follow it before inspecting its effects.
        if (effect.Effect == 36 && effect.TriggerSpell > 0)
            ResolvePreviewSpell(uint32(effect.TriggerSpell), preview, depth + 1);
        // Aura 78 is Mounted; MiscValue is the CreatureDisplayInfo ID used by the client model.
        if (effect.ApplyAuraName == 78 && effect.MiscValue > 0)
        {
            preview.type = "MOUNT";
            preview.display = uint32(effect.MiscValue);
            preview.spell = spellId;
        }
        // Effects 28 and 56 summon a creature/pet; MiscValue is the creature template entry.
        if ((effect.Effect == 28 || effect.Effect == 56) && effect.MiscValue > 0 && !preview.display)
        {
            preview.type = "COMPANION";
            preview.creature = uint32(effect.MiscValue);
            preview.spell = spellId;
        }
    }
}

void EmitAccessAndPreview(ChatHandler* handler, ItemTemplate const* item)
{
    static std::vector<NamedMask> const races = {{1u << 0, "Human"}, {1u << 1, "Orc"}, {1u << 2, "Dwarf"}, {1u << 3, "Night Elf"}, {1u << 4, "Undead"}, {1u << 5, "Tauren"}, {1u << 6, "Gnome"}, {1u << 7, "Troll"}, {1u << 9, "Blood Elf"}, {1u << 10, "Draenei"}};
    static std::vector<NamedMask> const classes = {{1u << 0, "Warrior"}, {1u << 1, "Paladin"}, {1u << 2, "Hunter"}, {1u << 3, "Rogue"}, {1u << 4, "Priest"}, {1u << 5, "Death Knight"}, {1u << 6, "Shaman"}, {1u << 7, "Mage"}, {1u << 8, "Warlock"}, {1u << 10, "Druid"}};
    Player* player = handler->GetSession()->GetPlayer();
    uint32 raceMask = EffectiveRaceMask(item);
    uint32 classMask = item->AllowableClass;
    uint32 playerRaceMask = player ? (1u << (player->getRace() - 1)) : 0;
    uint32 playerClassMask = player ? (1u << (player->getClass() - 1)) : 0;
    bool raceAllowed = (raceMask & playerRaceMask) != 0;
    bool classAllowed = !classMask || classMask == uint32(-1) || (classMask & playerClassMask);
    bool levelAllowed = !player || player->GetLevel() >= item->RequiredLevel;
    bool skillAllowed = !item->RequiredSkill || (player && player->GetSkillValue(item->RequiredSkill) >= item->RequiredSkillRank);
    bool spellAllowed = !item->RequiredSpell || (player && player->HasSpell(item->RequiredSpell));
    uint32 currentReputation = item->RequiredReputationFaction && player ? uint32(player->GetReputationRank(item->RequiredReputationFaction)) : 0;
    bool reputationAllowed = !item->RequiredReputationFaction || currentReputation >= item->RequiredReputationRank;
    bool uniqueAllowed = item->MaxCount <= 0 || !player || !player->HasItemCount(item->ItemId, uint32(item->MaxCount), true);
    bool usable = raceAllowed && classAllowed && levelAllowed && skillAllowed && spellAllowed && reputationAllowed && uniqueAllowed;
    std::vector<std::string> failures;
    if (!raceAllowed) failures.emplace_back("Faction or race restriction");
    if (!classAllowed) failures.emplace_back("Class restriction");
    if (!levelAllowed) failures.emplace_back("Level requirement");
    if (!skillAllowed) failures.emplace_back("Skill requirement");
    if (!spellAllowed) failures.emplace_back("Required spell missing");
    if (!reputationAllowed) failures.emplace_back("Reputation requirement");
    if (!uniqueAllowed) failures.emplace_back("Unique item limit reached");
    std::ostringstream reason;
    for (std::string const& failure : failures) { if (reason.tellp() > 0) reason << "; "; reason << failure; }
    Protocol::SendItemAccess(handler, raceMask, classMask, ItemFaction(item, raceMask), MaskNames(raceMask, races, PlayableRaceMask, "All playable races"), MaskNames(classMask, classes, PlayableClassMask, "All playable classes"), usable, usable ? "All evaluated requirements passed" : reason.str());

    Protocol::SendItemRequirement(handler, "FACTION_RACE", 0, ItemFaction(item, raceMask), MaskNames(raceMask, races, PlayableRaceMask, "All playable races"), player ? MaskNames(playerRaceMask, races, PlayableRaceMask, "Unknown") : "No character", raceAllowed, raceAllowed ? "Faction and race allowed" : "Character faction or race is not permitted");
    Protocol::SendItemRequirement(handler, "CLASS", 0, "Classes", MaskNames(classMask, classes, PlayableClassMask, "All playable classes"), player ? MaskNames(playerClassMask, classes, PlayableClassMask, "Unknown") : "No character", classAllowed, classAllowed ? "Class allowed" : "Character class is not permitted");
    if (item->RequiredLevel)
        Protocol::SendItemRequirement(handler, "LEVEL", 0, "Character level", std::to_string(item->RequiredLevel), player ? std::to_string(player->GetLevel()) : "Unknown", levelAllowed, levelAllowed ? "Level requirement met" : "Character level is too low");
    if (item->RequiredSkill)
        Protocol::SendItemRequirement(handler, "SKILL", item->RequiredSkill, SkillName(item->RequiredSkill), std::to_string(item->RequiredSkillRank), player ? std::to_string(player->GetSkillValue(item->RequiredSkill)) : "Unknown", skillAllowed, skillAllowed ? "Skill requirement met" : "Required skill or rank is missing");
    if (item->RequiredSpell)
        Protocol::SendItemRequirement(handler, "SPELL", item->RequiredSpell, SpellName(item->RequiredSpell), "Known", player && player->HasSpell(item->RequiredSpell) ? "Known" : "Not known", spellAllowed, spellAllowed ? "Required spell known" : "Required spell is missing");
    if (item->RequiredReputationFaction)
        Protocol::SendItemRequirement(handler, "REPUTATION", item->RequiredReputationFaction, FactionName(item->RequiredReputationFaction), ReputationRankName(item->RequiredReputationRank), ReputationRankName(currentReputation), reputationAllowed, reputationAllowed ? "Reputation requirement met" : "Reputation rank is too low");
    if (item->MaxCount > 0)
        Protocol::SendItemRequirement(handler, "UNIQUE", item->ItemId, "Unique item limit", std::to_string(item->MaxCount), player ? std::to_string(player->GetItemCount(item->ItemId, true)) : "Unknown", uniqueAllowed, uniqueAllowed ? "Below unique item limit" : "Unique item limit reached");

    ItemPreviewInfo preview;
    for (_Spell const& itemSpell : item->Spells)
        if (itemSpell.SpellId > 0) ResolvePreviewSpell(uint32(itemSpell.SpellId), preview);
    Protocol::SendItemPreview(handler, preview.type, preview.spell, preview.creature, preview.display);
}

std::string ProfessionName(uint32 skill)
{
    switch (skill)
    {
        case 129: return "First Aid";
        case 164: return "Blacksmithing";
        case 165: return "Leatherworking";
        case 171: return "Alchemy";
        case 182: return "Herbalism";
        case 185: return "Cooking";
        case 186: return "Mining";
        case 197: return "Tailoring";
        case 202: return "Engineering";
        case 333: return "Enchanting";
        case 356: return "Fishing";
        case 393: return "Skinning";
        case 755: return "Jewelcrafting";
        case 773: return "Inscription";
        default: return skill ? "Skill " + std::to_string(skill) : "Unknown";
    }
}

struct CraftSkill
{
    uint32 line = 0;
    uint32 rank = 0;
};

CraftSkill FindCraftSkill(uint32 spellId)
{
    CraftSkill result;
    for (uint32 row = 0; row < sSkillLineAbilityStore.GetNumRows(); ++row)
    {
        SkillLineAbilityEntry const* ability = sSkillLineAbilityStore.LookupEntry(row);
        if (!ability || ability->Spell != spellId) continue;
        if (!result.line || ability->MinSkillLineRank > result.rank)
        {
            result.line = ability->SkillLine;
            result.rank = ability->MinSkillLineRank;
        }
    }
    return result;
}

void EmitRecipeItems(ChatHandler* handler, uint32 spellId)
{
    QueryResult recipes = WorldDatabase.Query(
        "SELECT entry, name, Quality FROM item_template WHERE spellid_1 = {0} OR spellid_2 = {0} OR spellid_3 = {0} OR spellid_4 = {0} OR spellid_5 = {0} ORDER BY entry LIMIT 25", spellId);
    if (!recipes) return;
    do
    {
        Field* fields = recipes->Fetch();
        uint32 recipeId = fields[0].Get<uint32>();
        std::string recipeName = fields[1].Get<std::string>();
        Protocol::SendItemRecipe(handler, recipeId, recipeName, fields[2].Get<uint32>(), spellId);
        QueryResult vendors = WorldDatabase.Query("SELECT DISTINCT ct.entry, ct.name FROM npc_vendor nv JOIN creature_template ct ON ct.entry = nv.entry WHERE nv.item = {} ORDER BY ct.name LIMIT 20", recipeId);
        if (vendors)
        {
            do
            {
                Field* vendor = vendors->Fetch();
                Protocol::SendItemSource(handler, "RECIPE_VENDOR", vendor[0].Get<uint32>(), vendor[1].Get<std::string>(), "Sells recipe " + recipeName + " [" + std::to_string(recipeId) + "]");
            } while (vendors->NextRow());
        }
    } while (recipes->NextRow());
}

void EmitTrainerSources(ChatHandler* handler, uint32 spellId, std::string const& spellName)
{
    QueryResult trainers = WorldDatabase.Query(
        "SELECT DISTINCT ct.entry, ct.name FROM trainer_spell ts JOIN creature_default_trainer cdt ON cdt.TrainerId = ts.TrainerId JOIN creature_template ct ON ct.entry = cdt.CreatureId WHERE ts.SpellId = {} ORDER BY ct.name LIMIT 30", spellId);
    if (!trainers) return;
    do
    {
        Field* fields = trainers->Fetch();
        Protocol::SendItemSource(handler, "TRAINER", fields[0].Get<uint32>(), fields[1].Get<std::string>(), "Teaches " + spellName + " [spell " + std::to_string(spellId) + "]");
    } while (trainers->NextRow());
}

void EmitSources(ChatHandler* handler, uint32 itemId)
{
    QueryResult vendors = WorldDatabase.Query(
        "SELECT DISTINCT ct.entry, ct.name FROM npc_vendor nv JOIN creature_template ct ON ct.entry = nv.entry WHERE nv.item = {} ORDER BY ct.name LIMIT 30", itemId);
    if (vendors)
    {
        do
        {
            Field* fields = vendors->Fetch();
            Protocol::SendItemSource(handler, "VENDOR", fields[0].Get<uint32>(), fields[1].Get<std::string>(), "Sold by NPC");
        } while (vendors->NextRow());
    }

    QueryResult drops = WorldDatabase.Query(
        "SELECT DISTINCT ct.entry, ct.name, clt.Chance FROM creature_loot_template clt JOIN creature_template ct ON ct.lootid = clt.Entry WHERE clt.Item = {} ORDER BY clt.Chance DESC LIMIT 40", itemId);
    if (drops)
    {
        do
        {
            Field* fields = drops->Fetch();
            Protocol::SendItemSource(handler, "CREATURE_DROP", fields[0].Get<uint32>(), fields[1].Get<std::string>(), std::to_string(fields[2].Get<float>()) + "% chance");
        } while (drops->NextRow());
    }

    QueryResult quests = WorldDatabase.Query(
        "SELECT ID, LogTitle FROM quest_template WHERE RewardItem1 = {0} OR RewardItem2 = {0} OR RewardItem3 = {0} OR RewardItem4 = {0} OR RewardChoiceItemID1 = {0} OR RewardChoiceItemID2 = {0} OR RewardChoiceItemID3 = {0} OR RewardChoiceItemID4 = {0} OR RewardChoiceItemID5 = {0} OR RewardChoiceItemID6 = {0} ORDER BY ID LIMIT 40", itemId);
    if (quests)
    {
        do
        {
            Field* fields = quests->Fetch();
            uint32 questId = fields[0].Get<uint32>();
            std::string questName = fields[1].Get<std::string>();
            Protocol::SendItemSource(handler, "QUEST_REWARD", questId, questName, "Quest reward");
            if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
            {
                Player* player = handler->GetSession()->GetPlayer();
                for (uint8 index = 0; index < QUEST_ITEM_OBJECTIVES_COUNT; ++index)
                {
                    uint32 requiredItem = quest->RequiredItemId[index];
                    uint32 requiredCount = quest->RequiredItemCount[index];
                    if (!requiredItem || !requiredCount) continue;
                    ItemTemplate const* required = sObjectMgr->GetItemTemplate(requiredItem);
                    uint32 currentCount = player ? player->GetItemCount(requiredItem, true) : 0;
                    Protocol::SendItemRequirement(handler, "ACQUISITION_ITEM", requiredItem, required ? required->Name1 : "Required item", std::to_string(requiredCount), player ? std::to_string(currentCount) : "Unknown", currentCount >= requiredCount, "Required by quest " + questName + " [" + std::to_string(questId) + "]");
                }
                if (uint32 previousQuest = uint32(std::abs(quest->GetPrevQuestId())))
                {
                    Quest const* previous = sObjectMgr->GetQuestTemplate(previousQuest);
                    bool complete = player && player->GetQuestRewardStatus(previousQuest);
                    Protocol::SendItemRequirement(handler, "ACQUISITION_QUEST", previousQuest, previous ? previous->GetTitle() : "Previous quest", "Completed", complete ? "Completed" : "Not completed", complete, "Prerequisite for quest " + questName + " [" + std::to_string(questId) + "]");
                }
            }
        } while (quests->NextRow());
    }
}
}

bool ItemInspector::Inspect(ChatHandler* handler, uint32 itemId)
{
    if (!handler || !handler->GetSession()) return false;
    ItemTemplate const* selected = sObjectMgr->GetItemTemplate(itemId);
    if (!itemId || !selected)
    {
        Protocol::SendItemError(handler, "Enter a valid item ID before using Inspect Item");
        return true;
    }

    Protocol::SendItemBegin(handler, itemId, selected->Name1, selected->Quality, selected->ItemLevel, selected->RequiredLevel);
    EmitAccessAndPreview(handler, selected);
    uint32 craftCount = 0;
    std::unordered_set<uint32> emittedSpells;
    for (uint32 spellId = 0; spellId < sSpellStore.GetNumRows(); ++spellId)
    {
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
        if (!spell) continue;
        bool createsSelected = false;
        uint32 produced = 1;
        uint32 createdItemId = 0;
        uint32 createdCount = 1;
        for (SpellEffectInfo const& effect : spell->Effects)
        {
            if (effect.Effect == 24 || effect.Effect == 157)
            {
                if (!createdItemId) { createdItemId = uint32(effect.ItemType); createdCount = uint32(std::max<int32>(1, effect.CalcValue())); }
                if (uint32(effect.ItemType) == itemId) { createsSelected = true; produced = uint32(std::max<int32>(1, effect.CalcValue())); }
            }
        }
        bool consumesSelected = false;
        for (uint8 index = 0; index < MAX_SPELL_REAGENTS; ++index) if (spell->Reagent[index] == int32(itemId) && spell->ReagentCount[index] > 0) { consumesSelected = true; break; }
        if (consumesSelected && createdItemId)
        {
            CraftSkill useSkill = FindCraftSkill(spellId); ItemTemplate const* result = sObjectMgr->GetItemTemplate(createdItemId);
            Protocol::SendItemUse(handler, spellId, spell->SpellName[0], ProfessionName(useSkill.line), useSkill.rank, createdItemId, result ? result->Name1 : "Unknown result", createdCount);
        }
        if (!createsSelected) continue;

        CraftSkill craft = FindCraftSkill(spellId);
        std::string spellName = spell->SpellName[0];
        Protocol::SendItemCraft(handler, spellId, spellName, craft.line, ProfessionName(craft.line), craft.rank, produced, "DIRECT", "UNKNOWN");
        emittedSpells.insert(spellId);
        for (uint8 index = 0; index < MAX_SPELL_REAGENTS; ++index)
        {
            int32 reagentId = spell->Reagent[index];
            if (reagentId <= 0 || spell->ReagentCount[index] <= 0) continue;
            ItemTemplate const* reagent = sObjectMgr->GetItemTemplate(uint32(reagentId));
            Protocol::SendItemReagent(handler, spellId, uint32(reagentId), reagent ? reagent->Name1 : "Unknown reagent", reagent ? reagent->Quality : 1, spell->ReagentCount[index]);
        }
        EmitRecipeItems(handler, spellId);
        EmitTrainerSources(handler, spellId, spellName);
        ++craftCount;
        if (craftCount >= 50) break;
    }

    QueryResult perfectResults = WorldDatabase.Query("SELECT spellId, perfectCreateChance FROM skill_perfect_item_template WHERE perfectItemType = {} ORDER BY spellId", itemId);
    if (perfectResults)
    {
        do
        {
            Field* fields = perfectResults->Fetch();
            uint32 spellId = fields[0].Get<uint32>();
            if (emittedSpells.find(spellId) != emittedSpells.end()) continue;
            SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
            if (!spell) continue;
            CraftSkill craft = FindCraftSkill(spellId);
            Protocol::SendItemCraft(handler, spellId, spell->SpellName[0], craft.line, ProfessionName(craft.line), craft.rank, 1, "PERFECT_PROC", std::to_string(fields[1].Get<float>()) + "%");
            for (uint8 index = 0; index < MAX_SPELL_REAGENTS; ++index)
            {
                int32 reagentId = spell->Reagent[index];
                if (reagentId <= 0 || spell->ReagentCount[index] <= 0) continue;
                ItemTemplate const* reagent = sObjectMgr->GetItemTemplate(uint32(reagentId));
                Protocol::SendItemReagent(handler, spellId, uint32(reagentId), reagent ? reagent->Name1 : "Unknown reagent", reagent ? reagent->Quality : 1, spell->ReagentCount[index]);
            }
            EmitRecipeItems(handler, spellId);
            EmitTrainerSources(handler, spellId, spell->SpellName[0]);
            emittedSpells.insert(spellId); ++craftCount;
        } while (perfectResults->NextRow() && craftCount < 50);
    }
    EmitSources(handler, itemId);
    Protocol::SendItemEnd(handler, itemId, craftCount);
    return true;
}
}
