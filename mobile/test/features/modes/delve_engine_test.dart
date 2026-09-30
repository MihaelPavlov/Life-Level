import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/modes/treasure_delve/delve_engine.dart';

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

/// Always rolls [value], so every check passes (low) or fails (high).
class _FixedRandom implements math.Random {
  final double value;
  _FixedRandom(this.value);
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

DelveEngine _engine(double roll) => DelveEngine(
      profile: _profile,
      featured: DelveStat.str,
      random: _FixedRandom(roll),
    );

ActivityHistoryDto _workout(int minutes, DateTime at) => ActivityHistoryDto(
      id: '$minutes-$at',
      type: 'Running',
      durationMinutes: minutes,
      distanceKm: 0,
      calories: 0,
      xpGained: 0,
      strGained: 0,
      endGained: 0,
      agiGained: 0,
      flxGained: 0,
      staGained: 0,
      steps: 0,
      loggedAt: at,
    );

void main() {
  group('runs earned', () {
    final now = DateTime(2026, 9, 29, 18);

    test('20 min earns 1, 45 min earns 2, capped at 3', () {
      expect(delveRunsEarned([_workout(19, now)], now), 0);
      expect(delveRunsEarned([_workout(20, now)], now), 1);
      expect(delveRunsEarned([_workout(45, now)], now), 2);
      expect(delveRunsEarned([_workout(45, now), _workout(60, now)], now),
          kDelveMaxRunsPerDay);
    });

    test('only today counts', () {
      final yesterday = now.subtract(const Duration(days: 1));
      expect(delveRunsEarned([_workout(60, yesterday)], now), 0);
    });
  });

  test('each chamber offers safe, treasure and cursed with distinct events',
      () {
    final run = _engine(0).start();
    expect(run.options.map((o) => o.path), DelvePath.values);
    expect(run.options.map((o) => o.event).toSet().length, 3);
    expect(run.options.first.odds, DelveOdds.certain);
  });

  test('deeper chambers pay more', () {
    final e = _engine(0);
    var run = e.start();
    final first = run.options.firstWhere((o) => o.path == DelvePath.safe);
    run = e.continueDeeper(e.attempt(e.choose(run, first)));
    final second = run.options.firstWhere((o) => o.path == DelvePath.safe);
    expect(second.coins, greaterThan(first.coins));
  });

  test('Safe Passage always clears and its coins are secured', () {
    final e = _engine(.99);
    var run = e.start();
    final safe = run.options.firstWhere((o) => o.path == DelvePath.safe);
    run = e.attempt(e.choose(run, safe));
    expect(run.lastSucceeded, isTrue);
    expect(run.secured, safe.coins);
    expect(run.atRisk, 0);
    expect(run.phase, DelvePhase.decision);
  });

  test('a cleared risky path puts its coins at risk', () {
    final e = _engine(0);
    var run = e.start();
    final treasure =
        run.options.firstWhere((o) => o.path == DelvePath.treasure);
    run = e.attempt(e.choose(run, treasure));
    expect(run.atRisk, treasure.coins);
    expect(run.secured, 0);
  });

  test('failing keeps secured coins and loses the at-risk ones', () {
    // Clear Safe (secured), clear Treasure (at risk), then fail Cursed.
    final pass = _engine(0);
    var run = pass.start();
    final safe = run.options.firstWhere((o) => o.path == DelvePath.safe);
    run = pass.continueDeeper(pass.attempt(pass.choose(run, safe)));
    final treasure =
        run.options.firstWhere((o) => o.path == DelvePath.treasure);
    run = pass.continueDeeper(pass.attempt(pass.choose(run, treasure)));
    expect(run.atRisk, greaterThan(0));

    final fail = _engine(.99);
    final cursed = run.options.firstWhere((o) => o.path == DelvePath.cursed);
    run = fail.attempt(fail.choose(run, cursed));
    expect(run.end, DelveEnd.failed);
    expect(run.payout, safe.coins);
  });

  test('banking pays everything in the bag', () {
    final e = _engine(0);
    var run = e.start();
    final treasure =
        run.options.firstWhere((o) => o.path == DelvePath.treasure);
    run = e.bank(e.attempt(e.choose(run, treasure)));
    expect(run.end, DelveEnd.banked);
    expect(run.payout, treasure.coins);
  });

  test('clearing the last chamber ends the run as cleared', () {
    final e = _engine(0);
    var run = e.start();
    for (var i = 0; i < kDelveChambers; i++) {
      final safe = run.options.firstWhere((o) => o.path == DelvePath.safe);
      run = e.attempt(e.choose(run, safe));
      if (i < kDelveChambers - 1) run = e.continueDeeper(run);
    }
    expect(run.end, DelveEnd.cleared);
    expect(run.cleared.length, kDelveChambers);
  });

  test('success chance follows the stat gap', () {
    expect(successChance(35, 35), closeTo(.5, .001));
    expect(successChance(42, 35), greaterThan(.5));
    expect(successChance(10, 35), .1);
    expect(successChance(200, 35), .95);
  });

  test('the featured stat rotates daily', () {
    final a = featuredStatFor(DateTime(2026, 9, 29));
    final b = featuredStatFor(DateTime(2026, 9, 30));
    expect(a, isNot(b));
  });
}
