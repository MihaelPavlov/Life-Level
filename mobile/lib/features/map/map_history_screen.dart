import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../home/providers/map_journey_provider.dart';
import 'models/map_models.dart';

class MapHistoryScreen extends ConsumerWidget {
  const MapHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapJourneyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Map History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: mapAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text(
                    'Failed to load map history.',
                    style: TextStyle(color: AppColors.textSecondary),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Color(0xFF1e2632),
                      height: 1,
                    ),
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
      ),
    );
  }
}

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
                    color: isCurrent ? const Color(0xFF3fb950) : AppColors.textSecondary,
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
      case 'boss': return const Color(0xFFf85149);
      case 'crossroads': return const Color(0xFFe3b341);
      case 'chest': return const Color(0xFF3fb950);
      case 'dungeon': return const Color(0xFFa371f7);
      case 'event': return const Color(0xFFf5a623);
      default: return const Color(0xFF4f9eff);
    }
  }
}
