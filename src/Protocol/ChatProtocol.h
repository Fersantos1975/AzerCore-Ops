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
void SendEncounterDiagnosticBegin(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::string const& mapName, std::string const& scriptName);
void SendEncounterDiagnosticFinding(ChatHandler* handler, std::string const& severity, std::string const& category, std::string const& subject, std::string const& expected, std::string const& actual, std::string const& detail, std::string const& recommendation);
void SendEncounterDiagnosticRecovery(ChatHandler* handler, std::string const& id, std::string const& title, std::string const& confidence, std::string const& evidence, std::string const& verificationCommand, std::string const& actionCommands, std::string const& recheckCommand, std::string const& expectedResult, std::string const& safety);
void SendEncounterDiagnosticEnd(ChatHandler* handler, std::uint32_t passed, std::uint32_t warnings, std::uint32_t failures);
void SendEncounterDiagnosticError(ChatHandler* handler, std::string const& reason);
void SendEncounterHistoryBegin(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::string const& mapName, std::uint32_t count);
void SendEncounterHistoryEntry(ChatHandler* handler, std::uint64_t sequence, std::uint64_t timestampMs, std::uint32_t encounterId, std::string const& name, std::uint32_t oldState, std::string const& oldName, std::uint32_t newState, std::string const& newName, std::string const& classification, std::string const& event, std::uint32_t attempt, std::uint32_t wipes, std::uint32_t kills, std::string const& detail);
void SendEncounterHistoryStats(ChatHandler* handler, std::uint32_t encounterId, std::string const& name, std::uint32_t attempts, std::uint32_t wipes, std::uint32_t kills);
void SendEncounterHistoryEnd(ChatHandler* handler, std::uint32_t count, std::uint32_t anomalies);
void SendEncounterHistoryError(ChatHandler* handler, std::string const& reason);
void SendBindBegin(ChatHandler* handler, std::string const& player, std::string const& scope, std::uint32_t count);
void SendBindEntry(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t instanceId, std::uint32_t difficulty, bool permanent, bool extended, bool canReset, bool applicable, std::uint32_t resetSeconds, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason);
void SendBindBoss(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::uint32_t index, bool defeated, std::string const& name);
void SendBindEnd(ChatHandler* handler, std::string const& player, std::uint32_t count);
void SendUnbindBegin(ChatHandler* handler, std::string const& operation, std::string const& player, std::uint32_t requested);
void SendUnbindResult(ChatHandler* handler, std::string const& operation, std::uint32_t mapId, std::uint32_t difficulty, std::uint32_t instanceId, std::string const& result, std::string const& reason);
void SendUnbindEnd(ChatHandler* handler, std::string const& operation, std::uint32_t succeeded, std::uint32_t failed);
void SendQuestError(ChatHandler* handler, std::string const& reason);
void SendQuestSearch(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::string const& eligibility, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& player, std::string const& matchKind, std::uint32_t matchId, std::string const& matchName, std::uint32_t matchCount);
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
void SendNPCError(ChatHandler* handler, std::string const& reason);
void SendNPCSearchBegin(ChatHandler* handler, std::string const& query);
void SendNPCSearchResult(ChatHandler* handler, std::uint32_t entry, std::string const& name, std::uint32_t minLevel, std::uint32_t maxLevel, std::uint32_t rank, std::uint32_t type, std::uint32_t spawns);
void SendNPCSearchEnd(ChatHandler* handler, std::uint32_t count);
void SendNPCSpawnsBegin(ChatHandler* handler, std::uint32_t entry, std::string const& name, std::uint32_t total);
void SendNPCSpawn(ChatHandler* handler, std::uint32_t entry, std::uint32_t guid, std::uint32_t map, float x, float y, float z, float orientation, std::uint32_t spawnMask, std::uint32_t phaseMask, bool sameMap, float distance, std::string const& status, bool gridLoaded, std::uint32_t respawnSeconds);
void SendNPCSpawnsEnd(ChatHandler* handler, std::uint32_t entry, std::uint32_t count);
void SendNPCBegin(ChatHandler* handler, std::string const& name, std::uint32_t entry, std::string const& guid, std::string const& player);
void SendNPCOverview(ChatHandler* handler, std::uint32_t level, std::uint32_t minLevel, std::uint32_t maxLevel, std::uint32_t rank, std::uint32_t type, std::uint32_t family, std::uint32_t faction, std::uint32_t npcFlags);
void SendNPCState(ChatHandler* handler, bool alive, bool combat, std::uint32_t health, std::uint32_t maxHealth, std::uint32_t powerType, std::uint32_t power, std::uint32_t maxPower);
void SendNPCLocation(ChatHandler* handler, std::uint32_t map, std::uint32_t zone, std::uint32_t area, std::uint32_t instance, std::uint32_t phase, float x, float y, float z, float orientation);
void SendNPCSpawnInfo(ChatHandler* handler, std::uint64_t spawnId, bool databaseBacked, float homeX, float homeY, float homeZ, float homeOrientation, std::uint32_t respawnDelay, std::uint32_t corpseDelay, std::uint32_t movementType, float wanderDistance);
void SendNPCTechnical(ChatHandler* handler, std::uint32_t unitFlags, std::uint32_t dynamicFlags, std::uint32_t loot, std::uint32_t pickpocket, std::uint32_t skin, std::uint32_t minGold, std::uint32_t maxGold, std::string const& ai, std::uint32_t script);
void SendNPCQuest(ChatHandler* handler, std::string const& relation, std::uint32_t id, std::string const& title, std::string const& status, std::string const& eligibility, std::string const& reason, std::int32_t minLevel, std::int32_t level, std::string const& type, bool repeatable);
void SendNPCLoot(ChatHandler* handler, std::uint32_t id, std::string const& name, std::uint32_t quality, float chance, std::uint32_t minimum, std::uint32_t maximum, bool questRequired, std::string const& source, std::uint32_t tableId, std::uint32_t lootMode, std::uint32_t groupId);
void SendNPCLootReference(ChatHandler* handler, std::string const& source, std::uint32_t tableId, std::uint32_t referenceId, float chance, std::uint32_t minimum, std::uint32_t maximum, std::uint32_t lootMode, std::uint32_t groupId, std::uint32_t rows, std::uint32_t directRows, std::uint32_t nestedRows, std::string const& comment);
std::uint32_t SendNPCStory(ChatHandler* handler, std::string const& category, std::uint32_t sourceId, std::string const& title, std::string const& text);
void SendNPCStoryEnd(ChatHandler* handler, std::uint32_t count);
void SendNPCEnd(ChatHandler* handler, std::string const& name, std::uint32_t entry, std::uint32_t quests);
void SendItemError(ChatHandler* handler, std::string const& reason);
void SendItemBegin(ChatHandler* handler, std::uint32_t id, std::string const& name, std::uint32_t quality, std::uint32_t itemLevel, std::uint32_t requiredLevel);
void SendItemAccess(ChatHandler* handler, std::uint32_t raceMask, std::uint32_t classMask, std::string const& faction, std::string const& races, std::string const& classes, bool usable, std::string const& reason);
void SendItemPreview(ChatHandler* handler, std::string const& type, std::uint32_t spell, std::uint32_t creature, std::uint32_t display);
void SendItemRequirement(ChatHandler* handler, std::string const& kind, std::uint32_t id, std::string const& name, std::string const& required, std::string const& current, bool passed, std::string const& detail);
void SendItemCraft(ChatHandler* handler, std::uint32_t spell, std::string const& spellName, std::uint32_t skill, std::string const& profession, std::uint32_t rank, std::uint32_t produced, std::string const& resultType, std::string const& chance);
void SendItemReagent(ChatHandler* handler, std::uint32_t spell, std::uint32_t id, std::string const& name, std::uint32_t quality, std::uint32_t count);
void SendItemRecipe(ChatHandler* handler, std::uint32_t id, std::string const& name, std::uint32_t quality, std::uint32_t spell);
void SendItemSource(ChatHandler* handler, std::string const& type, std::uint32_t id, std::string const& name, std::string const& detail);
void SendItemUse(ChatHandler* handler, std::uint32_t spell, std::string const& spellName, std::string const& profession, std::uint32_t rank, std::uint32_t resultId, std::string const& resultName, std::uint32_t count);
void SendItemEnd(ChatHandler* handler, std::uint32_t id, std::uint32_t crafts);
void SendMovementCatalogBegin(ChatHandler* handler);
void SendMovementDestination(ChatHandler* handler, std::uint32_t id, std::string const& name, std::string const& category, std::uint32_t map, float x, float y, float z, float orientation);
void SendMovementCatalogEnd(ChatHandler* handler, std::uint32_t count);
void SendMovementCurrent(ChatHandler* handler, std::uint32_t map, std::uint32_t zone, std::uint32_t area, std::uint32_t phase, float x, float y, float z, float orientation);
void SendMovementResult(ChatHandler* handler, std::string const& result, std::string const& reason);
void SendMovementError(ChatHandler* handler, std::string const& reason);
}

#endif
