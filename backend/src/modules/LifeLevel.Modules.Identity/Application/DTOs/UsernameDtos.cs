namespace LifeLevel.Modules.Identity.Application.DTOs;

public record ChooseUsernameRequest(string Username);

public record ChooseUsernameResponse(string Token, string Username);

/// <param name="Reason">Why it can't be used, when <paramref name="Available"/> is false.</param>
public record UsernameAvailabilityResponse(bool Available, string? Reason);
