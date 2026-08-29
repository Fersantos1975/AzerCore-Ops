# AzerCore Ops 0.7.1

AzerCore Ops 0.7.1 improves Item, Movement, and NPC workflows in the AzerothCore server module and matching World of Warcraft 3.3.5a client addon.

## Highlights

- NPC-style horizontal Item Search layout
- Immediate Movement teleport when selecting a destination
- Brighter Movement region, zone, and destination menus
- Authoritative live NPC Spawn diagnostics
- Go to NPC with Emergency Return support
- Automatic NPC target-name insertion into search
- Honest database-spawn selection without misleading client targeting

## Item Inspector

Item Search now follows the established NPC Search layout, with a full-width search field and separate Search and Clear controls.

Controlled Add Item and Remove Item operations remain in the Operations panel with Item ID and quantity fields. Input rendering uses the shared complete-border style validated on the WoW 3.3.5a client.

## Movement

Selecting a final Movement destination now teleports immediately through the existing server-authorized movement backend. A successful teleport records the previous location for Emergency Return.

Region, zone, and destination menu entries use brighter labels for improved readability while retaining the existing catalogue hierarchy.

## NPC Inspector

The Spawn view is now distinct from Location and reports authoritative live creature-spawn data:

- Spawn ID
- Database-backed or runtime/summoned source
- Home position and orientation
- Current distance from home
- Respawn and corpse delays
- Movement type
- Wander distance

Go to NPC teleports the GM near the currently selected live creature and preserves an Emergency Return point. Arrival is offset slightly behind the creature to avoid placing the player inside its model.

When a creature is targeted, its name is inserted automatically into NPC Search. Active manual edits are preserved, and the search remains deliberate until Search is pressed.

Database world-spawn rows now select only the intended database record. WoW 3.3.5 cannot reliably target an arbitrary Spawn ID when several nearby creatures share the same name, so the addon no longer claims that a row click changes the visible client target.

## Reliability

The removed same-name targeting experiment no longer invokes protected targeting actions and cannot trigger Blizzard blocked-action warnings.

NPC Spawn data continues to use structured protocol v1 records and participates in the existing request, target, and stale-response protections.

## Validation

The 0.7.1 regression pass covered:

- Item Search layout and input rendering
- Exact-ID and name-based Item workflows
- Movement destination selection and automatic teleport
- Emergency Return after destination and NPC navigation
- Go to NPC positioning
- Live NPC Spawn ID and database-source reporting
- Home position, delay, movement, and wander fields
- Database-spawn row selection without client-target changes
- Automatic target-name insertion into NPC Search
- Protection of actively edited search text
- Addon and module compatibility
- Clean committed server build
- Final BugGrabber review

## Known limitations

- WoW 3.3.5 cannot reliably target one exact Spawn ID among multiple nearby creatures with the same name. Select the database row, use Go to Spawn, and then target the nearby creature normally.
- Creature templates using gossip menu ID 0 can expose generic database conversation options that are not necessarily available on that NPC.
- Target Quest Log reports do not yet include objective-level progress.
- Some Quest scaling and status labels remain presentation improvements for a future release.
- Courier remains under construction and is not included as an active release feature.

## Versions

- Server module: 0.7.1
- Client addon: 0.7.1
- Protocol: v1
- Release tag: 0.7.1

## Installation

Install the repository as `mod-azercore-ops` inside the AzerothCore modules directory and rebuild the core.

Copy the ready-to-install `addon/AzerCoreOps` directory into the WoW client `Interface/AddOns` directory.

The addon and running server module must use matching release versions.
