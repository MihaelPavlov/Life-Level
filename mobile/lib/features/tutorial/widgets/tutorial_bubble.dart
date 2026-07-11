import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/tutorial_step.dart';
import 'tutorial_bubble_tail.dart';

class TutorialBubble extends StatelessWidget {
  final int stepNumber;
  final int totalSteps;
  final TutorialStepContent content;
  final List<bool> doneDots;
  final bool waiting;
  final VoidCallback? onCta;
  final String ctaLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const double bubbleMaxWidth = 320;

  const TutorialBubble({
    super.key,
    required this.stepNumber,
    required this.totalSteps,
    required this.content,
    required this.doneDots,
    required this.onNext,
    required this.onSkip,
    this.waiting = false,
    this.onCta,
    this.ctaLabel = 'GOT IT',
  });

  @override
  Widget build(BuildContext context) {
    final accent = content.accent;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: bubbleMaxWidth),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceElevated, Color(0xFF1A212C)],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BubbleMetaRow(
              accent: accent,
              stepNumber: stepNumber,
              totalSteps: totalSteps,
              doneDots: doneDots,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    border: Border.all(color: accent.withValues(alpha: 0.24)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: AppIconImage(
                      content.iconAsset,
                      size: 14,
                      visualScale: 1.45,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              content.body,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SkipButton(onPressed: onSkip),
                const Spacer(),
                if (onCta != null)
                  _NextButton(
                    accent: content.accent,
                    label: ctaLabel,
                    onPressed: onCta!,
                  )
                else if (waiting)
                  const _WaitingButton()
                else
                  _NextButton(accent: accent, onPressed: onNext),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleMetaRow extends StatelessWidget {
  final Color accent;
  final int stepNumber;
  final int totalSteps;
  final List<bool> doneDots;

  const _BubbleMetaRow({
    required this.accent,
    required this.stepNumber,
    required this.totalSteps,
    required this.doneDots,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'QUEST · $stepNumber OF $totalSteps',
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalSteps, (i) {
            final isActive = i + 1 == stepNumber;
            final isDone = i < doneDots.length && doneDots[i];
            Color c = AppColors.border;
            List<BoxShadow>? glow;
            if (isActive) {
              c = accent;
              glow = [
                BoxShadow(color: accent.withValues(alpha: 0.85), blurRadius: 6),
              ];
            } else if (isDone) {
              c = AppColors.green;
            }
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  boxShadow: glow,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'SKIP',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;
  final String label;
  const _NextButton({
    required this.accent,
    required this.onPressed,
    this.label = 'GOT IT',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, accent.withValues(alpha: 0.6)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _WaitingButton extends StatefulWidget {
  const _WaitingButton();

  @override
  State<_WaitingButton> createState() => _WaitingButtonState();
}

class _WaitingButtonState extends State<_WaitingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _blink,
            builder: (_, __) {
              return Opacity(
                opacity: 0.3 + 0.7 * _blink.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          const Text(
            'WAITING...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

typedef TutorialTailDirection = TailDirection;
