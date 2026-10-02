import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/unlock_catalog.dart';

/// Small round padlock pinned to the corner of a locked slot.
class LockBadge extends StatelessWidget {
  final double size;
  const LockBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1017),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(Icons.lock_rounded,
          size: size * .55, color: AppColors.textSecondary),
    );
  }
}

/// Orange "NEW" pill on a slot whose tour hasn't run yet. Pulses gently.
class NewPill extends StatefulWidget {
  const NewPill({super.key});

  @override
  State<NewPill> createState() => _NewPillState();
}

class _NewPillState extends State<NewPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.allowsDecorativeMotion(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.12)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
                color: AppColors.orange.withValues(alpha: .7), blurRadius: 10),
          ],
        ),
        child: const Text('NEW',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
                color: AppColors.background)),
      ),
    );
  }
}

/// Tells the player what opens a locked slot.
void showLockedHint(BuildContext context, String key) {
  final meta = kUnlockCatalog[key];
  if (meta == null) return;
  AppToast.info(context, meta.lockedHint, icon: Icons.lock_rounded);
}
