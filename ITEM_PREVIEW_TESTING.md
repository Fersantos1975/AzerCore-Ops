# Item Inspector preview and requirements regression

This document records the 0.6.2 Item Inspector preview, requirements, source, and refresh validation.

## Preview behavior

Mount and companion preview metadata is resolved from AzerothCore's loaded creature data.

For WoW 3.3.5 clients that have not cached the referenced creature entry, the server primes the client with the standard `SMSG_CREATURE_QUERY_RESPONSE` before sending the AzerCore Ops Item Preview record.

The addon then uses `DressUpModel:SetCreature()` when available.

This preserves the display-specific textures that are lost when a raw model path is loaded directly.

Production code does not hard-code the test item, creature, display, or model-path values.

## Requirements behavior

Authoritative Item requirements include:

- Faction and playable-race restrictions
- Class restrictions
- Character level
- Skill and skill rank
- Required spell
- Reputation rank
- Unique-item ownership limits

Legacy `RequiredHonorRank` is displayed as informational metadata because AzerothCore 3.3.5 does not enforce that field through `Player::CanUseItem`.

## Source behavior

Item Sources include:

- Vendor sources
- Creature drops
- Equal-chance creature loot groups with explicit raw-Chance context
- GameObject direct loot
- GameObject one-level reference loot
- Quest rewards

Long source details use wrapped, dynamically sized rows in the addon.

## Regression items

Validated examples during the 0.6.2 pass included:

- `44602` — standard item-stat inspection
- `40727` — profession/skill requirements
- `44180` — reputation requirements
- `39200` — unique ownership and automatic add/remove refresh
- `37149` — Armor stat naming and equal-chance creature source
- `49044` — GameObject source and fully textured server-backed mount preview
- `16438` — legacy PvP honor-rank presentation

## Final preview validation

For item `49044`, the server resolved the mount spell to a creature entry and its corresponding display metadata.

The preview initially failed on an uncached client creature entry even though `DressUpModel:SetCreature()` worked for a client-known mount.

After the server sent the normal creature-query response before the Item Preview record, the same preview rendered the complete textured Swift Alliance Steed.

The final production implementation therefore uses creature-cache priming rather than a raw `SetModel()` path fallback.

## Release validation

The addon and rebuilt module must be tested together because Item Access, Item Preview, Item Source, and mutation-refresh behavior depend on matching client/server revisions.

The final 0.6.2 regression pass completed without AzerCore Ops Lua runtime errors.
