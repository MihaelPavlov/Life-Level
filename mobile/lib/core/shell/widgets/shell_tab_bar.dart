import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../motion/app_motion.dart';
import '../../widgets/app_icon_image.dart';
import '../shell_constants.dart';

/// Width of the gap in the middle of the bar that the Map button sits in.
const kMapSlotWidth = 96.0;

/// Home · Gear · [Map button] · Profile · Menu.
///
/// The Map button itself is drawn by the shell above this bar (it is
/// raised), so the middle slot only holds its "Map" caption.
class ShellTabBar extends StatelessWidget {
  /// 0 Home, 1 Gear, 2 Profile.
  final int currentIndex;
  final bool mapOpen;
  final bool menuOpen;
  final ValueChanged<int> onTab;
  final VoidCallback onMenu;
  final Key? menuKey;

  const ShellTabBar({
    super.key,
    required this.currentIndex,
    required this.mapOpen,
    required this.menuOpen,
    required this.onTab,
    required this.onMenu,
    this.menuKey,
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
            active: currentIndex == 0 && !menuOpen,
            onTap: () => onTab(0),
          ),
          _Tab(
            label: 'Gear',
            iconAsset: AppIcons.navGear,
            active: currentIndex == 1 && !menuOpen,
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
            label: 'Profile',
            iconAsset: AppIcons.navProfile,
            active: currentIndex == 2 && !menuOpen,
            onTap: () => onTab(2),
          ),
          _Tab(
            key: menuKey,
            label: 'Menu',
            icon: Icons.grid_view_rounded,
            active: menuOpen,
            onTap: onMenu,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String? iconAsset;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const _Tab({
    super.key,
    required this.label,
    this.iconAsset,
    this.icon,
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
                if (iconAsset != null)
                  AppIconImage(iconAsset!, size: 24, opacity: active ? 1 : .55)
                else
                  Icon(icon,
                      size: 24, color: active ? activeColor : inactiveColor),
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
