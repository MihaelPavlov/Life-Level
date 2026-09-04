using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Guild.Application.DTOs;
using LifeLevel.Modules.Guild.Application.UseCases;
using LifeLevel.Modules.Guild.Domain.Entities;
using LifeLevel.Modules.Guild.Domain.Enums;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using GuildEntity = LifeLevel.Modules.Guild.Domain.Entities.Guild;

namespace LifeLevel.Api.Tests;

public class GuildServiceTests
{
    [Fact]
    public async Task CreateSearchJoinKickLeave_UpdatesMembership()
    {
        await using var db = CreateDb();
        var xp = new CapturingGuildXpPort();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var notifications = new CapturingNotificationPort();
        var service = new GuildService(db, xp, new NoOpGuildRaidRealtimePort(), notifications);

        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Iron Wolves", "AM crew", "wolf"));
        var search = await service.SearchAsync("iron", 0, 10);

        Assert.Single(search);
        Assert.True(guild.IsLeader);
        Assert.Equal(1, guild.MemberCount);

        var joined = await service.JoinAsync(member, guild.Id);
        Assert.False(joined.IsLeader);
        Assert.Equal(2, joined.MemberCount);

        await service.KickAsync(owner, guild.Id, member);
        Assert.Null(await service.GetMineAsync(member));

        await service.JoinAsync(member, guild.Id);
        await service.LeaveAsync(member);
        var ownerView = await service.GetMineAsync(owner);
        Assert.NotNull(ownerView);
        Assert.Single(ownerView.Members);
    }

    [Fact]
    public async Task UpdateAsync_AllowsOwnerToRenameDescriptionAndIconOnly()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Iron Wolves", "AM crew", "wolf"));
        await service.JoinAsync(member, guild.Id);

        var updated = await service.UpdateAsync(owner, new GuildUpdateRequest("Dog Owners", "Evening walks", "crown"));
        var nonOwnerError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.UpdateAsync(member, new GuildUpdateRequest("Bad Rename", null, null)));

        Assert.Equal("Dog Owners", updated.Name);
        Assert.Equal("Evening walks", updated.Description);
        Assert.Equal("crown", updated.Icon);
        Assert.True(updated.CanEditGuild);
        Assert.Equal("Only the guild owner can edit the guild.", nonOwnerError.Message);
    }

    [Fact]
    public async Task OwnerCannotLeaveOrTransferOwnership()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);

        var leaveError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.LeaveAsync(owner));
        var transferError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.UpdateMemberRoleAsync(owner, guild.Id, member, new GuildRoleUpdateRequest("Leader")));

        Assert.Equal("The guild owner cannot leave. Delete the guild instead.", leaveError.Message);
        Assert.Equal("Ownership is not transferable.", transferError.Message);
    }

    [Fact]
    public async Task UpdateMemberRole_AllowsOwnerToAssignOfficerAndOfficerCanManageRaidAndMembers()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var officer = await SeedUserAsync(db, "officer");
        var member = await SeedUserAsync(db, "member");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 200);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(officer, guild.Id);
        await service.JoinAsync(member, guild.Id);

        var officerView = await service.UpdateMemberRoleAsync(owner, guild.Id, officer, new GuildRoleUpdateRequest("Officer"));
        var officerMember = officerView.Members.Single(m => m.UserId == officer);
        var dbOfficer = await db.Set<GuildMember>().SingleAsync(m => m.UserId == officer);

        Assert.Equal("Officer", officerMember.Role);
        Assert.Equal(GuildMemberRole.Officer, dbOfficer.Role);

        var raid = await service.StartRaidAsync(officer, bossId);
        Assert.Equal(bossId, raid.BossId);

        await service.KickAsync(officer, guild.Id, member);
        var kickOwnerError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.KickAsync(officer, guild.Id, owner));

        Assert.Equal("The guild owner cannot be removed.", kickOwnerError.Message);
        Assert.Null(await service.GetMineAsync(member));
    }

    [Fact]
    public async Task StartRaid_BlocksSecondActiveRaidUntilExpired()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var bossA = await SeedBossAsync(db, "Forest Warden", maxHp: 200);
        var bossB = await SeedBossAsync(db, "Ash Sentinel", maxHp: 300);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));

        await service.StartRaidAsync(owner, bossA);
        var error = await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.StartRaidAsync(owner, bossB));
        Assert.Equal("Your guild already has an active raid.", error.Message);

        var active = await db.Set<GuildRaid>().SingleAsync();
        active.ExpiresAt = DateTime.UtcNow.AddMinutes(-1);
        await db.SaveChangesAsync();

        Assert.Equal(1, await service.ExpireOverdueRaidsAsync());
        var next = await service.StartRaidAsync(owner, bossB);
        Assert.Equal(bossB, next.BossId);
    }

    [Fact]
    public async Task StartRaid_ScalesHpRewardAndDurationByGuildSizeAndBossType()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var miniBoss = await SeedBossAsync(db, "Mini", maxHp: 100, rewardXp: 400, isMini: true);
        var normalBoss = await SeedBossAsync(db, "Normal", maxHp: 100, rewardXp: 400);
        var majorBoss = await SeedBossAsync(db, "Major", maxHp: 100, rewardXp: 400, worldZoneId: Guid.NewGuid());
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);

        var mini = await service.StartRaidAsync(owner, miniBoss);
        Assert.Equal(145, mini.MaxHp);
        Assert.Equal(100, mini.BaseMaxHp);
        Assert.Equal(463, mini.RewardXp);
        Assert.Equal(400, mini.BaseRewardXp);
        Assert.Equal(2, mini.GuildSizeAtStart);
        Assert.InRange((mini.ExpiresAt - mini.StartedAt).TotalHours, 23.9, 24.1);

        await service.ForceExpireAsync(owner);
        var normal = await service.StartRaidAsync(owner, normalBoss);
        Assert.InRange((normal.ExpiresAt - normal.StartedAt).TotalDays, 2.9, 3.1);

        await service.ForceExpireAsync(owner);
        var major = await service.StartRaidAsync(owner, majorBoss);
        Assert.InRange((major.ExpiresAt - major.StartedAt).TotalDays, 6.9, 7.1);
    }

    [Fact]
    public async Task ApplyActivity_DamagesOnlyMembersAndIgnoresPreRaidActivities()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var outsider = await SeedUserAsync(db, "outsider");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 1000);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        var raid = await service.StartRaidAsync(owner, bossId);

        var preRaid = await service.ApplyActivityAsync(
            owner,
            Guid.NewGuid(),
            "Running",
            45,
            5,
            350,
            raid.StartedAt.AddSeconds(-1));
        Assert.Empty(preRaid);
        Assert.Equal(0, (await service.GetActiveRaidAsync(owner))!.TotalDamage);

        var outsiderResult = await service.ApplyActivityAsync(
            outsider,
            Guid.NewGuid(),
            "Running",
            45,
            5,
            350,
            DateTime.UtcNow);
        Assert.Empty(outsiderResult);

        await service.ApplyActivityAsync(owner, Guid.NewGuid(), "Running", 45, 5, 350, DateTime.UtcNow);
        var active = await service.GetActiveRaidAsync(owner);
        Assert.Equal(BossService.CalculateDamageFromActivity("Running", 45, 5, 350), active!.TotalDamage);
        Assert.Single(active.Contributions);
    }

    [Fact]
    public async Task DefeatRaid_GrantsBaseRewardToMembersAndBonusToTopContributorOnce()
    {
        await using var db = CreateDb();
        var xp = new CapturingGuildXpPort();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 100, rewardXp: 400);
        var notifications = new CapturingNotificationPort();
        var service = new GuildService(db, xp, new NoOpGuildRaidRealtimePort(), notifications);
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);
        await service.StartRaidAsync(owner, bossId);

        await service.DebugAddDamageAsync(member, 30);
        var defeated = await service.DebugAddDamageAsync(owner, 200);
        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.DebugAddDamageAsync(owner, 100));

        Assert.Single(defeated);
        Assert.Equal(guild.Id, defeated[0].GuildId);
        Assert.Equal(463, defeated[0].RewardXp);
        Assert.Equal(116, defeated[0].MvpBonusXp);
        Assert.Equal("owner", defeated[0].TopContributorUsername);
        Assert.Equal(115, defeated[0].TopContributorDamage);
        Assert.Equal(115, defeated[0].YourDamage);
        Assert.Equal(145, defeated[0].TotalDamage);
        Assert.Null(await service.GetActiveRaidAsync(owner));
        Assert.Equal(3, xp.Awards.Count);
        Assert.Contains(xp.Awards, a => a.UserId == owner && a.Source == "GuildRaid" && a.Xp == 463);
        Assert.Contains(xp.Awards, a => a.UserId == member && a.Source == "GuildRaid" && a.Xp == 463);
        Assert.Contains(xp.Awards, a => a.UserId == owner && a.Source == "GuildRaidMvp" && a.Xp == 116);
        Assert.Contains(notifications.Notifications, n => n.Category == "guild-raid-defeated" && n.IsCritical);
    }

    [Fact]
    public async Task DefeatRaid_RewardsOnlyContributors()
    {
        await using var db = CreateDb();
        var xp = new CapturingGuildXpPort();
        var owner = await SeedUserAsync(db, "owner");
        var contributor = await SeedUserAsync(db, "contributor");
        var inactive = await SeedUserAsync(db, "inactive");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 100, rewardXp: 400);
        var service = new GuildService(db, xp, new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(contributor, guild.Id);
        await service.JoinAsync(inactive, guild.Id);
        await service.StartRaidAsync(owner, bossId);

        await service.DebugAddDamageAsync(contributor, 200);

        Assert.DoesNotContain(xp.Awards, a => a.UserId == owner);
        Assert.DoesNotContain(xp.Awards, a => a.UserId == inactive);
        Assert.Contains(xp.Awards, a => a.UserId == contributor && a.Source == "GuildRaid");
        Assert.Contains(xp.Awards, a => a.UserId == contributor && a.Source == "GuildRaidMvp");
    }

    [Fact]
    public async Task ApplyDamage_PublishesRealtimeHpAndDefeatedEvents()
    {
        await using var db = CreateDb();
        var realtime = new CapturingGuildRealtimePort();
        var owner = await SeedUserAsync(db, "owner");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 100, rewardXp: 400);
        var service = new GuildService(db, new CapturingGuildXpPort(), realtime, new CapturingNotificationPort());
        await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.StartRaidAsync(owner, bossId);

        Assert.Single(realtime.Starts);
        Assert.Equal("Forest Warden", realtime.Starts[0].BossName);
        Assert.Equal(110, realtime.Starts[0].MaxHp);

        await service.DebugAddDamageAsync(owner, 40);
        await service.DebugAddDamageAsync(owner, 200);

        Assert.Equal(2, realtime.HpUpdates.Count);
        Assert.Equal(40, realtime.HpUpdates[0].DamageDelta);
        Assert.Equal(70, realtime.HpUpdates[0].RemainingHp);
        Assert.Single(realtime.Defeats);
        Assert.Equal("owner", realtime.Defeats[0].TopContributorUsername);
        Assert.Equal(110, realtime.Defeats[0].YourDamage);
        Assert.Empty(realtime.Expiries);
    }


    [Fact]
    public async Task PendingVictoryAcknowledgements_ReturnForDefeatMembersUntilAcknowledged()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var lateMember = await SeedUserAsync(db, "late");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 100, rewardXp: 400);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);
        await service.StartRaidAsync(owner, bossId);

        await service.DebugAddDamageAsync(owner, 200);
        await service.JoinAsync(lateMember, guild.Id);

        Assert.Single(await service.GetPendingVictoryAcknowledgementsAsync(owner));
        Assert.Single(await service.GetPendingVictoryAcknowledgementsAsync(member));
        Assert.Empty(await service.GetPendingVictoryAcknowledgementsAsync(lateMember));

        var pending = await service.GetPendingVictoryAcknowledgementsAsync(member);
        await service.AcknowledgeVictoryAsync(member, pending[0].GuildRaidId);
        Assert.Empty(await service.GetPendingVictoryAcknowledgementsAsync(member));

        await service.AcknowledgeVictoryAsync(member, pending[0].GuildRaidId);
        Assert.Empty(await service.GetPendingVictoryAcknowledgementsAsync(member));
    }

    [Fact]
    public async Task PendingExpiryAcknowledgements_ReturnForMembersUntilAcknowledged()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var lateMember = await SeedUserAsync(db, "late");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 500);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);
        await service.StartRaidAsync(owner, bossId);

        var joinedBeforeRaid = DateTime.UtcNow.AddMinutes(-10);
        var members = await db.Set<GuildMember>().ToListAsync();
        foreach (var guildMember in members)
        {
            guildMember.JoinedAt = joinedBeforeRaid;
        }

        var active = await db.Set<GuildRaid>().SingleAsync();
        active.StartedAt = DateTime.UtcNow.AddMinutes(-5);
        active.ExpiresAt = DateTime.UtcNow.AddMinutes(-1);
        await db.SaveChangesAsync();
        await service.ExpireOverdueRaidsAsync();
        await service.JoinAsync(lateMember, guild.Id);

        Assert.Single(await service.GetPendingExpiryAcknowledgementsAsync(owner));
        Assert.Single(await service.GetPendingExpiryAcknowledgementsAsync(member));
        Assert.Empty(await service.GetPendingExpiryAcknowledgementsAsync(lateMember));

        var pending = await service.GetPendingExpiryAcknowledgementsAsync(member);
        await service.AcknowledgeExpiryAsync(member, pending[0].GuildRaidId);
        Assert.Empty(await service.GetPendingExpiryAcknowledgementsAsync(member));

        await service.AcknowledgeExpiryAsync(member, pending[0].GuildRaidId);
        Assert.Empty(await service.GetPendingExpiryAcknowledgementsAsync(member));
    }

    [Fact]
    public async Task AcknowledgeVictory_RejectsNonMembersAndUnknownRaids()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var outsider = await SeedUserAsync(db, "outsider");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 100);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.StartRaidAsync(owner, bossId);
        await service.DebugAddDamageAsync(owner, 200);
        var pending = await service.GetPendingVictoryAcknowledgementsAsync(owner);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.AcknowledgeVictoryAsync(outsider, pending[0].GuildRaidId));
        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.AcknowledgeVictoryAsync(owner, Guid.NewGuid()));
    }


    [Fact]
    public async Task RaidHistory_ReturnsDefeatedAndExpiredRaidsWithContributions()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var xp = new CapturingGuildXpPort();
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 80, rewardXp: 400);
        var service = new GuildService(db, xp, new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);

        await service.StartRaidAsync(owner, bossId);
        await service.DebugAddDamageAsync(member, 20);
        await service.DebugAddDamageAsync(owner, 100);

        await service.StartRaidAsync(owner, bossId);
        var active = await db.Set<GuildRaid>().SingleAsync(r => !r.IsDefeated);
        active.ExpiresAt = DateTime.UtcNow.AddMinutes(-1);
        await db.SaveChangesAsync();
        await service.ExpireOverdueRaidsAsync();

        var history = await service.GetRaidHistoryAsync(owner);
        var defeated = history.Single(r => r.IsDefeated);
        var expired = history.Single(r => r.IsExpired);

        Assert.Equal(2, history.Count);
        Assert.True(defeated.RewardClaimed);
        Assert.NotNull(defeated.RewardClaimedAt);
        Assert.Equal("owner", defeated.MvpUsername);
        Assert.True(defeated.MvpDamage > 0);
        Assert.True(defeated.MvpBonusXp > 0);
        Assert.Equal(2, defeated.Contributions.Count);
        Assert.Equal(1, defeated.Contributions[0].Rank);
        Assert.True(defeated.Contributions[0].IsMvp);
        Assert.Equal(2, defeated.Contributions[1].Rank);
        Assert.False(expired.RewardClaimed);
        Assert.Null(expired.RewardClaimedAt);
        Assert.DoesNotContain(xp.Awards, a => a.Description.Contains("expired", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task DeleteAsync_OwnerDeletesGuildMembersRaidsAndContributions()
    {
        await using var db = CreateDb();
        var owner = await SeedUserAsync(db, "owner");
        var member = await SeedUserAsync(db, "member");
        var bossId = await SeedBossAsync(db, "Forest Warden", maxHp: 500);
        var service = new GuildService(db, new CapturingGuildXpPort(), new NoOpGuildRaidRealtimePort(), new CapturingNotificationPort());
        var guild = await service.CreateAsync(owner, new GuildCreateRequest("Raiders", null, null));
        await service.JoinAsync(member, guild.Id);
        await service.StartRaidAsync(owner, bossId);
        await service.DebugAddDamageAsync(member, 100);

        var nonOwnerError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.DeleteAsync(member));
        Assert.Equal("Only the guild owner can delete the guild.", nonOwnerError.Message);

        await service.DeleteAsync(owner);

        Assert.Empty(await db.Set<GuildEntity>().ToListAsync());
        Assert.Empty(await db.Set<GuildMember>().ToListAsync());
        Assert.Empty(await db.Set<GuildRaid>().ToListAsync());
        Assert.Empty(await db.Set<GuildRaidContribution>().ToListAsync());
        Assert.Empty(await db.Set<GuildRaidVictoryAcknowledgement>().ToListAsync());
        Assert.Empty(await db.Set<GuildRaidExpiryAcknowledgement>().ToListAsync());
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<Guid> SeedUserAsync(AppDbContext db, string name)
    {
        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            Id = userId,
            Username = name,
            Email = $"{name}@lifelevel.test",
            PasswordHash = "hash",
        });
        db.Characters.Add(new Character
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            AvatarEmoji = "hero",
            IsSetupComplete = true,
        });
        await db.SaveChangesAsync();
        return userId;
    }

    private static async Task<Guid> SeedBossAsync(
        AppDbContext db,
        string name,
        int maxHp,
        int rewardXp = 500,
        bool isMini = false,
        Guid? worldZoneId = null)
    {
        var bossId = Guid.NewGuid();
        db.Bosses.Add(new Boss
        {
            Id = bossId,
            Name = name,
            Icon = "assets/Bosses/boss_forest_warden.svg",
            MaxHp = maxHp,
            RewardXp = rewardXp,
            TimerDays = 7,
            IsMini = isMini,
            WorldZoneId = worldZoneId,
            SuppressExpiry = true,
        });
        await db.SaveChangesAsync();
        return bossId;
    }
}

file sealed class CapturingGuildXpPort : ICharacterXpPort
{
    public List<GuildXpAward> Awards { get; } = [];

    public Task<XpAwardResult> AwardXpAsync(
        Guid userId,
        string source,
        string sourceEmoji,
        string description,
        long xp,
        CancellationToken ct = default)
    {
        Awards.Add(new GuildXpAward(userId, source, sourceEmoji, description, xp));
        return Task.FromResult(XpAwardResult.None);
    }
}

file record GuildXpAward(Guid UserId, string Source, string SourceEmoji, string Description, long Xp);

file sealed class CapturingGuildRealtimePort : IGuildRaidRealtimePort
{
    public List<GuildRaidStartedInfo> Starts { get; } = [];
    public List<GuildRaidHpUpdatedInfo> HpUpdates { get; } = [];
    public List<GuildRaidDefeatedInfo> Defeats { get; } = [];
    public List<GuildRaidExpiredInfo> Expiries { get; } = [];

    public Task RaidStartedAsync(GuildRaidStartedInfo info, CancellationToken ct = default)
    {
        Starts.Add(info);
        return Task.CompletedTask;
    }

    public Task RaidHpUpdatedAsync(GuildRaidHpUpdatedInfo info, CancellationToken ct = default)
    {
        HpUpdates.Add(info);
        return Task.CompletedTask;
    }

    public Task RaidDefeatedAsync(GuildRaidDefeatedInfo info, CancellationToken ct = default)
    {
        Defeats.Add(info);
        return Task.CompletedTask;
    }

    public Task RaidExpiredAsync(GuildRaidExpiredInfo info, CancellationToken ct = default)
    {
        Expiries.Add(info);
        return Task.CompletedTask;
    }
}

file sealed class CapturingNotificationPort : INotificationPort
{
    public List<GuildNotification> Notifications { get; } = [];

    public Task<NotificationSendResult> SendToUserAsync(
        Guid userId,
        string category,
        string title,
        string body,
        IDictionary<string, string>? data = null,
        bool isCritical = false,
        CancellationToken ct = default)
    {
        Notifications.Add(new GuildNotification(userId, category, title, body, isCritical));
        return Task.FromResult(new NotificationSendResult(true, "Sent"));
    }
}

file record GuildNotification(Guid UserId, string Category, string Title, string Body, bool IsCritical);
