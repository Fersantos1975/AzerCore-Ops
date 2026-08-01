#include "ChatProtocol.h"

#include "Chat.h"
#include "Utilities/AzerCoreOpsText.h"

namespace AzerCoreOps::Protocol
{
void SendVersion(ChatHandler* handler, BuildInfo const& info)
{
    handler->PSendSysMessage(
        "AZERCORE_OPS|VERSION|module={}|protocol={}|release={}|capabilities={}|modulegit={}|moduledirty={}|core={}|coredate={}|coredirty={}|playerbots={}|playerbotsdirty={}|build={}|built={}",
        info.moduleVersion, info.protocolVersion, info.releaseChannel, info.capabilities, info.moduleCommit, info.moduleWorkspace,
        info.coreCommit, info.coreDate, info.coreWorkspace, info.playerbotsCommit,
        info.playerbotsWorkspace, info.buildType, info.builtAt);
}

void SendError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|ERROR|reason={}", Clean(reason)); }
void SendInstanceSearch(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t maxPlayers) { handler->PSendSysMessage("AZERCORE_OPS|SEARCH|map={}|name={}|type={}|max={}", mapId, Clean(name), type, maxPlayers); }
void SendInstanceSearchEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|SEARCH_END|count={}", count); }
void SendInstanceBegin(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::uint32_t difficulty, std::uint32_t referenceId, std::uint32_t members) { handler->PSendSysMessage("AZERCORE_OPS|BEGIN|map={}|name={}|difficulty={}|reference={}|members={}", mapId, Clean(name), difficulty, referenceId, members); }
void SendInstanceMember(ChatHandler* handler, std::string const& name, std::string const& result, std::uint32_t mapId, std::uint32_t currentInstanceId, std::uint32_t phaseMask, std::uint32_t bindId, bool permanent, bool extended, bool canReset, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|MEMBER|name={}|result={}|map={}|instance={}|phase={}|bind={}|permanent={}|extended={}|canreset={}|encountermask={}|bosstotal={}|bossdefeated={}|reason={}", Clean(name), result, mapId, currentInstanceId, phaseMask, bindId, permanent ? 1 : 0, extended ? 1 : 0, canReset ? 1 : 0, encounterMask, bossTotal, bossDefeated, Clean(reason)); }
void SendInstanceEnd(ChatHandler* handler) { handler->SendSysMessage("AZERCORE_OPS|END"); }
void SendBindBegin(ChatHandler* handler, std::string const& player, std::string const& scope, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|BIND_BEGIN|player={}|scope={}|count={}", Clean(player), scope, count); }
void SendBindEntry(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t instanceId, std::uint32_t difficulty, bool permanent, bool extended, bool canReset, bool applicable, std::uint32_t resetSeconds, std::uint32_t encounterMask, std::uint32_t bossTotal, std::uint32_t bossDefeated, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|BIND_ENTRY|map={}|name={}|type={}|instance={}|difficulty={}|permanent={}|extended={}|canreset={}|applicable={}|reset={}|encountermask={}|bosstotal={}|bossdefeated={}|reason={}", mapId, Clean(name), type, instanceId, difficulty, permanent ? 1 : 0, extended ? 1 : 0, canReset ? 1 : 0, applicable ? 1 : 0, resetSeconds, encounterMask, bossTotal, bossDefeated, Clean(reason)); }
void SendBindBoss(ChatHandler* handler, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t difficulty, std::uint32_t index, bool defeated, std::string const& name) { handler->PSendSysMessage("AZERCORE_OPS|BIND_BOSS|map={}|instance={}|difficulty={}|index={}|defeated={}|name={}", mapId, instanceId, difficulty, index, defeated ? 1 : 0, Clean(name)); }
void SendBindEnd(ChatHandler* handler, std::string const& player, std::uint32_t count) { handler->PSendSysMessage("AZERCORE_OPS|BIND_END|player={}|count={}", Clean(player), count); }
void SendUnbindBegin(ChatHandler* handler, std::string const& operation, std::string const& player, std::uint32_t requested) { handler->PSendSysMessage("AZERCORE_OPS|UNBIND_BEGIN|operation={}|player={}|requested={}", Clean(operation), Clean(player), requested); }
void SendUnbindResult(ChatHandler* handler, std::string const& operation, std::uint32_t mapId, std::uint32_t difficulty, std::uint32_t instanceId, std::string const& result, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|UNBIND_RESULT|operation={}|map={}|difficulty={}|instance={}|result={}|reason={}", Clean(operation), mapId, difficulty, instanceId, result, Clean(reason)); }
void SendUnbindEnd(ChatHandler* handler, std::string const& operation, std::uint32_t succeeded, std::uint32_t failed) { handler->PSendSysMessage("AZERCORE_OPS|UNBIND_END|operation={}|succeeded={}|failed={}", Clean(operation), succeeded, failed); }
void SendQuestError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_ERROR|reason={}", Clean(reason)); }
void SendQuestSearch(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::string const& eligibility, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& player) { handler->PSendSysMessage("AZERCORE_OPS|QUEST_SEARCH|id={}|title={}|faction={}|eligibility={}|status={}|min={}|level={}|type={}|player={}", id, Clean(title), faction, eligibility, status, minLevel, level, type, Clean(player)); }
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
}
