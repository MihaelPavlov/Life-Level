import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/services/seen_state_client.dart';
import '../character/providers/character_provider.dart';
import '../home/providers/adventure_hub_status_provider.dart';
import '../unlocks/tour/tour_target.dart';
import '../unlocks/tour/tours/unlock_tours.dart';
import 'models/title_models.dart';
import 'providers/titles_provider.dart';
import 'widgets/rank_ladder_widget.dart';
import 'widgets/title_equip_flight.dart';
import 'widgets/title_list_item.dart';
import 'widgets/titles_profile_header.dart';

class TitlesRanksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const TitlesRanksScreen({super.key, this.onClose});

  @override
  ConsumerState<TitlesRanksScreen> createState() => _TitlesRanksScreenState();
}

class _TitlesRanksScreenState extends ConsumerState<TitlesRanksScreen> {
  final _flight = TitleEquipFlight();
  final Set<String> _seenInFlight = {};
  final Set<String> _newTitleIds = {};

  VoidCallback? get onClose => widget.onClose;

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  /// Ribbon flight: the title lifts off its card as a glowing pill, flies
  /// into the header nameplate (the old title falls off meanwhile), and the
  /// equip is committed as it lands — so the nameplate letters, badge and
  /// border swap all play together from the optimistic update.
  Future<void> _equip(TitleDto title) async {
    if (_flight.inFlight) return;
    final from = RewardFx.rectOf(_flight.nameKeyFor(title.id));
    final to = RewardFx.rectOf(_flight.plateKey);
    if (!RewardFx.enabled(context) || from == null || to == null) {
      return _commit(title);
    }
    AppMotion.haptic(AppHaptic.selection);
    _flight.launch(title.id);
    await RewardFx.fly(
      context,
      child: TitleGhostPill(title: title),
      from: from.center,
      to: to.center,
      lift: -70,
      endScale: .92,
      duration: const Duration(milliseconds: 560),
      delay: const Duration(milliseconds: 80),
    );
    if (!mounted) return;
    _flight.land();
    RewardFx.burst(context, to.center, AppColors.orange,
        count: 14, distance: 50);
    AppMotion.haptic(AppHaptic.light);
    await _commit(title);
  }

  Future<void> _commit(TitleDto title) async {
    try {
      await ref.read(titlesProvider.notifier).equipTitle(title.id);
    } catch (_) {
      _flight.cancel();
      if (mounted) {
        AppToast.error(context, 'Couldn\'t equip ${title.name}. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titlesAsync = ref.watch(titlesProvider);
    final seenReady =
        ref.watch(adventureHubSeenMigrationProvider) is AsyncData<void> &&
            titlesAsync is AsyncData<TitlesAndRanksResponse>;
    final unseenIds = (seenReady ? titlesAsync.valueOrNull : null)?.earnedTitles
            .where((title) => title.seenAt == null)
            .map((title) => title.id)
            .where((id) => !_seenInFlight.contains(id))
            .toList() ?? const <String>[];
    if (unseenIds.isNotEmpty) {
      _newTitleIds.addAll(unseenIds);
      _seenInFlight.addAll(unseenIds);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_markSeen(unseenIds));
      });
    }
    final profileAsync = ref.watch(characterProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Titles & Ranks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: titlesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.blue,
                    strokeWidth: 2,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load titles',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              ref.read(titlesProvider.notifier).refresh(),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: AppColors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) {
                  final profile = profileAsync.valueOrNull;
                  final earnedTitles = [...data.earnedTitles]
                    ..sort((a, b) =>
                        (_newTitleIds.contains(b.id) ? 1 : 0) -
                        (_newTitleIds.contains(a.id) ? 1 : 0));
                  final firstToEquip =
                      earnedTitles.where((t) => !t.isEquipped).firstOrNull;

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: profile != null
                            ? TitlesProfileHeader(
                                data: data,
                                profile: profile,
                                flight: _flight,
                              )
                            : const SizedBox(height: 16),
                      ),
                      const SliverToBoxAdapter(
                        child: _SectionLabel('RANK PROGRESSION'),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: TourTarget(
                            id: TourIds.titlesRank,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: RankLadderWidget(
                                progression: data.rankProgression,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _SectionLabel(
                          'EARNED TITLES (${data.earnedTitles.length})',
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: ListenableBuilder(
                              listenable: _flight,
                              builder: (_, __) {
                                final t = earnedTitles[i];
                                final item = TitleListItem(
                                  key: ValueKey(t.id),
                                  title: t,
                                  isNew: _newTitleIds.contains(t.id),
                                  nameKey: _flight.nameKeyFor(t.id),
                                  equipDisabled: _flight.inFlight,
                                  onEquip: () => _equip(t),
                                );
                                // The tour ends on equipping the first title
                                // that isn't worn yet.
                                return t == firstToEquip
                                    ? TourTarget(
                                        id: TourIds.titlesEquip, child: item)
                                    : item;
                              },
                            ),
                          ),
                          childCount: earnedTitles.length,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: _SectionLabel('LOCKED TITLES'),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: i == 0
                                ? TourTarget(
                                    id: TourIds.titlesLocked,
                                    child: TitleListItem(
                                      title: data.lockedTitles[i],
                                      isLocked: true,
                                    ),
                                  )
                                : TitleListItem(
                                    title: data.lockedTitles[i],
                                    isLocked: true,
                                  ),
                          ),
                          childCount: data.lockedTitles.length,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markSeen(List<String> ids) async {
    try {
      await SeenStateClient().markTitles(ids);
      if (mounted) ref.invalidate(titlesProvider);
    } catch (_) {
      _seenInFlight.removeAll(ids);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
