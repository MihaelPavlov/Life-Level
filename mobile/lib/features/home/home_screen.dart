import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../activity/providers/activity_provider.dart';
import '../boss/providers/boss_provider.dart';
import '../character/providers/character_provider.dart';
import '../integrations/providers/integrations_provider.dart';
import '../tutorial/providers/tutorial_provider.dart';
import 'cards/home_header.dart';
import 'cards/home_portal_card.dart';
import 'cards/home_log_workout_cta.dart';
import 'cards/home_login_reward_chip.dart';
import 'cards/home_seasonal_event_row.dart';
import 'cards/home_stat_strip.dart';
import 'cards/home_streak_strip.dart';
import 'cards/home_todays_quests.dart';
import 'cards/home_xp_storm_banner.dart';
import 'providers/world_progress_provider.dart';

/// Home tab scaffold. Owns layout + the sync handler only; every card lives
/// in its own file under `cards/`.
///
/// Visual layout matches `design-mockup/home/home-v3.html` screens 1–3
/// (screen 4 is the notifications sheet, triggered from the header bell
/// via [showNotificationsSheet]).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // LL-035: GlobalKeys attached to the three Home coach-mark targets. The
  // tutorial controller reads their global rects to place floating bubbles.
  final _xpCardKey = GlobalKey();
  final _statsRowKey = GlobalKey();
  final _questsCardKey = GlobalKey();
  bool _tutorialKeysRegistered = false;

  @override
  void dispose() {
    final c = ref.read(tutorialControllerProvider);
    c.unregisterKey('xpCard');
    c.unregisterKey('statsRow');
    c.unregisterKey('questsCard');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;

    if (!_tutorialKeysRegistered) {
      _tutorialKeysRegistered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = ref.read(tutorialControllerProvider);
        c.registerKey('xpCard', _xpCardKey);
        c.registerKey('statsRow', _statsRowKey);
        c.registerKey('questsCard', _questsCardKey);
      });
    }

    // XP Storm & Seasonal event are scaffold-only — they render nothing
    // until LL-001 / LL-012 land a real feed and start returning non-null
    // state here.
    const xpStormState = null;
    const seasonalState = null;

    return Container(
      color: AppColors.backgroundAlt,
      child: Stack(
        children: [
          SingleChildScrollView(
            // Reserve room at the bottom so scrolled content never hides
            // behind the pinned "Log workout" CTA.
            padding: const EdgeInsets.only(bottom: 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(profile: profile),
                const HomeXpStormBanner(state: xpStormState),
                const HomeStreakStrip(),
                Padding(
                  key: _xpCardKey,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomePortalCard(
                    onSync: () => _handleSync(context, ref),
                  ),
                ),
                Container(
                  key: _statsRowKey,
                  child: const HomeStatStrip(),
                ),
                const HomeSeasonalEventRow(state: seasonalState),
                const HomeLoginRewardChip(),
                Container(
                  key: _questsCardKey,
                  child: const HomeTodaysQuestsCard(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Pinned CTA above the shell nav bar.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeLogWorkoutCta(),
          ),
        ],
      ),
    );
  }

  // ── Sync handler (wired into the Adventure Hero "Sync" button) ──────────
  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing activities...')),
    );

    int imported = 0;
    int skipped = 0;

    // Server-side integrations (Strava, Garmin, …)
    try {
      final res = await ApiClient.instance.post('/integrations/sync-all');
      final body = res.data as Map<String, dynamic>? ?? {};
      imported += (body['imported'] as int?) ?? 0;
      skipped += (body['skipped'] as int?) ?? 0;
    } catch (_) {/* swallow */}

    // Client-side Health Connect
    try {
      await ref.read(integrationSyncProvider.notifier).syncNow();
      final result = ref.read(integrationSyncProvider).lastResult;
      if (result != null) {
        imported += result.imported;
        skipped += result.skipped;
      }
    } catch (_) {/* swallow */}

    ref.invalidate(worldProgressProvider);
    ref.invalidate(currentRegionDetailProvider);
    ref.invalidate(characterProfileProvider);
    ref.invalidate(activityHistoryProvider);
    ref.invalidate(bossListProvider);

    if (!context.mounted) return;
    final msg = imported > 0
        ? 'Synced $imported new activit${imported == 1 ? 'y' : 'ies'}!'
        : skipped > 0
            ? 'Already up to date ($skipped synced)'
            : 'No new activities found';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
