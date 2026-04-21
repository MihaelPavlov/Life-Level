import 'package:flutter/material.dart';
import '../shell_constants.dart';
import '../shell_models.dart';

class ShellNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavTab> navTabs;
  final ValueChanged<int> onTap;
  final Map<String, GlobalKey>? keysByTabId;
  const ShellNavBar({
    super.key,
    required this.currentIndex,
    required this.navTabs,
    required this.onTap,
    this.keysByTabId,
  });

  @override
  Widget build(BuildContext context) {
    // Split tabs around the FAB gap (left half, right half).
    final half  = navTabs.length ~/ 2;
    final left  = navTabs.sublist(0, half);
    final right = navTabs.sublist(half);

    return Container(
      height: kNavBarH,
      decoration: const BoxDecoration(
        color: kNavBg,
        border: Border(top: BorderSide(color: kNavBorder)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < left.length; i++)
            ShellNavItem(
              key: keysByTabId?[left[i].id],
              tab: left[i],
              active: currentIndex == i,
              onTap: () => onTap(i),
            ),
          const Expanded(child: SizedBox()),
          for (int i = 0; i < right.length; i++)
            ShellNavItem(
              key: keysByTabId?[right[i].id],
              tab: right[i],
              active: currentIndex == half + i,
              onTap: () => onTap(half + i),
            ),
        ],
      ),
    );
  }
}

class ShellNavItem extends StatelessWidget {
  final NavTab tab;
  final bool active;
  final VoidCallback onTap;
  const ShellNavItem({
    super.key,
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor   = Color(0xFF4f9eff);
    const inactiveColor = Color(0xFF6e84b0);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tab.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(tab.label,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? activeColor : inactiveColor)),
            ],
          ),
        ),
      ),
    );
  }
}
