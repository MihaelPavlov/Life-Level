import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain
// ─────────────────────────────────────────────────────────────────────────────

enum ZoneStatus { completed, active, available, locked }

class ZoneData {
  const ZoneData({
    required this.id,
    required this.name,
    required this.icon,
    required this.status,
    required this.tier,
    required this.relativeX,
    required this.region,
    this.nodeCount,
    this.totalXp,
    this.distanceKm,
    required this.levelRequirement,
    required this.isCrossroads,
    this.description,
  });

  final String id;
  final String name;
  final String icon;
  final ZoneStatus status;
  final int tier;
  final double relativeX;
  final String region;
  final int? nodeCount;
  final int? totalXp;
  final int? distanceKm;
  final int levelRequirement;
  final bool isCrossroads;
  final String? description;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

const int _kMockUserLevel = 7;

const List<ZoneData> _kZones = [
  ZoneData(
    id: 'ashfield',
    name: 'Ashfield Plains',
    icon: '🌾',
    status: ZoneStatus.completed,
    tier: 0,
    relativeX: 0.5,
    region: 'Lowlands',
    nodeCount: 12,
    totalXp: 2500,
    distanceKm: 8,
    levelRequirement: 1,
    isCrossroads: false,
    description: 'A gentle, open plain where adventurers begin their journey.',
  ),
  ZoneData(
    id: 'first_fork',
    name: 'First Fork',
    icon: '⚔️',
    status: ZoneStatus.available,
    tier: 1,
    relativeX: 0.5,
    region: 'Lowlands',
    levelRequirement: 1,
    isCrossroads: true,
    description: 'A crossroads where two great paths diverge.',
  ),
  ZoneData(
    id: 'thornwood',
    name: 'Thornwood Forest',
    icon: '🌲',
    status: ZoneStatus.active,
    tier: 2,
    relativeX: 0.3,
    region: 'Verdant Reach',
    nodeCount: 9,
    totalXp: 3200,
    distanceKm: 12,
    levelRequirement: 5,
    isCrossroads: false,
    description: 'Dense woodland filled with ancient ruins and hidden trails.',
  ),
  ZoneData(
    id: 'iron_peaks',
    name: 'Iron Peaks',
    icon: '⛰️',
    status: ZoneStatus.available,
    tier: 2,
    relativeX: 0.7,
    region: 'Stonereach',
    nodeCount: 11,
    totalXp: 4100,
    distanceKm: 15,
    levelRequirement: 5,
    isCrossroads: false,
    description: 'Towering mountains forged from iron ore, home to powerful beasts.',
  ),
  ZoneData(
    id: 'convergence',
    name: 'The Convergence',
    icon: '🔀',
    status: ZoneStatus.locked,
    tier: 3,
    relativeX: 0.5,
    region: 'Nexus',
    levelRequirement: 8,
    isCrossroads: true,
    description: 'A mysterious junction where the paths of fate cross.',
  ),
  ZoneData(
    id: 'coral',
    name: 'Coral Coast',
    icon: '🌊',
    status: ZoneStatus.locked,
    tier: 4,
    relativeX: 0.3,
    region: 'Azure Shore',
    nodeCount: 10,
    totalXp: 5000,
    distanceKm: 18,
    levelRequirement: 10,
    isCrossroads: false,
    description: 'A sunken coastal zone teeming with sea beasts and lost treasure.',
  ),
  ZoneData(
    id: 'frostbound',
    name: 'Frostbound Peaks',
    icon: '❄️',
    status: ZoneStatus.locked,
    tier: 4,
    relativeX: 0.7,
    region: 'Glacial Expanse',
    nodeCount: 13,
    totalXp: 6200,
    distanceKm: 22,
    levelRequirement: 10,
    isCrossroads: false,
    description: 'A frozen mountain range where only the strongest endure.',
  ),
  ZoneData(
    id: 'final_approach',
    name: 'Final Approach',
    icon: '🔱',
    status: ZoneStatus.locked,
    tier: 5,
    relativeX: 0.5,
    region: 'Apex',
    levelRequirement: 12,
    isCrossroads: true,
    description: 'The last checkpoint before the ultimate trial.',
  ),
  ZoneData(
    id: 'desert',
    name: 'Desert of Trials',
    icon: '🏜️',
    status: ZoneStatus.locked,
    tier: 6,
    relativeX: 0.5,
    region: 'Ashen Wastes',
    nodeCount: 14,
    totalXp: 8000,
    distanceKm: 30,
    levelRequirement: 15,
    isCrossroads: false,
    description: 'An endless scorching desert that tests the limits of every hero.',
  ),
];

// id → list of connected ids (directed: from → to, drawn from lower tier to higher)
const Map<String, List<String>> _kEdges = {
  'ashfield':       ['first_fork'],
  'first_fork':     ['thornwood', 'iron_peaks'],
  'thornwood':      ['convergence'],
  'iron_peaks':     ['convergence'],
  'convergence':    ['coral', 'frostbound'],
  'coral':          ['final_approach'],
  'frostbound':     ['final_approach'],
  'final_approach': ['desert'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Layout constants
// ─────────────────────────────────────────────────────────────────────────────

const double _kCanvasWidth   = 390.0;
const double _kCanvasHeight  = 1200.0;
const double _kTierHeight    = 160.0;
const double _kTopPadding    = 80.0;
const double _kZoneRadius    = 26.0;
const double _kDiamondHalf   = 22.0;
const double _kFogStartFrac  = 0.42; // fraction of canvas height where fog begins

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

  // Precomputed zone centre positions (index matches _kZones order)
  late List<Offset> _zoneCentres;

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

    _zoneCentres = _kZones.map(_centreFor).toList();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Offset _centreFor(ZoneData z) {
    final y = _kTopPadding + z.tier * _kTierHeight;
    final x = z.relativeX * _kCanvasWidth;
    return Offset(x, y);
  }

  void _onCanvasTap(TapDownDetails details) {
    final tapped = details.localPosition;
    for (int i = 0; i < _kZones.length; i++) {
      final c = _zoneCentres[i];
      final z = _kZones[i];
      final hitRadius = z.isCrossroads ? _kDiamondHalf * 1.4 : _kZoneRadius * 1.2;
      if ((tapped - c).distance <= hitRadius) {
        _showZoneSheet(z);
        return;
      }
    }
  }

  void _showZoneSheet(ZoneData zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZoneDetailSheet(
        zone: zone,
        userLevel: _kMockUserLevel,
        onEnter: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          );
        },
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // ── map canvas ──────────────────────────────────────────────────────
          GestureDetector(
            onTapDown: _onCanvasTap,
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.6,
              maxScale: 2.0,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => CustomPaint(
                  size: const Size(_kCanvasWidth, _kCanvasHeight),
                  painter: _WorldMapPainter(
                    zones: _kZones,
                    centres: _zoneCentres,
                    edges: _kEdges,
                    pulseValue: _pulseAnim.value,
                  ),
                ),
              ),
            ),
          ),

          // ── floating HUD pill ───────────────────────────────────────────────
          Positioned(
            top: 48, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363d), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
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
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lv $_kMockUserLevel',
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({
    required this.zones,
    required this.centres,
    required this.edges,
    required this.pulseValue,
  });

  final List<ZoneData> zones;
  final List<Offset> centres;
  final Map<String, List<String>> edges;
  final double pulseValue;

  // Cache id → index lookup
  late final Map<String, int> _idxById = {
    for (int i = 0; i < zones.length; i++) zones[i].id: i,
  };

  // ── colour helpers ───────────────────────────────────────────────────────────

  Color _edgeColor(ZoneStatus a, ZoneStatus b) {
    if (a == ZoneStatus.completed && b == ZoneStatus.completed) {
      return AppColors.green;
    }
    if (a == ZoneStatus.locked || b == ZoneStatus.locked) {
      return const Color(0xFF333333);
    }
    return AppColors.blue;
  }

  Color _zoneFill(ZoneStatus s) {
    switch (s) {
      case ZoneStatus.completed: return const Color(0xFF1a3d1f);
      case ZoneStatus.active:    return const Color(0xFF1a2d4a);
      case ZoneStatus.available: return const Color(0xFF1e1a0a);
      case ZoneStatus.locked:    return const Color(0xFF111111);
    }
  }

  Color _zoneStroke(ZoneStatus s) {
    switch (s) {
      case ZoneStatus.completed: return AppColors.green;
      case ZoneStatus.active:    return AppColors.blue;
      case ZoneStatus.available: return AppColors.orange;
      case ZoneStatus.locked:    return const Color(0xFF333333);
    }
  }

  // ── dashed path ──────────────────────────────────────────────────────────────

  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const double dashLen = 6;
    const double gapLen  = 4;
    final path = Path()..moveTo(from.dx, from.dy)..lineTo(to.dx, to.dy);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = 0;
      bool drawing = true;
      while (dist < m.length) {
        final seg = drawing ? dashLen : gapLen;
        if (drawing) {
          canvas.drawPath(
            m.extractPath(dist, math.min(dist + seg, m.length)),
            paint,
          );
        }
        dist += seg;
        drawing = !drawing;
      }
    }
  }

  // ── tier label ───────────────────────────────────────────────────────────────

  void _drawTierLabel(Canvas canvas, int tier, double y) {
    const labels = ['TIER 0', 'TIER I', 'TIER II', 'TIER III', 'TIER IV', 'TIER V', 'TIER VI'];
    if (tier >= labels.length) return;

    final tp = TextPainter(
      text: TextSpan(
        text: labels[tier],
        style: const TextStyle(
          color: Color(0xFF3a4a5a),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, y - tp.height / 2));
  }

  // ── zone icon + text ─────────────────────────────────────────────────────────

  void _drawZoneIcon(Canvas canvas, String icon, Offset centre, double opacity) {
    final tp = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(opacity)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      centre.translate(-tp.width / 2, -tp.height / 2),
    );
  }

  void _drawZoneName(Canvas canvas, String name, Offset centre, ZoneStatus status) {
    final color = status == ZoneStatus.locked
        ? const Color(0xFF3a4a5a)
        : AppColors.textSecondary;
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 90);
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy + _kZoneRadius + 5),
    );
  }

  // ── player marker ────────────────────────────────────────────────────────────

  void _drawPlayerMarker(Canvas canvas, Offset centre) {
    final tp = TextPainter(
      text: const TextSpan(
        text: '🧙',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - _kZoneRadius - tp.height - 2),
    );
  }

  // ── main paint ───────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawTierLabels(canvas);
    _drawZones(canvas);
    _drawFogOfWar(canvas, size);
  }

  void _drawEdges(Canvas canvas) {
    edges.forEach((fromId, toIds) {
      final fromIdx = _idxById[fromId];
      if (fromIdx == null) return;
      final fromZone = zones[fromIdx];
      final fromCentre = centres[fromIdx];

      for (final toId in toIds) {
        final toIdx = _idxById[toId];
        if (toIdx == null) continue;
        final toZone = zones[toIdx];
        final toCentre = centres[toIdx];

        final color = _edgeColor(fromZone.status, toZone.status);
        final paint = Paint()
          ..color = color.withOpacity(0.7)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        _drawDashed(canvas, fromCentre, toCentre, paint);
      }
    });
  }

  void _drawTierLabels(Canvas canvas) {
    final Set<int> seenTiers = {};
    for (final z in zones) {
      if (seenTiers.add(z.tier)) {
        final y = _kTopPadding + z.tier * _kTierHeight;
        _drawTierLabel(canvas, z.tier, y);
      }
    }
  }

  void _drawZones(Canvas canvas) {
    for (int i = 0; i < zones.length; i++) {
      final z = zones[i];
      final c = centres[i];
      final isLocked = z.status == ZoneStatus.locked;
      final opacity = isLocked ? 0.5 : 1.0;

      if (z.isCrossroads) {
        _drawDiamond(canvas, z, c, opacity);
      } else {
        _drawCircle(canvas, z, c, opacity);
      }

      _drawZoneName(canvas, z.name, c, z.status);

      if (z.status == ZoneStatus.active) {
        _drawPlayerMarker(canvas, c);
      }
    }
  }

  void _drawCircle(Canvas canvas, ZoneData z, Offset c, double opacity) {
    final fill  = _zoneFill(z.status);
    final stroke = _zoneStroke(z.status);

    // Glow for active
    if (z.status == ZoneStatus.active) {
      final glowRadius = _kZoneRadius + 8 + pulseValue * 8;
      final glowPaint = Paint()
        ..color = AppColors.blue.withOpacity(0.18 + pulseValue * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(c, glowRadius, glowPaint);
    }

    // Fill
    canvas.drawCircle(
      c,
      _kZoneRadius,
      Paint()..color = fill.withOpacity(opacity),
    );

    // Stroke — dashed for available
    final strokePaint = Paint()
      ..color = stroke.withOpacity(opacity)
      ..strokeWidth = z.status == ZoneStatus.available ? 1.5 : 2.0
      ..style = PaintingStyle.stroke;

    if (z.status == ZoneStatus.available) {
      // Draw dashed circle via path
      final path = Path()
        ..addOval(Rect.fromCircle(center: c, radius: _kZoneRadius));
      final metrics = path.computeMetrics();
      for (final m in metrics) {
        double dist = 0;
        bool drawing = true;
        while (dist < m.length) {
          const double dashLen = 6;
          const double gapLen  = 4;
          final seg = drawing ? dashLen : gapLen;
          if (drawing) {
            canvas.drawPath(
              m.extractPath(dist, math.min(dist + seg, m.length)),
              strokePaint,
            );
          }
          dist += seg;
          drawing = !drawing;
        }
      }
    } else {
      canvas.drawCircle(c, _kZoneRadius, strokePaint);
    }

    // Icon
    _drawZoneIcon(canvas, z.icon, c, z.status == ZoneStatus.locked ? 0.35 : 0.9);

    // Completed checkmark overlay
    if (z.status == ZoneStatus.completed) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '✓',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(c.dx + _kZoneRadius - tp.width - 1, c.dy - _kZoneRadius + 1),
      );
    }
  }

  void _drawDiamond(Canvas canvas, ZoneData z, Offset c, double opacity) {
    final fill   = _zoneFill(z.status);
    final stroke = _zoneStroke(z.status);
    final h = _kDiamondHalf;

    final path = Path()
      ..moveTo(c.dx, c.dy - h)
      ..lineTo(c.dx + h, c.dy)
      ..lineTo(c.dx, c.dy + h)
      ..lineTo(c.dx - h, c.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = fill.withOpacity(opacity),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.withOpacity(opacity)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Icon (smaller for diamonds)
    final tp = TextPainter(
      text: TextSpan(
        text: z.icon,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(z.status == ZoneStatus.locked ? 0.3 : 0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c.translate(-tp.width / 2, -tp.height / 2));
  }

  void _drawFogOfWar(Canvas canvas, Size size) {
    final fogStartY = size.height * _kFogStartFrac;
    final rect = Rect.fromLTWH(0, fogStartY, size.width, size.height - fogStartY);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0x00040810),
        const Color(0xCC040810),
        const Color(0xFF040810),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WorldMapPainter old) => old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneDetailSheet extends StatelessWidget {
  const _ZoneDetailSheet({
    required this.zone,
    required this.userLevel,
    required this.onEnter,
  });

  final ZoneData zone;
  final int userLevel;
  final VoidCallback onEnter;

  // ── status display ───────────────────────────────────────────────────────────

  String get _statusLabel {
    switch (zone.status) {
      case ZoneStatus.completed: return 'Completed';
      case ZoneStatus.active:    return 'In Progress';
      case ZoneStatus.available: return 'Available';
      case ZoneStatus.locked:    return 'Locked';
    }
  }

  Color get _statusColor {
    switch (zone.status) {
      case ZoneStatus.completed: return AppColors.green;
      case ZoneStatus.active:    return AppColors.blue;
      case ZoneStatus.available: return AppColors.orange;
      case ZoneStatus.locked:    return AppColors.textSecondary;
    }
  }

  bool get _meetsLevelReq => userLevel >= zone.levelRequirement;
  bool get _canEnter => zone.status != ZoneStatus.locked && !zone.isCrossroads;

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF30363d), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3a4a5a),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon + name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(zone.icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone.region,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              // Stat chips (non-crossroads only)
              if (!zone.isCrossroads &&
                  zone.nodeCount != null &&
                  zone.totalXp != null &&
                  zone.distanceKm != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(label: '${zone.nodeCount} Nodes', icon: '🗺️'),
                    const SizedBox(width: 8),
                    _StatChip(label: '${zone.totalXp} XP', icon: '⭐'),
                    const SizedBox(width: 8),
                    _StatChip(label: '${zone.distanceKm} km', icon: '📍'),
                  ],
                ),
              ],

              // Description
              if (zone.description != null) ...[
                const SizedBox(height: 14),
                Text(
                  zone.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],

              // Requirements
              const SizedBox(height: 16),
              const Text(
                'REQUIREMENTS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              _RequirementRow(
                label: 'Level ${zone.levelRequirement}+',
                met: _meetsLevelReq,
              ),
              if (zone.isCrossroads) ...[
                const SizedBox(height: 6),
                const _RequirementRow(
                  label: 'Branching point — no entry needed',
                  met: true,
                  isNote: true,
                ),
              ],

              // Buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                            color: Color(0xFF30363d), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  if (!zone.isCrossroads) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _canEnter ? onEnter : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canEnter
                              ? AppColors.blue
                              : const Color(0xFF2a3340),
                          foregroundColor: _canEnter
                              ? Colors.white
                              : AppColors.textSecondary,
                          disabledBackgroundColor: const Color(0xFF2a3340),
                          disabledForegroundColor: AppColors.textSecondary,
                          elevation: _canEnter ? 4 : 0,
                          shadowColor: _canEnter
                              ? AppColors.blue.withOpacity(0.35)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _canEnter ? 'Enter Zone →' : 'Zone Locked',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable sub-widgets (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF30363d), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.met,
    this.isNote = false,
  });

  final String label;
  final bool met;
  final bool isNote;

  @override
  Widget build(BuildContext context) {
    if (isNote) {
      return Row(
        children: [
          const Icon(Icons.info_outline,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 16,
          color: met ? AppColors.green : AppColors.red,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: met ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
