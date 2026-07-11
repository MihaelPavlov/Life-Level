import 'package:flutter/material.dart';

/// Renders generated transparent PNG icons at the same visual footprint as the
/// previous icon set while keeping the surrounding layout box unchanged.
class AppIconImage extends StatelessWidget {
  static const double defaultVisualScale = 1.6;

  final String asset;
  final double size;
  final double visualScale;
  final double? opacity;

  const AppIconImage(
    this.asset, {
    super.key,
    required this.size,
    this.visualScale = defaultVisualScale,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(
          scale: visualScale,
          alignment: Alignment.center,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );

    if (opacity == null) return image;
    return Opacity(opacity: opacity!, child: image);
  }
}
