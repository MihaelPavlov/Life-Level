// Client models for the Season Track (`GET /season`, `POST /season/claim`,
// `POST /season/pass/purchase`). Plain immutable classes, hand-written `fromJson`.

enum SeasonRewardState { received, locked, pending, ready, unknown }

SeasonRewardState _stateFrom(String? s) {
  switch (s) {
    case 'received':
      return SeasonRewardState.received;
    case 'locked':
      return SeasonRewardState.locked;
    case 'pending':
      return SeasonRewardState.pending;
    case 'ready':
      return SeasonRewardState.ready;
    default:
      return SeasonRewardState.unknown;
  }
}

class SeasonRewardView {
  final String type;
  final String label;
  final String iconKey;
  final int amount;
  final String? rarity;
  final SeasonRewardState state;

  const SeasonRewardView({
    required this.type,
    required this.label,
    required this.iconKey,
    required this.amount,
    required this.rarity,
    required this.state,
  });

  factory SeasonRewardView.fromJson(Map<String, dynamic> j) => SeasonRewardView(
        type: j['type'] as String? ?? 'None',
        label: j['label'] as String? ?? '—',
        iconKey: j['iconKey'] as String? ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        rarity: j['rarity'] as String?,
        state: _stateFrom(j['state'] as String?),
      );

  bool get isClaimable => state == SeasonRewardState.ready;
}

class SeasonTier {
  final int tier;
  final bool isMilestone;
  final SeasonRewardView free;
  final SeasonRewardView founder;

  const SeasonTier({
    required this.tier,
    required this.isMilestone,
    required this.free,
    required this.founder,
  });

  factory SeasonTier.fromJson(Map<String, dynamic> j) => SeasonTier(
        tier: (j['tier'] as num).toInt(),
        isMilestone: j['isMilestone'] as bool? ?? false,
        free: SeasonRewardView.fromJson(j['free'] as Map<String, dynamic>),
        founder: SeasonRewardView.fromJson(j['founder'] as Map<String, dynamic>),
      );
}

class SeasonHeader {
  final String id;
  final int number;
  final String name;
  final String theme;
  final DateTime endsAt;
  final int daysLeft;

  const SeasonHeader({
    required this.id,
    required this.number,
    required this.name,
    required this.theme,
    required this.endsAt,
    required this.daysLeft,
  });

  factory SeasonHeader.fromJson(Map<String, dynamic> j) => SeasonHeader(
        id: j['id'] as String,
        number: (j['number'] as num).toInt(),
        name: j['name'] as String? ?? 'Season',
        theme: j['theme'] as String? ?? 'ember',
        endsAt: DateTime.tryParse(j['endsAt'] as String? ?? '') ?? DateTime.now(),
        daysLeft: (j['daysLeft'] as num?)?.toInt() ?? 0,
      );
}

class NextReward {
  final int tier;
  final String label;
  final String track;
  const NextReward({required this.tier, required this.label, required this.track});

  factory NextReward.fromJson(Map<String, dynamic> j) => NextReward(
        tier: (j['tier'] as num).toInt(),
        label: j['label'] as String? ?? '',
        track: j['track'] as String? ?? 'Free',
      );
}

class SeasonTrack {
  final bool hasActiveSeason;
  final SeasonHeader? season;
  final int xpPerTier;
  final int tierCount;
  final int milestoneTier;
  final int seasonXp;
  final int currentTier;
  final int xpIntoTier;
  final int xpToNextTier;
  final bool hasFounderPass;
  final NextReward? nextReward;
  final List<SeasonTier> tiers;

  const SeasonTrack({
    required this.hasActiveSeason,
    required this.season,
    required this.xpPerTier,
    required this.tierCount,
    required this.milestoneTier,
    required this.seasonXp,
    required this.currentTier,
    required this.xpIntoTier,
    required this.xpToNextTier,
    required this.hasFounderPass,
    required this.nextReward,
    required this.tiers,
  });

  factory SeasonTrack.fromJson(Map<String, dynamic> j) => SeasonTrack(
        hasActiveSeason: j['hasActiveSeason'] as bool? ?? false,
        season: j['season'] == null
            ? null
            : SeasonHeader.fromJson(j['season'] as Map<String, dynamic>),
        xpPerTier: (j['xpPerTier'] as num?)?.toInt() ?? 0,
        tierCount: (j['tierCount'] as num?)?.toInt() ?? 0,
        milestoneTier: (j['milestoneTier'] as num?)?.toInt() ?? 0,
        seasonXp: (j['seasonXp'] as num?)?.toInt() ?? 0,
        currentTier: (j['currentTier'] as num?)?.toInt() ?? 0,
        xpIntoTier: (j['xpIntoTier'] as num?)?.toInt() ?? 0,
        xpToNextTier: (j['xpToNextTier'] as num?)?.toInt() ?? 0,
        hasFounderPass: j['hasFounderPass'] as bool? ?? false,
        nextReward: j['nextReward'] == null
            ? null
            : NextReward.fromJson(j['nextReward'] as Map<String, dynamic>),
        tiers: ((j['tiers'] as List?) ?? const [])
            .map((e) => SeasonTier.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  double get tierProgress =>
      xpPerTier <= 0 ? 0 : (xpIntoTier / xpPerTier).clamp(0.0, 1.0);
}

class SeasonClaimResult {
  final int tier;
  final String track;
  final String label;
  final int xpAwarded;
  final bool leveledUp;
  final int? newLevel;
  final String? grantedItemName;
  final String? grantedTitleKey;

  const SeasonClaimResult({
    required this.tier,
    required this.track,
    required this.label,
    required this.xpAwarded,
    required this.leveledUp,
    required this.newLevel,
    required this.grantedItemName,
    required this.grantedTitleKey,
  });

  factory SeasonClaimResult.fromJson(Map<String, dynamic> j) => SeasonClaimResult(
        tier: (j['tier'] as num).toInt(),
        track: j['track'] as String? ?? 'Free',
        label: j['label'] as String? ?? 'Reward',
        xpAwarded: (j['xpAwarded'] as num?)?.toInt() ?? 0,
        leveledUp: j['leveledUp'] as bool? ?? false,
        newLevel: (j['newLevel'] as num?)?.toInt(),
        grantedItemName: j['grantedItemName'] as String?,
        grantedTitleKey: j['grantedTitleKey'] as String?,
      );
}
