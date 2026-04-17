---
tags: [lifelevel, backend, integrations]
aliases: [Integrations Module, Strava Backend, Garmin Backend]
---
# Integrations

> Connects Life-Level to external fitness platforms: Strava (OAuth + webhooks), Garmin (OAuth 2.0 + PKCE), Health Connect batch sync. Deduplicates external activities via `ExternalActivityRecord`.

## Entities

### StravaConnection
```csharp
class StravaConnection {
  Guid Id, UserId;
  long StravaAthleteId;
  string AthleteName;
  string AccessToken, RefreshToken;  // TODO: encrypt at rest
  DateTime ExpiresAt;
  bool IsActive;
  DateTime ConnectedAt;
}
```

### GarminConnection
```csharp
class GarminConnection {
  Guid Id, UserId;
  string GarminUserId;
  string AccessToken, RefreshToken;
  DateTime ExpiresAt;
  bool IsActive;
  DateTime ConnectedAt;
}
```

### ExternalActivityRecord (dedup)
```csharp
class ExternalActivityRecord {
  Guid Id, CharacterId;
  string ExternalId;           // "strava:12345" or "healthconnect:uuid"
  string Source;               // "Strava" | "Garmin" | "HealthConnect"
  DateTime SyncedAt;
}
```

Unique constraint on `(CharacterId, Source, ExternalId)`.

## Services

### StravaOAuthService
- `GetAuthorizationUrl()` → URL for mobile to open
- `HandleCallbackAsync(userId, code)`:
  - Exchange code for tokens at `https://www.strava.com/oauth/token`
  - Fetch athlete details
  - Insert/update `StravaConnection`
  - Grant the **Strava Sync Badge** (Rare Tracker item) on first connect
  - Subscribe to webhook (lazy — only on first connect)
- `RefreshTokenAsync(userId)` — uses refresh token to get new access token

### StravaWebhookService
Handles `POST /api/integrations/strava/webhook`:
1. Verify signature.
2. Parse `{ object_type, object_id, owner_id, aspect_type }`.
3. If `aspect_type == "create"` and `object_type == "activity"`:
   - Call Strava API `GET /activities/{id}` with athlete's access token.
   - Map `sport_type` to our `ActivityType` (see [[Activity Type Mapping]]).
   - Call `IActivityLogPort.LogExternalActivityAsync(...)` with `externalId = $"strava:{id}"`.
4. Dedup: `IActivityExternalIdReadPort.FindActivityIdByExternalIdAsync` — skip if exists.

### StravaTokenRefresher
`IHostedService` that refreshes tokens nearing expiry.

### GarminOAuthService + GarminWebhookService
Same pattern as Strava but with OAuth 2.0 + PKCE (code verifier + SHA-256 challenge).

### HealthSyncService

Not a separate endpoint — called via `POST /api/integrations/sync-batch`. Accepts a batch of `ExternalActivityDto` from the mobile app (which reads from Health Connect / HealthKit), dedups, and logs each via `IActivityLogPort`.

## Deduplication

Every external activity log:
1. Check `IActivityExternalIdReadPort.FindActivityIdByExternalIdAsync(characterId, externalId)`.
2. If exists → skip.
3. Else → log via `IActivityLogPort`, insert `ExternalActivityRecord`.

Manual logs have no `ExternalId` — no conflict possible.

## Credentials

Strava **Client ID 218444**. Secrets live in `backend/src/LifeLevel.Api/appsettings.json` under `Strava:ClientId`, `Strava:ClientSecret`, `Strava:VerifyToken`. See [[Strava]] for details.

> [!warning] `appsettings.json` is dev-only. Production must use Key Vault / secret manager and encrypt the refresh/access tokens at rest.

## Ports consumed
- `IActivityLogPort`, `IActivityExternalIdReadPort`

## Endpoints
- `POST /api/integrations/strava/authorize`
- `POST /api/integrations/strava/callback`
- `GET /api/integrations/strava/status`
- `DELETE /api/integrations/strava/disconnect`
- `GET /api/integrations/strava/webhook` — Strava subscription verification
- `POST /api/integrations/strava/webhook` — activity push
- `POST /api/integrations/garmin/authorize`
- `POST /api/integrations/garmin/callback`
- `GET /api/integrations/garmin/status`
- `DELETE /api/integrations/garmin/disconnect`
- `POST /api/integrations/garmin/webhook`
- `POST /api/integrations/sync-batch` — Health Connect / HealthKit batch

## Files
- `backend/src/modules/LifeLevel.Modules.Integrations/`

## Related
- [[Strava]]
- [[Health Connect]]
- [[Garmin]]
- [[Activity Type Mapping]]
- [[Activity]] (backend)
- [[Feature - Integrations]] (mobile)
- [[Strava Webhook Registration]] (dev ops)
