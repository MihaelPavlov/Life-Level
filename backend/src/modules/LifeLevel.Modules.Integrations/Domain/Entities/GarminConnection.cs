namespace LifeLevel.Modules.Integrations.Domain.Entities;

public class GarminConnection
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string GarminUserId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; }
    public DateTime ConnectedAt { get; set; }
}
