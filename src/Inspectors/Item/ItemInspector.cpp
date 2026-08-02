#include "ItemInspector.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "ObjectMgr.h"
#include "Protocol/ChatProtocol.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <string>
#include <unordered_set>
#include <vector>

namespace AzerCoreOps
{
namespace
{
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
            Protocol::SendItemSource(handler, "QUEST_REWARD", fields[0].Get<uint32>(), fields[1].Get<std::string>(), "Quest reward");
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
