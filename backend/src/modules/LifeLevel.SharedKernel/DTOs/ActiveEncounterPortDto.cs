namespace LifeLevel.SharedKernel.DTOs;

/// <summary>
/// Encounter result returned by IWorldZoneDistancePort so the Activity module
/// can thread it back to the mobile client without referencing WorldZone DTOs.
/// </summary>
public record ActiveEncounterPortDto(
    Guid TemplateId,
    string Type,
    string Name,
    string Emoji
);
