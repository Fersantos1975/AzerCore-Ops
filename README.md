# AzerCore Ops Platform

**Operational intelligence for AzerothCore.**  
**Understand. Diagnose. Resolve.**

AzerCore Ops Platform combines an AzerothCore C++ module with a World of Warcraft: Wrath of the Lich King 3.3.5a addon. Its flagship workspace, **Quest Intelligence**, provides quest inspection, contextual analysis, group auditing, history, diagnostics, and report export for administrators and Game Masters.

> **Development status:** `0.5.6-alpha2-movement-catalog`. The source requires compilation and in-game validation against a supported AzerothCore checkout before production use.

## Features

- Quest search by ID or title
- Quest details, eligibility, requirements, rewards, NPCs, and chain analysis
- SELF and TARGET inspection contexts
- Complete active Quest Log inspection for a selected online player
- Group quest auditing
- Search history and activity logging
- Report copy and export workflows
- Structured personal and target bind inventories with exact Instance IDs
- Group access readiness, bind-ID comparison, encounter progress, and boss names
- Confirmed multi-select bind removal with per-bind results and post-operation verification
- Role-aware Automatic, Player, and GM operating modes backed by server permissions
- Character overview, equipment, professions, recorded raid-achievement evidence, and restricted technical diagnostics
- Privacy-safe Character reports plus guarded GM target operations
- Module, core, and playerbots build information
- Shared addon design, search, reporting, and platform frameworks
- Validated Movement catalogue with Region, Zone/Instance, and Destination selection
- Personal saved locations, server-specific `game_tele` destinations, and Emergency Return

## Repository layout

```text
addon/AzerCoreOps/   WoW 3.3.5a addon
src/                 AzerothCore module source
docs/                Architecture and design documentation
images/              Project artwork and repository assets
tools/               Validation utilities
```

## Requirements

- AzerothCore configured to build external modules
- A compatible C++ toolchain and CMake version for the selected AzerothCore branch
- World of Warcraft 3.3.5a client for the addon
- Game Master permissions for administrative commands

Playerbots is optional. When installed under the standard AzerothCore modules directory, its revision is included in the build-information response.

## Install the module

Clone the repository into the AzerothCore modules directory:

```bash
cd <azerothcore-root>/modules
git clone https://github.com/Fersantos1975/AzerCore-Ops.git mod-azercore-ops
```

Configure and build AzerothCore using your normal build process. Example:

```bash
cd <azerothcore-root>
cmake -S . -B <build-directory> \
  -DCMAKE_INSTALL_PREFIX=<install-prefix> \
  -DMODULES=static
cmake --build <build-directory> --target install --parallel
```

Replace the placeholders with paths appropriate to your environment. AzerothCore also supports other module and build configurations; follow the core documentation for your platform.

## Install the addon

Copy the addon directory:

```text
addon/AzerCoreOps
```

into the WoW client:

```text
<wow-client>/Interface/AddOns/AzerCoreOps
```

Restart the client or reload the UI after replacing addon files.

## Basic use

Open AzerCore Ops from its minimap button or addon interface. The module command namespace is:

```text
.azercoreops
```

Available operations depend on the installed source revision and the permissions of the active account.

## Verification

Before treating a build as production-ready:

1. Run `tools/azercoreops-check` from the repository root.
2. Reconfigure and compile AzerothCore.
3. Install the resulting server binaries.
4. Copy the matching addon revision to the client.
5. Confirm the module version and capabilities in game.
6. Run the smoke-test checklist in `RELEASE-CHECKLIST.md`.

## Documentation

- [Architecture](ARCHITECTURE.md)
- [Vision](VISION.md)
- [Manifesto](MANIFESTO.md)
- [Philosophy](PHILOSOPHY.md)
- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)
- [Design system](docs/design-system/README.md)

## Support policy

This project tracks active AzerothCore development. Compatibility can vary by core branch and module combination, so include relevant core, module, and playerbots revisions when reporting problems.

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
