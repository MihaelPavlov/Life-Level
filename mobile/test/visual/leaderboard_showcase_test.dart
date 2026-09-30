import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_level/core/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/character/providers/character_provider.dart';
import 'package:life_level/features/leaderboard/leaderboard_screen.dart';
import 'package:life_level/features/leaderboard/models/leaderboard_models.dart';
import 'package:life_level/features/leaderboard/providers/leaderboard_provider.dart';

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

// Renders the leaderboard with real fonts and art to compare with the design
// by eye. Not part of the normal suite. Run with:
//   flutter test test/visual/leaderboard_showcase_test.dart \
//     --update-goldens --dart-define=SHOWCASE_DIR=/abs/output/dir
const _outDir = String.fromEnvironment('SHOWCASE_DIR');

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/development/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(Future.value(
        ByteData.view(File('$dir/Roboto-$f.ttf').readAsBytesSync().buffer)));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(
        File('$dir/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icons.load();
}

void main() {
  final skip = _outDir.isEmpty;

  setUpAll(() async {
    if (skip) return;
    await _loadFonts();
    goldenFileComparator =
        LocalFileComparator(Uri.file('$_outDir/showcase_test.dart'));
  });

  testWidgets('leaderboard', skip: skip, (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app((s, m) => _boardJson(stack: 3)));
    await tester.pump();
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(Scaffold).first);
      for (final a in [
        AppIcons.regionChestsBackground,
        AppIcons.regionChestsTitleBanner,
        AppIcons.leaderboardHero,
        AppIcons.homeCoinIcon,
        AppIcons.homeGemIcon,
        AppIcons.homePowerIcon,
        AppIcons.mapXpReward,
        AppIcons.activityRunning,
        AppIcons.ringBoss,
        AppIcons.rewardStreakFire,
        AppIcons.rewardTreasureChest,
        AppIcons.avatarFox,
      ]) {
        await precacheImage(AssetImage(a), ctx);
      }
    });
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('leaderboard.png'));
    await tester.pump(const Duration(seconds: 4));
  });
}
