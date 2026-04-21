Boot the full device-testing stack for Life-Level on the connected Android phone (Redmi). Execute these steps in order; parallelize where noted.

## 1. Detect the device

Run `adb devices -l`. On Windows, `adb` is usually not on PATH — fall back to `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices -l`.

- If no device listed → stop and tell the user to plug in the phone.
- If status is `unauthorized` → stop and tell the user to accept the USB-debugging prompt on the phone.
- Otherwise capture the serial (e.g. `euguw86hxst4qsqw`) and model.

## 2. Start backend and ngrok in parallel

Launch both in a single message, each with `run_in_background: true`:

- Backend: `cd backend/src/LifeLevel.Api && dotnet run --launch-profile http` (Bash)
- ngrok: `ngrok http 5128 --log=stdout` (PowerShell)

Then wait for both signals (in parallel):

- Backend ready: arm a `Monitor` tailing the backend output, greping for `Now listening on|Application started|error|Exception|FAILED`.
- ngrok URL: arm a `Monitor` running `until curl -sf http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -o 'https://[a-z0-9-]*\.ngrok-free\.app'; do sleep 2; done`. The emitted URL is the tunnel.

If ngrok's background task exits unexpectedly, verify it's still alive via `Get-Process -Name ngrok` and retry the API call — the URL endpoint is authoritative.

## 3. Update the API base URL

Edit `mobile/lib/core/api/api_client.dart` — replace the `_baseUrl` string with `<NGROK_URL>/api` (keep the `/api` suffix). Use `Edit`, not `Write`.

## 4. Verify the tunnel reaches Kestrel

One request: `Invoke-WebRequest "<NGROK_URL>/api/health" -Headers @{"ngrok-skip-browser-warning"="true"} -TimeoutSec 5 -UseBasicParsing`. Any response from Kestrel (even 404) proves the tunnel is wired. Only fail if the request can't reach the tunnel.

## 5. Launch Flutter on the device

`cd mobile && flutter run -d <DEVICE_SERIAL>` via `Bash` with `run_in_background: true`. Then arm a `Monitor` (timeout 600000ms) watching for:

- Progress: `Built build|Installing|Syncing files|Dart VM Service on`
- Failure: `error:|Error:|BUILD FAILED|FAILURE|Lost connection to device|Unhandled Exception|E/flutter`

Gradle first build is ~60–120s; cached rebuilds are faster.

## 6. Start the board dashboard server (reuse `/board` logic)

- Check port 8765: `Invoke-WebRequest http://127.0.0.1:8765/docs/board.md -UseBasicParsing -TimeoutSec 2`. If 200, skip the next sub-step.
- Otherwise start it: `cd <repo-root> && python -m http.server 8765` in the background.
- Open: `Start-Process "http://127.0.0.1:8765/design-mockup/project-board.html"`.

## 7. Open the ngrok inspector

`Start-Process "http://127.0.0.1:4040"`.

## 8. Arm a persistent runtime-error watcher

After the Dart VM Service URL appears, stop the step-5 monitor and arm a persistent one:

```
tail -f <flutter-output-file> | grep -E --line-buffered "EXCEPTION CAUGHT|Unhandled Exception|E/flutter|FATAL|Lost connection to device|Application finished"
```

## Skipped by default (mention to the user)

**Strava webhook re-registration** — only needed if testing inbound Strava activity sync this session. Requires deleting the stale subscription + posting a new one with the Strava client secret. Commands are in `memory/project_device_testing_resume.md` step 4. Ask the user before running (destructive + sends secrets).

## Final report

One short summary:

- Backend task id + port 5128
- ngrok URL
- Device serial + model
- Flutter task id + Dart VM Service URL
- Board dashboard: `http://127.0.0.1:8765/design-mockup/project-board.html`
- ngrok inspector: `http://127.0.0.1:4040`
