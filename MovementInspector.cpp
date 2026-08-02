#include "MovementInspector.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "MapManager.h"
#include "Player.h"
#include "Protocol/ChatProtocol.h"
#include "WorldSession.h"

#include <unordered_map>

namespace AzerCoreOps
{
namespace
{
struct ReturnPoint { uint32 map; float x; float y; float z; float o; };
std::unordered_map<uint32, ReturnPoint> returnPoints;
std::string Category(uint32 map)
{
    if (map == 0) return "Eastern Kingdoms";
    if (map == 1) return "Kalimdor";
    if (map == 530) return "Outland";
    if (map == 571) return "Northrend";
    return "Instances / Other";
}
}

bool MovementInspector::Catalog(ChatHandler* handler)
{
    if (!handler || !handler->GetSession()) return false;
    Protocol::SendMovementCatalogBegin(handler);
    uint32 count = 0;
    QueryResult result = WorldDatabase.Query("SELECT id, name, map, position_x, position_y, position_z, orientation FROM game_tele ORDER BY name");
    if (result) do
    {
        Field* f = result->Fetch(); uint32 map = f[2].Get<uint32>();
        Protocol::SendMovementDestination(handler, f[0].Get<uint32>(), f[1].Get<std::string>(), Category(map), map, f[3].Get<float>(), f[4].Get<float>(), f[5].Get<float>(), f[6].Get<float>()); ++count;
    } while (result->NextRow() && count < 1000);
    Protocol::SendMovementCatalogEnd(handler, count); return true;
}

bool MovementInspector::Current(ChatHandler* handler)
{
    Player* p = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr; if (!p) return false;
    Protocol::SendMovementCurrent(handler, p->GetMapId(), p->GetZoneId(), p->GetAreaId(), p->GetPhaseMask(), p->GetPositionX(), p->GetPositionY(), p->GetPositionZ(), p->GetOrientation()); return true;
}

bool MovementInspector::Go(ChatHandler* handler, uint32 map, float x, float y, float z, float orientation)
{
    Player* p = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr; if (!p) return false;
    if (!MapManager::IsValidMapCoord(map, x, y, z, orientation)) { Protocol::SendMovementError(handler,"Unsafe or invalid map coordinates"); return true; }
    returnPoints[p->GetGUID().GetCounter()]={p->GetMapId(),p->GetPositionX(),p->GetPositionY(),p->GetPositionZ(),p->GetOrientation()};
    bool ok=p->TeleportTo(map,x,y,z,orientation); Protocol::SendMovementResult(handler,ok?"SUCCESS":"FAILED",ok?"Teleport completed":"Core rejected destination"); return true;
}

bool MovementInspector::Return(ChatHandler* handler)
{
    Player* p = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr; if (!p) return false;
    auto it=returnPoints.find(p->GetGUID().GetCounter()); if (it==returnPoints.end()) { Protocol::SendMovementError(handler,"No emergency return point is available"); return true; }
    ReturnPoint point=it->second; bool ok=p->TeleportTo(point.map,point.x,point.y,point.z,point.o); if (ok) returnPoints.erase(it); Protocol::SendMovementResult(handler,ok?"SUCCESS":"FAILED",ok?"Returned to previous location":"Return teleport failed"); return true;
}
}
