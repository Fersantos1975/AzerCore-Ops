#include "AzerCoreOpsBuildInfo.h"

#include "GitRevision.h"
#include "azercoreops_build_info.generated.h"

namespace AzerCoreOps
{
BuildInfo GetBuildInfo()
{
    BuildInfo info;
    info.moduleVersion = AZERCORE_OPS_MODULE_VERSION;
    info.protocolVersion = AZERCORE_OPS_PROTOCOL_VERSION;
    info.releaseChannel = AZERCORE_OPS_RELEASE_CHANNEL;
    info.capabilities = AZERCORE_OPS_CAPABILITIES;
    info.moduleCommit = AZERCORE_OPS_MODULE_GIT_HASH;
    info.moduleWorkspace = AZERCORE_OPS_MODULE_GIT_DIRTY;
    info.coreCommit = GitRevision::GetHash();
    info.coreDate = GitRevision::GetDate();
    info.coreWorkspace = AZERCORE_OPS_CORE_GIT_DIRTY;
    info.playerbotsCommit = AZERCORE_OPS_PLAYERBOTS_GIT_HASH;
    info.playerbotsWorkspace = AZERCORE_OPS_PLAYERBOTS_GIT_DIRTY;
    info.buildType = AZERCORE_OPS_BUILD_TYPE;
    info.builtAt = __DATE__ " " __TIME__;
    return info;
}
}
