# Real-time deployment

The API uses PostgreSQL for game state. SignalR sends refresh hints through a Redis-compatible backplane when `REDIS_URL` is set. Single-instance local development works without it.

1. In Render, create a **Key Value** service in the same region as the API. Use its internal URL for the API's `REDIS_URL` environment variable. Keep PostgreSQL configured as `ConnectionStrings__DefaultConnection`.
2. Set `SignalR__ChannelPrefix` to a distinct value for each environment, such as `lifelevel-production`. Deploy the API and let its startup migrations finish before increasing the instance count.
3. Release the Flutter client with WebSockets-only SignalR and skipped negotiation. Older clients still negotiate and may fail behind Render's multi-instance load balancer, so scale the API only after the client update is in use.
4. Increase the Render API instance count. Validate that a mutation handled by one instance updates a client connected to another. Disconnect and reconnect the client, then check that its current guild group and pending state are restored.

PostgreSQL advisory locks coordinate migrations, seeders, and the four scheduled jobs. The daily reset records its completed UTC date in PostgreSQL so a restart cannot run it twice. Render Key Value is transient transport; a client reconciles from PostgreSQL on launch, foreground resume, and reconnect. The app still uses Firebase Cloud Messaging for background notifications.
