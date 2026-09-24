using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Streak.Application.UseCases;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class StreakDailyRewardTests
{
    [Fact]
    public async Task ConsecutiveDays_StackTenCoinsPerStreakDay()
    {
        await using var db = CreateDb();
        var wallet = new RecordingCurrency();
        var service = new StreakService(db, new NoopEvents(), wallet);
        var userId = Guid.NewGuid();
        var day = new DateTime(2026, 9, 20, 0, 0, 0, DateTimeKind.Utc);

        await service.RecordActivityDayAsync(userId, day);
        await service.RecordActivityDayAsync(userId, day.AddDays(1));
        await service.RecordActivityDayAsync(userId, day.AddDays(1));

        var streak = await service.GetDtoAsync(userId);
        Assert.Equal(2, streak.Current);
        Assert.Equal(30, streak.PendingRewardCoins);
        Assert.True(streak.CanClaimDailyReward);

        var claim = await service.ClaimDailyRewardAsync(userId);
        Assert.True(claim.Success);
        Assert.Equal(30, claim.CoinsClaimed);
        Assert.Equal(30, wallet.Coins);
        Assert.False((await service.GetDtoAsync(userId)).CanClaimDailyReward);
    }

    [Fact]
    public async Task BrokenStreak_NextDailyRewardResetsToTenCoins()
    {
        await using var db = CreateDb();
        var service = new StreakService(db, new NoopEvents(), new RecordingCurrency());
        var userId = Guid.NewGuid();
        var day = new DateTime(2026, 9, 20, 0, 0, 0, DateTimeKind.Utc);

        await service.RecordActivityDayAsync(userId, day);
        await service.ClaimDailyRewardAsync(userId);
        await service.RecordActivityDayAsync(userId, day.AddDays(3));

        var streak = await service.GetDtoAsync(userId);
        Assert.Equal(1, streak.Current);
        Assert.Equal(10, streak.PendingRewardCoins);
        Assert.Equal(20, streak.NextRewardCoins);
    }

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private sealed class RecordingCurrency : IRewardCurrencyPort
    {
        public int Coins { get; private set; }

        public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default)
        {
            Coins += amount;
            return Task.CompletedTask;
        }

        public Task AddCrystalsAsync(Guid userId, int amount, CancellationToken ct = default) =>
            Task.CompletedTask;
    }

    private sealed class NoopEvents : IEventPublisher
    {
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
            where TEvent : IDomainEvent => Task.CompletedTask;
    }
}
