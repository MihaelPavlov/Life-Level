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
  bool fail = false;

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
    if (fail) throw Exception('offline');
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

Future<void> _pumpScreen(WidgetTester tester, _FakeChests chests) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [regionChestServiceProvider.overrideWithValue(chests)],
    child: MaterialApp(home: RegionChestsScreen(worldService: _FakeWorld())),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
      'opening the chest keeps the region on screen and lands the loot in '
      'the wallet chips', (tester) async {
    final chests = _FakeChests();
    await _pumpScreen(tester, chests);

    // The ready chest takes focus first.
    expect(find.text('Forest of Endurance'), findsOneWidget);
    expect(find.text('Chest ready · tap it to open'), findsOneWidget);
    expect(find.text('1,250'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Open the region chest'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(chests.claims, 1);

    // Waiting on the server: the focus stays put and the wallet chips
    // haven't jumped ahead of the loot.
    expect(find.text('Forest of Endurance'), findsOneWidget);
    expect(find.text('Opening the chest…'), findsOneWidget);
    expect(find.text('1,250'), findsOneWidget);

    // Confirmed: the chest opens and the loot rises out of it.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('×150'), findsWidgets);
    expect(find.text('×20'), findsWidgets);

    // The loot flies into the chips, which then show the new balance.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('1,400'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    // No reward row or button under the chest any more.
    expect(find.text('Claimed'), findsNothing);
    expect(find.text('Region chest claimed'), findsOneWidget);
    // No second reveal popup any more.
    expect(find.text('You got loot!'), findsNothing);
    // Still the same region.
    expect(find.text('Forest of Endurance'), findsOneWidget);
  });

  testWidgets('a failed claim leaves the chest shut and ready', (tester) async {
    final chests = _FakeChests()..fail = true;
    await _pumpScreen(tester, chests);

    await tester.tap(find.bySemanticsLabel('Open the region chest'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(chests.claims, 1);
    expect(find.bySemanticsLabel('Open the region chest'), findsOneWidget);
    expect(find.text('Chest ready · tap it to open'), findsOneWidget);
    expect(find.text('1,250'), findsOneWidget);
    // Let the error toast time out.
    await tester.pump(const Duration(seconds: 5));
  });
}
