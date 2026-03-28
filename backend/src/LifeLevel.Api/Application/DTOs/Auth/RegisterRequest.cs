using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Application.DTOs.Auth;

public record RegisterRequest(string Username, string Email, string Password, UserRole Role = UserRole.Player);
