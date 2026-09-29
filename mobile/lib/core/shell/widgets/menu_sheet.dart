import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../motion/app_motion.dart';
import '../../widgets/app_icon_image.dart';

/// One tile in the Menu sheet.
class MenuEntry {
  final String id;
  final String label;
  final String? iconAsset;
  final IconData? icon;
  const MenuEntry(this.id, this.label, {this.iconAsset, this.icon});
}

/// Everything that used to live in the radial ring, plus a few shortcuts.
/// Ids are handled by the shell's `_openFeature`.
const kMenuEntries = [
  MenuEntry('world', 'World map', iconAsset: AppIcons.ringWorld),
  MenuEntry('boss', 'Bosses', iconAsset: AppIcons.ringBoss),
  MenuEntry('guild', 'Guild', iconAsset: AppIcons.ringGuild),
  MenuEntry('achievements', 'Achievements', iconAsset: AppIcons.rankChampion),
  MenuEntry('talents', 'Talents', iconAsset: AppIcons.talentCrystalIcon),
  MenuEntry('titles', 'Titles', iconAsset: AppIcons.ringTitles),
  MenuEntry('season', 'Season', iconAsset: AppIcons.seasonAdventureHub),
  MenuEntry('chests', 'Region Chests', iconAsset: AppIcons.regionChestsHubIcon),
  MenuEntry('rewards', 'Rewards', iconAsset: AppIcons.rewardDailyBonus),
  MenuEntry('log', 'Log workout', icon: Icons.add_rounded),
];

/// Opens the Menu sheet; resolves with the chosen entry id, or null.
Future<String?> showMenuSheet(BuildContext context) {
  return showAppBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const MenuSheet(),
  );
}

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A4A5A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Everything else',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 14,
              crossAxisSpacing: 6,
              childAspectRatio: .82,
              children: [
                for (final (i, e) in kMenuEntries.indexed)
                  _MenuTile(entry: e, index: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuEntry entry;
  final int index;
  const _MenuTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final tile = Semantics(
      button: true,
      label: entry.label,
      child: AppPressable(
        haptic: AppHaptic.selection,
        onTap: () => Navigator.of(context).pop(entry.id),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: entry.iconAsset != null
                  ? AppIconImage(entry.iconAsset!, size: 30)
                  : Icon(entry.icon, size: 28, color: AppColors.blue),
            ),
            const SizedBox(height: 6),
            Text(
              entry.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    if (!AppMotion.allowsDecorativeMotion(context)) return tile;
    // Tiles settle in one after another.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + index * 30),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child:
            Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: tile,
    );
  }
}
