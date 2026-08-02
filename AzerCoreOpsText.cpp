#include "AzerCoreOpsText.h"

#include "Chat.h"
#include "DBCStores.h"

#include <algorithm>

namespace AzerCoreOps
{
std::string Clean(std::string value)
{
    std::replace(value.begin(), value.end(), '|', '/');
    std::replace(value.begin(), value.end(), '\n', ' ');
    std::replace(value.begin(), value.end(), '\r', ' ');
    return value;
}

std::string LocalizedMapName(MapEntry const* entry, ChatHandler* handler)
{
    if (!entry)
        return "Unknown";

    int locale = handler->GetSessionDbcLocale();
    std::string name = entry->name[locale];
    if (name.empty())
        name = entry->name[LOCALE_enUS];
    return Clean(name);
}
}
