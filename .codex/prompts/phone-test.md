# Phone Test Prompt

Boot the Life-Level Android device testing stack.

## Flow

1. Detect device:

```powershell
adb devices -l
```

If `adb` is not on PATH, use:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices -l
```

Stop if no device is attached or if the device is unauthorized.

2. Start backend:

```powershell
cd backend/src/LifeLevel.Api
dotnet run --launch-profile http
```

3. Start ngrok:

```powershell
ngrok http 5128
```

4. Update `mobile/lib/core/api/api_client.dart` so `_baseUrl` is `<ngrok-url>/api`.

Do not commit that URL change.

5. Verify the tunnel reaches Kestrel with a simple request to the ngrok URL.

6. Run Flutter on the detected device:

```powershell
cd mobile
flutter run -d <device-serial>
```

7. Optionally serve the board dashboard on port 8765 and open the ngrok inspector.

## Default Skip

Skip Strava webhook re-registration unless the user explicitly asks. It changes external webhook state and uses secrets.

## Report

Include backend port, ngrok URL, device serial/model, Flutter run status, and useful URLs.
