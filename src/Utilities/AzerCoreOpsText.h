#ifndef AZERCORE_OPS_TEXT_H
#define AZERCORE_OPS_TEXT_H

#include <string>

class ChatHandler;
struct MapEntry;

namespace AzerCoreOps
{
std::string Clean(std::string value);
std::string LocalizedMapName(MapEntry const* entry, ChatHandler* handler);
}

#endif
