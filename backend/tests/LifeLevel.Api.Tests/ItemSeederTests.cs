using LifeLevel.Api.Application.Services;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class ItemSeederTests
{
    [Fact]
    public async Task SeedCatalogAsync_WhenCatalogAlreadyHasRows_InsertsNewCatalogItems()
    {
        await using var db = CreateDb();
        db.Items.Add(new Item
        {
            Id = new Guid("10000000-0000-0000-0000-000000000001"),
            Name = "Old Apex",
            Description = "old",
            Icon = "?",
            Rarity = ItemRarity.Common,
            Category = ItemCategory.Accessory,
            SlotType = EquipmentSlotType.Hands,
        });
        await db.SaveChangesAsync();

        await new ItemSeeder(db).SeedCatalogAsync();

        var newChestItem = await db.Items.FindAsync(new Guid("10000000-0000-0000-0000-000000000036"));
        var updatedApex = await db.Items.FindAsync(new Guid("10000000-0000-0000-0000-000000000001"));

        Assert.NotNull(newChestItem);
        Assert.Equal("Vanguard Puffer Jacket", newChestItem!.Name);
        Assert.Equal(EquipmentSlotType.Chest, newChestItem.SlotType);
        Assert.Equal("Apex GPS Pro", updatedApex!.Name);
        Assert.Equal(EquipmentSlotType.Accessory1, updatedApex.SlotType);
    }

    [Fact]
    public async Task SeedDropRulesAsync_WhenRulesAlreadyExist_InsertsNewManualRules()
    {
        await using var db = CreateDb();
        var seeder = new ItemSeeder(db);
        await seeder.SeedCatalogAsync();

        db.ItemDropRules.Add(new ItemDropRule
        {
            Id = new Guid("20000000-0000-0000-0000-000000000001"),
            ItemId = new Guid("10000000-0000-0000-0000-000000000011"),
            TriggerType = AcquisitionTrigger.Manual,
            TriggerParameters = "{}",
            DropChancePct = 1,
            IsEnabled = false,
        });
        await db.SaveChangesAsync();

        await seeder.SeedDropRulesAsync();

        var newRule = await db.ItemDropRules.FindAsync(new Guid("20000000-0000-0000-0000-000000000014"));
        var updatedRule = await db.ItemDropRules.FindAsync(new Guid("20000000-0000-0000-0000-000000000001"));

        Assert.NotNull(newRule);
        Assert.Equal(new Guid("10000000-0000-0000-0000-000000000036"), newRule!.ItemId);
        Assert.True(newRule.IsEnabled);
        Assert.Equal(AcquisitionTrigger.IntegrationConnect, updatedRule!.TriggerType);
        Assert.Equal(100, updatedRule.DropChancePct);
    }

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString())
        .Options);
}
