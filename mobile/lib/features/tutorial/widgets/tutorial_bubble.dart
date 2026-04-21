import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/tutorial_step.dart';
import 'tutorial_bubble_tail.dart';

/// The 290-wide speech-bubble card shown next to the current target.
/// Fixed-width layout, auto height. Tail is rendered as a sibling — this
/// widget just draws the surface + content; the overlay positions the
/// bubble and the tail separately so the tail can anchor to any edge.
class TutorialBubble extends StatelessWidget {
  /// Step index within the full flow (1..6). Used for "Quest · N of 6".
  final int stepNumber;

  /// Total step count (6 in the default flow, 1 for topic replays etc.).
  final int totalSteps;

  /// Step content — title, body, emoji, accent.
  final TutorialStepContent content;

  /// Already-seen steps for the dots indicator (lowered from controller).
  /// When a value is true the matching dot renders as "done" (green).
  final List<bool> doneDots;

  /// Disables the Next button and renders the "Waiting…" pulse instead.
  /// Used by step 4 in the first-run flow.
  final bool waiting;

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
            colors: [AppColors.surfaceElevated, Color(0xFF1a212c)],
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
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
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
                if (waiting)
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

// ── meta row (quest counter + dots) ─────────────────────────────────────────
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
          'QUEST \u00B7 $stepNumber OF $totalSteps',
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

// ── buttons ─────────────────────────────────────────────────────────────────
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
  const _NextButton({required this.accent, required this.onPressed});

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
        child: const Text(
          'GOT IT \u25B8',
          style: TextStyle(
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
          style: BorderStyle.solid,
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
            'WAITING\u2026',
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

/// Re-exported so overlay code can import the tail from the bubble file
/// without pulling a second import. The actual implementation lives in
/// `tutorial_bubble_tail.dart`.
typedef TutorialTailDirection = TailDirection;
