import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_colors.dart';
import 'models/map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChestRewardDialog
// ─────────────────────────────────────────────────────────────────────────────
class ChestRewardDialog extends StatefulWidget {
  final String rarity;
  final int xp;
  final Color color;

  const ChestRewardDialog({
    super.key,
    required this.rarity,
    required this.xp,
    required this.color,
  });

  @override
  State<ChestRewardDialog> createState() => _ChestRewardDialogState();
}

class _ChestRewardDialogState extends State<ChestRewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _xpSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn));
    _xpSlide = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chest icon with scale pop
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 24),
                    ],
                  ),
                  child: const Center(
                    child: Text('📦', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // "Chest Opened!" title
              ScaleTransition(
                scale: _scale,
                child: Text(
                  'Chest Opened!',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Rarity pill
              ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    widget.rarity,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // XP reward
              AnimatedBuilder(
                animation: _xpSlide,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, 20 * (1 - _xpSlide.value)),
                  child: Opacity(
                    opacity: _xpSlide.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.xp} XP',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Collect button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Collect',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NodeArrivalBanner
// ─────────────────────────────────────────────────────────────────────────────
class NodeArrivalBanner extends StatefulWidget {
  final MapNodeModel node;
  const NodeArrivalBanner({super.key, required this.node});

  @override
  State<NodeArrivalBanner> createState() => _NodeArrivalBannerState();
}

class _NodeArrivalBannerState extends State<NodeArrivalBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final accent = mapNodeColor(node.type);
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF30363d), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(node.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You arrived at ${node.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            node.type,
                            style: TextStyle(fontSize: 11, color: accent),
                          ),
                        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// NodeDiscoveredBanner
// ─────────────────────────────────────────────────────────────────────────────
class NodeDiscoveredBanner extends StatefulWidget {
  final MapNodeModel node;
  const NodeDiscoveredBanner({super.key, required this.node});

  @override
  State<NodeDiscoveredBanner> createState() => _NodeDiscoveredBannerState();
}

class _NodeDiscoveredBannerState extends State<NodeDiscoveredBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final accent = mapNodeColor(node.type);
    final hasXp = node.rewardXp > 0;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161b22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon glow
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.12),
                          border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
                        ),
                        child: Center(
                          child: Text(node.icon, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🗺️  New area discovered!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              node.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              node.type,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasXp) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.green.withOpacity(0.4)),
                          ),
                          child: Text(
                            '+${node.rewardXp} XP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BossSlainOverlay
// ─────────────────────────────────────────────────────────────────────────────
class BossSlainOverlay extends StatefulWidget {
  final BossData boss;
  final int xpAwarded;
  const BossSlainOverlay({super.key, required this.boss, required this.xpAwarded});

  @override
  State<BossSlainOverlay> createState() => _BossSlainOverlayState();
}

class _BossSlainOverlayState extends State<BossSlainOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMini = widget.boss.isMini;
    final accentColor = isMini ? AppColors.orange : AppColors.red;
    final xpStr = widget.xpAwarded >= 1000
        ? '${(widget.xpAwarded / 1000).toStringAsFixed(1)}k'
        : '${widget.xpAwarded}';

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Boss icon in glowing circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.12),
                  border: Border.all(color: accentColor.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 4),
                  ],
                ),
                child: Center(
                  child: Text(widget.boss.icon, style: const TextStyle(fontSize: 50)),
                ),
              ),
              const SizedBox(height: 24),

              // SLAIN label
              Text(
                isMini ? 'MINI BOSS\nDEFEATED!' : 'BOSS\nSLAIN!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 2,
                  height: 1.1,
                  shadows: [Shadow(color: accentColor.withOpacity(0.6), blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 8),

              // Boss name
              Text(
                widget.boss.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // XP reward badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.blue.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.blue.withOpacity(0.2), blurRadius: 16),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpStr XP',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tap to dismiss
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'tap to continue',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
