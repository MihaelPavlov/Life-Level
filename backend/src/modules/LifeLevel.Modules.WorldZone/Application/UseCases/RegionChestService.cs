using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

public class RegionChestService(
    DbContext db,
    IRewardCurrencyPort currency,
    IShopWalletPort wallet,
    ICharacterLevelReadPort characterLevel)
{
    public async Task<RegionChestsDto> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var regions = await ActiveRegionsAsync(ct);
        var resolved = await ResolvedRegionIdsAsync(userId, ct);
        var claims = await db.Set<UserRegionChestClaim>()
            .Where(x => x.UserId == userId)
            .ToDictionaryAsync(x => x.RegionId, ct);
        var level = await characterLevel.GetLevelAsync(userId, ct);

        var entries = regions.Select(region =>
        {
            var reward = RewardFor(region.ChapterIndex);
            var claimed = claims.GetValueOrDefault(region.Id);
            var status = claimed != null
                ? "claimed"
                : resolved.Contains(region.Id)
                    ? "ready"
                    : level < region.LevelRequirement ? "locked" : "inProgress";
            return new RegionChestDto(region.Id, region.ChapterIndex, reward.Coins, reward.Gems,
                status, claimed?.ClaimedAtUtc);
        }).ToList();

        return new RegionChestsDto(await WalletAsync(userId, ct), entries);
    }

    public async Task<RegionChestClaimResultDto> ClaimAsync(
        Guid userId, Guid regionId, CancellationToken ct = default)
    {
        var region = await db.Set<Region>()
            .Where(x => x.Id == regionId && x.World.IsActive)
            .SingleOrDefaultAsync(ct)
            ?? throw new RegionChestException("region_not_found", "Region not found.");

        if (await db.Set<UserRegionChestClaim>()
                .AnyAsync(x => x.UserId == userId && x.RegionId == regionId, ct))
            throw new RegionChestException("already_claimed", "This region chest is already claimed.");

        var resolved = await ResolvedRegionIdsAsync(userId, ct, regionId);
        if (!resolved.Contains(regionId))
            throw new RegionChestException("not_ready", "Resolve the region boss before claiming this chest.");

        await using var tx = db.Database.IsRelational()
            ? await db.Database.BeginTransactionAsync(ct)
            : null;
        var reward = RewardFor(region.ChapterIndex);
        var now = DateTime.UtcNow;
        db.Set<UserRegionChestClaim>().Add(new UserRegionChestClaim
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            RegionId = regionId,
            Coins = reward.Coins,
            Gems = reward.Gems,
            ClaimedAtUtc = now,
        });

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            throw new RegionChestException("already_claimed", "This region chest is already claimed.");
        }

        await currency.AddCoinsAsync(userId, reward.Coins, ct);
        await currency.AddGemsAsync(userId, reward.Gems, ct);
        if (tx != null) await tx.CommitAsync(ct);

        return new RegionChestClaimResultDto(regionId, reward.Coins, reward.Gems, "claimed", now,
            await WalletAsync(userId, ct));
    }

    internal static (int Coins, int Gems) RewardFor(int chapterIndex) => chapterIndex switch
    {
        <= 3 => (150, 20),
        <= 6 => (300, 35),
        <= 9 => (500, 50),
        <= 12 => (800, 80),
        _ => (1200, 120),
    };

    private Task<List<Region>> ActiveRegionsAsync(CancellationToken ct) => db.Set<Region>()
        .Where(x => x.World.IsActive)
        .OrderBy(x => x.ChapterIndex)
        .ToListAsync(ct);

    private async Task<HashSet<Guid>> ResolvedRegionIdsAsync(
        Guid userId, CancellationToken ct, Guid? onlyRegionId = null)
    {
        var query =
            from zone in db.Set<WorldZoneEntity>()
            join boss in db.Set<Boss>() on zone.Id equals boss.WorldZoneId
            join state in db.Set<UserBossState>() on boss.Id equals state.BossId
            where state.UserId == userId && (state.IsDefeated || state.IsExpired)
            select new { zone.RegionId };
        if (onlyRegionId.HasValue)
            query = query.Where(x => x.RegionId == onlyRegionId.Value);
        return (await query.Select(x => x.RegionId).Distinct().ToListAsync(ct)).ToHashSet();
    }

    private async Task<RegionChestWalletDto> WalletAsync(Guid userId, CancellationToken ct)
    {
        var balance = await wallet.GetBalanceAsync(userId, ct);
        return new RegionChestWalletDto(balance.Coins, balance.Gems);
    }
}
