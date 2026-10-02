import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/boss_damage_history.dart';
import '../models/boss_list_item.dart';
import '../services/boss_page_service.dart';
import 'boss_seen_store.dart';

/// One exchange to replay: the player's workout hits the boss, then the
/// boss hits back (unless the hit finished it or the player was recovering).
@immutable
class BossReplayTurn {
  final String activityType;
  final int dealt;
  final int taken;
  final int blocked;
  final int bossHpAfter;
  final int youHpAfter;
  final bool finisher;
  final bool ko;

  /// The player was knocked out: the workout earned rewards but no attack.
  final bool recovering;
  final DateTime at;

  /// Workouts folded into this turn (>1 for the combined "×N" opener).
  final int count;

  const BossReplayTurn({
    required this.activityType,
    required this.dealt,
    required this.taken,
    required this.blocked,
    required this.bossHpAfter,
    required this.youHpAfter,
    required this.at,
    this.finisher = false,
    this.ko = false,
    this.recovering = false,
    this.count = 1,
  });

  factory BossReplayTurn.fromHistory(BossDamageHistoryItem h) => BossReplayTurn(
        activityType: h.activityType,
        dealt: h.damage,
        taken: h.damageTaken,
        blocked: h.damageBlocked,
        bossHpAfter: h.bossHpAfter,
        youHpAfter: h.playerHpAfter,
        at: h.loggedAt,
        finisher: h.bossDefeated,
        ko: h.playerDefeated,
        recovering: h.skipReason == 'PlayerRecovering',
      );
}

/// Every unseen exchange for one boss, oldest first, plus the HP values the
/// player saw before them.
@immutable
class BossReplay {
  final BossListItem boss;
  final List<BossReplayTurn> turns;
  final int startBossHp;
  final int startYouHp;
  final int bossMax;
  final int youMax;

  const BossReplay({
    required this.boss,
    required this.turns,
    required this.startBossHp,
    required this.startYouHp,
    required this.bossMax,
    required this.youMax,
  });

  bool get finished => turns.any((t) => t.finisher);
  bool get endsKnockedOut => turns.isNotEmpty && turns.last.youHpAfter <= 0;
  int get workouts => turns.fold(0, (a, t) => a + t.count);
  int get totalDealt => turns.fold(0, (a, t) => a + t.dealt);
  int get totalTaken => turns.fold(0, (a, t) => a + t.taken);
  BossReplayTurn get last => turns.last;

  /// Four or more exchanges play as one combined "×N" hit plus the last three.
  List<BossReplayTurn> get playable => collapseTurns(turns);
}

@visibleForTesting
List<BossReplayTurn> collapseTurns(List<BossReplayTurn> turns) {
  if (turns.length < 4) return turns;
  final head = turns.sublist(0, turns.length - 3);
  final tail = turns.sublist(turns.length - 3);
  final lastHead = head.last;
  final combined = BossReplayTurn(
    activityType: lastHead.activityType,
    dealt: head.fold(0, (a, t) => a + t.dealt),
    taken: head.fold(0, (a, t) => a + t.taken),
    blocked: head.fold(0, (a, t) => a + t.blocked),
    bossHpAfter: lastHead.bossHpAfter,
    youHpAfter: lastHead.youHpAfter,
    at: lastHead.at,
    count: head.fold(0, (a, t) => a + t.count),
  );
  return [combined, ...tail];
}

/// Finds exchanges the player hasn't seen yet. History older than a fresh
/// install (no record) counts as seen, except the last few minutes, so a
/// kill right after reinstalling still gets its moment.
class BossReplayFinder {
  BossReplayFinder._();

  static const _freshWindow = Duration(minutes: 15);
  static const _defeatedWindow = Duration(hours: 24);

  /// The first boss with unseen exchanges, or null. Bosses with nothing new
  /// are quietly brought up to date so the Map button shows live values.
  static Future<BossReplay?> find(
    BossPageService service, {
    String? onlyBossId,
    BossSeenStore? store,
    DateTime? now,
  }) async {
    final seenStore = store ?? BossSeenStore.instance;
    final clock = now ?? DateTime.now();
    final bosses = await service.getAllBosses();
    for (final boss in bosses) {
      if (onlyBossId != null && boss.id != onlyBossId) continue;
      final recentKill = boss.isDefeated &&
          boss.defeatedAt != null &&
          clock.difference(boss.defeatedAt!.toLocal()) < _defeatedWindow;
      if (!boss.isActive && !recentKill) continue;

      final history = await service.getDamageHistory(boss.id);
      final replay = build(boss, history, seenStore[boss.id], clock);
      if (replay != null) return replay;
      // Nothing new: show the live values.
      final rec = seenStore[boss.id];
      final latest = history.isEmpty ? null : history.first.loggedAt;
      seenStore.put(
        boss.id,
        BossSeenRecord(
          turnAt: rec?.turnAt ?? latest ?? clock,
          bossHp: boss.hpRemaining.clamp(0, boss.maxHp),
          youHp: boss.currentPlayerHp,
        ),
      );
    }
    return null;
  }

  /// Pure part of [find]: [history] is newest first, as the API returns it.
  @visibleForTesting
  static BossReplay? build(
    BossListItem boss,
    List<BossDamageHistoryItem> history,
    BossSeenRecord? rec,
    DateTime now,
  ) {
    final turns = history.reversed.where((h) => h.turnId != null).toList();
    if (turns.isEmpty) return null;
    final bossMax =
        turns.last.bossMaxHp > 0 ? turns.last.bossMaxHp : boss.maxHp;
    final youMax = boss.playerMaxHp > 0 ? boss.playerMaxHp : 1;

    final cutoff = rec?.turnAt ?? now.subtract(_freshWindow);
    final firstNew = turns.indexWhere((t) => t.loggedAt.isAfter(cutoff));
    if (firstNew < 0) return null;
    // A kill the player already watched elsewhere is done.
    if (rec != null && rec.bossHp <= 0) return null;

    final before = firstNew > 0 ? turns[firstNew - 1] : null;
    final startBossHp = rec?.bossHp ?? before?.bossHpAfter ?? bossMax;
    final startYouHp = rec != null && rec.youHp >= 0
        ? rec.youHp
        : before?.playerHpAfter ?? youMax;

    return BossReplay(
      boss: boss,
      turns: [
        for (final t in turns.sublist(firstNew)) BossReplayTurn.fromHistory(t)
      ],
      startBossHp: startBossHp.clamp(0, bossMax),
      startYouHp: startYouHp.clamp(0, youMax),
      bossMax: bossMax,
      youMax: youMax,
    );
  }

  /// Everything in [replay] has been shown.
  static void markSeen(BossReplay replay, {BossSeenStore? store}) {
    (store ?? BossSeenStore.instance).put(
      replay.boss.id,
      BossSeenRecord(
        turnAt: replay.last.at,
        bossHp: replay.last.bossHpAfter,
        youHp: replay.last.youHpAfter,
      ),
    );
  }
}
