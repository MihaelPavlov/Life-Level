import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_progress_dots.dart';

/// Full-screen step-7 modal. Shown after the final bubble (Boss FAB) is
/// advanced. "Begin your adventure" calls `controller.advance()` once more
/// so the server sets `tutorialStep = 99` (completed) and claims the final
/// +250 XP + Novice title on the first run.
class TutorialOutroScreen extends ConsumerWidget {
  const TutorialOutroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Orange + green radial backdrop — matches the outro mockup.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.55),
                  radius: 1.0,
                  colors: [
                    AppColors.orange.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.7),
                  radius: 1.0,
                  colors: [
                    AppColors.green.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      '\u2705 QUEST COMPLETE',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _TrophyCircle(),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome, Novice Adventurer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You learned the basics. Now go train in the real world — your next level awaits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _RewardRow(),
                  const Spacer(),
                  const TutorialProgressDots(
                    total: 8,
                    activeIndex: 7,
                    doneUpTo: 7,
                    activeColor: AppColors.green,
                  ),
                  const SizedBox(height: 16),
                  _BeginAdventureButton(
                    onPressed: () async {
                      final controller =
                          ref.read(tutorialControllerProvider);
                      controller.dismissOutroModal();
                      // Close the outro screen first, then tell the server
                      // we're done. `advance()` on step 7 flips the server
                      // state to 99 and awards the final rewards (only the
                      // first time per account).
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      await controller.advance();
                      await controller.stop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyCircle extends StatelessWidget {
  const _TrophyCircle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [
              AppColors.orange.withValues(alpha: 0.5),
              AppColors.orange.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.45),
              blurRadius: 40,
            ),
          ],
        ),
        child: const Center(
          child: Text('\uD83C\uDFC6', style: TextStyle(fontSize: 52)),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _RewardChip(emoji: '\u2728', label: '+500 XP'),
        _RewardChip(emoji: '\uD83C\uDFC5', label: 'Novice Title'),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _RewardChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeginAdventureButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BeginAdventureButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orange, Color(0xFFc7831a)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'BEGIN YOUR ADVENTURE \u25B8',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
