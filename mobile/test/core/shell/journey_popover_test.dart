import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/shell/widgets/journey_popover.dart';
import 'package:life_level/features/home/providers/world_progress_provider.dart';
import 'package:life_level/features/map/models/world_zone_models.dart';

/// Regression: the popover is always built (hidden) behind the Map button,
/// so any build error in it shows as a red box over the tab bar.
void main() {
  for (final open in [false, true]) {
    testWidgets('journey popover builds cleanly, open=$open', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final world = WorldFullData.fromJson({
        'zones': [
          {'id': 'a', 'name': 'Dawn Camp', 'type': 'standard', 'tier': 1},
          {
            'id': 'b',
            'name': 'Whispering Fork',
            'type': 'crossroads',
            'tier': 2
          },
        ],
        'edges': [
          {
            'id': 'e',
            'fromZoneId': 'a',
            'toZoneId': 'b',
            'distanceKm': 4.0,
            'isBidirectional': true
          },
        ],
        'characterLevel': 5,
        'userProgress': {
          'currentZoneId': 'a',
          'destinationZoneId': 'b',
          'currentEdgeId': 'e',
          'distanceTraveledOnEdge': 2.6
        },
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          worldProgressProvider.overrideWith((ref) async => world),
          currentRegionDetailProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(children: [
              Positioned.fill(
                  child: JourneyPopover(
                      open: open, onClose: () {}, onSync: () {})),
            ]),
          ),
        ),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
