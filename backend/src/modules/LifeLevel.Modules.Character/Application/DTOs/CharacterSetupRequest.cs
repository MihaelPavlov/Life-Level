namespace LifeLevel.Modules.Character.Application.DTOs;

/// <param name="ClassSource">How the class was chosen: "detected", "changed" or "manual". Analytics only.</param>
public record CharacterSetupRequest(Guid ClassId, string AvatarEmoji, string? ClassSource = null);
