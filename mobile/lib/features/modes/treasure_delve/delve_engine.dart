import 'dart:math' as math;

import '../../../core/constants/app_icons.dart';
import '../../activity/models/activity_models.dart';
import '../../character/models/character_profile.dart';

// ── Tuning ──────────────────────────────────────────────────────────────────
// Sample values until the coin economy is balanced against shop prices.

const kDelveChambers = 5;
const kDelveMaxRunsPerDay = 3;

/// Each chamber deeper pays this much more than the one before.
const kDelveDepthMultiplier = 1.5;

/// Coin bonus for rooms that test today's featured stat.
const kDelveModifierBonus = 0.2;

// ── Stats ───────────────────────────────────────────────────────────────────

enum DelveStat { str, end, agi, flx, sta }

extension DelveStatX on DelveStat {
  String get short => switch (this) {
        DelveStat.str => 'STR',
        DelveStat.end => 'END',
        DelveStat.agi => 'AGI',
        DelveStat.flx => 'FLX',
        DelveStat.sta => 'STA',
      };

  String get name => switch (this) {
        DelveStat.str => 'Strength',
        DelveStat.end => 'Endurance',
        DelveStat.agi => 'Agility',
        DelveStat.flx => 'Flexibility',
        DelveStat.sta => 'Stamina',
      };

  String get icon => switch (this) {
        DelveStat.str => AppIcons.statStrength,
        DelveStat.end => AppIcons.statEndurance,
        DelveStat.agi => AppIcons.statAgility,
        DelveStat.flx => AppIcons.statFlexibility,
        DelveStat.sta => AppIcons.statStamina,
      };

  int valueFor(CharacterProfile p) => switch (this) {
        DelveStat.str => p.strength,
        DelveStat.end => p.endurance,
        DelveStat.agi => p.agility,
        DelveStat.flx => p.flexibility,
        DelveStat.sta => p.stamina,
      };
}

// ── Chamber events ──────────────────────────────────────────────────────────

enum DelveEvent {
  collapsedGate,
  floodedTunnel,
  trapCorridor,
  crystalPuzzle,
  longPassage
}

extension DelveEventX on DelveEvent {
  DelveStat get stat => switch (this) {
        DelveEvent.collapsedGate => DelveStat.str,
        DelveEvent.floodedTunnel => DelveStat.end,
        DelveEvent.trapCorridor => DelveStat.agi,
        DelveEvent.crystalPuzzle => DelveStat.flx,
        DelveEvent.longPassage => DelveStat.sta,
      };

  String get title => switch (this) {
        DelveEvent.collapsedGate => 'Collapsed Gate',
        DelveEvent.floodedTunnel => 'Flooded Tunnel',
        DelveEvent.trapCorridor => 'Trap Corridor',
        DelveEvent.crystalPuzzle => 'Crystal Puzzle',
        DelveEvent.longPassage => 'Long Passage',
      };

  String get flavour => switch (this) {
        DelveEvent.collapsedGate =>
          'Fallen stone blocks the way. Only raw strength will shift it.',
        DelveEvent.floodedTunnel =>
          'Cold water fills the tunnel. Keep going until you reach air.',
        DelveEvent.trapCorridor =>
          'Pressure plates line the floor. Quick feet get through untouched.',
        DelveEvent.crystalPuzzle =>
          'Crystals hang at odd angles. Bend and reach without touching one.',
        DelveEvent.longPassage =>
          'The passage winds on and on. Pace yourself to reach the end.',
      };
}

// ── Paths ───────────────────────────────────────────────────────────────────

enum DelvePath { safe, treasure, cursed }

extension DelvePathX on DelvePath {
  String get title => switch (this) {
        DelvePath.safe => 'Safe Passage',
        DelvePath.treasure => 'Treasure Route',
        DelvePath.cursed => 'Cursed Vault',
      };

  String get difficulty => switch (this) {
        DelvePath.safe => 'EASY',
        DelvePath.treasure => 'MEDIUM',
        DelvePath.cursed => 'HARD',
      };

  /// Chamber-1 coins before depth and modifier bonuses.
  int get baseCoins => switch (this) {
        DelvePath.safe => 10,
        DelvePath.treasure => 20,
        DelvePath.cursed => 35,
      };

  /// How hard the stat check is, relative to the player's average stat.
  double get difficultyFactor => switch (this) {
        DelvePath.safe => 0,
        DelvePath.treasure => 1.0,
        DelvePath.cursed => 1.35,
      };

  double get itemChance => switch (this) {
        DelvePath.safe => 0,
        DelvePath.treasure => 0.25,
        DelvePath.cursed => 0.4,
      };

  /// Safe Passage has no check and its coins are secured straight away.
  bool get guaranteed => this == DelvePath.safe;
}

enum DelveOdds { certain, high, good, risky, low }

extension DelveOddsX on DelveOdds {
  String get label => switch (this) {
        DelveOdds.certain => 'Guaranteed',
        DelveOdds.high => 'High chance of success',
        DelveOdds.good => 'Good chance of success',
        DelveOdds.risky => 'Risky',
        DelveOdds.low => 'Low chance of success',
      };

  /// Filled segments out of five.
  int get segments => switch (this) {
        DelveOdds.certain => 5,
        DelveOdds.high => 4,
        DelveOdds.good => 3,
        DelveOdds.risky => 2,
        DelveOdds.low => 1,
      };
}

class DelveOption {
  final DelvePath path;
  final DelveEvent event;
  final int coins;
  final int recommended;
  final double successChance;
  final bool boosted;

  const DelveOption({
    required this.path,
    required this.event,
    required this.coins,
    required this.recommended,
    required this.successChance,
    required this.boosted,
  });

  DelveOdds get odds {
    if (path.guaranteed) return DelveOdds.certain;
    if (successChance >= .8) return DelveOdds.high;
    if (successChance >= .6) return DelveOdds.good;
    if (successChance >= .4) return DelveOdds.risky;
    return DelveOdds.low;
  }
}

// ── Run state ───────────────────────────────────────────────────────────────

enum DelvePhase { choosing, challenge, decision, result }

enum DelveEnd { banked, failed, cleared }

class DelveRun {
  final String id;

  /// 0-based chamber the player is in.
  final int chamber;
  final List<DelveOption> options;
  final DelveOption? chosen;
  final DelvePhase phase;

  /// Coins the player keeps whatever happens.
  final int secured;

  /// Coins lost if a later check fails.
  final int atRisk;
  final int itemsFound;

  /// Outcome of the last check, for the decision screen.
  final bool? lastSucceeded;
  final int lastCoins;
  final bool lastItem;

  /// Paths cleared so far, oldest first.
  final List<DelvePath> cleared;
  final DelveEnd? end;

  const DelveRun({
    this.id = '',
    required this.chamber,
    required this.options,
    required this.phase,
    this.chosen,
    this.secured = 0,
    this.atRisk = 0,
    this.itemsFound = 0,
    this.lastSucceeded,
    this.lastCoins = 0,
    this.lastItem = false,
    this.cleared = const [],
    this.end,
  });

  int get total => secured + atRisk;

  /// Coins the player leaves with.
  int get payout => end == DelveEnd.failed ? secured : total;

  bool get isLastChamber => chamber >= kDelveChambers - 1;

  DelveRun copyWith({
    int? chamber,
    List<DelveOption>? options,
    DelveOption? chosen,
    bool clearChosen = false,
    DelvePhase? phase,
    int? secured,
    int? atRisk,
    int? itemsFound,
    bool? lastSucceeded,
    int? lastCoins,
    bool? lastItem,
    List<DelvePath>? cleared,
    DelveEnd? end,
  }) =>
      DelveRun(
        id: id,
        chamber: chamber ?? this.chamber,
        options: options ?? this.options,
        chosen: clearChosen ? null : (chosen ?? this.chosen),
        phase: phase ?? this.phase,
        secured: secured ?? this.secured,
        atRisk: atRisk ?? this.atRisk,
        itemsFound: itemsFound ?? this.itemsFound,
        lastSucceeded: lastSucceeded ?? this.lastSucceeded,
        lastCoins: lastCoins ?? this.lastCoins,
        lastItem: lastItem ?? this.lastItem,
        cleared: cleared ?? this.cleared,
        end: end ?? this.end,
      );
}

// ── Engine ──────────────────────────────────────────────────────────────────

/// The stat whose rooms pay more today; rotates daily.
DelveStat featuredStatFor(DateTime day) {
  final l = day.toLocal();
  final dayNumber =
      DateTime(l.year, l.month, l.day).difference(DateTime(2026, 1, 1)).inDays;
  return DelveStat.values[dayNumber % DelveStat.values.length];
}

/// Runs earned by today's workouts: 20 min = 1, 45 min = 2, max 3 a day.
int delveRunsEarned(List<ActivityHistoryDto> activities, DateTime now) {
  final today = now.toLocal();
  var runs = 0;
  for (final a in activities) {
    final l = a.loggedAt.toLocal();
    if (l.year != today.year || l.month != today.month || l.day != today.day) {
      continue;
    }
    if (a.durationMinutes >= 45) {
      runs += 2;
    } else if (a.durationMinutes >= 20) {
      runs += 1;
    }
  }
  return math.min(runs, kDelveMaxRunsPerDay);
}

DelveStat strongestStat(CharacterProfile p) =>
    DelveStat.values.reduce((a, b) => b.valueFor(p) > a.valueFor(p) ? b : a);

/// Most coins a run can pay: the Cursed Vault in every chamber, with today's
/// bonus.
int delveMaxReward() {
  var total = 0.0;
  for (var i = 0; i < kDelveChambers; i++) {
    total += DelvePath.cursed.baseCoins *
        math.pow(kDelveDepthMultiplier, i) *
        (1 + kDelveModifierBonus);
  }
  return total.round();
}

class DelveEngine {
  final CharacterProfile profile;
  final DelveStat featured;
  final math.Random _rng;

  DelveEngine({
    required this.profile,
    required this.featured,
    math.Random? random,
  }) : _rng = random ?? math.Random();

  DelveRun start() => DelveRun(
        chamber: 0,
        options: _optionsFor(0),
        phase: DelvePhase.choosing,
      );

  DelveRun choose(DelveRun run, DelveOption option) =>
      run.copyWith(chosen: option, phase: DelvePhase.challenge);

  DelveRun backToPaths(DelveRun run) =>
      run.copyWith(clearChosen: true, phase: DelvePhase.choosing);

  /// Resolves the chosen chamber. Safe Passage always clears and its coins
  /// are secured; other paths roll against the success chance and their
  /// coins go into the at-risk pool.
  DelveRun attempt(DelveRun run) {
    final option = run.chosen!;
    final success =
        option.path.guaranteed || _rng.nextDouble() < option.successChance;
    if (!success) {
      return run.copyWith(
        phase: DelvePhase.result,
        lastSucceeded: false,
        lastCoins: 0,
        lastItem: false,
        atRisk: 0,
        end: DelveEnd.failed,
      );
    }
    final item = _rng.nextDouble() < option.path.itemChance;
    final next = run.copyWith(
      lastSucceeded: true,
      lastCoins: option.coins,
      lastItem: item,
      itemsFound: run.itemsFound + (item ? 1 : 0),
      secured: option.path.guaranteed ? run.secured + option.coins : null,
      atRisk: option.path.guaranteed ? null : run.atRisk + option.coins,
      cleared: [...run.cleared, option.path],
    );
    if (run.isLastChamber) {
      return next.copyWith(phase: DelvePhase.result, end: DelveEnd.cleared);
    }
    return next.copyWith(phase: DelvePhase.decision);
  }

  DelveRun bank(DelveRun run) =>
      run.copyWith(phase: DelvePhase.result, end: DelveEnd.banked);

  DelveRun continueDeeper(DelveRun run) => run.copyWith(
        chamber: run.chamber + 1,
        options: _optionsFor(run.chamber + 1),
        clearChosen: true,
        phase: DelvePhase.choosing,
      );

  List<DelveOption> _optionsFor(int chamber) {
    final events = [...DelveEvent.values]..shuffle(_rng);
    return [
      for (var i = 0; i < DelvePath.values.length; i++)
        _option(DelvePath.values[i], events[i], chamber),
    ];
  }

  DelveOption _option(DelvePath path, DelveEvent event, int chamber) {
    final boosted = event.stat == featured;
    final coins = (path.baseCoins *
            math.pow(kDelveDepthMultiplier, chamber) *
            (boosted ? 1 + kDelveModifierBonus : 1))
        .round();
    final recommended = path.guaranteed
        ? 0
        : (_averageStat * path.difficultyFactor * (1 + .1 * chamber))
            .round()
            .clamp(1, 999);
    return DelveOption(
      path: path,
      event: event,
      coins: coins,
      recommended: recommended,
      successChance: path.guaranteed
          ? 1
          : successChance(event.stat.valueFor(profile), recommended),
      boosted: boosted,
    );
  }

  double get _averageStat {
    final sum = DelveStat.values.fold(0, (s, st) => s + st.valueFor(profile));
    return math.max(5, sum / DelveStat.values.length);
  }
}

/// 50% when the stat equals the recommendation, rising or falling with the
/// gap, kept between 10% and 95%.
double successChance(int stat, int recommended) {
  if (recommended <= 0) return 1;
  final gap = (stat - recommended) / recommended;
  return (0.5 + gap * 1.2).clamp(0.1, 0.95);
}
