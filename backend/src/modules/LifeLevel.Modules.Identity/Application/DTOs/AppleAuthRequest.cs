namespace LifeLevel.Modules.Identity.Application.DTOs;

public record AppleAuthRequest(
    string IdentityToken,
    string? Nonce = null,
    string? CurrentPassword = null);
