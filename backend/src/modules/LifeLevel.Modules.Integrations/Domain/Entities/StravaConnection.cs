namespace LifeLevel.Modules.Integrations.Domain.Entities;

public class StravaConnection
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public long StravaAthleteId { get; set; }
    public string AthleteName { get; set; } = string.Empty;
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; }
    public DateTime ConnectedAt { get; set; }
}
