import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../activity/providers/activity_provider.dart';
import '../providers/map_journey_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../widgets/home_stat_tile.dart';

/// Three-up compact stat strip: Banked km · Today's XP · Shields.
/// Matches `.home3-strip` in home-v3.html.
///
/// When `pendingDistanceKm == 0` the banked tile dims to a muted "Log a run"
/// hint variant (mockup screen 2).
class HomeStatStrip extends ConsumerWidget {
  const HomeStatStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapJourneyProvider);
    final historyAsync = ref.watch(activityHistoryProvider);
    final streakAsync = ref.watch(streakProvider);

    final pendingKm =
        mapAsync.valueOrNull?.userProgress.pendingDistanceKm ?? 0.0;
    final todaysXp = _todaysXp(historyAsync.valueOrNull);
    final shields = streakAsync.valueOrNull?.shieldsAvailable ?? 0;

    final bankedDim = pendingKm <= 0.001;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16)
          .copyWith(bottom: 14),
      child: Row(
        children: [
          HomeStatTile(
            icon: '\uD83C\uDFE6', // 🏦
            label: bankedDim ? 'LOG A RUN' : 'BANKED',
            value: bankedDim
                ? '\u2014'
                : '${pendingKm.toStringAsFixed(1)} km',
            valueColor: AppColors.blue,
            primary: !bankedDim,
            dim: bankedDim,
            onTap: () => NavTabNotifier.switchTo('map'),
          ),
          const SizedBox(width: 8),
          HomeStatTile(
            icon: '\u2728', // ✨
            label: 'TODAY',
            value: todaysXp > 0 ? '+$todaysXp XP' : '+0 XP',
            valueColor: AppColors.orange,
          ),
          const SizedBox(width: 8),
          HomeStatTile(
            icon: '\uD83D\uDEE1', // 🛡
            label: 'SHIELDS',
            value: '$shields',
            valueColor: AppColors.purple,
          ),
        ],
      ),
    );
  }

  /// Sum XP earned from activities logged today (local time).
  int _todaysXp(List<Object?>? history) {
    if (history == null || history.isEmpty) return 0;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (final entry in history) {
      // The list comes back as `List<ActivityHistoryDto>` but we keep the
      // type loose here to avoid importing the activity package into this
      // shell widget — we duck-type the two fields we need.
      try {
        final logged = (entry as dynamic).loggedAt;
        final xp = (entry as dynamic).xpGained;
        if (logged is DateTime && xp is int) {
          final localLogged = logged.isUtc ? logged.toLocal() : logged;
          if (!localLogged.isBefore(startOfDay)) total += xp;
        }
      } catch (_) {
        // Skip malformed rows rather than crash the strip.
      }
    }
    return total;
  }
}
