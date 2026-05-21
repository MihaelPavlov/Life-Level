# Work Next Ticket Prompt

Use this when the user asks Codex to work the next board ticket.

## Ticket Selection

Read `docs/board.md`.

- If the user supplied a ticket ID like `LL-011`, select that ticket wherever it appears.
- Otherwise select the first ticket under `In Progress`.
- Do not auto-pick blocked or completed tickets.
- If there is no in-progress ticket, list the top backlog candidates and ask the user which to pull forward.

## Checkpoint

Before editing code, summarize in no more than five lines:

- Ticket ID and title.
- Layer and relevant local skill or agent brief.
- One-sentence interpretation.
- Expected files or directories.
- Ambiguities.

Wait for approval before implementation if the ticket is ambiguous or the user explicitly requested a checkpoint.

## Execution

Use the relevant local skill:

- Backend: `.codex/skills/lifelevel-backend/SKILL.md`
- Flutter: `.codex/skills/lifelevel-flutter-ui/SKILL.md`
- Game logic: `.codex/skills/lifelevel-game-engine/SKILL.md`

Implement exactly the acceptance criteria. Avoid drive-by refactors.

## Verification

- Backend: run focused tests, then `dotnet test` when appropriate.
- Mobile: run `flutter analyze` and relevant widget tests.
- Review the diff before final reporting.

## Board Update

If the user asked for board maintenance:

- Check off acceptance criteria that are actually met.
- Append an implementation note.
- Do not move tickets between columns unless the user explicitly asks.

## Final Report

Include:

- Ticket ID and title.
- Files changed.
- Tests run and result.
- Uncertainties or follow-up risks.
