import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/profile/widgets/equipment_slot_tile.dart' show rarityColor;

// ── constants matching home_screen palette ────────────────────────────────────
const _surface1 = Color(0xFF161b22);

/// Shows the full-screen level-up overlay as a dialog route.
/// [level] is the new level the player reached. [unlocks] carries real
/// per-level rewards (items, zones, stat points); when null or empty,
/// the overlay renders a neutral fallback message.
void showLevelUpScreen(BuildContext context, int level, {LevelUpUnlocks? unlocks}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      );
    },
    pageBuilder: (ctx, _, __) => LevelUpOverlay(level: level, unlocks: unlocks),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LevelUpOverlay
// ─────────────────────────────────────────────────────────────────────────────
class LevelUpOverlay extends StatefulWidget {
  final int level;
  final LevelUpUnlocks? unlocks;
  const LevelUpOverlay({super.key, required this.level, this.unlocks});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocks = widget.unlocks;
    final hasUnlocks = unlocks != null && !unlocks.isEmpty;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {}, // absorb taps so content behind isn't triggered
        child: Container(
          color: const Color(0xED040810), // rgba(4,8,16,0.93)
          child: Stack(
            children: [
              // radial blue glow
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.3),
                        radius: 0.75,
                        colors: [
                          Color(0x384f9eff), // 22% blue
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 60, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // eyebrow
                    Text(
                      '✦ RANK UP ✦',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // pulsing rings + badge
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _PulsingRing(ctrl: _ringCtrl, size: 160, phaseOffset: 0.0,   borderColor: AppColors.blue.withValues(alpha: 0.12)),
                          _PulsingRing(ctrl: _ringCtrl, size: 132, phaseOffset: 0.125, borderColor: AppColors.blue.withValues(alpha: 0.22)),
                          _PulsingRing(ctrl: _ringCtrl, size: 104, phaseOffset: 0.25,  borderColor: AppColors.blue.withValues(alpha: 0.38)),
                          // level badge
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1e3a5f), Color(0xFF2d1b4e)],
                              ),
                              border: Border.all(color: AppColors.blue, width: 3),
                              boxShadow: [
                                BoxShadow(color: AppColors.blue.withValues(alpha: 0.50), blurRadius: 40),
                                BoxShadow(color: AppColors.blue.withValues(alpha: 0.18), blurRadius: 80),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LEVEL',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  '${widget.level}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      'Level Up!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You reached Level ${widget.level}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    if (hasUnlocks) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'UNLOCKED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      ..._buildUnlockTiles(unlocks),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Keep exploring to unlock zones and gear.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // continue button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.blue, AppColors.purple],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.35),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Continue →',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUnlockTiles(LevelUpUnlocks u) {
    final tiles = <Widget>[];

    if (u.statPointsGained > 0) {
      final s = u.statPointsGained;
      tiles.add(_LuUnlock(
        icon: '✨',
        name: s == 1 ? '+1 Stat Point' : '+$s Stat Points',
        desc: 'Spend on STR, END, AGI, FLX, or STA',
        badgeLabel: 'POINTS',
        badgeColor: AppColors.orange,
      ));
    }

    for (final zone in u.unlockedZones) {
      tiles.add(_LuUnlock(
        icon: zone.icon.isNotEmpty ? zone.icon : '🗺️',
        name: zone.name,
        desc: zone.region.isEmpty
            ? 'New zone · Lvl ${zone.levelRequirement}'
            : '${zone.region} · Lvl ${zone.levelRequirement}',
        badgeLabel: 'ZONE',
        badgeColor: AppColors.blue,
      ));
    }

    for (final item in u.grantedItems) {
      final rColor = rarityColor(item.rarity);
      tiles.add(_LuUnlock(
        icon: item.icon.isNotEmpty ? item.icon : '🎁',
        name: item.name,
        desc: item.slot.isEmpty
            ? _prettyRarity(item.rarity)
            : '${_prettyRarity(item.rarity)} · ${item.slot}',
        badgeLabel: item.rarity.isEmpty ? 'ITEM' : item.rarity.toUpperCase(),
        badgeColor: rColor,
      ));
    }

    return _withSpacing(tiles, const SizedBox(height: 7));
  }

  String _prettyRarity(String r) =>
      r.isEmpty ? 'Item' : r[0].toUpperCase() + r.substring(1).toLowerCase();

  List<Widget> _withSpacing(List<Widget> items, Widget gap) {
    if (items.isEmpty) return items;
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out..add(gap)..add(items[i]);
    }
    return out;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingRing extends StatelessWidget {
  final AnimationController ctrl;
  final double size;
  final double phaseOffset;
  final Color borderColor;

  const _PulsingRing({
    required this.ctrl,
    required this.size,
    required this.phaseOffset,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = (ctrl.value + phaseOffset) % 1.0;
        // triangle wave: 0→1→0
        final wave = t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0;
        final scale = 1.0 + wave * 0.05;
        final opacity = 0.45 + wave * 0.55;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: size,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LuUnlock extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;
  final String badgeLabel;
  final Color badgeColor;

  const _LuUnlock({
    required this.icon,
    required this.name,
    required this.desc,
    required this.badgeLabel,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface1,
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 1),
                Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}
