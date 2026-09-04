using LifeLevel.Modules.Notifications.Application.Ports.In;
using LifeLevel.Modules.Notifications.Application.Ports.Out;
using LifeLevel.Modules.Notifications.Application.DTOs;
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
        var preferences = await EnsurePreferencesAsync(userId, ct);

        if (!ShouldSendCategory(preferences, category, isCritical))
        {
            await LogOutcomeAsync(userId, category, title, body, isCritical,
                NotificationOutcome.SkippedPreferences, null, ct);
            return new NotificationSendResult(false, "Preferences");
        }

        // ── 1. Active tokens ─────────────────────────────────────────────────
        var tokens = await repo.GetActiveTokensAsync(userId, ct);
        if (tokens.Count == 0)
        {
            await LogOutcomeAsync(userId, category, title, body, isCritical,
                NotificationOutcome.NoActiveTokens, null, ct);
            return new NotificationSendResult(false, "NoActiveTokens");
        }

        // ── 2. Quiet hours (non-critical only) ───────────────────────────────
        if (!isCritical &&
            preferences.QuietHoursEnabled &&
            IsQuietHour(now.Hour, preferences.QuietHoursStartUtc, preferences.QuietHoursEndUtc))
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
        var now = clock.UtcNow;

        // IX_DeviceTokens_Token is unique on Token, so at most one row per token.
        // Reassign ownership on re-registration (same user or device moved accounts)
        // instead of inserting a new row, which would violate the unique constraint.
        var existing = (await repo.FindTokenAcrossUsersAsync(token, ct)).FirstOrDefault();

        if (existing != null)
        {
            existing.UserId = userId;
            existing.Platform = platform;
            existing.LastUsedAt = now;
            existing.IsActive = true;
        }
        else
        {
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

    public Task<List<NotificationLog>> GetNotificationsAsync(Guid userId, CancellationToken ct = default) =>
        repo.GetForUserAsync(userId, 50, ct);

    public Task MarkAllReadAsync(Guid userId, CancellationToken ct = default) =>
        repo.MarkAllReadAsync(userId, ct);

    public async Task<NotificationPreferencesDto> GetPreferencesAsync(
        Guid userId,
        CancellationToken ct = default) =>
        ToDto(await EnsurePreferencesAsync(userId, ct));

    public async Task<NotificationPreferencesDto> UpdatePreferencesAsync(
        Guid userId,
        UpdateNotificationPreferencesRequest req,
        CancellationToken ct = default)
    {
        ValidateHour(req.QuietHoursStartUtc, nameof(req.QuietHoursStartUtc));
        ValidateHour(req.QuietHoursEndUtc, nameof(req.QuietHoursEndUtc));

        var preferences = await EnsurePreferencesAsync(userId, ct);
        preferences.PushEnabled = req.PushEnabled;
        preferences.LevelUpEnabled = req.LevelUpEnabled;
        preferences.QuestEnabled = req.QuestEnabled;
        preferences.BossEnabled = req.BossEnabled;
        preferences.StreakEnabled = req.StreakEnabled;
        preferences.RankEnabled = req.RankEnabled;
        preferences.QuietHoursEnabled = req.QuietHoursEnabled;
        preferences.QuietHoursStartUtc = req.QuietHoursStartUtc;
        preferences.QuietHoursEndUtc = req.QuietHoursEndUtc;
        preferences.UpdatedAt = clock.UtcNow;

        await repo.SaveChangesAsync(ct);
        return ToDto(preferences);
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

    private async Task<NotificationPreference> EnsurePreferencesAsync(
        Guid userId,
        CancellationToken ct)
    {
        var preferences = await repo.GetPreferencesAsync(userId, ct);
        if (preferences != null) return preferences;

        preferences = new NotificationPreference
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            UpdatedAt = clock.UtcNow
        };
        await repo.AddPreferencesAsync(preferences, ct);
        await repo.SaveChangesAsync(ct);
        return preferences;
    }

    private static NotificationPreferencesDto ToDto(NotificationPreference p) =>
        new(
            p.PushEnabled,
            p.LevelUpEnabled,
            p.QuestEnabled,
            p.BossEnabled,
            p.StreakEnabled,
            p.RankEnabled,
            p.QuietHoursEnabled,
            p.QuietHoursStartUtc,
            p.QuietHoursEndUtc);

    private static bool ShouldSendCategory(
        NotificationPreference p,
        string category,
        bool isCritical)
    {
        if (!p.PushEnabled) return false;
        if (isCritical) return true;

        return NormalizeCategory(category) switch
        {
            "levelup" => p.LevelUpEnabled,
            "quest" => p.QuestEnabled,
            "boss" => p.BossEnabled,
            "streak" => p.StreakEnabled,
            "rank" => p.RankEnabled,
            _ => true,
        };
    }

    private static string NormalizeCategory(string category)
    {
        var lower = category.ToLowerInvariant().Replace("_", "-");
        if (lower.Contains("level")) return "levelup";
        if (lower.Contains("quest")) return "quest";
        if (lower.Contains("boss")) return "boss";
        if (lower.Contains("streak")) return "streak";
        if (lower.Contains("rank")) return "rank";
        return lower;
    }

    private static bool IsQuietHour(int hour, int start, int end)
    {
        if (start == end) return false;
        return start < end
            ? hour >= start && hour < end
            : hour >= start || hour < end;
    }

    private static void ValidateHour(int hour, string name)
    {
        if (hour is < 0 or > 23)
            throw new InvalidOperationException($"{name} must be between 0 and 23.");
    }
}
