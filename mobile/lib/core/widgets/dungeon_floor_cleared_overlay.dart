import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/dungeon_floor_cleared_notifier.dart';

/// Celebration dialog fired whenever `DungeonFloorClearedNotifier` emits a
/// non-null event. Mirrors the chest-opened / item-obtained overlays visually:
/// fade + slide + scale entrance, pulsing glow around the emoji, tap-outside
/// to dismiss.
///
/// Two variants based on [event.runCompleted]:
///  • false → per-floor "Floor X cleared!" in green with active-floor progress
///    summary (e.g. "Floor 2 of 3 done · Floor 3 unlocked")
///  • true  → full-run "🏆 Dungeon cleared!" in amber with bonus XP reward
void showDungeonFloorClearedOverlay(
  BuildContext context,
  DungeonFloorClearedEvent event,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss reward popup',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.18),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _FloorClearedDialog(event: event),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _FloorClearedDialog extends StatefulWidget {
  final DungeonFloorClearedEvent event;
  const _FloorClearedDialog({required this.event});

  @override
  State<_FloorClearedDialog> createState() => _FloorClearedDialogState();
}

class _FloorClearedDialogState extends State<_FloorClearedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.event.runCompleted;
    final accent = completed ? AppColors.orange : AppColors.green;
    final eyebrow = completed ? '✦ DUNGEON CLEARED ✦' : '✦ FLOOR CLEARED ✦';
    final title = completed ? 'Dungeon conquered!' : 'Floor cleared!';
    final emoji = completed ? '🏆' : '⚡';
    final subtitle = completed
        ? 'You beat all ${widget.event.totalFloors} trials of ${widget.event.dungeonName}.'
        : 'Floor ${widget.event.clearedFloorOrdinal} of ${widget.event.totalFloors} in ${widget.event.dungeonName} done.'
            '${widget.event.clearedFloorOrdinal < widget.event.totalFloors ? " Floor ${widget.event.clearedFloorOrdinal + 1} is now active." : ""}';

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.2),
                blurRadius: 42,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 22),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final t = _pulse.value;
                  return Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.12),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.55), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28 + 0.2 * t),
                          blurRadius: 26 + 14 * t,
                          spreadRadius: 2 + 2 * t,
                        ),
                      ],
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 46)),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              if (completed) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BONUS REWARD',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+${widget.event.bonusXpAwarded} XP',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 18),
                _ProgressStrip(
                  cleared: widget.event.clearedFloorOrdinal,
                  total: widget.event.totalFloors,
                  accent: accent,
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(completed ? 'Claim' : 'Keep going'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final int cleared;
  final int total;
  final Color accent;
  const _ProgressStrip({
    required this.cleared,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Container(
            width: 28,
            height: 6,
            decoration: BoxDecoration(
              color: i <= cleared
                  ? accent
                  : AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
