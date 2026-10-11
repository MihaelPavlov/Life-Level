import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/boss/models/boss_damage_history.dart';
import 'package:life_level/features/boss/models/boss_list_item.dart';
import 'package:life_level/features/boss/providers/boss_provider.dart';
import 'package:life_level/features/boss/screens/boss_battle_screen.dart';
import 'package:life_level/features/boss/widgets/boss_duel_arena.dart';
import 'package:life_level/features/items/models/item_models.dart';
import 'package:life_level/features/items/providers/items_provider.dart';

class _NoEquipment extends EquipmentNotifier {
  @override
  Future<CharacterEquipmentResponse> build() => Future.error('offline');
}

const _boss = BossListItem(
  id: 'titan',
  name: 'Stone Titan',
  icon: '',
  maxHp: 2100,
  rewardXp: 500,
  timerDays: 0,
  isMini: false,
  region: 'Mountains of Strength',
  nodeName: 'Titan Peak',
  levelRequirement: 1,
  canFight: true,
  activated: true,
  hpDealt: 1333,
  isDefeated: false,
  isExpired: false,
);

BossDamageHistoryItem _hit(String id, String type, int damage, DateTime at,
        {String? skip}) =>
    BossDamageHistoryItem(
      activityId: id,
      activityType: type,
      durationMinutes: 40,
      distanceKm: 0,
      calories: 300,
      damage: damage,
      rawDamage: (damage * 1.25).round(),
      damageMultiplier: 1,
      bossMitigation: .2,
      damageTaken: skip == null ? 24 : 0,
      damageBlocked: skip == null ? 16 : 0,
      playerHpAfter: 364,
      bossHpAfter: 767,
      bossMaxHp: 2100,
      skipReason: skip,
      loggedAt: at,
    );

// Pinned to calendar days so the day groups don't depend on the clock.
final _now = DateTime.now();
final _startOfToday = DateTime(_now.year, _now.month, _now.day);
final _hits = [
  _hit('a', 'Yoga', 104, _now.subtract(const Duration(seconds: 30))),
  _hit('b', 'Running', 312, _startOfToday.subtract(const Duration(hours: 12))),
  _hit('c', 'Gym', 240, _startOfToday.subtract(const Duration(days: 2))),
  _hit('d', 'Gym', 0, _startOfToday.subtract(const Duration(days: 3)),
      skip: 'recovering'),
  _hit('e', 'Cycling', 198, _startOfToday.subtract(const Duration(days: 4))),
];

Future<void> _pump(WidgetTester tester, List<BossDamageHistoryItem> hits) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      bossDamageHistoryProvider('titan').overrideWith((_) async => hits),
      equipmentProvider.overrideWith(_NoEquipment.new),
    ],
    child: MaterialApp(
      home: BossBattleView(boss: _boss, onBack: () {}),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('C2: duel arena on top, no damage formula, recent hits + one CTA',
      (tester) async {
    await _pump(tester, _hits);

    expect(find.byType(BossDuelArena), findsOneWidget);
    expect(find.text('Stone Titan'), findsOneWidget);
    expect(find.text('HOW YOUR DAMAGE IS CALCULATED'), findsNothing);

    await tester.scrollUntilVisible(find.text('RECENT HITS'), 300);
    expect(find.text('See all'), findsOneWidget);
    // Only the 3 newest hits on the page.
    expect(find.text('−104 HP'), findsOneWidget);
    expect(find.text('−312 HP'), findsOneWidget);
    expect(find.text('−240 HP'), findsOneWidget);
    expect(find.text('−198 HP'), findsNothing);

    await tester.scrollUntilVisible(find.textContaining('Log Workout'), 300);
    expect(find.text('Full damage history · 5 hits'), findsOneWidget);
    // The old separate History button is gone.
    expect(find.textContaining('📋'), findsNothing);
  });

  testWidgets('See all opens the full history with summary and hit maths',
      (tester) async {
    await _pump(tester, _hits);
    await tester.scrollUntilVisible(find.text('See all'), 300);
    await tester.tap(find.text('See all'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Damage history'), findsOneWidget);
    expect(find.text('Stone Titan · 5 workouts this battle'), findsOneWidget);
    // Skipped hits don't count towards the totals.
    expect(find.text('854'), findsOneWidget); // dealt 104+312+240+198
    expect(find.text('96'), findsOneWidget); // took 4 × 24
    expect(find.text('64'), findsOneWidget); // blocked 4 × 16
    expect(find.text('2,100 → 767'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);
    expect(find.text('SKIPPED'), findsOneWidget);

    // The newest hit opens with its maths.
    expect(find.text('Power multiplier'), findsOneWidget);
    expect(find.text('−20%'), findsOneWidget);
    expect(find.text('24 HP (16 blocked)'), findsOneWidget);

    // Tapping another hit moves the breakdown there.
    await tester.tap(find.text('−312 HP').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('312 HP'), findsOneWidget);
    expect(find.text('104 HP'), findsNothing);
  });

  testWidgets('no hits yet: hint instead of the list, no See all',
      (tester) async {
    await _pump(tester, const []);
    await tester.scrollUntilVisible(find.text('RECENT HITS'), 300);
    expect(find.text('Log a workout to deal damage!'), findsOneWidget);
    expect(find.text('See all'), findsNothing);
  });
}
