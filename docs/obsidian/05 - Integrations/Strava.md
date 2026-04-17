---
tags: [lifelevel, integrations]
aliases: [Strava OAuth, Strava Webhook]
---
# Strava

> OAuth 2.0 + real-time webhook. Activities are pushed from Strava to our backend within seconds of the athlete saving them.

## Developer app

- **Client ID:** 218444
- **Client Secret + Verify Token:** live in `backend/src/LifeLevel.Api/appsettings.json` under `Strava:*` keys (dev-only — git-ignored).
- **Redirect URI:** `lifelevel://oauth/strava`
- **Scopes:** `read,activity:read,activity:read_all`

## OAuth flow

1. User taps "Connect Strava" in [[Feature - Integrations]].
2. App opens `https://www.strava.com/oauth/authorize?client_id=218444&scope=...&redirect_uri=lifelevel://oauth/strava&response_type=code` via `url_launcher`.
3. User approves on the Strava page → Strava redirects to `lifelevel://oauth/strava?code=...`.
4. `AppLinks` delivers the URL to `MainShell._handleDeepLink`.
5. `MainShell._handleStravaCallback(code)` calls `StravaService.connect(code)`.
6. Backend (`StravaOAuthService.HandleCallbackAsync`):
   - `POST https://www.strava.com/oauth/token` with `code + client_id + client_secret` to exchange for tokens.
   - Stores `access_token, refresh_token, expires_at, athlete_id, athlete_name` in `StravaConnection`.
   - **Grants Strava Sync Badge** (Rare Tracker item) on first connect.
   - On first connect globally: subscribes to the webhook (lazy).

## Webhook

### Subscription

Strava pushes new activities to `POST {ngrok_url}/api/integrations/strava/webhook`.

Subscription registration (one-time per ngrok session — see [[Strava Webhook Registration]]):

```bash
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=218444 \
  -F client_secret=<secret> \
  -F callback_url=<https-ngrok-url>/api/integrations/strava/webhook \
  -F verify_token=<VERIFY_TOKEN_FROM_APPSETTINGS>
```

### Event handling

`StravaWebhookService`:
1. On `GET`: verify token handshake (echoes `hub.challenge`).
2. On `POST`: parse `{ object_type, object_id, owner_id, aspect_type }`.
3. If `aspect_type == "create"` and `object_type == "activity"`:
   - Fetch athlete's `StravaConnection` by `owner_id`.
   - `GET https://www.strava.com/api/v3/activities/{object_id}` with athlete's access token.
   - Map Strava `sport_type` → our [[Activity Type Mapping|ActivityType]].
   - Call `IActivityLogPort.LogExternalActivityAsync` with `externalId = "strava:{id}"`.
   - Dedup via `IActivityExternalIdReadPort.FindActivityIdByExternalIdAsync` — skip if already logged.

## Token refresh

`StravaTokenRefresher` (IHostedService) scans `StravaConnection` rows and refreshes tokens nearing expiry (< 1 hour) via `POST /oauth/token` with `refresh_token`.

## Disconnect

`DELETE /api/integrations/strava/disconnect`:
1. Mark `IsActive = false`.
2. Delete athlete access (optional: `POST https://www.strava.com/oauth/deauthorize`).

## Known fixed bugs (2026-04-02)

- ✅ Missing `redirect_uri` in token exchange
- ✅ Double deep-link fire on cold launch (fixed with `launchMode="singleTop"` + `taskAffinity=""`)
- ✅ App navigating away from Integrations mid-OAuth
- ✅ Unique-index crash on reconnecting same Strava account

## Related
- [[Integrations]] (backend module)
- [[Feature - Integrations]] (mobile)
- [[Strava Webhook Registration]]
- [[Activity Type Mapping]]
- [[Routing and Deep Links]]
- [[Items]] (Strava Sync Badge)
