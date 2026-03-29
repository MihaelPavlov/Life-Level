using LifeLevel.Modules.Adventure.Encounters.Application.DTOs;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Encounters.Application.UseCases;

public class BossService(DbContext db, ICharacterXpPort characterXp)
{
    public async Task<UserBossState> ActivateFightAsync(Guid userId, Guid bossId)
    {
        var boss = await db.Set<Boss>().FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (!boss.IsMini && progress.CurrentNodeId != boss.NodeId)
            throw new InvalidOperationException("You must be at the boss node to activate the fight.");

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
            UserMapProgressId = progress.Id,
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

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (!boss.IsMini && progress.CurrentNodeId != boss.NodeId)
            throw new InvalidOperationException("You must be at the boss node to deal damage.");

        var state = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId)
            ?? throw new InvalidOperationException("Fight not activated. Call /activate first.");

        if (state.IsDefeated)
            throw new InvalidOperationException("Boss is already defeated.");

        if (state.IsExpired)
            throw new InvalidOperationException("Fight has expired. Use debug reset to try again.");

        if (state.StartedAt.HasValue && DateTime.UtcNow > state.StartedAt.Value.AddDays(boss.TimerDays))
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

        var baseDamage = durationMinutes * 2 + distanceKm * 10 + calories / 5.0;
        return (int)(baseDamage * multiplier);
    }

    public async Task<UserBossState?> GetStateAsync(Guid userId, Guid bossId)
    {
        return await db.Set<UserBossState>()
            .Include(s => s.Boss)
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);
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

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        var state = new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = bossId,
            UserMapProgressId = progress.Id,
            HpDealt = 0,
            StartedAt = DateTime.UtcNow,
            IsDefeated = false,
            IsExpired = false
        };

        db.Set<UserBossState>().Add(state);
        return state;
    }
}
