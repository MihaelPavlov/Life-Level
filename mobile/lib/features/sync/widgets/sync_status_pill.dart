import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';

/// The small line under the Home header that tells the player about sync.
/// Orange pill with a count when workouts are waiting; otherwise a faint
/// "Synced 2m ago". Tapping the pill runs the same check as a pull.
class SyncStatusPill extends StatefulWidget {
  final int pendingCount;
  final DateTime? lastCheckedAt;
  final bool busy;
  final VoidCallback onTap;

  const SyncStatusPill({
    super.key,
    required this.pendingCount,
    required this.lastCheckedAt,
    required this.busy,
    required this.onTap,
  });

  static String agoLabel(DateTime? at, [DateTime? now]) {
    if (at == null) return 'Pull down to sync';
    final d = (now ?? DateTime.now()).difference(at);
    if (d.inSeconds < 60) return 'Synced just now';
    if (d.inMinutes < 60) return 'Synced ${d.inMinutes}m ago';
    if (d.inHours < 24) return 'Synced ${d.inHours}h ago';
    return 'Synced ${d.inDays}d ago';
  }

  @override
  State<SyncStatusPill> createState() => _SyncStatusPillState();
}

class _SyncStatusPillState extends State<SyncStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant SyncStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final want =
        widget.pendingCount > 0 && AppMotion.allowsDecorativeMotion(context);
    if (want && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!want && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.pendingCount;
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotionTokens.micro),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
            scale: Tween(begin: .85, end: 1.0).animate(a), child: child),
      ),
      child: n > 0
          ? _pill(n)
          : Text(
              widget.busy
                  ? 'Checking…'
                  : SyncStatusPill.agoLabel(widget.lastCheckedAt),
              key: const ValueKey('ago'),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary.withValues(alpha: .55),
                shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
    );
  }

  Widget _pill(int n) {
    return Semantics(
      key: const ValueKey('pill'),
      button: true,
      label: '$n new workout${n == 1 ? '' : 's'}, pull down or tap to import',
      child: AppPressable(
        haptic: AppHaptic.selection,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
            decoration: BoxDecoration(
              color: const Color(0xE610161F),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.orange.withValues(alpha: .6)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange
                      .withValues(alpha: .18 + .22 * _pulse.value),
                  blurRadius: 14,
                ),
              ],
            ),
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange
                        .withValues(alpha: .35 + .65 * (1 - _pulse.value)),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$n new workout${n == 1 ? '' : 's'} · pull down',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF5C26A),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.translate(
                    offset: Offset(0, 2.5 * _pulse.value), child: child),
                child: const Icon(Icons.south_rounded,
                    size: 13, color: Color(0xFFF5C26A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
