---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published as LL-NNN tickets in the Backlog of docs/board.md (the board /work-next-ticket reads).
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it.

**Life-Level tracker:** tickets live in `docs/board.md` (read its `## Format` section first). There is no `/setup-matt-pocock-skills` step here; ignore references to other trackers or triage labels. Plans the tickets come from usually live in `docs/obsidian/07 - Development/Plan - <Name>.md`.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket; green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Publish the tickets to docs/board.md

Publish the approved tickets as new entries under **`## 📋 Backlog`** in `docs/board.md`, in dependency order (blockers first):

- Number them from the highest existing `LL-NNN` in the board + 1.
- Use the board's exact ticket format (see its `## Format` section). Fill **Layer** (`backend`, `mobile`, `game-engine`, comma-separated when a slice crosses layers, which most tracer bullets do) and **Agent** to match, so `/work-next-ticket` can dispatch them.
- Put the blocking edges in the ticket's **Notes** as `Blocked by: LL-NNN, LL-NNN` (or `Blocked by: none`), and link the source plan.
- Never move tickets between columns, and never edit or reorder existing tickets. Moving a ticket to In Progress is the user's call.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

<board-ticket-template>

### LL-NNN — <Short imperative title>
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: high | medium | low
- **Phase**: P<n>
- **Acceptance**:
  - [ ] End-to-end behaviour, from the player's point of view
  - [ ] Test that proves it
- **Notes**: Blocked by: LL-NNN. What this slice makes work end to end. Plan: [[Plan - <Name>]].

</board-ticket-template>

Avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.
