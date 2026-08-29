# AzerCore Ops Platform

**Operational intelligence for AzerothCore.**  
**Understand. Diagnose. Resolve.**

AzerCore Ops Platform combines an AzerothCore C++ module with a World of Warcraft: Wrath of the Lich King 3.3.5a addon. It provides server-authoritative operations for administrators and Game Masters alongside a safe Player Mode for regular players. Player Mode exposes only permitted gameplay, inspection, and reporting features and cannot grant administrative authority.

> **Current release:** `0.7.1` — improves Item search layout, streamlines Movement navigation, adds authoritative NPC spawn diagnostics and Go to NPC navigation, and integrates live NPC targets with search.

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

## Screenshots

| Operations Center | Character Inspector |
| --- | --- |
| ![AzerCore Ops Operations Center](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/dashboard.png) | ![Character equipment inspection](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/character-equipment.png) |

| Quest Inspector | Instance Access |
| --- | --- |
| ![Target quest inspection](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/quest-inspector.png) | ![Group instance-access audit](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/instance-access.png) |

| NPC Inspector | Movement Control |
| --- | --- |
| ![NPC inspection workspace](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/npc-inspector.png) | ![Movement destination catalogue](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/movement-control.png) |

| Courier status | Platform Information |
| --- | --- |
| ![Courier under construction](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/courier-under-construction.png) | ![Platform compatibility information](https://raw.githubusercontent.com/Fersantos1975/AzerCore-Ops/main/docs/images/screenshots/platform-information.png) |

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

- [Architecture](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/ARCHITECTURE.md)
- [Vision](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/VISION.md)
- [Manifesto](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/MANIFESTO.md)
- [Philosophy](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/PHILOSOPHY.md)
- [Roadmap](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/ROADMAP.md)
- [Contributing](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/CONTRIBUTING.md)
- [Design system](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/docs/design-system/README.md)

## Support policy

This project tracks active AzerothCore development. Compatibility can vary by core branch and module combination, so include relevant core, module, and playerbots revisions when reporting problems.

## License

GNU General Public License v3.0. See [LICENSE](https://github.com/Fersantos1975/AzerCore-Ops/blob/main/LICENSE).
