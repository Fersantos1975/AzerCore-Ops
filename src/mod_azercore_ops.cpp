#include "Build/AzerCoreOpsBuildInfo.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Inspectors/Instance/InstanceInspector.h"
#include "Inspectors/Character/CharacterInspector.h"
#include "Inspectors/Quest/QuestInspector.h"
#include "Inspectors/NPC/NPCInspector.h"
#include "Manifest/AzerCoreOpsManifest.h"
#include "Protocol/ChatProtocol.h"
#include "RBAC.h"

using namespace Acore::ChatCommands;

namespace
{
class realm_ops_commands : public CommandScript
{
public:
    realm_ops_commands() : CommandScript("realm_ops_commands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable instanceTable =
        {
            { "search", AzerCoreOps::InstanceInspector::Search, rbac::RBAC_PERM_COMMAND_LOOKUP_MAP, Console::No },
            { "audit", AzerCoreOps::InstanceInspector::Audit, rbac::RBAC_PERM_COMMAND_INSTANCE_LISTBINDS, Console::No },
            { "binds", AzerCoreOps::InstanceInspector::Binds, rbac::RBAC_PERM_COMMAND_INSTANCE_LISTBINDS, Console::No },
            { "unbind", AzerCoreOps::InstanceInspector::Unbind, rbac::RBAC_PERM_COMMAND_INSTANCE_UNBIND, Console::No },
        };
        static ChatCommandTable questTable =
        {
            { "search", AzerCoreOps::QuestInspector::Search, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "info", AzerCoreOps::QuestInspector::Info, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "audit", AzerCoreOps::QuestInspector::Audit, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "log", AzerCoreOps::QuestInspector::Log, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
        };
        static ChatCommandTable characterTable =
        {
            { "inspect", AzerCoreOps::CharacterInspector::Inspect, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "raid", AzerCoreOps::CharacterInspector::Raid, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "save", AzerCoreOps::CharacterInspector::SaveTarget, rbac::RBAC_PERM_COMMAND_INSTANCE_UNBIND, Console::No },
        };
        static ChatCommandTable npcTable =
        {
            { "inspect", AzerCoreOps::NPCInspector::Inspect, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
        };
        static ChatCommandTable azerCoreOpsTable =
        {
            { "instance", instanceTable },
            { "quest", questTable },
            { "character", characterTable },
            { "npc", npcTable },
            { "version", HandleVersion, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
        };
        static ChatCommandTable commands = { { "azercoreops", azerCoreOpsTable } };
        return commands;
    }

    static bool HandleVersion(ChatHandler* handler)
    {
        AzerCoreOps::Protocol::SendVersion(handler, AzerCoreOps::Manifest::Get());
        return true;
    }
};
}

void AddSC_realm_ops_commands()
{
    new realm_ops_commands();
}
