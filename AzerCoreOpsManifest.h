#ifndef AZERCORE_OPS_MANIFEST_H
#define AZERCORE_OPS_MANIFEST_H

#include "Build/AzerCoreOpsBuildInfo.h"

namespace AzerCoreOps::Manifest
{
// Returns the immutable metadata snapshot advertised to the addon.
BuildInfo const& Get();

// Capability lookup for server-side feature gating.
bool Supports(char const* capability);
}

#endif
