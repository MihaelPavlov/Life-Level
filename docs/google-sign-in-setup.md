# Google Sign-In setup

Life-Level verifies Google ID tokens on the API and continues to use its own JWT
for application sessions. The mobile and API configurations must use the same
Google **Web application** OAuth client ID.

## Runtime configuration

- API: set `GoogleAuth__ServerClientId`.
- Flutter: build or run with
  `--dart-define=GOOGLE_SERVER_CLIENT_ID=<client-id>.apps.googleusercontent.com`.
- Never add an OAuth client secret to the app or repository; ID-token
  verification only requires the public client ID.

## Google/Firebase console

1. Enable Google in Firebase Authentication providers.
2. Android: register the debug and release SHA-1/SHA-256 fingerprints for
   `com.lifelevel.app`, then download a refreshed `google-services.json`.
3. Web: add `http://localhost:5000` and each production origin to the Web OAuth
   client's authorized JavaScript origins.
4. iOS: register `com.lifelevel.app`, add `GoogleService-Info.plist` to the
   Runner target, and add its `REVERSED_CLIENT_ID` as a URL scheme.

Local example:

```bash
flutter run -d chrome --web-hostname localhost --web-port 5000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<client-id>.apps.googleusercontent.com
```
