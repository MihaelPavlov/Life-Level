namespace LifeLevel.Modules.Integrations.Application;

public class StravaOptions
{
    public const string Section = "Strava";
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string WebhookVerifyToken { get; set; } = string.Empty;
}
