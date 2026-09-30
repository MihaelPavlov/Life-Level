import '../../activity/models/activity_models.dart';

/// How long a chain stays open after the player starts it.
const kBurnChainWindow = Duration(hours: 24);

/// Reward multiplier for a workout that beats the bar.
const kBurnChainBeatMultiplier = 2;

/// Coins per calorie for the first workout and for the one that breaks it.
const kBurnChainBaseMultiplier = 1;

/// Workouts shorter than this are ignored, so a tiny first workout can't be
/// used to set an easy bar.
const kBurnChainMinMinutes = 10;

enum ChainLinkKind {
  /// The first workout: sets the bar.
  base,

  /// Burned more than the bar: pays ×2 and becomes the new bar.
  beat,

  /// Burned less than the bar: ends the chain.
  breaker,
}

class ChainLink {
  final String activityId;
  final String type;
  final int durationMinutes;
  final int calories;
  final DateTime loggedAt;
  final ChainLinkKind kind;

  /// The bar this workout was measured against (null for the first one).
  final int? barBefore;

  const ChainLink({
    required this.activityId,
    required this.type,
    required this.durationMinutes,
    required this.calories,
    required this.loggedAt,
    required this.kind,
    required this.barBefore,
  });

  int get multiplier => kind == ChainLinkKind.beat
      ? kBurnChainBeatMultiplier
      : kBurnChainBaseMultiplier;

  int get coins => (calories ~/ 5) * multiplier;
}

enum BurnChainPhase {
  /// No chain started, or the last one was collected.
  idle,

  /// Window open and not broken.
  live,

  /// Broken or out of time; coins waiting to be collected.
  ended,

  /// Rewards collected, but the original 24-hour window has not closed.
  cooldown,
}

enum BurnChainEndReason { broken, timeUp }

class BurnChainState {
  final BurnChainPhase phase;
  final DateTime? startedAt;
  final List<ChainLink> links;
  final BurnChainEndReason? endReason;
  final DateTime? nextStartAt;
  final int talentCrystals;

  const BurnChainState({
    required this.phase,
    required this.startedAt,
    required this.links,
    this.endReason,
    this.nextStartAt,
    this.talentCrystals = 0,
  });

  static const idle =
      BurnChainState(phase: BurnChainPhase.idle, startedAt: null, links: []);

  DateTime? get endsAt => startedAt?.add(kBurnChainWindow);

  /// Calories the next workout has to beat, or null before the first one.
  int? get bar {
    int? bar;
    for (final link in links) {
      if (link.kind != ChainLinkKind.breaker) bar = link.calories;
    }
    return bar;
  }

  int get totalCoins => links.fold(0, (sum, l) => sum + l.coins);

  /// Workouts that beat the bar.
  int get beats => links.where((l) => l.kind == ChainLinkKind.beat).length;

  ChainLink? get bestLink => links.isEmpty
      ? null
      : links.reduce((a, b) => b.calories > a.calories ? b : a);

  Duration timeLeft(DateTime now) {
    final end = endsAt;
    if (end == null) return Duration.zero;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// Builds the chain from the workouts logged inside the window.
///
/// Workouts are taken oldest first. The first sets the bar; each one that
/// burns more beats it; the first one that burns less (or the same) breaks
/// the chain and nothing after it counts.
BurnChainState computeBurnChain({
  required DateTime? startedAt,
  required bool collected,
  required List<ActivityHistoryDto> activities,
  required DateTime now,
}) {
  if (startedAt == null || collected) return BurnChainState.idle;
  final endsAt = startedAt.add(kBurnChainWindow);

  final inWindow = activities
      .where((a) =>
          !a.loggedAt.isBefore(startedAt) &&
          a.loggedAt.isBefore(endsAt) &&
          a.durationMinutes >= kBurnChainMinMinutes &&
          a.calories > 0)
      .toList()
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  final links = <ChainLink>[];
  int? bar;
  for (final a in inWindow) {
    final ChainLinkKind kind;
    if (bar == null) {
      kind = ChainLinkKind.base;
    } else if (a.calories > bar) {
      kind = ChainLinkKind.beat;
    } else {
      kind = ChainLinkKind.breaker;
    }
    links.add(ChainLink(
      activityId: a.id,
      type: a.type,
      durationMinutes: a.durationMinutes,
      calories: a.calories,
      loggedAt: a.loggedAt,
      kind: kind,
      barBefore: bar,
    ));
    if (kind == ChainLinkKind.breaker) {
      return BurnChainState(
        phase: BurnChainPhase.ended,
        startedAt: startedAt,
        links: links,
        endReason: BurnChainEndReason.broken,
      );
    }
    bar = a.calories;
  }

  if (!now.isBefore(endsAt)) {
    return BurnChainState(
      phase: BurnChainPhase.ended,
      startedAt: startedAt,
      links: links,
      endReason: BurnChainEndReason.timeUp,
    );
  }
  return BurnChainState(
    phase: BurnChainPhase.live,
    startedAt: startedAt,
    links: links,
  );
}
