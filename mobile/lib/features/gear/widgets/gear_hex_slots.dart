import 'package:flutter/material.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../items/models/item_models.dart';
import '../gear_paperdoll_assets.dart';

/// Hexagon re-skin of the equipment paperdoll, arranged in the reference
/// design's 1-2-2-1 diamond layout. Same 6 slots as before (Head, Chest,
/// Hands, Feet, Accessory1, Legs) — just a different shape.
class GearHexSlots extends StatelessWidget {
  final CharacterEquipmentResponse equipment;
  final int characterLevel;
  final void Function(String slotType, ItemDto item)? onSlotTap;

  const GearHexSlots({
    super.key,
    required this.equipment,
    required this.characterLevel,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _hex('Head'),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hex('Chest'),
            const SizedBox(width: 8),
            _hex('Accessory1'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hex('Hands'),
            const SizedBox(width: 8),
            _hex('Legs'),
          ],
        ),
        const SizedBox(height: 8),
        _hex('Feet'),
      ],
    );
  }

  Widget _hex(String slotType) {
    final item = equipment.slotFor(slotType)?.item;
    return HexSlotTile(
      item: item,
      slotType: slotType,
      characterLevel: characterLevel,
      onTap: item == null || onSlotTap == null
          ? null
          : () => onSlotTap!(slotType, item),
    );
  }
}

/// A single hexagon equipment slot: item icon + rarity-coloured border/glow
/// when equipped, "+" placeholder when empty.
class HexSlotTile extends StatelessWidget {
  final ItemDto? item;
  final String? slotType;
  final int characterLevel;
  final VoidCallback? onTap;

  const HexSlotTile({
    super.key,
    this.item,
    this.slotType,
    required this.characterLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final equipped = item != null;
    final accent = equipped ? rarityColor(item!.rarity) : Colors.white24;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (equipped)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Lv.$characterLevel',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ),
          SizedBox(
            width: 64,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipPath(
                  clipper: _HexagonClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(64, 58),
                  painter: _HexagonBorderPainter(
                    color: accent,
                    strokeWidth: equipped ? 2.2 : 1.4,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: animation, curve: Curves.elasticOut),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(item?.id ?? 'empty-$slotType'),
                    child: equipped
                        ? ItemIconImage(
                            itemId: item!.id,
                            itemName: item!.name,
                            emojiFallback: item!.icon,
                            imageUrl: item!.inventoryIconUrl,
                            size: 28,
                            emojiSize: 20,
                          )
                        : _EmptySlotIcon(slotType: slotType),
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

/// Empty-slot placeholder: the confirmed default art for that slot type when
/// one exists (Chest/Legs/Feet/Accessory1/Hands), else the plain "+" (Head).
class _EmptySlotIcon extends StatelessWidget {
  final String? slotType;
  const _EmptySlotIcon({this.slotType});

  @override
  Widget build(BuildContext context) {
    final asset = slotType == null ? null : gearSlotDefaultIcon(slotType!);
    if (asset == null) {
      return const Icon(Icons.add, size: 20, color: Colors.white38);
    }
    return Opacity(
      opacity: 0.55,
      child: Image.asset(asset, width: 26, height: 26, fit: BoxFit.contain),
    );
  }
}

// Flat-top hexagon: horizontal top/bottom edges, pointed left/right corners.
Path _hexagonPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * 0.26, 0)
    ..lineTo(w * 0.74, 0)
    ..lineTo(w, h * 0.5)
    ..lineTo(w * 0.74, h)
    ..lineTo(w * 0.26, h)
    ..lineTo(0, h * 0.5)
    ..close();
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _hexagonPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _HexagonBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(_hexagonPath(size), paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
