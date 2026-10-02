import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/unlock_catalog.dart';
import '../providers/unlocks_provider.dart';
import '../tour/unlock_tour_runner.dart';
import '../widgets/unlock_badges.dart';

/// Profile → Tutorials: every feature in the unlock chain. Explored ones can
/// replay their tour; locked ones say what opens them.
class ExploredFeaturesScreen extends ConsumerWidget {
  const ExploredFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocks = ref.watch(unlocksSnapshotProvider);
    final metas = kUnlockCatalog.values.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Tutorials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: metas.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Features open as you play. Replay the short tour of anything you’ve unlocked.',
                style: TextStyle(
                    fontSize: 13, height: 1.45, color: AppColors.textSecondary),
              ),
            );
          }
          final m = metas[i - 1];
          final open = unlocks.isUnlocked(m.key);
          return _Row(
            meta: m,
            open: open,
            fresh: unlocks.isFresh(m.key),
            onTap: open
                ? () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    UnlockReplay.request(m.key);
                  }
                : () => showLockedHint(context, m.key),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final UnlockMeta meta;
  final bool open;
  final bool fresh;
  final VoidCallback onTap;

  const _Row({
    required this.meta,
    required this.open,
    required this.fresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: open ? 1 : .35,
                child: AppIconImage(meta.icon, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: open
                                ? AppColors.textPrimary
                                : AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(open ? meta.line : meta.lockedHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!open)
                const LockBadge(size: 22)
              else if (fresh)
                const NewPill()
              else
                Text('Replay',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: meta.color)),
            ],
          ),
        ),
      ),
    );
  }
}
