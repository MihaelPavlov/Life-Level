import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/home/cards/home_portal_card.dart';
import '../../motion/app_motion.dart';
import '../shell_constants.dart';
import 'map_orb_button.dart';

/// The journey card, opened from the Map button. It rises out of the button
/// with a small tail pointing back at it; the scrim closes it.
class JourneyPopover extends StatefulWidget {
  final bool open;
  final VoidCallback onClose;
  final VoidCallback onSync;
  const JourneyPopover({
    super.key,
    required this.open,
    required this.onClose,
    required this.onSync,
  });

  @override
  State<JourneyPopover> createState() => _JourneyPopoverState();
}

class _JourneyPopoverState extends State<JourneyPopover> {
  /// The card is only built while open or animating closed, so nothing
  /// hidden can ever paint over Home.
  late bool _built = widget.open;
  Timer? _unbuild;

  @override
  void didUpdateWidget(covariant JourneyPopover old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) {
      _unbuild?.cancel();
      _built = true;
    } else if (!widget.open && old.open) {
      _unbuild?.cancel();
      _unbuild = Timer(
        AppMotion.duration(context, const Duration(milliseconds: 360)),
        () {
          if (mounted && !widget.open) setState(() => _built = false);
        },
      );
    }
  }

  @override
  void dispose() {
    _unbuild?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.open;
    final onClose = widget.onClose;
    final onSync = widget.onSync;
    final duration =
        AppMotion.duration(context, const Duration(milliseconds: 320));
    final maxH = MediaQuery.of(context).size.height * .62;
    // The card sits just above the raised Map button.
    const cardBottom = kNavBarH + kMapOrbSize / 2 - 4;

    return IgnorePointer(
      ignoring: !open,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: kNavBarH,
            child: GestureDetector(
              onTap: onClose,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: duration,
                child: const ColoredBox(color: Color(0x9E02050A)),
              ),
            ),
          ),
          if (_built)
            Positioned(
              left: 10,
              right: 10,
              bottom: cardBottom,
              child: AnimatedSlide(
                offset: open ? Offset.zero : const Offset(0, .06),
                duration: duration,
                curve: open ? Curves.easeOutBack : Curves.easeInCubic,
                child: AnimatedScale(
                  scale: open ? 1 : .92,
                  alignment: Alignment.bottomCenter,
                  duration: duration,
                  curve: open ? Curves.easeOutBack : Curves.easeInCubic,
                  child: AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: AppMotion.duration(
                        context, const Duration(milliseconds: 200)),
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: 'Journey',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: maxH),
                            child: SingleChildScrollView(
                              child: HomePortalCard(onSync: onSync),
                            ),
                          ),
                          const _Tail(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tail extends StatelessWidget {
  const _Tail();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 10),
      painter: _TailPainter(),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width / 2, s.height)
      ..lineTo(s.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF161B22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
