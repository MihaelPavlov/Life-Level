import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/level_up_notifier.dart';
import '../../core/services/map_tab_notifier.dart';
import '../../core/services/world_map_notifier.dart';
import '../../core/widgets/api_error_state.dart';
import '../home/providers/map_journey_provider.dart';
import 'services/boss_service.dart';
import 'services/world_zone_service.dart';
import 'map_colors.dart';
import 'map_history_sheet.dart';
import 'map_painter.dart';
import 'map_debug_panel.dart';
import 'services/map_service.dart';
import 'map_banners.dart';
import 'models/map_models.dart';
import 'models/world_zone_models.dart';
import 'node_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MapScreen
// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.worldZoneId, this.zoneName});
  final String? worldZoneId;
  final String? zoneName;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final _service = MapService();
  final _bossService = BossService();
  final _worldZoneService = WorldZoneService();

  MapFullData? _data;
  bool _loading = true;
  String? _error;

  late String? _worldZoneId;
  late String? _zoneName;

  late final AnimationController _pulseCtrl;
  late final AnimationController _destCtrl;
  late final TransformationController _transformCtrl;
  late final StreamSubscription<LevelUpEvent> _levelUpSub;
  late final StreamSubscription<void> _mapTabSub;

  bool _hasInitializedViewport = false;

  @override
  void initState() {
    super.initState();
    _worldZoneId = widget.worldZoneId;
    _zoneName = widget.zoneName;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _destCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _transformCtrl = TransformationController();
    // Re-fetch map when the character levels up so node lock states update.
    _levelUpSub = LevelUpNotifier.stream.listen((_) => _loadMap());
    // Re-fetch from scratch when the Map tab is re-selected so that crossroads
    // or any zone change is always reflected.
    _mapTabSub = MapTabNotifier.stream.listen((_) {
      _worldZoneId = null;
      _zoneName = null;
      _hasInitializedViewport = false;
      _loadMap();
    });
    _loadMap();
  }

  @override
  void dispose() {
    _levelUpSub.cancel();
    _mapTabSub.cancel();
    _pulseCtrl.dispose();
    _destCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMap() async {
    final previousNodeId = _data?.userProgress.currentNodeId;
    final previouslyUnlocked = _data?.nodes
        .where((n) => n.userState?.isUnlocked ?? false)
        .map((n) => n.id)
        .toSet() ?? {};
    setState(() { _loading = true; _error = null; });

    if (_worldZoneId == null) {
      try {
        final world = await _worldZoneService.getFullWorld();
        // Prefer the destination zone when traveling — currentZoneId may be a
        // crossroads (no local map nodes) even though the user has already
        // selected their next zone.
        final zoneId = world.userProgress.destinationZoneId?.isNotEmpty == true
            ? world.userProgress.destinationZoneId!
            : world.userProgress.currentZoneId;
        if (zoneId.isEmpty) {
          setState(() { _loading = false; _data = null; });
          return;
        }
        final matchedZone = world.zones.cast<WorldZoneModel?>().firstWhere(
          (z) => z!.id == zoneId,
          orElse: () => null,
        );
        _worldZoneId = zoneId;
        _zoneName = matchedZone?.name;
      } catch (e) {
        setState(() { _loading = false; _data = null; });
        return;
      }
    }

    try {
      final data = await _service.getFullMap(worldZoneId: _worldZoneId);
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });

      // First load: center viewport on active node
      if (!_hasInitializedViewport) {
        _hasInitializedViewport = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnActiveNode());
      }

      // Node change feedback
      final newNodeId = data.userProgress.currentNodeId;
      if (previousNodeId != null && previousNodeId != newNodeId) {
        try {
          final newNode = data.nodes.firstWhere((n) => n.id == newNodeId);
          if (mounted) {
            if (previouslyUnlocked.contains(newNodeId)) {
              _showNodeArrivalBanner(newNode);
            } else {
              _showNodeDiscoveredBanner(newNode);
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _centerOnActiveNode() {
    final node = _currentNode;
    if (!mounted || node == null) return;
    final size = MediaQuery.of(context).size;
    const scale = 1.1;
    final tx = size.width / 2 - node.positionX * scale;
    final ty = size.height / 2 - node.positionY * scale;
    _transformCtrl.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  void _showNodeArrivalBanner(MapNodeModel node) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => NodeArrivalBanner(node: node, onDismiss: () => entry.remove()),
    );
    Overlay.of(context).insert(entry);
  }

  void _showLevelUpDialog(int newLevel) {
    LevelUpNotifier.notify(newLevel);
  }

  void _showNodeDiscoveredBanner(MapNodeModel node) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => NodeDiscoveredBanner(node: node, onDismiss: () => entry.remove()),
    );
    Overlay.of(context).insert(entry);
  }

  MapNodeModel? get _currentNode {
    final d = _data;
    if (d == null) return null;
    try {
      return d.nodes.firstWhere((n) => n.id == d.userProgress.currentNodeId);
    } catch (_) { return null; }
  }

  bool _isAdjacent(MapNodeModel node) {
    final d = _data;
    if (d == null) return false;
    final cur = d.userProgress.currentNodeId;
    return d.edges.any((e) =>
      (e.fromNodeId == cur && e.toNodeId == node.id) ||
      (e.isBidirectional && e.toNodeId == cur && e.fromNodeId == node.id));
  }

  double? _distanceToNode(MapNodeModel node) {
    final d = _data;
    if (d == null) return null;
    final cur = d.userProgress.currentNodeId;
    try {
      return d.edges.firstWhere((e) =>
        (e.fromNodeId == cur && e.toNodeId == node.id) ||
        (e.isBidirectional && e.toNodeId == cur && e.fromNodeId == node.id))
        .distanceKm;
    } catch (_) { return null; }
  }

  bool get _isAtLastNode {
    final data = _data;
    if (data == null || data.nodes.isEmpty) return false;

    final currentId = data.userProgress.currentNodeId;
    final currentNode = data.nodes.cast<MapNodeModel?>().firstWhere(
      (n) => n!.id == currentId,
      orElse: () => null,
    );

    if (currentNode == null) return false;
    if (currentNode.isStartNode) return false;
    if (!(currentNode.userState?.isUnlocked ?? false)) return false;

    final adjacentIds = data.edges
      .where((e) =>
        e.fromNodeId == currentId ||
        (e.isBidirectional && e.toNodeId == currentId))
      .map((e) => e.fromNodeId == currentId ? e.toNodeId : e.fromNodeId)
      .toSet();

    if (adjacentIds.isEmpty) return false;

    final unlockedIds = data.nodes
      .where((n) => n.userState?.isUnlocked ?? false)
      .map((n) => n.id)
      .toSet();

    return adjacentIds.every((id) => unlockedIds.contains(id));
  }

  Future<void> _completeZone() async {
    final zoneId = _worldZoneId;
    if (zoneId == null) return;

    setState(() { _loading = true; });
    try {
      final result = await _worldZoneService.completeZone(zoneId);
      if (!mounted) return;

      final xp = result['xpAwarded'] as int? ?? 0;
      final zoneName = result['zoneName'] as String? ?? _zoneName ?? 'Zone';
      final zoneIcon = result['zoneIcon'] as String? ?? '✅';
      final alreadyDone = result['alreadyCompleted'] as bool? ?? false;

      setState(() { _loading = false; });

      if (!alreadyDone && xp > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(zoneIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$zoneName complete! +$xp XP',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1a3d1f),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Open world map to show new position
      _openWorldMap();
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _onNodeTapped(MapNodeModel node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NodeDetailSheet(
        node: node,
        isAdjacent: _isAdjacent(node),
        distanceKm: _distanceToNode(node),
        userProgress: _data!.userProgress,
        onDestinationSet: _loadMap,
        onRefresh: _loadMap,
        onLevelUp: _showLevelUpDialog,
      ),
    );
  }

  void _openWorldMap() {
    WorldMapNotifier.open(onZoneSelected: (picked) {
      if (!mounted) return;
      setState(() {
        _worldZoneId = picked.zoneId;
        _zoneName = picked.zoneName;
        _hasInitializedViewport = false;
      });
      _loadMap();
    });
  }

  void _openDebugPanel() {
    final data = _data;
    if (data == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MapDebugPanel(
        nodes: data.nodes,
        userProgress: data.userProgress,
        service: _service,
        bossService: _bossService,
        onRefresh: _loadMap,
      ),
    );
  }

  void _openHistorySheet() {
    // Ensure the sheet sees the freshest journey data on open.
    ref.invalidate(mapJourneyProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: MapHistorySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          _buildBody(),
          if (_data != null) _buildHud(),
          if (_data != null)
            Positioned(
              top: 48,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'map_history_btn',
                backgroundColor: AppColors.orange.withOpacity(0.85),
                onPressed: _openHistorySheet,
                child: const Icon(Icons.history, size: 20, color: Colors.white),
              ),
            ),
          if (_isAtLastNode && _worldZoneId != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a3d1f),
                    foregroundColor: AppColors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.green.withOpacity(0.6), width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _completeZone,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Complete ${_zoneName ?? "Zone"}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      const Text('✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'world_map_btn',
              backgroundColor: AppColors.blue.withOpacity(0.85),
              onPressed: _openWorldMap,
              child: const Text('🌍', style: TextStyle(fontSize: 18)),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'map_debug',
              backgroundColor: AppColors.purple.withOpacity(0.85),
              onPressed: _openDebugPanel,
              child: const Text('🛠️', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue));
    }
    if (_error != null) {
      return ApiErrorState(
        title: 'Could not load the map',
        message: _error!,
        onRetry: _loadMap,
      );
    }

    if (_data != null && _data!.nodes.isEmpty)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_zoneName != null ? '🔀' : '🌍',
                style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 20),
              Text(
                _zoneName ?? 'Choose Your Path',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'This is a crossroads zone.\nOpen the World Map to choose your next destination.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                icon: const Text('🌍', style: TextStyle(fontSize: 18)),
                label: const Text('Open World Map',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: _openWorldMap,
              ),
            ],
          ),
        ),
      );

    if (_data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌍', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              const Text('Your Journey Begins',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Explore the World Map to choose a zone,\nthen complete activities to progress through it.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: const Text('🌍', style: TextStyle(fontSize: 18)),
                label: const Text('Open World Map',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: _openWorldMap,
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;

    return InteractiveViewer(
      transformationController: _transformCtrl,
      constrained: false,
      minScale: 0.4,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(100),
      child: SizedBox(
        width: 1000,
        height: 1000,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _destCtrl]),
          builder: (_, __) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(1000, 1000),
                  painter: MapPainter(
                    nodes: data.nodes,
                    edges: data.edges,
                    userProgress: data.userProgress,
                    pulseValue: _pulseCtrl.value,
                    destValue: _destCtrl.value,
                  ),
                ),
                for (final node in data.nodes)
                  if (!node.isHidden || (node.userState?.isUnlocked ?? false))
                    Positioned(
                      left: node.positionX - 24,
                      top: node.positionY - 24,
                      child: GestureDetector(
                        onTap: () => _onNodeTapped(node),
                        child: Container(width: 48, height: 48, color: Colors.transparent),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHud() {
    final node = _currentNode;
    final region = node?.region ?? 'Unknown Region';
    final isTraveling = _data!.userProgress.destinationNodeId != null;
    return Positioned(
      top: 48, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kMapBorder, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(_zoneName ?? region,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isTraveling ? AppColors.orange : AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isTraveling ? 'Traveling' : 'Exploring',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
