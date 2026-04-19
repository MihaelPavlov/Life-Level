using LifeLevel.Modules.Notifications.Application.EventHandlers;
using LifeLevel.Modules.Notifications.Application.Ports.In;
using LifeLevel.Modules.Notifications.Application.Ports.Out;
using LifeLevel.Modules.Notifications.Application.UseCases;
using LifeLevel.Modules.Notifications.Infrastructure.Fcm;
using LifeLevel.Modules.Notifications.Infrastructure.Persistence.Repositories;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.SharedKernel.Ports;
using LifeLevel.SharedKernel.Events;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Notifications;

public static class NotificationsModule
{
    /// <summary>
    /// Registers Notifications module services: NotificationService (driving + cross-module
    /// ports share the same scoped instance), the EF repository, the FCM adapter (singleton
    /// so FirebaseApp init only happens once), and the StreakBrokenEvent handler.
    /// </summary>
    public static IServiceCollection AddNotificationsModule(this IServiceCollection services)
    {
        // UseCase — same scoped instance serves both the in-module port
        // (INotificationService, used by the controller) and the cross-module port
        // (INotificationPort, used by other modules / event handlers).
        services.AddScoped<NotificationService>();
        services.AddScoped<INotificationService>(sp => sp.GetRequiredService<NotificationService>());
        services.AddScoped<INotificationPort>(sp => sp.GetRequiredService<NotificationService>());

        // Repository
        services.AddScoped<INotificationRepository, NotificationRepository>();

        // FCM adapter — singleton because the FirebaseApp it owns is global state.
        services.AddSingleton<IFcmSender, FcmNotificationAdapter>();

        // Domain event handlers this module subscribes to.
        services.AddScoped<IEventHandler<StreakBrokenEvent>, StreakBrokenNotificationHandler>();

        return services;
    }
}
