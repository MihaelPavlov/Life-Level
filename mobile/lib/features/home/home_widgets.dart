import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─── local palette aliases (thin wrappers around AppColors) ──────────────────
const kHBgBase      = AppColors.backgroundAlt;
const kHSurface1    = AppColors.surface;
const kHSurface2    = AppColors.surfaceElevated;
const kHBorderColor = AppColors.border;
const kHBorderSoft  = AppColors.surfaceElevated;
const kHTextMuted   = AppColors.textMuted;

// ── Format helper ──────────────────────────────────────────────────────────────
String homeFmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

// ── Badge widget ───────────────────────────────────────────────────────────────
class HomeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const HomeBadge(this.label, this.color, {super.key, this.fontSize = 9.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Card container ─────────────────────────────────────────────────────────────
class HomeCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? glowColor;

  const HomeCard({super.key, required this.child, this.borderColor, this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kHSurface1,
        border: Border.all(color: borderColor ?? kHBorderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!, blurRadius: 24, spreadRadius: 0)]
            : null,
      ),
      child: child,
    );
  }
}

// ── Section title row ──────────────────────────────────────────────────────────
class HomeSectionTitle extends StatelessWidget {
  final String label;
  final String? action;
  final Color? actionColor;

  const HomeSectionTitle({super.key, required this.label, this.action, this.actionColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 1.2,
              )),
          if (action != null)
            Text(action!,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: actionColor ?? AppColors.blue,
                )),
        ],
      ),
    );
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────────
class HomeProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  final double height;

  const HomeProgressBar({super.key, required this.progress, required this.colors, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: kHSurface2),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors.length > 1 ? colors : [colors.first, colors.first],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Streak day dot ─────────────────────────────────────────────────────────────
enum HomeStreakState { done, today, next }

class HomeStreakDay extends StatelessWidget {
  final String icon;
  final String label;
  final HomeStreakState state;

  const HomeStreakDay({super.key, required this.icon, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bg, border, textColor;
    switch (state) {
      case HomeStreakState.done:
        bg = AppColors.green.withValues(alpha: 0.1);
        border = AppColors.green.withValues(alpha: 0.3);
        textColor = AppColors.green;
      case HomeStreakState.today:
        bg = AppColors.orange.withValues(alpha: 0.12);
        border = AppColors.orange.withValues(alpha: 0.5);
        textColor = AppColors.orange;
      case HomeStreakState.next:
        bg = kHSurface2;
        border = kHBorderColor;
        textColor = kHTextMuted;
    }
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12, height: 1)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ── Quest item ─────────────────────────────────────────────────────────────────
enum HomeQuestState { done, active, pending }

class HomeQuestItem extends StatelessWidget {
  final String icon;
  final HomeQuestState iconState;
  final String name;
  final String sub;
  final String xp;
  final bool done;
  final double? progress;
  final Color? progressColor;

  const HomeQuestItem({
    super.key,
    required this.icon,
    required this.iconState,
    required this.name,
    required this.sub,
    required this.xp,
    required this.done,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBg, iconBorder;
    switch (iconState) {
      case HomeQuestState.done:
        iconBg = AppColors.green.withValues(alpha: 0.1);
        iconBorder = AppColors.green.withValues(alpha: 0.3);
      case HomeQuestState.active:
        iconBg = AppColors.blue.withValues(alpha: 0.08);
        iconBorder = AppColors.blue.withValues(alpha: 0.25);
      case HomeQuestState.pending:
        iconBg = AppColors.textSecondary.withValues(alpha: 0.06);
        iconBorder = AppColors.textSecondary.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kHBorderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              border: Border.all(color: iconBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  HomeProgressBar(
                    progress: progress!,
                    colors: [progressColor ?? AppColors.blue],
                    height: 4,
                  ),
                ],
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (done)
                Text('✓', style: TextStyle(fontSize: 16, color: AppColors.green, height: 1)),
              Text(xp, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Gain chip ──────────────────────────────────────────────────────────────────
class HomeGainChip extends StatelessWidget {
  final String label;
  final Color color;

  const HomeGainChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: kHSurface2,
        border: Border.all(color: kHBorderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Stat gem ───────────────────────────────────────────────────────────────────
class HomeStatGem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const HomeStatGem({super.key, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: kHSurface1,
          border: Border.all(color: kHBorderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 1.0,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing LV badge (on avatar) ───────────────────────────────────────────────
class HomePulsingLvBadge extends StatefulWidget {
  final String label;
  const HomePulsingLvBadge({super.key, required this.label});

  @override
  State<HomePulsingLvBadge> createState() => _HomePulsingLvBadgeState();
}

class _HomePulsingLvBadgeState extends State<HomePulsingLvBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = _glow.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kHBgBase, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.25 + t * 0.25),
                blurRadius: 5 + t * 10,
                spreadRadius: 1 + t * 2,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
