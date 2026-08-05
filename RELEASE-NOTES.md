# AzerCore Ops 0.6.0

AzerCore Ops 0.6.0 is the first public release of the combined AzerothCore server module and World of Warcraft 3.3.5a addon.

## Highlights

- Safe Player Mode for permitted inspection and reporting features.
- Server-authorized administrator and Game Master operations.
- Quest, Character, Instance Access, NPC, Item, and Movement workspaces.
- Validated and attributed Movement destination catalogue.
- Structured in-addon reports that keep internal command output out of Blizzard chat where supported.
- Automatic, Player, and GM operation modes backed by the module permission handshake.
- Minimap button support, including Minimap Button Frame 3.1.1 icon and tooltip compatibility.
- Platform Information pages for compatibility, capabilities, build details, credits, and resources.

## Installation

Install the repository as `mod-azercore-ops` in the AzerothCore modules directory and rebuild the core. Copy `addon/AzerCoreOps` into the WoW client's `Interface/AddOns` directory. The addon and module must use matching release revisions.

## Not included

Courier is visible as an under-construction preview but remains unavailable and non-interactive. Location sharing also remains disabled pending its authorization, verification, abuse-reporting, and safe-landing design.

## Verification

The 0.6.0 release candidate passed repository validation and in-game regression testing. The final server module must be rebuilt after installing this release so its reported version and release channel become `0.6.0` and `stable`.
