namespace LifeLevel.Modules.Identity.Application.Ports.Out;

public interface IAppleTokenVerifier
{
    /// <summary>
    /// Verifies an Apple identity token. <paramref name="rawNonce"/> is the nonce
    /// the app generated; Apple puts its SHA-256 in the token.
    /// </summary>
    Task<AppleIdentity> VerifyAsync(string identityToken, string? rawNonce, CancellationToken ct = default);
}

/// <summary>
/// <see cref="Email"/> can be null when the person shared no email, and is a
/// private relay address when they chose "Hide My Email".
/// </summary>
public sealed record AppleIdentity(
    string Subject,
    string? Email,
    bool IsPrivateEmail);
