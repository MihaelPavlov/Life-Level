using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using LifeLevel.Modules.Notifications.Application.Ports.Out;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace LifeLevel.Modules.Notifications.Infrastructure.Fcm;

/// <summary>
/// FirebaseAdmin SDK adapter for <see cref="IFcmSender"/>. Initializes the default
/// <see cref="FirebaseApp"/> once (thread-safe static init) using the service-account
/// JSON pointed to by config key <c>Firebase:CredentialsPath</c>, then sends one
/// message per call to <see cref="SendAsync"/>.
/// </summary>
public class FcmNotificationAdapter : IFcmSender
{
    private static readonly object InitLock = new();
    private static bool _initialized;

    private readonly ILogger<FcmNotificationAdapter> _logger;
    private readonly bool _available;

    public FcmNotificationAdapter(IConfiguration config, ILogger<FcmNotificationAdapter> logger)
    {
        _logger = logger;
        _available = EnsureInitialized(config, logger);
    }

    private static bool EnsureInitialized(IConfiguration config, ILogger logger)
    {
        if (_initialized) return FirebaseApp.DefaultInstance != null;

        lock (InitLock)
        {
            if (_initialized) return FirebaseApp.DefaultInstance != null;

            try
            {
                if (FirebaseApp.DefaultInstance != null)
                {
                    _initialized = true;
                    return true;
                }

                var credentialsPath = config["Firebase:CredentialsPath"];
                if (string.IsNullOrWhiteSpace(credentialsPath))
                {
                    logger.LogWarning("Firebase:CredentialsPath not configured — FCM disabled.");
                    _initialized = true;
                    return false;
                }

                var absolutePath = Path.IsPathRooted(credentialsPath)
                    ? credentialsPath
                    : Path.Combine(AppContext.BaseDirectory, credentialsPath);

                if (!File.Exists(absolutePath))
                {
                    logger.LogWarning(
                        "Firebase credentials file not found at {Path} — FCM disabled.",
                        absolutePath);
                    _initialized = true;
                    return false;
                }

                FirebaseApp.Create(new AppOptions
                {
                    Credential = GoogleCredential.FromFile(absolutePath)
                });
                _initialized = true;
                logger.LogInformation("FirebaseApp initialized from {Path}.", absolutePath);
                return true;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to initialize FirebaseApp — FCM disabled.");
                _initialized = true;
                return false;
            }
        }
    }

    public async Task<FcmSendResult> SendAsync(
        string token,
        string title,
        string body,
        IDictionary<string, string>? data,
        CancellationToken ct = default)
    {
        if (!_available)
            return new FcmSendResult(false, false, "FCM not initialized");

        var message = new Message
        {
            Token = token,
            Notification = new Notification
            {
                Title = title,
                Body = body
            },
            Data = data != null
                ? new Dictionary<string, string>(data)
                : null
        };

        try
        {
            await FirebaseMessaging.DefaultInstance.SendAsync(message, ct);
            return new FcmSendResult(true, false, null);
        }
        catch (FirebaseMessagingException ex)
            when (ex.MessagingErrorCode == MessagingErrorCode.Unregistered)
        {
            _logger.LogInformation(
                "FCM reported token as unregistered — will deactivate. Token prefix: {Prefix}",
                token.Length > 12 ? token[..12] : token);
            return new FcmSendResult(false, true, ex.Message);
        }
        catch (FirebaseMessagingException ex)
        {
            _logger.LogWarning(ex,
                "FCM send failed. ErrorCode={Code}", ex.MessagingErrorCode);
            return new FcmSendResult(false, false, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected FCM send error.");
            return new FcmSendResult(false, false, ex.Message);
        }
    }
}
