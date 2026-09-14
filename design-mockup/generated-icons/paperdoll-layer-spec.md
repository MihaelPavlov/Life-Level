# Paper-doll gear layer spec

How to author new equippable gear art so it drops onto the Gear page
character with zero manual alignment.

## Canvas

- **1024 × 1536 px**, transparent PNG (RGBA) — exactly the same canvas as
  `mobile/assets/Home/base_render_v2.png` (`AppIcons.gearBaseRender`), the
  character it layers onto. This is a separate render from
  `AppIcons.homeBaseRender` (used by the Home screen hero stage, different
  canvas) — don't mix them up.
- Same pose, same crop, same scale as that render. Don't crop the transparent
  margins away — the empty space *is* the alignment. Confirmed: the original
  5 test garments (`upper_body_1/2/3.png`, `long_pants.png`,
  `lower_shorts.png`) already share this exact canvas/pose and overlay
  pixel-correct with zero scaling or repositioning.

## Reference guide

`paperdoll-layer-guide.png` (this folder) is `base_render_v2.png` with the
key body lines marked:

| Line | y (fraction of 1536px height) |
|---|---|
| Shoulder line | 0.195 |
| Waist line | 0.396 |

When generating or painting a new garment, use this guide (or
`base_render_v2.png` directly) as the reference/inpainting base so the
garment lands in place on the first try, then export **only the garment
pixels** (erase the body) at the same 1024×1536 canvas — don't resize or
recenter anything afterward.

## Two files per item

1. **Icon** — a tightly-cropped product-shot render of the item alone, for
   the inventory tile grid. Existing convention: `mobile/assets/Items/
   item_<name>.png` (see any existing item for style).
2. **Layer** — the full 1024×1536 canvas file described above, for the
   on-character overlay only. Convention: `mobile/assets/Gear/
   layer_<slot>_<name>.png` (e.g. `layer_chest_tactical_raid_hoodie.png`).

## Wiring a new item into the app

Both `itemIconAsset()` (`mobile/lib/core/constants/item_icons.dart`) and
`gearOverlayAsset()` (`mobile/lib/features/gear/gear_paperdoll_assets.dart`)
currently resolve an item's art via a hardcoded switch on id/name. That's
fine for a handful of items; once the catalog grows, consider moving the
icon/layer filenames onto the `Item` entity itself (admin-panel-editable)
instead of adding a Dart case per item.
