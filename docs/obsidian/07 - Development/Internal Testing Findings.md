---
tags: [lifelevel, dev, testing, qa]
aliases: [Internal Testing Log, Testing Findings, QA Findings]
---
# Internal Testing Findings

> Active list for anything found while testing internal Google Play builds. Add rough notes here first; promote confirmed recurring issues to [[Known Issues]] later.

## How to Log a Finding

Use one checklist item per finding:

```md
- [ ] [P1] 2026-05-21 - Short title
  - Build: 1.0.0+3
  - Device: Android model / OS version
  - Area: Auth / Activity / Map / Notifications / Integrations / Other
  - Steps:
    1. ...
    2. ...
  - Expected:
  - Actual:
  - Evidence: screenshot, log, Render log timestamp, DB row, etc.
  - Status: New / Reproduced / Fixed / Cannot reproduce
```

Priority guide:

| Priority | Meaning |
|----------|---------|
| P0 | Blocks app startup, login, registration, or data safety |
| P1 | Blocks a core flow for many testers |
| P2 | Broken feature with workaround |
| P3 | Polish, copy, layout, or low-risk UX issue |

## Open Findings

- [ ] [P2] 2026-05-21 - First quest card is slightly cut off at the bottom
  - Build: 1.0.0+3
  - Device: Test phone
  - Area: Quests / Home
  - Steps:
    1. Register or log in.
    2. Open the screen where the first quest appears.
  - Expected: The full quest UI is visible within the screen.
  - Actual: The bottom has a few black pixels and the quest area is not fully on-screen.
  - Evidence: Tester observation.
  - Status: Fixed locally in 1.0.0+4; needs retest after Play update.

- [ ] [P1] 2026-05-21 - Day 0 reward claim returns Dio 409
  - Build: 1.0.0+3
  - Device: Test phone
  - Area: Login Reward
  - Steps:
    1. Register a new account.
    2. Reach "Day 0 reward ready".
    3. Tap Claim.
  - Expected: Reward is claimed or the UI shows the correct already-claimed / unavailable state.
  - Actual: Claim fails with DioException 409 and message that the request contains bad syntax.
  - Evidence: Tester observation.
  - Status: Fixed locally in 1.0.0+4; needs retest after Play update.

- [ ] [P1] 2026-05-21 - Health Connect connect flow only opens Health Connect
  - Build: 1.0.0+3
  - Device: Test phone
  - Area: Health Connect / Integrations
  - Steps:
    1. Open integrations or health sync flow.
    2. Tap Connect for Health Connect.
  - Expected: App requests permissions and completes the Health Connect connection state.
  - Actual: Health Connect opens, but the app does not appear connected afterward.
  - Evidence: Tester observation.
  - Status: Fixed locally in 1.0.0+4; needs retest after Play update.

- [ ] [P3] 2026-05-21 - Quest tabs show unwanted white bottom border
  - Build: 1.0.0+3
  - Device: Test phone
  - Area: Quests
  - Steps:
    1. Open Quest page.
    2. Look under the Daily / Weekly / Special tabs.
  - Expected: Tabs match the dark app style without an extra white bottom border.
  - Actual: A white bottom border line appears under the tabs.
  - Evidence: Tester observation.
  - Status: Fixed locally in 1.0.0+4; needs retest after Play update.

- [ ] [P1] 2026-05-21 - Register creates user but app shows generic duplicate message
  - Build: 1.0.0+2
  - Device: Test phone
  - Area: Auth
  - Steps:
    1. Install internal testing build.
    2. Register a new account.
  - Expected: App saves token and moves to onboarding.
  - Actual: User row appears in database, but app shows "Registration failed. Email or username may already be taken."
  - Evidence: Supabase Users table has new row.
  - Status: Fixed locally in 1.0.0+3; needs retest after Play update.

- [ ] [P1] 2026-05-21 - Login clears email/password and appears to do nothing
  - Build: 1.0.0+2
  - Device: Test phone
  - Area: Auth
  - Steps:
    1. Try logging in with an existing account.
  - Expected: Login succeeds or shows a stable error message.
  - Actual: Email/password fields clear and no useful result appears.
  - Evidence: Tester observation.
  - Status: Fixed locally in 1.0.0+3; needs retest after Play update.

## Retest Queue

- [ ] 1.0.0+5 - Connect Health Connect with Steps permission and confirm daily steps import as Walking activity.
- [ ] 1.0.0+5 - Confirm repeated Health Connect sync skips already-imported step days.
- [ ] 1.0.0+4 - Confirm First Quest / tutorial intro fits on the test phone.
- [ ] 1.0.0+4 - Claim Day 1 login reward after registration.
- [ ] 1.0.0+4 - Open Health Connect, grant permissions, return to app, confirm it shows connected.
- [ ] 1.0.0+4 - Confirm Quest tab bar has no white bottom divider.
- [ ] 1.0.0+3 - Register a brand-new account.
- [ ] 1.0.0+3 - Login with the account created during the failed 1.0.0+2 registration.
- [ ] 1.0.0+3 - Confirm onboarding opens after successful auth.
- [ ] 1.0.0+3 - Confirm backend receives authenticated requests after token save.

## Fixed / Closed

Move items here only after they are verified on an installed internal testing build.

## Related

- [[Known Issues]]
- [[Environment Setup]]
- [[Feature - Auth]]
- [[Auth and JWT]]
