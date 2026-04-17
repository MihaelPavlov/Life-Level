---
tags: [lifelevel, integrations]
aliases: [Garmin OAuth, Garmin PKCE]
---
# Garmin

> OAuth 2.0 with PKCE (Proof Key for Code Exchange). Similar shape to [[Strava]] but with an extra code-verifier / code-challenge exchange.

> [!warning] PKCE SHA-256 code challenge is **not yet fully implemented**. The `GarminService.generateCodeChallenge` currently falls back to plain text because the `crypto` package isn't in `pubspec.yaml`. Garmin may reject plain challenges.

## Flow

1. Client generates a **code verifier** (cryptographic random string, 43–128 chars, URL-safe).
2. Client computes **code challenge** = `BASE64URL(SHA256(verifier))`.
   - Current fallback: plain text (TODO: add `crypto` package).
3. Open authorization URL: `https://connect.garmin.com/oauth2Confirm?client_id=X&redirect_uri=lifelevel://oauth/garmin&response_type=code&code_challenge=X&code_challenge_method=S256`.
4. User approves → Garmin redirects to `lifelevel://oauth/garmin?code=...`.
5. `MainShell._handleGarminCallback(code, codeVerifier)` calls `GarminService.connect(code, codeVerifier)`.
6. Backend (`GarminOAuthService.HandleCallbackAsync`):
   - `POST https://connect.garmin.com/oauth2/token` with `{ code, code_verifier, client_id, client_secret, grant_type: authorization_code }`.
   - Stores tokens in `GarminConnection`.

## Credentials

In `appsettings.json` under `Garmin:*` keys. Not publicly published here.

## Webhook

Similar pattern to Strava — `GarminWebhookService` receives push notifications and ingests activities via `IActivityLogPort`.

## Files

- Mobile: `lib/features/integrations/services/garmin_service.dart`
- Backend: `LifeLevel.Modules.Integrations/Application/UseCases/GarminOAuthService.cs`, `GarminWebhookService.cs`

## Related
- [[Integrations]] (backend)
- [[Feature - Integrations]] (mobile)
- [[Strava]] (similar OAuth pattern)
- [[Activity Type Mapping]]
- [[Known Issues]]
- [[Dependencies]] (missing `crypto` package)
