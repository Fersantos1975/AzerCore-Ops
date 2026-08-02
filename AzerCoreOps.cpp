#include "AzerCoreOps.h"

namespace AzerCoreOps
{
Application& Application::Instance()
{
    static Application instance;
    return instance;
}

void Application::Reset() noexcept
{
    _inspectors.Clear();
    _diagnostics.Clear();
}
} // namespace AzerCoreOps
