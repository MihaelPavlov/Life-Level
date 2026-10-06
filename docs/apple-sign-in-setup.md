# Sign in with Apple setup

The app shows a round "Continue with Apple" button on iOS, next to the Google one
(Login and Register). App Store rule 4.8 requires it once Google sign-in ships.

## Apple Developer account

1. Certificates, Identifiers & Profiles → Identifiers → App ID `com.lifelevel.app`.
2. Enable the **Sign in with Apple** capability (as a primary App ID) and save.
3. Regenerate the provisioning profiles that use this App ID.

The app side is already set: `ios/Runner/Runner.entitlements` has
`com.apple.developer.applesignin = [Default]`.

## Backend

`POST /api/auth/apple` checks Apple's identity token: signature (Apple's published
keys), issuer `https://appleid.apple.com`, audience, expiry and the nonce the app sent.
The accepted audiences come from config:

```json
"AppleAuth": {
  "Audiences": [ "com.lifelevel.app" ]
}
```

`appsettings.Development.json` already has it. Add the same block to the server's
`appsettings.json` (not in git). If it's missing, the endpoint returns 503
`apple_auth_unavailable`.

## How accounts are matched

Same as Google (`UserExternalLogins`, provider `apple`):

- A known Apple ID signs straight in. Later sign-ins don't need an email.
- A first sign-in whose email matches an existing account asks for that account's
  password before linking (409 `account_link_required`).
- Otherwise a new password-less player is created. With "Hide My Email" that email is
  Apple's private relay address.
- A first sign-in with no email at all is refused (400 `email_missing`).

## Not covered

- Android and web: Apple's button is hidden there. They would need Apple's web flow
  and a Services ID added to `Audiences`.
- The Apple logo in `assets/auth/apple_logo.svg` is a stand-in drawn to match. Before
  release, swap in the official artwork from Apple Design Resources.
