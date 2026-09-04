# Life-Level New Machine Setup

This is the canonical setup guide for running Life-Level locally, testing on Android, and publishing updates.

## 1. Install the toolchain

Install and add these tools to `PATH`:

- Git
- .NET 10 SDK (the API targets `net10.0`)
- Flutter SDK and Android Studio
- Android SDK Platform Tools (`adb`), an Android SDK platform, and an emulator image
- Java 11-compatible JDK (Android Studio's bundled JDK is normally sufficient)
- PostgreSQL, or access to the project's Supabase PostgreSQL database
- ngrok for physical-device testing and Strava webhooks
- Docker Desktop only when publishing the backend container

Verify the installation from PowerShell:

```powershell
dotnet --version
flutter doctor
adb version
ngrok version
docker version
```

`docker version` is optional for local development. Resolve Android issues reported by `flutter doctor` before trying a release build.

## 2. Clone and restore dependencies

```powershell
git clone <repository-url>
cd Life-Level
cd backend
dotnet restore
cd ..\mobile
flutter pub get
```

If needed, accept Android SDK licenses with `flutter doctor --android-licenses`.

The first Flutter command creates `mobile/android/local.properties`, which contains machine-local SDK paths and must not be committed.

## 3. Configure the backend

Copy `backend/src/LifeLevel.Api/appsettings.example.json` to `appsettings.json` and fill in values supplied through the project's secret store. `appsettings.json` is ignored by Git.

At minimum, configure:

- `ConnectionStrings:DefaultConnection` for PostgreSQL
- `Jwt:Key` and the JWT issuer/audience settings
- `Strava` and `Garmin` integration credentials when those integrations are being tested
- `Firebase:CredentialsPath` and the Firebase Admin service-account file when push notifications are being tested

Keep Firebase keys, API credentials, JWT keys, and production connection strings outside Git. For local development, put the Firebase key at `backend/src/LifeLevel.Api/firebase-admin-key.json` when using the example relative path.

Apply the existing EF migrations from the `backend` directory. Stop any running API first so its output files are not locked:

```powershell
cd backend
dotnet ef database update --project src/LifeLevel.Api --startup-project src/LifeLevel.Api
dotnet build
dotnet test
```

Start the API in a separate PowerShell window:

```powershell
cd backend/src/LifeLevel.Api
dotnet run --launch-profile http
```

The local API is `http://localhost:5128`; Swagger is at `http://localhost:5128/swagger`.

## 4. Run Flutter locally

For an Android emulator, the app defaults to `http://10.0.2.2:5128/api`, which maps to the host machine's port 5128:

```powershell
cd mobile
flutter run
```

For Flutter web, use:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5128/api
```

Run the checks before sharing a change:

```powershell
flutter analyze
flutter test
```

## 5. Test on a physical Android phone

Enable Developer Options and USB debugging, connect the phone by USB, then check:

```powershell
adb devices
```

The device must appear as `device`, not `unauthorized`. Install the manufacturer's USB driver if Windows does not detect it.

In another window, expose the API:

```powershell
ngrok http 5128
```

Pass the current tunnel URL at launch. Do not edit `mobile/lib/core/api/api_client.dart`:

```powershell
cd mobile
flutter run -d <device-serial> --dart-define=API_BASE_URL=https://<current-ngrok-host>/api
```

The URL changes when ngrok restarts. Re-register the Strava webhook only when testing inbound Strava events, using credentials through environment variables. Never place credentials in documentation or source control. The callback is `https://<current-ngrok-host>/api/integrations/strava/webhook`.

## 6. Update and install an Android build

Update `version` in `mobile/pubspec.yaml` using `major.minor.patch+build`. The number after `+` must increase for every uploaded Play build.

For a local debug APK:

```powershell
cd mobile
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5128/api
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

For Google Play, use the existing upload keystore or create one once. Store it securely and do not regenerate it for routine releases:

```powershell
keytool -genkeypair -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `mobile/android/key.properties` with the real values:

```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Build the signed bundle with the production API URL:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=API_BASE_URL=https://<production-api-host>/api
```

Upload `mobile/build/app/outputs/bundle/release/app-release.aab` to the Play Console internal testing track first. Confirm Firebase, OAuth deep links, Health Connect permissions, and the production API before promotion.

## 7. Deploy the backend

Log in to Docker and publish the API image from the repository root:

```powershell
docker login
.\scripts\push-lifelevel-api-image.ps1
```

The script prints the timestamped image tag. Update the Render/container service to that tag and configure production secrets in the hosting provider, not in `appsettings.json`. Apply production migrations according to the deployment procedure and verify the API after deployment.

## 8. Files that must remain local

Never commit `appsettings.json`, `firebase-admin-key.json`, `mobile/android/local.properties`, `mobile/android/key.properties`, Android keystores, OAuth credentials, JWT keys, database passwords, or hosting credentials.

When setup differs from this document, update this file and the related Android/Claude instructions in the same change.

## Common failures

- API unreachable on emulator: confirm the API is listening on port 5128 and use `10.0.2.2`, not `localhost`.
- API unreachable on phone: confirm ngrok is running and pass its current URL with `--dart-define`.
- No Android device: run `adb devices`, accept the authorization prompt, and install the USB driver.
- Migration/build files locked: stop the running API and retry `dotnet ef database update`.
- Release signing failure: check `mobile/android/key.properties`, keystore path, alias, and passwords.
- Strava events missing: the callback must use the current ngrok host and the active subscription must point to it.
