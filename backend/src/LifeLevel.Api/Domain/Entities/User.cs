using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public UserRole Role { get; set; } = UserRole.Player;

    public Character? Character { get; set; }
    public ICollection<UserRingItem> RingItems { get; set; } = [];
    public Streak? Streak { get; set; }
    public LoginReward? LoginReward { get; set; }
    public ICollection<UserQuestProgress> QuestProgress { get; set; } = new List<UserQuestProgress>();
}
