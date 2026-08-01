# Contributing to AzerCore Ops

Thank you for your interest in AzerCore Ops.

AzerCore Ops is an operational diagnostics platform for AzerothCore. Contributions should strengthen its ability to help administrators inspect, diagnose, and resolve real server problems.

---

## Start With the Purpose

Before contributing, please read:

1. [README.md](README.md)
2. [VISION.md](VISION.md)
3. [MANIFESTO.md](MANIFESTO.md)
4. [ROADMAP.md](ROADMAP.md)
5. [ARCHITECTURE.md](ARCHITECTURE.md)

These documents define the project's purpose, direction, terminology, and boundaries.

---

## Decision Filter

Before proposing or implementing a feature, ask:

> **Does this help someone understand their server better?**

A strong proposal should also answer:

1. What operational question does this solve?
2. Who experiences the problem?
3. What information can AzerCore Ops inspect?
4. What diagnosis can it provide?
5. How does the result help the administrator?
6. Does the feature belong in AzerCore Ops?

Features without a clear operational question may be better suited to another project.

---

## Ways to Contribute

You do not need to write code to contribute.

Helpful contributions include:

- reporting reproducible bugs
- describing real Game Master workflows
- proposing focused Inspector or Diagnostic improvements
- testing module and addon changes
- checking compatibility with AzerothCore updates
- improving documentation
- correcting unclear report language
- suggesting test cases
- contributing C++, Lua, XML, SQL, or build changes

---

## Reporting Bugs

A useful bug report should include:

- AzerCore Ops version
- module commit
- addon version
- protocol version, when available
- AzerothCore branch and commit
- Playerbots or other relevant module versions
- operating system
- build type
- steps to reproduce
- expected behavior
- actual behavior
- relevant worldserver log output
- screenshots when the problem is visual

Remove passwords, private server addresses, account details, and other sensitive information before posting.

### Good Bug Report Example

```text
Title: Instance Inspector shows no lockout reason for character with active ICC save

AzerCore Ops version: 0.2.x
AzerothCore branch: Playerbots
Steps:
1. Log in with a character saved to ICC 10.
2. Open Instance Inspector.
3. Inspect ICC access.
4. Review the lockout section.

Expected:
The report identifies the active saved instance.

Actual:
The report shows an empty lockout section.
```

---

## Requesting Features

Feature requests should describe the problem before the solution.

Prefer:

> “Game Masters cannot quickly determine which condition blocks this quest.”

Instead of:

> “Add another button.”

Include:

- the operational question
- a real example
- current troubleshooting steps
- information AzerCore Ops could inspect
- the expected finding or report
- any safety or permission concerns

---

## Inspector Proposals

An Inspector proposal should define:

- its name
- its scope
- the questions it answers
- the inputs it requires
- the Diagnostics it uses
- the report sections it produces
- what it intentionally does not cover

Inspectors should remain focused.

A single large “inspect everything” screen is not the goal.

---

## Diagnostic Proposals

A Diagnostic should investigate one clear concern.

A proposal should define:

- input
- required server state
- pass or success condition
- warning condition
- blocking condition
- unsupported condition
- evidence shown to the user
- expected wording
- reuse opportunities

Diagnostics should not silently modify server state.

---

## Development Guidelines

### Keep Changes Focused

Avoid combining unrelated refactors, features, formatting changes, and fixes in one contribution.

Focused changes are easier to review and test.

### Follow Existing Structure

Use the existing module and addon organization unless the contribution intentionally improves the architecture.

Architecture changes should explain:

- the current limitation
- the proposed structure
- compatibility impact
- compatibility impact
- testing approach

### Prefer Reusable Components

Shared behavior should be implemented once when practical.

Avoid copying similar logic into multiple Inspectors.

### Apply the UI Rules Before Coding

All addon UI work must follow the binding rules in
[`docs/design-system/README.md`](docs/design-system/README.md). In particular,
button highlighting and workspace state must be event-driven and must not use
permanent `OnUpdate` polling. If a requested change conflicts with a binding UI
rule, document the conflict and obtain an explicit project decision before
implementation.

### Preserve Clear Boundaries

Keep these responsibilities separate:

- server inspection
- diagnostic evaluation
- report construction
- protocol transport
- addon presentation
- optional operations

### Do Not Hide Side Effects

A diagnostic action must not unexpectedly alter:

- character data
- account data
- quest state
- lockouts
- world state
- configuration
- database records

Any future operation that changes state must be explicit and clearly separated from inspection.

### Handle Missing Information Honestly

Do not convert missing, unsupported, or failed checks into a successful result.

Use clear outcomes such as:

- passed
- information
- warning
- blocked
- unsupported
- error

The exact model may evolve, but uncertainty must remain visible.

---

## C++ Guidelines

- Follow AzerothCore coding conventions where applicable.
- Prefer clear names over abbreviations.
- Keep includes minimal and organized.
- Avoid unnecessary core modifications.
- Validate pointers and external inputs.
- Keep diagnostic logic testable and isolated.
- Add comments for intent, not for obvious syntax.
- Do not introduce silent data changes.
- Consider compatibility with supported AzerothCore branches and modules.

---

## Lua and Addon Guidelines

- Maintain compatibility with the Wrath of the Lich King 3.3.5a client.
- Avoid retail-only APIs.
- Keep UI behavior consistent between Inspectors.
- Reuse shared controls and formatting.
- Handle missing or malformed protocol data safely.
- Avoid blocking or excessive work in frequent events.
- Keep SavedVariables backward-compatible when practical.
- Make errors visible without flooding chat.

---

## Protocol Guidelines

Protocol changes require special care.

A protocol contribution should document:

- current protocol behavior
- proposed message structure
- version impact
- compatibility behavior
- invalid input handling
- addon and module changes
- test scenarios

Do not change the module side without updating the addon side when both depend on the same protocol.

---

## Documentation Guidelines

Documentation should be:

- accurate
- direct
- specific to AzerCore Ops
- consistent with project terminology
- honest about current and planned features
- written for readers who may not know the implementation

Use these terms consistently:

- **Inspector** — a user-facing investigation tool
- **Diagnostic** — a focused reusable check
- **Report** — an organized presentation of results
- **Observation** — relevant information without a diagnosed problem
- **Finding** — a supported diagnostic conclusion
- **Recommendation** — a suggested next check or action

Avoid claiming that planned capabilities already exist.

---

## Testing

Before submitting a change:

1. build the module successfully
2. start `worldserver`
3. confirm AzerCore Ops loads without errors
4. load the addon in the 3.3.5a client
5. test the affected workflow
6. test at least one failure or unsupported path
7. review server and client output
8. verify that unrelated Inspectors still open and function

Include your test results in the pull request.

---

## Commit Messages

Use concise commit messages that explain the change.

Recommended style:

```text
type: summary
```

Examples:

```text
docs: expand AzerCore Ops architecture guide
fix: handle missing quest template safely
feat: add character reputation diagnostic
refactor: share report status formatting
test: document instance lockout scenarios
build: update module source registration
```

Common types:

- `feat`
- `fix`
- `docs`
- `refactor`
- `test`
- `build`
- `chore`

---

## Pull Requests

A pull request should include:

- a clear title
- the operational problem
- the proposed solution
- affected files or components
- compatibility considerations
- test steps
- test results
- screenshots for UI changes
- documentation updates when behavior changes

Keep pull requests small enough to review.

Large architectural changes should be discussed before implementation.

---

## Review Checklist

Before requesting review, confirm:

- [ ] The contribution solves a defined operational problem.
- [ ] The scope is focused.
- [ ] The implementation follows the project architecture.
- [ ] Results are supported by evidence.
- [ ] Missing information is handled honestly.
- [ ] Module and addon behavior remain compatible.
- [ ] The code builds.
- [ ] The affected workflow was tested.
- [ ] Documentation was updated.
- [ ] No secrets or private server information were included.

---

## Security and Privacy

Do not include:

- passwords
- database credentials
- private IP addresses
- access tokens
- private player information
- personally identifiable information
- production database dumps

Security-sensitive problems should not be published with exploit details before the maintainer has had an opportunity to review them privately through an appropriate channel.

---

## Conduct

Be respectful and constructive.

Review ideas and code without attacking the person who contributed them.

Assume good intent, explain disagreements, and focus on improving the project.

Harassment, discrimination, and abusive behavior are not acceptable.

---

## Recognition

AzerCore Ops is built through maintenance, testing, documentation, feedback, and code.

Every careful contribution helps administrators understand their servers more effectively.

Thank you for helping build AzerCore Ops.

> **Inspect. Diagnose. Resolve.**
