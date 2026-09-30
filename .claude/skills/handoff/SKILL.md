---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it in the repo's docs vault as `docs/obsidian/07 - Development/Handoffs/Handoff - <YYYY-MM-DD> <topic>.md` (create the folder if needed), so it's version-controlled next to the plans.

Structure it as: what the goal is, what is done (with verification status: built, tests run, not run), what is left in order, open decisions, and anything uncommitted or unapplied (e.g. EF migrations not yet applied, running dev servers).

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
