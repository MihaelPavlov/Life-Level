import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';

/// A painted banner for one game mode: art on the left, a kicker and title
/// on the right, reward tiles, a status strip in the corner and an alert
/// badge when something is ready.
class ModeBanner extends StatelessWidget {
  final String art;
  final Color accent;
  final Color border;
  final String kicker;
  final Color kickerColor;
  final String title;
  final List<ModeRewardTile> rewards;
  final String footerIcon;
  final Widget footer;
  final bool alert;
  final VoidCallback onTap;

  const ModeBanner({
    super.key,
    required this.art,
    required this.accent,
    required this.border,
    required this.kicker,
    required this.kickerColor,
    required this.title,
    required this.rewards,
    required this.footerIcon,
    required this.footer,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: AppPressable(
        onTap: onTap,
        pressedScale: .97,
        child: Container(
          height: 142,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .45),
                offset: const Offset(0, 6),
              ),
              BoxShadow(color: accent.withValues(alpha: .28), blurRadius: 24),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(art,
                    fit: BoxFit.cover, alignment: Alignment.centerLeft),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: .82),
                      ],
                      stops: const [.2, .62],
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(kicker,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: kickerColor,
                            shadows: _shadow,
                          )),
                      Text(title,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            shadows: _shadow,
                          )),
                    ],
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 70,
                  child: Row(
                    children: [
                      for (var i = 0; i < rewards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        rewards[i],
                      ],
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 5, 14, 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .72),
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIconImage(footerIcon, size: 16),
                        const SizedBox(width: 6),
                        footer,
                      ],
                    ),
                  ),
                ),
                if (alert)
                  const Positioned(right: 6, top: 6, child: _AlertBadge()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _shadow = [
    Shadow(color: Color(0xB3000000), offset: Offset(0, 2)),
  ];
}

/// "Label: value" text for a banner's status strip.
class ModeFooterText extends StatelessWidget {
  final String label;
  final String? value;
  final Color valueColor;

  const ModeFooterText(this.label,
      {super.key, this.value, this.valueColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          text: label,
          children: [
            if (value != null)
              TextSpan(text: value, style: TextStyle(color: valueColor)),
          ],
        ),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      );
}

/// Square reward preview on a banner.
class ModeRewardTile extends StatelessWidget {
  final String icon;
  final Color color;

  const ModeRewardTile({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color.lerp(color, Colors.black, .82),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: AppIconImage(icon, size: 26),
      );
}

/// Placeholder for modes that aren't built yet.
class ModeComingSoonCard extends StatelessWidget {
  const ModeComingSoonCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 118,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text('?',
                    style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted)),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              color: Colors.black.withValues(alpha: .3),
              child: const Text(
                'More modes coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Same red "!" as the Adventure Hub tiles.
class _AlertBadge extends StatelessWidget {
  const _AlertBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: .5),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('!',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            )),
      );
}
