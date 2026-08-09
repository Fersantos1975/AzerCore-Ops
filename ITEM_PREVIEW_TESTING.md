# Item preview and requirements test

This test build adds server-backed metadata to the Item Inspector.

## What changed

- Uncollected mount and companion items can use their server-resolved display or creature ID in the 3D preview.
- Requirements now show faction, playable races, playable classes, and whether the current character is permitted.
- Existing collected-companion and wearable-item previews remain as fallbacks.

## Install and test

1. Replace the server module with this source and rebuild/install AzerothCore.
2. Replace the Windows addon folder with `addon/AzerCoreOps`.
3. Restart the server and reload or restart the WoW client.
4. Inspect item IDs `44843` (Blue Dragonhawk Mount), `44842` (Red Dragonhawk Mount), `46814` (Sunreaver Dragonhawk), and `29957` (Silver Dragonhawk Hatchling).
5. Confirm Preview shows a model and Requirements shows faction/race/class access.

The addon and rebuilt module must be tested together because the new `ITEM_ACCESS` and `ITEM_PREVIEW` records are supplied by the server.
