namespace LifeLevel.Modules.Identity.Infrastructure;

public sealed class GoogleAuthOptions
{
    public const string Section = "GoogleAuth";
    public string ServerClientId { get; set; } = string.Empty;
}
