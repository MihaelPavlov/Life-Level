---
name: run-board
description: Start the local Life-Level project board over HTTP and open it in Chrome. Use when the user wants the Jira-like ticket board, wants `design-mockup/project-board.html` to load `docs/board.md` without `file://` fetch issues, or asks to run/open the board locally again.
---

# Run Board

## Overview

Start the local board through a loopback HTTP server so `design-mockup/project-board.html` can fetch `docs/board.md` normally. Use the bundled PowerShell script instead of opening the HTML directly with `file://`.

## Workflow

1. Run [scripts/run-board.ps1](scripts/run-board.ps1).
2. Let it start the loopback server if `http://127.0.0.1:8099/design-mockup/project-board.html` is not already live.
3. Let it open Chrome to the board URL unless the caller only wants the server.

## Files

- [scripts/run-board.ps1](scripts/run-board.ps1): entrypoint; starts the server if needed and opens Chrome.
- [scripts/serve-board.ps1](scripts/serve-board.ps1): simple TCP static server rooted at the repo.
- Board URL: `http://127.0.0.1:8099/design-mockup/project-board.html`
- Source markdown: `docs/board.md`

## Notes

- The script intentionally serves the board over HTTP to avoid Chrome blocking `fetch('../docs/board.md')` on `file://`.
- If the board server is already running, the launcher only opens the browser.
- Use `powershell -ExecutionPolicy Bypass -File skills/run-board/scripts/run-board.ps1 -NoBrowser` when only the local server is needed.
