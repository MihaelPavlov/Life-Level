using LifeLevel.Api.Infrastructure.Persistence;
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
        new() { Id = new Guid("10000000-0000-0000-0000-000000000011"), Name = "Strava Sync Badge", Description = "Awarded for connecting your Strava account. Syncs all your runs.", Icon = "🔗", Rarity = ItemRarity.Rare, Category = ItemCategory.Tracker, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 8, EndBonus = 3 },

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
        new() { Id = new Guid("10000000-0000-0000-0000-000000000006"), Name = "Sport Buds", Description = "Wireless earbuds with motivational beat detection.", Icon = "🎧", Rarity = ItemRarity.Rare, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 5, StaBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000018"), Name = "Climbing Chalk Bag", Description = "Keeps your hands dry for bouldering and weightlifting.", Icon = "🎒", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, StrBonus = 4, FlxBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000019"), Name = "Resistance Band Set", Description = "Versatile bands for mobility and strength training.", Icon = "🔴", Rarity = ItemRarity.Common, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, StrBonus = 2, FlxBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000020"), Name = "Champion Gloves", Description = "Worn by warriors who have conquered the highest peaks.", Icon = "🥊", Rarity = ItemRarity.Legendary, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Hands, XpBonusPct = 10, StrBonus = 12, FlxBonus = 6 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000021"), Name = "Aura Stone", Description = "A mystical stone that pulses with workout energy.", Icon = "💎", Rarity = ItemRarity.Epic, Category = ItemCategory.Accessory, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 12, StaBonus = 8 },

        // === CONSUMABLES (stored in Accessory2 slot as "use" items) ===
        new() { Id = new Guid("10000000-0000-0000-0000-000000000022"), Name = "XP Booster", Description = "Grants ×2 XP for your next workout. Consumed on use.", Icon = "⚗️", Rarity = ItemRarity.Rare, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 100 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000023"), Name = "Energy Gel", Description = "A burst of energy. +5 to all stats for one session.", Icon = "💧", Rarity = ItemRarity.Common, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, StaBonus = 5, EndBonus = 2 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000024"), Name = "Streak Shield", Description = "Protects your streak for one missed day.", Icon = "🛡️", Rarity = ItemRarity.Epic, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 0 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000025"), Name = "KT Tape Roll", Description = "Supports injured muscles so you can keep training.", Icon = "🩹", Rarity = ItemRarity.Common, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, StaBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000026"), Name = "Phoenix Elixir", Description = "Legendary potion. Restore a broken streak instantly.", Icon = "🔥", Rarity = ItemRarity.Legendary, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 50 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000027"), Name = "Zone Compass", Description = "Instantly reveals the next locked zone on your map.", Icon = "🧭", Rarity = ItemRarity.Uncommon, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000028"), Name = "Boss Scroll", Description = "Summons a mini-boss to your current zone.", Icon = "📜", Rarity = ItemRarity.Rare, Category = ItemCategory.Consumable, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 0 },
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
    ];

    public async Task SeedCatalogAsync()
    {
        if (await db.Items.AnyAsync()) return;

        db.Items.AddRange(CatalogItems);
        await db.SaveChangesAsync();
    }

    public async Task SeedDropRulesAsync()
    {
        if (await db.ItemDropRules.AnyAsync()) return;

        var existingItemIds = await db.Items.Select(i => i.Id).ToHashSetAsync();
        var validRules = DropRules.Where(r => existingItemIds.Contains(r.ItemId)).ToList();
        if (validRules.Count == 0) return;

        db.ItemDropRules.AddRange(validRules);
        await db.SaveChangesAsync();
    }
}
