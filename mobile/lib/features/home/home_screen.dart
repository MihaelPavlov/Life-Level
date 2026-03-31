import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/providers/character_provider.dart';
import '../map/models/map_models.dart';
import '../activity/log_activity_screen.dart';
import '../map/map_screen.dart';
import '../map/node_detail_sheet.dart';
import '../../core/api/api_client.dart';
import '../../core/services/level_up_notifier.dart';
import 'home_cards.dart';
import 'home_widgets.dart';
import 'providers/map_journey_provider.dart';
import 'widgets/home_map_progress_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final mapJourneyAsync = ref.watch(mapJourneyProvider);
    final nodeReached = mapJourneyAsync.valueOrNull != null
        ? _isNodeReached(mapJourneyAsync.valueOrNull!)
        : false;

    return Stack(
      children: [
        Container(
          color: kHBgBase,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(profile: profile, nodeReached: nodeReached),
                mapJourneyAsync.when(
                  data: (data) => HomeMapProgressSection(
                    data: data,
                    onLogActivity: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LogActivityScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                      ref.invalidate(mapJourneyProvider);
                    },
                    onOpenMap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    ),
                    onActionButton: () {
                      final destId = data.userProgress.destinationNodeId;
                      if (destId == null) return;
                      final node =
                          data.nodes.where((n) => n.id == destId).firstOrNull;
                      if (node == null) return;
                      _openNodeDetailSheet(
                        context, ref, node, data,
                        isAdjacent: true,
                        distanceKm: _distanceToNode(data, destId),
                      );
                    },
                    onStravaSync: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing Strava...')),
                      );
                      int imported = 0;
                      int skipped = 0;
                      try {
                        final res = await ApiClient.instance.post('/integrations/strava/sync');
                        final body = res.data as Map<String, dynamic>? ?? {};
                        imported = (body['imported'] as int?) ?? 0;
                        skipped = (body['skipped'] as int?) ?? 0;
                      } catch (_) {}
                      ref.invalidate(mapJourneyProvider);
                      ref.invalidate(characterProfileProvider);
                      if (context.mounted) {
                        final msg = imported > 0
                            ? 'Synced $imported new activit${imported == 1 ? 'y' : 'ies'}!'
                            : skipped > 0
                                ? 'Already up to date ($skipped synced)'
                                : 'No new activities found';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    },
                    onCarouselNodeTap: (node) => _openNodeDetailSheet(
                      context, ref, node, data,
                      isAdjacent: _isAdjacentNode(data, node.id),
                      distanceKm: _distanceToNode(data, node.id),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mapJourneyAsync.valueOrNull != null)
                        HomeMapHistoryCard(data: mapJourneyAsync.valueOrNull!),
                      HomeXpCard(profile: profile),
                      const HomeStreakCard(),
                      const HomeQuestsCard(),
                      const HomeLastActivityCard(),
                      const HomeStatsRow(),
                      const HomeBossCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isNodeReached(MapFullData data) {
    final p = data.userProgress;
    if (p.currentEdgeId != null) return false; // still traveling
    if (p.destinationNodeId == null) return false;
    final dest = data.nodes
        .where((n) => n.id == p.destinationNodeId)
        .firstOrNull;
    return dest?.userState?.isCurrentNode ?? false;
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

bool _isAdjacentNode(MapFullData data, String nodeId) {
  final cur = data.userProgress.currentNodeId;
  return data.edges.any((e) =>
      (e.fromNodeId == cur && e.toNodeId == nodeId) ||
      (e.isBidirectional && e.toNodeId == cur && e.fromNodeId == nodeId));
}

double? _distanceToNode(MapFullData data, String nodeId) {
  final cur = data.userProgress.currentNodeId;
  return data.edges
      .where((e) =>
          (e.fromNodeId == cur && e.toNodeId == nodeId) ||
          (e.isBidirectional && e.toNodeId == cur && e.fromNodeId == nodeId))
      .firstOrNull
      ?.distanceKm;
}

Future<void> _openNodeDetailSheet(
  BuildContext context,
  WidgetRef ref,
  MapNodeModel node,
  MapFullData data, {
  bool isAdjacent = false,
  double? distanceKm,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => NodeDetailSheet(
      node: node,
      isAdjacent: isAdjacent,
      distanceKm: distanceKm,
      userProgress: data.userProgress,
      onDestinationSet: () => ref.invalidate(mapJourneyProvider),
      onRefresh: () => ref.invalidate(mapJourneyProvider),
      onLevelUp: (lvl) => LevelUpNotifier.notify(lvl),
    ),
  );
  ref.invalidate(mapJourneyProvider);
}
