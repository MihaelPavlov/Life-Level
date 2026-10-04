import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/achievements/models/achievement_models.dart';
import 'package:life_level/features/home/cards/home_adventure_hub.dart';
import 'package:life_level/features/home/providers/adventure_hub_status_provider.dart';
import 'package:life_level/features/titles/models/title_models.dart';

import '../../helpers/unlocks_overrides.dart';

final _rewardsReadyProvider = StateProvider<bool>((ref) => false);
final _signalsRefreshingProvider = StateProvider<bool>((ref) => false);
final _attentionModeProvider = StateProvider<int>((ref) => 0);

const _title = TitleDto(
  id: 'title-1',
  emoji: '',
  name: 'Runner',
  unlockCondition: '',
  isEarned: true,
  isEquipped: false,
);

const _titles = TitlesAndRanksResponse(
  activeTitleEmoji: '',
  activeTitleName: '',
  rankProgression: RankProgressionDto(
    currentRank: 'Starter',
    bossesDefeated: 0,
    bossesRequiredForNextRank: 1,
    bossesRemainingForNextRank: 1,
    nextRank: null,
  ),
  earnedTitles: [_title],
  lockedTitles: [],
);

const _achievement = AchievementDto(
  id: 'achievement-1',
  title: 'First Run',
  description: '',
  icon: '',
  category: 'Running',
  tier: 'Common',
  tierColor: Colors.blue,
  xpReward: 10,
  targetValue: 1,
  targetUnit: 'km',
  currentValue: 1,
  isUnlocked: true,
);

void main() {
  testWidgets('shortcuts stay in place as live attention changes',
      (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allUnlockedOverride,
        adventureHubSignalsProvider.overrideWith((ref) async {
          final mode = ref.watch(_attentionModeProvider);
          return AdventureHubSignals(
            rewards: mode == 0,
            bosses: false,
            streak: mode != 2,
            talents: false,
            season: mode != 1,
            titles: false,
            achievements: false,
          );
        }),
      ],
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const MaterialApp(home: Scaffold(body: HomeAdventureHub()));
      }),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    double x(String label) => tester.getTopLeft(find.text(label)).dx;
    final positions = [x('Rewards'), x('Season'), x('Streak'), x('Journal')];
    expect(positions, orderedEquals(positions.toList()..sort()));

    container.read(_attentionModeProvider.notifier).state = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect([x('Rewards'), x('Season'), x('Streak'), x('Journal')], positions);
    expect(find.text('!'), findsOneWidget);

    container.read(_attentionModeProvider.notifier).state = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect([x('Rewards'), x('Season'), x('Streak'), x('Journal')], positions);
    expect(find.text('!'), findsOneWidget);
  });

  test('unseen badges wait for migration and fresh server responses', () {
    expect(
      hasVerifiedUnseenTitles(
          const AsyncLoading<void>(), const AsyncData(_titles)),
      isFalse,
    );
    expect(
      hasVerifiedUnseenAchievements(
          const AsyncLoading<void>(), const AsyncData([_achievement])),
      isFalse,
    );
    expect(
      hasVerifiedUnseenTitles(const AsyncData<void>(null),
          const AsyncLoading<TitlesAndRanksResponse>()),
      isFalse,
    );
    expect(
      hasVerifiedUnseenTitles(
          const AsyncData<void>(null), const AsyncData(_titles)),
      isTrue,
    );
    expect(
      hasVerifiedUnseenAchievements(
          const AsyncData<void>(null), const AsyncData([_achievement])),
      isTrue,
    );
  });

  testWidgets('hides stale alert while its signal refreshes', (tester) async {
    final refresh = Completer<AdventureHubSignals>();
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allUnlockedOverride,
        adventureHubSignalsProvider.overrideWith((ref) async {
          final refreshing = ref.watch(_signalsRefreshingProvider);
          if (refreshing) return refresh.future;
          return const AdventureHubSignals(
            rewards: false,
            bosses: false,
            streak: false,
            talents: false,
            season: false,
            titles: true,
            achievements: false,
          );
        }),
      ],
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const MaterialApp(home: Scaffold(body: HomeAdventureHub()));
      }),
    ));
    await tester.pump();
    expect(find.text('!'), findsOneWidget);

    container.read(_signalsRefreshingProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('!'), findsNothing);

    refresh.complete(AdventureHubSignals.empty);
    await tester.pump();
  });

  group('achievement hub alert', () {
    test('stays visible while an achievement reward is claimable', () {
      expect(
        achievementHubNeedsAttention(
          hasUnseenAchievements: false,
          readyCount: 1,
          chestsReady: 0,
        ),
        isTrue,
      );
    });

    test('stays visible while a stage chest is ready to open', () {
      expect(
        achievementHubNeedsAttention(
          hasUnseenAchievements: false,
          readyCount: 0,
          chestsReady: 1,
        ),
        isTrue,
      );
    });

    test('clears when everything has been viewed and collected', () {
      expect(
        achievementHubNeedsAttention(
          hasUnseenAchievements: false,
          readyCount: 0,
          chestsReady: 0,
        ),
        isFalse,
      );
    });
  });

  testWidgets('shows a live Rewards alert when claimable state changes',
      (tester) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUnlockedOverride,
          adventureHubSignalsProvider.overrideWith((ref) async {
            final rewardsReady = ref.watch(_rewardsReadyProvider);
            return AdventureHubSignals(
              rewards: rewardsReady,
              bosses: false,
              streak: false,
              talents: false,
              season: false,
              titles: false,
              achievements: false,
            );
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              home: Scaffold(body: HomeAdventureHub()),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('!'), findsNothing);
    expect(find.text('Ranks'), findsOneWidget);
    expect(find.text('Bosses'), findsOneWidget);
    expect(find.text('Milestones'), findsNothing);

    container.read(_rewardsReadyProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('shows an alert on Bosses when a boss is active', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUnlockedOverride,
          adventureHubSignalsProvider.overrideWith(
            (ref) async => const AdventureHubSignals(
              rewards: false,
              bosses: true,
              streak: false,
              talents: false,
              season: false,
              titles: false,
              achievements: false,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeAdventureHub()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Bosses'), findsOneWidget);
    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('shows an alert when a region chest is ready', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUnlockedOverride,
          adventureHubSignalsProvider.overrideWith(
            (ref) async => const AdventureHubSignals(
              rewards: false,
              bosses: false,
              streak: false,
              talents: false,
              season: false,
              titles: false,
              achievements: false,
              chests: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeAdventureHub()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Region Chests'), findsOneWidget);
    expect(find.text('!'), findsOneWidget);
  });
}
