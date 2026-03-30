using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class ItemSeeder(AppDbContext db)
{
    // Catalog items — one per slot type, various rarities matching the design mockup
    private static readonly Item[] CatalogItems =
    [
        new() { Id = new Guid("10000000-0000-0000-0000-000000000001"), Name = "Apex GPS Pro", Description = "Top-of-the-line GPS tracker with heart rate monitoring.", Icon = "⌚", Rarity = ItemRarity.Legendary, SlotType = EquipmentSlotType.Accessory1, XpBonusPct = 15, EndBonus = 0, AgiBonus = 0, StrBonus = 0, FlxBonus = 0, StaBonus = 8 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000002"), Name = "Aero Race Cap", Description = "Aerodynamic cap that keeps you cool on long runs.", Icon = "🧢", Rarity = ItemRarity.Epic, SlotType = EquipmentSlotType.Head, XpBonusPct = 8, EndBonus = 5, AgiBonus = 0, StrBonus = 0, FlxBonus = 0, StaBonus = 0 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000003"), Name = "Cryo Jersey", Description = "Moisture-wicking performance jersey with cooling tech.", Icon = "🎽", Rarity = ItemRarity.Rare, SlotType = EquipmentSlotType.Chest, XpBonusPct = 5, EndBonus = 0, AgiBonus = 3, StrBonus = 0, FlxBonus = 0, StaBonus = 5 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000004"), Name = "Grip Wraps", Description = "Lightweight wraps for improved grip and wrist support.", Icon = "🧤", Rarity = ItemRarity.Rare, SlotType = EquipmentSlotType.Hands, XpBonusPct = 0, EndBonus = 0, AgiBonus = 0, StrBonus = 8, FlxBonus = 5, StaBonus = 0 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000005"), Name = "Carbon X3", Description = "Carbon-plated racing shoes for maximum energy return.", Icon = "👟", Rarity = ItemRarity.Uncommon, SlotType = EquipmentSlotType.Feet, XpBonusPct = 3, EndBonus = 3, AgiBonus = 5, StrBonus = 0, FlxBonus = 0, StaBonus = 0 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000006"), Name = "Sport Buds", Description = "Wireless earbuds with motivational beat detection.", Icon = "🎧", Rarity = ItemRarity.Rare, SlotType = EquipmentSlotType.Accessory2, XpBonusPct = 5, EndBonus = 0, AgiBonus = 0, StrBonus = 0, FlxBonus = 0, StaBonus = 3 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000007"), Name = "Iron Headband", Description = "Simple but sturdy headband for intense workouts.", Icon = "🎽", Rarity = ItemRarity.Common, SlotType = EquipmentSlotType.Head, XpBonusPct = 0, EndBonus = 1, AgiBonus = 0, StrBonus = 0, FlxBonus = 0, StaBonus = 1 },
        new() { Id = new Guid("10000000-0000-0000-0000-000000000008"), Name = "Trail Runner X5", Description = "All-terrain trail running shoes.", Icon = "👟", Rarity = ItemRarity.Epic, SlotType = EquipmentSlotType.Feet, XpBonusPct = 10, EndBonus = 5, AgiBonus = 8, StrBonus = 0, FlxBonus = 0, StaBonus = 0 },
    ];

    public async Task SeedCatalogAsync()
    {
        // Only seed if no items exist yet
        if (await db.Items.AnyAsync()) return;

        db.Items.AddRange(CatalogItems);
        await db.SaveChangesAsync();
    }
}
