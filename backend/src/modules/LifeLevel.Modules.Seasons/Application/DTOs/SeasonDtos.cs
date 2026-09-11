namespace LifeLevel.Modules.Seasons.Application.DTOs;

/// <summary>Tile state as read by the mobile Season Track screen.</summary>
public enum SeasonTileState
{
    /// <summary>Reached and already collected.</summary>
    Received,
    /// <summary>Not reached yet, or Founder-locked (no pass).</summary>
    Locked,
    /// <summary>The single next tier you are progressing toward.</summary>
    Pending,
    /// <summary>Reached, unclaimed — tap to collect.</summary>
    Ready,
}

public record SeasonRewardView(
    string Type,
    string Label,
    string IconKey,
    int Amount,
    string? Rarity,
    string State);

public record SeasonTierView(
    int Tier,
    bool IsMilestone,
    SeasonRewardView Free,
    SeasonRewardView Founder);

public record SeasonHeader(
    Guid Id,
    int Number,
    string Name,
    string Theme,
    DateTime StartsAt,
    DateTime EndsAt,
    int DaysLeft);

public record NextRewardView(int Tier, string Label, string Track);

public record SeasonTrackResponse(
    bool HasActiveSeason,
    SeasonHeader? Season,
    int XpPerTier,
    int TierCount,
    int MilestoneTier,
    long SeasonXp,
    int CurrentTier,
    int XpIntoTier,
    int XpToNextTier,
    bool HasFounderPass,
    NextRewardView? NextReward,
    IReadOnlyList<SeasonTierView> Tiers);

public record SeasonClaimResult(
    int Tier,
    string Track,
    string Label,
    long XpAwarded,
    bool LeveledUp,
    int? NewLevel,
    string? GrantedItemName,
    string? GrantedTitleKey);
