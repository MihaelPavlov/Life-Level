import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../../unlocks/models/unlock_catalog.dart';
import '../../unlocks/models/unlock_models.dart';
import '../../unlocks/providers/unlocks_provider.dart';

/// XP at the start of [level]. Mirrors the server's `XpAtLevelStart`
/// (L(L−1)/2 × 300) so the card can count down to a level further away.
int xpAtLevelStart(int level) => level * (level - 1) ~/ 2 * 300;

/// What opens next, under the Adventure Hub: the next level's features
/// (still grey) and either the XP still to go or the action they wait for.
/// Hidden once every feature is open.
class HomeNextUnlockCard extends ConsumerWidget {
  const HomeNextUnlockCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocks = ref.watch(unlocksSnapshotProvider);
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    if (unlocks.isFallback || profile == null) return const SizedBox.shrink();
    final next = nextUnlockTier(unlocks);
    if (next == null) return const SizedBox.shrink();

    final level = profile.level, xp = profile.xp;
    final ready = next.any(
      (m) => m.requiredLevel == null || m.requiredLevel! <= level,
    );
    final names = next.map((m) => m.name).join(' & ');
    final String eyebrow, sub;
    double? progress;
    if (ready) {
      eyebrow = next.first.tier == 1 ? 'YOUR FIRST UNLOCK' : 'NEXT UNLOCK';
      final needs = {
        for (final m in next) _remainingNeed(m, level),
      };
      sub = needs.join(' · ');
    } else {
      final targetLevel = next
          .map((m) => m.requiredLevel)
          .whereType<int>()
          .reduce((a, b) => a < b ? a : b);
      final target = xpAtLevelStart(targetLevel);
      final from = xpAtLevelStart(level);
      eyebrow = 'NEXT UNLOCK · LEVEL $targetLevel';
      sub = '${_fmt(target - xp)} XP to go';
      progress = ((xp - from) / (target - from)).clamp(.04, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3340)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38 + (next.length - 1) * 30,
              height: 38,
              child: Stack(
                children: [
                  for (var i = 0; i < next.length; i++)
                    Positioned(
                        left: i * 30.0, child: _LockedIcon(next[i].icon)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow,
                      style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: AppColors.orange)),
                  const SizedBox(height: 2),
                  Text(names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  if (progress != null) ...[
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String _remainingNeed(UnlockMeta meta, int currentLevel) {
    final requiredLevel = meta.requiredLevel;
    if (requiredLevel != null && currentLevel < requiredLevel) {
      if (meta.need.startsWith('Reach Level')) return meta.need;
      return 'Reach Level $requiredLevel and ${meta.need[0].toLowerCase()}${meta.need.substring(1)}';
    }
    if (meta.need.startsWith('Reach Level') ||
        meta.key == UnlockKeys.achievements) {
      return 'Opens after your next workout';
    }
    return meta.need;
  }
}

/// The lowest level that still has a locked feature, and those features.
List<UnlockMeta>? nextUnlockTier(UnlocksSnapshot unlocks) {
  final locked = [
    for (final m in kUnlockCatalog.values)
      if (!unlocks.isUnlocked(m.key)) m,
  ]..sort((a, b) => a.tier.compareTo(b.tier));
  if (locked.isEmpty) return null;
  return [
    for (final m in locked)
      if (m.tier == locked.first.tier) m,
  ];
}

class _LockedIcon extends StatelessWidget {
  final String icon;
  const _LockedIcon(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1017),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0, 0, 0, 0, 89, //
            0, 0, 0, 0, 89,
            0, 0, 0, 0, 89,
            0, 0, 0, .6, 0,
          ]),
          child: AppIconImage(icon, size: 24),
        ),
      );
}
