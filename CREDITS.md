# Credits and Sources

AzerCore Ops is created and maintained by Fernando Santos with the help of
open-source projects, their contributors, testers, and AI-assisted development.

## Core projects

- **AzerothCore** — server framework and data structures used by the module.
- **mod-playerbots** — optional Playerbot integration and build context.

## Movement destination catalogue

The built-in Movement destination catalogue is adapted from
[`TeleportTable.lua`](https://github.com/superstyro/AzerothAdmin) in
**AzerothAdmin**, which is itself derived from TrinityAdmin/MangAdmin.

- Source project: AzerothAdmin
- Source repository: <https://github.com/superstyro/AzerothAdmin>
- Licence: GPL-3.0-or-later
- Use in AzerCore Ops: destination names, grouping, map identifiers, and
  coordinates were converted into a structured Region → Zone → Destination
  catalogue.
- Validation: malformed, all-zero, duplicated, non-finite, or implausible
  entries are rejected by `tools/import-azerothadmin-teleports.py`. The current
  import report is stored in `docs/AZEROTHADMIN-TELEPORT-VALIDATION.md`.

We gratefully acknowledge the AzerothAdmin, TrinityAdmin, MangAdmin,
AzerothCore, and wider open-source World of Warcraft server communities.

## Development assistance

- OpenAI ChatGPT — planning, review, documentation, and AI-assisted development.

All third-party material remains credited to its original authors and is used
under its applicable licence. AzerCore Ops is distributed under GPLv3.
