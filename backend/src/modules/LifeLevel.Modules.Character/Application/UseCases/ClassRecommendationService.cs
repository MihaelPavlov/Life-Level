using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Domain;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using CharacterClassEntity = LifeLevel.Modules.Character.Domain.Entities.CharacterClass;

namespace LifeLevel.Modules.Character.Application.UseCases;

/// <summary>
/// Detects the class that fits a player's recent training. Kept out of
/// <see cref="CharacterService"/> because it reads activities, and the
/// activity module already depends on the character ports.
/// </summary>
public class ClassRecommendationService(DbContext db, IActivityMixReadPort activityMix)
{
    public const int WindowDays = 30;

    public async Task<ClassDetectionResult> DetectAsync(Guid userId, CancellationToken ct = default)
    {
        var mix = await activityMix.GetRecentMixAsync(userId, DateTime.UtcNow.AddDays(-WindowDays), ct);
        return ClassDetector.Detect(mix);
    }

    public async Task<ClassRecommendationResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var mix = await activityMix.GetRecentMixAsync(userId, DateTime.UtcNow.AddDays(-WindowDays), ct);
        var result = ClassDetector.Detect(mix);

        var classes = await db.Set<CharacterClassEntity>()
            .Where(c => c.IsActive)
            .OrderBy(c => c.Name)
            .ToListAsync(ct);
        var byName = classes.ToDictionary(c => c.Name, StringComparer.OrdinalIgnoreCase);
        Guid? IdOf(string? name) => name != null && byName.TryGetValue(name, out var c) ? c.Id : null;

        var totalMinutes = Math.Max(1, result.Minutes);
        return new ClassRecommendationResponse(
            State: result.State.ToString().ToLowerInvariant(),
            RecommendedClassId: IdOf(result.RecommendedClass),
            AlternativeClassIds: result.Alternatives.Select(IdOf).OfType<Guid>().ToList(),
            TraitKey: result.TraitKey,
            DevotedActivityType: result.DevotedType?.ToString(),
            Shares: result.Groups
                .Where(g => byName.ContainsKey(g.ClassName))
                .Select(g => new ClassShareDto(byName[g.ClassName].Id, g.ClassName, g.Minutes, Math.Round(g.Share, 3)))
                .ToList(),
            Activities: mix
                .OrderByDescending(m => m.Minutes)
                .Select(m => new ActivityShareDto(m.Type.ToString(), m.Workouts, m.Minutes,
                    Math.Round((double)m.Minutes / totalMinutes, 3)))
                .ToList(),
            WorkoutCount: result.Workouts,
            ActiveMinutes: result.Minutes,
            WindowDays: WindowDays,
            Classes: classes
                .Select(c => new CharacterClassResponse(
                    c.Id, c.Name, c.Emoji, c.Description, c.Tagline,
                    c.StrMultiplier, c.EndMultiplier, c.AgiMultiplier, c.FlxMultiplier, c.StaMultiplier, c.IsHybrid))
                .ToList());
    }
}
