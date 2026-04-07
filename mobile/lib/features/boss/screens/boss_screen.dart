import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../models/boss_list_item.dart';
import '../providers/boss_provider.dart';
import '../widgets/boss_active_card.dart';
import '../widgets/boss_defeated_card.dart';
import '../widgets/boss_expired_card.dart';
import 'boss_battle_screen.dart';

class BossScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const BossScreen({super.key, this.onClose});

  @override
  ConsumerState<BossScreen> createState() => BossScreenState();
}

class BossScreenState extends ConsumerState<BossScreen> {
  BossListItem? _selectedBoss;

  void refresh() => ref.read(bossListProvider.notifier).refresh();

  void _openBattle(BossListItem boss) => setState(() => _selectedBoss = boss);
  void _closeBattle() {
    setState(() => _selectedBoss = null);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBoss != null) {
      return BossBattleView(
        boss: _selectedBoss!,
        onBack: _closeBattle,
      );
    }

    final bossAsync = ref.watch(bossListProvider);

    return Material(
      color: AppColors.backgroundAlt,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    '\u2694\uFE0F Bosses',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  bossAsync.whenOrNull(
                        data: (bosses) {
                          final activeCount =
                              bosses.where((b) => b.isActive).length;
                          if (activeCount == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: AppColors.red.withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$activeCount Active',
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ) ??
                      const SizedBox.shrink(),
                  const Spacer(),
                  IconButton(
                    onPressed: refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Body ──
            Expanded(
              child: bossAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.red),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Failed to load bosses',
                        style: TextStyle(color: AppColors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (bosses) => _buildList(bosses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToMap() {
    widget.onClose?.call();
    NavTabNotifier.switchTo('map');
  }

  Widget _buildList(List<BossListItem> bosses) {
    final active = bosses.where((b) => b.isActive).toList();
    final defeated = bosses.where((b) => b.isDefeated).toList();
    final expired = bosses.where((b) => b.isExpired && !b.isDefeated).toList();

    // Only regular (non-mini) bosses count for "zone reachable" — mini-bosses are fightable from anywhere
    final hasZoneBoss = bosses.any((b) => !b.isMini && b.canFight && !b.isDefeated && !b.isExpired);
    final hasHistory = expired.isNotEmpty || defeated.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(bossListProvider.notifier).refresh(),
      color: AppColors.red,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── No reachable bosses → zone banner ──
          if (!hasZoneBoss)
            _buildNoActiveBanner(hasHistory),

          if (active.isNotEmpty) ...[
            _sectionLabel('ACTIVE'),
            for (final boss in active)
              BossActiveCard(
                boss: boss,
                onEnterBattle: boss.canFight ? () => _openBattle(boss) : null,
              ),
          ],
          if (expired.isNotEmpty) ...[
            _sectionLabel('EXPIRED'),
            for (final boss in expired) BossExpiredCard(boss: boss),
          ],
          if (defeated.isNotEmpty) ...[
            _sectionLabel('DEFEATED'),
            for (final boss in defeated) BossDefeatedCard(boss: boss),
          ],
        ],
      ),
    );
  }

  Widget _buildNoActiveBanner(bool hasHistory) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 4, 20, hasHistory ? 8 : 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('\uD83D\uDC09', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 12),
          const Text(
            'No active bosses in your zone',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Travel through the map to reach boss nodes and unlock new encounters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.blue, Color(0xFF3578cc)],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _goToMap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '\uD83D\uDDFA\uFE0F  Open Map',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
