#include "CharacterInspector.h"

#include "AccountMgr.h"
#include "Bag.h"
#include "Chat.h"
#include "DBCStores.h"
#include "Item.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "WorldSession.h"

#include <array>
#include <algorithm>
#include <cctype>
#include <sstream>
#include <string>

namespace AzerCoreOps
{
namespace
{
bool IsGMAuthorized(ChatHandler* handler)
{
    return handler && handler->GetSession() && handler->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
}

Player* SelectedCharacter(ChatHandler* handler)
{
    Player* player = handler ? handler->getSelectedPlayer() : nullptr;
    if (!player && handler && handler->GetSession())
        player = handler->GetSession()->GetPlayer();
    return player;
}

struct ProfessionDefinition { uint32 id; char const* name; char const* category; };
constexpr std::array<ProfessionDefinition, 13> Professions = {{
    { 164, "Blacksmithing", "Primary" }, { 165, "Leatherworking", "Primary" },
    { 171, "Alchemy", "Primary" }, { 182, "Herbalism", "Primary" },
    { 186, "Mining", "Primary" }, { 197, "Tailoring", "Primary" },
    { 202, "Engineering", "Primary" }, { 333, "Enchanting", "Primary" },
    { 393, "Skinning", "Primary" }, { 755, "Jewelcrafting", "Primary" },
    { 129, "First Aid", "Secondary" }, { 185, "Cooking", "Secondary" },
    { 356, "Fishing", "Secondary" }
}};

struct RaidAchievement { char const* raidKey; char const* raid; char const* difficultyKey; char const* difficulty; uint32 id; char const* section; };
constexpr RaidAchievement RaidAchievements[] = {
    { "VOA", "Vault of Archavon", "10N", "10 Player", 1722, "Archavon the Stone Watcher" }, { "VOA", "Vault of Archavon", "10N", "10 Player", 3136, "Emalon the Storm Watcher" }, { "VOA", "Vault of Archavon", "10N", "10 Player", 3836, "Koralon the Flame Watcher" }, { "VOA", "Vault of Archavon", "10N", "10 Player", 4585, "Toravon the Ice Watcher" },
    { "VOA", "Vault of Archavon", "25N", "25 Player", 1721, "Archavon the Stone Watcher" }, { "VOA", "Vault of Archavon", "25N", "25 Player", 3137, "Emalon the Storm Watcher" }, { "VOA", "Vault of Archavon", "25N", "25 Player", 3837, "Koralon the Flame Watcher" }, { "VOA", "Vault of Archavon", "25N", "25 Player", 4586, "Toravon the Ice Watcher" },
    { "NAXX", "Naxxramas", "10N", "10 Player", 562, "Arachnid Quarter" }, { "NAXX", "Naxxramas", "10N", "10 Player", 564, "Construct Quarter" }, { "NAXX", "Naxxramas", "10N", "10 Player", 566, "Plague Quarter" }, { "NAXX", "Naxxramas", "10N", "10 Player", 568, "Military Quarter" }, { "NAXX", "Naxxramas", "10N", "10 Player", 572, "Sapphiron's Demise" }, { "NAXX", "Naxxramas", "10N", "10 Player", 574, "Kel'Thuzad's Defeat" },
    { "NAXX", "Naxxramas", "25N", "25 Player", 563, "Arachnid Quarter" }, { "NAXX", "Naxxramas", "25N", "25 Player", 565, "Construct Quarter" }, { "NAXX", "Naxxramas", "25N", "25 Player", 567, "Plague Quarter" }, { "NAXX", "Naxxramas", "25N", "25 Player", 569, "Military Quarter" }, { "NAXX", "Naxxramas", "25N", "25 Player", 573, "Sapphiron's Demise" }, { "NAXX", "Naxxramas", "25N", "25 Player", 575, "Kel'Thuzad's Defeat" },
    { "OS", "The Obsidian Sanctum", "10N", "10 Player", 1876, "Sartharion defeated" }, { "OS", "The Obsidian Sanctum", "25N", "25 Player", 625, "Sartharion defeated" }, { "OS", "The Obsidian Sanctum", "10HM", "10 Player Hard Mode", 2051, "The Twilight Zone" }, { "OS", "The Obsidian Sanctum", "25HM", "25 Player Hard Mode", 2054, "The Twilight Zone" },
    { "EOE", "The Eye of Eternity", "10N", "10 Player", 622, "The Spellweaver's Downfall" }, { "EOE", "The Eye of Eternity", "25N", "25 Player", 623, "The Spellweaver's Downfall" },
    { "ULDUAR", "Ulduar", "10N", "10 Player", 2886, "The Siege of Ulduar" }, { "ULDUAR", "Ulduar", "10N", "10 Player", 2888, "The Antechamber of Ulduar" }, { "ULDUAR", "Ulduar", "10N", "10 Player", 2890, "The Keepers of Ulduar" }, { "ULDUAR", "Ulduar", "10N", "10 Player", 2892, "The Descent into Madness" }, { "ULDUAR", "Ulduar", "10N", "10 Player", 2894, "The Secrets of Ulduar" },
    { "ULDUAR", "Ulduar", "25N", "25 Player", 2887, "The Siege of Ulduar" }, { "ULDUAR", "Ulduar", "25N", "25 Player", 2889, "The Antechamber of Ulduar" }, { "ULDUAR", "Ulduar", "25N", "25 Player", 2891, "The Keepers of Ulduar" }, { "ULDUAR", "Ulduar", "25N", "25 Player", 2893, "The Descent into Madness" }, { "ULDUAR", "Ulduar", "25N", "25 Player", 2895, "The Secrets of Ulduar" },
    { "ULDUAR", "Ulduar", "10HM", "10 Player Hard Mode", 2957, "Glory of the Ulduar Raider" }, { "ULDUAR", "Ulduar", "25HM", "25 Player Hard Mode", 2958, "Glory of the Ulduar Raider" },
    { "TOC", "Trial of the Crusader", "10N", "10 Player", 3917, "Call of the Crusade" }, { "TOC", "Trial of the Crusader", "25N", "25 Player", 3916, "Call of the Crusade" }, { "TOC", "Trial of the Crusader", "10H", "10 Player Heroic", 3918, "Call of the Grand Crusade" }, { "TOC", "Trial of the Crusader", "25H", "25 Player Heroic", 3812, "Call of the Grand Crusade" },
    { "ONYXIA", "Onyxia's Lair", "10N", "10 Player", 4396, "Onyxia defeated" }, { "ONYXIA", "Onyxia's Lair", "25N", "25 Player", 4397, "Onyxia defeated" },
    { "ICC", "Icecrown Citadel", "10N", "10 Player", 4531, "Lower Spire" }, { "ICC", "Icecrown Citadel", "10N", "10 Player", 4528, "Plagueworks" }, { "ICC", "Icecrown Citadel", "10N", "10 Player", 4529, "Crimson Hall" }, { "ICC", "Icecrown Citadel", "10N", "10 Player", 4527, "Frostwing Halls" }, { "ICC", "Icecrown Citadel", "10N", "10 Player", 4532, "Fall of the Lich King" },
    { "ICC", "Icecrown Citadel", "25N", "25 Player", 4604, "Lower Spire" }, { "ICC", "Icecrown Citadel", "25N", "25 Player", 4605, "Plagueworks" }, { "ICC", "Icecrown Citadel", "25N", "25 Player", 4606, "Crimson Hall" }, { "ICC", "Icecrown Citadel", "25N", "25 Player", 4607, "Frostwing Halls" }, { "ICC", "Icecrown Citadel", "25N", "25 Player", 4608, "Fall of the Lich King" },
    { "ICC", "Icecrown Citadel", "10H", "10 Player Heroic", 4628, "Lower Spire" }, { "ICC", "Icecrown Citadel", "10H", "10 Player Heroic", 4629, "Plagueworks" }, { "ICC", "Icecrown Citadel", "10H", "10 Player Heroic", 4630, "Crimson Hall" }, { "ICC", "Icecrown Citadel", "10H", "10 Player Heroic", 4631, "Frostwing Halls" }, { "ICC", "Icecrown Citadel", "10H", "10 Player Heroic", 4636, "Fall of the Lich King" },
    { "ICC", "Icecrown Citadel", "25H", "25 Player Heroic", 4632, "Lower Spire" }, { "ICC", "Icecrown Citadel", "25H", "25 Player Heroic", 4633, "Plagueworks" }, { "ICC", "Icecrown Citadel", "25H", "25 Player Heroic", 4634, "Crimson Hall" }, { "ICC", "Icecrown Citadel", "25H", "25 Player Heroic", 4635, "Frostwing Halls" }, { "ICC", "Icecrown Citadel", "25H", "25 Player Heroic", 4637, "Fall of the Lich King" },
    { "RS", "The Ruby Sanctum", "10N", "10 Player", 4817, "The Twilight Destroyer" }, { "RS", "The Ruby Sanctum", "25N", "25 Player", 4815, "The Twilight Destroyer" }, { "RS", "The Ruby Sanctum", "10H", "10 Player Heroic", 4818, "Heroic: The Twilight Destroyer" }, { "RS", "The Ruby Sanctum", "25H", "25 Player Heroic", 4816, "Heroic: The Twilight Destroyer" }
};

std::string Upper(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return char(std::toupper(c)); });
    return value;
}
}

bool CharacterInspector::Inspect(ChatHandler* handler)
{
    Player* requester = handler->GetSession()->GetPlayer();
    Player* player = SelectedCharacter(handler);
    if (!player)
        return true;

    bool gm = IsGMAuthorized(handler);
    bool sameGroup = requester && requester->GetGroup() && requester->GetGroup() == player->GetGroup();
    if (!gm && player != requester && !sameGroup)
    {
        Protocol::SendCharacterError(handler, "Player mode may inspect only yourself or a member of your current group");
        return true;
    }
    if (gm && handler->HasLowerSecurity(player))
    {
        Protocol::SendCharacterError(handler, "You cannot inspect a player with higher security");
        return true;
    }

    Protocol::SendCharacterBegin(handler, player->GetName(), gm ? "GM" : "PLAYER");
    Protocol::SendCharacterOverview(handler, player->GetName(), player->GetLevel(), player->getRace(), player->getClass(), player->GetTeamId(true) == TEAM_ALLIANCE ? "Alliance" : "Horde", player->GetGuildId(), gm ? std::to_string(player->GetGUID().GetCounter()) : "Restricted");
    Powers powerType = player->getPowerType();
    Protocol::SendCharacterState(handler, player->IsAlive(), player->IsInCombat(), player->GetHealth(), player->GetMaxHealth(), uint32(powerType), player->GetPower(powerType), player->GetMaxPower(powerType));
    if (gm)
        Protocol::SendCharacterLocation(handler, player->GetMapId(), player->GetZoneId(), player->GetAreaId(), player->GetInstanceId(), player->GetPhaseMask(), player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(), true);
    else
        Protocol::SendCharacterLocation(handler, 0, 0, 0, 0, 0, 0.0f, 0.0f, 0.0f, 0.0f, false);

    uint32 capacity = INVENTORY_SLOT_ITEM_END - INVENTORY_SLOT_ITEM_START;
    uint32 used = 0;
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot)) ++used;
    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
        if (Bag* bag = player->GetBagByPos(bagSlot))
        {
            capacity += bag->GetBagSize();
            for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
                if (bag->GetItemByPos(slot)) ++used;
        }
    uint32 equipped = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot)) ++equipped;
    Protocol::SendCharacterInventory(handler, used, capacity, equipped, uint32(player->GetAverageItemLevelForDF()));

    for (ProfessionDefinition const& profession : Professions)
        if (uint16 value = player->GetSkillValue(profession.id))
            Protocol::SendCharacterProfession(handler, profession.id, profession.name, profession.category, value, player->GetMaxSkillValue(profession.id));

    Protocol::SendCharacterEnd(handler, player->GetName());
    return true;
}

bool CharacterInspector::Raid(ChatHandler* handler, Acore::ChatCommands::Tail selection)
{
    Player* requester = handler->GetSession()->GetPlayer();
    Player* player = SelectedCharacter(handler);
    if (!player)
        return true;
    bool gm = IsGMAuthorized(handler);
    bool sameGroup = requester && requester->GetGroup() && requester->GetGroup() == player->GetGroup();
    if (!gm && player != requester && !sameGroup) { Protocol::SendCharacterError(handler, "Player mode may inspect only yourself or a member of your current group"); return true; }
    if (gm && handler->HasLowerSecurity(player)) { Protocol::SendCharacterError(handler, "You cannot inspect a player with higher security"); return true; }

    std::stringstream stream{std::string(selection)};
    std::string raidKey, difficultyKey;
    stream >> raidKey >> difficultyKey;
    raidKey = Upper(raidKey); difficultyKey = Upper(difficultyKey);
    uint32 count = 0;
    for (RaidAchievement const& achievement : RaidAchievements)
        if (raidKey == achievement.raidKey && difficultyKey == achievement.difficultyKey)
        {
            Protocol::SendCharacterRaid(handler, raidKey, difficultyKey, achievement.raid, achievement.difficulty, achievement.section, achievement.id, player->HasAchieved(achievement.id));
            ++count;
        }
    if (!count) { Protocol::SendCharacterError(handler, "Unsupported raid or difficulty selection"); return true; }
    Protocol::SendCharacterRaidEnd(handler, player->GetName(), raidKey, difficultyKey, count);
    return true;
}

bool CharacterInspector::SaveTarget(ChatHandler* handler)
{
    Player* player = SelectedCharacter(handler);
    if (!player)
        return true;
    if (!IsGMAuthorized(handler))
    {
        Protocol::SendCharacterSaveResult(handler, player->GetName(), "DENIED", "GM authorization is required");
        return true;
    }
    if (handler->HasLowerSecurity(player))
    {
        Protocol::SendCharacterSaveResult(handler, player->GetName(), "DENIED", "Target has higher security");
        return true;
    }
    player->SaveToDB(false, false);
    Protocol::SendCharacterSaveResult(handler, player->GetName(), "SUCCESS", "Character state persisted without logging the player out");
    return true;
}
}
