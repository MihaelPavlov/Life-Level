namespace LifeLevel.Modules.Integrations.Application.DTOs;

public record StravaConnectRequest(string Code, string RedirectUri);

public record StravaStatusDto(
    bool IsConnected,
    string? AthleteName,
    long? AthleteId,
    DateTime? ConnectedAt);
