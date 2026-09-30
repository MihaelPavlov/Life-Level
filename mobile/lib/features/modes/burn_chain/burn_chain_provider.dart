import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers/character_provider.dart';
import '../services/modes_api_service.dart';
import 'burn_chain_rules.dart';

/// The chain plus how many of its links the player has already seen.
class BurnChainView {
  final BurnChainState chain;
  final int seenLinks;
  const BurnChainView(this.chain, this.seenLinks);

  /// The newest link, when it hasn't been shown to the player yet.
  ChainLink? get unseenLink =>
      chain.links.length > seenLinks ? chain.links.last : null;
}

class BurnChainNotifier extends AsyncNotifier<BurnChainView> {
  Timer? _tick;

  @override
  Future<BurnChainView> build() async {
    final api = await ref.read(modesApiServiceProvider).burnStatus();
    final chain = api.chain;

    // Re-check once the window closes, so a live chain ends on time.
    _tick?.cancel();
    if (chain.phase == BurnChainPhase.live) {
      _tick = Timer(chain.timeLeft(DateTime.now().toUtc()), ref.invalidateSelf);
    }
    ref.onDispose(() => _tick?.cancel());

    return BurnChainView(chain, api.acknowledgedLinks);
  }

  Future<void> start() async {
    state = const AsyncLoading();
    try {
      final api = await ref.read(modesApiServiceProvider).startBurn();
      state = AsyncData(BurnChainView(api.chain, api.acknowledgedLinks));
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<void> collect() async {
    try {
      final api = await ref.read(modesApiServiceProvider).collectBurn();
      state = AsyncData(BurnChainView(api.chain, api.acknowledgedLinks));
      ref.invalidate(characterProfileProvider);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<void> markSeen() async {
    final view = state.valueOrNull;
    if (view == null) return;
    final count = view.chain.links.length;
    if (count == view.seenLinks) return;
    final api = await ref.read(modesApiServiceProvider).acknowledgeBurn(count);
    state = AsyncData(BurnChainView(api.chain, api.acknowledgedLinks));
  }

  /// Pulls fresh workouts (e.g. after an import) and rebuilds the chain.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final burnChainProvider =
    AsyncNotifierProvider<BurnChainNotifier, BurnChainView>(
        BurnChainNotifier.new);
