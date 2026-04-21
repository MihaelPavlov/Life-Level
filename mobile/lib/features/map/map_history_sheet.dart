import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../home/providers/map_journey_provider.dart';
import 'models/map_models.dart';

// ── MapHistorySheet ───────────────────────────────────────────────────────────
// Bottom sheet variant of MapHistoryScreen. Visually matches XpHistorySheet
// (drag handle, 0xFF0f1828 surface, rounded top corners, icon+title header,
// divider-separated list, empty state).
class MapHistorySheet extends ConsumerWidget {
  const MapHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapJourneyProvider);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: const Color(0xFF0f1828),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.orange.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2a3a5a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Text('🗺️', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Nodes visited on this journey',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF30363d), height: 1),

          // body
          Expanded(
            child: mapAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load map history',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => ref.invalidate(mapJourneyProvider),
                      child: const Text('Retry', style: TextStyle(color: AppColors.orange)),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final current = data.nodes
                    .where((n) => n.userState?.isCurrentNode == true)
                    .firstOrNull;

                final completed = data.nodes
                    .where((n) =>
                        n.userState?.isUnlocked == true &&
                        n.userState?.isCurrentNode == false)
                    .toList()
                    .reversed
                    .toList();

                final entries = <MapNodeModel>[
                  if (current != null) current,
                  ...completed,
                ];

                if (entries.isEmpty) {
                  return const Center(
                    child: Text(
                      'No nodes visited yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFF30363d), height: 1),
                  itemBuilder: (context, index) {
                    final node = entries[index];
                    final isCurrent = node.userState?.isCurrentNode == true;
                    return _HistoryEntry(node: node, isCurrent: isCurrent);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── _HistoryEntry ─────────────────────────────────────────────────────────────
// Copied from map_history_screen.dart so the orphaned screen can stay intact.
class _HistoryEntry extends StatelessWidget {
  final MapNodeModel node;
  final bool isCurrent;

  const _HistoryEntry({required this.node, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final typeColor = _nodeTypeColor(node.type);
    final statusText = isCurrent
        ? '✓ Just arrived! Challenge unlocked'
        : _completedStatusText(node);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              border: Border.all(color: typeColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(node.icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrent
                        ? const Color(0xFF3fb950)
                        : AppColors.textSecondary,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (node.rewardXp > 0)
                Text(
                  '+${node.rewardXp} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFf5a623),
                  ),
                ),
              Text(
                node.type.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _completedStatusText(MapNodeModel node) {
    if (node.dungeonPortal != null) return 'Cleared';
    if (node.chest != null) return 'Opened';
    if (node.boss != null) return 'Defeated';
    if (node.crossroads != null) return 'Path chosen';
    return 'Completed';
  }

  Color _nodeTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'boss':
        return const Color(0xFFf85149);
      case 'crossroads':
        return const Color(0xFFe3b341);
      case 'chest':
        return const Color(0xFF3fb950);
      case 'dungeon':
        return const Color(0xFFa371f7);
      case 'event':
        return const Color(0xFFf5a623);
      default:
        return const Color(0xFF4f9eff);
    }
  }
}
