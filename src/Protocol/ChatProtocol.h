#ifndef AZERCORE_OPS_CHAT_PROTOCOL_H
#define AZERCORE_OPS_CHAT_PROTOCOL_H

#include "Build/AzerCoreOpsBuildInfo.h"

#include <cstdint>
#include <string>

class ChatHandler;

namespace AzerCoreOps::Protocol
{
void SendVersion(ChatHandler* handler, BuildInfo const& info);
void SendError(ChatHandler* handler, std::string const& reason);
void SendInstanceSearch(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t maxPlayers);
void SendInstanceSearchEnd(ChatHandler* handler, std::uint32_t count);
void SendInstanceBegin(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::uint32_t difficulty, std::uint32_t referenceId, std::uint32_t members);
void SendInstanceMember(ChatHandler* handler, std::string const& name, std::string const& result, std::uint32_t mapId, std::uint32_t currentInstanceId, std::uint32_t phaseMask, std::uint32_t bindId, bool permanent, bool extended, bool canReset, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason);
void SendInstanceEnd(ChatHandler* handler);
void SendBindBegin(ChatHandler* handler, std::string const& player, std::string const& scope, std::uint32_t count);
void SendBindEntry(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t instanceId, std::uint32_t difficulty, bool permanent, bool extended, bool canReset, bool applicable, std::uint32_t resetSeconds, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason);
void SendBindBoss(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::uint32_t index, bool defeated, std::string const& name);
void SendBindEnd(ChatHandler* handler, std::string const& player, std::uint32_t count);
void SendUnbindBegin(ChatHandler* handler, std::string const& operation, std::string const& player, std::uint32_t requested);
void SendUnbindResult(ChatHandler* handler, std::string const& operation, std::uint32_t mapId, std::uint32_t difficulty, std::uint32_t instanceId, std::string const& result, std::string const& reason);
void SendUnbindEnd(ChatHandler* handler, std::string const& operation, std::uint32_t succeeded, std::uint32_t failed);
void SendQuestError(ChatHandler* handler, std::string const& reason);
void SendQuestSearch(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::string const& eligibility, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& player);
void SendQuestSearchEnd(ChatHandler* handler, std::uint32_t count);
void SendQuestInfo(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::int32_t minLevel, std::int32_t level, std::string const& type, bool repeatable, std::string const& status, std::string const& eligibility, std::string const& reason, std::string const& items, std::string const& reputation, std::string const& player, std::string const& starters, std::string const& enders);
void SendQuestChain(ChatHandler* handler, std::string const& direction, std::uint32_t id, std::string const& title, std::string const& status, std::string const& eligibility, std::string const& faction, std::string const& required, std::uint32_t depth, std::string const& reason);
void SendQuestInfoEnd(ChatHandler* handler, std::uint32_t id, std::uint32_t chainCount);
void SendQuestAuditBegin(ChatHandler* handler, std::uint32_t id, std::string const& title, std::uint32_t members);
void SendQuestAuditMember(ChatHandler* handler, std::string const& name, std::string const& result, std::string const& status, std::string const& eligibility, std::string const& reason);
void SendQuestAuditEnd(ChatHandler* handler);
void SendQuestLogBegin(ChatHandler* handler, std::string const& player, std::uint32_t count);
void SendQuestLogEntry(ChatHandler* handler, std::uint32_t slot, std::uint32_t id, std::string const& title, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& faction);
void SendQuestLogEnd(ChatHandler* handler, std::string const& player, std::uint32_t count);
void SendCharacterError(ChatHandler* handler, std::string const& reason);
void SendCharacterBegin(ChatHandler* handler, std::string const& player, std::string const& mode);
void SendCharacterOverview(ChatHandler* handler, std::string const& player, std::uint32_t level, std::uint32_t race, std::uint32_t playerClass, std::string const& faction, std::uint32_t guildId, std::string const& guid);
void SendCharacterState(ChatHandler* handler, bool alive, bool combat, std::uint32_t health, std::uint32_t maxHealth, std::uint32_t powerType, std::uint32_t power, std::uint32_t maxPower);
void SendCharacterLocation(ChatHandler* handler, std::uint32_t map, std::uint32_t zone, std::uint32_t area, std::uint32_t instance, std::uint32_t phase, float x, float y, float z, float orientation, bool authorized);
void SendCharacterInventory(ChatHandler* handler, std::uint32_t used, std::uint32_t capacity, std::uint32_t equipped, std::uint32_t averageItemLevel);
void SendCharacterProfession(ChatHandler* handler, std::uint32_t id, std::string const& name, std::string const& category, std::uint32_t value, std::uint32_t maximum);
void SendCharacterRaid(ChatHandler* handler, std::string const& raidKey, std::string const& difficultyKey, std::string const& raid, std::string const& difficulty, std::string const& section, std::uint32_t achievement, bool complete);
void SendCharacterRaidEnd(ChatHandler* handler, std::string const& player, std::string const& raidKey, std::string const& difficultyKey, std::uint32_t count);
void SendCharacterEnd(ChatHandler* handler, std::string const& player);
void SendCharacterSaveResult(ChatHandler* handler, std::string const& player, std::string const& result, std::string const& reason);
}

#endif
