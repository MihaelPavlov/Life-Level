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
