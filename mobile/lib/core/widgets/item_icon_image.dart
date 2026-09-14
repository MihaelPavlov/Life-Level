import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../constants/item_icons.dart';
import 'app_icon_image.dart';

class ItemIconImage extends StatelessWidget {
  final String itemId;
  final String itemName;
  final String emojiFallback;
  final String? imageUrl;
  final double size;
  final double emojiSize;
  final double visualScale;

  const ItemIconImage({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.emojiFallback,
    this.imageUrl,
    required this.size,
    double? emojiSize,
    this.visualScale = AppIconImage.defaultVisualScale,
  }) : emojiSize = emojiSize ?? size * 0.45;

  @override
  Widget build(BuildContext context) {
    final asset = itemIconAsset(id: itemId, name: itemName);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.scale(
            scale: visualScale,
            alignment: Alignment.center,
            child: Image.network(
              ApiClient.resolveMediaUrl(imageUrl!),
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => _fallback(asset),
            ),
          ),
        ),
      );
    }
    if (asset == null) return _EmojiIcon(emojiFallback, size: emojiSize);

    return SizedBox(
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
            errorBuilder: (_, __, ___) => _fallback(null),
          ),
        ),
      ),
    );
  }

  Widget _fallback(String? asset) {
    if (asset == null) {
      return Transform.scale(
        scale: 1 / visualScale,
        child: _EmojiIcon(emojiFallback, size: emojiSize),
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _EmojiIcon(emojiFallback, size: emojiSize),
    );
  }
}

class _EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;

  const _EmojiIcon(this.emoji, {required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji.isEmpty ? '?' : emoji,
      style: TextStyle(fontSize: size),
    );
  }
}
