import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../map/models/map_models.dart';
import '../home_widgets.dart';

// ── MAP PROGRESS SECTION ───────────────────────────────────────────────────────
class HomeMapProgressSection extends StatelessWidget {
  final MapFullData data;
  final VoidCallback onLogActivity;
  final VoidCallback onOpenMap;
  final VoidCallback onActionButton;
  final void Function(MapNodeModel) onCarouselNodeTap;

  const HomeMapProgressSection({
    super.key,
    required this.data,
    required this.onLogActivity,
    required this.onOpenMap,
    required this.onActionButton,
    required this.onCarouselNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3fb950),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'MAP PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: Color(0xFF8b949e),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onOpenMap,
                  child: const Text(
                    'Map →',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4f9eff),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                HomeMapFeaturedCard(
                  data: data,
                  onLogActivity: onLogActivity,
                  onOpenMap: onOpenMap,
                  onActionButton: onActionButton,
                  onCarouselNodeTap: onCarouselNodeTap,
                ),
                HomeMapEventCarousel(
                  data: data,
                  onNodeTap: onCarouselNodeTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FEATURED CARD ──────────────────────────────────────────────────────────────
class HomeMapFeaturedCard extends StatelessWidget {
  final MapFullData data;
  final VoidCallback onLogActivity;
  final VoidCallback onOpenMap;
  final VoidCallback onActionButton;
  final void Function(MapNodeModel) onCarouselNodeTap;

  const HomeMapFeaturedCard({
    super.key,
    required this.data,
    required this.onLogActivity,
    required this.onOpenMap,
    required this.onActionButton,
    required this.onCarouselNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = data.userProgress;
    final isTraveling = progress.currentEdgeId != null;
    final destNode = progress.destinationNodeId != null
        ? data.nodes.where((n) => n.id == progress.destinationNodeId).firstOrNull
        : null;
    final activeEdge = progress.currentEdgeId != null
        ? data.edges.where((e) => e.id == progress.currentEdgeId).firstOrNull
        : null;
    final double edgeProgress = (activeEdge != null && activeEdge.distanceKm > 0)
        ? (progress.distanceTraveledOnEdge / activeEdge.distanceKm).clamp(0.0, 1.0)
        : 0.0;
    final double remaining = activeEdge != null
        ? (activeEdge.distanceKm - progress.distanceTraveledOnEdge).clamp(0.0, double.infinity)
        : 0.0;
    final isArrived = !isTraveling &&
        destNode != null &&
        (destNode.userState?.isCurrentNode ?? false);

    if (destNode == null && !isTraveling) {
      return _buildNoDestinationCard();
    }

    if (isTraveling) {
      return _buildTravelingCard(destNode, activeEdge, edgeProgress, remaining, progress);
    }

    if (isArrived) {
      return _buildArrivedCard(destNode);
    }

    return _buildNoDestinationCard();
  }

  Widget _buildNoDestinationCard() {
    return GestureDetector(
      onTap: onOpenMap,
      child: HomeCard(
        child: Row(
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No destination set',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Open the Map to choose your next route',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Open Map →',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4f9eff),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTravelingCard(
    MapNodeModel? destNode,
    MapEdgeModel? activeEdge,
    double edgeProgress,
    double remaining,
    UserMapProgressModel progress,
  ) {
    return HomeCard(
      borderColor: const Color(0xFF4f9eff).withValues(alpha: 0.55),
      glowColor: const Color(0xFF4f9eff).withValues(alpha: 0.2),
      child: Stack(
        children: [
          // Watermark icon
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                destNode?.icon ?? '📍',
                style: const TextStyle(fontSize: 80),
              ).apply(opacity: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: badge + sync
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HomeBadge('🚶 TRAVELING', const Color(0xFF4f9eff)),
                  const Text(
                    '⟳ Strava',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Heading
              const Text(
                'NEXT NODE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              // Node name
              Text(
                destNode?.name ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              // Sub: type + challenge hint
              Text(
                '${_nodeIcon(destNode?.type ?? '')} ${destNode?.type ?? ''} · ${_challengeHint(destNode)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              // Progress row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Distance traveled',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${progress.distanceTraveledOnEdge.toStringAsFixed(1)} / ${activeEdge?.distanceKm.toStringAsFixed(1) ?? '?'} km',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              HomeProgressBar(
                progress: edgeProgress,
                colors: const [Color(0xFF4f9eff), Color(0xFF6ab8ff)],
                height: 7,
              ),
              const SizedBox(height: 8),
              // Activity chips
              Row(
                children: [
                  _ActivityChip(label: '🏃 Run'),
                  const SizedBox(width: 6),
                  _ActivityChip(label: '🚴 Cycle'),
                  const SizedBox(width: 6),
                  _ActivityChip(label: '👣 Steps'),
                ],
              ),
              const SizedBox(height: 10),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${remaining.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4f9eff),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'to go',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onLogActivity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4f9eff), Color(0xFF6ab8ff)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Log Activity →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedCard(MapNodeModel destNode) {
    final challengeProgress = _challengeProgress(destNode);

    return HomeCard(
      borderColor: const Color(0xFF3fb950).withValues(alpha: 0.6),
      glowColor: const Color(0xFF3fb950).withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badge + sync
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HomeBadge('✅ NODE REACHED', const Color(0xFF3fb950)),
              const Text(
                '⟳ Strava',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Heading
          const Text(
            'YOU\'VE ARRIVED AT',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          // Node name
          Text(
            destNode.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          // Challenge block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_nodeIcon(destNode.type)} ${destNode.type.toUpperCase()} CHALLENGE',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _challengeDescription(destNode),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Challenge progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Challenge progress',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                '${(challengeProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          HomeProgressBar(
            progress: challengeProgress,
            colors: const [Color(0xFF3fb950), Color(0xFF6ddd8f)],
            height: 7,
          ),
          const SizedBox(height: 10),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(challengeProgress * 100).toStringAsFixed(0)}% complete',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3fb950),
                ),
              ),
              GestureDetector(
                onTap: onActionButton,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3fb950), Color(0xFF6ddd8f)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _arrivedActionLabel(destNode),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── MAP HISTORY CARD ──────────────────────────────────────────────────────────
class HomeMapHistoryCard extends StatelessWidget {
  final MapFullData data;

  const HomeMapHistoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Current node (just arrived) — shown first in Screen 2
    final current = data.nodes
        .where((n) => n.userState?.isCurrentNode == true)
        .firstOrNull;

    // Previously completed nodes (unlocked, not current), latest first
    final completed = data.nodes
        .where((n) =>
            n.userState?.isUnlocked == true &&
            n.userState?.isCurrentNode == false)
        .toList()
        .reversed
        .take(2)
        .toList();

    final entries = <MapNodeModel>[
      if (current != null) current,
      ...completed,
    ];

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(label: 'MAP HISTORY', action: 'View all →'),
            const SizedBox(height: 4),
            ...entries.asMap().entries.map((e) {
              final isLast = e.key == entries.length - 1;
              return _HistoryEntry(
                node: e.value,
                isCurrent: e.value.userState?.isCurrentNode == true,
                showDivider: !isLast,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final MapNodeModel node;
  final bool isCurrent;
  final bool showDivider;

  const _HistoryEntry({
    required this.node,
    required this.isCurrent,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _nodeTypeColor(node.type);
    final statusText = isCurrent
        ? '✓ Just arrived! Challenge unlocked'
        : _completedStatusText(node);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: const Color(0xFF1e2632)))
            : null,
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              border: Border.all(color: typeColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(node.icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isCurrent
                        ? const Color(0xFF3fb950)
                        : AppColors.textSecondary,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // XP + type label
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (node.rewardXp > 0)
                Text(
                  '+${node.rewardXp} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFf5a623),
                  ),
                ),
              Text(
                node.type.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 0.05,
                  color: kHTextMuted,
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
}

// ── EVENT CAROUSEL ─────────────────────────────────────────────────────────────
class HomeMapEventCarousel extends StatelessWidget {
  final MapFullData data;
  final void Function(MapNodeModel) onNodeTap;

  const HomeMapEventCarousel({
    super.key,
    required this.data,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    // Upcoming locked nodes where level is met but not unlocked and not destination
    final upcoming = data.nodes
        .where((n) =>
            n.userState?.isUnlocked == false &&
            n.userState?.isLevelMet == true &&
            n.userState?.isDestination == false)
        .take(5)
        .toList();

    // Active mini-bosses
    final miniBosses = data.nodes
        .where((n) =>
            n.boss?.isMini == true &&
            (n.boss?.isActivated ?? false) &&
            !(n.boss?.isDefeated ?? false))
        .toList();

    // Merge, deduplicate by id
    final seen = <String>{};
    final items = <MapNodeModel>[];
    for (final n in [...miniBosses, ...upcoming]) {
      if (seen.add(n.id)) items.add(n);
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final node = items[index];
          final typeColor = _nodeTypeColor(node.type);

          // Attempt to find distance from edges
          double? distKm;
          final edge = data.edges
              .where((e) => e.toNodeId == node.id || e.fromNodeId == node.id)
              .firstOrNull;
          if (edge != null) distKm = edge.distanceKm;

          // Mini-boss progress
          double? bossProgress;
          if (node.boss?.isMini == true && node.boss?.isActivated == true) {
            final b = node.boss!;
            bossProgress = b.maxHp > 0
                ? (b.hpDealt / b.maxHp).clamp(0.0, 1.0)
                : 0.0;
          }

          return GestureDetector(
            onTap: () => onNodeTap(node),
            child: Container(
            width: 130,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF161b22),
              border: Border.all(color: typeColor.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                HomeBadge(_typeLabel(node), typeColor, fontSize: 8),
                const SizedBox(height: 6),
                // Node name
                Text(
                  node.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                // Distance
                Text(
                  distKm != null ? '📍 +${distKm.toStringAsFixed(1)} km' : '📍 ...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                // Challenge hint
                Expanded(
                  child: Text(
                    _challengeHint(node),
                    style: const TextStyle(
                      fontSize: 9,
                      color: kHTextMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Mini-boss progress bar
                if (bossProgress != null) ...[
                  const SizedBox(height: 4),
                  HomeProgressBar(
                    progress: bossProgress,
                    colors: const [Color(0xFFf5a623), Color(0xFFffc55c)],
                    height: 4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'In progress · ${(bossProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFFf5a623),
                    ),
                  ),
                ],
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

// ── PRIVATE HELPERS ────────────────────────────────────────────────────────────

String _nodeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'boss':
      return '🗡️';
    case 'crossroads':
      return '⑂';
    case 'chest':
      return '💰';
    case 'dungeon':
      return '⛏️';
    case 'event':
      return '⚡';
    default:
      return '📍';
  }
}

String _arrivedActionLabel(MapNodeModel node) {
  if (node.dungeonPortal != null) return 'Enter Challenge →';
  if (node.boss != null) return 'Fight Boss →';
  if (node.chest != null) return 'Open Chest →';
  if (node.crossroads != null) return 'Choose Path →';
  return 'Log Activity →';
}

String _challengeHint(MapNodeModel? node) {
  if (node == null) return '';
  if (node.dungeonPortal != null) return 'Complete dungeon floors';
  if (node.boss != null) return 'Defeat the boss';
  if (node.chest != null) return 'Log any workout to open';
  if (node.crossroads != null) return 'Arrive & choose path';
  return 'Reach this node';
}

String _challengeDescription(MapNodeModel? node) {
  if (node?.dungeonPortal != null) {
    final d = node!.dungeonPortal!;
    if (d.floors.isNotEmpty) {
      final floor = d.floors
          .where((f) => f.floorNumber == d.currentFloor)
          .firstOrNull ?? d.floors.first;
      return 'Complete ${floor.requiredMinutes} min ${floor.requiredActivity} to clear floor ${d.currentFloor}';
    }
    return 'Complete all dungeon floors';
  }
  if (node?.boss != null) return 'Deal damage to defeat ${node!.boss!.name}';
  if (node?.chest != null) return 'Log any workout to open the chest';
  if (node?.crossroads != null) return 'Choose your path at this crossroads';
  return 'You have arrived! Log an activity to continue.';
}

double _challengeProgress(MapNodeModel? node) {
  if (node?.dungeonPortal != null) {
    final d = node!.dungeonPortal!;
    return d.totalFloors > 0 ? (d.currentFloor - 1) / d.totalFloors : 0.0;
  }
  if (node?.boss != null) {
    final b = node!.boss!;
    return b.maxHp > 0 ? (b.hpDealt / b.maxHp).clamp(0.0, 1.0) : 0.0;
  }
  return 0.0;
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

String _typeLabel(MapNodeModel node) {
  if (node.boss?.isMini == true) return 'MINI-BOSS';
  switch (node.type.toLowerCase()) {
    case 'boss':
      return 'BOSS NODE';
    case 'crossroads':
      return 'CROSSROADS';
    case 'chest':
      return 'CHEST NODE';
    case 'dungeon':
      return 'DUNGEON';
    case 'event':
      return 'WORLD EVENT';
    default:
      return node.type.toUpperCase();
  }
}

// ── HELPER EXTENSION ───────────────────────────────────────────────────────────
extension _OpacityText on Widget {
  Widget apply({required double opacity}) {
    return Opacity(opacity: opacity, child: this);
  }
}

// ── ACTIVITY CHIP ──────────────────────────────────────────────────────────────
class _ActivityChip extends StatelessWidget {
  final String label;

  const _ActivityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4f9eff).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFF4f9eff).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4f9eff),
        ),
      ),
    );
  }
}
