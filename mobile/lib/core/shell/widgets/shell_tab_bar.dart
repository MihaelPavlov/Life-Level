import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../motion/app_motion.dart';
import '../../widgets/app_icon_image.dart';
import '../shell_constants.dart';

/// Width of the gap in the middle of the bar that the Map button sits in.
const kMapSlotWidth = 96.0;

/// Home · Gear · [Map button] · Mode · Profile.
///
/// The Map button itself is drawn by the shell above this bar (it is
/// raised), so the middle slot only holds its "Map" caption.
class ShellTabBar extends StatelessWidget {
  /// 0 Home, 1 Gear, 2 Profile, 3 Mode.
  final int currentIndex;
  final bool mapOpen;
  final ValueChanged<int> onTab;

  const ShellTabBar({
    super.key,
    required this.currentIndex,
    required this.mapOpen,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kNavBarH,
      decoration: const BoxDecoration(
        color: kNavBg,
        border: Border(top: BorderSide(color: kNavBorder)),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Home',
            iconAsset: AppIcons.navHome,
            active: currentIndex == 0,
            onTap: () => onTab(0),
          ),
          _Tab(
            label: 'Gear',
            iconAsset: AppIcons.navGear,
            active: currentIndex == 1,
            onTap: () => onTab(1),
          ),
          SizedBox(
            width: kMapSlotWidth,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Map',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: mapOpen ? AppColors.blue : const Color(0xFF6E84B0),
                  ),
                ),
              ),
            ),
          ),
          _Tab(
            label: 'Mode',
            iconAsset: AppIcons.navMode,
            active: currentIndex == 3,
            onTap: () => onTab(3),
          ),
          _Tab(
            label: 'Profile',
            iconAsset: AppIcons.navProfile,
            active: currentIndex == 2,
            onTap: () => onTab(2),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool active;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.iconAsset,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.blue;
    const inactiveColor = Color(0xFF6E84B0);
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: AppPressable(
          haptic: AppHaptic.selection,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconImage(iconAsset, size: 24, opacity: active ? 1 : .55),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
