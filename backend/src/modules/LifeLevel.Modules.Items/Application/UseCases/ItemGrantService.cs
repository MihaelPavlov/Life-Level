using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Items.Application.UseCases;

public class ItemGrantService(DbContext db, ICharacterIdReadPort characterIdRead)
{
    public async Task<CharacterItem?> GrantItemAsync(Guid userId, Guid itemId)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId);
        if (characterId == null) return null;

        var item = await db.Set<Item>().FindAsync(itemId);
        if (item == null) return null;

        // Idempotent — don't duplicate
        var existing = await db.Set<CharacterItem>()
            .FirstOrDefaultAsync(ci => ci.CharacterId == characterId && ci.ItemId == itemId);
        if (existing != null) return existing;

        var charItem = new CharacterItem
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId.Value,
            ItemId = itemId,
            IsEquipped = false,
            AcquiredAt = DateTime.UtcNow
        };
        db.Set<CharacterItem>().Add(charItem);
        await db.SaveChangesAsync();
        return charItem;
    }

    public async Task<List<CharacterItem>> EvaluateTriggerAsync(Guid userId, AcquisitionTrigger trigger, Dictionary<string, string> parameters)
    {
        var rules = await db.Set<ItemDropRule>()
            .Where(r => r.TriggerType == trigger && r.IsEnabled)
            .ToListAsync();

        var granted = new List<CharacterItem>();
        var rng = new Random();

        foreach (var rule in rules)
        {
            if (rule.DropChancePct < 100 && rng.Next(100) >= rule.DropChancePct)
                continue;

            var charItem = await GrantItemAsync(userId, rule.ItemId);
            if (charItem != null) granted.Add(charItem);
        }

        return granted;
    }
}
