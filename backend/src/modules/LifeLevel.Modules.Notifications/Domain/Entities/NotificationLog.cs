using LifeLevel.Modules.Notifications.Domain.Enums;

namespace LifeLevel.Modules.Notifications.Domain.Entities;

/// <summary>
/// Audit record of every notification decision for a user. Rows are written for both
/// successful sends and policy-suppressed attempts (quiet hours, daily cap, etc.) so
/// the cadence logic can inspect recent history.
/// </summary>
public class NotificationLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Category { get; set; } = null!;
    public string Title { get; set; } = null!;
    public string Body { get; set; } = null!;
    public bool IsCritical { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public NotificationOutcome Outcome { get; set; }
    public string? ErrorMessage { get; set; }
}
