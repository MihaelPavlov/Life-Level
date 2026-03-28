using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class ChestService(AppDbContext db, CharacterService characterService)
{
    /// <summary>
    /// Collect a chest. Zone check enforced. One-time only.
    /// Awards RewardXp to character on collect.
    /// </summary>
    public async Task<CollectChestResult> CollectAsync(Guid userId, Guid chestId)
    {
        var chest = await db.Chests.FindAsync(chestId)
            ?? throw new InvalidOperationException("Chest not found.");

        var progress = await db.UserMapProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != chest.NodeId)
            throw new InvalidOperationException("You must be at the chest node to open it.");

        var existing = await db.UserChestStates
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
            db.UserChestStates.Add(existing);
        }

        existing.IsCollected = true;
        existing.CollectedAt = DateTime.UtcNow;

        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
        if (character != null)
        {
            character.Xp += chest.RewardXp;
            character.UpdatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync();

        bool leveledUp = false;
        int newLevel = 0;
        if (character != null)
        {
            var emoji = chest.Rarity switch
            {
                ChestRarity.Legendary => "🟠",
                ChestRarity.Epic      => "🟣",
                ChestRarity.Rare      => "💎",
                ChestRarity.Uncommon  => "🟦",
                _                     => "📦",
            };
            (leveledUp, newLevel) = await characterService.RecordXpAsync(
                character,
                "Chest",
                emoji,
                $"{chest.Rarity} Chest opened",
                chest.RewardXp);
        }

        return new CollectChestResult
        {
            RewardXp = chest.RewardXp,
            Rarity = chest.Rarity.ToString(),
            CollectedAt = existing.CollectedAt!.Value,
            LeveledUp = leveledUp,
            NewLevel = newLevel
        };
    }

    /// <summary>Debug: reset chest state so it can be collected again.</summary>
    public async Task DebugResetAsync(Guid userId, Guid chestId)
    {
        var state = await db.UserChestStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.ChestId == chestId);

        if (state != null)
        {
            db.UserChestStates.Remove(state);
            await db.SaveChangesAsync();
        }
    }
}

public class CollectChestResult
{
    public int RewardXp { get; set; }
    public string Rarity { get; set; } = string.Empty;
    public DateTime CollectedAt { get; set; }
    public bool LeveledUp { get; set; }
    public int NewLevel { get; set; }
}
