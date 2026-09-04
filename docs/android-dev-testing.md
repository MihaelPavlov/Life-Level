# Android Development Testing

Use this workflow to run the local API and Flutter app on a physical Android device. For complete machine setup and release publishing, see [new-machine-setup.md](new-machine-setup.md).

## Prerequisites

- .NET 10 SDK
- Flutter SDK and Android Studio
- Android SDK Platform Tools (`adb`)
- ngrok authenticated with `ngrok config add-authtoken <your-token>`
- A phone with Developer Options and USB debugging enabled
- Backend `appsettings.json` configured from `backend/src/LifeLevel.Api/appsettings.example.json`

## Start the API

```powershell
cd backend/src/LifeLevel.Api
dotnet run --launch-profile http
```

The API listens on `http://localhost:5128`. Keep this window open.

## Start ngrok

In a second window:

```powershell
ngrok http 5128
```

Copy the current `https://<host>.ngrok-free.app` URL.

## Register the current Strava webhook when needed

Only do this when testing inbound Strava activity sync. The tunnel URL changes between sessions. Set credentials in the current PowerShell session rather than placing them in source files:

```powershell
$env:STRAVA_CLIENT_ID = '<client-id>'
$env:STRAVA_CLIENT_SECRET = '<client-secret>'
$env:STRAVA_VERIFY_TOKEN = '<verify-token>'
curl.exe "https://www.strava.com/api/v3/push_subscriptions?client_id=$env:STRAVA_CLIENT_ID&client_secret=$env:STRAVA_CLIENT_SECRET"
```

Delete the stale subscription using the returned ID, then register the new callback:

```powershell
curl.exe -X DELETE "https://www.strava.com/api/v3/push_subscriptions/<subscription-id>?client_id=$env:STRAVA_CLIENT_ID&client_secret=$env:STRAVA_CLIENT_SECRET"
curl.exe -X POST https://www.strava.com/api/v3/push_subscriptions `
  -F client_id=$env:STRAVA_CLIENT_ID `
  -F client_secret=$env:STRAVA_CLIENT_SECRET `
  -F callback_url=https://<host>.ngrok-free.app/api/integrations/strava/webhook `
  -F verify_token=$env:STRAVA_VERIFY_TOKEN
```

## Connect and run the phone app

```powershell
adb devices
cd mobile
flutter run -d <device-serial> --dart-define=API_BASE_URL=https://<host>.ngrok-free.app/api
```

The device must have status `device`, not `unauthorized`. Do not edit `mobile/lib/core/api/api_client.dart` to change the URL.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `adb devices` is empty | Install the phone's USB driver and reconnect it. |
| Device is `unauthorized` | Accept the USB debugging prompt on the phone. |
| API cannot be reached | Confirm the API is on port 5128, ngrok is running, and the current URL was passed with `--dart-define`. |
| Strava events do not arrive | Confirm the active subscription uses the current ngrok callback URL. |
| Release signing fails | Check `mobile/android/key.properties` and the upload keystore. |

## Security notes

Do not commit API credentials, JWT keys, Firebase service-account files, signing keys, `appsettings.json`, or `mobile/android/key.properties`. iOS HealthKit testing additionally requires the HealthKit capability in Xcode.
