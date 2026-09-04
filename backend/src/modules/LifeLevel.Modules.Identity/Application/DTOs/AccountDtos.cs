namespace LifeLevel.Modules.Identity.Application.DTOs;

public record AccountResponse(string Username, string Email);

public record UpdateEmailRequest(string Email, string CurrentPassword);

public record UpdateEmailResponse(string Token, string Username, string Email);

public record ChangePasswordRequest(
    string CurrentPassword,
    string NewPassword,
    string ConfirmPassword);
