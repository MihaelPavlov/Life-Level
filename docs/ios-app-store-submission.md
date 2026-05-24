# Life-Level iOS TestFlight Checklist

This checklist starts after the repo-side iOS prep is committed.

## IDs

- App name: `Life-Level`
- Bundle ID: `com.lifelevel.app`
- Backend API: `https://life-level-api-latest-1779363121.onrender.com/api`
- Privacy policy: `https://mpavlov9905.github.io/life-level/privacy/`
- Support/website: `https://mpavlov9905.github.io/life-level/`

## Apple Developer

1. Open Apple Developer → Certificates, Identifiers & Profiles → Identifiers.
2. Create an explicit App ID:
   - Description: `Life-Level`
   - Bundle ID: `com.lifelevel.app`
3. Enable capabilities:
   - HealthKit
   - Push Notifications
   - Background Modes / Remote notifications
4. Create an APNs Auth Key:
   - Name: `LifeLevel APNs`
   - Service: Apple Push Notifications service
   - Download the `.p8` once and store it privately.
   - Keep the Key ID and Team ID for Firebase.

## Firebase

1. Open Firebase project `life-level-ae77f`.
2. Add an iOS app with bundle ID `com.lifelevel.app`.
3. Download `GoogleService-Info.plist`.
4. Place it at `mobile/ios/Runner/GoogleService-Info.plist`.
5. Upload the APNs Auth Key under Firebase Cloud Messaging.
6. On a Mac, run FlutterFire configuration again so `mobile/lib/firebase_options.dart` receives the real iOS app ID for `com.lifelevel.app`.

## Xcode

1. On a Mac, from `mobile/`, run:

   ```sh
   flutter pub get
   cd ios
   pod install
   open Runner.xcworkspace
   ```

2. In Xcode → Runner target:
   - Team: your Apple Developer team
   - Bundle Identifier: `com.lifelevel.app`
   - Signing: Automatically manage signing
   - Capabilities: HealthKit, Push Notifications, Background Modes with Remote notifications
3. Build and run on a real iPhone.

## Build And Upload

From `mobile/` on the Mac:

```sh
flutter build ipa --release --dart-define=API_BASE_URL=https://life-level-api-latest-1779363121.onrender.com/api
```

Upload `build/ios/ipa/*.ipa` with Xcode Organizer or Apple Transporter.

## TestFlight Smoke Test

- Register a new account.
- Log in after closing/reopening the app.
- Grant notification permission.
- Confirm the device token reaches the backend.
- Grant Apple Health permissions.
- Add a sample Apple Health workout and sync it into Life-Level.
- Confirm XP, quests, streaks, and map progress update.
- Claim daily reward.
- Confirm privacy policy opens from the app and store listing.

## App Review Notes

Life-Level is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Health/activity data is used only for user-authorized gameplay progress, XP, quests, streaks, rewards, and activity history.
