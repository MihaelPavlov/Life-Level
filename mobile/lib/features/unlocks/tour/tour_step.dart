import 'package:flutter/widgets.dart';

/// One stop on a guided tour: a spotlight on [targetId] and a short bubble.
class TourStep {
  final String targetId;
  final String icon;
  final String eyebrow;
  final String title;

  /// Plain text; wrap words in `**` to make them bold.
  final String body;

  /// When set, the player moves on by tapping the real widget and this
  /// label is shown instead of the Next button ("TAP CLAIM ALL").
  final String? tapLabel;

  final double pad;
  final double radius;
  final bool circular;

  /// Overrides the tour's colour for this stop.
  final Color? color;

  const TourStep({
    required this.targetId,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.tapLabel,
    this.pad = 6,
    this.radius = 18,
    this.circular = false,
    this.color,
  });

  bool get isTap => tapLabel != null;
}
