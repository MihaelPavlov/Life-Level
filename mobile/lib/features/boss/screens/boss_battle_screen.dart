import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../activity/log_activity_screen.dart';
import '../models/boss_list_item.dart';
import '../providers/boss_provider.dart';
import '../widgets/boss_damage_hit_row.dart';
import '../widgets/boss_hp_bar.dart';
import '../widgets/boss_damage_hint.dart';
import '../widgets/boss_icon.dart';

/// Inline battle view displayed within BossScreen (keeps bottom nav visible).
class BossBattleView extends ConsumerStatefulWidget {
  final BossListItem boss;
  final VoidCallback onBack;
  final VoidCallback? onRefreshRequested;

  const BossBattleView({
    super.key,
    required this.boss,
    required this.onBack,
    this.onRefreshRequested,
  });

  @override
  ConsumerState<BossBattleView> createState() => _BossBattleViewState();
}

class _BossBattleViewState extends ConsumerState<BossBattleView> {
  BossListItem get boss => widget.boss;
  VoidCallback get onBack => widget.onBack;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshBattleData);
  }

  @override
  void didUpdateWidget(covariant BossBattleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boss.id != widget.boss.id ||
        oldWidget.boss.hpDealt != widget.boss.hpDealt) {
      Future.microtask(_refreshBattleData);
    }
  }

  void _refreshBattleData() {
    ref.invalidate(bossDamageHistoryProvider(boss.id));
    widget.onRefreshRequested?.call();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = boss.timeRemaining;
    // World-zone bosses suppress the legacy 7-day expiry — backend returns
    // `timerExpiresAt: null` and `timerDays: 0`. Render ∞ / "no limit"
    // instead of the misleading "0d left" that the legacy formula prints.
    final timerText = remaining != null
        ? '${_fmtDuration(remaining)} left'
        : (boss.timerDays > 0 ? '${boss.timerDays}d left' : '∞ no limit');

    return Material(
      color: const Color(0xFF060b10),
      child: Stack(
        children: [
          // ── Background glow ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 0.8,
                  colors: [
                    AppColors.red.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onBack,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text(
                            '\u2190 Bosses',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⏱ $timerText',
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 40),
                    children: [
                      _buildHero(),
                      const SizedBox(height: 16),
                      _buildHpSection(),
                      const SizedBox(height: 16),
                      const BossDamageHint(),
                      const SizedBox(height: 12),
                      _buildMyDamage(),
                      const SizedBox(height: 16),
                      _buildRecentHits(ref),
                      const SizedBox(height: 16),
                      _buildCtas(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${boss.isMini ? "\u26A1 MINI BOSS" : "\u26A0\uFE0F ELITE BOSS"} \u00B7 ${boss.regionDisplay.toUpperCase()}',
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Avatar with rings
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.2), width: 2),
                  ),
                ),
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF230808),
                    border: Border.all(color: AppColors.red, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.red.withValues(alpha: 0.5),
                          blurRadius: 30),
                      BoxShadow(
                          color: AppColors.red.withValues(alpha: 0.15),
                          blurRadius: 60),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: BossIcon(
                    icon: boss.icon,
                    size: 88,
                    emojiSize: 50,
                    visualScale: 1.15,
                    visualOffset: const Offset(-0.75, -1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            boss.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Defeat by burning calories',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOSS HP',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${_fmtNumber(boss.maxHp - boss.hpDealt)} / ${_fmtNumber(boss.maxHp)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          BossHpBar(
              hpDealt: boss.hpDealt,
              maxHp: boss.maxHp,
              showLabel: false,
              height: 14),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${((boss.maxHp - boss.hpDealt) / boss.maxHp * 100).toStringAsFixed(0)}% remaining',
              style: const TextStyle(color: Color(0xFF586070), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDamage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY TOTAL DAMAGE',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'From all your workouts this battle',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          Text(
            _fmtNumber(boss.hpDealt),
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHits(WidgetRef ref) {
    final historyAsync = ref.watch(bossDamageHistoryProvider(boss.id));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'RECENT HITS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
                ),
              ),
            ),
            error: (err, _) => Column(
              children: [
                const Text(
                  'Couldn\'t load damage history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(bossDamageHistoryProvider(boss.id)),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            data: (hits) {
              if (hits.isEmpty) {
                return const Column(
                  children: [
                    Text(
                      'Damage is dealt automatically when you log workouts or sync activities from Strava.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Log a workout to deal damage!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }
              final recent = hits.take(3);
              return Column(
                children: [
                  for (final hit in recent) BossDamageHitRow(hit: hit),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCtas(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // History button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _showHistorySheet(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      '\uD83D\uDCCB History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Log Workout button
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [AppColors.green, Color(0xFF2d8f3c)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _openLogWorkout(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      '\u26A1 Log Workout',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  static String _fmtNumber(int n) {
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }

  Future<void> _openLogWorkout(BuildContext context) async {
    await Navigator.of(context).push(
      AppRoute<void>(
        builder: (_) => const LogActivityScreen(),
      ),
    );
    if (!mounted) return;
    _refreshBattleData();
  }

  void _showHistorySheet(BuildContext context) {
    _refreshBattleData();
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BossDamageHistorySheet(bossId: boss.id),
    );
  }
}

class _BossDamageHistorySheet extends ConsumerWidget {
  final String bossId;

  const _BossDamageHistorySheet({required this.bossId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bossDamageHistoryProvider(bossId));
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0d1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Text(
                    'Damage History',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        ref.invalidate(bossDamageHistoryProvider(bossId)),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: historyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.red),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Couldn\'t load damage history.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (hits) {
                  if (hits.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No workout hits yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    itemCount: hits.length,
                    itemBuilder: (_, i) => BossDamageHitRow(hit: hits[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
