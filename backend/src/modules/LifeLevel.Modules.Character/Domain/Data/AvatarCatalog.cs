using LifeLevel.Modules.Character.Application.DTOs;

namespace LifeLevel.Modules.Character.Domain.Data;

public enum AvatarUnlockType
{
    Starter,
    Level,
    Rank,
    Streak,
    DailyQuests,
    BossesDefeated
}

public record AvatarDefinition(
    string Emoji,
    string Name,
    AvatarUnlockType UnlockType,
    int RequiredValue,
    string? RequiredRank,
    string UnlockRequirement,
    int SortOrder)
{
    public AvatarOptionResponse ToResponse(bool unlocked, bool equipped) =>
        new(Emoji, Name, unlocked, equipped, unlocked ? null : UnlockRequirement, SortOrder);
}

public static class AvatarCatalog
{
    public static readonly IReadOnlyList<AvatarDefinition> All =
    [
        new("🧙", "Wizard", AvatarUnlockType.Starter, 0, null, "Available from start", 0),
        new("⚔️", "Warrior", AvatarUnlockType.Starter, 0, null, "Available from start", 1),
        new("🏹", "Archer", AvatarUnlockType.Starter, 0, null, "Available from start", 2),
        new("🛡️", "Paladin", AvatarUnlockType.Starter, 0, null, "Available from start", 3),
        new("🧘", "Monk", AvatarUnlockType.Starter, 0, null, "Available from start", 4),
        new("🐺", "Wolf", AvatarUnlockType.Starter, 0, null, "Available from start", 5),
        new("🦊", "Fox", AvatarUnlockType.Starter, 0, null, "Available from start", 6),
        new("🥷", "Ninja", AvatarUnlockType.Starter, 0, null, "Available from start", 7),
        new("🦸", "Superhero", AvatarUnlockType.Starter, 0, null, "Available from start", 8),
        new("🧝", "Elf", AvatarUnlockType.Starter, 0, null, "Available from start", 9),
        new("👑", "Crown", AvatarUnlockType.Rank, 0, "Champion", "Reach Rank Champion", 10),
        new("🌟", "Star", AvatarUnlockType.Level, 10, null, "Reach Level 10", 11),
        new("💎", "Diamond", AvatarUnlockType.Level, 25, null, "Reach Level 25", 12),
        new("🔮", "Mystic", AvatarUnlockType.DailyQuests, 10, null, "Complete 10 daily quests", 13),
        new("⚡", "Lightning", AvatarUnlockType.Streak, 7, null, "Maintain a 7-day streak", 14),
        new("🌙", "Moon", AvatarUnlockType.BossesDefeated, 5, null, "Defeat 5 bosses", 15),
    ];

    public static AvatarDefinition? Find(string emoji) =>
        All.FirstOrDefault(a => a.Emoji == emoji);
}
