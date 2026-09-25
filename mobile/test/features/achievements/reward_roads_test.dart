import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/achievements/models/achievement_models.dart';
import 'package:life_level/features/achievements/providers/achievements_provider.dart';
import 'package:life_level/features/achievements/roads/reward_roads_hub.dart';

// ── Fixture: Running road, Stage 1 (Common) chest opened, Stage 2
// (Uncommon) with one claimed and one ready — claiming it finishes the stage.

Map<String, dynamic> _a(String id, String title, String tier,
        {bool unlocked = false, bool claimed = false, double current = 0}) =>
    {
      'id': id,
      'title': title,
      'description': '',
      'icon': '🏃',
      'category': 'Running',
      'tier': tier,
      'xpReward': 250,
      'targetValue': 10,
      'targetUnit': 'km',
      'currentValue': unlocked ? 10 : current,
      'isUnlocked': unlocked,
      'coinReward': 150,
      'gemReward': 3,
      'isClaimed': claimed,
    };

Map<String, dynamic> _stage(String tier, String chestKey, String chestName,
        List<Map<String, dynamic>> list,
        {bool opened = false}) {
  final claimed = list.where((a) => a['isClaimed'] == true).length;
  final unlocked = list.where((a) => a['isUnlocked'] == true).length;
  return {
    'tier': tier,
    'chestKey': chestKey,
    'chestName': chestName,
    'chestItemRarity': 'Common',
    'chestCoins': 500,
    'chestGems': 5,
    'total': list.length,
    'unlocked': unlocked,
    'claimed': claimed,
    'ready': unlocked - claimed,
    'chestReady': claimed == list.length && !opened,
    'chestOpened': opened,
    'achievements': list,
  };
}

AchievementRoadsData _data({required bool stage2Claimed, bool stage2Opened = false}) {
  final stages = [
    _stage('Common', 'wayfarer', 'Wayfarer Chest',
        [_a('c1', 'First Steps', 'Common', unlocked: true, claimed: true)],
        opened: true),
    _stage('Uncommon', 'wayfarer', 'Wayfarer Chest', [
      _a('u1', 'Road Warrior', 'Uncommon', unlocked: true, claimed: true),
      _a('u2', 'Weekend Long Run', 'Uncommon',
          unlocked: true, claimed: stage2Claimed),
    ], opened: stage2Opened),
    _stage('Rare', 'adept', 'Adept Chest',
        [_a('r1', 'Marathon Prep', 'Rare', current: 6)]),
  ];
  final ready = stage2Claimed ? 0 : 1;
  final current = stage2Opened ? 2 : 1;
  return AchievementRoadsData.fromJson({
    'wallet': {'coins': 6720, 'gems': 148},
    'readyCount': ready,
    'chestsReady': stage2Claimed && !stage2Opened ? 1 : 0,
    'roads': [
      {
        'category': 'Running',
        'total': 4,
        'claimed': stage2Claimed ? 3 : 2,
        'ready': ready,
        'currentStage': current,
        'stages': stages,
      },
    ],
  });
}

class _FakeRoads extends AchievementRoadsNotifier {
  AchievementRoadsData current = _data(stage2Claimed: false);
  final calls = <String>[];

  @override
  Future<AchievementRoadsData> build() async => current;

  @override
  Future<void> reload() async => state = AsyncData(current);

  @override
  Future<AchievementClaimResult> claim(String achievementId) async {
    calls.add('claim:$achievementId');
    current = _data(stage2Claimed: true);
    return AchievementClaimResult.fromJson({
      'claimedIds': [achievementId],
      'xp': 250,
      'coins': 150,
      'gems': 3,
      'chestsReady': [
        {'category': 'Running', 'tier': 'Uncommon'}
      ],
      'wallet': {'coins': 6870, 'gems': 151},
    });
  }

  @override
  Future<StageChestOpenResult> openStageChest(
      String category, String tier) async {
    calls.add('open:$category/$tier');
    current = _data(stage2Claimed: true, stage2Opened: true);
    return StageChestOpenResult.fromJson({
      'category': category,
      'tier': tier,
      'chestKey': 'wayfarer',
      'chestName': 'Wayfarer Chest',
      'item': {
        'id': '10000000-0000-0000-0000-000000000016',
        'name': 'Recovery Slides',
        'icon': '🩴',
        'rarity': 'Common',
      },
      'coins': 500,
      'gems': 5,
      'wallet': {'coins': 7370, 'gems': 156},
    });
  }

  @override
  void refreshCharacter() {}
}

Widget _app(_FakeRoads fake, {bool motion = false}) => ProviderScope(
      overrides: [achievementRoadsProvider.overrideWith(() => fake)],
      // Motion off app-wide (pushed routes and the popup too): effects are
      // skipped and the chest popup opens settled.
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !motion),
          child: child!,
        ),
        home: const RewardRoadsHub(),
      ),
    );

void main() {
  testWidgets('hub shows the ready bar, continue card and road tiles',
      (tester) async {
    await tester.pumpWidget(_app(_FakeRoads()));
    await tester.pumpAndSettle();

    expect(find.text('Reward ready to claim'), findsOneWidget);
    expect(find.text('On Running'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('Claim 1 to open the Wayfarer Chest'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    // Tile badge + the continue card's legend.
    expect(find.text('1 ready'), findsNWidgets(2));
  });

  testWidgets(
      'claiming the last achievement opens the stage chest and moves on to the next stage',
      (tester) async {
    final fake = _FakeRoads();
    await tester.pumpWidget(_app(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Running'));
    await tester.pumpAndSettle();
    expect(find.text('READY TO CLAIM'), findsOneWidget);
    expect(find.text('Weekend Long Run'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Claim'));
    await tester.pumpAndSettle();

    expect(fake.calls, ['claim:u2', 'open:Running/Uncommon']);
    // Chest popup: rewards + subtitle only — no "You got loot!", no close hint.
    expect(find.text('Recovery Slides · Stage 2 complete'), findsOneWidget);
    expect(find.text('You got loot!'), findsNothing);
    expect(find.text('Tap to close'), findsNothing);

    // Close the popup: the road now shows Stage 3 and the item toast.
    await tester.tapAt(const Offset(195, 300));
    await tester.pumpAndSettle();
    expect(find.text('Recovery Slides · Stage 2 complete'), findsNothing);
    expect(find.textContaining('STAGE 3 OF 3'), findsOneWidget);
    expect(find.text('1 more to open the Adept Chest'), findsOneWidget);
    expect(find.text('Recovery Slides added to your gear'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('claim + chest animations run without errors when motion is on',
      (tester) async {
    final fake = _FakeRoads();
    await tester.pumpWidget(_app(fake, motion: true));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Running'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.widgetWithText(FilledButton, 'Claim'));
    // Stamp, flight, count-up, fold, pieces, "Stage 2 complete!", then the
    // chest popup plays its 2.3 s intro.
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(fake.calls, ['claim:u2', 'open:Running/Uncommon']);
    expect(find.text('Recovery Slides · Stage 2 complete'), findsOneWidget);

    await tester.tapAt(const Offset(195, 300));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.textContaining('STAGE 3 OF 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
