import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers/character_provider.dart';
import '../services/modes_api_service.dart';
import 'delve_engine.dart';

/// Today's entry into Treasure Delve.
class DelveStatus {
  final int runsEarned;
  final int runsUsed;
  final DelveStat featured;
  final int bestRun;
  final DelveRun? activeRun;

  const DelveStatus({
    required this.runsEarned,
    required this.runsUsed,
    required this.featured,
    required this.bestRun,
    this.activeRun,
  });

  int get runsLeft => math.max(0, runsEarned - runsUsed);
}

final delveStatusProvider = FutureProvider<DelveStatus>((ref) async {
  final status = await ref.read(modesApiServiceProvider).delveStatus();
  return DelveStatus(
    runsEarned: status.runsEarned,
    runsUsed: status.runsUsed,
    featured: status.featured,
    bestRun: status.bestRun,
    activeRun: status.activeRun,
  );
});

/// The run in progress, or null between runs.
class DelveRunNotifier extends Notifier<DelveRun?> {
  @override
  DelveRun? build() => null;

  /// Spends one of today's runs and opens chamber 1. Returns false when no
  /// run is left.
  Future<bool> start() async {
    final status = await ref.read(delveStatusProvider.future);
    final run = status.activeRun ??
        await ref.read(modesApiServiceProvider).startDelve();
    state = run;
    ref.invalidate(delveStatusProvider);
    return true;
  }

  Future<void> choose(DelveOption option) async {
    final run = state;
    if (run == null) return;
    state = await ref.read(modesApiServiceProvider).choose(run.id, option.path);
  }

  void backToPaths() {
    final run = state;
    if (run == null || run.phase != DelvePhase.challenge) return;
    state = run.copyWith(clearChosen: true, phase: DelvePhase.choosing);
  }

  Future<void> attempt() async {
    final run = state;
    if (run == null) return;
    state = await ref.read(modesApiServiceProvider).attempt(run.id);
    if (state?.phase == DelvePhase.result) {
      ref.invalidate(characterProfileProvider);
    }
  }

  Future<void> bank() async {
    final run = state;
    if (run == null) return;
    state = await ref.read(modesApiServiceProvider).bank(run.id);
    ref.invalidate(characterProfileProvider);
  }

  Future<void> continueDeeper() async {
    final run = state;
    if (run == null) return;
    state = await ref.read(modesApiServiceProvider).continueRun(run.id);
  }

  Future<void> finish() async {
    final run = state;
    if (run != null) {
      await ref.read(modesApiServiceProvider).acknowledge(run.id);
    }
    ref.invalidate(delveStatusProvider);
    ref.invalidate(characterProfileProvider);
    state = null;
  }
}

final delveRunProvider =
    NotifierProvider<DelveRunNotifier, DelveRun?>(DelveRunNotifier.new);
