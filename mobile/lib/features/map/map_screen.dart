import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/level_up_notifier.dart';
import 'boss_service.dart';
import 'chest_service.dart';
import 'dungeon_service.dart';
import 'crossroads_service.dart';
import 'map_service.dart';
import 'models/map_models.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _kSurface2 = Color(0xFF1e2632);
const _kBorder   = Color(0xFF30363d);
const _kGold     = Color(0xFFf5dc3c);

Color _nodeColor(String type) {
  switch (type) {
    case 'Boss':       return AppColors.red;
    case 'Crossroads': return AppColors.orange;
    case 'Dungeon':    return AppColors.purple;
    case 'Chest':      return _kGold;
    case 'Event':      return AppColors.green;
    default:           return AppColors.blue;
  }
}

Color _rarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'uncommon':  return AppColors.green;
    case 'rare':      return AppColors.blue;
    case 'epic':      return AppColors.purple;
    case 'legendary': return AppColors.orange;
    default:          return AppColors.textSecondary;
  }
}

Color _difficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':  return AppColors.green;
    case 'hard':  return AppColors.red;
    default:      return AppColors.orange;
  }
}

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
    _loadMap();
  }

  @override
  void dispose() {
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
      pageBuilder: (ctx, _, __) => _NodeArrivalBanner(node: node),
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
      pageBuilder: (ctx, _, __) => _NodeDiscoveredBanner(node: node),
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
      builder: (_) => _NodeDetailSheet(
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
      builder: (_) => _DebugPanel(
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
                  painter: _MapPainter(
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
            border: Border.all(color: _kBorder, width: 1),
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

// ─────────────────────────────────────────────────────────────────────────────
// _MapPainter
// ─────────────────────────────────────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  final List<MapNodeModel> nodes;
  final List<MapEdgeModel> edges;
  final UserMapProgressModel userProgress;
  final double pulseValue;
  final double destValue;

  const _MapPainter({
    required this.nodes,
    required this.edges,
    required this.userProgress,
    required this.pulseValue,
    required this.destValue,
  });

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.pulseValue != pulseValue || old.destValue != destValue ||
      old.nodes != nodes || old.edges != edges || old.userProgress != userProgress;

  MapNodeModel? _nodeById(String id) {
    try { return nodes.firstWhere((n) => n.id == id); } catch (_) { return null; }
  }

  bool _isUnlocked(MapNodeModel node) =>
      node.isStartNode || (node.userState?.isUnlocked ?? false);

  @override
  void paint(Canvas canvas, Size size) {
    _drawTerrain(canvas, size);
    _drawEdges(canvas);
    _drawNodes(canvas);
    _drawPlayerDot(canvas);
  }

  // ── terrain background ────────────────────────────────────────────────────
  void _drawTerrain(Canvas canvas, Size size) {
    // Base dark gradient from bottom to top (warmer at bottom = starting zone)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFF060c10),
          Color(0xFF040810),
          Color(0xFF050810),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines for RPG parchment feel
    final gridPaint = Paint()
      ..color = const Color(0xFF4f9eff).withOpacity(0.025)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Terrain region blobs — soft glowing areas per zone
    _drawTerrainBlob(canvas,
      center: const Offset(500, 820),
      radiusX: 240, radiusY: 120,
      color: const Color(0xFF1a2a1a), // Ashfield — warm dark green
      blur: 70,
    );
    _drawTerrainBlob(canvas,
      center: const Offset(470, 580),
      radiusX: 200, radiusY: 200,
      color: const Color(0xFF0d1f0e), // Forest of Endurance — deep green
      blur: 80,
    );
    _drawTerrainBlob(canvas,
      center: const Offset(340, 490),
      radiusX: 130, radiusY: 110,
      color: const Color(0xFF0a1a0b),
      blur: 60,
    );
    _drawTerrainBlob(canvas,
      center: const Offset(460, 220),
      radiusX: 200, radiusY: 180,
      color: const Color(0xFF130f1e), // Mountains of Strength — deep purple
      blur: 80,
    );
    _drawTerrainBlob(canvas,
      center: const Offset(720, 490),
      radiusX: 150, radiusY: 130,
      color: const Color(0xFF080f1e), // Ocean of Balance — deep blue
      blur: 70,
    );
    _drawTerrainBlob(canvas,
      center: const Offset(640, 700),
      radiusX: 130, radiusY: 100,
      color: const Color(0xFF0b160e), // Swamps — murky green
      blur: 60,
    );

    // Vignette edges — darken corners for depth
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  void _drawTerrainBlob(
    Canvas canvas, {
    required Offset center,
    required double radiusX,
    required double radiusY,
    required Color color,
    required double blur,
  }) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
      paint,
    );
  }

  // ── dashed line ────────────────────────────────────────────────────────────
  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint,
      {double dashLength = 6, double gapLength = 4}) {
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    double traveled = 0;
    bool drawing = true;
    while (traveled < total) {
      final segLen = drawing ? dashLength : gapLength;
      final end = math.min(traveled + segLen, total);
      if (drawing) {
        canvas.drawLine(from + dir * traveled, from + dir * end, paint);
      }
      traveled = end;
      drawing = !drawing;
    }
  }

  // ── edges ─────────────────────────────────────────────────────────────────
  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      final fromNode = _nodeById(edge.fromNodeId);
      final toNode   = _nodeById(edge.toNodeId);
      if (fromNode == null || toNode == null) continue;

      final fromUnlocked = _isUnlocked(fromNode);
      final toUnlocked   = _isUnlocked(toNode);
      if (!fromUnlocked && !toUnlocked) continue;

      final from = Offset(fromNode.positionX, fromNode.positionY);
      final to   = Offset(toNode.positionX,   toNode.positionY);

      final isCurrentEdge =
          userProgress.currentEdgeId != null && userProgress.currentEdgeId == edge.id;
      final isDestinationEdge =
          userProgress.destinationNodeId != null &&
          (toNode.id == userProgress.destinationNodeId ||
           fromNode.id == userProgress.destinationNodeId);

      if (isCurrentEdge) {
        _drawDashedLine(canvas, from, to,
          Paint()..color = AppColors.orange.withOpacity(0.6)..strokeWidth = 2.5..style = PaintingStyle.stroke);
        if (edge.distanceKm > 0) {
          final t = (userProgress.distanceTraveledOnEdge / edge.distanceKm).clamp(0.0, 1.0);
          // Respect travel direction — currentNodeId is the origin
          final goingForward = userProgress.currentNodeId == edge.fromNodeId;
          final progressStart = goingForward ? from : to;
          final progressEnd   = goingForward ? to   : from;
          canvas.drawLine(progressStart, Offset.lerp(progressStart, progressEnd, t)!,
            Paint()..color = AppColors.green..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        }
      } else if (isDestinationEdge) {
        _drawDashedLine(canvas, from, to,
          Paint()..color = AppColors.orange.withOpacity(0.55)..strokeWidth = 2.0..style = PaintingStyle.stroke);
      } else {
        _drawDashedLine(canvas, from, to,
          Paint()..color = const Color(0xFF8b949e).withOpacity(0.35)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      }
    }
  }

  // ── nodes ─────────────────────────────────────────────────────────────────
  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      final unlocked = _isUnlocked(node);
      if (node.isHidden && !unlocked) continue;

      final center      = Offset(node.positionX, node.positionY);
      final color       = _nodeColor(node.type);
      final isCurrent   = node.userState?.isCurrentNode ?? false;
      final isDestination = node.userState?.isDestination ?? false;
      const radius = 22.0;

      // Outer glow — wide soft halo
      if (isCurrent) {
        canvas.drawCircle(center, radius + 14 + 6 * pulseValue,
          Paint()..color = color.withOpacity(0.12 + 0.08 * pulseValue)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      } else if (unlocked) {
        canvas.drawCircle(center, radius + 8,
          Paint()..color = color.withOpacity(0.08)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }

      // Dashed destination ring
      if (isDestination) {
        _drawDashedCircle(canvas, center, radius + 8 + 2 * destValue,
          Paint()..color = AppColors.orange.withOpacity(0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      }

      // Shadow behind circle
      canvas.drawCircle(center, radius + 2,
        Paint()..color = Colors.black.withOpacity(0.5)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Main fill
      Color fillColor;
      if (!unlocked) {
        fillColor = const Color(0xFF0d1117); // near-black for locked
      } else if (isCurrent) {
        fillColor = color.withOpacity(0.55);
      } else {
        fillColor = color.withOpacity(0.28);
      }
      canvas.drawCircle(center, radius, Paint()..color = fillColor..style = PaintingStyle.fill);

      // Inner fill gradient-like highlight (top half lighter)
      if (unlocked) {
        canvas.drawCircle(
          center - Offset(0, radius * 0.25),
          radius * 0.65,
          Paint()..color = color.withOpacity(isCurrent ? 0.25 : 0.10)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Border
      canvas.drawCircle(center, radius,
        Paint()
          ..color = unlocked
              ? (isCurrent ? color : color.withOpacity(0.75))
              : const Color(0xFF8b949e).withOpacity(0.25)
          ..strokeWidth = isCurrent ? 2.5 : 1.5
          ..style = PaintingStyle.stroke);

      // Icon (emoji)
      _drawText(canvas, node.icon, center + const Offset(0, -2),
        fontSize: 15, color: unlocked ? Colors.white.withOpacity(0.95) : Colors.white24);

      // Name label — pill background below node
      final label = node.name.length > 14 ? '${node.name.substring(0, 13)}…' : node.name;
      final labelOffset = center + const Offset(0, radius + 10);

      // Measure text first
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(
          fontSize: 8.5,
          color: unlocked ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.35),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        )),
        textDirection: TextDirection.ltr,
      )..layout();

      // Pill background
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: labelOffset, width: tp.width + 10, height: tp.height + 5),
        const Radius.circular(4),
      );
      canvas.drawRRect(pillRect,
        Paint()..color = Colors.black.withOpacity(0.45)..style = PaintingStyle.fill);

      // Label text
      tp.paint(canvas, labelOffset - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // ── player dot ────────────────────────────────────────────────────────────
  void _drawPlayerDot(Canvas canvas) {
    Offset pos;

    final edgeId = userProgress.currentEdgeId;

    if (edgeId != null) {
      // On an edge — interpolate position respecting travel direction
      MapEdgeModel? activeEdge;
      try { activeEdge = edges.firstWhere((e) => e.id == edgeId); } catch (_) { return; }
      final edgeFromNode = _nodeById(activeEdge.fromNodeId);
      final edgeToNode   = _nodeById(activeEdge.toNodeId);
      if (edgeFromNode == null || edgeToNode == null) return;

      // Determine direction: are we traveling from→to or to→from?
      final goingForward = userProgress.currentNodeId == activeEdge.fromNodeId;
      final startNode = goingForward ? edgeFromNode : edgeToNode;
      final endNode   = goingForward ? edgeToNode   : edgeFromNode;

      final t = activeEdge.distanceKm > 0
          ? (userProgress.distanceTraveledOnEdge / activeEdge.distanceKm).clamp(0.0, 1.0)
          : 0.0;
      pos = Offset.lerp(
        Offset(startNode.positionX, startNode.positionY),
        Offset(endNode.positionX,   endNode.positionY),
        t,
      )!;
    } else {
      // At a node — draw on the current node
      final currentNode = _nodeById(userProgress.currentNodeId);
      if (currentNode == null) return;
      pos = Offset(currentNode.positionX, currentNode.positionY);
    }

    // Outer pulse ring
    canvas.drawCircle(pos, 16 + 4 * pulseValue,
      Paint()
        ..color = AppColors.blue.withOpacity(0.18 + 0.12 * pulseValue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Second ring
    canvas.drawCircle(pos, 13,
      Paint()..color = AppColors.blue.withOpacity(0.35)..style = PaintingStyle.fill);

    // White ring border
    canvas.drawCircle(pos, 10,
      Paint()..color = Colors.white.withOpacity(0.9)..style = PaintingStyle.fill);

    // Blue dot core
    canvas.drawCircle(pos, 7,
      Paint()..color = AppColors.blue..style = PaintingStyle.fill);

    // Inner white highlight
    canvas.drawCircle(pos - const Offset(1.5, 1.5), 2,
      Paint()..color = Colors.white.withOpacity(0.7)..style = PaintingStyle.fill);
  }

  // ── draw helpers ──────────────────────────────────────────────────────────
  void _drawText(Canvas canvas, String text, Offset center,
      {required double fontSize, required Color color}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint,
      {int segments = 16}) {
    final step = 2 * math.pi / segments;
    for (int i = 0; i < segments; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        step * i, step * 0.7, false, paint,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NodeDetailSheet
// ─────────────────────────────────────────────────────────────────────────────
class _NodeDetailSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isAdjacent;
  final double? distanceKm;
  final UserMapProgressModel userProgress;
  final VoidCallback onDestinationSet;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const _NodeDetailSheet({
    required this.node, required this.isAdjacent, this.distanceKm,
    required this.userProgress, required this.onDestinationSet,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<_NodeDetailSheet> createState() => _NodeDetailSheetState();
}

class _NodeDetailSheetState extends State<_NodeDetailSheet> {
  bool _settingDestination = false;
  bool _bossBusy = false;
  String? _bossStatus;
  int? _localBossHpDealt;        // updated locally after each damage hit
  bool? _localBossDefeated;      // updated locally on defeat
  bool? _localBossActivated;     // updated locally on activate
  bool? _localBossExpired;       // updated locally on expire
  final _bossService = BossService();

  bool _chestBusy = false;
  String? _chestStatus;
  bool? _localChestCollected;          // updated locally after collect
  final _chestService = ChestService();

  bool _dungeonBusy = false;
  String? _dungeonStatus;
  bool? _localDungeonDiscovered;       // updated locally after enter
  int? _localDungeonFloor;             // updated locally after each floor
  final _dungeonService = DungeonService();

  bool _crossroadsBusy = false;
  String? _crossroadsStatus;
  final _crossroadsService = CrossroadsService();

  bool get _isUnlocked =>
      widget.node.isStartNode || (widget.node.userState?.isUnlocked ?? false);

  bool get _isLevelMet =>
      widget.node.isStartNode || (widget.node.userState?.isLevelMet ?? false);
  bool get _isCurrentNode => widget.node.userState?.isCurrentNode ?? false;
  bool get _isDestination => widget.node.userState?.isDestination ?? false;

  Future<void> _setDestination() async {
    setState(() => _settingDestination = true);
    try {
      await MapService().setDestination(widget.node.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDestinationSet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _settingDestination = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(widget.node.type);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                          ),
                          child: Center(child: Text(widget.node.icon,
                            style: const TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.node.name,
                                style: const TextStyle(color: AppColors.textPrimary,
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [
                                _Pill(widget.node.region, color: AppColors.purple),
                                _Pill('Lv ${widget.node.levelRequirement}+',
                                  color: _isLevelMet ? AppColors.green : AppColors.orange),
                                if (_isCurrentNode)
                                  _Pill('📍 Here', color: AppColors.green),
                                if (_isDestination)
                                  _Pill('🎯 Destination', color: AppColors.orange),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!_isLevelMet) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kSurface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(children: [
                          const Text('🔒', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            'Reach level ${widget.node.levelRequirement} to unlock this location.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          )),
                        ]),
                      ),
                    ] else ...[
                      if (widget.node.description != null) ...[
                        Text(widget.node.description!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 16),
                      ],
                      _buildTypeContent(),
                      const SizedBox(height: 16),
                      _buildDestinationButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeContent() {
    switch (widget.node.type) {
      case 'Boss': return _buildBossContent();
      case 'Chest': return _buildChestContent();
      case 'Dungeon': return _buildDungeonContent();
      case 'Crossroads': return _buildCrossroadsContent();
      default: return _buildZoneContent();
    }
  }

  Widget _buildZoneContent() {
    if (widget.distanceKm != null && !_isCurrentNode) {
      return _InfoRow('Distance', '${widget.distanceKm!.toStringAsFixed(1)} km to reach');
    }
    return const SizedBox.shrink();
  }

  Widget _buildBossContent() {
    final boss = widget.node.boss;
    if (boss == null) return const SizedBox.shrink();

    // Use local state when available so the sheet updates without closing
    final hpDealt     = _localBossHpDealt   ?? boss.hpDealt;
    final isDefeated  = _localBossDefeated  ?? boss.isDefeated;
    final isActivated = _localBossActivated ?? boss.isActivated;
    final isExpired   = _localBossExpired   ?? boss.isExpired;

    final hpRemaining = boss.maxHp - hpDealt;
    final hpPct = isDefeated ? 0.0 : (hpRemaining / boss.maxHp).clamp(0.0, 1.0);
    final hpBarColor = isDefeated
        ? AppColors.green
        : isExpired
            ? AppColors.textSecondary
            : AppColors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Boss header row
        Row(children: [
          Text(boss.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(boss.name,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              if (boss.isMini)
                const Text('Mini Boss · No travel required',
                  style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          )),
          const SizedBox(width: 8),
          if (isDefeated)
            _Pill('✓ Defeated', color: AppColors.green)
          else if (isExpired)
            _Pill('⌛ Expired', color: AppColors.textSecondary)
          else if (isActivated)
            _Pill('⚔️ Active', color: AppColors.orange),
        ]),
        const SizedBox(height: 10),

        // HP bar
        const _SectionLabel('HP'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hpPct,
            minHeight: 8,
            backgroundColor: _kSurface2,
            valueColor: AlwaysStoppedAnimation(hpBarColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('$hpDealt dealt',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const Spacer(),
          Text('$hpRemaining / ${boss.maxHp} HP remaining',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 10),

        // Stats row
        Wrap(spacing: 8, runSpacing: 6, children: [
          _InfoChip('⚡ ${boss.rewardXp} XP reward'),
          _InfoChip('⏱ ${boss.timerDays}d timer'),
          if (boss.isMini) _InfoChip('🌍 Fight anywhere'),
          if (boss.timerExpiresAt != null && !isDefeated && !isExpired)
            _InfoChip('🗓 Expires ${_formatDate(boss.timerExpiresAt!)}'),
          if (boss.defeatedAt != null)
            _InfoChip('🏆 Defeated ${_formatDate(boss.defeatedAt!)}'),
        ]),

        // Status feedback
        if (_bossStatus != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bossStatus!.startsWith('✓')
                  ? AppColors.green.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _bossStatus!.startsWith('✓')
                    ? AppColors.green.withOpacity(0.4)
                    : AppColors.red.withOpacity(0.4),
              ),
            ),
            child: Text(_bossStatus!,
              style: TextStyle(
                color: _bossStatus!.startsWith('✓') ? AppColors.green : AppColors.red,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],

        // Action buttons
        // Mini-bosses: accessible from anywhere. Regular bosses: must be at the node.
        if ((_isCurrentNode || boss.isMini) && !isDefeated) ...[
          const SizedBox(height: 14),
          if (!isActivated && !isExpired) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: boss.isMini ? AppColors.orange : AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _bossBusy ? null : () => _bossActivate(boss.id),
                child: _bossBusy
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        boss.isMini ? '⚡ Challenge Mini Boss' : '⚔️ Activate Fight',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ] else if (isActivated && !isExpired) ...[
            const _SectionLabel('DEAL DAMAGE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [10, 25, 50, 100, 200].map((dmg) =>
                _DebugButton(
                  label: '-$dmg HP',
                  color: boss.isMini ? AppColors.orange : AppColors.red,
                  onTap: _bossBusy ? null : () => _bossDamage(boss.id, dmg),
                ),
              ).toList(),
            ),
          ] else if (isExpired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: const Row(children: [
                Text('⌛', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Timer expired. Use the debug panel to reset.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                )),
              ]),
            ),
          ],
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _bossActivate(String bossId) async {
    setState(() { _bossBusy = true; _bossStatus = null; });
    try {
      await _bossService.activateFight(bossId);
      if (mounted) {
        final timerDays = widget.node.boss?.timerDays ?? 7;
        setState(() {
          _bossBusy = false;
          _localBossActivated = true;
          _bossStatus = '✓ Fight activated! ${timerDays}d timer started.';
        });
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) setState(() { _bossBusy = false; _bossStatus = '✗ $e'; });
    }
  }

  Future<void> _bossDamage(String bossId, int damage) async {
    setState(() { _bossBusy = true; _bossStatus = null; });
    try {
      final result = await _bossService.dealDamage(bossId, damage);
      if (mounted) {
        final defeated = result['isDefeated'] as bool? ?? false;
        final justDefeated = result['justDefeated'] as bool? ?? false;
        final newHpDealt = result['hpDealt'] as int? ?? 0;
        final maxHp = result['maxHp'] as int? ?? 0;
        final xp = result['rewardXpAwarded'] as int? ?? 0;
        setState(() {
          _bossBusy = false;
          _localBossHpDealt = newHpDealt;
          if (defeated) _localBossDefeated = true;
          _bossStatus = defeated
              ? '✓ DEFEATED! +$xp XP awarded!'
              : '✓ -$damage HP dealt ($newHpDealt/$maxHp)';
        });
        widget.onRefresh();
        if (justDefeated && mounted) {
          _showBossSlainOverlay(context, boss: widget.node.boss!, xpAwarded: xp);
          final leveledUp = result['leveledUp'] as bool? ?? false;
          final newLevel  = result['newLevel']  as int?  ?? 0;
          if (leveledUp) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) widget.onLevelUp(newLevel);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() { _bossBusy = false; _bossStatus = '✗ $e'; });
    }
  }

  void _showBossSlainOverlay(BuildContext context, {required BossData boss, required int xpAwarded}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => _BossSlainOverlay(boss: boss, xpAwarded: xpAwarded),
    );
  }

  Widget _buildChestContent() {
    final chest = widget.node.chest;
    if (chest == null) return const SizedBox.shrink();
    final isCollected = _localChestCollected ?? chest.isCollected;
    final rarityColor = _rarityColor(chest.rarity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _Pill(chest.rarity, color: rarityColor),
          const SizedBox(width: 8),
          _InfoChip('⚡ ${chest.rewardXp} XP'),
          const SizedBox(width: 8),
          if (isCollected) _Pill('✓ Collected', color: AppColors.green),
        ]),

        if (_chestStatus != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _chestStatus!.startsWith('✓')
                  ? AppColors.green.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _chestStatus!.startsWith('✓')
                    ? AppColors.green.withOpacity(0.4)
                    : AppColors.red.withOpacity(0.4),
              ),
            ),
            child: Text(_chestStatus!,
              style: TextStyle(
                color: _chestStatus!.startsWith('✓') ? AppColors.green : AppColors.red,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],

        if (_isCurrentNode && !isCollected) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: const Color(0xFF1a1000),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _chestBusy ? null : () => _collectChest(chest.id),
              child: _chestBusy
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Color(0xFF1a1000), strokeWidth: 2))
                  : const Text('📦 Open Chest',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _collectChest(String chestId) async {
    setState(() { _chestBusy = true; _chestStatus = null; });
    try {
      final result = await _chestService.collect(chestId);
      if (mounted) {
        final xp = result['rewardXp'] as int? ?? 0;
        final rarity = result['rarity'] as String? ?? '';
        setState(() { _chestBusy = false; _localChestCollected = true; });
        widget.onRefresh();
        if (mounted) _showChestRewardDialog(rarity, xp);
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel  = result['newLevel']  as int?  ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _chestBusy = false; _chestStatus = '✗ $e'; });
    }
  }

  void _showChestRewardDialog(String rarity, int xp) {
    final color = _rarityColor(rarity);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _ChestRewardDialog(rarity: rarity, xp: xp, color: color),
    );
  }

  Widget _buildDungeonContent() {
    final dungeon = widget.node.dungeonPortal;
    if (dungeon == null) return const SizedBox.shrink();

    // Use local state when available (sheet stays open after actions)
    final currentFloor = _localDungeonFloor ?? dungeon.currentFloor;
    final isDiscovered = _localDungeonDiscovered ?? dungeon.isDiscovered;
    final isFullyCleared = currentFloor >= dungeon.totalFloors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(dungeon.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
          if (isFullyCleared)
            _Pill('✓ Cleared', color: AppColors.green)
          else if (isDiscovered)
            _Pill('Floor $currentFloor/${dungeon.totalFloors}', color: AppColors.purple)
          else
            _Pill('Undiscovered', color: AppColors.textSecondary),
        ]),
        const SizedBox(height: 12),
        const _SectionLabel('FLOORS'),
        const SizedBox(height: 6),
        ...dungeon.floors.map((f) {
          final isCompleted = f.floorNumber <= currentFloor;
          final isNextFloor = f.floorNumber == currentFloor + 1 && isDiscovered;
          return _DungeonFloorRow(
            floor: f,
            isCompleted: isCompleted,
            isNext: isNextFloor && _isCurrentNode,
            isBusy: _dungeonBusy,
            onComplete: _isCurrentNode && isNextFloor && !_dungeonBusy
                ? () => _completeFloor(dungeon.id, f.floorNumber)
                : null,
          );
        }),

        if (_dungeonStatus != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _dungeonStatus!.startsWith('✓')
                  ? AppColors.green.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _dungeonStatus!.startsWith('✓')
                    ? AppColors.green.withOpacity(0.4)
                    : AppColors.red.withOpacity(0.4),
              ),
            ),
            child: Text(_dungeonStatus!,
              style: TextStyle(
                color: _dungeonStatus!.startsWith('✓') ? AppColors.green : AppColors.red,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],

        if (_isCurrentNode && !isDiscovered) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _dungeonBusy ? null : () => _enterDungeon(dungeon.id),
              child: _dungeonBusy
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('🌀 Enter Dungeon',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _enterDungeon(String dungeonId) async {
    setState(() { _dungeonBusy = true; _dungeonStatus = null; });
    try {
      await _dungeonService.enter(dungeonId);
      if (mounted) {
        setState(() {
          _dungeonBusy = false;
          _localDungeonDiscovered = true;
          _dungeonStatus = '✓ Entered dungeon. Complete floors below.';
        });
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) setState(() { _dungeonBusy = false; _dungeonStatus = '✗ $e'; });
    }
  }

  Future<void> _completeFloor(String dungeonId, int floorNumber) async {
    setState(() { _dungeonBusy = true; _dungeonStatus = null; });
    try {
      final result = await _dungeonService.completeFloor(dungeonId, floorNumber);
      if (mounted) {
        final xp = result['rewardXp'] as int? ?? 0;
        final isCleared = result['isFullyCleared'] as bool? ?? false;
        final newFloor = result['currentFloor'] as int? ?? floorNumber;
        setState(() {
          _dungeonBusy = false;
          _localDungeonFloor = newFloor;
          _dungeonStatus = isCleared
              ? '✓ Dungeon cleared! +$xp XP'
              : '✓ Floor $floorNumber complete! +$xp XP';
        });
        widget.onRefresh();
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel  = result['newLevel']  as int?  ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _dungeonBusy = false; _dungeonStatus = '✗ $e'; });
    }
  }

  Widget _buildCrossroadsContent() {
    final crossroads = widget.node.crossroads;
    if (crossroads == null) return const SizedBox.shrink();
    final hasChosen = crossroads.chosenPathId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: _SectionLabel('CHOOSE YOUR PATH')),
          if (hasChosen) _Pill('Path chosen', color: AppColors.orange),
        ]),
        const SizedBox(height: 8),
        if (!hasChosen && _isCurrentNode)
          const Text(
            'Tap a path to commit to it. This cannot be changed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        if (!hasChosen && _isCurrentNode) const SizedBox(height: 10),
        ...crossroads.paths.map((p) {
          final isChosen = crossroads.chosenPathId == p.id;
          final canChoose = !hasChosen && _isCurrentNode && !_crossroadsBusy;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SelectablePathCard(
              path: p,
              isChosen: isChosen,
              isDisabled: hasChosen && !isChosen,
              canChoose: canChoose,
              onTap: canChoose ? () => _choosePath(crossroads.id, p.id) : null,
            ),
          );
        }),

        if (_crossroadsStatus != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _crossroadsStatus!.startsWith('✓')
                  ? AppColors.orange.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _crossroadsStatus!.startsWith('✓')
                    ? AppColors.orange.withOpacity(0.4)
                    : AppColors.red.withOpacity(0.4),
              ),
            ),
            child: Text(_crossroadsStatus!,
              style: TextStyle(
                color: _crossroadsStatus!.startsWith('✓') ? AppColors.orange : AppColors.red,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  Future<void> _choosePath(String crossroadsId, String pathId) async {
    setState(() { _crossroadsBusy = true; _crossroadsStatus = null; });
    try {
      final result = await _crossroadsService.choosePath(crossroadsId, pathId);
      if (mounted) {
        final name = result['pathName'] as String? ?? '';
        setState(() { _crossroadsBusy = false; _crossroadsStatus = '✓ "$name" chosen — journey begins!'; });
        widget.onRefresh();
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel  = result['newLevel']  as int?  ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _crossroadsBusy = false; _crossroadsStatus = '✗ $e'; });
    }
  }

  Widget _buildDestinationButton() {
    if (_isCurrentNode) return const SizedBox.shrink();
    if (!widget.isAdjacent) {
      return Text('Not reachable from current location',
        style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12));
    }
    if (_isDestination) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange.withOpacity(0.4)),
        ),
        child: const Center(child: Text('🎯 Currently Heading Here',
          style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w600))),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _settingDestination ? null : _setDestination,
        child: _settingDestination
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Set Destination → ${widget.distanceKm != null ? "${widget.distanceKm!.toStringAsFixed(1)} km" : ""}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

// ── small reusable widgets ─────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4), width: 1),
    ),
    child: Text(label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.textSecondary,
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _kSurface2, borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _kBorder),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  );
}

class _DungeonFloorRow extends StatelessWidget {
  final DungeonFloorData floor;
  final bool isCompleted;
  final bool isNext;
  final bool isBusy;
  final VoidCallback? onComplete;

  const _DungeonFloorRow({
    required this.floor,
    required this.isCompleted,
    required this.isNext,
    required this.isBusy,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.green
        : isNext
            ? AppColors.purple
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.green.withOpacity(0.08)
              : isNext
                  ? AppColors.purple.withOpacity(0.08)
                  : const Color(0xFF1e2632),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? AppColors.green.withOpacity(0.3)
                : isNext
                    ? AppColors.purple.withOpacity(0.4)
                    : const Color(0xFF30363d),
          ),
        ),
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(child: isCompleted
                ? Icon(Icons.check, color: color, size: 13)
                : Text('${floor.floorNumber}',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Floor ${floor.floorNumber}',
                style: TextStyle(color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${floor.requiredActivity} · ${floor.requiredMinutes} min',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          )),
          Text('⚡ ${floor.rewardXp}',
            style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
          if (onComplete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isBusy ? null : onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                ),
                child: isBusy
                    ? const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(color: AppColors.purple, strokeWidth: 1.5))
                    : const Text('Complete',
                        style: TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _SelectablePathCard extends StatelessWidget {
  final CrossroadsPathData path;
  final bool isChosen;
  final bool isDisabled;
  final bool canChoose;
  final VoidCallback? onTap;

  const _SelectablePathCard({
    required this.path,
    required this.isChosen,
    required this.isDisabled,
    required this.canChoose,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(path.difficulty);
    final borderColor = isChosen
        ? AppColors.orange
        : canChoose
            ? diffColor.withOpacity(0.4)
            : _kBorder;
    final bgColor = isChosen
        ? AppColors.orange.withOpacity(0.1)
        : isDisabled
            ? _kSurface2.withOpacity(0.4)
            : canChoose
                ? diffColor.withOpacity(0.05)
                : _kSurface2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isChosen ? 1.5 : 1,
          ),
        ),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(path.name,
                  style: TextStyle(
                    color: isChosen ? AppColors.orange : AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w700),
                )),
                if (isChosen)
                  const Text('✓', style: TextStyle(color: AppColors.orange, fontSize: 16, fontWeight: FontWeight.w700)),
                if (canChoose)
                  Icon(Icons.chevron_right, color: diffColor.withOpacity(0.6), size: 18),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _Pill(path.difficulty, color: diffColor),
                _InfoChip('${path.distanceKm.toStringAsFixed(0)} km · ${path.estimatedDays}d'),
                _InfoChip('⚡ ${path.rewardXp} XP'),
              ]),
              if (path.additionalRequirement != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 11)),
                  Expanded(child: Text(path.additionalRequirement!,
                    style: const TextStyle(color: AppColors.red, fontSize: 11))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DebugPanel
// ─────────────────────────────────────────────────────────────────────────────
class _DebugPanel extends StatefulWidget {
  final List<MapNodeModel> nodes;
  final UserMapProgressModel userProgress;
  final MapService service;
  final BossService bossService;
  final VoidCallback onRefresh;

  const _DebugPanel({
    required this.nodes,
    required this.userProgress,
    required this.service,
    required this.bossService,
    required this.onRefresh,
  });

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  bool _busy = false;
  String? _status;
  int? _currentLevel;
  int? _currentXp;
  String? _selectedBossId;
  String? _selectedBossName;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    ApiClient.isAdmin().then((v) { if (mounted) setState(() => _isAdmin = v); });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _status = null; });
    try {
      await action();
      widget.onRefresh();
      if (mounted) setState(() { _busy = false; _status = '✓ Done'; });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
    }
  }

  Future<void> _adjustLevel(int delta) async {
    setState(() { _busy = true; _status = null; });
    try {
      final newLevel = await widget.service.debugAdjustLevel(delta);
      if (mounted) setState(() { _busy = false; _currentLevel = newLevel; _status = '✓ Level $newLevel'; });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleNodes = widget.nodes
        .where((n) => !n.isHidden || (n.userState?.isUnlocked ?? false) || n.isStartNode)
        .toList();
    final hasDestination = widget.userProgress.destinationNodeId != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161b22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF30363d))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                const Text('🛠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Debug Panel',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_busy)
                  const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2)),
                if (_status != null)
                  Text(_status!,
                    style: TextStyle(
                      color: _status!.startsWith('✓') ? AppColors.green : AppColors.red,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Divider(color: Color(0xFF30363d), height: 1),
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: InkWell(
                  onTap: () async {
                    final token = await ApiClient.getToken();
                    final uri = Uri.parse('http://localhost:5128/admin-map')
                        .replace(queryParameters: token != null ? {'token': token} : null);
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⚙️', style: TextStyle(fontSize: 15)),
                        SizedBox(width: 8),
                        Text('Open Admin Portal',
                          style: TextStyle(color: AppColors.purple,
                            fontSize: 13, fontWeight: FontWeight.w700)),
                        SizedBox(width: 6),
                        Icon(Icons.open_in_new, color: AppColors.purple, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isAdmin)
              const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Level controls ─────────────────────────────────────
                    const Text('CHARACTER LEVEL',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _DebugButton(
                        label: '− Level Down',
                        color: AppColors.red,
                        onTap: _busy ? null : () => _adjustLevel(-1),
                      ),
                      const SizedBox(width: 8),
                      if (_currentLevel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                          ),
                          child: Text('Lv $_currentLevel',
                            style: const TextStyle(color: AppColors.orange,
                              fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      const SizedBox(width: 8),
                      _DebugButton(
                        label: '+ Level Up',
                        color: AppColors.green,
                        onTap: _busy ? null : () => _adjustLevel(1),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Travel controls ────────────────────────────────────
                    const Text('SIMULATE TRAVEL',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    hasDestination
                      ? Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [1.0, 3.0, 5.0, 10.0, 99.0].map((km) =>
                            _DebugButton(
                              label: km == 99.0 ? 'Complete' : '+${km.toStringAsFixed(0)} km',
                              color: km == 99.0 ? AppColors.green : AppColors.blue,
                              onTap: _busy ? null : () => _run(() => widget.service.debugAddDistance(km)),
                            ),
                          ).toList(),
                        )
                      : Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                          ),
                          child: const Row(children: [
                            Text('⚠️', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 8),
                            Text('Set a destination first',
                              style: TextStyle(color: AppColors.orange, fontSize: 12)),
                          ]),
                        ),
                    const SizedBox(height: 20),
                    const Text('TELEPORT TO NODE',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...visibleNodes.map((node) {
                      final isCurrent = node.id == widget.userProgress.currentNodeId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: _busy || isCurrent
                              ? null
                              : () => _run(() => widget.service.debugTeleport(node.id)),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? _nodeColor(node.type).withOpacity(0.15)
                                  : const Color(0xFF1e2632),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent
                                    ? _nodeColor(node.type).withOpacity(0.5)
                                    : const Color(0xFF30363d),
                              ),
                            ),
                            child: Row(children: [
                              Text(node.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(node.name,
                                    style: TextStyle(
                                      color: isCurrent ? _nodeColor(node.type) : AppColors.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(node.region,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              )),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('HERE',
                                    style: TextStyle(color: AppColors.green, fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                                )
                              else
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // ── XP controls ────────────────────────────────────────
                    const Text('CHARACTER XP',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _DebugButton(
                        label: '+1 000 XP',
                        color: AppColors.orange,
                        onTap: _busy ? null : () async {
                          setState(() { _busy = true; _status = null; });
                          try {
                            final newXp = await widget.service.debugSetXp((_currentXp ?? 0) + 1000);
                            if (mounted) setState(() { _busy = false; _currentXp = newXp; _status = '✓ XP: $newXp'; });
                            widget.onRefresh();
                          } catch (e) {
                            if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
                          }
                        },
                      ),
                      _DebugButton(
                        label: '+5 000 XP',
                        color: AppColors.orange,
                        onTap: _busy ? null : () async {
                          setState(() { _busy = true; _status = null; });
                          try {
                            final newXp = await widget.service.debugSetXp((_currentXp ?? 0) + 5000);
                            if (mounted) setState(() { _busy = false; _currentXp = newXp; _status = '✓ XP: $newXp'; });
                            widget.onRefresh();
                          } catch (e) {
                            if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
                          }
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Node unlock controls ───────────────────────────────
                    const Text('NODE UNLOCKS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _DebugButton(
                        label: '🔓 Unlock All',
                        color: AppColors.green,
                        onTap: _busy ? null : () => _run(() => widget.service.debugUnlockAll()),
                      ),
                      _DebugButton(
                        label: '🔴 Reset Progress',
                        color: AppColors.red,
                        onTap: _busy ? null : () => _run(() => widget.service.debugResetProgress()),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Boss fight debug ───────────────────────────────────
                    const Text('BOSS FIGHT',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    // Boss selector
                    ...widget.nodes.where((n) => n.type == 'Boss' && n.boss != null).map((node) {
                      final isSelected = _selectedBossId == node.boss!.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedBossId = node.boss!.id;
                            _selectedBossName = node.boss!.name;
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.red.withOpacity(0.15)
                                  : const Color(0xFF1e2632),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.red.withOpacity(0.5)
                                    : const Color(0xFF30363d),
                              ),
                            ),
                            child: Row(children: [
                              Text(node.boss!.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(node.boss!.name,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.red : AppColors.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('${node.boss!.hpDealt}/${node.boss!.maxHp} HP dealt',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              )),
                              if (node.boss!.isDefeated)
                                const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 14, fontWeight: FontWeight.w700))
                              else if (node.boss!.isExpired)
                                const Text('⌛', style: TextStyle(fontSize: 14))
                              else if (node.boss!.isActivated)
                                const Text('⚔️', style: TextStyle(fontSize: 14))
                              else
                                const Text('💤', style: TextStyle(fontSize: 14)),
                            ]),
                          ),
                        ),
                      );
                    }),
                    if (_selectedBossId != null) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _DebugButton(
                          label: '½ HP',
                          color: AppColors.orange,
                          onTap: _busy ? null : () async {
                            final boss = widget.nodes
                                .where((n) => n.boss?.id == _selectedBossId)
                                .first.boss!;
                            await _run(() => widget.bossService.debugSetHp(_selectedBossId!, boss.maxHp ~/ 2));
                          },
                        ),
                        _DebugButton(
                          label: '⚔️ Force Defeat',
                          color: AppColors.green,
                          onTap: _busy ? null : () => _run(() => widget.bossService.debugForceDefeat(_selectedBossId!)),
                        ),
                        _DebugButton(
                          label: '⌛ Force Expire',
                          color: AppColors.textSecondary,
                          onTap: _busy ? null : () => _run(() => widget.bossService.debugForceExpire(_selectedBossId!)),
                        ),
                        _DebugButton(
                          label: '🔄 Reset',
                          color: AppColors.blue,
                          onTap: _busy ? null : () => _run(() => widget.bossService.debugReset(_selectedBossId!)),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 20),

                    // ── Chest debug ────────────────────────────────────────
                    const Text('CHESTS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...widget.nodes.where((n) => n.type == 'Chest' && n.chest != null).map((node) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text(node.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(node.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                          if (node.chest!.isCollected)
                            const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 14, fontWeight: FontWeight.w700))
                          else
                            _DebugButton(
                              label: 'Reset',
                              color: AppColors.blue,
                              onTap: _busy ? null : () => _run(() => ChestService().debugReset(node.chest!.id)),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Dungeon debug ──────────────────────────────────────
                    const Text('DUNGEONS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...widget.nodes.where((n) => n.type == 'Dungeon' && n.dungeonPortal != null).map((node) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e2632),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF30363d)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(node.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(node.name,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                                Text('Floor ${node.dungeonPortal!.currentFloor}/${node.dungeonPortal!.totalFloors}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                ...List.generate(node.dungeonPortal!.totalFloors + 1, (i) =>
                                  _DebugButton(
                                    label: 'Floor $i',
                                    color: i == node.dungeonPortal!.currentFloor
                                        ? AppColors.purple
                                        : AppColors.textSecondary,
                                    onTap: _busy ? null : () => _run(
                                      () => DungeonService().debugSetFloor(node.dungeonPortal!.id, i)),
                                  ),
                                ),
                                _DebugButton(
                                  label: '🔄 Reset',
                                  color: AppColors.blue,
                                  onTap: _busy ? null : () => _run(() => DungeonService().debugReset(node.dungeonPortal!.id)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Crossroads debug ───────────────────────────────────
                    const Text('CROSSROADS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...widget.nodes.where((n) => n.type == 'Crossroads' && n.crossroads != null).map((node) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text(node.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(node.name,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                              Text(
                                node.crossroads!.chosenPathId != null
                                    ? 'Path chosen'
                                    : 'No path chosen',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          )),
                          _DebugButton(
                            label: '🔄 Reset',
                            color: AppColors.blue,
                            onTap: _busy ? null : () => _run(() => CrossroadsService().debugReset(node.crossroads!.id)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DebugButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap == null ? 0.05 : 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(onTap == null ? 0.2 : 0.5)),
        ),
        child: Text(label,
          style: TextStyle(
            color: onTap == null ? color.withOpacity(0.4) : color,
            fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChestRewardDialog
// ─────────────────────────────────────────────────────────────────────────────
class _ChestRewardDialog extends StatefulWidget {
  final String rarity;
  final int xp;
  final Color color;

  const _ChestRewardDialog({
    required this.rarity,
    required this.xp,
    required this.color,
  });

  @override
  State<_ChestRewardDialog> createState() => _ChestRewardDialogState();
}

class _ChestRewardDialogState extends State<_ChestRewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _xpSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn));
    _xpSlide = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chest icon with scale pop
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 24),
                    ],
                  ),
                  child: const Center(
                    child: Text('📦', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // "Chest Opened!" title
              ScaleTransition(
                scale: _scale,
                child: Text(
                  'Chest Opened!',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Rarity pill
              ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    widget.rarity,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // XP reward
              AnimatedBuilder(
                animation: _xpSlide,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, 20 * (1 - _xpSlide.value)),
                  child: Opacity(
                    opacity: _xpSlide.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.xp} XP',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Collect button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Collect',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boss Slain Victory Overlay
// ---------------------------------------------------------------------------

// ─────────────────────────────────────────────────────────────────────────────
// _NodeArrivalBanner  (revisit — subtle, no celebration)
// ─────────────────────────────────────────────────────────────────────────────
class _NodeArrivalBanner extends StatefulWidget {
  final MapNodeModel node;
  const _NodeArrivalBanner({required this.node});

  @override
  State<_NodeArrivalBanner> createState() => _NodeArrivalBannerState();
}

class _NodeArrivalBannerState extends State<_NodeArrivalBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final accent = _nodeColor(node.type);
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF30363d), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(node.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You arrived at ${node.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            node.type,
                            style: TextStyle(fontSize: 11, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NodeDiscoveredBanner
// ─────────────────────────────────────────────────────────────────────────────
class _NodeDiscoveredBanner extends StatefulWidget {
  final MapNodeModel node;
  const _NodeDiscoveredBanner({required this.node});

  @override
  State<_NodeDiscoveredBanner> createState() => _NodeDiscoveredBannerState();
}

class _NodeDiscoveredBannerState extends State<_NodeDiscoveredBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final accent = _nodeColor(node.type);
    final hasXp = node.rewardXp > 0;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161b22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon glow
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.12),
                          border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
                        ),
                        child: Center(
                          child: Text(node.icon, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🗺️  New area discovered!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              node.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              node.type,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasXp) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.green.withOpacity(0.4)),
                          ),
                          child: Text(
                            '+${node.rewardXp} XP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BossSlainOverlay extends StatefulWidget {
  final BossData boss;
  final int xpAwarded;
  const _BossSlainOverlay({required this.boss, required this.xpAwarded});

  @override
  State<_BossSlainOverlay> createState() => _BossSlainOverlayState();
}

class _BossSlainOverlayState extends State<_BossSlainOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMini = widget.boss.isMini;
    final accentColor = isMini ? AppColors.orange : AppColors.red;
    final xpStr = widget.xpAwarded >= 1000
        ? '${(widget.xpAwarded / 1000).toStringAsFixed(1)}k'
        : '${widget.xpAwarded}';

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Boss icon in glowing circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.12),
                  border: Border.all(color: accentColor.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 4),
                  ],
                ),
                child: Center(
                  child: Text(widget.boss.icon, style: const TextStyle(fontSize: 50)),
                ),
              ),
              const SizedBox(height: 24),

              // SLAIN label
              Text(
                isMini ? 'MINI BOSS\nDEFEATED!' : 'BOSS\nSLAIN!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 2,
                  height: 1.1,
                  shadows: [Shadow(color: accentColor.withOpacity(0.6), blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 8),

              // Boss name
              Text(
                widget.boss.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // XP reward badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.blue.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.blue.withOpacity(0.2), blurRadius: 16),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpStr XP',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tap to dismiss
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'tap to continue',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
