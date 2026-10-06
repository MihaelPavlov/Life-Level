using System.Security.Cryptography;
using System.Text;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace LifeLevel.Modules.Identity.Infrastructure;

public sealed class AppleTokenVerifier(IOptions<AppleAuthOptions> options) : IAppleTokenVerifier
{
    private const string Issuer = "https://appleid.apple.com";

    // Caches Apple's signing keys and refreshes them when they rotate.
    private static readonly ConfigurationManager<OpenIdConnectConfiguration> Keys = new(
        $"{Issuer}/.well-known/openid-configuration",
        new OpenIdConnectConfigurationRetriever(),
        new HttpDocumentRetriever { RequireHttps = true });

    public async Task<AppleIdentity> VerifyAsync(
        string identityToken,
        string? rawNonce,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(identityToken))
            throw new InvalidAppleTokenException();

        var audiences = options.Value.Audiences.Where(a => !string.IsNullOrWhiteSpace(a)).ToArray();
        if (audiences.Length == 0)
            throw new AppleAuthUnavailableException();

        OpenIdConnectConfiguration config;
        try
        {
            config = await Keys.GetConfigurationAsync(ct);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or InvalidOperationException)
        {
            throw new AppleAuthUnavailableException();
        }

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(identityToken,
            new TokenValidationParameters
            {
                ValidIssuer = Issuer,
                ValidAudiences = audiences,
                IssuerSigningKeys = config.SigningKeys,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(2),
            });
        if (!result.IsValid)
        {
            // A new signing key we have not fetched yet: refresh once and let the
            // client retry.
            if (result.Exception is SecurityTokenSignatureKeyNotFoundException)
                Keys.RequestRefresh();
            throw new InvalidAppleTokenException();
        }

        var claims = result.Claims;
        var subject = claims.TryGetValue("sub", out var sub) ? sub?.ToString() : null;
        if (string.IsNullOrWhiteSpace(subject))
            throw new InvalidAppleTokenException();

        var tokenNonce = claims.TryGetValue("nonce", out var n) ? n?.ToString() : null;
        if (tokenNonce is not null || rawNonce is not null)
        {
            if (tokenNonce is null || rawNonce is null ||
                !CryptographicOperations.FixedTimeEquals(
                    Encoding.UTF8.GetBytes(tokenNonce),
                    Encoding.UTF8.GetBytes(Sha256Hex(rawNonce))))
                throw new InvalidAppleTokenException();
        }

        var email = claims.TryGetValue("email", out var e) ? e?.ToString() : null;
        var emailVerified = claims.TryGetValue("email_verified", out var ev) && IsTrue(ev);
        var isPrivate = claims.TryGetValue("is_private_email", out var pe) && IsTrue(pe);

        return new AppleIdentity(
            subject,
            !string.IsNullOrWhiteSpace(email) && emailVerified ? email : null,
            isPrivate);
    }

    // Apple sends booleans either as JSON booleans or as "true"/"false" strings.
    private static bool IsTrue(object? value) =>
        value is true || string.Equals(value?.ToString(), "true", StringComparison.OrdinalIgnoreCase);

    public static string Sha256Hex(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value))).ToLowerInvariant();
}

public sealed class InvalidAppleTokenException : Exception
{
    public InvalidAppleTokenException() : base("Apple sign-in could not be verified.") { }
}

public sealed class AppleAuthUnavailableException : Exception
{
    public AppleAuthUnavailableException() : base("Apple sign-in is not configured.") { }
}
