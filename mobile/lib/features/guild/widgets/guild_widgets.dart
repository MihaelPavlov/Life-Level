import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../boss/widgets/boss_icon.dart';

/// Shared building blocks for the redesigned Guild screens: banner crest,
/// top bar, panels, pills, HP bar, avatars and form fields.

const kGuildPanelTop = Color(0xFF0e192b);
const kGuildPanelBottom = Color(0xFF0a1220);
const kGuildLine = Color(0xFF223250);
const kGuildLineStrong = Color(0xFF2c4266);
const kGuildGold = Color(0xFFf5b53f);
const kGuildGoldLight = Color(0xFFffd98a);
const kGuildInk = Color(0xFF0a1322);

String guildNum(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return value < 0 ? '-$buf' : buf.toString();
}

String guildRoleLabel(String role) {
  final normalized = role.toLowerCase();
  if (normalized == 'leader') return 'Leader';
  if (normalized == 'officer') return 'Officer';
  return 'Member';
}

Color guildRoleColor(String role) {
  final normalized = role.toLowerCase();
  if (normalized == 'leader') return kGuildGold;
  if (normalized == 'officer') return AppColors.blue;
  return AppColors.textSecondary;
}

const kGuildCrestIcons = [
  'shield',
  'wolf',
  'mountain',
  'flame',
  'crown',
  'bolt'
];

IconData guildIconData(String icon) => switch (icon) {
      'wolf' => Icons.pets_rounded,
      'flame' => Icons.local_fire_department_rounded,
      'crown' => Icons.workspace_premium_rounded,
      'mountain' => Icons.landscape_rounded,
      'bolt' => Icons.bolt_rounded,
      _ => Icons.shield_rounded,
    };

class _BannerClipper extends CustomClipper<Path> {
  const _BannerClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * .86)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(0, size.height * .86)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Hanging-banner guild crest: gold frame, blue field, white glyph.
class GuildCrest extends StatelessWidget {
  final String icon;
  final double width;
  final double aspect;
  final List<Color>? colors;

  const GuildCrest({
    super.key,
    required this.icon,
    this.width = 56,
    this.aspect = 1.16,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final inset = width * .045;
    final field = colors ??
        (icon == 'flame'
            ? const [Color(0xFFe0764a), Color(0xFF7a2e12)]
            : const [Color(0xFF3b7cf0), Color(0xFF173f96)]);
    return SizedBox(
      width: width,
      height: width * aspect,
      child: ClipPath(
        clipper: const _BannerClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kGuildGoldLight, Color(0xFFb8791a)],
            ),
          ),
          padding: EdgeInsets.all(inset),
          child: ClipPath(
            clipper: const _BannerClipper(),
            child: Container(
              alignment: const Alignment(0, -.12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: field,
                ),
              ),
              child: Icon(guildIconData(icon),
                  color: Colors.white, size: width * .46),
            ),
          ),
        ),
      ),
    );
  }
}

/// Golden rod the hero banner hangs from.
class GuildRod extends StatelessWidget {
  final double width;
  const GuildRod({super.key, required this.width});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFffe29b), Color(0xFFc98a1b), Color(0xFF7a4d0a)],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      );
}

class GuildRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  const GuildRoundButton(
      {super.key, required this.icon, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: const Color(0xCC060c17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1FFFFFFF)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class GuildTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  const GuildTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          GuildRoundButton(
              icon: Icons.arrow_back_rounded, onTap: onBack, tooltip: 'Back'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFaebbd0), fontSize: 11.5),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class GuildCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final List<Color>? gradient;

  const GuildCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient ?? const [kGuildPanelTop, kGuildPanelBottom],
        ),
        border: Border.all(color: borderColor ?? kGuildLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

enum GuildButtonStyle { primary, gold, ghost, danger }

class GuildButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final GuildButtonStyle style;
  final bool expand;
  final bool compact;

  const GuildButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.style = GuildButtonStyle.primary,
    this.expand = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final (List<Color> fill, Color border, Color fg) = switch (style) {
      GuildButtonStyle.primary => (
          const [Color(0xFF2c66d0), Color(0xFF1d4696)],
          const Color(0x884f9eff),
          Colors.white,
        ),
      GuildButtonStyle.gold => (
          const [Color(0xFFf7c65a), Color(0xFFd89216)],
          const Color(0xFFffdf94),
          const Color(0xFF2a1a00),
        ),
      GuildButtonStyle.ghost => (
          const [Color(0xFF0c1424), Color(0xFF0c1424)],
          kGuildLineStrong,
          const Color(0xFFdbe6f6),
        ),
      GuildButtonStyle.danger => (
          const [Color(0xFF0c1424), Color(0xFF0c1424)],
          const Color(0x88f85149),
          const Color(0xFFff8f89),
        ),
    };
    final radius = BorderRadius.circular(compact ? 10 : 12);
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: fill,
            ),
            border: Border.all(color: border),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: compact ? 8 : 13, horizontal: compact ? 14 : 16),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: compact ? 16 : 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: compact ? 12.5 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GuildPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const GuildPill(this.label, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class GuildHpBar extends StatelessWidget {
  final double percent;
  final double height;
  const GuildHpBar({super.key, required this.percent, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF070d18),
          border: Border.all(color: const Color(0xFF3a557f)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percent.clamp(0.0, 1.0).toDouble(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF2b7bff), Color(0xFF59d2ff)]),
            ),
          ),
        ),
      ),
    );
  }
}

class GuildAvatar extends StatelessWidget {
  final String emoji;
  final String name;
  final double size;
  final bool leader;

  const GuildAvatar({
    super.key,
    required this.emoji,
    required this.name,
    this.size = 44,
    this.leader = false,
  });

  static const _palettes = [
    [Color(0xFF3a6fd8), Color(0xFF1c2f6b)],
    [Color(0xFF3fa56b), Color(0xFF15452b)],
    [Color(0xFF8a94a8), Color(0xFF39424f)],
    [Color(0xFFa371f7), Color(0xFF3b1f7a)],
    [Color(0xFFe0764a), Color(0xFF6b2a12)],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[
        name.codeUnits.fold<int>(0, (a, b) => a + b) % _palettes.length];
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette,
              ),
              border: Border.all(
                  color: leader ? kGuildGold : const Color(0x55FFFFFF),
                  width: 2),
            ),
            child: Text(
              emoji.isEmpty ? initial : emoji,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: emoji.isEmpty ? size * .36 : size * .46,
              ),
            ),
          ),
          if (leader)
            Positioned(
              top: -7,
              right: -5,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: const Color(0xFF0b1220),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x88f5b53f)),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 12, color: kGuildGold),
              ),
            ),
        ],
      ),
    );
  }
}

class GuildSectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GuildSectionHeader(
    this.title, {
    super.key,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(count!,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!,
                      style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.blue),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Framed boss portrait used on raid cards.
class GuildBossFrame extends StatelessWidget {
  final String icon;
  final double size;
  const GuildBossFrame({super.key, required this.icon, this.size = 58});

  bool get _raster =>
      icon.startsWith('assets/') && !icon.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * .24);
    // Boss portraits are opaque light-background paintings, so raster art
    // fills the frame like a bestiary plate instead of floating on the
    // tinted panel.
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0x1FF85149),
        border: Border.all(color: const Color(0x6BF85149)),
        borderRadius: radius,
      ),
      child: _raster
          ? Image.asset(icon,
              fit: BoxFit.cover, filterQuality: FilterQuality.high)
          : Center(
              child: BossIcon(
                icon: icon.isEmpty ? '?' : icon,
                size: size * .8,
                emojiSize: size * .47,
                visualScale: icon.startsWith('assets/') ? 1.2 : 1,
              ),
            ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Dashed placeholder for an unfilled guild seat.
class GuildOpenSeat extends StatelessWidget {
  final String label;
  const GuildOpenSeat({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedBorderPainter(kGuildLineStrong, 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kGuildLineStrong),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration guildInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: kGuildInk,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGuildLineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue),
      ),
    );

class GuildField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;

  const GuildField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: guildInputDecoration(hint).copyWith(counterText: ''),
        ),
      ],
    );
  }
}

class GuildLabel extends StatelessWidget {
  final String text;
  const GuildLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .9,
        ),
      );
}

class GuildInfoStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const GuildInfoStrip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GuildCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GuildMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const GuildMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

void confirmGuildAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required VoidCallback onConfirm,
}) {
  showAppDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content:
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child:
              Text(actionLabel, style: const TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
}

class GuildErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const GuildErrorView(
      {super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.red, size: 42),
            const SizedBox(height: 12),
            const Text('Guild unavailable',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
            const SizedBox(height: 18),
            GuildButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onTap: onRetry,
                expand: false),
          ],
        ),
      ),
    );
  }
}
