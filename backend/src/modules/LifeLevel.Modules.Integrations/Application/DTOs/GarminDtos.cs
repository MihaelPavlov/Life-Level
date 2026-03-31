namespace LifeLevel.Modules.Integrations.Application.DTOs;

public record GarminConnectRequest(string Code, string CodeVerifier, string RedirectUri);

public record GarminStatusDto(
    bool IsConnected,
    string? DisplayName,
    string? GarminUserId,
    DateTime? ConnectedAt);
