import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../motion/app_motion.dart';
import '../../widgets/app_icon_image.dart';
import '../../../features/unlocks/tour/tour_target.dart';
import '../../../features/unlocks/widgets/unlock_badges.dart';
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

  /// Tab indexes that haven't unlocked yet, and ones whose tour is waiting.
  final Set<int> locked;
  final Set<int> fresh;

  const ShellTabBar({
    super.key,
    required this.currentIndex,
    required this.mapOpen,
    required this.onTab,
    this.locked = const {},
    this.fresh = const {},
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
            locked: locked.contains(1),
            fresh: fresh.contains(1),
            targetId: 'slot.gear',
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
            locked: locked.contains(3),
            fresh: fresh.contains(3),
            targetId: 'slot.modes',
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
  final bool locked;
  final bool fresh;
  final String? targetId;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.iconAsset,
    required this.active,
    required this.onTap,
    this.locked = false,
    this.fresh = false,
    this.targetId,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.blue;
    const inactiveColor = Color(0xFF6E84B0);
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        AppIconImage(iconAsset, size: 24, opacity: active ? 1 : .55),
        if (locked)
          const Positioned(top: -6, right: -14, child: LockBadge(size: 16)),
        if (fresh && !locked)
          const Positioned(top: -8, right: -22, child: NewPill()),
      ],
    );
    Widget tab = AppPressable(
      haptic: AppHaptic.selection,
      onTap: onTap,
      child: Opacity(
        opacity: locked ? .35 : 1,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (targetId != null)
                TourTarget(id: targetId!, child: icon)
              else
                icon,
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
    );
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: locked ? '$label, locked' : label,
        child: tab,
      ),
    );
  }
}
