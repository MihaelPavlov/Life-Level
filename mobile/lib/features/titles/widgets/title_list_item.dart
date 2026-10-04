import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/title_rank_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/title_models.dart';

class TitleListItem extends StatefulWidget {
  final TitleDto title;
  final VoidCallback? onEquip;
  final bool isLocked;
  final bool isNew;

  /// On the title name — where the equip flight lifts off from.
  final GlobalKey? nameKey;

  /// Disables Equip while another title is mid-flight.
  final bool equipDisabled;

  const TitleListItem({
    super.key,
    required this.title,
    this.onEquip,
    this.isLocked = false,
    this.isNew = false,
    this.nameKey,
    this.equipDisabled = false,
  });

  @override
  State<TitleListItem> createState() => _TitleListItemState();
}

class _TitleListItemState extends State<TitleListItem>
    with TickerProviderStateMixin {
  // 0 = plain card, 1 = equipped (orange border, tinted icon tile).
  late final AnimationController _eq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.title.isEquipped ? 1 : 0,
  );
  // Glow pulse when this card becomes the equipped one.
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  TitleDto get title => widget.title;

  @override
  void didUpdateWidget(covariant TitleListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = widget.title.isEquipped;
    if (now == oldWidget.title.isEquipped) return;
    if (!AppMotion.isFull(context)) {
      _eq.value = now ? 1 : 0;
      return;
    }
    if (now) {
      _eq.forward();
      _pulse.forward(from: 0);
    } else {
      _eq.reverse();
    }
  }

  @override
  void dispose() {
    _eq.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Rises to 1 at 35% of the pulse, then eases back to 0.
  double get _glow {
    if (!_pulse.isAnimating) return 0;
    final t = _pulse.value;
    return t < .35 ? t / .35 : 1 - Curves.easeOut.transform((t - .35) / .65);
  }

  @override
  Widget build(BuildContext context) {
    final iconAsset = titleIconAsset(id: title.id, name: title.name);
    final badgeIn = AppMotion.duration(
        context, const Duration(milliseconds: 380),
        reduced: Duration.zero);
    final badgeOut = AppMotion.duration(
        context, const Duration(milliseconds: 200),
        reduced: Duration.zero);

    final Widget card = AnimatedBuilder(
      animation: Listenable.merge([_eq, _pulse]),
      builder: (context, child) {
        final e = Curves.easeOut.transform(_eq.value);
        final glow = _glow;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color.lerp(AppColors.border,
                  AppColors.orange.withValues(alpha: 0.6), e)!,
              width: 1.0 + .5 * e,
            ),
            boxShadow: e > 0 || glow > 0
                ? [
                    BoxShadow(
                      color: AppColors.orange
                          .withValues(alpha: 0.12 * e + 0.38 * glow),
                      blurRadius: 12 + 10 * glow,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _eq,
            builder: (context, child) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color.lerp(AppColors.surfaceElevated,
                    AppColors.orange.withValues(alpha: 0.15), _eq.value),
                borderRadius: BorderRadius.circular(10),
              ),
              child: child,
            ),
            child: Center(
              child: iconAsset != null
                  ? AppIconImage(
                      iconAsset,
                      size: 30,
                      visualScale: 1.35,
                    )
                  : Text(
                      title.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Title name + unlock condition
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.name,
                        key: widget.nameKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: badgeIn,
                      reverseDuration: badgeOut,
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: a,
                          curve: Curves.easeOutBack,
                          reverseCurve: Curves.easeIn,
                        ),
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: title.isEquipped
                          ? const Padding(
                              key: ValueKey('equipped'),
                              padding: EdgeInsets.only(left: 6),
                              child: _EquippedBadge(),
                            )
                          : const SizedBox.shrink(key: ValueKey('none')),
                    ),
                    if (widget.isNew)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('NEW',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.orange)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title.unlockCondition,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right action: equip button or lock icon
          if (widget.isLocked)
            const Icon(
              Icons.lock_outline,
              size: 18,
              color: AppColors.textSecondary,
            )
          else
            AnimatedSize(
              duration: badgeOut,
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: badgeOut,
                child: title.isEquipped
                    ? const SizedBox.shrink(key: ValueKey('none'))
                    : TextButton(
                        key: const ValueKey('equip'),
                        onPressed: widget.equipDisabled ? null : widget.onEquip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Equip',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.equipDisabled
                                ? AppColors.textSecondary
                                : AppColors.blue,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );

    if (widget.isLocked) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }
}

class _EquippedBadge extends StatelessWidget {
  const _EquippedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: const Text(
        'EQUIPPED',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.orange,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
