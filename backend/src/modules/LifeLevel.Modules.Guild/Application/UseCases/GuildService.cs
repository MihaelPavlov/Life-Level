using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Guild.Application.DTOs;
using LifeLevel.Modules.Guild.Domain.Entities;
using LifeLevel.Modules.Guild.Domain.Enums;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using LifeLevel.SharedKernel.Events;
using Microsoft.EntityFrameworkCore;
using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;
using XpHistoryEntryEntity = LifeLevel.Modules.Character.Domain.Entities.XpHistoryEntry;

namespace LifeLevel.Modules.Guild.Application.UseCases;

public class GuildService(
    DbContext db,
    ICharacterXpPort characterXp,
    IGuildRaidRealtimePort realtime,
    INotificationPort notifications,
    ITalentBonusReadPort? talentBonus = null,
    ICharacterCombatStatsReadPort? combatStats = null,
    IEventPublisher? events = null)
    : IGuildRaidActivityPort, IGuildRaidMaintenancePort
{
    private const int DefaultMaxMembers = 5;
    private const int MiniRaidDurationDays = 1;
    private const int NormalRaidDurationDays = 3;
    private const int MajorRaidDurationDays = 7;

    public async Task<GuildDetailDto?> GetMineAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (member == null) return null;

        await RepairMissingRewardsAsync(member.GuildId, ct);
        return await BuildGuildDetailAsync(member.GuildId, userId, ct);
    }

    public async Task<GuildDetailDto> CreateAsync(Guid userId, GuildCreateRequest request, CancellationToken ct = default)
    {
        var name = request.Name.Trim();
        if (name.Length is < 3 or > 60)
            throw new InvalidOperationException("Guild name must be between 3 and 60 characters.");

        var alreadyMember = await db.Set<GuildMember>().AnyAsync(m => m.UserId == userId, ct);
        if (alreadyMember)
            throw new InvalidOperationException("You are already in a guild.");

        var guild = new Domain.Entities.Guild
        {
            Id = Guid.NewGuid(),
            Name = name,
            Description = (request.Description ?? string.Empty).Trim(),
            Icon = string.IsNullOrWhiteSpace(request.Icon) ? "shield" : request.Icon.Trim(),
            OwnerUserId = userId,
            MaxMembers = DefaultMaxMembers,
            IsOpen = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };

        db.Set<Domain.Entities.Guild>().Add(guild);
        db.Set<GuildMember>().Add(new GuildMember
        {
            Id = Guid.NewGuid(),
            GuildId = guild.Id,
            UserId = userId,
            Role = GuildMemberRole.Leader,
            JoinedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);

        return (await BuildGuildDetailAsync(guild.Id, userId, ct))!;
    }

    public async Task<IReadOnlyList<GuildSearchItemDto>> SearchAsync(string? query, int skip, int take, CancellationToken ct = default)
    {
        take = Math.Clamp(take, 1, 30);
        skip = Math.Max(0, skip);
        var q = (query ?? string.Empty).Trim().ToLowerInvariant();

        var rows = await db.Set<Domain.Entities.Guild>()
            .AsNoTracking()
            .Where(g => g.IsOpen && (q == string.Empty || g.Name.ToLower().Contains(q)))
            .OrderBy(g => g.Name)
            .Skip(skip)
            .Take(take)
            .Select(g => new
            {
                g.Id,
                g.Name,
                g.Description,
                g.Icon,
                g.MaxMembers,
                g.IsOpen,
                MemberCount = g.Members.Count
            })
            .ToListAsync(ct);

        return rows.Select(g => new GuildSearchItemDto(
            g.Id, g.Name, g.Description, g.Icon, g.MemberCount, g.MaxMembers, g.IsOpen)).ToList();
    }

    public async Task<GuildDetailDto> UpdateAsync(Guid userId, GuildUpdateRequest request, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        if (member.Role != GuildMemberRole.Leader)
            throw new InvalidOperationException("Only the guild owner can edit the guild.");

        var guild = await db.Set<Domain.Entities.Guild>()
            .FirstOrDefaultAsync(g => g.Id == member.GuildId && g.OwnerUserId == userId, ct)
            ?? throw new InvalidOperationException("Only the guild owner can edit the guild.");

        var name = request.Name.Trim();
        if (name.Length is < 3 or > 60)
            throw new InvalidOperationException("Guild name must be between 3 and 60 characters.");

        guild.Name = name;
        guild.Description = (request.Description ?? string.Empty).Trim();
        guild.Icon = string.IsNullOrWhiteSpace(request.Icon) ? "shield" : request.Icon.Trim();
        guild.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return (await BuildGuildDetailAsync(guild.Id, userId, ct))!;
    }

    public async Task<GuildDetailDto> JoinAsync(Guid userId, Guid guildId, CancellationToken ct = default)
    {
        var alreadyMember = await db.Set<GuildMember>().AnyAsync(m => m.UserId == userId, ct);
        if (alreadyMember)
            throw new InvalidOperationException("You are already in a guild.");

        var guild = await db.Set<Domain.Entities.Guild>()
            .Include(g => g.Members)
            .FirstOrDefaultAsync(g => g.Id == guildId, ct)
            ?? throw new InvalidOperationException("Guild not found.");

        if (!guild.IsOpen)
            throw new InvalidOperationException("Guild is closed.");
        if (guild.Members.Count >= guild.MaxMembers)
            throw new InvalidOperationException("Guild is full.");

        db.Set<GuildMember>().Add(new GuildMember
        {
            Id = Guid.NewGuid(),
            GuildId = guild.Id,
            UserId = userId,
            Role = GuildMemberRole.Member,
            JoinedAt = DateTime.UtcNow,
        });
        guild.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        await NotifyGuildMembersAsync(
            guild.Id,
            "guild-member-joined",
            "New guild member",
            $"{await UsernameAsync(userId, ct)} joined {guild.Name}.",
            new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://guild",
                ["guildId"] = guild.Id.ToString()
            },
            excludeUserId: userId,
            ct: ct);

        return (await BuildGuildDetailAsync(guild.Id, userId, ct))!;
    }

    public async Task LeaveAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        if (member.Role == GuildMemberRole.Leader)
            throw new InvalidOperationException("The guild owner cannot leave. Delete the guild instead.");

        var guildId = member.GuildId;
        db.Set<GuildMember>().Remove(member);
        await db.SaveChangesAsync(ct);

        var remaining = await db.Set<GuildMember>()
            .Where(m => m.GuildId == guildId)
            .OrderBy(m => m.JoinedAt)
            .ToListAsync(ct);

        if (remaining.Count == 0)
        {
            var guild = await db.Set<Domain.Entities.Guild>().FindAsync([guildId], ct);
            if (guild != null) db.Set<Domain.Entities.Guild>().Remove(guild);
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task DeleteAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");

        if (member.Role != GuildMemberRole.Leader)
            throw new InvalidOperationException("Only the guild owner can delete the guild.");

        var guild = await db.Set<Domain.Entities.Guild>()
            .FirstOrDefaultAsync(g => g.Id == member.GuildId && g.OwnerUserId == userId, ct)
            ?? throw new InvalidOperationException("Only the guild owner can delete the guild.");

        var raidIds = await db.Set<GuildRaid>()
            .Where(r => r.GuildId == guild.Id)
            .Select(r => r.Id)
            .ToListAsync(ct);
        if (raidIds.Count > 0)
        {
            var contributions = await db.Set<GuildRaidContribution>()
                .Where(c => raidIds.Contains(c.GuildRaidId))
                .ToListAsync(ct);
            db.Set<GuildRaidContribution>().RemoveRange(contributions);

            var acknowledgements = await db.Set<GuildRaidVictoryAcknowledgement>()
                .Where(a => raidIds.Contains(a.GuildRaidId))
                .ToListAsync(ct);
            db.Set<GuildRaidVictoryAcknowledgement>().RemoveRange(acknowledgements);

            var expiryAcknowledgements = await db.Set<GuildRaidExpiryAcknowledgement>()
                .Where(a => raidIds.Contains(a.GuildRaidId))
                .ToListAsync(ct);
            db.Set<GuildRaidExpiryAcknowledgement>().RemoveRange(expiryAcknowledgements);

            var raids = await db.Set<GuildRaid>()
                .Where(r => r.GuildId == guild.Id)
                .ToListAsync(ct);
            db.Set<GuildRaid>().RemoveRange(raids);
        }

        var members = await db.Set<GuildMember>()
            .Where(m => m.GuildId == guild.Id)
            .ToListAsync(ct);
        db.Set<GuildMember>().RemoveRange(members);
        db.Set<Domain.Entities.Guild>().Remove(guild);
        await db.SaveChangesAsync(ct);
    }

    public async Task KickAsync(Guid leaderUserId, Guid guildId, Guid targetUserId, CancellationToken ct = default)
    {
        if (leaderUserId == targetUserId)
            throw new InvalidOperationException("Leader must leave the guild instead.");

        var actor = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.UserId == leaderUserId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        if (actor.GuildId != guildId)
            throw new InvalidOperationException("Guild not found.");
        if (!CanManageMembers(actor.Role))
            throw new InvalidOperationException("Only guild leaders and officers can remove members.");

        var target = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.GuildId == actor.GuildId && m.UserId == targetUserId, ct)
            ?? throw new InvalidOperationException("Member not found.");
        if (target.Role == GuildMemberRole.Leader)
            throw new InvalidOperationException("The guild owner cannot be removed.");
        if (actor.Role == GuildMemberRole.Officer && target.Role != GuildMemberRole.Member)
            throw new InvalidOperationException("Officers can only remove members.");
        var guildName = await db.Set<Domain.Entities.Guild>()
            .AsNoTracking()
            .Where(g => g.Id == actor.GuildId)
            .Select(g => g.Name)
            .FirstOrDefaultAsync(ct) ?? "your guild";

        db.Set<GuildMember>().Remove(target);
        await db.SaveChangesAsync(ct);

        await notifications.SendToUserAsync(
            targetUserId,
            "guild-member-kicked",
            "Removed from guild",
            $"You were removed from {guildName}.",
            new Dictionary<string, string> { ["deeplink"] = "lifelevel://guild" },
            isCritical: true,
            ct: ct);
    }

    public async Task<GuildDetailDto> UpdateMemberRoleAsync(
        Guid leaderUserId,
        Guid guildId,
        Guid targetUserId,
        GuildRoleUpdateRequest request,
        CancellationToken ct = default)
    {
        if (leaderUserId == targetUserId)
            throw new InvalidOperationException("Ownership is not transferable.");

        var leader = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.UserId == leaderUserId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        if (leader.GuildId != guildId || leader.Role != GuildMemberRole.Leader)
            throw new InvalidOperationException("Only the guild owner can change member roles.");

        var target = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.GuildId == guildId && m.UserId == targetUserId, ct)
            ?? throw new InvalidOperationException("Member not found.");
        if (target.Role == GuildMemberRole.Leader)
            throw new InvalidOperationException("Ownership is not transferable.");

        target.Role = ParseAssignableRole(request.Role);
        await db.SaveChangesAsync(ct);

        return (await BuildGuildDetailAsync(guildId, leaderUserId, ct))!;
    }

    public async Task<IReadOnlyList<GuildRaidBossDto>> GetRaidBossesAsync(CancellationToken ct = default)
    {
        return await db.Set<Boss>()
            .AsNoTracking()
            .OrderBy(b => b.IsMini)
            .ThenBy(b => b.MaxHp)
            .Take(12)
            .Select(b => new GuildRaidBossDto(b.Id, b.Name, b.Icon, b.MaxHp, b.RewardXp, b.TimerDays, b.IsMini))
            .ToListAsync(ct);
    }

    public async Task<GuildRaidDto> StartRaidAsync(Guid userId, Guid bossId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        if (!CanManageRaid(member.Role))
            throw new InvalidOperationException("Only guild leaders and officers can start raids.");

        var hasActive = await db.Set<GuildRaid>()
            .AnyAsync(r => r.GuildId == member.GuildId && !r.IsDefeated && !r.IsExpired && r.ExpiresAt > DateTime.UtcNow, ct);
        if (hasActive)
            throw new InvalidOperationException("Your guild already has an active raid.");

        var boss = await db.Set<Boss>().FindAsync([bossId], ct)
            ?? throw new InvalidOperationException("Raid boss not found.");
        var guildSize = await db.Set<GuildMember>().CountAsync(m => m.GuildId == member.GuildId, ct);
        var maxHp = ScaledRaidMaxHp(boss.MaxHp, guildSize);
        var rewardXp = ScaledRaidRewardXp(boss.RewardXp, guildSize);
        var durationDays = RaidDurationDaysFor(boss);

        var now = DateTime.UtcNow;
        var raid = new GuildRaid
        {
            Id = Guid.NewGuid(),
            GuildId = member.GuildId,
            BossId = boss.Id,
            StartedByUserId = userId,
            StartedAt = now,
            ExpiresAt = now.AddDays(durationDays),
            MaxHp = maxHp,
            RewardXp = rewardXp,
            GuildSizeAtStart = guildSize,
            TotalDamage = 0,
            IsDefeated = false,
            IsExpired = false,
        };

        db.Set<GuildRaid>().Add(raid);
        await db.SaveChangesAsync(ct);

        await realtime.RaidStartedAsync(new GuildRaidStartedInfo(
            raid.GuildId,
            raid.Id,
            boss.Name,
            boss.Icon,
            maxHp,
            rewardXp,
            raid.ExpiresAt), ct);

        await NotifyGuildMembersAsync(
            raid.GuildId,
            "guild-raid-started",
            "Guild raid started",
            $"{boss.Name} is active. Log workouts to damage the raid boss.",
            new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://guild",
                ["guildId"] = raid.GuildId.ToString(),
                ["guildRaidId"] = raid.Id.ToString()
            },
            excludeUserId: userId,
            ct: ct);

        return await BuildRaidDtoAsync(raid.Id, ct) ?? throw new InvalidOperationException("Raid could not be loaded.");
    }

    public async Task<GuildRaidDto?> GetActiveRaidAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>().AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (member == null) return null;
        var raid = await GetActiveRaidEntityAsync(member.GuildId, ct);
        return raid == null ? null : await BuildRaidDtoAsync(raid.Id, ct);
    }

    public async Task<IReadOnlyList<GuildRaidDto>> GetRaidHistoryAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>().AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (member == null) return [];

        var ids = await db.Set<GuildRaid>()
            .AsNoTracking()
            .Where(r => r.GuildId == member.GuildId && (r.IsDefeated || r.IsExpired || r.ExpiresAt <= DateTime.UtcNow))
            .OrderByDescending(r => r.StartedAt)
            .Take(10)
            .Select(r => r.Id)
            .ToListAsync(ct);

        var list = new List<GuildRaidDto>();
        foreach (var id in ids)
        {
            var dto = await BuildRaidDtoAsync(id, ct);
            if (dto != null) list.Add(dto);
        }
        return list;
    }

    public async Task<IReadOnlyList<GuildRaidDefeatedInfo>> GetPendingVictoryAcknowledgementsAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (member == null) return [];

        var raidIds = await db.Set<GuildRaid>()
            .AsNoTracking()
            .Where(raid => raid.GuildId == member.GuildId
                           && raid.IsDefeated
                           && !raid.IsExpired
                           && raid.DefeatedAt != null
                           && raid.DefeatedAt >= member.JoinedAt
                           && !db.Set<GuildRaidVictoryAcknowledgement>()
                               .Any(a => a.GuildRaidId == raid.Id && a.UserId == userId))
            .OrderBy(raid => raid.DefeatedAt)
            .Take(5)
            .Select(raid => raid.Id)
            .ToListAsync(ct);

        var victories = new List<GuildRaidDefeatedInfo>();
        foreach (var raidId in raidIds)
        {
            var victory = await BuildVictoryInfoAsync(raidId, userId, ct);
            if (victory != null) victories.Add(victory);
        }

        return victories;
    }

    public async Task AcknowledgeVictoryAsync(Guid userId, Guid guildRaidId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");

        var canAcknowledge = await db.Set<GuildRaid>()
            .AsNoTracking()
            .AnyAsync(r => r.Id == guildRaidId
                           && r.GuildId == member.GuildId
                           && r.IsDefeated
                           && !r.IsExpired
                           && r.DefeatedAt != null
                           && r.DefeatedAt >= member.JoinedAt, ct);
        if (!canAcknowledge)
            throw new InvalidOperationException("Raid victory not found.");

        var exists = await db.Set<GuildRaidVictoryAcknowledgement>()
            .AnyAsync(a => a.GuildRaidId == guildRaidId && a.UserId == userId, ct);
        if (exists) return;

        db.Set<GuildRaidVictoryAcknowledgement>().Add(new GuildRaidVictoryAcknowledgement
        {
            Id = Guid.NewGuid(),
            GuildRaidId = guildRaidId,
            UserId = userId,
            AcknowledgedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<GuildRaidExpiredInfo>> GetPendingExpiryAcknowledgementsAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (member == null) return [];

        var raidIds = await db.Set<GuildRaid>()
            .AsNoTracking()
            .Where(raid => raid.GuildId == member.GuildId
                           && raid.IsExpired
                           && !raid.IsDefeated
                           && raid.ExpiresAt >= member.JoinedAt
                           && !db.Set<GuildRaidExpiryAcknowledgement>()
                               .Any(a => a.GuildRaidId == raid.Id && a.UserId == userId))
            .OrderBy(raid => raid.ExpiresAt)
            .Take(5)
            .Select(raid => raid.Id)
            .ToListAsync(ct);

        var expiries = new List<GuildRaidExpiredInfo>();
        foreach (var raidId in raidIds)
        {
            var expired = await BuildExpiredInfoAsync(raidId, ct);
            if (expired != null) expiries.Add(expired);
        }

        return expiries;
    }

    public async Task AcknowledgeExpiryAsync(Guid userId, Guid guildRaidId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>()
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");

        var canAcknowledge = await db.Set<GuildRaid>()
            .AsNoTracking()
            .AnyAsync(r => r.Id == guildRaidId
                           && r.GuildId == member.GuildId
                           && r.IsExpired
                           && !r.IsDefeated
                           && r.ExpiresAt >= member.JoinedAt, ct);
        if (!canAcknowledge)
            throw new InvalidOperationException("Raid expiry not found.");

        var exists = await db.Set<GuildRaidExpiryAcknowledgement>()
            .AnyAsync(a => a.GuildRaidId == guildRaidId && a.UserId == userId, ct);
        if (exists) return;

        db.Set<GuildRaidExpiryAcknowledgement>().Add(new GuildRaidExpiryAcknowledgement
        {
            Id = Guid.NewGuid(),
            GuildRaidId = guildRaidId,
            UserId = userId,
            AcknowledgedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<GuildRaidDefeatedInfo>> ApplyActivityAsync(
        Guid userId,
        Guid activityId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>().AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (member == null) return [];

        var raid = await GetActiveRaidEntityAsync(member.GuildId, ct);
        if (raid == null) return [];
        if (activityLoggedAt < raid.StartedAt) return [];

        var damage = BossService.CalculateDamageFromActivity(activityType, durationMinutes, distanceKm, calories);
        if (damage <= 0) return [];

        // Power-based multiplier (Attack/Defense/Health, including the
        // permanent talent BossDamagePct baked into Attack — see
        // CombatStatsCalculator). Applied before the still-separate,
        // contextual BossActiveDamagePct below, which only fires because a
        // raid is active here by definition.
        if (combatStats is not null)
        {
            var stats = await combatStats.GetCombatStatsAsync(userId, ct);
            damage = (int)Math.Round(damage * stats.DamageMultiplier);
        }

        if (talentBonus is not null)
        {
            var talents = await talentBonus.GetBonusesAsync(userId, ct);
            if (talents.BossActiveDamagePct > 0)
                damage = (int)Math.Round(damage * (1.0 + talents.BossActiveDamagePct / 100.0));
        }

        return await ApplyDamageAsync(userId, raid, damage, activityId, activityLoggedAt, ct);
    }

    public async Task<IReadOnlyList<GuildRaidDefeatedInfo>> DebugAddDamageAsync(Guid userId, int damage, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>().AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        var raid = await GetActiveRaidEntityAsync(member.GuildId, ct)
            ?? throw new InvalidOperationException("No active raid.");

        return await ApplyDamageAsync(userId, raid, damage, null, DateTime.UtcNow, ct);
    }

    public async Task ForceExpireAsync(Guid userId, CancellationToken ct = default)
    {
        var member = await db.Set<GuildMember>().AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct)
            ?? throw new InvalidOperationException("You are not in a guild.");
        var raid = await GetActiveRaidEntityAsync(member.GuildId, ct)
            ?? throw new InvalidOperationException("No active raid.");
        await ExpireRaidAsync(raid, DateTime.UtcNow, ct);
    }

    public async Task<int> ExpireOverdueRaidsAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var raids = await db.Set<GuildRaid>()
            .Where(r => !r.IsDefeated && !r.IsExpired && r.ExpiresAt <= now)
            .ToListAsync(ct);

        foreach (var raid in raids)
        {
            await ExpireRaidAsync(raid, raid.ExpiresAt, ct);
        }

        return raids.Count;
    }

    private async Task<IReadOnlyList<GuildRaidDefeatedInfo>> ApplyDamageAsync(
        Guid userId,
        GuildRaid raid,
        int damage,
        Guid? activityId,
        DateTime activityLoggedAt,
        CancellationToken ct)
    {
        var boss = await db.Set<Boss>().FindAsync([raid.BossId], ct)
            ?? throw new InvalidOperationException("Raid boss not found.");
        var maxHp = RaidMaxHp(raid, boss);

        if (raid.ExpiresAt <= DateTime.UtcNow)
        {
            await ExpireRaidAsync(raid, raid.ExpiresAt, ct);
            return [];
        }

        var contribution = await db.Set<GuildRaidContribution>()
            .FirstOrDefaultAsync(c => c.GuildRaidId == raid.Id && c.UserId == userId, ct);
        if (contribution == null)
        {
            contribution = new GuildRaidContribution
            {
                Id = Guid.NewGuid(),
                GuildRaidId = raid.Id,
                UserId = userId,
            };
            db.Set<GuildRaidContribution>().Add(contribution);
        }

        var effectiveDamage = Math.Min(damage, Math.Max(0, maxHp - raid.TotalDamage));
        if (effectiveDamage <= 0) return [];

        contribution.DamageDealt += effectiveDamage;
        contribution.LastActivityId = activityId;
        contribution.LastActivityAt = activityLoggedAt;
        raid.TotalDamage = Math.Min(maxHp, raid.TotalDamage + effectiveDamage);

        var defeated = false;
        if (raid.TotalDamage >= maxHp && !raid.IsDefeated)
        {
            defeated = true;
            raid.IsDefeated = true;
            raid.DefeatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync(ct);

        if (events != null && activityId.HasValue)
            await events.PublishAsync(new GuildRaidContributionEvent(userId, raid.Id, activityId.Value), ct);

        await realtime.RaidHpUpdatedAsync(new GuildRaidHpUpdatedInfo(
            raid.GuildId,
            raid.Id,
            boss.Name,
            boss.Icon,
            maxHp,
            raid.TotalDamage,
            Math.Max(0, maxHp - raid.TotalDamage),
            userId,
            effectiveDamage,
            contribution.DamageDealt), ct);

        if (!defeated) return [];

        if (events != null)
        {
            var contributorIds = await db.Set<GuildRaidContribution>().AsNoTracking()
                .Where(c => c.GuildRaidId == raid.Id && c.DamageDealt > 0)
                .Select(c => c.UserId).ToListAsync(ct);
            foreach (var contributorId in contributorIds)
                await events.PublishAsync(new GuildRaidWonEvent(contributorId, raid.Id), ct);
        }

        await GrantScaledRaidRewardsAsync(raid, boss, ct);
        var victory = await BuildVictoryInfoAsync(raid.Id, userId, ct)
            ?? new GuildRaidDefeatedInfo(
                raid.GuildId,
                raid.Id,
                boss.Name,
                boss.Icon,
                RaidRewardXp(raid, boss),
                MvpBonusXp(RaidRewardXp(raid, boss)),
                null,
                0,
                contribution.DamageDealt,
                raid.TotalDamage);
        await realtime.RaidDefeatedAsync(victory, ct);
        return [victory];
    }

    private async Task GrantRaidRewardsAsync(GuildRaid raid, Boss boss, CancellationToken ct)
    {
        if (!raid.IsDefeated || raid.IsExpired) return;

        var members = await db.Set<GuildMember>()
            .AsNoTracking()
            .Where(m => m.GuildId == raid.GuildId)
            .Select(m => m.UserId)
            .ToListAsync(ct);

        var baseDescription = $"{boss.Name} guild raid defeated";
        foreach (var memberId in members)
        {
            if (!await HasXpHistoryAsync(memberId, "GuildRaid", baseDescription, ct))
            {
                await characterXp.AwardXpAsync(memberId, "GuildRaid", "🛡️", baseDescription, boss.RewardXp, ct);
            }
        }

        var top = await db.Set<GuildRaidContribution>()
            .AsNoTracking()
            .Where(c => c.GuildRaidId == raid.Id)
            .OrderByDescending(c => c.DamageDealt)
            .FirstOrDefaultAsync(ct);
        if (top != null)
        {
            var bonus = MvpBonusXp(boss.RewardXp);
            var mvpDescription = $"{boss.Name} top contributor";
            if (!await HasXpHistoryAsync(top.UserId, "GuildRaidMvp", mvpDescription, ct))
            {
                await characterXp.AwardXpAsync(top.UserId, "GuildRaidMvp", "🏆", mvpDescription, bonus, ct);
            }
        }

        raid.RewardClaimedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    private static int MvpBonusXp(int rewardXp) => Math.Max(1, (int)Math.Round(rewardXp * 0.25));

    private async Task GrantScaledRaidRewardsAsync(GuildRaid raid, Boss boss, CancellationToken ct)
    {
        if (!raid.IsDefeated || raid.IsExpired) return;
        if (raid.RewardClaimedAt != null) return;

        var contributors = await db.Set<GuildRaidContribution>()
            .AsNoTracking()
            .Where(c => c.GuildRaidId == raid.Id && c.DamageDealt > 0)
            .Select(c => c.UserId)
            .ToListAsync(ct);

        var rewardXp = RaidRewardXp(raid, boss);
        var baseDescription = $"{boss.Name} guild raid defeated";
        foreach (var memberId in contributors)
        {
            if (!await HasXpHistoryAsync(memberId, "GuildRaid", baseDescription, ct))
            {
                await characterXp.AwardXpAsync(memberId, "GuildRaid", "guild", baseDescription, rewardXp, ct);
            }
        }

        var top = await db.Set<GuildRaidContribution>()
            .AsNoTracking()
            .Where(c => c.GuildRaidId == raid.Id && c.DamageDealt > 0)
            .OrderByDescending(c => c.DamageDealt)
            .ThenBy(c => c.LastActivityAt ?? DateTime.MaxValue)
            .ThenBy(c => c.UserId)
            .FirstOrDefaultAsync(ct);
        if (top != null)
        {
            var bonus = MvpBonusXp(rewardXp);
            var mvpDescription = $"{boss.Name} top contributor";
            if (!await HasXpHistoryAsync(top.UserId, "GuildRaidMvp", mvpDescription, ct))
            {
                await characterXp.AwardXpAsync(top.UserId, "GuildRaidMvp", "mvp", mvpDescription, bonus, ct);
            }
        }

        raid.RewardClaimedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        await NotifyGuildMembersAsync(
            raid.GuildId,
            "guild-raid-defeated",
            "Guild raid cleared",
            $"{boss.Name} was defeated. Contributors earned {rewardXp} XP.",
            new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://guild",
                ["guildId"] = raid.GuildId.ToString(),
                ["guildRaidId"] = raid.Id.ToString()
            },
            isCritical: true,
            ct: ct);
    }

    private static int ScaledRaidMaxHp(int baseHp, int guildSize) =>
        Math.Max(1, (int)Math.Round(baseHp * RaidScaleMultiplier(guildSize)));

    private static int ScaledRaidRewardXp(int baseRewardXp, int guildSize)
    {
        var multiplier = RaidScaleMultiplier(guildSize);
        return Math.Max(1, (int)Math.Round(baseRewardXp * (1 + ((multiplier - 1) * 0.35))));
    }

    private static double RaidScaleMultiplier(int guildSize) =>
        0.75 + (Math.Clamp(guildSize, 1, DefaultMaxMembers) * 0.35);

    private static int RaidDurationDaysFor(Boss boss)
    {
        if (boss.IsMini) return MiniRaidDurationDays;
        if (boss.WorldZoneId.HasValue) return MajorRaidDurationDays;
        return NormalRaidDurationDays;
    }

    private static int RaidMaxHp(GuildRaid raid, Boss boss) => raid.MaxHp > 0 ? raid.MaxHp : boss.MaxHp;

    private static int RaidRewardXp(GuildRaid raid, Boss boss) => raid.RewardXp > 0 ? raid.RewardXp : boss.RewardXp;

    private async Task RepairMissingRewardsAsync(Guid guildId, CancellationToken ct)
    {
        var raids = await db.Set<GuildRaid>()
            .Where(r => r.GuildId == guildId && r.IsDefeated && !r.IsExpired)
            .OrderByDescending(r => r.DefeatedAt)
            .Take(5)
            .ToListAsync(ct);

        foreach (var raid in raids)
        {
            var boss = await db.Set<Boss>().FindAsync([raid.BossId], ct);
            if (boss != null) await GrantScaledRaidRewardsAsync(raid, boss, ct);
        }
    }

    private async Task<bool> HasXpHistoryAsync(Guid userId, string source, string description, CancellationToken ct)
    {
        var characterId = await db.Set<CharacterEntity>()
            .Where(c => c.UserId == userId)
            .Select(c => (Guid?)c.Id)
            .FirstOrDefaultAsync(ct);
        if (characterId == null) return true;

        return await db.Set<XpHistoryEntryEntity>()
            .AnyAsync(x => x.CharacterId == characterId
                           && x.Source == source
                           && x.Description == description, ct);
    }

    private async Task<GuildRaidDefeatedInfo?> BuildVictoryInfoAsync(
        Guid raidId,
        Guid viewerUserId,
        CancellationToken ct)
    {
        var raid = await db.Set<GuildRaid>().AsNoTracking().FirstOrDefaultAsync(r => r.Id == raidId, ct);
        if (raid == null) return null;
        var boss = await db.Set<Boss>().AsNoTracking().FirstOrDefaultAsync(b => b.Id == raid.BossId, ct);
        if (boss == null) return null;

        var top = await (
            from contribution in db.Set<GuildRaidContribution>().AsNoTracking()
            join user in db.Set<User>().AsNoTracking() on contribution.UserId equals user.Id
            where contribution.GuildRaidId == raid.Id && contribution.DamageDealt > 0
            orderby contribution.DamageDealt descending, contribution.LastActivityAt, contribution.UserId
            select new { user.Username, contribution.DamageDealt }).FirstOrDefaultAsync(ct);

        var yourDamage = await db.Set<GuildRaidContribution>()
            .AsNoTracking()
            .Where(c => c.GuildRaidId == raid.Id && c.UserId == viewerUserId)
            .Select(c => (int?)c.DamageDealt)
            .FirstOrDefaultAsync(ct) ?? 0;

        return new GuildRaidDefeatedInfo(
            raid.GuildId,
            raid.Id,
            boss.Name,
            boss.Icon,
            RaidRewardXp(raid, boss),
            MvpBonusXp(RaidRewardXp(raid, boss)),
            top?.Username,
            top?.DamageDealt ?? 0,
            yourDamage,
            raid.TotalDamage);
    }

    private async Task<GuildRaidExpiredInfo?> BuildExpiredInfoAsync(Guid raidId, CancellationToken ct)
    {
        var raid = await db.Set<GuildRaid>().AsNoTracking().FirstOrDefaultAsync(r => r.Id == raidId, ct);
        if (raid == null) return null;
        var boss = await db.Set<Boss>().AsNoTracking().FirstOrDefaultAsync(b => b.Id == raid.BossId, ct);
        if (boss == null) return null;

        var maxHp = RaidMaxHp(raid, boss);
        return new GuildRaidExpiredInfo(
            raid.GuildId,
            raid.Id,
            boss.Name,
            boss.Icon,
            maxHp,
            raid.TotalDamage,
            Math.Max(0, maxHp - raid.TotalDamage));
    }

    private async Task<GuildRaidExpiredInfo?> ExpireRaidAsync(
        GuildRaid raid,
        DateTime expiresAt,
        CancellationToken ct)
    {
        if (raid.IsExpired || raid.IsDefeated) return await BuildExpiredInfoAsync(raid.Id, ct);

        raid.IsExpired = true;
        raid.ExpiresAt = expiresAt;
        await db.SaveChangesAsync(ct);

        var expired = await BuildExpiredInfoAsync(raid.Id, ct);
        if (expired != null) await realtime.RaidExpiredAsync(expired, ct);
        var boss = await db.Set<Boss>().AsNoTracking().FirstOrDefaultAsync(b => b.Id == raid.BossId, ct);
        if (boss != null)
        {
            await NotifyGuildMembersAsync(
                raid.GuildId,
                "guild-raid-expired",
                "Guild raid expired",
                $"{boss.Name} expired with {Math.Max(0, RaidMaxHp(raid, boss) - raid.TotalDamage)} HP left.",
                new Dictionary<string, string>
                {
                    ["deeplink"] = "lifelevel://guild",
                    ["guildId"] = raid.GuildId.ToString(),
                    ["guildRaidId"] = raid.Id.ToString()
                },
                isCritical: true,
                ct: ct);
        }
        return expired;
    }

    private async Task<GuildRaid?> GetActiveRaidEntityAsync(Guid guildId, CancellationToken ct)
    {
        var raid = await db.Set<GuildRaid>()
            .Where(r => r.GuildId == guildId && !r.IsDefeated && !r.IsExpired)
            .OrderByDescending(r => r.StartedAt)
            .FirstOrDefaultAsync(ct);

        if (raid != null && raid.ExpiresAt <= DateTime.UtcNow)
        {
            await ExpireRaidAsync(raid, raid.ExpiresAt, ct);
            return null;
        }

        return raid;
    }

    private async Task<GuildDetailDto?> BuildGuildDetailAsync(Guid guildId, Guid viewerUserId, CancellationToken ct)
    {
        var guild = await db.Set<Domain.Entities.Guild>()
            .AsNoTracking()
            .FirstOrDefaultAsync(g => g.Id == guildId, ct);
        if (guild == null) return null;

        var activeRaid = await GetActiveRaidEntityAsync(guildId, ct);
        var activeRaidId = activeRaid?.Id;
        var members = await BuildMemberDtosAsync(guildId, activeRaidId, ct);
        var viewerRole = await db.Set<GuildMember>()
            .AsNoTracking()
            .Where(m => m.GuildId == guildId && m.UserId == viewerUserId)
            .Select(m => (GuildMemberRole?)m.Role)
            .FirstOrDefaultAsync(ct) ?? GuildMemberRole.Member;
        var isLeader = viewerRole == GuildMemberRole.Leader;

        return new GuildDetailDto(
            guild.Id,
            guild.Name,
            guild.Description,
            guild.Icon,
            members.Count,
            guild.MaxMembers,
            guild.IsOpen,
            isLeader,
            viewerRole.ToString(),
            CanManageRaid(viewerRole),
            CanManageMembers(viewerRole),
            isLeader,
            members,
            activeRaidId.HasValue ? await BuildRaidDtoAsync(activeRaidId.Value, ct) : null);
    }

    private async Task<IReadOnlyList<GuildMemberDto>> BuildMemberDtosAsync(Guid guildId, Guid? activeRaidId, CancellationToken ct)
    {
        var rows = await (
            from member in db.Set<GuildMember>().AsNoTracking()
            join user in db.Set<User>().AsNoTracking() on member.UserId equals user.Id
            join character in db.Set<CharacterEntity>().AsNoTracking() on member.UserId equals character.UserId into characterJoin
            from character in characterJoin.DefaultIfEmpty()
            where member.GuildId == guildId
            orderby member.Role, member.JoinedAt
            select new
            {
                member.UserId,
                user.Username,
                AvatarEmoji = character == null ? string.Empty : character.AvatarEmoji,
                member.Role,
                member.JoinedAt
            }).ToListAsync(ct);

        var damage = activeRaidId.HasValue
            ? await db.Set<GuildRaidContribution>()
                .AsNoTracking()
                .Where(c => c.GuildRaidId == activeRaidId.Value)
                .ToDictionaryAsync(c => c.UserId, c => c.DamageDealt, ct)
            : new Dictionary<Guid, int>();

        return rows.Select(r => new GuildMemberDto(
            r.UserId,
            r.Username,
            string.IsNullOrWhiteSpace(r.AvatarEmoji) ? "hero" : r.AvatarEmoji!,
            r.Role.ToString(),
            r.JoinedAt,
            damage.GetValueOrDefault(r.UserId))).ToList();
    }

    private async Task<GuildRaidDto?> BuildRaidDtoAsync(Guid raidId, CancellationToken ct)
    {
        var raid = await db.Set<GuildRaid>().AsNoTracking().FirstOrDefaultAsync(r => r.Id == raidId, ct);
        if (raid == null) return null;
        var boss = await db.Set<Boss>().AsNoTracking().FirstOrDefaultAsync(b => b.Id == raid.BossId, ct);
        if (boss == null) return null;

        var contributionRows = await (
            from contribution in db.Set<GuildRaidContribution>().AsNoTracking()
            join user in db.Set<User>().AsNoTracking() on contribution.UserId equals user.Id
            join character in db.Set<CharacterEntity>().AsNoTracking() on contribution.UserId equals character.UserId into characterJoin
            from character in characterJoin.DefaultIfEmpty()
            where contribution.GuildRaidId == raid.Id
            orderby contribution.DamageDealt descending, contribution.LastActivityAt, contribution.UserId
            select new
            {
                contribution.UserId,
                user.Username,
                AvatarEmoji = character == null || character.AvatarEmoji == null ? "hero" : character.AvatarEmoji,
                contribution.DamageDealt,
                contribution.LastActivityAt
            }).ToListAsync(ct);

        var mvp = contributionRows.FirstOrDefault(r => r.DamageDealt > 0);
        var rows = contributionRows.Select((row, index) => new GuildRaidContributionDto(
            row.UserId,
            row.Username,
            row.AvatarEmoji,
            row.DamageDealt,
            row.LastActivityAt,
            index + 1,
            mvp != null && row.UserId == mvp.UserId)).ToList();

        var maxHp = RaidMaxHp(raid, boss);
        var rewardXp = RaidRewardXp(raid, boss);
        return new GuildRaidDto(
            raid.Id,
            boss.Id,
            boss.Name,
            boss.Icon,
            maxHp,
            boss.MaxHp,
            rewardXp,
            boss.RewardXp,
            raid.GuildSizeAtStart > 0 ? raid.GuildSizeAtStart : 1,
            raid.StartedAt,
            raid.ExpiresAt,
            raid.TotalDamage,
            raid.IsDefeated,
            raid.IsExpired || raid.ExpiresAt <= DateTime.UtcNow,
            raid.DefeatedAt,
            raid.RewardClaimedAt,
            raid.RewardClaimedAt != null,
            mvp?.UserId,
            mvp?.Username,
            mvp?.DamageDealt ?? 0,
            MvpBonusXp(rewardXp),
            rows);
    }

    private static bool CanManageRaid(GuildMemberRole role) =>
        role is GuildMemberRole.Leader or GuildMemberRole.Officer;

    private static bool CanManageMembers(GuildMemberRole role) =>
        role is GuildMemberRole.Leader or GuildMemberRole.Officer;

    private static GuildMemberRole ParseAssignableRole(string? role)
    {
        if (!Enum.TryParse<GuildMemberRole>((role ?? string.Empty).Trim(), ignoreCase: true, out var parsed))
            throw new InvalidOperationException("Unknown guild role.");
        if (parsed == GuildMemberRole.Leader)
            throw new InvalidOperationException("Ownership is not transferable.");
        return parsed;
    }

    private async Task NotifyGuildMembersAsync(
        Guid guildId,
        string category,
        string title,
        string body,
        IDictionary<string, string> data,
        Guid? excludeUserId = null,
        bool isCritical = false,
        CancellationToken ct = default)
    {
        var memberIds = await db.Set<GuildMember>()
            .AsNoTracking()
            .Where(m => m.GuildId == guildId && (!excludeUserId.HasValue || m.UserId != excludeUserId.Value))
            .Select(m => m.UserId)
            .ToListAsync(ct);

        foreach (var memberId in memberIds)
        {
            await notifications.SendToUserAsync(memberId, category, title, body, data, isCritical, ct);
        }
    }

    private async Task<string> UsernameAsync(Guid userId, CancellationToken ct)
    {
        return await db.Set<User>()
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.Username)
            .FirstOrDefaultAsync(ct) ?? "A member";
    }
}
