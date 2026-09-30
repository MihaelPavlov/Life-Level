namespace LifeLevel.Modules.Character.Domain.Entities;

/// <summary>
/// One feature a player has unlocked through play (guided unlocks). <see cref="SeenAt"/> is set when
/// the unlock ceremony was shown, <see cref="TouredAt"/> when its guided tour was finished.
/// </summary>
public class CharacterUnlock
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Key { get; set; } = string.Empty;
    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SeenAt { get; set; }
    public DateTime? TouredAt { get; set; }
}
