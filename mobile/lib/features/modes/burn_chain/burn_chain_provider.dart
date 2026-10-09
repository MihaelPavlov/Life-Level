import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers/character_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/client_experience_service.dart';
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
    final previous = state;
    final optimistic = ClientExperienceService.instance.enabled('modes');
    if (optimistic) {
      state = AsyncData(BurnChainView(
        BurnChainState(
          phase: BurnChainPhase.live,
          startedAt: DateTime.now().toUtc(),
          links: const [],
        ),
        0,
      ));
    } else {
      state = const AsyncLoading();
    }
    try {
      final api = await ref
          .read(modesApiServiceProvider)
          .startBurn(operationId: ApiClient.newOperationId());
      state = AsyncData(BurnChainView(api.chain, api.acknowledgedLinks));
    } catch (error, stack) {
      state = optimistic ? previous : AsyncError(error, stack);
      rethrow;
    }
  }

  Future<void> collect() async {
    final previous = state;
    final current = state.valueOrNull;
    final optimistic = ClientExperienceService.instance.enabled('modes');
    if (optimistic && current != null) {
      final chain = current.chain;
      state = AsyncData(BurnChainView(
        BurnChainState(
          phase: BurnChainPhase.cooldown,
          startedAt: chain.startedAt,
          links: chain.links,
          endReason: chain.endReason,
          nextStartAt: chain.nextStartAt ?? chain.endsAt,
          talentCrystals: chain.talentCrystals,
        ),
        current.seenLinks,
      ));
      ref.read(characterProfileProvider.notifier).adjustWalletLocally(
          coins: chain.totalCoins, talentCrystals: chain.talentCrystals);
    }
    try {
      final api = await ref
          .read(modesApiServiceProvider)
          .collectBurn(operationId: ApiClient.newOperationId());
      state = AsyncData(BurnChainView(api.chain, api.acknowledgedLinks));
      ref.invalidate(characterProfileProvider);
    } catch (error, stack) {
      state = optimistic ? previous : AsyncError(error, stack);
      if (optimistic && current != null) {
        ref.read(characterProfileProvider.notifier).adjustWalletLocally(
            coins: -current.chain.totalCoins,
            talentCrystals: -current.chain.talentCrystals);
      }
      rethrow;
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
