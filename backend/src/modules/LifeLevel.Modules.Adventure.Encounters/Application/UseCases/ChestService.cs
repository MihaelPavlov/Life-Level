using LifeLevel.Modules.Adventure.Encounters.Application.DTOs;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Enums;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Encounters.Application.UseCases;

public class ChestService(DbContext db, ICharacterXpPort characterXp)
{
    public async Task<CollectChestResult> CollectAsync(Guid userId, Guid chestId)
    {
        var chest = await db.Set<Chest>().FindAsync(chestId)
            ?? throw new InvalidOperationException("Chest not found.");

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != chest.NodeId)
            throw new InvalidOperationException("You must be at the chest node to open it.");

        var existing = await db.Set<UserChestState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.ChestId == chestId);

        if (existing?.IsCollected == true)
            throw new InvalidOperationException("Chest already collected.");

        if (existing == null)
        {
            existing = new UserChestState
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ChestId = chestId,
                UserMapProgressId = progress.Id
            };
            db.Set<UserChestState>().Add(existing);
        }

        existing.IsCollected = true;
        existing.CollectedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        var emoji = chest.Rarity switch
        {
            ChestRarity.Legendary => "🟠",
            ChestRarity.Epic      => "🟣",
            ChestRarity.Rare      => "💎",
            ChestRarity.Uncommon  => "🟦",
            _                     => "📦",
        };
        await characterXp.AwardXpAsync(
            userId,
            "Chest",
            emoji,
            $"{chest.Rarity} Chest opened",
            chest.RewardXp);

        return new CollectChestResult
        {
            RewardXp = chest.RewardXp,
            Rarity = chest.Rarity.ToString(),
            CollectedAt = existing.CollectedAt!.Value
        };
    }

    public async Task DebugResetAsync(Guid userId, Guid chestId)
    {
        var state = await db.Set<UserChestState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.ChestId == chestId);

        if (state != null)
        {
            db.Set<UserChestState>().Remove(state);
            await db.SaveChangesAsync();
        }
    }
}
