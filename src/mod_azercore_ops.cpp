#include "Build/AzerCoreOpsBuildInfo.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Inspectors/Instance/InstanceInspector.h"
#include "Inspectors/Quest/QuestInspector.h"
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
        };
        static ChatCommandTable questTable =
        {
            { "search", AzerCoreOps::QuestInspector::Search, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "info", AzerCoreOps::QuestInspector::Info, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "audit", AzerCoreOps::QuestInspector::Audit, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "log", AzerCoreOps::QuestInspector::Log, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
        };
        static ChatCommandTable azerCoreOpsTable =
        {
            { "instance", instanceTable },
            { "quest", questTable },
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
