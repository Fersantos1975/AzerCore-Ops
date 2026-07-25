# AzerCore Ops Vision

> **Inspect. Diagnose. Resolve.**

AzerCore Ops exists to help AzerothCore administrators understand their server.

This document defines where the project is going, what it aims to become, and the principles that should guide its growth.

---

## Mission

AzerCore Ops helps administrators investigate gameplay and server problems by turning scattered technical information into clear operational answers.

The project should reduce the time spent searching through databases, source code, logs, and unrelated commands. It should help a Game Master move from:

> “Something is wrong.”

to:

> “I understand why it is happening and what I should check next.”

---

## Vision

AzerCore Ops aims to become the operational diagnostics platform for AzerothCore.

The long-term goal is a consistent collection of Inspectors, Diagnostics, Reports, and supporting tools that can explain the state of a running realm.

AzerCore Ops should help administrators answer questions such as:

- Why can a player not enter an instance?
- Why is a quest unavailable?
- Why can a character not learn a spell?
- Why has an achievement not completed?
- Why is an NPC or event not behaving as expected?
- Which requirement, condition, lockout, or dependency is blocking progress?

AzerCore Ops should not require administrators to guess which database table, command, or source file contains the answer.

---

## The AzerCore Ops Experience

A AzerCore Ops investigation should follow a predictable path.

### 1. Inspect

Collect the relevant facts from the server.

### 2. Diagnose

Evaluate requirements, conditions, dependencies, and current state.

### 3. Resolve

Present findings clearly enough that an administrator can decide what to do next.

This experience should remain consistent across every Inspector.

---

## Product Direction

AzerCore Ops is intended to grow in four connected areas.

### Inspectors

Inspectors are the main tools used by administrators.

Examples include:

- Quest Inspector
- Instance Inspector
- Character Inspector
- Reputation Inspector
- Achievement Inspector
- Spell Inspector
- NPC Inspector
- Item Inspector

Each Inspector should answer a defined set of operational questions.

### Diagnostics

Diagnostics are reusable checks that explain a specific condition.

Examples include:

- eligibility checks
- lockout checks
- quest requirement checks
- reputation requirement checks
- spell requirement checks
- group and raid checks

A Diagnostic should be reusable by more than one Inspector whenever practical.

### Reports

Reports organize diagnostic results into a clear structure.

A report may contain:

- observations
- passed checks
- warnings
- findings
- blocking conditions
- supporting details
- recommended next checks

Reports should communicate results without hiding the evidence behind them.

### Platform Services

Shared platform services should reduce duplication between Inspectors.

Examples include:

- version and compatibility information
- shared protocol handling
- report formatting
- export support
- filtering and search
- consistent error handling
- common user-interface components

---

## Design Principles

### Explain Why

AzerCore Ops should explain the reason behind a result whenever the server exposes enough information to determine it.

A simple pass or fail is not enough when the underlying condition can be identified.

### Investigate Before Acting

AzerCore Ops is primarily a diagnostic platform.

It should help administrators understand a problem before offering or performing any corrective operation.

### Prefer Evidence Over Assumptions

Findings should be based on server state, data, requirements, and reproducible checks.

When AzerCore Ops cannot determine a cause, it should say so clearly.

### Keep Inspectors Consistent

Inspectors should share terminology, status levels, presentation rules, and navigation patterns.

A user who understands one Inspector should quickly understand another.

### Reuse Diagnostics

Common checks should not be rewritten separately for each Inspector.

Reusable Diagnostics improve consistency, testing, and maintainability.

### Respect AzerothCore

AzerCore Ops should integrate cleanly with AzerothCore conventions and avoid unnecessary changes to the core.

Compatibility and maintainability are more important than clever implementation.

### Build for Real Operational Problems

Every major feature should answer a real question asked by a server administrator.

The project should not add features merely because they are technically possible.

---

## What AzerCore Ops Is Not

AzerCore Ops is not intended to become:

- a replacement for all Game Master commands
- a general-purpose server administration panel
- a database editor
- an automated repair tool that changes data without explanation
- a collection of unrelated utilities
- a substitute for logs, debugging, or source-code investigation in every situation

AzerCore Ops should complement existing tools by making investigations faster and clearer.

---

## Long-Term Goals

### A Unified Inspector Framework

All Inspectors should share a common foundation for registration, execution, results, and presentation.

### A Shared Diagnostic Framework

Diagnostics should expose consistent inputs, outcomes, evidence, and messages.

### Structured Reports

AzerCore Ops should produce reports that are easy to read in-game and suitable for future export.

### Reliable Compatibility Information

AzerCore Ops should make its module, addon, protocol, AzerothCore, and optional integration versions visible and easy to verify.

### Extensible Development

Adding a new Inspector should become easier as the framework matures.

Future contributors should be able to understand where a new feature belongs and how it should behave.

### Honest Results

AzerCore Ops should distinguish clearly between:

- confirmed findings
- warnings
- incomplete information
- unsupported checks
- internal errors

The platform should never present speculation as fact.

---

## Community Direction

AzerCore Ops should be welcoming to administrators, testers, documenters, addon developers, and C++ contributors.

Not every useful contribution requires programming.

Valuable contributions include:

- reproducible bug reports
- real-world diagnostic scenarios
- wording improvements
- translations
- documentation
- test results
- compatibility reports
- feature proposals grounded in actual server administration

---

## Decision Filter

Before adding a feature, ask:

> **Does this help someone understand their server better?**

Then ask:

1. What operational question does it answer?
2. What evidence will it inspect?
3. What diagnosis can it provide?
4. How will the result help the administrator?
5. Does the capability belong in AzerCore Ops or in another tool?

A feature that cannot answer those questions may not belong in the project.

---

## Success

AzerCore Ops will be successful when administrators can use it to replace uncertainty with understanding.

The goal is not to produce the largest number of features.

The goal is to produce trustworthy answers.

---

## North Star

> **AzerCore Ops exists to help administrators understand their server.**
