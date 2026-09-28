import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../../core/widgets/currency_chip.dart';
import '../../../core/widgets/resource_info_dialog.dart';
import '../../character/models/character_profile.dart';
import '../../activity/providers/activity_provider.dart';
import '../../gear/widgets/gear_paperdoll.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';
import '../../shop/shop_screen.dart';
import '../../streak/providers/streak_provider.dart';
import '../providers/world_progress_provider.dart';
import '../widgets/home_avatar_ring.dart';

/// Painted hero panel: header (avatar/name/XP/currency chips) + night-forest
/// scene + character flanked by MOUNT / WEAPON mini-cards + POWER/Run/Shields
/// — all painted over ONE continuous background image that runs from the
/// very top of the screen down through the character, instead of the header
/// sitting on a flat page background above a separate bordered card.
///
/// The character uses the same equipment-aware paper doll as the Gear screen.
/// Mount/Weapon mini-card art remains static because those concepts are not
/// represented in the domain yet. Run/Shields and the header currencies are
/// wired to real data.
class HomeHeroStage extends ConsumerWidget {
  final CharacterProfile? profile;
  const HomeHeroStage({super.key, this.profile});

  static const _refW = 366.0;
  static const _bodyRefH = 320.0;

  // How far the background art bleeds *past* the panel's natural bottom
  // edge, into the space behind the Adventure Hub section below. Fading the
  // image out over this extra stretch (instead of forcing the fade to
  // finish exactly at the panel's own boundary) means there's no single y
  // where "the gradient ends" lines up with a widget seam — the classic
  // cause of a visible edge even when the colours technically match.
  static const _bleed = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final coins = p?.talents?.coins ?? 0;
    final pendingKm = ref
            .watch(worldProgressProvider)
            .valueOrNull
            ?.userProgress
            .pendingDistanceKm ??
        0.0;
    final shields =
        ref.watch(streakProvider).valueOrNull?.shieldsAvailable ?? 0;
    final equipment = ref.watch(equipmentProvider).valueOrNull;
    final totalSteps =
        ref.watch(activitySummaryProvider).valueOrNull?.totalSteps;
    final bankedDim = pendingKm <= 0.001;
    final topPad = MediaQuery.of(context).padding.top;

    return LayoutBuilder(
      builder: (context, outer) {
        final fullW = outer.maxWidth;
        final bodyW = fullW - 32;
        final bodyH = bodyW * _bodyRefH / _refW;
        const headerRowH = 46.0;
        final panelH = topPad + 12 + headerRowH + 8 + bodyH + 14;

        return Container(
          color: AppColors.backgroundAlt,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── painted scene, bleeding past the panel's own bottom so
              // its fade-out resolves inside the Adventure Hub's margin
              // instead of stopping dead at the panel edge ────────────────
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: panelH + _bleed,
                child: IgnorePointer(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // Fully opaque through the scene + circle + character,
                      // then one long, smooth fade of the image's OWN alpha
                      // (not a black overlay) down to nothing — so what's
                      // revealed underneath is exactly the flat page
                      // background colour, not an intermediate black band.
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.72, 1.0],
                    ).createShader(rect),
                    child: Image.asset(AppIcons.homeSceneBg, fit: BoxFit.cover),
                  ),
                ),
              ),
              // Separate, small top-only darkening for header text contrast
              // — unrelated to the bottom fade above.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: panelH,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.18, 0.32],
                      ),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  SizedBox(height: topPad + 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _HeaderRow(
                      profile: p,
                      coins: coins,
                      totalSteps: totalSteps,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: AspectRatio(
                      aspectRatio: _refW / _bodyRefH,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          double px(double v) => v / _refW * w;
                          double py(double v) => v / _bodyRefH * h;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ── MOUNT mini-card (left) ──────────────────
                              Positioned(
                                left: px(4),
                                top: py(46),
                                child: _MiniCard(
                                  key: const ValueKey('home-mount-button'),
                                  size: px(72),
                                  semanticsLabel: 'Open gear from mount',
                                  onTap: () => NavTabNotifier.switchTo('gear'),
                                  icon: Image.asset(AppIcons.homeMountIcon,
                                      fit: BoxFit.contain),
                                ),
                              ),

                              // ── WEAPON mini-card (right) ────────────────
                              Positioned(
                                right: px(4),
                                top: py(46),
                                child: _MiniCard(
                                  key: const ValueKey('home-weapon-button'),
                                  size: px(72),
                                  semanticsLabel: 'Open gear from weapon',
                                  onTap: () => NavTabNotifier.switchTo('gear'),
                                  icon: Image.asset(AppIcons.homeSwordIcon,
                                      fit: BoxFit.contain),
                                ),
                              ),

                              // ── equipped character (floating+breathing) ──
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: py(20),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: _FloatingCharacter(
                                    equipment: equipment,
                                    height: py(258),
                                  ),
                                ),
                              ),

                              // ── POWER (icon + score) ────────────────────
                              // Server-computed (CombatStatsCalculator, from
                              // core stats + equipped gear + talents).
                              Positioned(
                                left: px(4),
                                bottom: py(12),
                                child: Semantics(
                                  button: true,
                                  label: 'Power information',
                                  child: GestureDetector(
                                    key: const ValueKey('home-power-button'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _showPower(context),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(AppIcons.homePowerIcon,
                                            width: px(32),
                                            height: px(32),
                                            fit: BoxFit.contain),
                                        SizedBox(width: px(6)),
                                        Text(
                                          _fmtPower(p?.power ?? 0),
                                          style: TextStyle(
                                            fontSize: px(22),
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                            color: AppColors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // ── Run / Shields chips (real data) ─────────
                              Positioned(
                                right: px(4),
                                bottom: py(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _StatChip(
                                      key: const ValueKey(
                                          'home-banked-distance-button'),
                                      iconAsset: AppIcons.mapCurrentLocation,
                                      label: bankedDim ? 'RUN' : 'BANKED',
                                      value: bankedDim
                                          ? '—'
                                          : '${pendingKm.toStringAsFixed(1)} km',
                                      onTap: () => _showBankedDistance(context),
                                    ),
                                    SizedBox(width: px(7)),
                                    _StatChip(
                                      key:
                                          const ValueKey('home-shields-button'),
                                      iconAsset: AppIcons.rewardStreakShield,
                                      label: 'SHIELDS',
                                      value: '$shields',
                                      onTap: () => _showShields(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final CharacterProfile? profile;
  final int coins;
  final int? totalSteps;
  const _HeaderRow({
    required this.profile,
    required this.coins,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'Open profile',
          child: GestureDetector(
            key: const ValueKey('home-profile-button'),
            behavior: HitTestBehavior.opaque,
            onTap: () => NavTabNotifier.switchTo('profile'),
            child: HomeAvatarRing(
              emoji: p?.avatarEmoji ?? '🧙',
              level: p?.level ?? 1,
              xpProgress: p?.xpProgress ?? 0.0,
              size: 46,
              showLevelPill: false,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      p?.username ?? '…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.purple],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'LV ${p?.level ?? 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        CurrencyChip(
          key: const ValueKey('home-steps-button'),
          iconAsset: AppIcons.homeStepsIcon,
          value: totalSteps == null ? '—' : _fmtPower(totalSteps!),
          showAdd: false,
          onTapAdd: () => _showSteps(context),
        ),
        const SizedBox(width: 6),
        CurrencyChip(
          iconAsset: AppIcons.homeCoinIcon,
          value: '$coins',
          onTapAdd: () => _openShop(context),
        ),
        const SizedBox(width: 6),
        CurrencyChip(
          iconAsset: AppIcons.homeGemIcon,
          value: '${p?.talents?.crystals ?? 0}',
          onTapAdd: () => _openShop(context),
        ),
      ],
    );
  }
}

void _openShop(BuildContext context) {
  Navigator.of(context).push(AppRoute(builder: (_) => const ShopScreen()));
}

void _showSteps(BuildContext context) {
  showResourceInfoDialog(
    context,
    const ResourceInfoData(
      name: 'Steps',
      icon: AppIcons.homeStepsIcon,
      description:
          'All steps recorded across your logged and synced activities.',
      destination: 'Activity tracking',
    ),
  );
}

void _showPower(BuildContext context) {
  showResourceInfoDialog(
    context,
    const ResourceInfoData(
      name: 'Power',
      icon: AppIcons.homePowerIcon,
      description:
          'Your overall combat strength, calculated from character stats, equipped gear, and talents.',
      destination: 'Combat',
    ),
  );
}

void _showBankedDistance(BuildContext context) {
  showResourceInfoDialog(
    context,
    const ResourceInfoData(
      name: 'Banked Distance',
      icon: AppIcons.mapCurrentLocation,
      description:
          'Distance saved from your activities and ready to advance your journey.',
      destination: 'World map',
    ),
  );
}

void _showShields(BuildContext context) {
  showResourceInfoDialog(
    context,
    const ResourceInfoData(
      name: 'Streak Shields',
      icon: AppIcons.rewardStreakShield,
      description: 'Protects an active streak when you miss an eligible day.',
      destination: 'Streak protection',
    ),
  );
}

class _MiniCard extends StatelessWidget {
  final double size;
  final Widget icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _MiniCard({
    super.key,
    required this.size,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: const Color(0xFF7DB6FF), width: 1.2),
                borderRadius: BorderRadius.circular(size * 0.16),
              ),
              child: icon,
            ),
            // Decorative swap affordance — matches the reference art; no
            // render-swap feature exists yet, so it's non-interactive.
            Positioned(
              top: -size * 0.14,
              right: -size * 0.14,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0c1420),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Icon(Icons.autorenew,
                    size: size * 0.18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatChip({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(iconAsset,
                    width: 12, height: 12, fit: BoxFit.contain),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCharacter extends StatefulWidget {
  final CharacterEquipmentResponse? equipment;
  final double height;
  const _FloatingCharacter({required this.equipment, required this.height});

  @override
  State<_FloatingCharacter> createState() => _FloatingCharacterState();
}

class _FloatingCharacterState extends State<_FloatingCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _dy;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _dy = Tween<double>(begin: 0, end: -4)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_c);
    // Subtle breathing: a gentle scale pulse riding the same cycle as the
    // float so the character reads as alive, not just bobbing.
    _scale = Tween<double>(begin: 0.985, end: 1.015)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _dy.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.equipment == null
          ? Image.asset(
              AppIcons.gearBaseRender,
              height: widget.height,
              fit: BoxFit.contain,
            )
          : GearPaperDoll(
              key: const ValueKey('home-equipped-hero'),
              equipment: widget.equipment!,
              height: widget.height,
            ),
    );
  }
}

/// Thousand-separated integer, e.g. `1240` → `"1,240"`.
String _fmtPower(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
