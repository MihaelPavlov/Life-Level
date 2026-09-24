import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/motion/app_motion.dart';
import '../../core/services/level_up_notifier.dart';
import '../../core/widgets/app_toast.dart';
import '../character/providers/character_provider.dart';
import 'buy_founder_pass_screen.dart';
import 'models/season_models.dart';
import 'providers/season_provider.dart';
import 'widgets/season_legend.dart';
import 'widgets/season_milestone_card.dart';
import 'widgets/season_reward_sheet.dart';
import 'widgets/season_theme.dart';
import 'widgets/season_tier_row.dart';

class SeasonTrackScreen extends ConsumerWidget {
  final VoidCallback? onClose;
  const SeasonTrackScreen({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seasonProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.blue, strokeWidth: 2),
          ),
          error: (e, _) => _ErrorState(
            onRetry: () => ref.read(seasonProvider.notifier).refresh(),
            onClose: onClose,
          ),
          data: (track) => _Body(track: track, onClose: onClose),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final SeasonTrack track;
  final VoidCallback? onClose;
  const _Body({required this.track, this.onClose});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  static const _tierRowExtent = 86.0;
  late final ScrollController _trackController;

  SeasonTrack get track => widget.track;
  VoidCallback? get onClose => widget.onClose;

  @override
  void initState() {
    super.initState();
    _trackController = ScrollController(
      initialScrollOffset: _initialTierIndex(track) * _tierRowExtent,
    );
  }

  @override
  void dispose() {
    _trackController.dispose();
    super.dispose();
  }

  int _initialTierIndex(SeasonTrack value) {
    final ready = value.tiers.indexWhere((tier) =>
        tier.free.state == SeasonRewardState.ready ||
        tier.founder.state == SeasonRewardState.ready);
    if (ready >= 0) return ready;

    final pending = value.tiers.indexWhere((tier) =>
        tier.free.state == SeasonRewardState.pending ||
        tier.founder.state == SeasonRewardState.pending);
    if (pending >= 0) return pending;

    return value.tiers.isEmpty ? 0 : value.tiers.length - 1;
  }

  Future<void> _claim(BuildContext context) async {
    try {
      final rewards = await ref.read(seasonProvider.notifier).claimAvailable();
      final result = SeasonClaimResult.combined(rewards);
      ref.invalidate(characterProfileProvider);
      if (!context.mounted) return;
      // Non-blocking bottom pop-up that auto-dismisses — collect several
      // tiers in a row without tapping "Continue".
      unawaited(showSeasonRewardSheet(context, result));
      if (result.leveledUp && result.newLevel != null) {
        LevelUpNotifier.notify(result.newLevel!);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!track.hasActiveSeason || track.season == null) {
      return _NoSeason(onClose: onClose);
    }
    final s = track.season!;
    final accent = SeasonAccent.of(s.theme);
    final milestone = track.tiers
        .where((t) => t.isMilestone)
        .cast<SeasonTier?>()
        .firstWhere((_) => true, orElse: () => null);

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppColors.textPrimary),
                onPressed: onClose ?? () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('SEASON ${s.number}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        )),
                    Text(s.name,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accent.accent)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('ENDS IN',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: AppColors.textSecondary)),
                  Text('${s.daysLeft}d',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        ),

        // ── Tier XP bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              _TierChip(
                  label: '${track.currentTier}',
                  accent: accent.accent,
                  filled: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: track.tierProgress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation(accent.accent),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      track.currentTier >= track.tierCount
                          ? 'Track complete'
                          : '${track.xpToNextTier} Season XP to Tier ${track.currentTier + 1}'
                              '${track.nextReward != null ? ' · next ${track.nextReward!.label}' : ''}',
                      style: const TextStyle(
                          fontSize: 9.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _TierChip(
                  label: track.tierCount < 1
                      ? '—'
                      : '${(track.currentTier + 1).clamp(1, track.tierCount)}',
                  accent: accent.accent,
                  filled: false),
            ],
          ),
        ),

        // ── Unlock Founder lane ──
        if (!track.hasFounderPass)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                AppRoute(
                  builder: (_) => BuyFounderPassScreen(theme: s.theme),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.accentSoft,
                  border: Border.all(
                      color: accent.accent.withValues(alpha: 0.5),
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_open_rounded,
                        size: 16, color: accent.accent),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unlock the Founder lane',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent.accent)),
                          const Text('Every Founder reward, this season',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: accent.accent),
                  ],
                ),
              ),
            ),
          ),

        // ── Lane headers ──
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('FREE',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: AppColors.textSecondary)),
              ),
              Text('FOUNDER',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: AppColors.orange)),
            ],
          ),
        ),

        // ── Track ──
        Expanded(
          child: ListView(
            controller: _trackController,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
            children: [
              for (final tier in track.tiers)
                SeasonTierRow(
                  tier: tier,
                  onClaim: (_, __) => _claim(context),
                ),
              const SeasonLegend(),
              if (milestone != null) SeasonMilestoneCard(tier: milestone),
            ],
          ),
        ),
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool filled;
  const _TierChip(
      {required this.label, required this.accent, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            filled ? accent.withValues(alpha: 0.15) : AppColors.surfaceElevated,
        border: Border.all(color: filled ? accent : AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: filled ? accent : AppColors.textSecondary)),
    );
  }
}

class _NoSeason extends StatelessWidget {
  final VoidCallback? onClose;
  const _NoSeason({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textPrimary),
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
        ),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No season is running right now.\nCheck back soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onClose;
  const _ErrorState({required this.onRetry, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textPrimary),
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 40),
                const SizedBox(height: 12),
                const Text('Failed to load the Season Track',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry',
                      style: TextStyle(color: AppColors.blue)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
