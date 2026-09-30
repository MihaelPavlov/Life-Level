import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';

// Accent palettes for the two modes.
const kBurnOrange = Color(0xFFF0883E);
const kBurnOrangeLight = Color(0xFFFFB27A);
const kBurnOrangeTop = Color(0xFFFF9D55);
const kBurnInk = Color(0xFF1D0C02);
const kGold = AppColors.orange;
const kGoldLight = Color(0xFFFFD27A);
const kGoldTop = Color(0xFFFFC24D);
const kGoldInk = Color(0xFF1A1204);
const kBody = Color(0xFFAAB4C0);

/// Full-screen page for a mode: a coloured glow at the top, a back button,
/// a small caps title and an optional chip on the right.
class ModeScaffold extends StatelessWidget {
  final String title;
  final Color glow;
  final Widget? trailing;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  const ModeScaffold({
    super.key,
    required this.title,
    required this.glow,
    required this.child,
    this.trailing,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.7),
            radius: 1.1,
            colors: [glow, const Color(0xFF0A0C12), AppColors.background],
            stops: const [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (showBack) ...[
                      ModeIconButton(
                        icon: Icons.chevron_left_rounded,
                        label: 'Back',
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          color: Color(0xFFC9D4E3),
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModeIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ModeIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 26),
      ),
    );
  }
}

/// Coin icon + amount pill.
class ModeCoinChip extends StatelessWidget {
  final String value;
  final Color color;

  const ModeCoinChip(this.value, {super.key, this.color = kGoldLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: kGold.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIconImage(AppIcons.homeCoinIcon, size: 16),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

/// The big call-to-action at the bottom of a mode screen.
class ModeCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color top;
  final Color bottom;
  final Color ink;
  final IconData? icon;
  final double height;

  const ModeCta({
    super.key,
    required this.label,
    required this.onTap,
    this.top = kGoldTop,
    this.bottom = kGold,
    this.ink = kGoldInk,
    this.icon,
    this.height = 56,
  });

  const ModeCta.blue({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 56,
  })  : top = AppColors.blue,
        bottom = AppColors.blue,
        ink = const Color(0xFF04101F);

  const ModeCta.burn({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 56,
  })  : top = kBurnOrangeTop,
        bottom = kBurnOrange,
        ink = kBurnInk;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AppPressable(
        haptic: AppHaptic.light,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : .45,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bottom.withValues(alpha: .38),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: ink, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action.
class ModeOutlineCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Widget? leading;

  const ModeOutlineCta({
    super.key,
    required this.label,
    required this.onTap,
    this.color = kGold,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppPressable(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color.lerp(color, Colors.white, .35),
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

/// Small caps label used above values and sections.
class ModeLabel extends StatelessWidget {
  final String text;
  final Color color;
  const ModeLabel(this.text, {super.key, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: color,
        ),
      );
}

/// Surface card.
class ModePanel extends StatelessWidget {
  final Widget child;
  final Color? border;
  final Color color;
  final EdgeInsetsGeometry padding;

  const ModePanel({
    super.key,
    required this.child,
    this.border,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border ?? AppColors.border),
        ),
        child: child,
      );
}

/// Art on a soft glow, used for hero images.
class ModeGlowArt extends StatelessWidget {
  final String asset;
  final Color glow;
  final double size;

  const ModeGlowArt({
    super.key,
    required this.asset,
    required this.glow,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size * 1.3,
        height: size * 1.15,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              glow.withValues(alpha: .5),
              glow.withValues(alpha: .08),
              glow.withValues(alpha: 0),
            ],
            stops: const [0, .45, .7],
          ),
        ),
        child:
            Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
      );
}

String modeFmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

String modeDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes.clamp(0, 59)}m';
}
