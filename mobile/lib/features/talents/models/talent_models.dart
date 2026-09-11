// Client models for the Talents screen (`GET /talents`, `POST /talents/draw`,
// `POST /talents/{key}/upgrade`). Plain immutable classes, hand-written `fromJson`.

enum TalentTileState { locked, owned, upgradeable, unknown }

TalentTileState _tileStateFrom(String? s) {
  switch (s) {
    case 'locked':
      return TalentTileState.locked;
    case 'owned':
      return TalentTileState.owned;
    case 'upgradeable':
      return TalentTileState.upgradeable;
    default:
      return TalentTileState.unknown;
  }
}

class TalentWallet {
  final int coins;
  final int tokens;
  final int ownedCount;
  final int catalogCount;

  const TalentWallet({
    required this.coins,
    required this.tokens,
    required this.ownedCount,
    required this.catalogCount,
  });

  factory TalentWallet.fromJson(Map<String, dynamic> j) => TalentWallet(
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        tokens: (j['tokens'] as num?)?.toInt() ?? 0,
        ownedCount: (j['ownedCount'] as num?)?.toInt() ?? 0,
        catalogCount: (j['catalogCount'] as num?)?.toInt() ?? 0,
      );
}

class TalentView {
  final String key;
  final String name;
  final String description;
  final String iconKey;
  final String rarity; // "Common" | "Rare" | "Epic"
  final int maxLevel;
  final bool owned;
  final int level;
  final int shards;
  final TalentTileState state;
  final String effectText;
  final int? upgradeShardCost;
  final int? upgradeCoinCost;
  final bool canUpgrade;

  const TalentView({
    required this.key,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.rarity,
    required this.maxLevel,
    required this.owned,
    required this.level,
    required this.shards,
    required this.state,
    required this.effectText,
    required this.upgradeShardCost,
    required this.upgradeCoinCost,
    required this.canUpgrade,
  });

  factory TalentView.fromJson(Map<String, dynamic> j) => TalentView(
        key: j['key'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        iconKey: j['iconKey'] as String? ?? '',
        rarity: j['rarity'] as String? ?? 'Common',
        maxLevel: (j['maxLevel'] as num?)?.toInt() ?? 10,
        owned: j['owned'] as bool? ?? false,
        level: (j['level'] as num?)?.toInt() ?? 0,
        shards: (j['shards'] as num?)?.toInt() ?? 0,
        state: _tileStateFrom(j['state'] as String?),
        effectText: j['effectText'] as String? ?? '',
        upgradeShardCost: (j['upgradeShardCost'] as num?)?.toInt(),
        upgradeCoinCost: (j['upgradeCoinCost'] as num?)?.toInt(),
        canUpgrade: j['canUpgrade'] as bool? ?? false,
      );

  bool get isMaxed => owned && level >= maxLevel;
}

class TalentScreen {
  final TalentWallet wallet;
  final int drawTokenCost;
  final int drawCoinCost;
  final bool canDraw;
  final List<TalentView> talents;

  const TalentScreen({
    required this.wallet,
    required this.drawTokenCost,
    required this.drawCoinCost,
    required this.canDraw,
    required this.talents,
  });

  factory TalentScreen.fromJson(Map<String, dynamic> j) => TalentScreen(
        wallet: TalentWallet.fromJson(
            j['wallet'] as Map<String, dynamic>? ?? const {}),
        drawTokenCost: (j['drawTokenCost'] as num?)?.toInt() ?? 1,
        drawCoinCost: (j['drawCoinCost'] as num?)?.toInt() ?? 300,
        canDraw: j['canDraw'] as bool? ?? false,
        talents: ((j['talents'] as List<dynamic>?) ?? const [])
            .map((e) => TalentView.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TalentDrawResult {
  final String kind; // "newTalent" | "shards"
  final bool isNew;
  final TalentView talent;
  final int shardsAwarded;
  final int shieldsGranted;
  final TalentWallet wallet;

  const TalentDrawResult({
    required this.kind,
    required this.isNew,
    required this.talent,
    required this.shardsAwarded,
    required this.shieldsGranted,
    required this.wallet,
  });

  factory TalentDrawResult.fromJson(Map<String, dynamic> j) => TalentDrawResult(
        kind: j['kind'] as String? ?? 'shards',
        isNew: j['isNew'] as bool? ?? false,
        talent: TalentView.fromJson(j['talent'] as Map<String, dynamic>),
        shardsAwarded: (j['shardsAwarded'] as num?)?.toInt() ?? 0,
        shieldsGranted: (j['shieldsGranted'] as num?)?.toInt() ?? 0,
        wallet: TalentWallet.fromJson(
            j['wallet'] as Map<String, dynamic>? ?? const {}),
      );
}

class TalentUpgradeResult {
  final TalentView talent;
  final int newLevel;
  final String effectText;
  final int shieldsGranted;
  final TalentWallet wallet;

  const TalentUpgradeResult({
    required this.talent,
    required this.newLevel,
    required this.effectText,
    required this.shieldsGranted,
    required this.wallet,
  });

  factory TalentUpgradeResult.fromJson(Map<String, dynamic> j) =>
      TalentUpgradeResult(
        talent: TalentView.fromJson(j['talent'] as Map<String, dynamic>),
        newLevel: (j['newLevel'] as num?)?.toInt() ?? 0,
        effectText: j['effectText'] as String? ?? '',
        shieldsGranted: (j['shieldsGranted'] as num?)?.toInt() ?? 0,
        wallet: TalentWallet.fromJson(
            j['wallet'] as Map<String, dynamic>? ?? const {}),
      );
}
