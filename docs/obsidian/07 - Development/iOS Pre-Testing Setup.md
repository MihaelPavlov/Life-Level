---
tags: [lifelevel, dev]
aliases: [iOS Setup, APNs Setup, iOS Checklist, iOS Required]
---
# iOS Pre-Testing Setup

> Everything that must be configured **before iOS device/simulator testing can begin**. None of these can be done from Windows — they require macOS + Xcode + an Apple Developer Program membership ($99/yr).

> [!warning] **Status: not yet done.** Android testing is fully unblocked; iOS has been deferred until Mac access is available. Track here so nothing is forgotten when that day comes.

---

## Why this is its own checklist

iOS testing is gated by several independent prerequisites that compound — you can't do (3) without (2), can't do (2) without (1), etc. Knock them out in one sitting on a Mac to avoid context-switching back and forth.

Estimated total time on a Mac with Apple Developer access already set up: **45–60 minutes**.

---

## Prerequisites (one-time, off-device)

| Requirement | Why | Get it |
|---|---|---|
| Mac with Xcode 15+ | Sole way to sign iOS builds, edit capabilities, generate provisioning profiles | App Store → Xcode |
| Apple ID | Apple Developer Program enrolment + App Store Connect | appleid.apple.com |
| Apple Developer Program membership ($99/yr) | Required for Push Notifications + HealthKit + signed builds on real devices | https://developer.apple.com/programs |
| iOS device for real-hardware testing (recommended) | Push notifications and HealthKit don't work in the iOS Simulator | Any iPhone running iOS 13+ |

---

## The Setup Tasks

### Task 1 — Decide the iOS bundle ID
**Current:** `com.example.lifeLevel` (Flutter scaffold default)

If you plan to publish under a real org, change it BEFORE registering anything with Apple or Firebase iOS — both lock to the bundle ID. Suggested replacements: `com.mihaelpavlov.lifelevel`, `com.coherentsolutions.lifelevel`.

To change: open `mobile/ios/Runner.xcodeproj/project.pbxproj` in Xcode and update `PRODUCT_BUNDLE_IDENTIFIER` under all build configs. (Then re-run `flutterfire configure` so Firebase iOS app is re-registered.)

---

### Task 2 — Apple Developer: register the App ID + capabilities
1. https://developer.apple.com → Certificates, Identifiers & Profiles → **Identifiers** → **+** → **App IDs**
2. Description: `Life Level`
3. Bundle ID: explicit, matches Task 1 (e.g. `com.mihaelpavlov.lifelevel`)
4. **Capabilities** — tick at minimum:
   - ☑ **Push Notifications** (required for FCM iOS, [[LL-013 Notifications|LL-013]])
   - ☑ **HealthKit** (required for [[Health Connect|Apple Health import]], [[LL-018]])
5. Register

---

### Task 3 — Apple Developer: APNs Authentication Key
The auth key approach is preferred over the older cert-based approach (one key works for all your apps, no expiry).

1. developer.apple.com → Certificates, Identifiers & Profiles → **Keys** → **+**
2. Name: `LifeLevel APNs`
3. ☑ **Apple Push Notifications service (APNs)** → Continue → Register
4. **Download the `.p8` file** ⚠ this can only be downloaded **once** — store securely (1Password, Bitwarden, etc.)
5. Note these three values for the Firebase upload step:
   - **Key ID** (10-char alphanumeric, shown on the key page)
   - **Team ID** (10-char alphanumeric, top-right of any developer.apple.com page after sign-in)
   - The `.p8` file itself

---

### Task 4 — Firebase Console: upload APNs key + grab `GoogleService-Info.plist`
1. https://console.firebase.google.com/project/life-level-ae77f/settings/cloudmessaging
2. Section: "Apple app configuration" → find the iOS app entry (already registered by `flutterfire configure`)
3. **APNs Authentication Key** → **Upload** → pick `.p8`, fill Key ID + Team ID → Save
4. While here: Project Settings → General → "Your apps" → iOS app → **GoogleService-Info.plist** → **Download**
5. Save the plist to: `mobile/ios/Runner/GoogleService-Info.plist`

> The plist is needed for native iOS Firebase init even though Flutter mostly relies on `firebase_options.dart`. FCM specifically reads from the plist on iOS.

---

### Task 5 — Xcode: capabilities, signing, plist inclusion
Open the project: `open mobile/ios/Runner.xcworkspace` (note: `.xcworkspace`, not `.xcodeproj` — the workspace pulls in CocoaPods).

1. Select the **Runner** target (left sidebar)
2. **Signing & Capabilities** tab:
   - **Team**: pick your Apple Developer team
   - **Bundle Identifier**: matches Task 1
   - Click **+ Capability** → add **Push Notifications**
   - Click **+ Capability** → add **Background Modes** → tick ☑ **Remote notifications**
   - Click **+ Capability** → add **HealthKit** (covers [[LL-018]])
3. Verify `GoogleService-Info.plist` (from Task 4) appears in the **Runner** group in the navigator. If missing: drag it in, ensure ☑ **"Copy items if needed"** and ☑ **"Add to targets: Runner"**.
4. Build once (⌘B) — if the build fails complaining about provisioning, click **"Try Again"** so Xcode auto-generates a signing profile.

---

### Task 6 — Verify push works end-to-end
1. Run the app on a **real iOS device** (push doesn't work in the simulator)
2. App should request push permission on first launch (after Flutter wires up `firebase_messaging` per [[LL-013 Notifications|LL-013a]])
3. Get the FCM token from app logs (it'll print on launch)
4. Firebase Console → Engage → **Cloud Messaging** → **Send test message** → paste FCM token → Send
5. Push notification should appear in the iOS notification tray within seconds

### Task 7 — Verify HealthKit works
1. Open the app → trigger Health Connect / HealthKit sync
2. iOS asks permission for Apple Health data → grant
3. Add a sample workout in the iOS Health app → trigger sync in Life-Level → verify it imports

---

## Files that will be touched on the Mac

| File | Source | Notes |
|---|---|---|
| `mobile/ios/Runner/GoogleService-Info.plist` | Firebase Console download | NOT secret — safe to commit |
| `mobile/ios/Runner/Runner.entitlements` | Auto-generated by Xcode capabilities | Commit |
| `mobile/ios/Runner.xcodeproj/project.pbxproj` | Xcode capability edits | Commit |
| `mobile/ios/Runner/Info.plist` | Already has HealthKit usage descriptions | Verify still present |
| `~/Library/MobileDevice/Provisioning Profiles/*.mobileprovision` | Auto-generated by Xcode signing | Local only — never commit |
| `*.p8` (APNs key) | Apple Developer download | Local only — never commit; store in password manager |

---

## Related tickets
- [[LL-013 Notifications|LL-013]] — Push notifications via FCM (Android works without this; iOS gated by Tasks 3-5)
- [[LL-018]] — iOS HealthKit capability (covered by Task 5)

## Related notes
- [[Environment Setup]]
- [[Known Issues]]
- [[Health Connect]]
- [[Garmin]] (PKCE crypto TODO — not iOS-specific but FCM-adjacent)
