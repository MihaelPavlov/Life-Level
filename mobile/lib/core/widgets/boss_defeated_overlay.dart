import 'package:flutter/material.dart';
import '../../features/activity/models/activity_models.dart';
import '../constants/app_colors.dart';

/// Celebration dialog fired whenever `BossDefeatedNotifier` emits an event —
/// i.e. an activity log finished a boss off. Mirrors the chest-opened /
/// dungeon-floor-cleared overlays: fade + slide + scale entrance, pulsing
/// red glow around the boss icon, tap-outside to dismiss.
void showBossDefeatedOverlay(
  BuildContext context,
  BossDefeatedInfo info,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss boss reward popup',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 420),
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
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _BossDefeatedDialog(info: info),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _BossDefeatedDialog extends StatefulWidget {
  final BossDefeatedInfo info;
  const _BossDefeatedDialog({required this.info});

  @override
  State<_BossDefeatedDialog> createState() => _BossDefeatedDialogState();
}

class _BossDefeatedDialogState extends State<_BossDefeatedDialog>
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
    final info = widget.info;
    const accent = AppColors.red;
    final eyebrow = info.isMini ? '✦ MINI-BOSS SLAIN ✦' : '✦ BOSS SLAIN ✦';
    final title = info.isMini ? 'Mini-boss down!' : 'Boss vanquished!';
    final subtitle = '${info.name} has fallen. The path forward is yours.';
    final iconGlyph = info.icon.isEmpty ? '👹' : info.icon;

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
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 48,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
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
                    width: 104,
                    height: 104,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.6), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35 + 0.25 * t),
                          blurRadius: 28 + 16 * t,
                          spreadRadius: 2 + 3 * t,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(iconGlyph, style: const TextStyle(fontSize: 50)),
                        // Diagonal "slain" stroke — purely decorative.
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '☠',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
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
              if (info.rewardXp > 0) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.orange.withValues(alpha: 0.22),
                        AppColors.orange.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.45),
                        width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BOSS REWARD',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+${info.rewardXp} XP',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
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
                  child: const Text('Claim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
