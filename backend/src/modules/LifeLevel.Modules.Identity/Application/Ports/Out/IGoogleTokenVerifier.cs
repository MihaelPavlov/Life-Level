namespace LifeLevel.Modules.Identity.Application.Ports.Out;

public interface IGoogleTokenVerifier
{
    Task<GoogleIdentity> VerifyAsync(string idToken, CancellationToken ct = default);
}

public sealed record GoogleIdentity(
    string Subject,
    string Email,
    bool EmailVerified,
    DateTimeOffset IssuedAt);
