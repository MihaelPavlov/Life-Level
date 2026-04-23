import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_progress_dots.dart';
import '../widgets/tutorial_skip_sheet.dart';

/// Full-screen step-0 modal. Shown on first build after a new character is
/// created (when `tutorialStep == 0`). The integration pass decides whether
/// to push this as a route or embed it in the shell's stack.
///
/// "Begin the quest" calls `controller.advance()` so the server bumps
/// step 0 → 1 and awards the first +25 XP; the overlay then fades into
/// the bubble for the XP card.
class TutorialIntroScreen extends ConsumerWidget {
  const TutorialIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Radial backdrop — blue up-top + purple bottom glow, mirrors
          // the character-setup intro styling.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.55),
                  radius: 1.0,
                  colors: [
                    AppColors.blue.withValues(alpha: 0.22),
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
                    AppColors.purple.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const _FirstQuestTag(),
                  const SizedBox(height: 16),
                  const _HeroCircle(
                    emoji: '\uD83D\uDDE1',
                    accent: AppColors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'A new adventurer arrives',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your journey has begun. Let's learn how training in the real world makes you stronger in this one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _PillarCard(
                    emoji: '\uD83D\uDCC8',
                    title: 'Train \u2192 Level up',
                    desc: 'Workouts earn XP and raise stats',
                  ),
                  const SizedBox(height: 10),
                  const _PillarCard(
                    emoji: '\uD83D\uDDFA\uFE0F',
                    title: 'Explore the world',
                    desc: 'Distance moves you across zones',
                  ),
                  const SizedBox(height: 10),
                  const _PillarCard(
                    emoji: '\u2694\uFE0F',
                    title: 'Defeat bosses',
                    desc: 'Daily raids reward gear & titles',
                  ),
                  const SizedBox(height: 24),
                  const TutorialProgressDots(
                    total: 8,
                    activeIndex: 0,
                    doneUpTo: 0,
                    activeColor: AppColors.blue,
                  ),
                  const SizedBox(height: 16),
                  _BeginButton(
                    onPressed: () async {
                      final controller =
                          ref.read(tutorialControllerProvider);
                      controller.dismissIntroModal();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      // `advance()` bumps the server 0 → 1 and (first time
                      // only) awards +25 XP that the overlay will flash.
                      await controller.advance();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SkipLink(
                    onPressed: () async {
                      final confirmed = await showTutorialSkipSheet(context);
                      if (confirmed == true) {
                        await ref
                            .read(tutorialControllerProvider)
                            .skip();
                        if (context.mounted &&
                            Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
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

// ── pieces ──────────────────────────────────────────────────────────────────
class _FirstQuestTag extends StatelessWidget {
  const _FirstQuestTag();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '\u2694 FIRST QUEST',
        style: TextStyle(
          color: AppColors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  final String emoji;
  final Color accent;
  const _HeroCircle({required this.emoji, required this.accent});

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
              accent.withValues(alpha: 0.5),
              accent.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 40,
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 52)),
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _PillarCard({
    required this.emoji,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeginButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BeginButton({required this.onPressed});

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
            colors: [AppColors.blue, Color(0xFF2f7ad8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'BEGIN THE QUEST \u25B8',
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

class _SkipLink extends StatelessWidget {
  final VoidCallback onPressed;
  const _SkipLink({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
        child: const Text(
          'SKIP TUTORIAL',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
