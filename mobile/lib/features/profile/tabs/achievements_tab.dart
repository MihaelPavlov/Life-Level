import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../achievements/models/achievement_models.dart';
import '../../achievements/providers/achievements_provider.dart';
import '../../achievements/services/achievements_service.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _kSurface = Color(0xFF161b22);
const _kBorder  = Color(0xFF21262d);
const _kTextPri = Color(0xFFe6edf3);
const _kTextSec = Color(0xFF8b949e);

const _kCategories = ['All', 'Running', 'Strength', 'Social', 'Raids'];
const _kCategoryEmojis = {
  'All':      '🏅',
  'Running':  '🏃',
  'Strength': '🏋',
  'Social':   '👥',
  'Raids':    '⚔️',
};

const _kTierOrder = ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];
const _kTierColors = {
  'Common':    Color(0xFF8b949e),
  'Uncommon':  Color(0xFF3fb950),
  'Rare':      Color(0xFF4f9eff),
  'Epic':      Color(0xFFa371f7),
  'Legendary': Color(0xFFf5a623),
};

// ── Main Tab ──────────────────────────────────────────────────────────────────
class AchievementsTab extends ConsumerStatefulWidget {
  const AchievementsTab({super.key});
  @override
  ConsumerState<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends ConsumerState<AchievementsTab> {
  String _activeCategory = 'All';
  bool _checkingUnlocks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUnlocks());
  }

  Future<void> _checkUnlocks() async {
    if (_checkingUnlocks) return;
    setState(() => _checkingUnlocks = true);
    try {
      final result = await AchievementsService().checkUnlocks();
      if (result.newlyUnlockedIds.isNotEmpty && mounted) {
        ref.read(achievementsProvider.notifier).refresh();
        ref
            .read(achievementsByCategoryProvider(_activeCategory).notifier)
            .refresh();
      }
    } catch (_) {
      // silent — don't break the tab if check fails
    } finally {
      if (mounted) setState(() => _checkingUnlocks = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(achievementsProvider.notifier).refresh(),
      ref
          .read(achievementsByCategoryProvider(_activeCategory).notifier)
          .refresh(),
    ]);
    await _checkUnlocks();
  }

  void _selectCategory(String cat) {
    if (_activeCategory == cat) return;
    setState(() => _activeCategory = cat);
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(achievementsProvider);
    final catAsync =
        ref.watch(achievementsByCategoryProvider(_activeCategory));

    return RefreshIndicator(
      color: AppColors.blue,
      backgroundColor: _kSurface,
      onRefresh: _onRefresh,
      child: catAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
        error: (e, _) => _ErrorView(onRetry: _onRefresh),
        data: (items) => _buildContent(
          allAsync.valueOrNull ?? items,
          items,
        ),
      ),
    );
  }

  Widget _buildContent(
      List<AchievementDto> all, List<AchievementDto> filtered) {
    final unlocked = filtered.where((a) => a.isUnlocked).toList()
      ..sort((a, b) => (b.unlockedAt ?? DateTime(0))
          .compareTo(a.unlockedAt ?? DateTime(0)));
    final inProgress = filtered.where((a) => a.isInProgress).toList()
      ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
    final locked = filtered
        .where((a) => !a.isUnlocked && !a.isInProgress)
        .toList()
      ..sort((a, b) {
        final ti =
            _kTierOrder.indexOf(b.tier) - _kTierOrder.indexOf(a.tier);
        return ti != 0 ? ti : a.title.compareTo(b.title);
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _OverallProgressHeader(all: all),
        const SizedBox(height: 12),
        _TierCountRow(all: all),
        const SizedBox(height: 12),
        _CategoryFilterRow(
          active: _activeCategory,
          onSelect: _selectCategory,
        ),
        const SizedBox(height: 16),
        if (unlocked.isNotEmpty) ...[
          _SectionHeader('Recently Unlocked', unlocked.length),
          ...unlocked.map((a) => _AchievementCard(a)),
          const SizedBox(height: 8),
        ],
        if (inProgress.isNotEmpty) ...[
          _SectionHeader('In Progress', inProgress.length),
          ...inProgress.map((a) => _AchievementCard(a)),
          const SizedBox(height: 8),
        ],
        if (locked.isNotEmpty) ...[
          _SectionHeader('Locked', locked.length),
          ...locked.map((a) => _AchievementCard(a)),
        ],
        if (unlocked.isEmpty && inProgress.isEmpty && locked.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No achievements in this category yet.',
                style: TextStyle(color: _kTextSec, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Overall Progress Header ───────────────────────────────────────────────────
class _OverallProgressHeader extends StatelessWidget {
  final List<AchievementDto> all;
  const _OverallProgressHeader({required this.all});

  @override
  Widget build(BuildContext context) {
    final total = all.length;
    final unlocked = all.where((a) => a.isUnlocked).length;
    final pct = total > 0 ? unlocked / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPri,
                ),
              ),
              const Spacer(),
              Text(
                '$unlocked / $total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPri,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _kBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% unlocked',
            style: const TextStyle(fontSize: 11, color: _kTextSec),
          ),
        ],
      ),
    );
  }
}

// ── Tier Count Row ────────────────────────────────────────────────────────────
class _TierCountRow extends StatelessWidget {
  final List<AchievementDto> all;
  const _TierCountRow({required this.all});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final a in all.where((a) => a.isUnlocked)) {
      counts[a.tier] = (counts[a.tier] ?? 0) + 1;
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _kTierOrder.map((tier) {
          final color = _kTierColors[tier]!;
          final count = counts[tier] ?? 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              border: Border.all(color: color.withOpacity(0.40)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tier,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Category Filter ───────────────────────────────────────────────────────────
class _CategoryFilterRow extends StatelessWidget {
  final String active;
  final ValueChanged<String> onSelect;
  const _CategoryFilterRow({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _kCategories.map((cat) {
          final isActive = cat == active;
          final emoji = _kCategoryEmojis[cat] ?? '';
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.blue.withOpacity(0.15)
                    : _kSurface,
                border: Border.all(
                  color: isActive ? AppColors.blue : _kBorder,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$emoji $cat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.blue : _kTextSec,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kTextSec,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kTextSec,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievement Card ──────────────────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final AchievementDto achievement;
  const _AchievementCard(this.achievement);

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final dimmed = !a.isUnlocked;
    final borderColor = a.tierColor.withOpacity(a.isUnlocked ? 0.7 : 0.25);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(achievement: a, dimmed: dimmed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dimmed ? _kTextSec : _kTextPri,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _XpBadge(xp: a.xpReward, unlocked: a.isUnlocked),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  a.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextSec,
                  ),
                ),
                if (a.isInProgress) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: a.progressPercent,
                      minHeight: 4,
                      backgroundColor: _kBorder,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(a.tierColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmt(a.currentValue)} / ${_fmt(a.targetValue)} ${a.targetUnit}',
                    style: TextStyle(
                      fontSize: 10,
                      color: a.tierColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (a.isUnlocked) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      const Text(
                        'Completed!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3fb950),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _IconBox extends StatelessWidget {
  final AchievementDto achievement;
  final bool dimmed;
  const _IconBox({required this.achievement, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: achievement.tierColor
                .withOpacity(dimmed ? 0.06 : 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: achievement.tierColor
                  .withOpacity(dimmed ? 0.2 : 0.45),
            ),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        if (!achievement.isUnlocked && !achievement.isInProgress)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
      ],
    );
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  final bool unlocked;
  const _XpBadge({required this.xp, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFf5a623);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: orange.withOpacity(unlocked ? 0.15 : 0.07),
        border: Border.all(
            color: orange.withOpacity(unlocked ? 0.5 : 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$xp XP',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: orange.withOpacity(unlocked ? 1.0 : 0.5),
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Failed to load achievements',
            style: TextStyle(color: _kTextSec, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                  color: AppColors.blue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
