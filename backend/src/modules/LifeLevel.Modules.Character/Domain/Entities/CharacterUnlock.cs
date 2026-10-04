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

    /// <summary>How many workouts the player had logged when this unlock was released. The next
    /// tier waits for a workout beyond the highest of these (one tier per workout).</summary>
    public int ActivityCountAtUnlock { get; set; }
}
