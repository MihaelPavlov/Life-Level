import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/widgets/crossroads_choice_sheet.dart';

ZoneNode _node(
  String id,
  String name, {
  bool isCrossroads = false,
  String? branchOf,
  double km = 5,
  int xp = 500,
}) =>
    ZoneNode(
      id: id,
      name: name,
      emoji: '',
      description: '',
      tier: 1,
      levelRequirement: 1,
      xpReward: xp,
      distanceKm: km,
      status: ZoneNodeStatus.available,
      isCrossroads: isCrossroads,
      isBoss: false,
      isChest: false,
      isDungeon: false,
      branchOf: branchOf,
    );

final _fork = _node('fork', 'Twin Roads Fork', isCrossroads: true);
final _valley =
    _node('valley', 'Valley Road', branchOf: 'fork', km: 8, xp: 450);
final _ruined =
    _node('ruined', 'Ruined Pass', branchOf: 'fork', km: 5, xp: 700);

Widget _harness({
  String? alreadyChosen,
  String? initialSelected,
  required Future<void> Function(ZoneNode) onChoose,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CrossroadsChoiceSheet(
            crossroads: _fork,
            branches: [_valley, _ruined],
            alreadyChosenBranchId: alreadyChosen,
            initialSelectedBranchId: initialSelected,
            onChoose: onChoose,
          ),
        ),
      ),
    );

void main() {
  testWidgets('tapping a card selects it; only the button commits',
      (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(_harness(
      initialSelected: 'valley',
      onChoose: (n) async => chosen.add(n.id),
    ));

    expect(find.text('Take Valley Road →'), findsOneWidget);
    expect(find.text('🔒 Ruined Pass locks once you choose.'), findsOneWidget);

    await tester.tap(find.text('Ruined Pass'));
    await tester.pump();
    expect(chosen, isEmpty, reason: 'selecting a card must not commit');
    expect(find.text('Take Ruined Pass →'), findsOneWidget);
    expect(find.text('🔒 Valley Road locks once you choose.'), findsOneWidget);

    await tester.tap(find.text('Take Ruined Pass →'));
    await tester.pump();
    expect(chosen, ['ruined']);
  });

  testWidgets('defaults to the first branch when no initial selection',
      (tester) async {
    await tester.pumpWidget(_harness(onChoose: (_) async {}));
    expect(find.text('Take Valley Road →'), findsOneWidget);
  });

  testWidgets('button ignores repeated taps while the choice is in flight',
      (tester) async {
    final request = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(_harness(
      onChoose: (_) {
        calls++;
        return request.future;
      },
    ));

    await tester.tap(find.text('Take Valley Road →'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Take Valley Road →'));
    await tester.pump();
    expect(calls, 1);

    request.complete();
    await tester.pumpAndSettle();
    expect(find.text('Take Valley Road →'), findsOneWidget);
  });

  testWidgets('already chosen shows pills and no button', (tester) async {
    await tester.pumpWidget(_harness(
      alreadyChosen: 'valley',
      onChoose: (_) async {},
    ));
    expect(find.text('CHOSEN'), findsOneWidget);
    expect(find.text('🔒 LOCKED'), findsOneWidget);
    expect(find.textContaining('Take '), findsNothing);
    expect(find.text('Your path is locked in.'), findsOneWidget);
  });
}
