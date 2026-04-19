using LifeLevel.Modules.Notifications.Domain.Enums;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.Ports.In;

/// <summary>
/// Driving port for the Notifications module. Extends the cross-module
/// <see cref="INotificationPort"/> (available to other modules) with device-token
/// lifecycle operations that only the HTTP controller in this module needs to call.
/// </summary>
public interface INotificationService : INotificationPort
{
    Task RegisterTokenAsync(Guid userId, string token, DevicePlatform platform, CancellationToken ct = default);
    Task UnregisterTokenAsync(string token, CancellationToken ct = default);
}
