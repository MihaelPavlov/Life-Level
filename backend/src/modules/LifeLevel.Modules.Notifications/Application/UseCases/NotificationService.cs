using LifeLevel.Modules.Notifications.Application.Ports.In;
using LifeLevel.Modules.Notifications.Application.Ports.Out;
using LifeLevel.Modules.Notifications.Domain.Entities;
using LifeLevel.Modules.Notifications.Domain.Enums;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.UseCases;

/// <summary>
/// Orchestrates push notifications: cadence policy (quiet hours + daily cap),
/// FCM dispatch, stale-token cleanup, and audit logging. Implements both the
/// module's driving port (<see cref="INotificationService"/>) and the cross-module
/// port (<see cref="INotificationPort"/>) so other modules can inject the cross-module
/// abstraction without taking a project reference to this module.
/// </summary>
public class NotificationService(
    INotificationRepository repo,
    IFcmSender fcm,
    ICurrentClock clock) : INotificationService
{
    // Quiet hours in UTC. isCritical notifications bypass this check.
    private static readonly HashSet<int> QuietHoursUtc =
        new() { 22, 23, 0, 1, 2, 3, 4, 5, 6, 7 };

    // Non-critical notifications capped per user per UTC day.
    private const int DailyCap = 3;

    public async Task<NotificationSendResult> SendToUserAsync(
        Guid userId,
        string category,
        string title,
        string body,
        IDictionary<string, string>? data = null,
        bool isCritical = false,
        CancellationToken ct = default)
    {
        var now = clock.UtcNow;

        // ── 1. Active tokens ─────────────────────────────────────────────────
        var tokens = await repo.GetActiveTokensAsync(userId, ct);
        if (tokens.Count == 0)
        {
            await LogOutcomeAsync(userId, category, title, body, isCritical,
                NotificationOutcome.NoActiveTokens, null, ct);
            return new NotificationSendResult(false, "NoActiveTokens");
        }

        // ── 2. Quiet hours (non-critical only) ───────────────────────────────
        if (!isCritical && QuietHoursUtc.Contains(now.Hour))
        {
            await LogOutcomeAsync(userId, category, title, body, isCritical,
                NotificationOutcome.SkippedQuietHours, null, ct);
            return new NotificationSendResult(false, "QuietHours");
        }

        // ── 3. Daily cap (non-critical only) ─────────────────────────────────
        if (!isCritical)
        {
            var todayStartUtc = new DateTime(now.Year, now.Month, now.Day, 0, 0, 0, DateTimeKind.Utc);
            var sentTodayCount = await repo.CountSentNonCriticalSinceAsync(userId, todayStartUtc, ct);
            if (sentTodayCount >= DailyCap)
            {
                await LogOutcomeAsync(userId, category, title, body, isCritical,
                    NotificationOutcome.SkippedDailyCap, null, ct);
                return new NotificationSendResult(false, "DailyCap");
            }
        }

        // ── 4. Dedupe ────────────────────────────────────────────────────────
        // TODO(v2): Dedupe against User.LastSeenAt — if the user opened the app in the
        // last N minutes, we know they saw the in-app state and don't need a push.
        // User.LastSeenAt does not exist in the Identity module yet (LL-020).
        // For v1 we send regardless of in-app presence.

        // ── 5. Dispatch ──────────────────────────────────────────────────────
        var anySuccess = false;
        string? lastError = null;

        foreach (var token in tokens)
        {
            var result = await fcm.SendAsync(token.Token, title, body, data, ct);

            if (result.Success)
            {
                token.LastUsedAt = now;
                anySuccess = true;
            }
            else if (result.TokenInvalid)
            {
                // FCM says the token is gone (uninstall, app data cleared). Stop trying it.
                token.IsActive = false;
                lastError = result.Error;
            }
            else
            {
                lastError = result.Error;
            }
        }

        var outcome = anySuccess ? NotificationOutcome.Sent : NotificationOutcome.FcmError;
        await LogOutcomeAsync(userId, category, title, body, isCritical,
            outcome, anySuccess ? null : lastError, ct);

        return anySuccess
            ? new NotificationSendResult(true, "Sent")
            : new NotificationSendResult(false, "FcmError");
    }

    public async Task RegisterTokenAsync(
        Guid userId,
        string token,
        DevicePlatform platform,
        CancellationToken ct = default)
    {
        var existing = await repo.FindTokenAsync(userId, token, ct);
        var now = clock.UtcNow;

        if (existing != null)
        {
            existing.LastUsedAt = now;
            existing.IsActive = true;
            existing.Platform = platform;
        }
        else
        {
            // Token moved to a different user account (rare, but possible on shared device).
            // Deactivate on any previous owner so we don't double-send.
            var others = await repo.FindTokenAcrossUsersAsync(token, ct);
            foreach (var o in others.Where(o => o.UserId != userId))
                o.IsActive = false;

            var entry = new DeviceToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Token = token,
                Platform = platform,
                RegisteredAt = now,
                LastUsedAt = now,
                IsActive = true
            };
            await repo.AddTokenAsync(entry, ct);
        }

        await repo.SaveChangesAsync(ct);
    }

    public async Task UnregisterTokenAsync(string token, CancellationToken ct = default)
    {
        var matches = await repo.FindTokenAcrossUsersAsync(token, ct);
        foreach (var m in matches)
            m.IsActive = false;
        await repo.SaveChangesAsync(ct);
    }

    private async Task LogOutcomeAsync(
        Guid userId,
        string category,
        string title,
        string body,
        bool isCritical,
        NotificationOutcome outcome,
        string? errorMessage,
        CancellationToken ct)
    {
        await repo.AddLogAsync(new NotificationLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Category = category,
            Title = title,
            Body = body,
            IsCritical = isCritical,
            SentAt = clock.UtcNow,
            Outcome = outcome,
            ErrorMessage = errorMessage
        }, ct);
        await repo.SaveChangesAsync(ct);
    }
}
