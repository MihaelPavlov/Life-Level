---
tags: [lifelevel, plan, activity, verification, anti-cheat, ios, android]
aliases: [Verified Workouts, Activity Trust]
---

# Plan - Verified Workout Recording and Activity Trust

## Summary

Replace reward-bearing manual workout logging in production with two supported paths:

1. synced workouts from connected health and fitness providers; and
2. an in-app workout recorder that gathers enough device evidence to establish a trust level.

Manual entries remain available as a private journal, but never grant XP, steps, quest credit, boss damage, achievement progress, leaderboard points, streak credit, coins, gems, or other competitive rewards. The server remains authoritative: the client records evidence, while backend policy determines what each activity can affect.

This gives users without a separate tracking app a legitimate way to use Life Level while making fabricated activity substantially harder and limiting the competitive impact of weaker evidence.

## Product Rules and Trust Matrix

| Activity evidence | Personal progression | Competitive progression | Route display |
|---|---:|---:|---:|
| Verified outdoor in-app recording | Full | Full | Available for 30 days |
| Trusted provider/device sync | Full | Full | Provider-dependent |
| Verified timed indoor recording | Full | None | Not applicable |
| Ambiguous provider sync | Full | None | Provider-dependent |
| Manual journal entry | None | None | None |
| Rejected or invalid session | None | None | None |

Personal progression includes XP, character stats, steps/distance totals, personal quests, achievements, streaks, and ordinary adventure progress. Competitive progression includes leaderboards, guild contribution, raids, shared bosses, PvP-adjacent systems, and any future ranked event.

The backend must evaluate rewards from the stored trust decision. Mobile clients must never be allowed to select their own verification status or reward eligibility.

## Backend Model and Interfaces

### Activity provenance

Extend stored activities with explicit provenance and verification data:

- `ActivitySource`: `ProviderSync`, `InAppOutdoor`, `InAppIndoor`, `ManualJournal`.
- `VerificationStatus`: `Pending`, `Verified`, `PersonalOnly`, `Rejected`.
- provider name and immutable provider activity ID where applicable.
- recording session ID where applicable.
- verification reason codes and policy version.
- server-calculated eligibility flags for personal and competitive rewards.
- server-calculated trusted duration, distance, steps, elevation, and calories used for rewards.

Keep raw reported metrics separate from trusted metrics. Existing activity responses should expose source, verification status, eligibility, and an understandable rejection or limitation reason without exposing anti-cheat thresholds that would make evasion easier.

### Workout sessions

Add a `WorkoutSession` aggregate owned by one user with:

- server-generated session ID and short-lived upload token;
- activity type and indoor/outdoor mode;
- server start time, client start time, completion time, and status;
- monotonic elapsed-time evidence;
- sampled location, accuracy, speed, altitude, motion, and device-integrity summaries;
- pause/resume periods and background gaps;
- route bounding information and encrypted/compressed route evidence;
- app/device build, platform, integrity verdict, and policy version;
- deterministic completion and idempotency keys;
- verification result and reason codes.

Store detailed route evidence for 30 days, then remove or irreversibly aggregate it. Retain the minimal verification audit record required to explain reward decisions and prevent duplicate rewards.

### API surface

- `POST /api/workout-sessions/start` creates a server-authoritative session and returns the session ID, upload token, sampling configuration, and server start time.
- `POST /api/workout-sessions/{id}/samples` uploads ordered, bounded batches during recording and supports idempotent retries.
- `POST /api/workout-sessions/{id}/complete` seals the session, verifies it, creates the activity, and returns the activity plus its trust decision and rewards.
- `POST /api/workout-sessions/offline` uploads a locally recorded session when the user could not start online; it receives stricter validation and can never silently become more trusted than the evidence supports.
- `GET /api/workout-sessions/{id}` returns recording/upload/verification state so interrupted clients can resume safely.

Completion must be idempotent. A session can create at most one activity and an external provider activity ID can be imported at most once per user.

## Verification Policy

### Outdoor sessions

Outdoor sessions require plausible elapsed time, enough valid GPS samples, acceptable accuracy, route continuity, consistent motion evidence, and speed/acceleration compatible with the selected activity. Validation must detect teleports, impossible pace, large unexplained gaps, emulator/mock-location indicators where available, duplicate routes, timestamp manipulation, and simultaneous conflicting sessions.

Low-confidence sessions are downgraded to personal-only or rejected; they are not automatically granted full competitive credit. The API returns stable user-facing reason codes such as insufficient GPS, implausible movement, interrupted recording, duplicate workout, or device verification unavailable.

### Indoor sessions

Indoor strength, mobility, yoga, treadmill, cycling, and similar sessions use server-bounded elapsed time plus foreground/background state, motion/heart-rate evidence when available, pause periods, and sensible duration limits. Because elapsed time alone cannot prove exertion, valid in-app indoor sessions grant personal progression only in v1.

Swimming is sync-only in v1 because reliable phone-based evidence and safe background recording are not broadly available in a normal pool session.

### Synced activities

Preserve provider provenance and deduplicate across repeated imports and overlapping providers. Provider/device-recorded workouts with stable IDs and trustworthy metadata may receive full credit. Weak, manually entered, or ambiguous provider records receive personal-only or no credit based on policy. Provider labels are evidence inputs, not automatic proof.

### Reward enforcement

Move every reward consumer behind one centralized eligibility policy. Activity creation may store a rejected or journal-only record, but downstream services must use trusted metrics and eligibility flags rather than raw client values. This applies to XP, stats, steps, streaks, quests, achievements, adventure movement, boss damage, guild/raid contribution, currencies, and leaderboards.

## Mobile Experience

Replace the production `Log workout` reward flow with `Start workout`. Users choose an activity and see whether it is eligible for full or personal-only progress before recording.

The recorder must:

- request permissions contextually and explain why they are needed;
- show elapsed time, recording state, GPS quality, pause/resume, and trusted metrics;
- persist recording locally and continue through screen lock, app backgrounding, temporary connectivity loss, and process recreation where the platform permits;
- upload small ordered sample batches and retry without duplication;
- clearly distinguish `Verifying`, `Verified`, `Personal progress only`, and `Not eligible` results;
- never celebrate or animate rewards until the backend completion response confirms them.

Keep `Add manual entry` as a secondary journal action with an explicit `No game rewards` label and confirmation. Manual entries remain editable because they have no progression impact; rewarded records remain immutable except for safe display metadata.

## Android and iOS Deployment

### Android

- Implement foreground location and workout recording with the required persistent notification and foreground-service types.
- Request activity-recognition and location permissions progressively; support approximate-location denial and explain when full outdoor verification is unavailable.
- Integrate Play Integrity behind a backend abstraction. Begin in observe-only mode, collect verdict coverage, then enforce only after measuring false positives.
- Test background recording under Doze, battery optimization, process recreation, offline completion, and current Google Play foreground-service declarations.

### iOS

- Enable the required location/background capabilities and provide complete privacy usage descriptions.
- Use Core Location background recording only during an active user-started workout, with visible recording state and correct termination behavior.
- Integrate App Attest/DeviceCheck behind the same backend integrity abstraction, initially observe-only.
- Test screen lock, background suspension, force quit, low-power mode, denied permissions, and interrupted upload.

This increases native release complexity but does not require a separate app. Store review risk is manageable when background access is user-initiated, visibly active, narrowly scoped, and described accurately in privacy declarations. CI and release checklists must validate platform entitlements, manifests, signing, and store disclosures.

## Rollout

1. Introduce provenance, trust fields, centralized reward policy, and provider deduplication without changing the current user flow.
2. Ship the recorder to internal testers with integrity checks in observe-only mode and all recorded activities personal-only.
3. Enable full outdoor personal rewards after validation telemetry and false-positive review.
4. Enable competitive outdoor rewards only for sessions meeting the strict policy; keep indoor sessions personal-only.
5. Relabel manual logging as journal-only and remove every reward path from it before production rollout.
6. Monitor rejection/downgrade rates, duplicate attempts, sample gaps, integrity availability, battery impact, crashes, and support reports by platform/app version.

Policy thresholds must be versioned and remotely adjustable on the backend. Existing activities keep their original decision and are not silently re-rated when policy changes.

## Verification and Acceptance Tests

### Backend

- Starting, batching, resuming, completing, and retrying a session is authenticated and idempotent.
- The same session or provider activity cannot grant rewards twice.
- Plausible outdoor evidence receives the expected trust decision and trusted metrics.
- teleports, impossible speed, timestamp manipulation, excessive gaps, conflicting sessions, mock/emulated evidence, and malformed batches are downgraded or rejected.
- Timed indoor sessions can grant personal rewards but never competitive rewards.
- Manual entries never reach any progression or reward consumer.
- Every downstream progression system uses eligibility and trusted metrics.
- Route evidence expires after 30 days while the minimal audit record remains.
- Policy-version changes affect only newly evaluated activities unless an explicit administrative re-evaluation is run.

### Mobile

- Permission accepted, denied, and later-enabled flows are understandable on both platforms.
- Recording survives backgrounding, screen lock, temporary loss of network, and supported process recreation.
- Upload retries do not duplicate samples, activities, or rewards.
- The UI accurately represents pending, verified, personal-only, rejected, and failed-upload states.
- Manual journal entries display `No game rewards` before and after saving.
- Reward animations occur only after server-confirmed eligible completion.

### Release acceptance

- Test representative Android and iOS devices for battery use and route continuity.
- Confirm privacy policy, store declarations, permission copy, data retention, and account-deletion behavior cover workout evidence and routes.
- Confirm no health-provider writeback is performed in v1.
- Confirm users without an external fitness app can earn personal progression through verified outdoor or timed indoor recording.

## Assumptions

- V1 supports verified outdoor recording and timed indoor recording; swimming remains provider-sync-only.
- Outdoor sessions that pass strict verification can affect competitive systems; indoor recordings remain personal-only.
- Detailed route evidence is retained for 30 days.
- Device integrity starts in observe-only mode and is enforced progressively after telemetry review.
- Life Level does not write workouts back to Apple Health, Health Connect, or other providers in v1.
- No client-supplied duration, distance, steps, calories, or trust label is accepted directly for rewards.
