using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class BossService(AppDbContext db, CharacterService characterService)
{
    /// <summary>
    /// Activate the fight when the player arrives at the boss node.
    /// Creates UserBossState with StartedAt = now if one doesn't exist.
    /// Zone check: player must be at the boss node.
    /// </summary>
    public async Task<UserBossState> ActivateFightAsync(Guid userId, Guid bossId)
    {
        var boss = await db.Bosses.FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var progress = await db.UserMapProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (!boss.IsMini && progress.CurrentNodeId != boss.NodeId)
            throw new InvalidOperationException("You must be at the boss node to activate the fight.");

        var existing = await db.UserBossStates
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

        db.UserBossStates.Add(state);
        await db.SaveChangesAsync();
        return state;
    }

    /// <summary>
    /// Deal explicit damage to the boss. Zone check enforced.
    /// Automatically resolves defeat + awards XP when HP is depleted.
    /// Also checks timer expiration on each call.
    /// </summary>
    public async Task<BossDamageResult> DealDamageAsync(Guid userId, Guid bossId, int damage)
    {
        var boss = await db.Bosses.FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var progress = await db.UserMapProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (!boss.IsMini && progress.CurrentNodeId != boss.NodeId)
            throw new InvalidOperationException("You must be at the boss node to deal damage.");

        var state = await db.UserBossStates
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
        Character? defeatedCharacter = null;
        if (state.HpDealt >= boss.MaxHp)
        {
            state.IsDefeated = true;
            state.DefeatedAt = DateTime.UtcNow;
            justDefeated = true;

            defeatedCharacter = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
            if (defeatedCharacter != null)
            {
                defeatedCharacter.Xp += boss.RewardXp;
                defeatedCharacter.UpdatedAt = DateTime.UtcNow;
            }
        }

        await db.SaveChangesAsync();

        bool leveledUp = false;
        int newLevel = 0;
        if (justDefeated && defeatedCharacter != null)
        {
            var emoji = boss.IsMini ? "👹" : "💀";
            var source = boss.IsMini ? "MiniBossDefeated" : "BossDefeated";
            (leveledUp, newLevel) = await characterService.RecordXpAsync(defeatedCharacter, source, emoji, $"{boss.Name} defeated", boss.RewardXp);
        }

        return new BossDamageResult
        {
            HpDealt = state.HpDealt,
            MaxHp = boss.MaxHp,
            IsDefeated = state.IsDefeated,
            JustDefeated = justDefeated,
            RewardXpAwarded = justDefeated ? boss.RewardXp : 0,
            LeveledUp = leveledUp,
            NewLevel = newLevel
        };
    }

    /// <summary>
    /// Calculate damage from activity parameters.
    /// Formula: (durationMinutes * 2 + distanceKm * 10 + calories / 5) * activityMultiplier
    /// </summary>
    public static int CalculateDamageFromActivity(string activityType, int durationMinutes, double distanceKm, int calories)
    {
        var multiplier = activityType.ToLowerInvariant() switch
        {
            "climbing" => 1.3,
            "running" => 1.2,
            "swimming" => 1.1,
            "gym" => 1.0,
            "cycling" => 1.0,
            "hiking" => 1.0,
            "yoga" => 0.8,
            _ => 1.0
        };

        var baseDamage = durationMinutes * 2 + distanceKm * 10 + calories / 5.0;
        return (int)(baseDamage * multiplier);
    }

    public async Task<UserBossState?> GetStateAsync(Guid userId, Guid bossId)
    {
        return await db.UserBossStates
            .Include(s => s.Boss)
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);
    }

    // ── Debug methods ──────────────────────────────────────────────────────────

    /// <summary>Debug: set HpDealt directly. No zone check. Auto-defeats if hp >= MaxHp.</summary>
    public async Task DebugSetHpAsync(Guid userId, Guid bossId, int hp)
    {
        var boss = await db.Bosses.FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var state = await EnsureStateAsync(userId, bossId);
        state.HpDealt = Math.Clamp(hp, 0, boss.MaxHp);

        bool justDefeated = false;
        Character? defeatedCharacter = null;
        if (state.HpDealt >= boss.MaxHp && !state.IsDefeated)
        {
            state.IsDefeated = true;
            state.DefeatedAt = DateTime.UtcNow;
            justDefeated = true;

            defeatedCharacter = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
            if (defeatedCharacter != null)
            {
                defeatedCharacter.Xp += boss.RewardXp;
                defeatedCharacter.UpdatedAt = DateTime.UtcNow;
            }
        }

        await db.SaveChangesAsync();

        if (justDefeated && defeatedCharacter != null)
        {
            var emoji = boss.IsMini ? "👹" : "💀";
            var source = boss.IsMini ? "MiniBossDefeated" : "BossDefeated";
            await characterService.RecordXpAsync(defeatedCharacter, source, emoji, $"{boss.Name} defeated", boss.RewardXp);
        }
    }

    /// <summary>Debug: immediately defeat the boss and award XP.</summary>
    public async Task DebugForceDefeatAsync(Guid userId, Guid bossId)
    {
        var boss = await db.Bosses.FindAsync(bossId)
            ?? throw new InvalidOperationException("Boss not found.");

        var state = await EnsureStateAsync(userId, bossId);
        bool wasAlreadyDefeated = state.IsDefeated;

        state.HpDealt = boss.MaxHp;
        state.IsDefeated = true;
        state.DefeatedAt ??= DateTime.UtcNow;
        state.IsExpired = false;

        Character? defeatedCharacter = null;
        if (!wasAlreadyDefeated)
        {
            defeatedCharacter = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
            if (defeatedCharacter != null)
            {
                defeatedCharacter.Xp += boss.RewardXp;
                defeatedCharacter.UpdatedAt = DateTime.UtcNow;
            }
        }

        await db.SaveChangesAsync();

        if (!wasAlreadyDefeated && defeatedCharacter != null)
        {
            var emoji = boss.IsMini ? "👹" : "💀";
            var source = boss.IsMini ? "MiniBossDefeated" : "BossDefeated";
            await characterService.RecordXpAsync(defeatedCharacter, source, emoji, $"{boss.Name} defeated", boss.RewardXp);
        }
    }

    /// <summary>Debug: force the fight timer to expire.</summary>
    public async Task DebugForceExpireAsync(Guid userId, Guid bossId)
    {
        var state = await EnsureStateAsync(userId, bossId);
        state.IsExpired = true;
        state.StartedAt = DateTime.UtcNow.AddDays(-100);
        await db.SaveChangesAsync();
    }

    /// <summary>Debug: reset boss state completely so the fight can be re-activated.</summary>
    public async Task DebugResetAsync(Guid userId, Guid bossId)
    {
        var state = await db.UserBossStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);

        if (state != null)
        {
            db.UserBossStates.Remove(state);
            await db.SaveChangesAsync();
        }
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private async Task<UserBossState> EnsureStateAsync(Guid userId, Guid bossId)
    {
        var existing = await db.UserBossStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId);

        if (existing != null) return existing;

        var progress = await db.UserMapProgresses
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

        db.UserBossStates.Add(state);
        return state;
    }
}

public class BossDamageResult
{
    public int HpDealt { get; set; }
    public int MaxHp { get; set; }
    public bool IsDefeated { get; set; }
    public bool JustDefeated { get; set; }
    public int RewardXpAwarded { get; set; }
    public bool LeveledUp { get; set; }
    public int NewLevel { get; set; }
}
