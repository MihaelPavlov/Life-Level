import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/map/models/region_chest_models.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/providers/region_chest_provider.dart';
import 'package:life_level/features/map/screens/region_chests_screen.dart';
import 'package:life_level/features/map/services/region_chest_service.dart';
import 'package:life_level/features/map/services/world_zone_service.dart';

class _FakeWorld extends WorldZoneService {
  @override
  Future<WorldMapData> getWorldMap() async => WorldMapData.fromJson({
        'user': <String, dynamic>{},
        'regions': [
          {
            'id': 'forest',
            'name': 'Forest of Endurance',
            'chapterIndex': 1,
            'status': 'completed',
            'completedZones': 10,
            'totalZones': 10,
          },
          {
            'id': 'ocean',
            'name': 'Ocean of Balance',
            'chapterIndex': 2,
            'status': 'active',
            'completedZones': 1,
            'totalZones': 8,
          },
        ],
      });
}

class _FakeChests extends RegionChestService {
  int claims = 0;

  @override
  Future<RegionChestsOverview> getOverview() async =>
      RegionChestsOverview.fromJson({
        'wallet': {'coins': 1250, 'gems': 18},
        'regions': [
          {
            'regionId': 'forest',
            'chapterIndex': 1,
            'coins': 150,
            'gems': 20,
            'status': 'ready',
          },
          {
            'regionId': 'ocean',
            'chapterIndex': 2,
            'coins': 150,
            'gems': 20,
            'status': 'inProgress',
          },
        ],
      });

  @override
  Future<RegionChestClaimResult> claim(String regionId) async {
    claims++;
    return RegionChestClaimResult.fromJson({
      'regionId': regionId,
      'coins': 150,
      'gems': 20,
      'status': 'claimed',
      'claimedAtUtc': '2026-10-02T09:00:00Z',
      'wallet': {'coins': 1400, 'gems': 38},
    });
  }
}

void main() {
  testWidgets(
      'claiming keeps the claimed region on screen and shows the reward reveal',
      (tester) async {
    final chests = _FakeChests();
    await tester.pumpWidget(ProviderScope(
      overrides: [regionChestServiceProvider.overrideWithValue(chests)],
      child: MaterialApp(home: RegionChestsScreen(worldService: _FakeWorld())),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The ready chest takes focus first.
    expect(find.text('Forest of Endurance'), findsOneWidget);
    expect(find.text('Region boss resolved — chest ready'), findsOneWidget);

    await tester.tap(find.text('Rewards'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(chests.claims, 1);

    // Before the fix the focus jumped to Ocean of Balance here, tearing down
    // the panel mid-claim: no lid opening and no reveal.
    expect(find.text('Forest of Endurance'), findsOneWidget);
    expect(find.text('Region chest claimed'), findsOneWidget);
    expect(find.text('Opening…'), findsNothing);

    // Lids open, beams rise, then the reward reveal pops up.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('You got loot!'), findsWidgets);
    expect(find.text('×150'), findsWidgets);
    expect(find.text('Tap to close'), findsOneWidget);
  });
}
