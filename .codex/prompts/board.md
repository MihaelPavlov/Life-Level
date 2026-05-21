# Board Dashboard Prompt

Serve and open the Life-Level ticket board dashboard locally.

## Steps

1. Check whether port 8765 is already serving the repo:

```powershell
Invoke-WebRequest http://127.0.0.1:8765/docs/board.md -UseBasicParsing -TimeoutSec 2
```

2. If it is not running, start a static HTTP server in the repo root:

```powershell
python -m http.server 8765
```

3. Open:

```text
http://127.0.0.1:8765/design-mockup/project-board.html
```

Opening a browser requires approval in sandboxed Codex sessions.

## Why HTTP

`design-mockup/project-board.html` fetches `../docs/board.md`, and browser file access blocks that from `file://`.

## Report

Return the dashboard URL and any background process details.
