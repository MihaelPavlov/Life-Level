import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/world_zone_refresh_notifier.dart';
import 'world_map_data.dart';
import 'world_map_detail_sheet.dart';
import 'world_map_layout.dart';
import 'world_map_models.dart';
import 'world_map_painter.dart';
import 'models/world_zone_models.dart';
import 'services/world_zone_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorldMapScreen
// ─────────────────────────────────────────────────────────────────────────────

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final _service = WorldZoneService();
  final _scrollController = ScrollController();
  bool _hasScrolledToActive = false;

  List<ZoneData> _zones = [];
  Map<String, List<String>> _edges = {};
  List<Offset> _zoneCentres = [];
  int _characterLevel = 1;

  Offset? _playerOnEdge;   // null = player is at zone, not travelling
  Offset? _playerAnchor;   // source zone centre for the progress line
  double  _travelProgress = 0.0;

  bool _loading = true;
  String? _error;

  String? _lastKnownZoneId;
  late StreamSubscription<void> _refreshSub;

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _refreshSub = WorldZoneRefreshNotifier.stream.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── data loading ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final previousZoneId = _lastKnownZoneId;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getFullWorld();

      final isTraveling = data.userProgress.currentEdgeId != null;
      final zones = data.zones.map((m) => ZoneData.fromApiModel(m, isTraveling: isTraveling)).toList();

      final edges = <String, List<String>>{};
      for (final e in data.edges) {
        edges.putIfAbsent(e.fromZoneId, () => []).add(e.toZoneId);
        if (e.isBidirectional) {
          edges.putIfAbsent(e.toZoneId, () => []).add(e.fromZoneId);
        }
      }

      final layoutZones = WorldMapLayout.applyTierLayout(zones);

      // ── travel state ────────────────────────────────────────────────────────
      Offset? playerOnEdge;
      Offset? playerAnchor;
      double  travelProgress = 0.0;

      final prog = data.userProgress;
      if (prog.destinationZoneId != null && prog.currentEdgeId != null) {
        final edge = data.edges.cast<WorldZoneEdgeModel?>().firstWhere(
          (e) => e?.id == prog.currentEdgeId,
          orElse: () => null,
        );
        final fromIdx = layoutZones.indexWhere((z) => z.id == prog.currentZoneId);
        final toIdx   = layoutZones.indexWhere((z) => z.id == prog.destinationZoneId);
        if (edge != null && fromIdx != -1 && toIdx != -1 && edge.distanceKm > 0) {
          final frac = (prog.distanceTraveledOnEdge / edge.distanceKm).clamp(0.0, 1.0);
          final centres = layoutZones.map(WorldMapLayout.centreFor).toList();
          // Use a minimum visual fraction so the character is always visibly
          // on the edge (not sitting on top of the source zone node at 0%).
          final visualFrac = frac > 0 ? frac : 0.06;
          playerOnEdge   = Offset.lerp(centres[fromIdx], centres[toIdx], visualFrac)!;
          playerAnchor   = centres[fromIdx];
          travelProgress = frac;
        }
      }

      setState(() {
        _zones = layoutZones;
        _edges = edges;
        _zoneCentres = layoutZones.map(WorldMapLayout.centreFor).toList();
        _characterLevel = data.characterLevel;
        _playerOnEdge   = playerOnEdge;
        _playerAnchor   = playerAnchor;
        _travelProgress = travelProgress;
        _loading = false;
      });

      // Scroll to the active zone on first load
      if (!_hasScrolledToActive) {
        _hasScrolledToActive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveZone(layoutZones));
      }

      // Detect zone arrival
      final activeZone = layoutZones.cast<ZoneData?>().firstWhere(
        (z) => z!.status == ZoneStatus.active,
        orElse: () => null,
      );
      if (activeZone != null) {
        if (previousZoneId != null && previousZoneId != activeZone.id && mounted) {
          _showZoneArrivalBanner(activeZone);
        }
        _lastKnownZoneId = activeZone.id;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToActiveZone(List<ZoneData> zones) {
    if (!mounted || !_scrollController.hasClients) return;
    final activeZone = zones.cast<ZoneData?>().firstWhere(
      (z) => z!.status == ZoneStatus.active,
      orElse: () => zones.cast<ZoneData?>().firstWhere(
        (z) => z!.isDestination,
        orElse: () => null,
      ),
    );
    if (activeZone == null) return;
    final centre = WorldMapLayout.centreFor(activeZone);
    final screenHeight = MediaQuery.of(context).size.height;
    final targetOffset = (centre.dy - screenHeight / 2).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _onCanvasTap(TapDownDetails details) {
    final tapped = details.localPosition;
    for (int i = 0; i < _zones.length; i++) {
      final c = _zoneCentres[i];
      final z = _zones[i];
      final hitRadius =
          z.isCrossroads ? kDiamondHalf * 1.4 : kZoneRadius * 1.2;
      if ((tapped - c).distance <= hitRadius) {
        _showZoneSheet(z);
        return;
      }
    }
  }

  Future<void> _handleSetDestination(ZoneData zone) async {
    try {
      await _service.setDestination(zone.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set destination: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    // Crossroads: backend auto-completed the move — stay on world map and refresh
    if (zone.isCrossroads) {
      await _load();
      return;
    }

    _handleEnterLocalMap(zone);
  }

  void _handleEnterLocalMap(ZoneData zone) {
    if (mounted) {
      Navigator.pop(context, {'zoneId': zone.id, 'zoneName': zone.name});
    }
  }

  void _showZoneSheet(ZoneData zone) {
    final currentZone = _zones.cast<ZoneData?>().firstWhere(
      (z) => z!.status == ZoneStatus.active && !z.isDestination,
      orElse: () => null,
    );
    final currentZoneId = currentZone?.id;
    final adjacentIds = currentZoneId != null
        ? (_edges[currentZoneId] ?? <String>[])
        : <String>[];
    final isAdjacent = adjacentIds.contains(zone.id);

    final isAtCrossroads = currentZone?.isCrossroads ?? false;
    // At a crossroads the player must move forward (higher tier).
    // Any adjacent zone at the same tier or below is "behind" and unreachable.
    final crossroadsTier = currentZone?.tier ?? 0;
    final isForwardZone = !isAtCrossroads || zone.tier > crossroadsTier;

    VoidCallback? enterCallback;
    if (zone.status == ZoneStatus.active) {
      // Crossroads have no local map to enter — leave enterCallback null so
      // the sheet shows an informational "you are here" state instead.
      if (!zone.isCrossroads) {
        enterCallback = () {
          Navigator.pop(context);
          _handleEnterLocalMap(zone);
        };
      }
    } else if (isAdjacent && isForwardZone &&
        (zone.status == ZoneStatus.available ||
            // Allow revisiting completed zones only when NOT at a crossroads.
            (!isAtCrossroads && zone.status == ZoneStatus.completed) ||
            (zone.status == ZoneStatus.locked &&
                _characterLevel >= zone.levelRequirement))) {
      enterCallback = () {
        Navigator.pop(context);
        _handleSetDestination(zone);
      };
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WorldMapDetailSheet(
        zone: zone,
        userLevel: _characterLevel,
        isAdjacentToCurrentZone: isAdjacent,
        travelProgress: zone.isDestination ? _travelProgress : null,
        onEnter: enterCallback,
      ),
    );
  }

  void _showZoneArrivalBanner(ZoneData zone) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: child);
      },
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1e2632),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: AppColors.orange.withOpacity(0.15), blurRadius: 16),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(zone.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ZONE REACHED',
                        style: TextStyle(color: AppColors.orange, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 2),
                      Text(zone.name,
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── full-screen background ────────────────────────────────────────────
        Positioned.fill(
          child: CustomPaint(painter: _MapBackgroundPainter()),
        ),

        // ── content ───────────────────────────────────────────────────────────
        if (_loading)
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.blue,
              strokeWidth: 2,
            ),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load world map',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // ── scrollable map canvas ───────────────────────────────────────────
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: GestureDetector(
                  onTapDown: _onCanvasTap,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => CustomPaint(
                      size: const Size(kCanvasWidth, kCanvasHeight),
                      painter: WorldMapPainter(
                        zones: _zones,
                        centres: _zoneCentres,
                        edges: _edges,
                        pulseValue: _pulseAnim.value,
                        playerOnEdge: _playerOnEdge,
                        playerAnchor: _playerAnchor,
                        travelProgress: _travelProgress,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── floating HUD pill ───────────────────────────────────────────────
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363d), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌍', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    const Text(
                      'World Map',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lv $_characterLevel',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen background — matches world-structure.html:
//   • base #040810
//   • radial blue glow  — top-left  (30 % / 20 %)
//   • radial purple glow — bottom-right (70 % / 80 %)
//   • subtle 40 px grid
//   • scattered stars
// ─────────────────────────────────────────────────────────────────────────────

class _BgStar {
  const _BgStar(this.x, this.y, this.r, this.a);
  final double x, y, r, a;
}

class _MapBackgroundPainter extends CustomPainter {
  static final List<_BgStar> _stars = _genStars();

  static List<_BgStar> _genStars() {
    final rng = math.Random(0xBEEF1234);
    return [
      for (int i = 0; i < 90; i++)
        _BgStar(
          rng.nextDouble() * 430,
          rng.nextDouble() * 960,
          rng.nextDouble() * 1.3 + 0.2,
          rng.nextDouble() * 0.5 + 0.1,
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // base fill
    canvas.drawRect(rect, Paint()..color = const Color(0xFF040810));

    // radial blue — top-left
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.40, -0.60),
          radius: 1.1,
          colors: [Color(0x0A4F9EFF), Color(0x004F9EFF)],
        ).createShader(rect),
    );

    // radial purple — bottom-right
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.40, 0.60),
          radius: 1.1,
          colors: [Color(0x0AA371F7), Color(0x00A371F7)],
        ).createShader(rect),
    );

    // 40 px grid
    final gridPaint = Paint()
      ..color = const Color(0x05FFFFFF)
      ..strokeWidth = 1.0;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      starPaint.color = Color.fromRGBO(190, 220, 255, s.a);
      canvas.drawCircle(Offset(s.x, s.y), s.r, starPaint);
    }
  }

  @override
  bool shouldRepaint(_MapBackgroundPainter _) => false;
}
