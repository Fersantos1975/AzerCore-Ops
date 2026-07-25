# The AzerCore Ops Manifesto

> **Inspect. Diagnose. Resolve.**

Administrators rarely struggle because they lack commands.

They struggle because they lack answers.

AzerCore Ops exists to help find those answers.

---

## We Build for Understanding

A player cannot enter an instance.

A quest does not appear.

A spell cannot be learned.

An achievement does not complete.

An NPC does not behave as expected.

The visible problem is usually simple.

The reason behind it may be hidden across requirements, lockouts, database records, character state, group state, configuration, and source-code rules.

AzerCore Ops brings those pieces together.

---

## We Believe Questions Come Before Commands

Commands can change the server.

Diagnostics explain the server.

Before changing anything, an administrator should be able to ask:

- What is happening?
- What condition failed?
- What requirement is missing?
- What evidence supports this result?
- What should be checked next?

AzerCore Ops should make those questions easier to answer.

---

## We Inspect

We collect the facts that matter.

We do not bury users in every available value.

We select information because it helps answer an operational question.

Inspection is not data dumping.

Inspection is purposeful observation.

---

## We Diagnose

We connect facts to rules and conditions.

We explain why a check passed, failed, or could not be completed.

We distinguish between evidence and assumption.

We do not call something a finding unless the available information supports it.

---

## We Resolve

Resolution begins with understanding.

AzerCore Ops should provide actionable information, but it should not pretend that every problem has a safe automatic fix.

Sometimes the correct result is:

- a missing requirement
- an active lockout
- a configuration issue
- inconsistent data
- an unsupported scenario
- a need for deeper investigation

A trustworthy explanation is more valuable than a careless action.

---

## We Prefer Clarity Over Complexity

The internal implementation may be complex.

The result shown to the administrator should not be.

AzerCore Ops should use consistent language and clear status levels.

Reports should separate:

- information
- successful checks
- warnings
- findings
- blockers
- errors

A user should not need to understand the source code to understand a report.

---

## We Prefer Evidence Over Guesswork

AzerCore Ops should inspect real server state and known rules.

When evidence is incomplete, the platform should say so.

When a check is unsupported, the platform should say so.

When AzerCore Ops does not know, it should not invent an answer.

Honesty is part of correctness.

---

## We Build Reusable Diagnostics

A requirement check should behave consistently wherever it appears.

A lockout should not be interpreted one way in the Instance Inspector and another way in the Character Inspector.

Shared Diagnostics create shared truth.

Consistency is not only a design preference.

It is a requirement for trust.

---

## We Respect the Server

AzerCore Ops should integrate cleanly with AzerothCore.

It should avoid unnecessary core modifications.

It should not change character or world data merely to make an inspection succeed.

It should not hide side effects behind diagnostic actions.

Investigation and modification should remain clearly separated.

---

## We Respect Existing Tools

AzerCore Ops is not built to replace every Game Master addon or command.

Existing tools are valuable.

AzerCore Ops has a specific purpose:

> To help administrators understand why something is happening.

It should complement command systems, logs, database tools, debuggers, and other administration utilities.

---

## We Build for Real Problems

Every feature should begin with an operational question.

Not:

> “What can we add?”

But:

> “What does an administrator need to understand?”

A feature earns its place by solving a real diagnostic problem.

---

## We Value Quality Over Quantity

A small Inspector that produces reliable answers is more valuable than a large Inspector filled with incomplete checks.

A clear report is more valuable than a long report.

A tested Diagnostic is more valuable than several speculative ones.

AzerCore Ops should grow carefully.

---

## We Welcome Contributors

Contributions are not limited to code.

Administrators who provide real scenarios help shape better Diagnostics.

Testers who reproduce problems improve reliability.

Writers who improve explanations make findings easier to understand.

Developers who keep the architecture consistent make future work possible.

Every contribution should strengthen the platform's ability to inspect, diagnose, or resolve.

---

## Our Standard

AzerCore Ops should be:

- useful
- honest
- consistent
- understandable
- maintainable
- focused
- respectful of the AzerothCore ecosystem

When those values conflict with adding another feature, the values come first.

---

## Our Question

Before every feature, every report, and every line of code, we ask:

> **Does this help someone understand their server better?**

If it does, we continue.

If it does not, we reconsider.

---

## Our Commitment

We will inspect before assuming.

We will diagnose before acting.

We will explain what the evidence supports.

We will resolve what can be resolved safely.

We will not confuse complexity with value.

We will not confuse activity with progress.

We will build AzerCore Ops around trustworthy answers.

---

> **Inspect. Diagnose. Resolve.**
