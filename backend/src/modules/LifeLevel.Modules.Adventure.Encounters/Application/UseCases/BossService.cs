using LifeLevel.Modules.Adventure.Encounters.Application.DTOs;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Adventure.Encounters.Application.UseCases;

// IActivityHistoryReadPort is resolved lazily via IServiceProvider rather than
// injected directly. Direct injection would form a scoped cycle:
//   BossService ← IActivityHistoryReadPort (ActivityService)
//               ← IActivityBossDamagePort (ActivityBossDamageAdapter → BossService).
// The cycle deadlocks the DI container the first time any endpoint that
// transitively needs ActivityService tries to resolve (e.g. /api/character/me,
// /api/boss). Resolving the port at method-call time breaks it.
public class BossService(
    DbContext db,
    ICharacterXpPort characterXp,
    IEventPublisher events,
    IServiceProvider services,
    IWorldZoneCompletionPort? worldZoneCompletion = null)
{
    public async Task<List<BossListItemDto>> GetAllBossesForUserAsync(Guid userId)
    {
        var bosses = await db.Set<Boss>().ToListAsync();
        // Legacy local-map bosses have NodeId set. World-zone bosses leave it null.
        var bossNodeIds = bosses
            .Where(b => b.NodeId.HasValue)
            .Select(b => b.NodeId!.Value)
            .ToList();
        var nodes = await db.Set<MapNode>()
            .Where(n => bossNodeIds.Contains(n.Id))
            .ToDictionaryAsync(n => n.Id);
        var userStates = await db.Set<UserBossState>()
            .Where(s => s.UserId == userId)
            .ToDictionaryAsync(s => s.BossId);

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId);
        var currentNodeId = progress?.CurrentNodeId;

        return bosses.Select(boss =>
        {
            MapNode? node = null;
            if (boss.NodeId.HasValue) nodes.TryGetValue(boss.NodeId.Value, out node);
            userStates.TryGetValue(boss.Id, out var state);

            // World-zone bosses: canFight is governed by WorldZone state, which
            // the bridge already enforces by only spawning the Boss row on
            // arrival. Once spawned, the user is always eligible to fight.
            var canFight = boss.WorldZoneId.HasValue
                || boss.IsMini
                || (boss.NodeId.HasValue && currentNodeId == boss.NodeId.Value);

            return new BossListItemDto
            {
                Id = boss.Id,
                Name = boss.Name,
                Icon = boss.Icon,
                MaxHp = boss.MaxHp,
                RewardXp = boss.RewardXp,
                TimerDays = boss.TimerDays,
                IsMini = boss.IsMini,
                Region = node?.Region.ToString() ?? string.Empty,
                NodeName = node?.Name ?? string.Empty,
                LevelRequirement = node?.LevelRequirement ?? 0,
                WorldZoneId = boss.WorldZoneId,
                CanFight = canFight,
                Activated = state != null,
                HpDealt = state?.HpDealt ?? 0,
                IsDefeated = state?.IsDefeated ?? false,
                IsExpired = state?.IsExpired ?? false,
                StartedAt = state?.StartedAt,
                TimerExpiresAt = boss.SuppressExpiry
                    ? null
                    : state?.StartedAt?.AddDays(boss.TimerDays),
                DefeatedAt = state?.DefeatedAt
            };
        })
        .OrderByDescending(b => b.Activated && !b.IsDefeated && !b.IsExpired) // active first
        .ThenByDescending(b => b.IsDefeated)                                   // defeated next
        .ThenBy(b => b.LevelRequirement)                                       // locked by level
        .ToList();
    }

    public async Task<UserBossState> ActivateFightAsync(Guid userId, Guid bossId)
    {
        var boss = await db.Set<Boss>().FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        // World-zone bosses don't require local-map progress — the world-zone
        // bridge is the gate. Skip the node-position check entirely.
        Guid? userMapProgressId = null;
        if (!boss.WorldZoneId.HasValue)
        {
            var progress = await db.Set<UserMapProgress>()
                .FirstOrDefaultAsync(p => p.UserId == userId)
                ?? throw new InvalidOperationException("Map progress not found.");

            if (!boss.IsMini && boss.NodeId.HasValue && progress.CurrentNodeId != boss.NodeId.Value)
                throw new InvalidOperationException("You must be at the boss node to activate the fight.");

            userMapProgressId = progress.Id;
        }

        var existing = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);

        if (existing != null)
        {
            if (existing.IsDefeated)
                throw new InvalidOperationException("Boss is already defeated.");
            if (existing.IsExpired)
                throw new InvalidOperationException("Fight has expired. Use debug reset to try again.");
            return existing;
        }

        var state = new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = bossId,
            UserMapProgressId = userMapProgressId,
            HpDealt = 0,
            IsDefeated = false,
            IsExpired = false,
            StartedAt = DateTime.UtcNow
        };

        db.Set<UserBossState>().Add(state);
        await db.SaveChangesAsync();
        return state;
    }

    public async Task<BossDamageResult> DealDamageAsync(Guid userId, Guid bossId, int damage)
    {
        var boss = await db.Set<Boss>().FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        // World-zone bosses: skip the local-map position check.
        if (!boss.WorldZoneId.HasValue)
        {
            var progress = await db.Set<UserMapProgress>()
                .FirstOrDefaultAsync(p => p.UserId == userId)
                ?? throw new InvalidOperationException("Map progress not found.");

            if (!boss.IsMini && boss.NodeId.HasValue && progress.CurrentNodeId != boss.NodeId.Value)
                throw new InvalidOperationException("You must be at the boss node to deal damage.");
        }

        var state = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId)
            ?? throw new InvalidOperationException("Fight not activated. Call /activate first.");

        if (state.IsDefeated)
            throw new InvalidOperationException("Boss is already defeated.");

        if (state.IsExpired)
            throw new InvalidOperationException("Fight has expired. Use debug reset to try again.");

        // World-zone bosses never expire (SuppressExpiry = true). Skip the
        // 7-day timer check for them.
        if (!boss.SuppressExpiry
            && state.StartedAt.HasValue
            && DateTime.UtcNow > state.StartedAt.Value.AddDays(boss.TimerDays))
        {
            state.IsExpired = true;
            await db.SaveChangesAsync();
            throw new InvalidOperationException($"Fight timer has expired ({boss.TimerDays} days elapsed).");
        }

        state.HpDealt = Math.Min(state.HpDealt + damage, boss.MaxHp);

        bool justDefeated = false;
        if (state.HpDealt >= boss.MaxHp)
        {
            state.IsDefeated = true;
            state.DefeatedAt = DateTime.UtcNow;
            justDefeated = true;
        }

        await db.SaveChangesAsync();

        if (justDefeated)
        {
            var emoji = boss.IsMini ? "👹" : "💀";
            var source = boss.IsMini ? "MiniBossDefeated" : "BossDefeated";
            await characterXp.AwardXpAsync(userId, source, emoji, $"{boss.Name} defeated", boss.RewardXp);
            await events.PublishAsync(new BossDefeatedEvent(userId, bossId));

            // World-zone bridge: complete the linked world-zone and advance to
            // the next region's entry. Port is optional so legacy tests that
            // don't wire WorldZone stay green.
            if (boss.WorldZoneId.HasValue && worldZoneCompletion != null)
            {
                await worldZoneCompletion.CompleteBossZoneAsync(userId, boss.WorldZoneId.Value);
            }
        }

        return new BossDamageResult
        {
            HpDealt = state.HpDealt,
            MaxHp = boss.MaxHp,
            IsDefeated = state.IsDefeated,
            JustDefeated = justDefeated,
            RewardXpAwarded = justDefeated ? boss.RewardXp : 0
        };
    }

    public static int CalculateDamageFromActivity(string activityType, int durationMinutes, double distanceKm, int calories)
    {
        var multiplier = activityType.ToLowerInvariant() switch
        {
            "climbing" => 1.3,
            "running"  => 1.2,
            "swimming" => 1.1,
            "gym"      => 1.0,
            "cycling"  => 1.0,
            "hiking"   => 1.0,
            "yoga"     => 0.8,
            _          => 1.0
        };

        var baseDamage = calories * 0.5 + durationMinutes * 1.0 + distanceKm * 3.0;
        return (int)(baseDamage * multiplier);
    }

    public async Task<UserBossState?> GetStateAsync(Guid userId, Guid bossId)
    {
        return await db.Set<UserBossState>()
            .Include(s => s.Boss)
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);
    }

    /// <summary>
    /// Returns the per-activity damage log for the authenticated user's current
    /// fight against <paramref name="bossId"/>. Computed on read by replaying
    /// the damage formula against every Activity logged inside the fight window
    /// (<c>UserBossState.StartedAt</c> through <c>DefeatedAt ?? now</c>). Newest
    /// first. Throws <see cref="InvalidOperationException"/> if the user has
    /// never engaged this boss.
    /// </summary>
    public async Task<IReadOnlyList<BossDamageHistoryItemDto>> GetDamageHistoryAsync(
        Guid userId, Guid bossId, CancellationToken ct = default)
    {
        var state = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId, ct)
            ?? throw new InvalidOperationException("You haven't engaged this boss.");

        // Missing StartedAt is a legacy/corrupt case — treat as "from epoch" so
        // we still return something rather than blowing up on nullable access.
        var from = state.StartedAt ?? DateTime.MinValue;
        var to = state.DefeatedAt ?? DateTime.UtcNow;

        var activityHistoryRead = services.GetService<IActivityHistoryReadPort>();
        var activities = activityHistoryRead != null
            ? await activityHistoryRead.ListForUserBetweenAsync(userId, from, to, ct)
            : (IReadOnlyList<ActivityRecordDto>)Array.Empty<ActivityRecordDto>();

        var items = new List<BossDamageHistoryItemDto>(activities.Count);
        foreach (var a in activities)
        {
            var dmg = CalculateDamageFromActivity(
                a.Type, a.DurationMinutes, a.DistanceKm, a.Calories);
            if (dmg <= 0) continue;
            items.Add(new BossDamageHistoryItemDto
            {
                ActivityId = a.Id,
                ActivityType = a.Type,
                DurationMinutes = a.DurationMinutes,
                DistanceKm = a.DistanceKm,
                Calories = a.Calories,
                Damage = dmg,
                LoggedAt = a.LoggedAt,
            });
        }
        return items;
    }

    public async Task DebugSetHpAsync(Guid userId, Guid bossId, int hp)
    {
        var boss = await db.Set<Boss>().FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var state = await EnsureStateAsync(userId, bossId);
        state.HpDealt = Math.Clamp(hp, 0, boss.MaxHp);

        bool justDefeated = false;
        if (state.HpDealt >= boss.MaxHp && !state.IsDefeated)
        {
            state.IsDefeated = true;
            state.DefeatedAt = DateTime.UtcNow;
            justDefeated = true;
        }

        await db.SaveChangesAsync();

        if (justDefeated)
        {
            var emoji = boss.IsMini ? "👹" : "💀";
            var source = boss.IsMini ? "MiniBossDefeated" : "BossDefeated";
            await characterXp.AwardXpAsync(userId, source, emoji, $"{boss.Name} defeated", boss.RewardXp);
            await events.PublishAsync(new BossDefeatedEvent(userId, bossId));

            if (boss.WorldZoneId.HasValue && worldZoneCompletion != null)
            {
                await worldZoneCompletion.CompleteBossZoneAsync(userId, boss.WorldZoneId.Value);
            }
        }
    }

    public async Task DebugForceDefeatAsync(Guid userId, Guid bossId)
    {
        var boss = await db.Set<Boss>().FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var state = await EnsureStateAsync(userId, bossId);
        bool wasAlreadyDefeated = state.IsDefeated;

        state.HpDealt = boss.MaxHp;
        state.IsDefeated = true;
        state.DefeatedAt ??= DateTime.UtcNow;
        state.IsExpired = false;

        await db.SaveChangesAsync();

        if (!wasAlreadyDefeated)
        {
            var emoji = boss.IsMini ? "👹" : "💀";
            var source = boss.IsMini ? "MiniBossDefeated" : "BossDefeated";
            await characterXp.AwardXpAsync(userId, source, emoji, $"{boss.Name} defeated", boss.RewardXp);
            await events.PublishAsync(new BossDefeatedEvent(userId, bossId));

            if (boss.WorldZoneId.HasValue && worldZoneCompletion != null)
            {
                await worldZoneCompletion.CompleteBossZoneAsync(userId, boss.WorldZoneId.Value);
            }
        }
    }

    public async Task DebugForceExpireAsync(Guid userId, Guid bossId)
    {
        var state = await EnsureStateAsync(userId, bossId);
        state.IsExpired = true;
        state.StartedAt = DateTime.UtcNow.AddDays(-100);
        await db.SaveChangesAsync();
    }

    public async Task DebugResetAsync(Guid userId, Guid bossId)
    {
        var state = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);

        if (state != null)
        {
            db.Set<UserBossState>().Remove(state);
            await db.SaveChangesAsync();
        }
    }

    private async Task<UserBossState> EnsureStateAsync(Guid userId, Guid bossId)
    {
        var existing = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);

        if (existing != null) return existing;

        var boss = await db.Set<Boss>().FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        // World-zone bosses don't need a local-map progress row. Legacy
        // bosses still do (their list-view logic uses it).
        Guid? userMapProgressId = null;
        if (!boss.WorldZoneId.HasValue)
        {
            var progress = await db.Set<UserMapProgress>()
                .FirstOrDefaultAsync(p => p.UserId == userId)
                ?? throw new InvalidOperationException("Map progress not found.");
            userMapProgressId = progress.Id;
        }

        var state = new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = bossId,
            UserMapProgressId = userMapProgressId,
            HpDealt = 0,
            StartedAt = DateTime.UtcNow,
            IsDefeated = false,
            IsExpired = false
        };

        db.Set<UserBossState>().Add(state);
        return state;
    }
}
