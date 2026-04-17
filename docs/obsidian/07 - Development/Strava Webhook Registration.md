---
tags: [lifelevel, dev, integrations]
aliases: [Webhook Subscription, Strava Subscription]
---
# Strava Webhook Registration

> Strava pushes activities to a single configured `callback_url`. The URL is the current ngrok HTTPS tunnel — which changes every session. So every time ngrok restarts, the old subscription must be deleted and a new one created.

## Known subscription ID

Last recorded subscription ID: **339240**. Update these commands if a different ID appears in responses.

## Delete the old subscription

```bash
curl -X DELETE "https://www.strava.com/api/v3/push_subscriptions/339240?client_id=218444&client_secret=<STRAVA_CLIENT_SECRET>"
```

> `<STRAVA_CLIENT_SECRET>` is in `backend/src/LifeLevel.Api/appsettings.json` under `Strava:ClientSecret`.

## Register a new subscription

```bash
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=218444 \
  -F client_secret=<STRAVA_CLIENT_SECRET> \
  -F callback_url=https://XXXX.ngrok-free.app/api/integrations/strava/webhook \
  -F verify_token=lifelevel-webhook-2026
```

Replace `XXXX` with your current ngrok subdomain. The response JSON includes the new subscription ID — update it in this note for next time.

## How Strava verifies the subscription

Strava makes a `GET` request to your `callback_url` with `hub.mode=subscribe&hub.challenge=...&hub.verify_token=...`. The backend's `StravaWebhookService`:
1. Checks `hub.verify_token == Strava:VerifyToken` (from appsettings).
2. Echoes `hub.challenge` in the response.

If that check fails, subscription creation fails.

## How activities arrive

Once subscribed, Strava POSTs to `/api/integrations/strava/webhook` within seconds of the athlete saving an activity on Strava (web, mobile, or Garmin sync). Payload:

```json
{
  "object_type": "activity",
  "object_id": 12345,
  "owner_id": 67890,
  "aspect_type": "create",
  "event_time": 1699999999
}
```

Backend workflow in [[Strava]] → "Webhook / Event handling".

## Related
- [[Strava]]
- [[Integrations]] (backend)
- [[Every-Session Startup]] (Step 4)
