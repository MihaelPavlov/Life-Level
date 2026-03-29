import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/level_up_notifier.dart';
import 'boss_service.dart';
import 'map_colors.dart';
import 'map_painter.dart';
import 'map_debug_panel.dart';
import 'map_service.dart';
import 'map_banners.dart';
import 'models/map_models.dart';
import 'node_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MapScreen
// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final _service = MapService();
  final _bossService = BossService();

  MapFullData? _data;
  bool _loading = true;
  String? _error;

  late final AnimationController _pulseCtrl;
  late final AnimationController _destCtrl;
  late final TransformationController _transformCtrl;
  late final StreamSubscription<int> _levelUpSub;

  bool _hasInitializedViewport = false;

  @override
  void initState() {
    super.initState();
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
    _loadMap();
  }

  @override
  void dispose() {
    _levelUpSub.cancel();
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
    try {
      final data = await _service.getFullMap();
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: child);
      },
      pageBuilder: (ctx, _, __) => NodeArrivalBanner(node: node),
    );
  }

  void _showLevelUpDialog(int newLevel) {
    LevelUpNotifier.notify(newLevel);
  }

  void _showNodeDiscoveredBanner(MapNodeModel node) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: child);
      },
      pageBuilder: (ctx, _, __) => NodeDiscoveredBanner(node: node),
    );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          _buildBody(),
          if (_data != null) _buildHud(),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Could not load the map',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                onPressed: _loadMap,
                child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
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
              Text(region,
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
