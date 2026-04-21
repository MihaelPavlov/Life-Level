import 'package:flutter/material.dart';

/// Full-screen dim + animated pulse ring painter. The dim is a single flat
/// fill (0.78 opacity over #04060C per the spec); the pulse ring is a
/// 2px stroke + soft outer glow on the target's rect, animating brightness
/// between 1.0 and 1.3× every 1.8s to match the HTML mockup.
class TutorialDimBackdrop extends StatefulWidget {
  /// Target rect in global coordinates. Pass `null` to render just the
  /// full-screen dim (used by modal steps with no target).
  final Rect? targetRect;

  /// Accent color used for the pulse ring stroke + glow. Typically the
  /// step's accent (blue / purple / orange / green / red).
  final Color accentColor;

  /// When true, the target rect is drawn as a circle (used for the FAB
  /// and other round targets). Otherwise the ring hugs the rect as a
  /// rounded rectangle.
  final bool circular;

  const TutorialDimBackdrop({
    super.key,
    required this.targetRect,
    required this.accentColor,
    this.circular = false,
  });

  @override
  State<TutorialDimBackdrop> createState() => _TutorialDimBackdropState();
}

class _TutorialDimBackdropState extends State<TutorialDimBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          // 0..1..0 ping-pong — peaks at 0.5.
          final t = (1 - (2 * _pulseCtrl.value - 1).abs());
          return CustomPaint(
            size: Size.infinite,
            painter: _BackdropPainter(
              target: widget.targetRect,
              accent: widget.accentColor,
              circular: widget.circular,
              pulseT: t,
            ),
          );
        },
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final Rect? target;
  final Color accent;
  final bool circular;
  final double pulseT;

  static const Color _scrim = Color(0xFF04060C);

  _BackdropPainter({
    required this.target,
    required this.accent,
    required this.circular,
    required this.pulseT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;

    // Single flat dim — spec uses rgba(4,6,12,0.78) everywhere. The bubble
    // variant keeps the full dim (no cut-out) and relies on the ring-only
    // highlight for focus.
    final dim = Paint()..color = _scrim.withValues(alpha: 0.78);
    canvas.drawRect(full, dim);

    final rect = target;
    if (rect == null) return;

    // Padding so the ring sits just outside the target.
    const pad = 6.0;
    final inflated = rect.inflate(pad);

    // Two-layer glow + crisp stroke. The glow brightness oscillates with
    // `pulseT`; stroke stays constant so the target remains readable.
    final glowAlpha = 0.25 + 0.20 * pulseT;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = accent.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.75);

    if (circular) {
      final cx = inflated.center.dx;
      final cy = inflated.center.dy;
      final r = inflated.longestSide / 2;
      canvas.drawCircle(Offset(cx, cy), r, glow);
      canvas.drawCircle(Offset(cx, cy), r, ring);
    } else {
      final rr = RRect.fromRectAndRadius(inflated, const Radius.circular(16));
      canvas.drawRRect(rr, glow);
      canvas.drawRRect(rr, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) =>
      old.target != target ||
      old.accent != accent ||
      old.circular != circular ||
      old.pulseT != pulseT;
}
