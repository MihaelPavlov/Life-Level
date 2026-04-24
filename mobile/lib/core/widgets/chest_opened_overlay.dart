import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// "Chest Opened!" celebration dialog. Slides + fades in, shows the zone
/// emoji inside a pulsing orange glow, the reward amount in a big centered
/// number, a short congratulatory line, and a dismiss button. Mirrors the
/// style of `item_obtained_overlay.dart` so the app feels consistent.
void showChestOpenedOverlay(
  BuildContext context, {
  required String zoneName,
  required int xp,
  String emoji = '🎁',
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss chest reward',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _ChestOpenedDialog(
      zoneName: zoneName,
      xp: xp,
      emoji: emoji,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChestOpenedDialog extends StatefulWidget {
  final String zoneName;
  final int xp;
  final String emoji;
  const _ChestOpenedDialog({
    required this.zoneName,
    required this.xp,
    required this.emoji,
  });

  @override
  State<_ChestOpenedDialog> createState() => _ChestOpenedDialogState();
}

class _ChestOpenedDialogState extends State<_ChestOpenedDialog>
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
                color: AppColors.orange.withValues(alpha: 0.18),
                blurRadius: 42,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Eyebrow
              const Text(
                '✦ CHEST OPENED ✦',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 22),

              // Pulsing emoji in orange glow
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
                      color: AppColors.orange.withValues(alpha: 0.12),
                      border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.55),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange
                              .withValues(alpha: 0.28 + 0.18 * t),
                          blurRadius: 26 + 14 * t,
                          spreadRadius: 2 + 2 * t,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 46),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Congratulatory copy
              const Text(
                'Congratulations!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You opened ${widget.zoneName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Reward block — big XP number
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: 0.18),
                      AppColors.orange.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'YOU EARNED',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+${widget.xp} XP',
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
              const SizedBox(height: 18),

              // Claim / dismiss
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
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
