-- AzerCore Ops Design System v1
-- Single source of truth for workflow colors, semantic states, spacing, and sizes.

AzerCoreOpsDesign = {
  Colors = {
    Background = {0.055, 0.071, 0.086, 0.98},
    Surface = {0.090, 0.110, 0.135, 0.98},
    SurfaceRaised = {0.120, 0.145, 0.170, 0.98},
    Border = {0.350, 0.400, 0.450, 1.00},
    Text = {0.925, 0.940, 0.960, 1.00},
    Muted = {0.620, 0.660, 0.700, 1.00},

    Inspect = {0.122, 0.420, 0.698, 1.00},
    Diagnose = {0.831, 0.627, 0.090, 1.00},
    Resolve = {0.298, 0.686, 0.314, 1.00},
    Operate = {0.714, 0.753, 0.800, 1.00},

    Success = {0.298, 0.686, 0.314, 1.00},
    Warning = {0.957, 0.655, 0.137, 1.00},
    Danger = {0.890, 0.270, 0.250, 1.00},
    Info = {0.122, 0.420, 0.698, 1.00},

    Button = {0.130, 0.155, 0.185, 1.00},
    ButtonHover = {0.190, 0.235, 0.280, 1.00},
    ButtonSelected = {0.105, 0.330, 0.405, 1.00},
  },

  Spacing = {
    XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32,
  },

  Size = {
    Header = 48,
    Sidebar = 160,
    ButtonHeight = 30,
    FieldHeight = 24,
    Radius = 4,
  },

  Workflow = {
    {Key="Inspect", Label="INSPECT", Description="Gather facts and observe state."},
    {Key="Diagnose", Label="DIAGNOSE", Description="Identify the cause and blocker."},
    {Key="Resolve", Label="RESOLVE", Description="Apply a deliberate corrective action."},
    {Key="Operate", Label="OPERATE", Description="Verify, monitor, and improve."},
  },
}
