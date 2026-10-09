enum RegionChestStatus { inProgress, ready, claimed, locked }

String regionChestProgressLabel(
  RegionChestStatus status,
  int completedZones,
  int totalZones,
) {
  if (status == RegionChestStatus.ready ||
      status == RegionChestStatus.claimed) {
    return 'REGION CLEARED';
  }
  return '$completedZones / $totalZones ZONES';
}

RegionChestStatus _status(String value) => RegionChestStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RegionChestStatus.inProgress,
    );

class RegionChestWallet {
  final int coins;
  final int gems;
  const RegionChestWallet({required this.coins, required this.gems});

  factory RegionChestWallet.fromJson(Map<String, dynamic> json) =>
      RegionChestWallet(
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
      );
}

class RegionChestEntry {
  final String regionId;
  final int chapterIndex;
  final int coins;
  final int gems;
  final RegionChestStatus status;
  final DateTime? claimedAtUtc;

  const RegionChestEntry({
    required this.regionId,
    required this.chapterIndex,
    required this.coins,
    required this.gems,
    required this.status,
    this.claimedAtUtc,
  });

  factory RegionChestEntry.fromJson(Map<String, dynamic> json) =>
      RegionChestEntry(
        regionId: json['regionId'] as String,
        chapterIndex: (json['chapterIndex'] as num).toInt(),
        coins: (json['coins'] as num).toInt(),
        gems: (json['gems'] as num).toInt(),
        status: _status(json['status'] as String),
        claimedAtUtc: json['claimedAtUtc'] == null
            ? null
            : DateTime.parse(json['claimedAtUtc'] as String),
      );

  RegionChestEntry claimed(DateTime at) => RegionChestEntry(
        regionId: regionId,
        chapterIndex: chapterIndex,
        coins: coins,
        gems: gems,
        status: RegionChestStatus.claimed,
        claimedAtUtc: at,
      );
}

class RegionChestsOverview {
  final RegionChestWallet wallet;
  final List<RegionChestEntry> regions;
  const RegionChestsOverview({required this.wallet, required this.regions});

  bool get hasReady =>
      regions.any((entry) => entry.status == RegionChestStatus.ready);

  factory RegionChestsOverview.fromJson(Map<String, dynamic> json) =>
      RegionChestsOverview(
        wallet:
            RegionChestWallet.fromJson(json['wallet'] as Map<String, dynamic>),
        regions: (json['regions'] as List<dynamic>)
            .map((item) =>
                RegionChestEntry.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  RegionChestsOverview apply(RegionChestClaimResult result) =>
      RegionChestsOverview(
        wallet: result.wallet,
        regions: [
          for (final entry in regions)
            if (entry.regionId == result.regionId)
              entry.claimed(result.claimedAtUtc)
            else
              entry,
        ],
      );

  RegionChestsOverview claimLocally(String regionId, DateTime at) {
    final chest =
        regions.where((entry) => entry.regionId == regionId).firstOrNull;
    if (chest == null || chest.status != RegionChestStatus.ready) return this;
    return RegionChestsOverview(
      wallet: RegionChestWallet(
        coins: wallet.coins + chest.coins,
        gems: wallet.gems + chest.gems,
      ),
      regions: [
        for (final entry in regions)
          entry.regionId == regionId ? entry.claimed(at) : entry,
      ],
    );
  }
}

class RegionChestClaimResult {
  final String regionId;
  final int coins;
  final int gems;
  final DateTime claimedAtUtc;
  final RegionChestWallet wallet;

  const RegionChestClaimResult({
    required this.regionId,
    required this.coins,
    required this.gems,
    required this.claimedAtUtc,
    required this.wallet,
  });

  factory RegionChestClaimResult.fromJson(Map<String, dynamic> json) =>
      RegionChestClaimResult(
        regionId: json['regionId'] as String,
        coins: (json['coins'] as num).toInt(),
        gems: (json['gems'] as num).toInt(),
        claimedAtUtc: DateTime.parse(json['claimedAtUtc'] as String),
        wallet:
            RegionChestWallet.fromJson(json['wallet'] as Map<String, dynamic>),
      );
}
