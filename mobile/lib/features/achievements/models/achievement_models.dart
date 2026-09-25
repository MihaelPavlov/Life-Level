import 'package:flutter/material.dart';

const _kCommonColor = Color(0xFF8b949e);
const _kUncommonColor = Color(0xFF3fb950);
const _kRareColor = Color(0xFF4f9eff);
const _kEpicColor = Color(0xFFa371f7);
const _kLegendaryColor = Color(0xFFf5a623);

class AchievementDto {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final String tier;
  final Color tierColor;
  final int xpReward;
  final double targetValue;
  final String targetUnit;
  final double currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int coinReward;
  final int gemReward;
  final bool isClaimed;

  const AchievementDto({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.tier,
    required this.tierColor,
    required this.xpReward,
    required this.targetValue,
    required this.targetUnit,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
    this.coinReward = 0,
    this.gemReward = 0,
    this.isClaimed = false,
  });

  double get progressPercent =>
      targetValue <= 0 ? 0.0 : (currentValue / targetValue).clamp(0.0, 1.0);

  bool get isInProgress => !isUnlocked && currentValue > 0;

  /// Unlocked but its reward not collected yet.
  bool get isReady => isUnlocked && !isClaimed;

  factory AchievementDto.fromJson(Map<String, dynamic> json) {
    final tierStr = json['tier'] as String? ?? 'Common';
    return AchievementDto(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      category: json['category'] as String? ?? '',
      tier: tierStr,
      tierColor: _tierColor(tierStr),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      targetUnit: json['targetUnit'] as String? ?? '',
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
      coinReward: (json['coinReward'] as num?)?.toInt() ?? 0,
      gemReward: (json['gemReward'] as num?)?.toInt() ?? 0,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }

  static Color _tierColor(String tier) {
    switch (tier) {
      case 'Uncommon':
        return _kUncommonColor;
      case 'Rare':
        return _kRareColor;
      case 'Epic':
        return _kEpicColor;
      case 'Legendary':
        return _kLegendaryColor;
      default:
        return _kCommonColor;
    }
  }
}

class CheckUnlocksResult {
  final List<String> newlyUnlockedIds;
  const CheckUnlocksResult({required this.newlyUnlockedIds});

  factory CheckUnlocksResult.fromJson(Map<String, dynamic> json) =>
      CheckUnlocksResult(
        newlyUnlockedIds: (json['newlyUnlockedIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

// ── Reward Roads ─────────────────────────────────────────────────────────────

class AchievementWallet {
  final int coins;
  final int gems;
  const AchievementWallet({required this.coins, required this.gems});

  factory AchievementWallet.fromJson(Map<String, dynamic> json) =>
      AchievementWallet(
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
      );
}

/// One tier of a road. Its chest opens once every achievement in it is claimed.
class AchievementStage {
  final String tier;
  final String chestKey;
  final String chestName;
  final String chestItemRarity;
  final int chestCoins;
  final int chestGems;
  final int total;
  final int unlocked;
  final int claimed;
  final int ready;
  final bool chestReady;
  final bool chestOpened;
  final List<AchievementDto> achievements;

  const AchievementStage({
    required this.tier,
    required this.chestKey,
    required this.chestName,
    required this.chestItemRarity,
    required this.chestCoins,
    required this.chestGems,
    required this.total,
    required this.unlocked,
    required this.claimed,
    required this.ready,
    required this.chestReady,
    required this.chestOpened,
    required this.achievements,
  });

  int get toGo => total - unlocked;

  factory AchievementStage.fromJson(Map<String, dynamic> json) =>
      AchievementStage(
        tier: json['tier'] as String? ?? 'Common',
        chestKey: json['chestKey'] as String? ?? 'wayfarer',
        chestName: json['chestName'] as String? ?? 'Chest',
        chestItemRarity: json['chestItemRarity'] as String? ?? 'Common',
        chestCoins: (json['chestCoins'] as num?)?.toInt() ?? 0,
        chestGems: (json['chestGems'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        unlocked: (json['unlocked'] as num?)?.toInt() ?? 0,
        claimed: (json['claimed'] as num?)?.toInt() ?? 0,
        ready: (json['ready'] as num?)?.toInt() ?? 0,
        chestReady: json['chestReady'] as bool? ?? false,
        chestOpened: json['chestOpened'] as bool? ?? false,
        achievements: (json['achievements'] as List<dynamic>? ?? [])
            .map((e) => AchievementDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One category's road of tier stages.
class AchievementRoad {
  final String category;
  final int total;
  final int claimed;
  final int ready;

  /// Index into [stages] of the first stage whose chest is still closed;
  /// -1 once every chest on the road is open.
  final int currentStage;
  final List<AchievementStage> stages;

  const AchievementRoad({
    required this.category,
    required this.total,
    required this.claimed,
    required this.ready,
    required this.currentStage,
    required this.stages,
  });

  bool get isComplete => currentStage < 0;
  AchievementStage? get current => isComplete ? null : stages[currentStage];
  bool get hasChestReady => stages.any((s) => s.chestReady);

  factory AchievementRoad.fromJson(Map<String, dynamic> json) =>
      AchievementRoad(
        category: json['category'] as String? ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
        claimed: (json['claimed'] as num?)?.toInt() ?? 0,
        ready: (json['ready'] as num?)?.toInt() ?? 0,
        currentStage: (json['currentStage'] as num?)?.toInt() ?? -1,
        stages: (json['stages'] as List<dynamic>? ?? [])
            .map((e) => AchievementStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AchievementRoadsData {
  final AchievementWallet wallet;
  final int readyCount;
  final int chestsReady;
  final List<AchievementRoad> roads;

  const AchievementRoadsData({
    required this.wallet,
    required this.readyCount,
    required this.chestsReady,
    required this.roads,
  });

  AchievementRoad? road(String category) =>
      roads.where((r) => r.category == category).firstOrNull;

  factory AchievementRoadsData.fromJson(Map<String, dynamic> json) =>
      AchievementRoadsData(
        wallet: AchievementWallet.fromJson(
            json['wallet'] as Map<String, dynamic>? ?? const {}),
        readyCount: (json['readyCount'] as num?)?.toInt() ?? 0,
        chestsReady: (json['chestsReady'] as num?)?.toInt() ?? 0,
        roads: (json['roads'] as List<dynamic>? ?? [])
            .map((e) => AchievementRoad.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AchievementClaimResult {
  final List<String> claimedIds;
  final int xp;
  final int coins;
  final int gems;

  /// Stages this claim finished whose chest is ready to open: (category, tier).
  final List<(String, String)> chestsReady;
  final AchievementWallet wallet;

  const AchievementClaimResult({
    required this.claimedIds,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.chestsReady,
    required this.wallet,
  });

  factory AchievementClaimResult.fromJson(Map<String, dynamic> json) =>
      AchievementClaimResult(
        claimedIds: (json['claimedIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        chestsReady: (json['chestsReady'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .map((e) => (e['category'] as String, e['tier'] as String))
            .toList(),
        wallet: AchievementWallet.fromJson(
            json['wallet'] as Map<String, dynamic>? ?? const {}),
      );
}

class StageChestItem {
  final String id;
  final String name;
  final String icon;
  final String rarity;
  final String? inventoryIconUrl;
  const StageChestItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.rarity,
    this.inventoryIconUrl,
  });

  factory StageChestItem.fromJson(Map<String, dynamic> json) => StageChestItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '🎁',
        rarity: json['rarity'] as String? ?? 'Common',
        inventoryIconUrl: json['inventoryIconUrl'] as String?,
      );
}

class StageChestOpenResult {
  final String category;
  final String tier;
  final String chestKey;
  final String chestName;
  final StageChestItem? item;
  final int coins;
  final int gems;
  final AchievementWallet wallet;

  const StageChestOpenResult({
    required this.category,
    required this.tier,
    required this.chestKey,
    required this.chestName,
    required this.item,
    required this.coins,
    required this.gems,
    required this.wallet,
  });

  factory StageChestOpenResult.fromJson(Map<String, dynamic> json) =>
      StageChestOpenResult(
        category: json['category'] as String? ?? '',
        tier: json['tier'] as String? ?? '',
        chestKey: json['chestKey'] as String? ?? 'wayfarer',
        chestName: json['chestName'] as String? ?? 'Chest',
        item: json['item'] == null
            ? null
            : StageChestItem.fromJson(json['item'] as Map<String, dynamic>),
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        wallet: AchievementWallet.fromJson(
            json['wallet'] as Map<String, dynamic>? ?? const {}),
      );
}
