import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'world_map_data.dart';
import 'world_map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorldMapPainter
// ─────────────────────────────────────────────────────────────────────────────

class WorldMapPainter extends CustomPainter {
  WorldMapPainter({
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
      Offset(centre.dx - tp.width / 2, centre.dy + kZoneRadius + 5),
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
      Offset(centre.dx - tp.width / 2, centre.dy - kZoneRadius - tp.height - 2),
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
        final y = kTopPadding + z.tier * kTierHeight;
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
      final glowRadius = kZoneRadius + 8 + pulseValue * 8;
      final glowPaint = Paint()
        ..color = AppColors.blue.withOpacity(0.18 + pulseValue * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(c, glowRadius, glowPaint);
    }

    // Fill
    canvas.drawCircle(
      c,
      kZoneRadius,
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
        ..addOval(Rect.fromCircle(center: c, radius: kZoneRadius));
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
      canvas.drawCircle(c, kZoneRadius, strokePaint);
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
        Offset(c.dx + kZoneRadius - tp.width - 1, c.dy - kZoneRadius + 1),
      );
    }
  }

  void _drawDiamond(Canvas canvas, ZoneData z, Offset c, double opacity) {
    final fill   = _zoneFill(z.status);
    final stroke = _zoneStroke(z.status);
    final h = kDiamondHalf;

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
    final fogStartY = size.height * kFogStartFrac;
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
  bool shouldRepaint(WorldMapPainter old) => old.pulseValue != pulseValue;
}
