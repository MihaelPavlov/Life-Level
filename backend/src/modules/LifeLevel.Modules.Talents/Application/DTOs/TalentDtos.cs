namespace LifeLevel.Modules.Talents.Application.DTOs;

/// <summary>Per-tile state as read by the mobile Talents grid.</summary>
public enum TalentTileState
{
    /// <summary>Not owned yet.</summary>
    Locked,
    /// <summary>Owned, at max level or without the shards/coins to upgrade.</summary>
    Owned,
    /// <summary>Owned and can be levelled up right now.</summary>
    Upgradeable,
}

public record TalentWalletView(long Coins, int Tokens, int OwnedCount, int CatalogCount);

public record TalentView(
    string Key,
    string Name,
    string Description,
    string IconKey,
    string Rarity,
    int MaxLevel,
    bool Owned,
    int Level,
    int Shards,
    string State,
    string EffectText,
    int? UpgradeShardCost,
    int? UpgradeCoinCost,
    bool CanUpgrade);

public record TalentScreenResponse(
    TalentWalletView Wallet,
    int DrawTokenCost,
    int DrawCoinCost,
    bool CanDraw,
    IReadOnlyList<TalentView> Talents);

public record TalentDrawResult(
    string Kind,                 // "newTalent" | "shards"
    bool IsNew,
    TalentView Talent,
    int ShardsAwarded,
    int ShieldsGranted,
    TalentWalletView Wallet);

public record TalentUpgradeResult(
    TalentView Talent,
    int NewLevel,
    string EffectText,
    int ShieldsGranted,
    TalentWalletView Wallet);
