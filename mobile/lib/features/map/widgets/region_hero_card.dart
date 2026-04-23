import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';
import 'region_status_chip.dart';
import 'world_map_theme.dart';

/// Large tappable region card rendered on the world hub.
/// Mirrors `.wv3-region` from the v3 mockup: banner + emoji + status chip,
/// lore, progress bar, pins, and CTA row.
class RegionHeroCard extends StatelessWidget {
  final RegionCard region;
  final int userLevel;
  final VoidCallback? onTap;

  const RegionHeroCard({
    super.key,
    required this.region,
    required this.userLevel,
    this.onTap,
  });

  bool get _locked => region.status == RegionStatus.locked;

  @override
  Widget build(BuildContext context) {
    final theme = RegionThemeColors.of(region.theme);
    final borderColor = region.status == RegionStatus.active
        ? theme.accent.withOpacity(0.5)
        : AppColors.border;

    return Opacity(
      opacity: _locked ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: region.status == RegionStatus.active
                ? [
                    BoxShadow(
                      color: theme.accent.withOpacity(0.14),
                      blurRadius: 28,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Banner(
                    region: region, theme: theme, userLevel: userLevel),
                _Body(region: region, userLevel: userLevel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final RegionCard region;
  final RegionThemeColors theme;
  final int userLevel;
  const _Banner({
    required this.region,
    required this.theme,
    required this.userLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.bannerGradient,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Text(
                region.emoji,
                style: const TextStyle(fontSize: 40, height: 1),
              ),
              const Spacer(),
              _StatusBadge(region: region, userLevel: userLevel),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Pins(region: region, userLevel: userLevel),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RegionCard region;
  final int userLevel;
  const _StatusBadge({required this.region, required this.userLevel});

  @override
  Widget build(BuildContext context) {
    switch (region.status) {
      case RegionStatus.active:
        return const RegionStatusChip.active();
      case RegionStatus.completed:
        return const RegionStatusChip.completed();
      case RegionStatus.locked:
        return RegionStatusChip.locked(
          label: '🔒 Lv ${region.levelRequirement}',
        );
    }
  }
}

class _Pins extends StatelessWidget {
  final RegionCard region;
  final int userLevel;
  const _Pins({required this.region, required this.userLevel});

  @override
  Widget build(BuildContext context) {
    final pins = <Widget>[];
    // Pull pins from the API first — max 2 to keep the banner readable.
    for (final p in region.pins.take(2)) {
      pins.add(_pinChip(
        '${p.label} · ${p.value}',
        active: region.status == RegionStatus.active,
      ));
    }
    // Fallback cosmetic pins when the API gives us nothing — keeps the
    // banner from looking empty on the 11 minor regions.
    if (pins.isEmpty) {
      if (region.status == RegionStatus.locked) {
        pins.add(_pinChip('🔒 Unlock at Lv ${region.levelRequirement}'));
      } else {
        pins.add(_pinChip('🗝 ${region.totalZones} zones'));
      }
    }
    return Row(children: [
      for (final p in pins) Padding(padding: const EdgeInsets.only(right: 4), child: p),
    ]);
  }

  Widget _pinChip(String label, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.blue.withOpacity(0.45)
            : Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: active
              ? AppColors.blue.withOpacity(0.55)
              : Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final RegionCard region;
  final int userLevel;
  const _Body({required this.region, required this.userLevel});

  @override
  Widget build(BuildContext context) {
    final locked = region.status == RegionStatus.locked;
    final unlockProgress = locked
        ? (userLevel / region.levelRequirement).clamp(0.0, 1.0)
        : region.progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            region.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            region.lore,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _BarRow(
            leftLabel: locked ? 'Unlock progress' : 'Progress',
            rightLabel: locked
                ? 'Lv $userLevel / ${region.levelRequirement}'
                : region.status == RegionStatus.completed
                    ? '${region.completedZones} / ${region.totalZones} · ✓'
                    : '${region.completedZones} / ${region.totalZones} zones',
          ),
          const SizedBox(height: 6),
          _ProgressBar(
            value: unlockProgress,
            color: locked ? AppColors.orange : AppColors.green,
          ),
          const SizedBox(height: 12),
          _CtaRow(region: region, userLevel: userLevel),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  const _BarRow({required this.leftLabel, required this.rightLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          leftLabel.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          rightLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.hardEdge,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _CtaRow extends StatelessWidget {
  final RegionCard region;
  final int userLevel;
  const _CtaRow({required this.region, required this.userLevel});

  @override
  Widget build(BuildContext context) {
    final meta = _metaText();
    final buttonText = _buttonText();
    final buttonStyle = _buttonStyle();

    return Row(
      children: [
        Expanded(
          child: Text(
            meta,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.04,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: buttonStyle,
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _metaText() {
    switch (region.status) {
      case RegionStatus.active:
        final xpBit = region.totalXpEarned > 0
            ? '+${region.totalXpEarned} XP'
            : 'New region';
        final bossBit = region.zonesUntilBoss != null && region.zonesUntilBoss! > 0
            ? '${region.zonesUntilBoss} zones to boss'
            : region.bossStatus == RegionBossStatus.defeated
                ? '${region.bossName} defeated'
                : '${region.bossName} awaits';
        return '$xpBit · $bossBit';
      case RegionStatus.completed:
        return 'Rewards cleared · revisit anytime';
      case RegionStatus.locked:
        final gap = region.levelRequirement - userLevel;
        if (gap <= 0) return 'Unlock available';
        return '$gap levels to go';
    }
  }

  String _buttonText() {
    switch (region.status) {
      case RegionStatus.active:
        return 'Enter →';
      case RegionStatus.completed:
        return 'Revisit →';
      case RegionStatus.locked:
        return '🔒 Locked';
    }
  }

  BoxDecoration _buttonStyle() {
    switch (region.status) {
      case RegionStatus.active:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.green, Color(0xFF2ea043)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.green.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withOpacity(0.3),
              blurRadius: 14,
            ),
          ],
        );
      case RegionStatus.completed:
        return BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        );
      case RegionStatus.locked:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        );
    }
  }
}
