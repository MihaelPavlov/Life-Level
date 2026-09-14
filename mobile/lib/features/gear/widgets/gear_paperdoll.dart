import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/item_icons.dart';
import '../../items/models/item_models.dart';
import '../gear_paperdoll_assets.dart';

/// Renders the base character with equipped Legs/Chest art stacked on top.
/// Chest items without a tailored layer reuse their inventory image.
///
/// Every layer asset is authored on the exact same 1024x1536 canvas as
/// `AppIcons.gearBaseRender`, with the garment already positioned correctly
/// on the body (see `design-mockup/generated-icons/paperdoll-layer-spec.md`)
/// — so stacking them at identical size is all that's needed, no per-item
/// offset/scale calibration.
class GearPaperDoll extends StatelessWidget {
  final CharacterEquipmentResponse equipment;
  final double height;

  // The base render's own aspect ratio, so this widget's box matches
  // exactly what `Image.asset(..., height: height, fit: contain)` renders,
  // regardless of the width the parent happens to offer.
  static const _baseAspect = 1024 / 1536;

  const GearPaperDoll(
      {super.key, required this.equipment, required this.height});

  @override
  Widget build(BuildContext context) {
    final width = height * _baseAspect;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Image.asset(AppIcons.gearBaseRender,
              width: width, height: height, fit: BoxFit.fill),
          for (final slotType in gearOverlaySlotOrder)
            _layerFor(slotType, width, height),
        ],
      ),
    );
  }

  Widget _layerFor(String slotType, double width, double height) {
    final item = equipment.slotFor(slotType)?.item;
    final asset =
        item == null ? null : gearOverlayAsset(id: item.id, name: item.name);
    final gearImageUrl = item?.gearImageUrl;
    final icon = asset == null && slotType == 'Chest' && item != null
        ? itemIconAsset(id: item.id, name: item.name)
        : null;

    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        child: gearImageUrl != null && gearImageUrl.isNotEmpty
            ? Image.network(
                ApiClient.resolveMediaUrl(gearImageUrl),
                key: ValueKey('gear-$gearImageUrl'),
                width: width,
                height: height,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => asset == null
                    ? const SizedBox.shrink()
                    : Image.asset(asset,
                        width: width, height: height, fit: BoxFit.fill),
              )
            : asset != null
                ? Image.asset(
                    asset,
                    key: ValueKey(asset),
                    width: width,
                    height: height,
                    fit: BoxFit.fill,
                  )
                : icon != null
                    ? SizedBox.expand(
                        key: ValueKey('icon-$icon'),
                        child: Stack(
                          children: [
                            Positioned(
                              left: width * 0.29,
                              top: height * 0.18,
                              width: width * 0.42,
                              height: height * 0.25,
                              child: Image.asset(icon, fit: BoxFit.contain),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(key: ValueKey('empty-$slotType')),
      ),
    );
  }
}
