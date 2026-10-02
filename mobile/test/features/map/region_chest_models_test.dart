import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/map/models/region_chest_models.dart';

void main() {
  test('resolved branch regions show cleared instead of impossible totals', () {
    expect(
      regionChestProgressLabel(RegionChestStatus.ready, 10, 11),
      'REGION CLEARED',
    );
    expect(
      regionChestProgressLabel(RegionChestStatus.claimed, 8, 9),
      'REGION CLEARED',
    );
    expect(
      regionChestProgressLabel(RegionChestStatus.inProgress, 8, 9),
      '8 / 9 ZONES',
    );
  });

  test('overview parses authoritative wallet and ready state', () {
    final overview = RegionChestsOverview.fromJson({
      'wallet': {'coins': 1234, 'gems': 56},
      'regions': [
        {
          'regionId': 'r1',
          'chapterIndex': 1,
          'coins': 150,
          'gems': 20,
          'status': 'ready',
          'claimedAtUtc': null,
        },
      ],
    });

    expect(overview.wallet.coins, 1234);
    expect(overview.wallet.gems, 56);
    expect(overview.hasReady, isTrue);
    expect(overview.regions.single.status, RegionChestStatus.ready);
  });

  test('claim result updates wallet and marks only its region claimed', () {
    const overview = RegionChestsOverview(
      wallet: RegionChestWallet(coins: 0, gems: 0),
      regions: [
        RegionChestEntry(
          regionId: 'r1',
          chapterIndex: 1,
          coins: 150,
          gems: 20,
          status: RegionChestStatus.ready,
        ),
        RegionChestEntry(
          regionId: 'r2',
          chapterIndex: 2,
          coins: 150,
          gems: 20,
          status: RegionChestStatus.inProgress,
        ),
      ],
    );
    final at = DateTime.utc(2026, 10, 2);
    final updated = overview.apply(RegionChestClaimResult(
      regionId: 'r1',
      coins: 150,
      gems: 20,
      claimedAtUtc: at,
      wallet: const RegionChestWallet(coins: 150, gems: 20),
    ));

    expect(updated.wallet.coins, 150);
    expect(updated.wallet.gems, 20);
    expect(updated.hasReady, isFalse);
    expect(updated.regions.first.status, RegionChestStatus.claimed);
    expect(updated.regions.last.status, RegionChestStatus.inProgress);
  });
}
