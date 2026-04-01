using System.Text.Json;
using LifeLevel.Modules.Items.Application.DTOs;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Items.Application.UseCases;

public record GrantItemResult(CharacterItem? Item, bool InventoryFull);
public record BlockedItemInfo(string ItemName, string ItemIcon);
public record LevelUpGrantSummary(List<ItemDto> Granted, List<BlockedItemInfo> Blocked);

public class ItemGrantService(DbContext db, ICharacterIdReadPort characterIdRead, IInventorySlotReadPort inventorySlotRead)
{
    public async Task<GrantItemResult> GrantItemAsync(Guid userId, Guid itemId, CancellationToken ct = default)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId == null) return new GrantItemResult(null, InventoryFull: false);

        var item = await db.Set<Item>().FindAsync([itemId], ct);
        if (item == null) return new GrantItemResult(null, InventoryFull: false);

        // Enforce slot cap before idempotency check
        var maxSlots = await inventorySlotRead.GetMaxInventorySlotsAsync(userId, ct);
        var currentCount = await db.Set<CharacterItem>().CountAsync(ci => ci.CharacterId == characterId, ct);
        if (currentCount >= maxSlots)
            return new GrantItemResult(null, InventoryFull: true);

        // Idempotent — don't duplicate
        var existing = await db.Set<CharacterItem>()
            .FirstOrDefaultAsync(ci => ci.CharacterId == characterId && ci.ItemId == itemId, ct);
        if (existing != null) return new GrantItemResult(existing, InventoryFull: false);

        var charItem = new CharacterItem
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId.Value,
            ItemId = itemId,
            IsEquipped = false,
            AcquiredAt = DateTime.UtcNow
        };
        db.Set<CharacterItem>().Add(charItem);
        await db.SaveChangesAsync(ct);
        return new GrantItemResult(charItem, InventoryFull: false);
    }

    public async Task<LevelUpGrantSummary> EvaluateLevelUpAsync(Guid userId, int previousLevel, int newLevel, CancellationToken ct = default)
    {
        var rules = await db.Set<ItemDropRule>()
            .Where(r => r.TriggerType == AcquisitionTrigger.LevelReached && r.IsEnabled)
            .ToListAsync(ct);

        var granted = new List<ItemDto>();
        var blocked = new List<BlockedItemInfo>();
        var rng = new Random();

        foreach (var rule in rules)
        {
            int requiredLevel;
            try
            {
                var doc = JsonDocument.Parse(rule.TriggerParameters);
                if (!doc.RootElement.TryGetProperty("level", out var lvlProp) || !lvlProp.TryGetInt32(out requiredLevel))
                    continue;
            }
            catch (JsonException)
            {
                continue;
            }

            if (requiredLevel <= previousLevel || requiredLevel > newLevel)
                continue;

            if (rule.DropChancePct < 100 && rng.Next(100) >= rule.DropChancePct)
                continue;

            var result = await GrantItemAsync(userId, rule.ItemId, ct);
            if (result.InventoryFull)
            {
                var item = await db.Set<Item>().FindAsync([rule.ItemId], ct);
                if (item != null) blocked.Add(new BlockedItemInfo(item.Name, item.Icon));
            }
            else if (result.Item != null)
            {
                var item = await db.Set<Item>().FindAsync([rule.ItemId], ct);
                if (item != null)
                {
                    granted.Add(new ItemDto
                    {
                        Id = item.Id,
                        Name = item.Name,
                        Description = item.Description,
                        Icon = item.Icon,
                        Rarity = item.Rarity.ToString(),
                        SlotType = item.SlotType.ToString(),
                        XpBonusPct = item.XpBonusPct,
                        StrBonus = item.StrBonus,
                        EndBonus = item.EndBonus,
                        AgiBonus = item.AgiBonus,
                        FlxBonus = item.FlxBonus,
                        StaBonus = item.StaBonus,
                        Category = item.Category.ToString(),
                    });
                }
            }
        }

        return new LevelUpGrantSummary(granted, blocked);
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

            var result = await GrantItemAsync(userId, rule.ItemId);
            if (result.Item != null) granted.Add(result.Item);
        }

        return granted;
    }
}
