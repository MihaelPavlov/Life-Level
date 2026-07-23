import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BossIcon extends StatelessWidget {
  final String icon;
  final double size;
  final double emojiSize;
  final double opacity;
  final double visualScale;
  final Offset visualOffset;

  const BossIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.emojiSize,
    this.opacity = 1,
    this.visualScale = 1,
    this.visualOffset = Offset.zero,
  });

  bool get _isAssetPath => icon.startsWith('assets/');
  bool get _isSvg => icon.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final rawChild = _isAssetPath
        ? _isSvg
            ? SvgPicture.asset(
                icon,
                width: size,
                height: size,
                fit: BoxFit.contain,
              )
            : Image.asset(
                icon,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              )
        : Text(icon, style: TextStyle(fontSize: emojiSize));
    final child = Transform.scale(
      scale: visualScale,
      alignment: Alignment.center,
      child: Transform.translate(offset: visualOffset, child: rawChild),
    );

    if (opacity >= 1) return child;
    return Opacity(opacity: opacity, child: child);
  }
}
