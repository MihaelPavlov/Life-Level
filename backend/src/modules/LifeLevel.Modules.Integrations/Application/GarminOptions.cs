namespace LifeLevel.Modules.Integrations.Application;

public class GarminOptions
{
    public const string Section = "Garmin";
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string WebhookVerifyToken { get; set; } = string.Empty;
}
