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
    if (!player)
        Protocol::SendCharacterError(handler, "Select an online player before inspecting Character data");
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

struct RaidAchievement { uint32 id; char const* section; char const* difficulty; };
constexpr std::array<RaidAchievement, 10> IccAchievements = {{
    { 4531, "Lower Spire", "10 Player" }, { 4528, "Plagueworks", "10 Player" },
    { 4529, "Crimson Hall", "10 Player" }, { 4527, "Frostwing Halls", "10 Player" },
    { 4530, "The Frozen Throne", "10 Player" }, { 4604, "Lower Spire", "25 Player" },
    { 4605, "Plagueworks", "25 Player" }, { 4606, "Crimson Hall", "25 Player" },
    { 4607, "Frostwing Halls", "25 Player" }, { 4608, "The Frozen Throne", "25 Player" }
}};
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

    for (RaidAchievement const& achievement : IccAchievements)
        Protocol::SendCharacterRaid(handler, "Icecrown Citadel", achievement.difficulty, achievement.section, achievement.id, player->HasAchieved(achievement.id));

    Protocol::SendCharacterEnd(handler, player->GetName());
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
