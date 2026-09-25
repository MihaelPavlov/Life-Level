using LifeLevel.Modules.Achievements.Domain.Enums;

namespace LifeLevel.Modules.Achievements.Domain;

/// <summary>
/// Reward Roads economy in one place: what an achievement pays on claim and what
/// each stage chest holds. Stage chests reuse the Shop chests (item rarity + art).
/// </summary>
public static class AchievementRewardTable
{
    public static (int Coins, int Gems) AchievementReward(AchievementTier tier) => tier switch
    {
        AchievementTier.Common => (50, 1),
        AchievementTier.Uncommon => (150, 3),
        AchievementTier.Rare => (400, 8),
        AchievementTier.Epic => (1000, 20),
        AchievementTier.Legendary => (2500, 50),
        _ => (0, 0),
    };

    public static StageChest Chest(AchievementTier tier) => tier switch
    {
        AchievementTier.Common => new("wayfarer", "Wayfarer Chest", "Common", 200, 2),
        AchievementTier.Uncommon => new("wayfarer", "Wayfarer Chest", "Common", 500, 5),
        AchievementTier.Rare => new("adept", "Adept Chest", "Rare", 1000, 10),
        AchievementTier.Epic => new("adept", "Adept Chest", "Rare", 2000, 20),
        _ => new("champion", "Champion Chest", "Legendary", 5000, 50),
    };

    public record StageChest(string Key, string Name, string ItemRarity, int Coins, int Gems);
}
