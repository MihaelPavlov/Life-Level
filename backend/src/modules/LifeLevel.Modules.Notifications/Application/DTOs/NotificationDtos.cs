namespace LifeLevel.Modules.Notifications.Application.DTOs;

public record RegisterTokenRequest(string Token, string Platform);

public record UnregisterTokenRequest(string Token);

public record NotificationItemDto(
    Guid Id,
    string Title,
    string Body,
    string Category,
    string? DeepLink,
    DateTime CreatedAt,
    bool IsRead
);

public record NotificationPreferencesDto(
    bool PushEnabled,
    bool LevelUpEnabled,
    bool QuestEnabled,
    bool BossEnabled,
    bool StreakEnabled,
    bool RankEnabled,
    bool QuietHoursEnabled,
    int QuietHoursStartUtc,
    int QuietHoursEndUtc);

public record UpdateNotificationPreferencesRequest(
    bool PushEnabled,
    bool LevelUpEnabled,
    bool QuestEnabled,
    bool BossEnabled,
    bool StreakEnabled,
    bool RankEnabled,
    bool QuietHoursEnabled,
    int QuietHoursStartUtc,
    int QuietHoursEndUtc);
