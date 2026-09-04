namespace LifeLevel.Modules.Notifications.Domain.Enums;

public enum NotificationOutcome
{
    Sent,
    SkippedQuietHours,
    SkippedDailyCap,
    SkippedDedupe,
    SkippedPreferences,
    NoActiveTokens,
    FcmError
}
