import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';
import 'zone_node_tile.dart';

/// Duolingo-style vertical trail of zone bubbles connected by status-coloured
/// cubic Bezier curves. Mirrors `.rv3-trail` in
/// `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html` — bubbles alternate left /
/// right by index with boss and crossroads forced to the centre, and the SVG
/// curve layer sits behind them.
class ZoneTrail extends StatelessWidget {
  final List<ZoneNode> nodes;
  final ActiveJourney? journey;
  final String? nextRegionName;

  /// Character avatar rendered on the walker token. When null, the walker is
  /// suppressed — we'd rather show nothing than a placeholder.
  final String? avatarEmoji;

  final void Function(ZoneNode) onTap;

  const ZoneTrail({
    super.key,
    required this.nodes,
    required this.journey,
    required this.nextRegionName,
    required this.avatarEmoji,
    required this.onTap,
  });

  static const double _rowHeight = 110;
  static const double _tailSpace = 24;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox(height: _rowHeight);
    }

    final layouts = _buildLayouts(nodes);
    final totalHeight = _rowHeight * nodes.length + _tailSpace;
    final traveling = journey != null;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final walkerPos = (traveling && avatarEmoji != null)
          ? _walkerPlacement(nodes, layouts, journey!, width)
          : null;

      return SizedBox(
        width: width,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TrailPainter(layouts: layouts, traveling: traveling),
              ),
            ),
            for (int i = 0; i < nodes.length; i++)
              Positioned(
                top: layouts[i].yCenter - _rowHeight / 2,
                left: 0,
                right: 0,
                height: _rowHeight,
                child: _SlotAlign(
                  slot: layouts[i].slot,
                  child: ZoneNodeBubble(
                    node: nodes[i],
                    journey: journey,
                    nextRegionName: nodes[i].isBoss ? nextRegionName : null,
                    onTap: () => onTap(nodes[i]),
                  ),
                ),
              ),
            if (walkerPos != null)
              Positioned(
                left: walkerPos.dx,
                top: walkerPos.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _Walker(
                    avatarEmoji: avatarEmoji!,
                    travelledKm: journey!.distanceTravelledKm,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  static List<_Layout> _buildLayouts(List<ZoneNode> nodes) {
    final out = <_Layout>[];
    int standardSlotIndex = 0; // counter for non-centered nodes
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      _Slot slot;
      if (n.isBoss || n.isCrossroads) {
        slot = _Slot.center;
      } else {
        slot = standardSlotIndex.isEven ? _Slot.left : _Slot.right;
        standardSlotIndex++;
      }
      out.add(_Layout(
        slot: slot,
        yCenter: _rowHeight * (i + 0.5),
        status: n.status,
      ));
    }
    return out;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum _Slot { left, right, center }

class _Layout {
  final _Slot slot;
  final double yCenter;
  final ZoneNodeStatus status;
  const _Layout({
    required this.slot,
    required this.yCenter,
    required this.status,
  });
}

// Shared x-coordinate for a given slot — used by both the curve painter and
// the walker placement helper so they never drift apart.
const double _xLeftRatio = 110 / 390;
const double _xRightRatio = 280 / 390;
const double _xCenterRatio = 0.5;

double _xFor(_Slot s, double width) {
  switch (s) {
    case _Slot.left:
      return width * _xLeftRatio;
    case _Slot.right:
      return width * _xRightRatio;
    case _Slot.center:
      return width * _xCenterRatio;
  }
}

// Cubic Bezier point at parameter t (0..1) for the same curve shape the
// painter draws: (p0) → control1=(p0.x, midY) → control2=(p3.x, midY) → (p3).
Offset _cubicBezier(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
  final u = 1 - t;
  final uu = u * u;
  final uuu = uu * u;
  final tt = t * t;
  final ttt = tt * t;
  final x = uuu * p0.dx +
      3 * uu * t * p1.dx +
      3 * u * tt * p2.dx +
      ttt * p3.dx;
  final y = uuu * p0.dy +
      3 * uu * t * p1.dy +
      3 * u * tt * p2.dy +
      ttt * p3.dy;
  return Offset(x, y);
}

Offset? _walkerPlacement(
  List<ZoneNode> nodes,
  List<_Layout> layouts,
  ActiveJourney journey,
  double width,
) {
  if (journey.distanceTotalKm <= 0) return null;
  final activeIdx = nodes.indexWhere((n) => n.status == ZoneNodeStatus.active);
  final nextIdx = nodes.indexWhere((n) => n.status == ZoneNodeStatus.next);
  if (activeIdx < 0 || nextIdx < 0) return null;

  final a = layouts[activeIdx];
  final b = layouts[nextIdx];
  final x0 = _xFor(a.slot, width);
  final y0 = a.yCenter;
  final x1 = _xFor(b.slot, width);
  final y1 = b.yCenter;
  final midY = (y0 + y1) / 2;
  final t =
      (journey.distanceTravelledKm / journey.distanceTotalKm).clamp(0.0, 1.0);
  return _cubicBezier(
    t,
    Offset(x0, y0),
    Offset(x0, midY),
    Offset(x1, midY),
    Offset(x1, y1),
  );
}

class _SlotAlign extends StatelessWidget {
  final _Slot slot;
  final Widget child;
  const _SlotAlign({required this.slot, required this.child});

  @override
  Widget build(BuildContext context) {
    switch (slot) {
      case _Slot.left:
        return Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Align(alignment: Alignment.centerLeft, child: child),
        );
      case _Slot.right:
        return Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Align(alignment: Alignment.centerRight, child: child),
        );
      case _Slot.center:
        return Align(alignment: Alignment.center, child: child);
    }
  }
}

// ─── Curve painter ───────────────────────────────────────────────────────────

class _TrailPainter extends CustomPainter {
  final List<_Layout> layouts;
  final bool traveling;

  _TrailPainter({required this.layouts, required this.traveling});

  @override
  void paint(Canvas canvas, Size size) {
    if (layouts.length < 2) return;

    // Walk nodes pairwise. Track how many locked segments we've emitted so
    // later ones fade further (8/6 dash at first, then 5/6 opacity 0.5).
    int lockedStepsSoFar = 0;

    for (int i = 0; i < layouts.length - 1; i++) {
      final a = layouts[i];
      final b = layouts[i + 1];
      final x0 = _xFor(a.slot, size.width);
      final y0 = a.yCenter;
      final x1 = _xFor(b.slot, size.width);
      final y1 = b.yCenter;
      final midY = (y0 + y1) / 2;

      final path = Path()
        ..moveTo(x0, y0)
        ..cubicTo(x0, midY, x1, midY, x1, y1);

      // Read the underlying node status for the transition decision. The
      // painter doesn't need the full node, just the bits relevant to the
      // colouring rules.
      final fromStatus = _statusAt(i);
      final toStatus = _statusAt(i + 1);
      final unlocked = _isUnlocked(fromStatus) && _isUnlocked(toStatus);

      if (unlocked) {
        // Solid gradient. Colour depends on the transition.
        final isActiveToNext = fromStatus == ZoneNodeStatus.active &&
            toStatus == ZoneNodeStatus.next;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _solidGradient(fromStatus, toStatus, traveling),
          ).createShader(Rect.fromLTRB(0, y0, size.width, y1));
        canvas.drawPath(path, paint);

        // A soft halo behind the active→next curve sells the glow.
        if (isActiveToNext) {
          final halo = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..color = (traveling ? AppColors.orange : AppColors.blue)
                .withOpacity(0.12);
          canvas.drawPath(path, halo);
        }
        lockedStepsSoFar = 0; // reset on re-entering the unlocked chain
      } else {
        final firstLocked = lockedStepsSoFar == 0;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = firstLocked ? 3 : 2.5
          ..strokeCap = StrokeCap.butt
          ..color = AppColors.border
              .withOpacity(firstLocked ? 0.75 : 0.5);
        final dash = firstLocked ? 8.0 : 5.0;
        const gap = 6.0;
        _drawDashed(canvas, path, paint, dash, gap);
        lockedStepsSoFar++;
      }
    }
  }

  ZoneNodeStatus _statusAt(int i) => layouts[i].status;

  static bool _isUnlocked(ZoneNodeStatus s) =>
      s == ZoneNodeStatus.completed || s == ZoneNodeStatus.active;

  List<Color> _solidGradient(
      ZoneNodeStatus from, ZoneNodeStatus to, bool traveling) {
    const green60 = Color(0x993fb950); // 0.6 alpha
    const green30 = Color(0x4d3fb950); // 0.3
    const green40 = Color(0x663fb950); // 0.4
    const blue60 = Color(0x994f9eff);
    const orange70 = Color(0xb3f5a623);

    if (from == ZoneNodeStatus.active) {
      // Active → next: green base, tip coloured by travel state.
      return [green40, traveling ? orange70 : blue60];
    }
    if (to == ZoneNodeStatus.active) {
      return [green40, blue60];
    }
    return [green60, green30];
  }

  void _drawDashed(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final next =
            (d + dash).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) {
    if (old.traveling != traveling) return true;
    if (old.layouts.length != layouts.length) return true;
    for (int i = 0; i < layouts.length; i++) {
      if (old.layouts[i].slot != layouts[i].slot ||
          old.layouts[i].yCenter != layouts[i].yCenter ||
          old.layouts[i].status != layouts[i].status) {
        return true;
      }
    }
    return false;
  }
}

// ─── Walker token ────────────────────────────────────────────────────────────

class _Walker extends StatefulWidget {
  final String avatarEmoji;
  final double travelledKm;
  const _Walker({required this.avatarEmoji, required this.travelledKm});

  @override
  State<_Walker> createState() => _WalkerState();
}

class _WalkerState extends State<_Walker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, __) {
        final t = _bob.value; // 0..1..0
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: _WalkerBody(
            avatarEmoji: widget.avatarEmoji,
            travelledKm: widget.travelledKm,
          ),
        );
      },
    );
  }
}

class _WalkerBody extends StatelessWidget {
  final String avatarEmoji;
  final double travelledKm;
  const _WalkerBody({
    required this.avatarEmoji,
    required this.travelledKm,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.blue.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.25),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Text(
              avatarEmoji,
              style: const TextStyle(
                fontSize: 22,
                shadows: [
                  Shadow(
                    color: Color(0x80000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'YOU · ${travelledKm.toStringAsFixed(1)} KM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
