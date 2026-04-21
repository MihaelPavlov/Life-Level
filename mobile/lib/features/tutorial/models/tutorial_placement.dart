import 'package:flutter/material.dart';

/// Four deterministic placements for the floating bubble, chosen from the
/// target rect + screen size. See the 4-case algorithm in the plan.
enum BubblePlacement {
  /// Bubble above target, centered horizontally, tail points down-center.
  above,

  /// Bubble below target, centered horizontally, tail points up-center.
  below,

  /// Bubble above target but shifted left so it doesn't run off-screen —
  /// tail anchored toward the right edge of the bubble (for edge-hugging
  /// nav-tab-style targets).
  aboveRightOffset,

  /// Bubble above the center-bottom FAB with a larger gap (clears the FAB
  /// ring). Tail centered on bottom.
  aboveFab,
}

/// Chooses one of the four placements for a target rect on a given screen.
///
/// Mirrors the algorithm documented in `humming-enchanting-flask.md`:
///   - FAB case: narrow target near screen horizontal center, near bottom.
///   - Edge-hugging: target hugs the right edge and is narrow (e.g. Map tab).
///   - Plenty of room above and wide enough target → above.
///   - Fallback → below.
BubblePlacement choosePlacement(Rect target, Size screen) {
  final spaceAbove = target.top;

  // FAB case: center-bottom, narrow, near the nav bar.
  final bool isFabLike = target.width < 80 &&
      target.center.dx > screen.width * 0.4 &&
      target.center.dx < screen.width * 0.6 &&
      target.top > screen.height * 0.7;
  if (isFabLike) return BubblePlacement.aboveFab;

  // Edge-hugging target (e.g. Map nav tab sitting in the bottom-right corner).
  final bool isRightEdge =
      target.right > screen.width - 80 && target.width < 100;
  if (isRightEdge) return BubblePlacement.aboveRightOffset;

  // Tall target with plenty of room above.
  if (spaceAbove > 280 && target.width >= 120) return BubblePlacement.above;

  // Default: below.
  return BubblePlacement.below;
}
