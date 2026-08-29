#include "ChatProtocol.h"

#include "Chat.h"
#include "Utilities/AzerCoreOpsText.h"
#include "WorldSession.h"

#include <algorithm>

namespace AzerCoreOps::Protocol
{
void SendVersion(ChatHandler* handler, BuildInfo const& info)
{
    bool gm = handler && handler->GetSession() && handler->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
    std::string permissions = std::string("CHARACTER_MODE=") + (gm ? "GM" : "PLAYER") +
        ";CHARACTER_TECHNICAL=" + (gm ? "GRANTED" : "RESTRICTED") +
        ";CHARACTER_SAVE_TARGET=" + (gm ? "GRANTED" : "RESTRICTED");
    std::string features = "CHARACTER:CHARACTER_INSPECT,CHARACTER_INVENTORY,CHARACTER_PROFESSIONS,CHARACTER_RAID_EXPERIENCE;NPC:NPC_INSPECT,NPC_QUEST_RELATIONS,NPC_LOOT,NPC_STORY,NPC_TECHNICAL;ITEM:ITEM_INSPECT,ITEM_CRAFTING,ITEM_SOURCES,ITEM_USES;MOVEMENT:MOVEMENT_CATALOG,MOVEMENT_PERSONAL_LOCATIONS,MOVEMENT_RETURN,MOVEMENT_SHARING_DISABLED;INSTANCE:INSTANCE_SEARCH,INSTANCE_AUDIT,INSTANCE_STRUCTURED_BINDS,INSTANCE_ENCOUNTER_DIAGNOSTICS,INSTANCE_ENCOUNTER_HISTORY,INSTANCE_ENCOUNTER_ANOMALIES,INSTANCE_RECOVERY_GUIDANCE;QUEST:QUEST_SEARCH,QUEST_INFO,QUEST_TARGET_LOG";
    handler->PSendSysMessage(
        "AZERCORE_OPS|VERSION|module={}|protocol={}|capschema=1|release={}|capabilities={}|features={}|permissions={}|modulegit={}|moduledirty={}|core={}|coredate={}|coredirty={}|playerbots={}|playerbotsdirty={}|build={}|built={}",
        info.moduleVersion, info.protocolVersion, info.releaseChannel, info.capabilities, features, permissions, info.moduleCommit, info.moduleWorkspace,
        info.coreCommit, info.coreDate, info.coreWorkspace, info.playerbotsCommit,
        info.playerbotsWorkspace, info.buildType, info.builtAt);
    handler->PSendSysMessage("AZERCORE_OPS|CAPABILITIES|values={}|features={}", info.capabilities, features);
    handler->PSendSysMessage("AZERCORE_OPS|PERMISSIONS|values={}", permissions);
    handler->PSendSysMessage("AZERCORE_OPS|BUILD|modulegit={}|moduledirty={}|core={}|coredate={}|coredirty={}|playerbots={}|playerbotsdirty={}", info.moduleCommit, info.moduleWorkspace, info.coreCommit, info.coreDate, info.coreWorkspace, info.playerbotsCommit, info.playerbotsWorkspace);
    handler->PSendSysMessage("AZERCORE_OPS|BUILD_EXT|build={}|built={}", info.buildType, info.builtAt);
}

void SendError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|ERROR|reason={}", Clean(reason)); }
void SendInstanceSearch(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t maxPlayers) { handler->PSendSysMessage("AZERCORE_OPS|SEARCH|map={}|name={}|type={}|max={}", mapId, Clean(name), type, maxPlayers); }
void SendInstanceSearchEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|SEARCH_END|count={}", count); }
void SendInstanceBegin(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::uint32_t difficulty, std::uint32_t referenceId, std::uint32_t members) { handler->PSendSysMessage("AZERCORE_OPS|BEGIN|map={}|name={}|difficulty={}|reference={}|members={}", mapId, Clean(name), difficulty, referenceId, members); }
void SendInstanceMember(ChatHandler* handler, std::string const& name, std::string const& result, std::uint32_t mapId, std::uint32_t currentInstanceId, std::uint32_t phaseMask, std::uint32_t bindId, bool permanent, bool extended, bool canReset, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|MEMBER|name={}|result={}|map={}|instance={}|phase={}|bind={}|permanent={}|extended={}|canreset={}|encountermask={}|bosstotal={}|bossdefeated={}|reason={}", Clean(name), result, mapId, currentInstanceId, phaseMask, bindId, permanent ? 1 : 0, extended ? 1 : 0, canReset ? 1 : 0, encounterMask, bossTotal, bossDefeated, Clean(reason)); }
void SendInstanceEnd(ChatHandler* handler) { handler->SendSysMessage("AZERCORE_OPS|END"); }
void SendEncounterDiagnosticBegin(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::string const& mapName, std::string const& scriptName) { handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_DIAG_BEGIN|map={}|instance={}|difficulty={}|name={}|script={}", mapId, instanceId, difficulty, Clean(mapName), Clean(scriptName)); }
void SendEncounterDiagnosticFinding(ChatHandler* handler, std::string const& severity, std::string const& category, std::string const& subject, std::string const& expected, std::string const& actual, std::string const& detail, std::string const& recommendation) { handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_DIAG_FINDING|severity={}|category={}|subject={}|expected={}|actual={}|detail={}|recommendation={}", Clean(severity), Clean(category), Clean(subject), Clean(expected), Clean(actual), Clean(detail), Clean(recommendation)); }
void SendEncounterDiagnosticRecovery(ChatHandler* handler, std::string const& id, std::string const& title, std::string const& confidence, std::string const& evidence, std::string const& verificationCommand, std::string const& actionCommands, std::string const& recheckCommand, std::string const& expectedResult, std::string const& safety) { handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_DIAG_RECOVERY|id={}|title={}|confidence={}|evidence={}|verify={}|actions={}|recheck={}|expected={}|safety={}", Clean(id), Clean(title), Clean(confidence), Clean(evidence), Clean(verificationCommand), Clean(actionCommands), Clean(recheckCommand), Clean(expectedResult), Clean(safety)); }
void SendEncounterDiagnosticEnd(ChatHandler* handler, std::uint32_t passed, std::uint32_t warnings, std::uint32_t failures) { handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_DIAG_END|passed={}|warnings={}|failures={}", passed, warnings, failures); }
void SendEncounterDiagnosticError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_DIAG_ERROR|reason={}", Clean(reason)); }
void SendEncounterHistoryBegin(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::string const& mapName, std::uint32_t count) { if (handler) handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_HISTORY_BEGIN|map={}|instance={}|difficulty={}|name={}|count={}", mapId, instanceId, difficulty, Clean(mapName), count); }
void SendEncounterHistoryEntry(ChatHandler* handler, std::uint64_t sequence, std::uint64_t timestampMs, std::uint32_t encounterId, std::string const& name, std::uint32_t oldState, std::string const& oldName, std::uint32_t newState, std::string const& newName, std::string const& classification, std::string const& event, std::uint32_t attempt, std::uint32_t wipes, std::uint32_t kills, std::string const& detail) { if (handler) handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_HISTORY_ENTRY|seq={}|time={}|id={}|name={}|old={}|oldname={}|new={}|newname={}|class={}|event={}|attempt={}|wipes={}|kills={}|detail={}", sequence, timestampMs, encounterId, Clean(name), oldState, Clean(oldName), newState, Clean(newName), Clean(classification), Clean(event), attempt, wipes, kills, Clean(detail)); }
void SendEncounterHistoryStats(ChatHandler* handler, std::uint32_t encounterId, std::string const& name, std::uint32_t attempts, std::uint32_t wipes, std::uint32_t kills) { if (handler) handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_HISTORY_STATS|id={}|name={}|attempts={}|wipes={}|kills={}", encounterId, Clean(name), attempts, wipes, kills); }
void SendEncounterHistoryEnd(ChatHandler* handler, std::uint32_t count, std::uint32_t anomalies) { if (handler) handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_HISTORY_END|count={}|anomalies={}", count, anomalies); }
void SendEncounterHistoryError(ChatHandler* handler, std::string const& reason) { if (handler) handler->PSendSysMessage("AZERCORE_OPS|ENCOUNTER_HISTORY_ERROR|reason={}", Clean(reason)); }
void SendBindBegin(ChatHandler* handler, std::string const& player, std::string const& scope, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|BIND_BEGIN|player={}|scope={}|count={}", Clean(player), scope, count); }
void SendBindEntry(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t instanceId, std::uint32_t difficulty, bool permanent, bool extended, bool canReset, bool applicable, std::uint32_t resetSeconds, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|BIND_ENTRY|map={}|name={}|type={}|instance={}|difficulty={}|permanent={}|extended={}|canreset={}|applicable={}|reset={}|encountermask={}|bosstotal={}|bossdefeated={}|reason={}", mapId, Clean(name), type, instanceId, difficulty, permanent ? 1 : 0, extended ? 1 : 0, canReset ? 1 : 0, applicable ? 1 : 0, resetSeconds, encounterMask, bossTotal, bossDefeated, Clean(reason)); }
void SendBindBoss(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::uint32_t index, bool defeated, std::string const& name) { handler->PSendSysMessage("AZERCORE_OPS|BIND_BOSS|map={}|instance={}|difficulty={}|index={}|defeated={}|name={}", mapId, instanceId, difficulty, index, defeated ? 1 : 0, Clean(name)); }
void SendBindEnd(ChatHandler* handler, std::string const& player, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|BIND_END|player={}|count={}", Clean(player), count); }
void SendUnbindBegin(ChatHandler* handler, std::string const& operation, std::string const& player, std::uint32_t requested) { handler->PSendSysMessage("AZERCORE_OPS|UNBIND_BEGIN|operation={}|player={}|requested={}", Clean(operation), Clean(player), requested); }
void SendUnbindResult(ChatHandler* handler, std::string const& operation, std::uint32_t mapId, std::uint32_t difficulty, std::uint32_t instanceId, std::string const& result, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|UNBIND_RESULT|operation={}|map={}|difficulty={}|instance={}|result={}|reason={}", Clean(operation), mapId, difficulty, instanceId, result, Clean(reason)); }
void SendUnbindEnd(ChatHandler* handler, std::string const& operation, std::uint32_t succeeded, std::uint32_t failed) { handler->PSendSysMessage("AZERCORE_OPS|UNBIND_END|operation={}|succeeded={}|failed={}", Clean(operation), succeeded, failed); }
void SendQuestError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_ERROR|reason={}", Clean(reason)); }
void SendQuestSearch(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::string const& eligibility, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& player, std::string const& matchKind, std::uint32_t matchId, std::string const& matchName, std::uint32_t matchCount)
{
    handler->PSendSysMessage(
        "AZERCORE_OPS|QUEST_SEARCH|id={}|title={}|faction={}|eligibility={}|status={}|min={}|level={}|type={}|player={}|matchkind={}|matchid={}|matchname={}|matchcount={}",
        id,
        Clean(title),
        faction,
        eligibility,
        status,
        minLevel,
        level,
        type,
        Clean(player),
        Clean(matchKind),
        matchId,
        Clean(matchName),
        matchCount);
}
void SendQuestSearchEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_SEARCH_END|count={}", count); }
void SendQuestInfo(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::int32_t minLevel, std::int32_t level, std::string const& type, bool repeatable, std::string const& status, std::string const& eligibility, std::string const& reason, std::string const& items, std::string const& reputation, std::string const& player, std::string const& starters, std::string const& enders)
{
    handler->PSendSysMessage("AZERCORE_OPS|QUEST_INFO|id={}|title={}|faction={}|min={}|level={}|type={}|repeatable={}|status={}|eligibility={}|reason={}|items={}|reputation={}|player={}|starters={}|enders={}", id, Clean(title), faction, minLevel, level, type, repeatable ? "yes" : "no", status, eligibility, Clean(reason), Clean(items), Clean(reputation), Clean(player), Clean(starters), Clean(enders));
}
void SendQuestChain(ChatHandler* handler, std::string const& direction, std::uint32_t id, std::string const& title, std::string const& status, std::string const& eligibility, std::string const& faction, std::string const& required, std::uint32_t depth, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_CHAIN|direction={}|id={}|title={}|status={}|eligibility={}|faction={}|required={}|depth={}|reason={}", direction, id, Clean(title), status, eligibility, faction, required, depth, Clean(reason)); }
void SendQuestInfoEnd(ChatHandler* handler, std::uint32_t id, std::uint32_t chainCount) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_INFO_END|id={}|chain={}", id, chainCount); }
void SendQuestAuditBegin(ChatHandler* handler, std::uint32_t id, std::string const& title, std::uint32_t members) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_AUDIT_BEGIN|id={}|title={}|members={}", id, Clean(title), members); }
void SendQuestAuditMember(ChatHandler* handler, std::string const& name, std::string const& result, std::string const& status, std::string const& eligibility, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_AUDIT_MEMBER|name={}|result={}|status={}|eligibility={}|reason={}", Clean(name), result, status, eligibility, Clean(reason)); }
void SendQuestAuditEnd(ChatHandler* handler) { handler->SendSysMessage("AZERCORE_OPS|QUEST_AUDIT_END"); }
void SendQuestLogBegin(ChatHandler* handler, std::string const& player, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_LOG_BEGIN|player={}|count={}", Clean(player), count); }
void SendQuestLogEntry(ChatHandler* handler, std::uint32_t slot, std::uint32_t id, std::string const& title, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& faction) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_LOG_ENTRY|slot={}|id={}|title={}|status={}|min={}|level={}|type={}|faction={}", slot, id, Clean(title), status, minLevel, level, Clean(type), faction); }
void SendQuestLogEnd(ChatHandler* handler, std::string const& player, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_LOG_END|player={}|count={}", Clean(player), count); }
void SendCharacterError(ChatHandler* handler, std::string const& reason) { if (handler) handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_ERROR|reason={}", Clean(reason)); }
void SendCharacterBegin(ChatHandler* handler, std::string const& player, std::string const& mode) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_BEGIN|player={}|mode={}", Clean(player), mode); }
void SendCharacterOverview(ChatHandler* handler, std::string const& player, std::uint32_t level, std::uint32_t race, std::uint32_t playerClass, std::string const& faction, std::uint32_t guildId, std::string const& guid) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_OVERVIEW|player={}|level={}|race={}|class={}|faction={}|guild={}|guid={}", Clean(player), level, race, playerClass, faction, guildId, Clean(guid)); }
void SendCharacterState(ChatHandler* handler, bool alive, bool combat, std::uint32_t health, std::uint32_t maxHealth, std::uint32_t powerType, std::uint32_t power, std::uint32_t maxPower) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_STATE|alive={}|combat={}|health={}|maxhealth={}|powertype={}|power={}|maxpower={}", alive ? 1 : 0, combat ? 1 : 0, health, maxHealth, powerType, power, maxPower); }
void SendCharacterLocation(ChatHandler* handler, std::uint32_t map, std::uint32_t zone, std::uint32_t area, std::uint32_t instance, std::uint32_t phase, float x, float y, float z, float orientation, bool authorized) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_LOCATION|map={}|zone={}|area={}|instance={}|phase={}|x={:.2f}|y={:.2f}|z={:.2f}|o={:.2f}|authorized={}", map, zone, area, instance, phase, x, y, z, orientation, authorized ? 1 : 0); }
void SendCharacterInventory(ChatHandler* handler, std::uint32_t used, std::uint32_t capacity, std::uint32_t equipped, std::uint32_t averageItemLevel) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_INVENTORY|used={}|capacity={}|equipped={}|average={}", used, capacity, equipped, averageItemLevel); }
void SendCharacterProfession(ChatHandler* handler, std::uint32_t id, std::string const& name, std::string const& category, std::uint32_t value, std::uint32_t maximum) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_PROFESSION|id={}|name={}|category={}|value={}|maximum={}", id, Clean(name), category, value, maximum); }
void SendCharacterRaid(ChatHandler* handler, std::string const& raidKey, std::string const& difficultyKey, std::string const& raid, std::string const& difficulty, std::string const& section, std::uint32_t achievement, bool complete) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_RAID|raidkey={}|difficultykey={}|raid={}|difficulty={}|section={}|achievement={}|complete={}", raidKey, difficultyKey, Clean(raid), Clean(difficulty), Clean(section), achievement, complete ? 1 : 0); }
void SendCharacterRaidEnd(ChatHandler* handler, std::string const& player, std::string const& raidKey, std::string const& difficultyKey, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_RAID_END|player={}|raidkey={}|difficultykey={}|count={}", Clean(player), raidKey, difficultyKey, count); }
void SendCharacterEnd(ChatHandler* handler, std::string const& player) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_END|player={}", Clean(player)); }
void SendCharacterSaveResult(ChatHandler* handler, std::string const& player, std::string const& result, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|CHARACTER_SAVE_RESULT|player={}|result={}|reason={}", Clean(player), result, Clean(reason)); }
void SendNPCError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|NPC_ERROR|reason={}", Clean(reason)); }
void SendNPCSearchBegin(ChatHandler* handler, std::string const& query) { handler->PSendSysMessage("AZERCORE_OPS|NPC_SEARCH_BEGIN|query={}", Clean(query)); }
void SendNPCSearchResult(ChatHandler* handler, std::uint32_t entry, std::string const& name, std::uint32_t minLevel, std::uint32_t maxLevel, std::uint32_t rank, std::uint32_t type, std::uint32_t spawns) { handler->PSendSysMessage("AZERCORE_OPS|NPC_SEARCH_RESULT|entry={}|name={}|min={}|max={}|rank={}|type={}|spawns={}", entry, Clean(name), minLevel, maxLevel, rank, type, spawns); }
void SendNPCSearchEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|NPC_SEARCH_END|count={}", count); }
void SendNPCSpawnsBegin(ChatHandler* handler, std::uint32_t entry, std::string const& name, std::uint32_t total) { handler->PSendSysMessage("AZERCORE_OPS|NPC_SPAWNS_BEGIN|entry={}|name={}|total={}", entry, Clean(name), total); }
void SendNPCSpawn(ChatHandler* handler, std::uint32_t entry, std::uint32_t guid, std::uint32_t map, float x, float y, float z, float orientation, std::uint32_t spawnMask, std::uint32_t phaseMask, bool sameMap, float distance, std::string const& status, bool gridLoaded, std::uint32_t respawnSeconds)
{
    handler->PSendSysMessage(
        "AZERCORE_OPS|NPC_SPAWN|entry={}|guid={}|map={}|x={:.3f}|y={:.3f}|z={:.3f}|o={:.3f}|spawnmask={}|phasemask={}|samemap={}|distance={:.2f}|status={}|gridloaded={}|respawn={}",
        entry,
        guid,
        map,
        x,
        y,
        z,
        orientation,
        spawnMask,
        phaseMask,
        sameMap ? 1 : 0,
        distance,
        Clean(status),
        gridLoaded ? 1 : 0,
        respawnSeconds);
}
void SendNPCSpawnsEnd(ChatHandler* handler, std::uint32_t entry, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|NPC_SPAWNS_END|entry={}|count={}", entry, count); }
void SendNPCBegin(ChatHandler* handler, std::string const& name, std::uint32_t entry, std::string const& guid, std::string const& player) { handler->PSendSysMessage("AZERCORE_OPS|NPC_BEGIN|name={}|entry={}|guid={}|player={}", Clean(name), entry, Clean(guid), Clean(player)); }
void SendNPCOverview(ChatHandler* handler, std::uint32_t level, std::uint32_t minLevel, std::uint32_t maxLevel, std::uint32_t rank, std::uint32_t type, std::uint32_t family, std::uint32_t faction, std::uint32_t npcFlags) { handler->PSendSysMessage("AZERCORE_OPS|NPC_OVERVIEW|level={}|min={}|max={}|rank={}|type={}|family={}|faction={}|npcflags={}", level, minLevel, maxLevel, rank, type, family, faction, npcFlags); }
void SendNPCState(ChatHandler* handler, bool alive, bool combat, std::uint32_t health, std::uint32_t maxHealth, std::uint32_t powerType, std::uint32_t power, std::uint32_t maxPower) { handler->PSendSysMessage("AZERCORE_OPS|NPC_STATE|alive={}|combat={}|health={}|maxhealth={}|powertype={}|power={}|maxpower={}", alive ? 1 : 0, combat ? 1 : 0, health, maxHealth, powerType, power, maxPower); }
void SendNPCLocation(ChatHandler* handler, std::uint32_t map, std::uint32_t zone, std::uint32_t area, std::uint32_t instance, std::uint32_t phase, float x, float y, float z, float orientation) { handler->PSendSysMessage("AZERCORE_OPS|NPC_LOCATION|map={}|zone={}|area={}|instance={}|phase={}|x={:.2f}|y={:.2f}|z={:.2f}|o={:.2f}", map, zone, area, instance, phase, x, y, z, orientation); }
void SendNPCSpawnInfo(ChatHandler* handler, std::uint64_t spawnId, bool databaseBacked, float homeX, float homeY, float homeZ, float homeOrientation, std::uint32_t respawnDelay, std::uint32_t corpseDelay, std::uint32_t movementType, float wanderDistance)
{
    handler->PSendSysMessage(
        "AZERCORE_OPS|NPC_SPAWN_INFO|spawnid={}|dbspawn={}|homex={:.3f}|homey={:.3f}|homez={:.3f}|homeo={:.3f}|respawndelay={}|corpsedelay={}|movement={}|wander={:.2f}",
        spawnId,
        databaseBacked ? 1 : 0,
        homeX,
        homeY,
        homeZ,
        homeOrientation,
        respawnDelay,
        corpseDelay,
        movementType,
        wanderDistance);
}
void SendNPCTechnical(ChatHandler* handler, std::uint32_t unitFlags, std::uint32_t dynamicFlags, std::uint32_t loot, std::uint32_t pickpocket, std::uint32_t skin, std::uint32_t minGold, std::uint32_t maxGold, std::string const& ai, std::uint32_t script) { handler->PSendSysMessage("AZERCORE_OPS|NPC_TECHNICAL|unitflags={}|dynamicflags={}|loot={}|pickpocket={}|skin={}|mingold={}|maxgold={}|ai={}|script={}", unitFlags, dynamicFlags, loot, pickpocket, skin, minGold, maxGold, Clean(ai), script); }
void SendNPCQuest(ChatHandler* handler, std::string const& relation, std::uint32_t id, std::string const& title, std::string const& status, std::string const& eligibility, std::string const& reason, std::int32_t minLevel, std::int32_t level, std::string const& type, bool repeatable) { handler->PSendSysMessage("AZERCORE_OPS|NPC_QUEST|relation={}|id={}|title={}|status={}|eligibility={}|reason={}|min={}|level={}|type={}|repeatable={}", relation, id, Clean(title), status, eligibility, Clean(reason), minLevel, level, Clean(type), repeatable ? 1 : 0); }
void SendNPCLoot(ChatHandler* handler, std::uint32_t id, std::string const& name, std::uint32_t quality, float chance, std::uint32_t minimum, std::uint32_t maximum, bool questRequired, std::string const& source, std::uint32_t tableId, std::uint32_t lootMode, std::uint32_t groupId)
{
    handler->PSendSysMessage(
        "AZERCORE_OPS|NPC_LOOT|source={}|table={}|id={}|name={}|quality={}|chance={:.4f}|min={}|max={}|quest={}|lootmode={}|group={}",
        Clean(source),
        tableId,
        id,
        Clean(name),
        quality,
        chance,
        minimum,
        maximum,
        questRequired ? 1 : 0,
        lootMode,
        groupId);
}

void SendNPCLootReference(ChatHandler* handler, std::string const& source, std::uint32_t tableId, std::uint32_t referenceId, float chance, std::uint32_t minimum, std::uint32_t maximum, std::uint32_t lootMode, std::uint32_t groupId, std::uint32_t rows, std::uint32_t directRows, std::uint32_t nestedRows, std::string const& comment)
{
    handler->PSendSysMessage(
        "AZERCORE_OPS|NPC_LOOT_REFERENCE|source={}|table={}|reference={}|chance={:.4f}|min={}|max={}|lootmode={}|group={}|rows={}|directrows={}|nestedrows={}|comment={}",
        Clean(source),
        tableId,
        referenceId,
        chance,
        minimum,
        maximum,
        lootMode,
        groupId,
        rows,
        directRows,
        nestedRows,
        Clean(comment));
}
std::uint32_t SendNPCStory(ChatHandler* handler, std::string const& category, std::uint32_t sourceId, std::string const& title, std::string const& value)
{
    std::string story = Clean(value);
    if (!handler || story.empty()) return 0;
    constexpr std::size_t chunkSize = 80;
    std::string safeTitle = Clean(title).substr(0, 48);
    std::uint32_t part = 0;
    for (std::size_t offset = 0; offset < story.size();)
    {
        std::size_t length = std::min(chunkSize, story.size() - offset);
        if (offset + length < story.size())
        {
            std::size_t space = story.rfind(' ', offset + length);
            if (space != std::string::npos && space > offset + 50) length = space - offset;
        }
        ++part;
        handler->PSendSysMessage("AZERCORE_OPS|NPC_STORY|category={}|id={}|title={}|part={}|text={}", Clean(category), sourceId, safeTitle, part, story.substr(offset, length));
        offset += length;
        while (offset < story.size() && story[offset] == ' ') ++offset;
    }
    return part;
}
void SendNPCStoryEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|NPC_STORY_END|count={}", count); }
void SendNPCEnd(ChatHandler* handler, std::string const& name, std::uint32_t entry, std::uint32_t quests) { handler->PSendSysMessage("AZERCORE_OPS|NPC_END|name={}|entry={}|quests={}", Clean(name), entry, quests); }
void SendItemError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_ERROR|reason={}", Clean(reason)); }
void SendItemBegin(ChatHandler* handler, std::uint32_t id, std::string const& name, std::uint32_t quality, std::uint32_t itemLevel, std::uint32_t requiredLevel) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_BEGIN|id={}|name={}|quality={}|itemlevel={}|requiredlevel={}", id, Clean(name), quality, itemLevel, requiredLevel); }
void SendItemAccess(ChatHandler* handler, std::uint32_t raceMask, std::uint32_t classMask, std::string const& faction, std::string const& races, std::string const& classes, bool usable, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_ACCESS|racemask={}|classmask={}|faction={}|races={}|classes={}|usable={}|reason={}", raceMask, classMask, Clean(faction), Clean(races), Clean(classes), usable ? 1 : 0, Clean(reason)); }
void SendItemPreview(ChatHandler* handler, std::string const& type, std::uint32_t spell, std::uint32_t creature, std::uint32_t display) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_PREVIEW|type={}|spell={}|creature={}|display={}", Clean(type), spell, creature, display); }
void SendItemRequirement(ChatHandler* handler, std::string const& kind, std::uint32_t id, std::string const& name, std::string const& required, std::string const& current, bool passed, std::string const& detail) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_REQUIREMENT|kind={}|id={}|name={}|required={}|current={}|passed={}|detail={}", Clean(kind), id, Clean(name), Clean(required), Clean(current), passed ? 1 : 0, Clean(detail)); }
void SendItemCraft(ChatHandler* handler, std::uint32_t spell, std::string const& spellName, std::uint32_t skill, std::string const& profession, std::uint32_t rank, std::uint32_t produced, std::string const& resultType, std::string const& chance) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_CRAFT|spell={}|spellname={}|skill={}|profession={}|rank={}|produced={}|resulttype={}|chance={}", spell, Clean(spellName), skill, Clean(profession), rank, produced, Clean(resultType), Clean(chance)); }
void SendItemReagent(ChatHandler* handler, std::uint32_t spell, std::uint32_t id, std::string const& name, std::uint32_t quality, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_REAGENT|spell={}|id={}|name={}|quality={}|count={}", spell, id, Clean(name), quality, count); }
void SendItemRecipe(ChatHandler* handler, std::uint32_t id, std::string const& name, std::uint32_t quality, std::uint32_t spell) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_RECIPE|id={}|name={}|quality={}|spell={}", id, Clean(name), quality, spell); }
void SendItemSource(ChatHandler* handler, std::string const& type, std::uint32_t id, std::string const& name, std::string const& detail) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_SOURCE|type={}|id={}|name={}|detail={}", Clean(type), id, Clean(name), Clean(detail)); }
void SendItemUse(ChatHandler* handler, std::uint32_t spell, std::string const& spellName, std::string const& profession, std::uint32_t rank, std::uint32_t resultId, std::string const& resultName, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_USE|spell={}|spellname={}|profession={}|rank={}|resultid={}|resultname={}|count={}", spell, Clean(spellName), Clean(profession), rank, resultId, Clean(resultName), count); }
void SendItemEnd(ChatHandler* handler, std::uint32_t id, std::uint32_t crafts) { handler->PSendSysMessage("AZERCORE_OPS|ITEM_END|id={}|crafts={}", id, crafts); }
void SendMovementCatalogBegin(ChatHandler* handler) { handler->SendSysMessage("AZERCORE_OPS|MOVEMENT_CATALOG_BEGIN"); }
void SendMovementDestination(ChatHandler* handler, std::uint32_t id, std::string const& name, std::string const& category, std::uint32_t map, float x, float y, float z, float orientation) { handler->PSendSysMessage("AZERCORE_OPS|MOVEMENT_DESTINATION|id={}|name={}|category={}|map={}|x={:.3f}|y={:.3f}|z={:.3f}|o={:.3f}",id,Clean(name),Clean(category),map,x,y,z,orientation); }
void SendMovementCatalogEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|MOVEMENT_CATALOG_END|count={}",count); }
void SendMovementCurrent(ChatHandler* handler, std::uint32_t map, std::uint32_t zone, std::uint32_t area, std::uint32_t phase, float x, float y, float z, float orientation) { handler->PSendSysMessage("AZERCORE_OPS|MOVEMENT_CURRENT|map={}|zone={}|area={}|phase={}|x={:.3f}|y={:.3f}|z={:.3f}|o={:.3f}",map,zone,area,phase,x,y,z,orientation); }
void SendMovementResult(ChatHandler* handler, std::string const& result, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|MOVEMENT_RESULT|result={}|reason={}",Clean(result),Clean(reason)); }
void SendMovementError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|MOVEMENT_ERROR|reason={}",Clean(reason)); }
}
