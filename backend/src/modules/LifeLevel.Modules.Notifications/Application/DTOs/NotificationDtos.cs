namespace LifeLevel.Modules.Notifications.Application.DTOs;

public record RegisterTokenRequest(string Token, string Platform);

public record UnregisterTokenRequest(string Token);
