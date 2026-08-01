# AzerCore Ops Design System

The design system is the shared visual and interaction language for the addon,
documentation, repository graphics, reports, and future tools.

Core workflow:

> **Inspect → Diagnose → Resolve → Operate**

The original project motto remains:

> **Inspect. Diagnose. Resolve.**

Operate extends the workflow by verifying the outcome, monitoring the realm, and
improving future operations.

## Binding UI Implementation Rules

These rules must be checked before coding any addon UI change:

1. **Event-driven state:** persistent highlights and other UI state changes must
   react to clicks, selections, protocol results, or explicit events. Do not use
   permanent `OnUpdate` polling for UI state.
2. **Centralized ownership:** shared state and reusable paint helpers should own
   active, hover, selected, disabled, and default presentation. The planned
   centralized UI State Manager is a `0.6.0` architecture objective.
3. **One active choice:** each interaction group may show only its actual active
   navigation item, workspace, filter, or selection as active.
4. **Consistent action placement:** report/output actions such as Copy, Share,
   and Export belong in the bottom action bar. Operational controls remain near
   the context they affect.
5. **Reuse before duplication:** extend shared helpers and frameworks whenever
   practical instead of copying equivalent behavior into each workspace.
6. **Performance review:** a proposed UI change must be checked for persistent
   handlers, repeated work, unnecessary frame creation, and avoidable redraws.
7. **Conflict escalation:** when a requested implementation conflicts with these
   rules, stop before coding, explain the conflict, and agree on an explicit
   exception or alternative with the project owner.
