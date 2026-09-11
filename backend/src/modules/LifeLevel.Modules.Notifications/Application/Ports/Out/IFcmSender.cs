namespace LifeLevel.Modules.Notifications.Application.Ports.Out;

/// <summary>
/// Driven port for delivering a single push message to one device token.
/// Implemented by an FCM adapter in Infrastructure; consumed by
/// <see cref="UseCases.NotificationService"/>.
/// </summary>
public interface IFcmSender
{
    Task<FcmSendResult> SendAsync(
        string token,
        string title,
        string body,
        IDictionary<string, string>? data,
        CancellationToken ct = default);
}

/// <summary>
/// Outcome of a single FCM send attempt.
/// </summary>
/// <param name="Success">The message was accepted by FCM.</param>
/// <param name="TokenInvalid">
/// FCM reported the token as unregistered (uninstall, app data cleared) — the
/// caller should deactivate it and stop sending to it.
/// </param>
/// <param name="Error">Failure detail when <paramref name="Success"/> is false; otherwise null.</param>
public record FcmSendResult(bool Success, bool TokenInvalid, string? Error);
