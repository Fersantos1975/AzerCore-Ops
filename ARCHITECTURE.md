# AzerCore Ops Architecture

> **Inspectors ask questions. Diagnostics find answers. Reports communicate the results.**

This document describes the intended architecture of AzerCore Ops.

It is a conceptual blueprint. Some parts already exist, while others represent the direction in which the module and addon should evolve.

---

## Purpose

AzerCore Ops is an operational diagnostics platform for AzerothCore.

Its architecture should make it possible to add new Inspectors without duplicating common logic or creating a different user experience for every feature.

The design separates six concerns:

1. user-facing inspection
2. diagnostic evaluation
3. report construction
4. protocol transport
5. addon presentation
6. compatibility and platform services

---

## High-Level Model

```text
Administrator
     │
     ▼
AzerCore Ops Addon
     │
     │ request / response protocol
     ▼
AzerCore Ops Module
     │
     ├── Inspectors
     │     └── coordinate investigations
     │
     ├── Diagnostics
     │     └── evaluate focused conditions
     │
     ├── Reports
     │     └── organize findings
     │
     ├── Protocol
     │     └── transport structured results
     │
     └── Platform Services
           ├── versioning
           ├── compatibility
           ├── formatting
           └── future export support
```

---

## Architectural Vocabulary

### Inspector

A user-facing investigation tool.

An Inspector accepts a subject or context, runs relevant Diagnostics, and produces a Report.

Examples:

- Quest Inspector
- Instance Inspector
- Character Inspector
- Reputation Inspector
- Spell Inspector

An Inspector should answer a recognizable set of operational questions.

### Diagnostic

A focused and reusable check.

A Diagnostic evaluates one concern and returns a structured result supported by evidence.

Examples:

- quest eligibility
- instance lockout
- reputation threshold
- class or race restriction
- prerequisite spell
- group eligibility

Diagnostics should not control the user interface directly.

### Report

An organized collection of diagnostic results.

A Report provides context and separates observations, successful checks, warnings, findings, blockers, unsupported checks, and errors.

### Observation

Relevant information that does not itself represent a problem.

Example:

> Character level: 80

### Finding

A conclusion supported by inspected evidence.

Example:

> The character does not meet the required reputation rank.

### Recommendation

A suggested next check or action.

Recommendations should be derived from findings and should not be presented as guaranteed fixes.

### Operation

A deliberate state-changing action.

Operations are not the primary focus of AzerCore Ops and must remain clearly separated from Diagnostics.

Examples might include reset, assign, or repair actions if they are ever implemented.

---

## Core Architecture

```text
AzerCore Ops
├── Inspectors
├── Diagnostics
├── Reports
├── Protocol
├── Addon UI
├── Export
└── Platform Services
```

Each layer has a distinct responsibility.

---

## Inspectors

Inspectors coordinate an investigation.

An Inspector should:

1. validate its input
2. load the required context
3. select relevant Diagnostics
4. execute those Diagnostics
5. assemble a Report
6. return the result through the protocol
7. avoid changing server state unless an explicit Operation is requested

### Inspector Example

```text
Instance Inspector
├── Instance Metadata Diagnostic
├── Character Eligibility Diagnostic
├── Difficulty Diagnostic
├── Lockout Diagnostic
├── Group Diagnostic
└── Requirement Diagnostic
```

### Inspector Responsibilities

An Inspector owns:

- investigation scope
- subject validation
- diagnostic selection
- execution order
- report context
- Inspector-specific summary

An Inspector does not own:

- addon window layout
- protocol parsing details
- unrelated diagnostic logic
- hidden state-changing behavior

### Inspector Input

Potential input types include:

- character GUID
- account ID
- quest ID
- map or instance ID
- creature entry
- spell ID
- item ID
- group or raid context

Inputs must be validated before use.

---

## Diagnostics

Diagnostics are the reusable analytical units of AzerCore Ops.

A Diagnostic should answer one focused question.

### Diagnostic Example

```text
Quest Eligibility Diagnostic

Question:
Can this character accept this quest?

Evidence:
- character level
- class
- race
- prerequisite quests
- reputation
- existing quest state
- repeatability
- daily or weekly state

Possible outcomes:
- passed
- blocked
- warning
- unsupported
- error
```

### Diagnostic Properties

The shared Diagnostic model should eventually provide:

- stable identifier
- display name
- summary
- outcome
- severity
- evidence
- details
- optional recommendation
- machine-readable code
- human-readable message

### Suggested Outcomes

The exact implementation may evolve, but AzerCore Ops needs consistent semantic outcomes.

| Outcome | Meaning |
|---|---|
| Pass | The inspected condition is satisfied |
| Information | Relevant context without a problem |
| Warning | Something deserves attention but may not block progress |
| Blocked | A confirmed condition prevents the expected result |
| Unsupported | AzerCore Ops cannot evaluate this condition |
| Error | The Diagnostic could not complete correctly |

### Diagnostic Rules

A Diagnostic should:

- inspect only the information it needs
- produce deterministic results when given the same state
- expose evidence
- avoid user-interface code
- avoid transport-specific formatting
- avoid silent state changes
- handle missing data honestly
- be reusable when the concern appears in multiple Inspectors

---

## Reports

Reports communicate findings.

A Report should provide enough context that the result remains meaningful after it leaves the immediate Inspector screen.

### Suggested Structure

```text
Report
├── Metadata
│   ├── Inspector
│   ├── Subject
│   ├── AzerCore Ops version
│   └── Timestamp or context
├── Summary
├── Observations
├── Passed Checks
├── Warnings
├── Findings
├── Blockers
├── Unsupported Checks
├── Errors
└── Recommendations
```

Not every Report needs every section.

Empty sections should normally be omitted from the user interface.

### Report Principles

Reports should be:

- structured
- readable
- stable enough for export
- honest about incomplete results
- independent of one specific UI layout
- detailed enough to support troubleshooting

### Report Summary

A summary should answer:

- What was inspected?
- Did AzerCore Ops identify a blocker?
- Were any checks incomplete?
- What is the most important finding?

---

## Protocol

The protocol connects the server module and the game addon.

It must account for the limitations of the World of Warcraft 3.3.5a addon environment.

### Protocol Responsibilities

- request identification
- response identification
- protocol versioning
- message validation
- chunking when required
- ordering
- error responses
- compatibility checks
- safe parsing
- clear handling of unsupported messages

### Versioning

The project should distinguish:

- module version
- addon version
- protocol version
- AzerothCore version
- optional integration versions

The module and addon may evolve at different speeds, so protocol compatibility must be explicit.

### Protocol Safety

The addon should not trust malformed server messages.

The module should not trust malformed addon requests.

Both sides should:

- validate message type
- validate required fields
- limit input size
- handle unknown versions
- reject unsupported operations safely
- avoid leaking sensitive server information

---

## Addon UI

The addon presents AzerCore Ops to the administrator.

It should not contain authoritative server diagnostic logic when that logic depends on server state.

### Addon Responsibilities

- navigation
- input controls
- request submission
- response parsing
- report presentation
- filtering
- minimization and window state
- settings
- copy or export presentation
- clear loading and error states

### UI Consistency

All Inspectors should share:

- naming conventions
- status presentation
- report section behavior
- empty-state wording
- error presentation
- navigation patterns
- common controls

### Client Compatibility

The addon targets the Wrath of the Lich King 3.3.5a client.

It should avoid APIs introduced in later client versions.

---

## Export

Export is a presentation and transport concern built on top of Reports.

The Report model should become stable before multiple export formats are added.

Potential export targets include:

- copyable plain text
- SavedVariables
- addon-to-addon structured data
- future external formats

Export should not expose sensitive information by default.

---

## Platform Services

Shared services support all AzerCore Ops components.

### Version Service

Provides:

- module version
- addon version
- protocol version
- build or commit information when available
- compatibility status

### Formatting Service

Provides consistent:

- labels
- status names
- identifiers
- field formatting
- empty values
- error messages

### Registry

A future registry may allow Inspectors and Diagnostics to register with stable identifiers.

Benefits include:

- discovery
- routing
- testing
- protocol stability
- reduced coupling

### Permissions

AzerCore Ops capabilities should respect AzerothCore security levels and command permissions.

Inspection access should not automatically imply permission to perform state-changing Operations.

### Logging

Server logging should help diagnose AzerCore Ops itself without flooding normal logs.

Useful log areas include:

- startup and version information
- protocol validation failures
- Inspector execution errors
- unsupported requests
- optional debug-level Diagnostic traces

---

## Module and Addon Boundary

The server module owns authoritative evaluation of server state.

The addon owns presentation and interaction.

```text
Server Module                         Addon
-------------                         -----
Character and world state             Windows and controls
AzerothCore rule evaluation           Navigation
Diagnostic execution                  Display formatting
Permission checks                     User input
Report construction                   Filtering and copying
Protocol response generation          Protocol request generation
```

The addon may perform harmless display calculations, but it should not guess server rules that can be evaluated authoritatively by the module.

---

## Data Flow

A typical request should follow this path:

```text
1. Administrator selects an Inspector
2. Addon validates local input
3. Addon sends a versioned request
4. Module validates permission and input
5. Inspector loads the subject context
6. Inspector runs Diagnostics
7. Diagnostics produce structured results
8. Inspector assembles a Report
9. Protocol serializes the Report
10. Addon validates and parses the response
11. Addon displays the Report
```

Errors should be returned at the layer where they occur.

---

## Error Handling

AzerCore Ops should distinguish between different failure types.

### User Input Error

Examples:

- invalid quest ID
- unknown character name
- missing required field

### Permission Error

The requester lacks the required security level or command permission.

### Unsupported Check

AzerCore Ops does not currently support the requested rule or context.

### Missing Server Data

Expected records or templates are unavailable.

### Protocol Error

The request or response is malformed or incompatible.

### Internal Error

AzerCore Ops could not complete due to an unexpected condition.

These should not all be shown as the same generic failure.

---

## Operations and State Changes

AzerCore Ops is primarily diagnostic.

Any state-changing capability must be treated as an explicit Operation.

An Operation should require:

- clear user intent
- permission validation
- confirmation where appropriate
- visible scope
- success or failure reporting
- logging
- no hidden execution during inspection

Diagnostics must never change state merely by being viewed or executed.

---

## Extending AzerCore Ops

### Adding an Inspector

A contributor should:

1. define the operational questions
2. define the subject and input
3. identify reusable Diagnostics
4. add missing Diagnostics
5. define the Report structure
6. implement module routing
7. implement addon navigation and presentation
8. add protocol handling
9. document permissions
10. test success, blocked, unsupported, and error paths

### Adding a Diagnostic

A contributor should:

1. define one focused question
2. identify required evidence
3. define outcomes
4. implement evaluation without UI dependencies
5. expose supporting details
6. add error and unsupported handling
7. reuse the Diagnostic where applicable
8. document test cases

### Adding a Report Field

A contributor should consider:

- whether the field belongs in metadata, evidence, or presentation
- protocol compatibility
- addon behavior with older responses
- export implications
- privacy and security
- empty-value behavior

---

## Testing Strategy

AzerCore Ops should be tested at several levels.

### Diagnostic Testing

Verify:

- passing state
- blocking state
- missing data
- unsupported conditions
- invalid input
- boundary values

### Inspector Testing

Verify:

- correct Diagnostic selection
- subject validation
- report ordering
- summary accuracy
- partial failure behavior

### Protocol Testing

Verify:

- compatible versions
- incompatible versions
- malformed messages
- missing chunks
- unexpected ordering
- oversized input

### Addon Testing

Verify:

- loading
- navigation
- minimization
- settings
- empty reports
- long reports
- errors
- copy or export behavior

### Compatibility Testing

Record:

- AzerothCore branch and commit
- module versions
- client version
- build configuration
- operating system

---

## Repository Direction

The repository should remain understandable to both administrators and contributors.

A possible long-term structure is:

```text
mod-azercore-ops/
├── README.md
├── VISION.md
├── MANIFESTO.md
├── ROADMAP.md
├── CONTRIBUTING.md
├── ARCHITECTURE.md
├── CHANGELOG.md
├── LICENSE
├── module/
│   └── ...
├── addon/
│   └── AzerCore Ops/
├── docs/
│   └── ...
└── images/
    └── ...
```

The exact source layout should reflect the real implementation and should not be reorganized only for appearance.

---

## Architectural Boundaries

AzerCore Ops should avoid:

- Inspector-specific copies of shared checks
- server rules duplicated in addon Lua
- UI code inside Diagnostics
- protocol formatting inside domain logic
- hidden state changes during inspection
- reports that hide missing or unsupported checks
- dependencies on unnecessary core modifications
- feature growth without an operational question

---

## Architecture Decision Filter

Before changing the architecture, ask:

1. Does this reduce duplication?
2. Does this improve correctness?
3. Does this make results more consistent?
4. Does this make the module and addon boundary clearer?
5. Does this make future Inspectors easier to add?
6. Can the change be tested?
7. Is the implementation cost justified?

---

## Guiding Principle

> **Inspectors ask questions. Diagnostics find answers. Reports communicate the results.**

That principle should remain visible in the code, protocol, addon, and documentation as AzerCore Ops grows.
