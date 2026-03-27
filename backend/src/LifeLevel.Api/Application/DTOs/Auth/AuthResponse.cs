namespace LifeLevel.Api.Application.DTOs.Auth;

public record AuthResponse(string Token, string Username, Guid CharacterId);
