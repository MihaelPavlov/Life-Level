namespace LifeLevel.Modules.Identity.Infrastructure;

public sealed class AppleAuthOptions
{
    public const string Section = "AppleAuth";

    /// <summary>
    /// Accepted token audiences: the iOS bundle id, plus a Services ID if web or
    /// Android sign-in is added later.
    /// </summary>
    public string[] Audiences { get; set; } = [];
}
