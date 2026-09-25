namespace LifeLevel.Modules.Talents.Application.DTOs;

/// <summary>Per-tile state as read by the mobile Talents grid.</summary>
public enum TalentTileState
{
    /// <summary>Not owned yet.</summary>
    Locked,
    /// <summary>Owned — levelling up happens automatically via future draws, not a manual action.</summary>
    Owned,
}

public record TalentWalletView(long Coins, int Crystals, int OwnedCount, int CatalogCount);

public record TalentView(
    string Key,
    string Name,
    string Description,
    string IconKey,
    string Rarity,
    int MaxLevel,
    bool Owned,
    int Level,
    string State,
    string EffectText);

public record TalentScreenResponse(
    TalentWalletView Wallet,
    int DrawCount,
    int DrawCrystalCost,
    int DrawCoinCost,
    bool CanDraw,
    bool CollectionComplete,
    IReadOnlyList<TalentView> Talents);

/// <summary>
/// <see cref="CrystalsAwarded"/> is only ever non-zero when a duplicate draw hit a talent already
/// at max level (nothing left to level up, so it refunds Coins/Crystals instead) — otherwise a
/// duplicate just levels the talent up (see <see cref="Talent"/>'s new <c>Level</c>) for free
/// beyond the draw's own cost.
/// </summary>
public record TalentDrawResult(
    string Kind,                 // "newTalent" | "duplicate"
    bool IsNew,
    TalentView Talent,
    int CrystalsAwarded,
    int ShieldsGranted,
    TalentWalletView Wallet);
