import 'package:flutter/widgets.dart';

/// Where every [TourTarget] currently on screen is, by id, and who wants to
/// hear when one is tapped.
///
/// Targets register their [BuildContext] (not a GlobalKey) so wrapping a
/// widget never reparents it and the same id can move between screens.
abstract final class TourTargets {
  static final Map<String, _TourTargetState> _mounted = {};
  static final List<void Function(String id)> _tapListeners = [];

  /// Global rect of the target, or null when it isn't laid out on screen.
  static Rect? rectOf(String id) {
    final state = _mounted[id];
    if (state == null || !state.mounted) return null;
    final box = state.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static BuildContext? contextOf(String id) {
    final state = _mounted[id];
    return state != null && state.mounted ? state.context : null;
  }

  /// False while the target is shown but can't be used (nothing to claim…).
  static bool isEnabled(String id) => _mounted[id]?.widget.enabled ?? false;

  static void addTapListener(void Function(String id) listener) =>
      _tapListeners.add(listener);

  static void removeTapListener(void Function(String id) listener) =>
      _tapListeners.remove(listener);

  static void _tapped(String id) {
    for (final l in List.of(_tapListeners)) {
      l(id);
    }
  }
}

/// Marks a widget a guided tour can point at. Taps still reach [child]
/// untouched; the tour only listens for them.
class TourTarget extends StatefulWidget {
  final String id;

  /// Set false when the widget is visible but its action isn't available,
  /// so a tour step that asks for a tap falls back to "Got it".
  final bool enabled;
  final Widget child;

  const TourTarget({
    super.key,
    required this.id,
    this.enabled = true,
    required this.child,
  });

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  Offset? _down;

  @override
  void initState() {
    super.initState();
    TourTargets._mounted[widget.id] = this;
  }

  @override
  void didUpdateWidget(TourTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      if (identical(TourTargets._mounted[old.id], this)) {
        TourTargets._mounted.remove(old.id);
      }
      TourTargets._mounted[widget.id] = this;
    }
  }

  @override
  void dispose() {
    if (identical(TourTargets._mounted[widget.id], this)) {
      TourTargets._mounted.remove(widget.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-claim the id on rebuild: when two screens share an id, the one
    // being shown is the one that rebuilt last.
    TourTargets._mounted[widget.id] = this;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _down = e.position,
      onPointerUp: (e) {
        final down = _down;
        _down = null;
        // A tap, not a scroll or a drag.
        if (down != null && (e.position - down).distance < 18) {
          TourTargets._tapped(widget.id);
        }
      },
      onPointerCancel: (_) => _down = null,
      child: widget.child,
    );
  }
}
