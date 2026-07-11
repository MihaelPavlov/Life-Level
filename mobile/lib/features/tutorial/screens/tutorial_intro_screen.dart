import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_progress_dots.dart';
import '../widgets/tutorial_skip_sheet.dart';

class TutorialIntroScreen extends ConsumerWidget {
  const TutorialIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight.isFinite
                        ? constraints.maxHeight - 46
                        : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const _FirstQuestTag(),
                      const SizedBox(height: 16),
                      const _HeroCircle(
                        asset: AppIcons.questFirst,
                        accent: AppColors.blue,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'A new adventurer arrives',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your journey has begun. Let\'s learn how training in the real world makes you stronger in this one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _PillarCard(
                        asset: AppIcons.rewardXpSparkle,
                        title: 'Train & Level Up',
                        desc: 'Workouts earn XP and raise stats',
                      ),
                      const SizedBox(height: 10),
                      const _PillarCard(
                        asset: AppIcons.mapDestination,
                        title: 'Explore the world',
                        desc: 'Distance moves you across zones',
                      ),
                      const SizedBox(height: 10),
                      const _PillarCard(
                        asset: AppIcons.ringBoss,
                        title: 'Defeat bosses',
                        desc: 'Boss fights reward gear and titles',
                      ),
                      const SizedBox(height: 18),
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
                          NavTabNotifier.switchTo('home');
                          await controller.advance();
                        },
                      ),
                      const SizedBox(height: 8),
                      _SkipLink(
                        onPressed: () async {
                          final confirmed =
                              await showTutorialSkipSheet(context);
                          if (confirmed == true) {
                            await ref.read(tutorialControllerProvider).skip();
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
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstQuestTag extends StatelessWidget {
  const _FirstQuestTag();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          border: Border.all(color: AppColors.orange.withOpacity(0.28)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'FIRST QUEST',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  final String asset;
  final Color accent;

  const _HeroCircle({required this.asset, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 108,
        height: 108,
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
          child: AppIconImage(
            asset,
            size: 60,
            visualScale: 1.55,
          ),
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final String asset;
  final String title;
  final String desc;

  const _PillarCard({
    required this.asset,
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: Center(
              child: AppIconImage(
                asset,
                size: 24,
                visualScale: 1.5,
              ),
            ),
          ),
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
            colors: [AppColors.blue, Color(0xFF2F7AD8)],
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
          'BEGIN THE QUEST',
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
