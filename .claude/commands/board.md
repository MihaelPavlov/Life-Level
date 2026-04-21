Serve and open the Life-Level ticket board dashboard locally.

## Steps

1. Check if port 8765 is already serving the repo — `Invoke-WebRequest http://127.0.0.1:8765/docs/board.md -UseBasicParsing -TimeoutSec 2`. If it returns 200, skip step 2.

2. Otherwise, start a static HTTP server in the repo root in the background:
   - `cd <repo-root> && python -m http.server 8765` via `Bash` with `run_in_background: true`

3. Open the dashboard in the default browser:
   - `Start-Process "http://127.0.0.1:8765/design-mockup/project-board.html"`

## Why HTTP (not file://)

`design-mockup/project-board.html` fetches `../docs/board.md` and uses the Chromium File System Access API (`showOpenFilePicker`) for its **🔗 Connect file** button. Both require an HTTP origin — `file://` blocks them.

## Report

One line with the URL and the background task id of the server, so the user can stop it later if needed.
