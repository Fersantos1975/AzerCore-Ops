# AzerCore Ops Working Backlog

## Operations scripts

- Verify the updated `ac-start` workflow during the next module update: maintenance must switch OFF successfully before either server starts.

## Movement

- Teleport catalogue: tested successfully in game.
- Test Save My Location.
- Test Emergency Return.
- Test GPS.
- Test Appear Target and Summon Target.
- Test the server-specific `game_tele` catalogue.
- Keep location sharing disabled until its authorization, verification, abuse-reporting, and safe-landing design is approved.

## Repository cleanup

- Remove duplicate legacy root source files after confirming every required file is present under the canonical `src/` and `addon/AzerCoreOps/` trees.

## Minimap and MBF

- Completed: the AzerCore Ops icon and tooltip were validated inside Minimap Button Frame 3.1.1.

## First public release

- Completed: NPC Info opens the Technical workspace without raw `.npc info` output in Blizzard chat.
- Audit remaining addon-triggered commands for internal output that should be captured or hidden.
- Completed: Courier is visibly unavailable and non-interactive.

## Information

- Completed: Overview, Capabilities, Build Information, Credits, and Resources were validated in the WoW 3.3.5a client.
- Completed: the Information workspaces remain usable at the tested window scale.
