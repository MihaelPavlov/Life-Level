import '../../activity/models/activity_models.dart';

class LevelUpBlockedItem {
  final String itemId;
  final String name;
  final String icon;
  const LevelUpBlockedItem(this.itemId, this.name, this.icon);
  factory LevelUpBlockedItem.fromJson(Map<String, dynamic> j) =>
      LevelUpBlockedItem(j['itemId'] as String, j['name'] as String,
          j['icon'] as String? ?? '');
}

class LevelUpTitleInfo {
  final String titleId;
  final String name;
  final String emoji;
  const LevelUpTitleInfo(this.titleId, this.name, this.emoji);
  factory LevelUpTitleInfo.fromJson(Map<String, dynamic> j) => LevelUpTitleInfo(
      j['titleId'] as String, j['name'] as String, j['emoji'] as String? ?? '');
}

class LevelUpAvatarInfo {
  final String name;
  final String emoji;
  final int levelRequirement;
  const LevelUpAvatarInfo(this.name, this.emoji, this.levelRequirement);
  factory LevelUpAvatarInfo.fromJson(Map<String, dynamic> j) =>
      LevelUpAvatarInfo(j['name'] as String, j['emoji'] as String? ?? '',
          (j['levelRequirement'] as num).toInt());
}

class LevelUpRegionInfo {
  final String regionId;
  final String name;
  final String emoji;
  final int levelRequirement;
  const LevelUpRegionInfo(
      this.regionId, this.name, this.emoji, this.levelRequirement);
  factory LevelUpRegionInfo.fromJson(Map<String, dynamic> j) =>
      LevelUpRegionInfo(j['regionId'] as String, j['name'] as String,
          j['emoji'] as String? ?? '', (j['levelRequirement'] as num).toInt());
}

class LevelUpReceipt {
  final String id;
  final String source;
  final int previousLevel;
  final int newLevel;
  final int baseStatPointsGranted;
  final int bonusStatPointsGranted;
  final int powerGained;
  final int coinsGranted;
  final int previousInventorySlots;
  final int newInventorySlots;
  final List<GrantedItemInfo> grantedItems;
  final List<LevelUpBlockedItem> blockedItems;
  final List<LevelUpTitleInfo> grantedTitles;
  final List<LevelUpAvatarInfo> availableAvatars;
  final List<LevelUpRegionInfo> availableRegions;

  const LevelUpReceipt({
    required this.id,
    required this.source,
    required this.previousLevel,
    required this.newLevel,
    required this.baseStatPointsGranted,
    required this.bonusStatPointsGranted,
    required this.powerGained,
    required this.coinsGranted,
    required this.previousInventorySlots,
    required this.newInventorySlots,
    required this.grantedItems,
    required this.blockedItems,
    required this.grantedTitles,
    required this.availableAvatars,
    required this.availableRegions,
  });

  int get totalStatPoints => baseStatPointsGranted + bonusStatPointsGranted;
  int get levelsGained => newLevel - previousLevel;

  factory LevelUpReceipt.fromJson(Map<String, dynamic> j) => LevelUpReceipt(
        id: j['id'] as String,
        source: j['source'] as String? ?? '',
        previousLevel: (j['previousLevel'] as num).toInt(),
        newLevel: (j['newLevel'] as num).toInt(),
        baseStatPointsGranted:
            (j['baseStatPointsGranted'] as num? ?? 0).toInt(),
        bonusStatPointsGranted:
            (j['bonusStatPointsGranted'] as num? ?? 0).toInt(),
        powerGained: (j['powerGained'] as num? ?? 0).toInt(),
        coinsGranted: (j['coinsGranted'] as num? ?? 0).toInt(),
        previousInventorySlots:
            (j['previousInventorySlots'] as num? ?? 0).toInt(),
        newInventorySlots: (j['newInventorySlots'] as num? ?? 0).toInt(),
        grantedItems: _list(j, 'grantedItems', GrantedItemInfo.fromJson),
        blockedItems: _list(j, 'blockedItems', LevelUpBlockedItem.fromJson),
        grantedTitles: _list(j, 'grantedTitles', LevelUpTitleInfo.fromJson),
        availableAvatars:
            _list(j, 'availableAvatars', LevelUpAvatarInfo.fromJson),
        availableRegions:
            _list(j, 'availableRegions', LevelUpRegionInfo.fromJson),
      );
}

List<T> _list<T>(Map<String, dynamic> json, String key,
        T Function(Map<String, dynamic>) parse) =>
    (json[key] as List<dynamic>? ?? const [])
        .map((e) => parse(Map<String, dynamic>.from(e as Map)))
        .toList();
