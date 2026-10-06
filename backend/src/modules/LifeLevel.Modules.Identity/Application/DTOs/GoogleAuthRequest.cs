namespace LifeLevel.Modules.Identity.Application.DTOs;

public record GoogleAuthRequest(string IdToken, string? CurrentPassword = null);

public record SetPasswordWithGoogleRequest(
    string GoogleIdToken,
    string NewPassword,
    string ConfirmPassword);
