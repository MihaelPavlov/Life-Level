namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// What a player has done so far, read across modules, so the Character module can decide which
/// features are unlocked (guided unlocks). Every fact is derived from state that already exists.
/// </summary>
public interface IUnlockFactsReadPort
{
    Task<UnlockFacts> GetAsync(Guid userId, CancellationToken ct = default);
}

public record UnlockFacts(
    bool SetupComplete,
    int ActivityCount,
    bool HasDistance,
    int ItemCount,
    int ZonesReached,
    int Level,
    int LongestStreak,
    bool BossSeen,
    DateTime? CharacterCreatedAt = null,
    int TitlesEarned = 0,
    bool RankReached = false);
