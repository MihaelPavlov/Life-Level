using LifeLevel.Modules.Identity.Domain.Enums;

namespace LifeLevel.Modules.Identity.Application.DTOs;

public record RegisterRequest(string Username, string Email, string Password, UserRole Role = UserRole.Player);
