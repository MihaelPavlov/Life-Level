using Google.Apis.Auth;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using Microsoft.Extensions.Options;

namespace LifeLevel.Modules.Identity.Infrastructure;

public sealed class GoogleTokenVerifier(IOptions<GoogleAuthOptions> options) : IGoogleTokenVerifier
{
    public async Task<GoogleIdentity> VerifyAsync(string idToken, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(idToken))
            throw new InvalidGoogleTokenException();

        var clientId = options.Value.ServerClientId;
        if (string.IsNullOrWhiteSpace(clientId))
            throw new GoogleAuthUnavailableException();

        try
        {
            var payload = await GoogleJsonWebSignature.ValidateAsync(
                idToken,
                new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = [clientId]
                });

            if (string.IsNullOrWhiteSpace(payload.Subject) ||
                string.IsNullOrWhiteSpace(payload.Email) ||
                payload.EmailVerified != true)
                throw new InvalidGoogleTokenException();

            return new GoogleIdentity(
                payload.Subject,
                payload.Email,
                true,
                DateTimeOffset.FromUnixTimeSeconds(payload.IssuedAtTimeSeconds ?? 0));
        }
        catch (InvalidGoogleTokenException)
        {
            throw;
        }
        catch (Exception ex) when (ex is InvalidJwtException or ArgumentException)
        {
            throw new InvalidGoogleTokenException();
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            throw new GoogleAuthUnavailableException();
        }
    }
}

public sealed class InvalidGoogleTokenException : Exception
{
    public InvalidGoogleTokenException() : base("Google sign-in could not be verified.") { }
}

public sealed class GoogleAuthUnavailableException : Exception
{
    public GoogleAuthUnavailableException() : base("Google sign-in is not configured.") { }
}
