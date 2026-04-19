namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Result of a notification send attempt. The caller can inspect Sent + Reason to tell
/// whether the notification was actually delivered to FCM, was suppressed by policy
/// (quiet hours / daily cap / dedupe), or could not be delivered (no active tokens /
/// FCM error).
/// </summary>
/// <param name="Sent">True if at least one FCM message was dispatched successfully.</param>
/// <param name="Reason">Short machine-readable reason code:
/// "Sent", "QuietHours", "DailyCap", "Dedupe", "NoActiveTokens", "FcmError".</param>
public record NotificationSendResult(bool Sent, string Reason);

/// <summary>
/// Cross-module port for triggering a push notification to a user. All side-modules
/// (Streak, Quest, Boss, XP storms, etc.) depend on this port — never on the
/// concrete Notifications module. The Notifications module applies cadence rules
/// (quiet hours, daily cap, dedupe) before actually sending to FCM.
/// </summary>
public interface INotificationPort
{
    Task<NotificationSendResult> SendToUserAsync(
        Guid userId,
        string category,
        string title,
        string body,
        IDictionary<string, string>? data = null,
        bool isCritical = false,
        CancellationToken ct = default);
}
