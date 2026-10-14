using LifeLevel.Modules.Activity.Application.DTOs;
using LifeLevel.Modules.Activity.Application.UseCases;
using LifeLevel.Modules.Activity.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public sealed class TrackedSessionServiceTests
{
    [Fact]
    public async Task TimerOnlySessionIsStoredOnceWithoutAReward()
    {
        await using var db = NewDb();
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        var service = new TrackedSessionService(db, new CharacterIds(characterId), null!);
        var end = DateTime.UtcNow.AddSeconds(-1);
        var request = new FinishTrackedSessionRequest
        {
            SessionId = Guid.NewGuid(), Type = ActivityType.Yoga,
            StartedAtUtc = end.AddMinutes(-30), EndedAtUtc = end,
            ActiveSeconds = 1800, DistanceMeters = 0, GpsSampleCount = 0,
        };

        var first = await service.FinishAsync(userId, request, CancellationToken.None);
        var retry = await service.FinishAsync(userId, request, CancellationToken.None);

        Assert.False(first.GpsMeasured);
        Assert.Null(first.RewardedActivityId);
        Assert.Null(first.Reward);
        Assert.Equal(first.SessionId, retry.SessionId);
        Assert.Single(await service.GetHistoryAsync(userId, CancellationToken.None));
    }

    [Fact]
    public async Task OutdoorSessionWithoutUsableGpsDoesNotGrantProgress()
    {
        await using var db = NewDb();
        var service = new TrackedSessionService(db, new CharacterIds(Guid.NewGuid()), null!);
        var end = DateTime.UtcNow.AddSeconds(-1);
        var result = await service.FinishAsync(Guid.NewGuid(), new FinishTrackedSessionRequest
        {
            SessionId = Guid.NewGuid(), Type = ActivityType.Running,
            StartedAtUtc = end.AddMinutes(-10), EndedAtUtc = end,
            ActiveSeconds = 600, DistanceMeters = 500, GpsSampleCount = 2,
            GpsCoveredSeconds = 15,
        }, CancellationToken.None);

        Assert.False(result.GpsMeasured);
        Assert.Null(result.RewardedActivityId);
    }

    private static TestDb NewDb()
    {
        var options = new DbContextOptionsBuilder<TestDb>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
        return new TestDb(options);
    }

    private sealed class TestDb(DbContextOptions<TestDb> options) : DbContext(options)
    {
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TrackedSession>().HasKey(x => x.Id);
            modelBuilder.Entity<TrackedSession>().Property(x => x.Type).HasConversion<string>();
        }
    }

    private sealed class CharacterIds(Guid characterId) : ICharacterIdReadPort
    {
        public Task<Guid?> GetCharacterIdAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult<Guid?>(characterId);
    }
}
