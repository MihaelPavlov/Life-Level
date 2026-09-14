import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../character/providers/character_provider.dart';
import '../items/providers/items_provider.dart';
import 'widgets/gear_hex_slots.dart';
import 'widgets/gear_inventory_grid.dart';
import 'widgets/gear_outfit_mount_row.dart';
import 'widgets/gear_paperdoll.dart';
import 'widgets/gear_slot_detail_sheet.dart';
import 'widgets/gear_stats_row.dart';

/// Standalone "Gear" page — hex equipment slots + a paper-doll character
/// (base render + any equipped Legs/Chest overlay art) posed on a
/// cliff-edge background + Outfit/Mount previews + a real inventory grid
/// (see `GearInventoryGrid`). Supersedes the old Equipment/Inventory tabs
/// that used to live inside Profile. Tapping an inventory item or an
/// equipped hex slot opens the same detail sheet, which equips or unequips
/// depending on the item's current state.
class GearScreen extends ConsumerWidget {
  const GearScreen({super.key});

  // The source art (equipment_background.png) is a tall 851x1847 image whose
  // bottom half is already a gradient fading to near-black. We only display
  // a short top crop (sky + cliff), sized off screen width via this w:h
  // ratio — BoxFit.cover + Alignment.topCenter below crops away the rest —
  // so the hero stays compact and the sections below sit close to the
  // character instead of leaving a big gap.
  static const _bgAspect = 851 / 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final equipmentAsync = ref.watch(equipmentProvider);
    final equipment = equipmentAsync.valueOrNull;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.blue,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(equipmentProvider.notifier).refresh();
          ref.read(characterProfileProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, outer) {
                  final w = outer.maxWidth;
                  final heroH = w / _bgAspect;
                  return SizedBox(
                    height: heroH,
                    width: w,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            AppIcons.gearBackground,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: topPad + 10,
                          child: _CoinsPill(coins: profile?.talents?.coins ?? 0),
                        ),
                        // Character posed on the cliff-edge rock, feet
                        // resting on the flattened top of the nearest slab —
                        // nudged up and right of the crop's bottom-left
                        // corner so the feet land exactly on the rock edge.
                        Positioned(
                          left: w * 0.10,
                          top: heroH * 0.20,
                          child: equipment == null
                              ? Image.asset(
                                  AppIcons.gearBaseRender,
                                  height: heroH * 0.66,
                                  fit: BoxFit.contain,
                                )
                              : GearPaperDoll(equipment: equipment, height: heroH * 0.66),
                        ),
                        Positioned(
                          right: 14,
                          top: heroH * 0.08,
                          child: equipmentAsync.when(
                            data: (equipment) => GearHexSlots(
                              equipment: equipment,
                              characterLevel: profile?.level ?? 1,
                              onSlotTap: (slotType, item) =>
                                  showGearItemDetailSheet(
                                context,
                                ref: ref,
                                item: item,
                              ),
                            ),
                            loading: () => const SizedBox(
                              width: 64,
                              height: 220,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Transform.translate(
                // Pull the stats/outfit row up into the background's own
                // fade-to-dark so it sits close to the character with no
                // hard seam.
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile != null) GearStatsRow(profile: profile),
                      const SizedBox(height: 12),
                      const GearOutfitMountRow(),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: GearInventoryGrid(),
              ),
              // Leaves room above the shell's bottom nav bar / FAB.
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinsPill extends StatelessWidget {
  final int coins;
  const _CoinsPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppIcons.homeCoinIcon, width: 16, height: 16, fit: BoxFit.contain),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
