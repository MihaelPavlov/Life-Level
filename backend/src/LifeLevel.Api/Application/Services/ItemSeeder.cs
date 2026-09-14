using System.Text.Json;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class ItemSeeder(AppDbContext db)
{
    private static readonly Item[] CatalogItems =
    [
        // === TRACKERS ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000001"), Name = "Apex GPS Pro", Description = "Top-of-the-line GPS tracker with heart rate monitoring. Unlocked at 500 km lifetime.", Icon = "⌚", Rarity = ItemRarity.Legendary, Category = ItemCategory.Tracker, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 15, StaBonus = 8 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000009"), Name = "Pulse Wristband", Description = "Tracks heart rate and daily steps. Great for beginners.", Icon = "⌚", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Tracker, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 4, StaBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000010"), Name = "Basic Step Counter", Description = "A simple pedometer. Every step counts.", Icon = "📟", Rarity = ItemRarity.Common, Category = ItemCategory.Tracker, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 1, StaBonus = 1 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000011"), Name = "Strava Sync Badge", Description = "Awarded for connecting your Strava account. Syncs all your runs.", Icon = "🔗", Rarity = ItemRarity.Rare, Category = ItemCategory.Tracker, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 8, EndBonus = 3 },

        // === CLOTHING ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000003"), Name = "Cryo Jersey", Description = "Moisture-wicking performance jersey with cooling tech.", Icon = "🎽", Rarity = ItemRarity.Rare, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 5, AgiBonus = 3, StaBonus = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000007"), Name = "Iron Headband", Description = "Simple but sturdy headband for intense workouts.", Icon = "🎽", Rarity = ItemRarity.Common, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Head, XpBonusPct = 0, EndBonus = 1, StaBonus = 1 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000012"), Name = "Storm Jacket", Description = "Windproof shell for outdoor training in any weather.", Icon = "🧥", Rarity = ItemRarity.Epic, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 10, EndBonus = 5, StaBonus = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000013"), Name = "Compression Shirt", Description = "Reduces muscle fatigue and improves circulation.", Icon = "👕", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 3, StrBonus = 2, StaBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000014"), Name = "Elite Windbreaker", Description = "The finest aerodynamic jacket worn only by champions.", Icon = "🥇", Rarity = ItemRarity.Legendary, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 12, AgiBonus = 8, EndBonus = 6 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000002"), Name = "Aero Race Cap", Description = "Aerodynamic cap that keeps you cool on long runs.", Icon = "🧢", Rarity = ItemRarity.Epic, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Head, XpBonusPct = 8, EndBonus = 5 },

        // === FOOTWEAR ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000005"), Name = "Carbon X3", Description = "Carbon-plated racing shoes for maximum energy return.", Icon = "👟", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Footwear, SlotType = EquipmentSlotType.Feet, XpBonusPct = 3, EndBonus = 3, AgiBonus = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000008"), Name = "Trail Runner X5", Description = "All-terrain trail running shoes.", Icon = "👟", Rarity = ItemRarity.Epic, Category = ItemCategory.Footwear, SlotType = EquipmentSlotType.Feet, XpBonusPct = 10, EndBonus = 5, AgiBonus = 8 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000015"), Name = "Speed Spikes", Description = "Track spikes engineered for maximum sprint performance.", Icon = "⚡", Rarity = ItemRarity.Rare, Category = ItemCategory.Footwear, SlotType = EquipmentSlotType.Feet, XpBonusPct = 6, AgiBonus = 10, EndBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000016"), Name = "Recovery Slides", Description = "Soft foam slides for active recovery days.", Icon = "🩴", Rarity = ItemRarity.Common, Category = ItemCategory.Footwear, SlotType = EquipmentSlotType.Feet, XpBonusPct = 0, StaBonus = 3, FlxBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000017"), Name = "Gravity Boots", Description = "Legendary boots said to make every stride effortless.", Icon = "🥾", Rarity = ItemRarity.Legendary, Category = ItemCategory.Footwear, SlotType = EquipmentSlotType.Feet, XpBonusPct = 15, AgiBonus = 12, EndBonus = 8 },

        // === ACCESSORIES ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000004"), Name = "Grip Wraps", Description = "Lightweight wraps for improved grip and wrist support.", Icon = "🧤", Rarity = ItemRarity.Rare, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, StrBonus = 8, FlxBonus = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000006"), Name = "Sport Buds", Description = "Wireless earbuds with motivational beat detection.", Icon = "🎧", Rarity = ItemRarity.Rare, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 5, StaBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000018"), Name = "Climbing Chalk Bag", Description = "Keeps your hands dry for bouldering and weightlifting.", Icon = "🎒", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, StrBonus = 4, FlxBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000019"), Name = "Resistance Band Set", Description = "Versatile bands for mobility and strength training.", Icon = "🔴", Rarity = ItemRarity.Common, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, StrBonus = 2, FlxBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000020"), Name = "Champion Gloves", Description = "Worn by warriors who have conquered the highest peaks.", Icon = "🥊", Rarity = ItemRarity.Legendary, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, XpBonusPct = 10, StrBonus = 12, FlxBonus = 6 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000021"), Name = "Aura Stone", Description = "A mystical stone that pulses with workout energy.", Icon = "💎", Rarity = ItemRarity.Epic, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 12, StaBonus = 8 },

        // === CONSUMABLES (stored in Accessory1 slot as "use" items) ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000022"), Name = "XP Booster", Description = "Grants ×2 XP for your next workout. Consumed on use.", Icon = "⚗️", Rarity = ItemRarity.Rare, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 100 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000023"), Name = "Energy Gel", Description = "A burst of energy. +5 to all stats for one session.", Icon = "💧", Rarity = ItemRarity.Common, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, StaBonus = 5, EndBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000024"), Name = "Streak Shield", Description = "Protects your streak for one missed day.", Icon = "🛡️", Rarity = ItemRarity.Epic, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 0 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000025"), Name = "KT Tape Roll", Description = "Supports injured muscles so you can keep training.", Icon = "🩹", Rarity = ItemRarity.Common, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, StaBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000026"), Name = "Phoenix Elixir", Description = "Legendary potion. Restore a broken streak instantly.", Icon = "🔥", Rarity = ItemRarity.Legendary, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 50 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000027"), Name = "Zone Compass", Description = "Instantly reveals the next locked zone on your map.", Icon = "🧭", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000028"), Name = "Boss Scroll", Description = "Summons a mini-boss to your current zone.", Icon = "📜", Rarity = ItemRarity.Rare, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 0 },

        // === LEGS (paper-doll test items) ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000029"), Name = "Shadow Joggers", Description = "Weathered training joggers, worn thin from a thousand miles.", Icon = "👖", Rarity = ItemRarity.Rare, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Legs, XpBonusPct = 6, EndBonus = 4, AgiBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000030"), Name = "Crimson Trail Shorts", Description = "Lightweight shorts for hot-weather trail runs.", Icon = "🩳", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Legs, XpBonusPct = 2, AgiBonus = 3, StaBonus = 1 },

        // === CHEST (paper-doll test items) ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000031"), Name = "Tactical Raid Hoodie", Description = "Strapped and pocketed hoodie built for boss-zone raids.", Icon = "🧥", Rarity = ItemRarity.Epic, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 9, StrBonus = 5, StaBonus = 4 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000032"), Name = "Alpine Cable Sweater", Description = "A heavy knit sweater for cold-weather training.", Icon = "🧶", Rarity = ItemRarity.Rare, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 4, StaBonus = 6, FlxBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000033"), Name = "Wanderer's Poncho", Description = "A fringed poncho worn by travelers between zones.", Icon = "🧣", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 3, FlxBonus = 3, EndBonus = 2 },

        // === CHEST (new drop) ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000034"), Name = "Ascender's Climbing Rig", Description = "A roped climbing harness rig for scaling the toughest peaks.", Icon = "🧗", Rarity = ItemRarity.Epic, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 9, StrBonus = 6, EndBonus = 4 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000035"), Name = "Timber Flannel Shirt", Description = "A cozy buffalo-plaid flannel for casual training days.", Icon = "👕", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 3, StaBonus = 3, FlxBonus = 1 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000036"), Name = "Vanguard Puffer Jacket", Description = "An insulated tactical puffer jacket built for cold-weather expeditions.", Icon = "🧥", Rarity = ItemRarity.Rare, Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest, XpBonusPct = 6, EndBonus = 5, StaBonus = 3 },
    ];

    private static readonly ItemDropRule[] DropRules =
    [
        // Strava Sync Badge → connect Strava integration
        new() { Id = new Guid("20000000-0000-0000-0000-000000000001"), ItemId = new Guid("10000000-0000-0000-0000-000000000011"), TriggerType = AcquisitionTrigger.IntegrationConnect, TriggerParameters = """{"provider":"Strava"}""", DropChancePct = 100, IsEnabled = true },
        // Pulse Wristband → reach level 5
        new() { Id = new Guid("20000000-0000-0000-0000-000000000002"), ItemId = new Guid("10000000-0000-0000-0000-000000000009"), TriggerType = AcquisitionTrigger.LevelReached, TriggerParameters = """{"level":5}""", DropChancePct = 100, IsEnabled = true },
        // Energy Gel → random drop on any Running activity
        new() { Id = new Guid("20000000-0000-0000-0000-000000000003"), ItemId = new Guid("10000000-0000-0000-0000-000000000023"), TriggerType = AcquisitionTrigger.RandomDrop, TriggerParameters = """{"activityType":"Running"}""", DropChancePct = 10, IsEnabled = true },
        // XP Booster → complete 10 quests (stat milestone via quest completion)
        new() { Id = new Guid("20000000-0000-0000-0000-000000000004"), ItemId = new Guid("10000000-0000-0000-0000-000000000022"), TriggerType = AcquisitionTrigger.QuestCompletion, TriggerParameters = """{"questCount":10}""", DropChancePct = 100, IsEnabled = true },
        // Carbon X3 → reach 50 END stat
        new() { Id = new Guid("20000000-0000-0000-0000-000000000005"), ItemId = new Guid("10000000-0000-0000-0000-000000000005"), TriggerType = AcquisitionTrigger.StatMilestone, TriggerParameters = """{"stat":"END","threshold":50}""", DropChancePct = 100, IsEnabled = true },
        // Iron Headband → manual grant (starter item)
        new() { Id = new Guid("20000000-0000-0000-0000-000000000006"), ItemId = new Guid("10000000-0000-0000-0000-000000000007"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        // Paper-doll test items → manual grant only
        new() { Id = new Guid("20000000-0000-0000-0000-000000000007"), ItemId = new Guid("10000000-0000-0000-0000-000000000029"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000008"), ItemId = new Guid("10000000-0000-0000-0000-000000000030"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000009"), ItemId = new Guid("10000000-0000-0000-0000-000000000031"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000010"), ItemId = new Guid("10000000-0000-0000-0000-000000000032"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000011"), ItemId = new Guid("10000000-0000-0000-0000-000000000033"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000012"), ItemId = new Guid("10000000-0000-0000-0000-000000000034"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000013"), ItemId = new Guid("10000000-0000-0000-0000-000000000035"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
        new() { Id = new Guid("20000000-0000-0000-0000-000000000014"), ItemId = new Guid("10000000-0000-0000-0000-000000000036"), TriggerType = AcquisitionTrigger.Manual, TriggerParameters = "{}", DropChancePct = 100, IsEnabled = true },
    ];

    public async Task SeedCatalogAsync()
    {
        await EnsureLegacyAccessory2SlotMigratedAsync();

        var existingById = await db.Items.ToDictionaryAsync(i => i.Id);

        foreach (var catalogItem in CatalogItems)
        {
            if (existingById.TryGetValue(catalogItem.Id, out var existing))
            {
                CopyCatalogItem(catalogItem, existing);
            }
            else
            {
                db.Items.Add(CloneCatalogItem(catalogItem));
            }
        }

        await db.SaveChangesAsync();
    }

    public async Task SeedDropRulesAsync()
    {
        var existingItemIds = await db.Items.Select(i => i.Id).ToHashSetAsync();
        var existingById = await db.ItemDropRules.ToDictionaryAsync(r => r.Id);

        foreach (var dropRule in DropRules.Where(r => existingItemIds.Contains(r.ItemId)))
        {
            if (existingById.TryGetValue(dropRule.Id, out var existing))
            {
                existing.ItemId = dropRule.ItemId;
                existing.TriggerType = dropRule.TriggerType;
                existing.TriggerParameters = dropRule.TriggerParameters;
                existing.DropChancePct = dropRule.DropChancePct;
                existing.IsEnabled = dropRule.IsEnabled;
            }
            else
            {
                db.ItemDropRules.Add(CloneDropRule(dropRule));
            }
        }

        await db.SaveChangesAsync();
    }

    private static Item CloneCatalogItem(Item source)
    {
        var clone = new Item { Id = source.Id };
        CopyCatalogItem(source, clone);
        return clone;
    }

    private static void CopyCatalogItem(Item source, Item target)
    {
        target.Name = source.Name;
        target.Description = source.Description;
        target.Icon = source.Icon;
        target.Rarity = source.Rarity;
        target.Category = source.Category;
        target.SlotType = source.SlotType;
        target.XpBonusPct = source.XpBonusPct;
        target.StrBonus = source.StrBonus;
        target.EndBonus = source.EndBonus;
        target.AgiBonus = source.AgiBonus;
        target.FlxBonus = source.FlxBonus;
        target.StaBonus = source.StaBonus;
    }

    private static ItemDropRule CloneDropRule(ItemDropRule source) => new()
    {
        Id = source.Id,
        ItemId = source.ItemId,
        TriggerType = source.TriggerType,
        TriggerParameters = source.TriggerParameters,
        DropChancePct = source.DropChancePct,
        IsEnabled = source.IsEnabled,
    };

    private async Task EnsureLegacyAccessory2SlotMigratedAsync()
    {
        if (!db.Database.IsRelational()) return;

        await db.Database.ExecuteSqlRawAsync(
            """
            UPDATE "Items" SET "SlotType" = 'Accessory1' WHERE "SlotType" = 'Accessory2';

            DELETE FROM "EquipmentSlots" es2
            WHERE es2."SlotType" = 'Accessory2'
              AND EXISTS (
                  SELECT 1 FROM "EquipmentSlots" es1
                  WHERE es1."CharacterId" = es2."CharacterId"
                    AND es1."SlotType" = 'Accessory1'
              );

            UPDATE "EquipmentSlots" SET "SlotType" = 'Accessory1' WHERE "SlotType" = 'Accessory2';
            """);
    }

    public async Task BackfillLevelReachedRewardsAsync(CancellationToken ct = default)
    {
        var levelRules = await db.ItemDropRules
            .Where(r => r.TriggerType == AcquisitionTrigger.LevelReached
                        && r.IsEnabled
                        && r.DropChancePct >= 100)
            .ToListAsync(ct);

        var parsedRules = levelRules
            .Select(rule => new
            {
                Rule = rule,
                Level = TryReadRequiredLevel(rule.TriggerParameters)
            })
            .Where(x => x.Level.HasValue)
            .ToList();

        if (parsedRules.Count == 0) return;

        var characters = await db.Set<Character>()
            .Select(c => new { c.Id, c.Level, c.MaxInventorySlots })
            .ToListAsync(ct);

        foreach (var character in characters)
        {
            var existingItemIds = await db.CharacterItems
                .Where(ci => ci.CharacterId == character.Id)
                .Select(ci => ci.ItemId)
                .ToHashSetAsync(ct);

            var currentCount = existingItemIds.Count;
            foreach (var parsed in parsedRules
                         .Where(x => x.Level!.Value <= character.Level)
                         .OrderBy(x => x.Level!.Value))
            {
                if (existingItemIds.Contains(parsed.Rule.ItemId)) continue;
                if (currentCount >= character.MaxInventorySlots) break;

                db.CharacterItems.Add(new CharacterItem
                {
                    Id = Guid.NewGuid(),
                    CharacterId = character.Id,
                    ItemId = parsed.Rule.ItemId,
                    IsEquipped = false,
                    AcquiredAt = DateTime.UtcNow
                });
                existingItemIds.Add(parsed.Rule.ItemId);
                currentCount++;
            }
        }

        await db.SaveChangesAsync(ct);
    }

    private static int? TryReadRequiredLevel(string triggerParameters)
    {
        try
        {
            using var doc = JsonDocument.Parse(triggerParameters);
            return doc.RootElement.TryGetProperty("level", out var level)
                   && level.TryGetInt32(out var requiredLevel)
                ? requiredLevel
                : null;
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
