import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/widgets/zone_detail_sheet.dart';

void main() {
  testWidgets('set destination ignores rapid repeated taps while submitting',
      (tester) async {
    final request = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZoneDetailSheet(
              node: const ZoneNode(
                id: 'next-zone',
                name: 'Next Zone',
                emoji: '🏕️',
                description: 'The next stop on the trail.',
                tier: 1,
                levelRequirement: 1,
                xpReward: 100,
                distanceKm: 2,
                status: ZoneNodeStatus.next,
                isCrossroads: false,
                isBoss: false,
                isChest: false,
                isDungeon: false,
              ),
              regionName: 'Test Region',
              userLevel: 1,
              activeJourney: null,
              isDestination: false,
              onSetDestination: () {
                calls++;
                return request.future;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('→ Set as destination'));
    await tester.tap(find.text('→ Set as destination'));
    await tester.pump();

    expect(calls, 1);
    expect(find.text('Setting destination…'), findsOneWidget);

    request.complete();
    await tester.pump();
  });
}
