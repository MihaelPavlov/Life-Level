import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_colors.dart';
import 'models/map_models.dart';

class MapPainter extends CustomPainter {
  final List<MapNodeModel> nodes;
  final List<MapEdgeModel> edges;
  final UserMapProgressModel userProgress;
  final double pulseValue;
  final double destValue;

  const MapPainter({
    required this.nodes,
    required this.edges,
    required this.userProgress,
    required this.pulseValue,
    required this.destValue,
  });

  @override
  bool shouldRepaint(MapPainter old) =>
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
      final color       = mapNodeColor(node.type);
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
