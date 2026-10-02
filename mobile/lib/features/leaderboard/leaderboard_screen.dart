import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/services/shell_overlay_notifier.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/currency_chip.dart';
import '../character/providers/character_provider.dart';
import '../rewards/widgets/task_reward_popup.dart';
import '../shop/shop_screen.dart';
import '../unlocks/models/unlock_catalog.dart';
import '../unlocks/tour/tour_target.dart';
import '../unlocks/tour/tours/unlock_tours.dart';
import '../unlocks/tour/unlock_tour_runner.dart';
import 'models/leaderboard_models.dart';
import 'providers/leaderboard_provider.dart';
import 'widgets/leaderboard_widgets.dart';

/// Leaderboard: Global · Region · Guild, ranked by Power (all-time) or a
/// weekly metric. Your row is pinned at the bottom; every player you pass
/// stacks a reward in the rank-up chest on it.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  static void open(BuildContext context) => Navigator.push(
      context,
      AppRoute(
          builder: (_) => const TourOnFirstVisit(
              unlockKey: UnlockKeys.leaderboard, child: LeaderboardScreen())));

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  var _scope = LeaderboardScope.global;
  var _metric = LeaderboardMetric.power;
  var _opening = false;

  (LeaderboardScope, LeaderboardMetric) get _key => (_scope, _metric);

  Future<void> _refresh() async {
    ref.invalidate(leaderboardChestProvider);
    ref.invalidate(leaderboardProvider(_key));
    await ref.read(leaderboardProvider(_key).future);
  }

  Future<void> _openChest() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final result = await ref.read(leaderboardServiceProvider).openChest();
      if (!mounted) return;
      if (result.passes.isNotEmpty) {
        await showRewardRevealPopup(
          context,
          items: [
            if (result.coins > 0)
              RewardRevealItem(
                  asset: AppIcons.homeCoinIcon,
                  label: '×${result.coins}',
                  color: AppColors.orange),
            if (result.gems > 0)
              RewardRevealItem(
                  asset: AppIcons.homeGemIcon,
                  label: '×${result.gems}',
                  color: AppColors.purple),
          ],
          subtitle:
              passedSubtitle(result.passes.map((p) => p.username).toList()),
          heroAsset: AppIcons.rewardChestBurst,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not open the chest. Try again.');
      }
    } finally {
      ref.invalidate(characterProfileProvider);
      ref.invalidate(leaderboardChestProvider);
      ref.invalidate(leaderboardProvider(_key));
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final wallet = profile?.talents;
    final board = ref.watch(leaderboardProvider(_key));
    final data = board.valueOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1C34),
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset(AppIcons.regionChestsBackground,
                  fit: BoxFit.cover)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .5, .72],
                  colors: [
                    Color(0x59040810),
                    Color(0x80040810),
                    Color(0xEB040810)
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 26),
                      ),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _WalletChip(
                            icon: AppIcons.homeGemIcon,
                            value: '${wallet?.gems ?? 0}'),
                        const SizedBox(width: 10),
                        _WalletChip(
                            icon: AppIcons.homeCoinIcon,
                            value: leaderboardFmt(wallet?.coins ?? 0)),
                      ]),
                    ],
                  ),
                ),
                const _TitleRibbon('Leaderboard'),
                const SizedBox(height: 4),
                _PeriodPill(text: periodLabel(_metric, data)),
                const SizedBox(height: 10),
                TourTarget(
                  id: TourIds.leaderboardScopes,
                  child: _ScopeTabs(
                    value: _scope,
                    onChanged: (s) => setState(() => _scope = s),
                  ),
                ),
                const SizedBox(height: 8),
                TourTarget(
                  id: TourIds.leaderboardMetrics,
                  child: _MetricChips(
                    value: _metric,
                    onChanged: (m) => setState(() => _metric = m),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.blue,
                    backgroundColor: AppColors.surface,
                    onRefresh: _refresh,
                    child: board.when(
                      skipLoadingOnReload: true,
                      data: (b) =>
                          _BoardList(board: b, bottomPad: 110 + bottomInset),
                      loading: () => const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.blue)),
                      error: (_, __) => _Message(
                        icon: Icons.wifi_off_rounded,
                        title: 'Could not load the leaderboard',
                        body: 'Pull down to try again.',
                        bottomPad: 110 + bottomInset,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (data != null && data.chest.stack > 0)
            Positioned(
              right: 16,
              bottom: 96 + bottomInset,
              child: IgnorePointer(child: ClimbedPill(stack: data.chest.stack)),
            ),
          if (data != null && data.available)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16 + bottomInset,
              child: TourTarget(
                id: TourIds.leaderboardYou,
                child: _YouRow(
                  board: data,
                  avatarEmoji: profile?.avatarEmoji,
                  opening: _opening,
                  onOpenChest: _openChest,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "You passed Taro, Lena and Oskar" for the chest reveal.
String passedSubtitle(List<String> names) {
  if (names.isEmpty) return 'Rank-up chest';
  if (names.length == 1) return 'You passed ${names.first}';
  if (names.length <= 3) {
    return 'You passed ${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }
  return 'You passed ${names.take(2).join(', ')} and ${names.length - 2} more';
}

/// The line under the ribbon: what the board is and when it resets.
String periodLabel(LeaderboardMetric metric, LeaderboardBoard? board,
    {DateTime? now}) {
  final context = board?.contextName;
  final String period;
  if (metric == LeaderboardMetric.power) {
    period = 'All-time';
  } else if (metric == LeaderboardMetric.streak) {
    period = 'Current streaks';
  } else if (board?.resetsAt != null) {
    final left = board!.resetsAt!.difference(now ?? DateTime.now().toUtc());
    final d = left.inDays, h = left.inHours % 24;
    period = left.isNegative
        ? 'This week'
        : 'Resets in ${d > 0 ? '${d}d ' : ''}${h}h';
  } else {
    period = 'This week';
  }
  return context == null ? period : '$context · $period';
}

/// The gold line on your row.
String youGapLabel(LeaderboardBoard b) {
  final me = b.me;
  if (me.rank == null) return 'Train to get on this board';
  if (me.rank == 1) return 'You lead this board';
  final gap = me.gapToNext ?? 0;
  if (gap <= 0) return 'Tied with ${me.nextUsername}';
  return '${b.metric.gap(gap)} to pass ${me.nextUsername}';
}

class _BoardList extends StatelessWidget {
  final LeaderboardBoard board;
  final double bottomPad;

  const _BoardList({required this.board, required this.bottomPad});

  @override
  Widget build(BuildContext context) {
    if (!board.available) {
      return board.scope == LeaderboardScope.guild
          ? _Message(
              icon: Icons.shield_outlined,
              title: 'Join a guild',
              body: 'Guild boards rank you against your guildmates.',
              action: 'Find a guild',
              onAction: () => ShellOverlayNotifier.open('guild'),
              bottomPad: bottomPad,
            )
          : _Message(
              icon: Icons.map_outlined,
              title: 'No region yet',
              body: 'Travel on the map to join your region\'s board.',
              bottomPad: bottomPad,
            );
    }
    if (board.entries.isEmpty) {
      return _Message(
        icon: Icons.emoji_events_outlined,
        title: 'No one here yet',
        body: 'Log a workout to be first on this board.',
        bottomPad: bottomPad,
      );
    }
    final top = board.entries.take(3).toList();
    final rest = board.entries.skip(3).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
      children: [
        LeaderboardPodium(top: top, metric: board.metric),
        if (rest.isNotEmpty)
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xF0161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              for (final e in rest)
                LeaderboardRow(entry: e, metric: board.metric),
            ]),
          ),
      ],
    );
  }
}

class _YouRow extends StatelessWidget {
  final LeaderboardBoard board;
  final String? avatarEmoji;
  final bool opening;
  final VoidCallback onOpenChest;

  const _YouRow({
    required this.board,
    required this.avatarEmoji,
    required this.opening,
    required this.onOpenChest,
  });

  @override
  Widget build(BuildContext context) {
    final me = board.me;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1D33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue, width: 2),
        boxShadow: [
          const BoxShadow(
              color: Color(0x99000000), blurRadius: 30, offset: Offset(0, -8)),
          BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.3), blurRadius: 24),
        ],
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 34),
            child: Text(me.rank == null ? '—' : '#${leaderboardFmt(me.rank!)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7DB6FF))),
          ),
          const SizedBox(width: 6),
          LeaderboardAvatar(
              avatarEmoji: avatarEmoji, size: 38, border: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You · ${board.metric.format(me.score)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                Text(youGapLabel(board),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kPodiumGold)),
              ],
            ),
          ),
          if (board.chest.stack > 0)
            RankUpChestButton(
                stack: board.chest.stack, busy: opening, onTap: onOpenChest),
        ],
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  final LeaderboardScope value;
  final ValueChanged<LeaderboardScope> onChanged;

  const _ScopeTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          for (final s in LeaderboardScope.values)
            Expanded(
              child: Semantics(
                selected: s == value,
                button: true,
                child: AppPressable(
                  onTap: () => onChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s == value ? AppColors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(s.label,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: s == value
                                ? const Color(0xFF04101F)
                                : const Color(0xFFAAB4C0))),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChips extends StatelessWidget {
  final LeaderboardMetric value;
  final ValueChanged<LeaderboardMetric> onChanged;

  const _MetricChips({required this.value, required this.onChanged});

  static String _icon(LeaderboardMetric m) => switch (m) {
        LeaderboardMetric.power => AppIcons.homePowerIcon,
        LeaderboardMetric.xp => AppIcons.mapXpReward,
        LeaderboardMetric.km => AppIcons.activityRunning,
        LeaderboardMetric.boss => AppIcons.ringBoss,
        LeaderboardMetric.streak => AppIcons.rewardStreakFire,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: LeaderboardMetric.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final m = LeaderboardMetric.values[i];
          final on = m == value;
          return Semantics(
            selected: on,
            button: true,
            child: AppPressable(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: on
                      ? AppColors.orange.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: on
                          ? AppColors.orange
                          : Colors.white.withValues(alpha: 0.12),
                      width: on ? 1.5 : 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(_icon(m), width: 16, height: 16),
                  const SizedBox(width: 5),
                  Text(m.label,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: on ? kPodiumGold : const Color(0xFFC9D4E3))),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String text;
  const _PeriodPill({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1420),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final double bottomPad;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.bottomPad,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 40, 24, bottomPad),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xF0161B22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            if (action != null) ...[
              const SizedBox(height: 14),
              AppPressable(
                onTap: onAction,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(action!,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF04101F))),
                ),
              ),
            ],
          ]),
        ),
      ],
    );
  }
}

/// Wallet chip styled like the Region Chests header; tapping opens the Shop.
class _WalletChip extends StatelessWidget {
  final String icon;
  final String value;

  const _WalletChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => CurrencyChip(
        iconAsset: icon,
        value: value,
        onTapAdd: () => Navigator.of(context)
            .push(AppRoute(builder: (_) => const ShopScreen())),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: const Color(0xFF0b1420),
        borderColor: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        iconSize: 15,
        valueFontSize: 11.5,
        gap: 5,
      );
}

/// The Region Chests gold ribbon with the page name.
class _TitleRibbon extends StatelessWidget {
  final String text;
  const _TitleRibbon(this.text);

  static const double _aspect = 1537 / 327;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 260,
          child: AspectRatio(
            aspectRatio: _aspect,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(AppIcons.regionChestsTitleBanner,
                    fit: BoxFit.contain),
                Text(text,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5a3300),
                        letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      );
}
