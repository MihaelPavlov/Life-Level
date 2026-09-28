import 'package:flutter/widgets.dart';

/// What a reward line grants — decides its icon and which HUD element the
/// reward flies into when claimed.
enum RewardKind { xp, coins, gems, item, other }

/// Where claimed rewards fly to: the on-screen HUD widgets (coin and gem
/// chips, the avatar's XP ring) register themselves here while visible.
///
/// Registration follows [TickerMode], so a HUD on a hidden tab or under a
/// shell overlay stops being a target — rewards never fly to something the
/// player can't see. With no target on screen, [RewardMoment] lets the
/// reward drift up and fade instead.
class RewardHud {
  RewardHud._();

  static final _targets = <RewardKind, List<_RewardHudTargetState>>{};

  /// Global rect of the most recently shown visible target for [kind].
  static Rect? rectFor(RewardKind kind) {
    final list = _targets[kind];
    if (list == null) return null;
    for (final t in list.reversed) {
      final r = t._rect;
      if (r != null) return r;
    }
    return null;
  }

  static void _add(RewardKind kind, _RewardHudTargetState t) {
    final list = _targets.putIfAbsent(kind, () => []);
    list.remove(t);
    list.add(t);
  }

  static void _remove(RewardKind kind, _RewardHudTargetState t) =>
      _targets[kind]?.remove(t);
}

/// Marks [child] as the HUD element that [kind] rewards fly into.
class RewardHudTarget extends StatefulWidget {
  final RewardKind kind;
  final Widget child;

  const RewardHudTarget({super.key, required this.kind, required this.child});

  @override
  State<RewardHudTarget> createState() => _RewardHudTargetState();
}

class _RewardHudTargetState extends State<RewardHudTarget> {
  Rect? get _rect {
    if (!mounted) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-runs whenever the enclosing TickerMode flips (tab switch, shell
    // overlay opened or closed).
    if (TickerMode.of(context)) {
      RewardHud._add(widget.kind, this);
    } else {
      RewardHud._remove(widget.kind, this);
    }
  }

  @override
  void didUpdateWidget(covariant RewardHudTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      RewardHud._remove(oldWidget.kind, this);
      if (TickerMode.of(context)) RewardHud._add(widget.kind, this);
    }
  }

  @override
  void dispose() {
    RewardHud._remove(widget.kind, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
