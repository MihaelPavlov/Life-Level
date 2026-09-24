using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>
/// Read-only activity history used while assigning adaptive tasks.
///
/// This adapter deliberately does not resolve ActivityService: that service
/// depends on IQuestProgressPort for activity writes, while QuestService needs
/// activity history for task assignment. Resolving both through each other
/// creates a circular dependency when the Rewards endpoint is opened.
/// </summary>
public sealed class TaskActivityHistoryReadAdapter(AppDbContext db) : IActivityHistoryReadPort
{
    public async Task<IReadOnlyList<ActivityRecordDto>> ListForUserBetweenAsync(
        Guid userId,
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken ct = default)
    {
        var characterId = await db.Set<Character>().AsNoTracking()
            .Where(c => c.UserId == userId)
            .Select(c => (Guid?)c.Id)
            .FirstOrDefaultAsync(ct);

        if (characterId is null)
            return Array.Empty<ActivityRecordDto>();

        return await db.Set<ActivityEntity>().AsNoTracking()
            .Where(a => a.CharacterId == characterId.Value &&
                        a.LoggedAt >= fromUtc &&
                        a.LoggedAt <= toUtc)
            .OrderByDescending(a => a.LoggedAt)
            .Select(a => new ActivityRecordDto(
                a.Id,
                a.Type.ToString(),
                a.DurationMinutes,
                a.DistanceKm,
                a.Calories,
                a.LoggedAt))
            .ToListAsync(ct);
    }
}
