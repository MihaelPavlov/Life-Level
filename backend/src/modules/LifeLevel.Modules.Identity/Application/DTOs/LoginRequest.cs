namespace LifeLevel.Modules.Identity.Application.DTOs;

public record LoginRequest(string EmailOrUsername, string Password);
