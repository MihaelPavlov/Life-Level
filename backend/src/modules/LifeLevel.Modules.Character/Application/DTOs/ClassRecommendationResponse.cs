namespace LifeLevel.Modules.Character.Application.DTOs;

/// <summary>Share of recent active minutes that builds toward one class.</summary>
public record ClassShareDto(Guid ClassId, string ClassName, int Minutes, double Share);

/// <summary>Workouts and minutes for one activity type in the detection window.</summary>
public record ActivityShareDto(string Type, int Workouts, int Minutes, double Share);

/// <param name="State">insufficient · devoted · multisport · hybrid · balanced · close · clear</param>
/// <param name="TraitKey">Set when the state grants a trait, e.g. "devoted:Running".</param>
/// <param name="Classes">Every active class, so the client can render picks without a second call.</param>
public record ClassRecommendationResponse(
    string State,
    Guid? RecommendedClassId,
    IReadOnlyList<Guid> AlternativeClassIds,
    string? TraitKey,
    string? DevotedActivityType,
    IReadOnlyList<ClassShareDto> Shares,
    IReadOnlyList<ActivityShareDto> Activities,
    int WorkoutCount,
    int ActiveMinutes,
    int WindowDays,
    IReadOnlyList<CharacterClassResponse> Classes);
