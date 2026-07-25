# Coding standards

## Lua

- Keep WoW 3.3.5a compatibility.
- Centralize colors and spacing in `DesignSystem.lua`.
- Keep server command strings in the command table.
- Validate inputs before sending commands.
- Confirm world-changing actions.
- Remove obsolete compatibility code after its supported window ends and document any breaking change.

## C++

- Inspectors collect facts and do not mutate world state.
- Diagnostics return structured reasons and recommendations.
- Protocol fields must remain versioned and parseable.
- Build metadata must be included in compatibility reports.
- Avoid branch-specific APIs without a compatibility wrapper.
