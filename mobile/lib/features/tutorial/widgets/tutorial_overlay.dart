import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/tutorial_placement.dart';
import '../models/tutorial_step.dart';
import '../providers/tutorial_provider.dart';
import '../tutorial_controller.dart';
import 'tutorial_bubble.dart';
import 'tutorial_bubble_tail.dart';
import 'tutorial_dim_backdrop.dart';
import 'tutorial_skip_sheet.dart';

/// Root widget rendered by `MainShell` on top of its Stack. Listens to the
/// [TutorialController], and when a bubble step is active:
///   1. Paints a full-screen dim + pulsing ring on the target rect
///   2. Positions the 290px speech-bubble above/below the target per the
///      4-case placement rule (see `tutorial_placement.dart`)
///   3. Shows an enter/exit fade-scale tween when the step changes
///   4. Flashes a `+XP` toast from the top when the controller reports a
///      pending reward after `advance()`
///
/// The overlay does NOT handle the intro/outro full-screen modals — those
/// are pushed as routes by the integration layer (`MainShell`) because
/// they're full-screen and block the shell rather than overlaying it.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterAnim;

  late final AnimationController _toastCtrl;
  late final Animation<double> _toastAnim;
  Timer? _toastClearTimer;

  TutorialStep? _lastStep;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _enterAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack);

    _toastCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _toastAnim = CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _toastClearTimer?.cancel();
    _enterCtrl.dispose();
    _toastCtrl.dispose();
    super.dispose();
  }

  void _onStepChanged() {
    _enterCtrl
      ..value = 0
      ..forward();
  }

  void _maybeShowToast(TutorialController c) {
    if (c.pendingXpReward == null) return;
    _toastCtrl.forward(from: 0);
    _toastClearTimer?.cancel();
    _toastClearTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _toastCtrl.reverse();
      c.clearPendingReward();
    });
  }

  Future<void> _handleSkip(TutorialController c) async {
    final confirmed = await showTutorialSkipSheet(context);
    if (confirmed == true) {
      await c.skip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(tutorialControllerProvider);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _buildOverlay(controller),
    );
  }

  Widget _buildOverlay(TutorialController c) {
    final step = c.step;
    // Inactive + modal steps: render nothing. Modals are handled outside.
    if (step == null ||
        step == TutorialStep.intro ||
        step == TutorialStep.outro) {
      _lastStep = step;
      return const SizedBox.shrink();
    }

    if (step != _lastStep) {
      _lastStep = step;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onStepChanged();
      });
    }

    // Kick the toast if a reward is pending.
    if (c.pendingXpReward != null && !_toastCtrl.isAnimating &&
        _toastCtrl.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeShowToast(c);
      });
    }

    final content = kTutorialStepContent[step];
    if (content == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final targetRect = c.currentTargetRect();
        final placement = c.currentPlacement(screenSize);

        // FAB + small round targets read nicer with a circular pulse ring.
        final circular = step == TutorialStep.bossFab ||
            step == TutorialStep.logActivity;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Tap on dim = no-op; users advance via the Next button.
                },
                child: TutorialDimBackdrop(
                  targetRect: targetRect,
                  accentColor: content.accent,
                  circular: circular,
                ),
              ),
            ),
            if (targetRect != null)
              _PositionedBubble(
                target: targetRect,
                screen: screenSize,
                placement: placement,
                content: content,
                stepNumber: _stepNumberFor(step),
                totalSteps: kTutorialBubbleCount,
                doneDots: _doneDotsFor(step),
                waiting: c.isActionGated,
                enterAnim: _enterAnim,
                onNext: c.advance,
                onSkip: () => _handleSkip(c),
              ),
            if (targetRect == null)
              // Fallback: center the bubble when we can't find the target —
              // avoids a broken-looking empty overlay on first frame.
              Positioned.fill(
                child: Center(
                  child: FadeTransition(
                    opacity: _enterAnim,
                    child: TutorialBubble(
                      stepNumber: _stepNumberFor(step),
                      totalSteps: kTutorialBubbleCount,
                      content: content,
                      doneDots: _doneDotsFor(step),
                      waiting: c.isActionGated,
                      onNext: c.advance,
                      onSkip: () => _handleSkip(c),
                    ),
                  ),
                ),
              ),
            if (c.pendingXpReward != null)
              _XpRewardToast(animation: _toastAnim, xp: c.pendingXpReward!),
          ],
        );
      },
    );
  }

  int _stepNumberFor(TutorialStep step) {
    switch (step) {
      case TutorialStep.xpBar:
        return 1;
      case TutorialStep.stats:
        return 2;
      case TutorialStep.quests:
        return 3;
      case TutorialStep.logActivity:
        return 4;
      case TutorialStep.mapTab:
        return 5;
      case TutorialStep.bossFab:
        return 6;
      default:
        return 1;
    }
  }

  /// 6-length bool list: `true` = dot already completed. Determines the
  /// green "done" dots in the bubble's meta row.
  List<bool> _doneDotsFor(TutorialStep step) {
    final n = _stepNumberFor(step);
    return List.generate(kTutorialBubbleCount, (i) => i < n - 1);
  }
}

// ── positioned bubble + tail ────────────────────────────────────────────────
class _PositionedBubble extends StatelessWidget {
  final Rect target;
  final Size screen;
  final BubblePlacement placement;
  final TutorialStepContent content;
  final int stepNumber;
  final int totalSteps;
  final List<bool> doneDots;
  final bool waiting;
  final Animation<double> enterAnim;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _PositionedBubble({
    required this.target,
    required this.screen,
    required this.placement,
    required this.content,
    required this.stepNumber,
    required this.totalSteps,
    required this.doneDots,
    required this.waiting,
    required this.enterAnim,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp width to min(screenWidth - 48, 320) per the plan.
    final bubbleWidth = (screen.width - 48).clamp(220.0, 320.0);
    const tailWidth = 16.0;
    const tailHeight = 10.0;
    const gap = 16.0;
    const fabGap = 24.0;

    // ── choose bubble X position ──
    // Default: center over the target, clamped to screen edges.
    double bubbleLeft;
    if (placement == BubblePlacement.aboveRightOffset) {
      // Shift left so a right-edge target (e.g. Map nav tab) stays under
      // the tail while the bubble avoids overflowing off-screen.
      bubbleLeft =
          (screen.width - bubbleWidth - 12).clamp(16.0, screen.width - 16.0);
    } else if (placement == BubblePlacement.aboveFab) {
      bubbleLeft = (screen.width - bubbleWidth) / 2;
    } else {
      bubbleLeft = target.center.dx - bubbleWidth / 2;
    }
    bubbleLeft = bubbleLeft.clamp(16.0, screen.width - bubbleWidth - 16.0);

    // ── tail direction + bubble Y ──
    late final TailDirection tailDir;
    late final double bubbleTop;
    switch (placement) {
      case BubblePlacement.below:
        tailDir = TailDirection.up;
        bubbleTop = target.bottom + gap;
        break;
      case BubblePlacement.above:
      case BubblePlacement.aboveRightOffset:
      case BubblePlacement.aboveFab:
        tailDir = TailDirection.down;
        // We don't know the bubble's rendered height until after layout,
        // so we position using a rough estimate — the bubble is allowed
        // to lay out normally and we shift it up using a FractionalTranslation
        // in the child tree.
        final extraGap = placement == BubblePlacement.aboveFab ? fabGap : gap;
        bubbleTop = target.top - extraGap;
        break;
    }

    // ── tail anchor X (global) ──
    double tailCenterX;
    if (placement == BubblePlacement.aboveRightOffset) {
      tailCenterX = target.center.dx;
    } else if (placement == BubblePlacement.aboveFab) {
      tailCenterX = screen.width / 2;
    } else {
      tailCenterX = target.center.dx;
    }
    // Constrain the tail to stay within the bubble edges (+ 12px padding).
    final tailMinX = bubbleLeft + 18;
    final tailMaxX = bubbleLeft + bubbleWidth - 18;
    tailCenterX = tailCenterX.clamp(tailMinX, tailMaxX);

    // Build the bubble + tail as a single Positioned with manual layout.
    // For "above" placements we use a Column with the tail at the bottom;
    // for "below" the tail is at the top. The bubble measures itself
    // and the whole group is offset so the tail tip touches the target.

    final bubble = TutorialBubble(
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      content: content,
      doneDots: doneDots,
      waiting: waiting,
      onNext: onNext,
      onSkip: onSkip,
    );

    final tail = TutorialBubbleTail(
      direction: tailDir,
      accentColor: content.accent,
      fillColor: const Color(0xFF1a212c),
      width: tailWidth,
      height: tailHeight,
    );

    // Compose the bubble+tail with a Stack so the tail can be positioned
    // at any X within the bubble's width (independent of content size).
    final composed = SizedBox(
      width: bubbleWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tailDir == TailDirection.up)
            _TailLane(
              width: bubbleWidth,
              tail: tail,
              tailLeftInside: tailCenterX - bubbleLeft - tailWidth / 2,
            ),
          bubble,
          if (tailDir == TailDirection.down)
            _TailLane(
              width: bubbleWidth,
              tail: tail,
              tailLeftInside: tailCenterX - bubbleLeft - tailWidth / 2,
            ),
        ],
      ),
    );

    // For "below" placements, bubbleTop is the Y of the tail's top edge.
    // For "above" placements, the whole composed widget sits above bubbleTop;
    // use FractionalTranslation(-1.0 vertical) to shift it above the target.
    Widget positioned;
    if (tailDir == TailDirection.up) {
      // Bubble below the target; the composed widget's origin = tailTopY.
      positioned = Positioned(
        left: bubbleLeft,
        top: bubbleTop - tailHeight,
        child: FadeTransition(
          opacity: enterAnim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(enterAnim),
            alignment: Alignment.topCenter,
            child: composed,
          ),
        ),
      );
    } else {
      // Bubble above the target. Translate up by 100% of its own height.
      positioned = Positioned(
        left: bubbleLeft,
        top: bubbleTop,
        child: FractionalTranslation(
          translation: const Offset(0, -1.0),
          child: FadeTransition(
            opacity: enterAnim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(enterAnim),
              alignment: Alignment.bottomCenter,
              child: composed,
            ),
          ),
        ),
      );
    }
    return positioned;
  }
}

/// Single-row container that reserves space for the tail and places it at
/// the correct X position inside the bubble's width.
class _TailLane extends StatelessWidget {
  final double width;
  final Widget tail;
  final double tailLeftInside;

  const _TailLane({
    required this.width,
    required this.tail,
    required this.tailLeftInside,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: tailLeftInside.clamp(4, width - 20).toDouble(),
            top: 0,
            child: tail,
          ),
        ],
      ),
    );
  }
}

// ── XP reward toast ─────────────────────────────────────────────────────────
class _XpRewardToast extends StatelessWidget {
  final Animation<double> animation;
  final int xp;

  const _XpRewardToast({required this.animation, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          return Center(
            child: Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, -20 + 20 * animation.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.orange, Color(0xFFe68c14)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Text(
                    '\u2728 +$xp XP',
                    style: const TextStyle(
                      color: Color(0xFF1a0f02),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
