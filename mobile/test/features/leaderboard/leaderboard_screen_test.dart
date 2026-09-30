import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/character/providers/character_provider.dart';
import 'package:life_level/features/leaderboard/leaderboard_screen.dart';
import 'package:life_level/features/leaderboard/models/leaderboard_models.dart';
import 'package:life_level/features/leaderboard/providers/leaderboard_provider.dart';
import 'package:life_level/features/leaderboard/widgets/leaderboard_widgets.dart';

const _profile = CharacterProfile(
  username: 'Hero',
  avatarEmoji: null,
  className: null,
  classEmoji: null,
  rank: 'Novice',
  level: 5,
  xp: 100,
  xpForCurrentLevel: 0,
  xpForNextLevel: 200,
  strength: 12,
  endurance: 10,
  agility: 42,
  flexibility: 7,
  stamina: 11,
  weeklyRuns: 2,
  weeklyDistanceKm: 8,
  weeklyXpEarned: 300,
  currentStreak: 4,
  availableStatPoints: 0,
  power: 125,
  attack: 32,
  health: 210,
  defense: 18,
);

class _Profile extends CharacterNotifier {
  @override
  Future<CharacterProfile> build() async => _profile;
}

Map<String, dynamic> _entry(int rank, String name, double score,
        {bool me = false}) =>
    {
      'rank': rank,
      'userId': 'u$rank',
      'username': name,
      'avatarEmoji': '🦊',
      'level': 10 + rank,
      'className': 'Archer',
      'score': score,
      'isMe': me,
    };

Map<String, dynamic> _boardJson({
  String scope = 'global',
  String metric = 'power',
  bool available = true,
  int stack = 0,
}) =>
    {
      'scope': scope,
      'metric': metric,
      'available': available,
      'contextName': null,
      'resetsAtUtc': metric == 'power' ? null : '2026-10-05T00:00:00Z',
      'entries': available
          ? [
              _entry(1, 'Aria', 3400),
              _entry(2, 'Borin', 3100),
              _entry(3, 'Mira', 2900),
              _entry(4, 'Taro', 2500),
              _entry(5, 'Hero', 2405, me: true),
            ]
          : [],
      'me': available
          ? {
              'rank': 5,
              'score': 2405,
              'total': 5,
              'nextUsername': 'Taro',
              'gapToNext': 95
            }
          : {'rank': null, 'score': 0, 'total': 0},
      'chest': {'stack': stack, 'coins': stack * 40, 'gems': 0},
    };

Widget _app(
        Map<String, dynamic> Function(LeaderboardScope, LeaderboardMetric)
            board) =>
    ProviderScope(
      overrides: [
        characterProfileProvider.overrideWith(_Profile.new),
        leaderboardProvider.overrideWith((ref, key) async =>
            LeaderboardBoard.fromJson(board(key.$1, key.$2))),
      ],
      child: const MaterialApp(home: LeaderboardScreen()),
    );

void main() {
  group('labels', () {
    test('metrics format scores and gaps', () {
      expect(LeaderboardMetric.power.format(2405), '2,405');
      expect(LeaderboardMetric.xp.format(1240), '1,240 XP');
      expect(LeaderboardMetric.km.format(12.34), '12.3 km');
      expect(LeaderboardMetric.boss.format(5200), '5.2k');
      expect(LeaderboardMetric.streak.format(12), '12 d');
      expect(LeaderboardMetric.power.gap(94.2), '95 power');
      expect(LeaderboardMetric.streak.gap(1), '1 day');
    });

    test('your row explains the gap to the next player', () {
      final b = LeaderboardBoard.fromJson(_boardJson());
      expect(youGapLabel(b), '95 power to pass Taro');
    });

    test('the chest reveal names who you passed', () {
      expect(passedSubtitle(['Taro']), 'You passed Taro');
      expect(passedSubtitle(['Taro', 'Lena', 'Oskar']),
          'You passed Taro, Lena and Oskar');
      expect(passedSubtitle(['A', 'B', 'C', 'D', 'E']),
          'You passed A, B and 3 more');
    });

    test('power is all-time, weekly boards count down to the reset', () {
      expect(periodLabel(LeaderboardMetric.power, null), 'All-time');
      final weekly = LeaderboardBoard.fromJson(_boardJson(metric: 'xp'));
      expect(
          periodLabel(LeaderboardMetric.xp, weekly,
              now: DateTime.utc(2026, 10, 1, 20)),
          'Resets in 3d 4h');
    });
  });

  testWidgets('shows the podium, the list and your pinned row', (tester) async {
    await tester.pumpWidget(_app((s, m) => _boardJson()));
    await tester.pumpAndSettle();

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.byType(LeaderboardPodium), findsOneWidget);
    for (final name in ['Aria', 'Borin', 'Mira', 'Taro']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('You · 2,405'), findsOneWidget);
    expect(find.text('95 power to pass Taro'), findsOneWidget);
    expect(find.byType(RankUpChestButton), findsNothing);
  });

  testWidgets('the chest pops onto your row when rewards are stacked',
      (tester) async {
    await tester.pumpWidget(_app((s, m) => _boardJson(stack: 3)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(RankUpChestButton), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(find.text('▲ You climbed · 3 rewards stacked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('switching scope and metric loads that board', (tester) async {
    final asked = <(LeaderboardScope, LeaderboardMetric)>[];
    await tester.pumpWidget(_app((s, m) {
      asked.add((s, m));
      return _boardJson(scope: s.name, metric: m.name);
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XP'));
    await tester.pumpAndSettle();

    expect(asked, contains((LeaderboardScope.region, LeaderboardMetric.xp)));
  });

  testWidgets('guild board without a guild offers to find one', (tester) async {
    await tester.pumpWidget(_app((s, m) => _boardJson(
        scope: s.name,
        metric: m.name,
        available: s != LeaderboardScope.guild)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guild'));
    await tester.pumpAndSettle();

    expect(find.text('Join a guild'), findsOneWidget);
    expect(find.text('Find a guild'), findsOneWidget);
  });
}
