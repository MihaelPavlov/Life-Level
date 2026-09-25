import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';

/// One reward shown in the popup, e.g. coins ×35 or points +20.
class TaskRewardItem {
  final String asset;
  final String label;
  final Color color;
  const TaskRewardItem(
      {required this.asset, required this.label, required this.color});
}

/// "Chest burst" claim popup: the screen dims, a treasure chest drops in,
/// shakes and bursts open (flash, glow, sparks, confetti), the rewards shoot
/// up out of it into their slots and "You got loot!" appears. Tap anywhere
/// to close — a tap during the intro skips to the end first.
///
/// Resolves with each reward tile's on-screen centre and icon at the moment
/// it closes, so the caller can fly the rewards on to where they live.
Future<List<(Offset, String)>> showTaskRewardPopup(
  BuildContext context, {
  required List<TaskRewardItem> items,
  required String subtitle,
}) async {
  final landed = await showGeneralDialog<List<(Offset, String)>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (_, __, ___) =>
        _TaskRewardPopup(items: items, subtitle: subtitle),
  );
  return landed ?? const [];
}

class _TaskRewardPopup extends StatefulWidget {
  final List<TaskRewardItem> items;
  final String subtitle;
  const _TaskRewardPopup({required this.items, required this.subtitle});

  @override
  State<_TaskRewardPopup> createState() => _TaskRewardPopupState();
}

class _TaskRewardPopupState extends State<_TaskRewardPopup>
    with SingleTickerProviderStateMixin {
  // Timeline (ms): drop 0–450 · land squash 450–570 · shake 570–1070 ·
  // burst open 1070–1520 · tiles fly out from 1190 (120 ms apart) ·
  // title 1520–1900 · close hint from 1900.
  static const _totalMs = 2300.0;
  static const _openAt = 1070.0;

  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2300))
    ..addListener(_tick);
  final _chest = FxAnchor();
  late final _tiles = [for (final _ in widget.items) FxAnchor()];
  bool _burst = false;

  double get _ms => _c.value * _totalMs;

  double _seg(double start, double len, [Curve curve = Curves.linear]) =>
      curve.transform(((_ms - start) / len).clamp(0.0, 1.0));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value > 0) return;
    if (AppMotion.isFull(context)) {
      _c.forward();
    } else {
      _burst = true;
      _c.value = 1;
    }
  }

  void _tick() {
    if (!_burst && _ms >= _openAt) {
      _burst = true;
      final c = _chest.center;
      if (c != null) {
        RewardFx.burst(context, c, const Color(0xFFFFD27A),
            count: 18, distance: 80, size: 6);
        RewardFx.confetti(context, c - const Offset(0, 20), count: 38);
      }
      AppMotion.haptic(AppHaptic.light);
    }
    setState(() {});
  }

  void _tap() {
    if (_c.isAnimating) {
      _burst = true;
      _c.value = 1;
      return;
    }
    final landed = <(Offset, String)>[
      for (final (i, a) in _tiles.indexed)
        if (a.center case final c?) (c, widget.items[i].asset),
    ];
    Navigator.of(context).pop(landed);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: LayoutBuilder(builder: (context, box) {
        final cx = box.maxWidth / 2, cy = box.maxHeight / 2;
        final chestC = Offset(cx, cy + 90);
        final tilesY = cy - 40;
        final titleY = cy - 150;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _seg(0, 300),
                child: const ColoredBox(color: Color(0xB802050A)),
              ),
            ),
            _glow(chestC),
            _chestWidget(chestC),
            for (final (i, item) in widget.items.indexed)
              _tile(i, item, cx, tilesY, chestC),
            _title(cx, titleY),
            _closeHint(box.maxHeight),
          ],
        );
      }),
    );
  }

  Widget _glow(Offset c) {
    final open = _seg(_openAt, 450);
    if (open <= 0) return const SizedBox.shrink();
    final k = open < .4 ? open / .4 : 1 - .3 * ((open - .4) / .6);
    const r = 150.0;
    return Positioned(
      left: c.dx - r,
      top: c.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: k.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: .4 + .7 * math.min(1, open / .4),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x8CFFD27A),
                  Color(0x24FFA11C),
                  Color(0x00FFA11C),
                ], stops: [
                  0,
                  .55,
                  1
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chestWidget(Offset c) {
    const size = 150.0;
    // Drop in, squash on landing, shake, then burst (grow + flash).
    final drop = _seg(0, 450, const Cubic(.5, 0, .8, .6));
    final land = _seg(450, 120);
    final squash = math.sin(land * math.pi);
    var rot = 0.0;
    final shake = _seg(570, 500);
    if (shake > 0 && shake < 1) {
      const keys = [0.0, -8.0, 8.0, -7.0, 6.0, -4.0, 0.0];
      final p = shake * (keys.length - 1);
      final i = p.floor().clamp(0, keys.length - 2);
      rot = (keys[i] + (keys[i + 1] - keys[i]) * (p - i)) * math.pi / 180;
    }
    final open = _seg(_openAt, 450);
    final grow =
        open < .3 ? 1 + .25 * (open / .3) : 1.25 - .2 * ((open - .3) / .7);
    final flash = open < .3 ? open / .3 : 1 - (open - .3) / .7;
    return Positioned(
      left: c.dx - size / 2,
      top: c.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: drop.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -300 * (1 - drop)),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..rotateZ(rot)
                ..scale((.8 + .2 * drop) * (1 + .05 * squash) * grow,
                    (.8 + .2 * drop) * (1 - .08 * squash) * grow),
              child: FxAnchorTarget(
                anchor: _chest,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: .7 * flash.clamp(0, 1)),
                      BlendMode.srcATop),
                  child: Image.asset(AppIcons.rewardChestBurst,
                      width: size, height: size, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(int i, TaskRewardItem item, double cx, double y, Offset chestC) {
    const size = 82.0;
    final n = widget.items.length;
    final c = Offset(cx + (i - (n - 1) / 2) * (size + 18), y);
    final p = _seg(_openAt + 120 + i * 120, 600);
    if (p <= 0) return const SizedBox.shrink();
    // Shoot up out of the chest, overshoot, settle.
    final e = const Cubic(.3, .8, .3, 1).transform(p);
    final from = chestC - c;
    final pos = Offset.lerp(from, Offset.zero, e)! +
        Offset(0, -30 * math.sin(p * math.pi));
    final scale = .2 + .8 * e + .15 * math.sin(p * math.pi);
    return Positioned(
      left: c.dx - size / 2,
      top: c.dy - size / 2,
      width: size,
      height: size,
      child: Transform.translate(
        offset: pos,
        child: Transform.scale(
          scale: scale,
          child: FxAnchorTarget(anchor: _tiles[i], child: _RewardTile(item)),
        ),
      ),
    );
  }

  Widget _title(double cx, double y) {
    final p = _seg(1520, 380, const Cubic(.3, .8, .3, 1));
    if (p <= 0) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      top: y - 30,
      child: Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 1.8 - .8 * p,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _StrokeText('You got loot!',
                  fontSize: 28,
                  fill: Color(0xFFFFD27A),
                  stroke: Color(0xFF3A2206)),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFFC9D1D9),
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _closeHint(double h) {
    final p = _seg(1900, 400);
    if (p <= 0) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 110,
      child: Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - p)),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xD9030710),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text('Tap to close',
                      style: TextStyle(
                          color: Color(0xFFC9D1D9),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square reward tile: tinted gradient, thick coloured rim, big icon and the
/// amount in the corner.
class _RewardTile extends StatelessWidget {
  final TaskRewardItem item;
  const _RewardTile(this.item);

  @override
  Widget build(BuildContext context) {
    final c = item.color;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(c, Colors.black, .55)!,
            Color.lerp(c, Colors.black, .8)!,
          ],
        ),
        boxShadow: [
          const BoxShadow(color: Color(0x59000000), offset: Offset(0, 6)),
          BoxShadow(color: c.withValues(alpha: .35), blurRadius: 16),
        ],
      ),
      child: Stack(
        children: [
          Center(child: AppIconImage(item.asset, size: 50)),
          Positioned(
            right: 6,
            bottom: 4,
            child: _StrokeText(item.label,
                fontSize: 13,
                fill: Colors.white,
                stroke: const Color(0xE6030710)),
          ),
        ],
      ),
    );
  }
}

/// Chunky game-style text: a thick dark outline under a solid fill.
class _StrokeText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fill;
  final Color stroke;
  const _StrokeText(this.text,
      {required this.fontSize, required this.fill, required this.stroke});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize / 5
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          ),
        ),
        Text(
          text,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.w900, color: fill),
        ),
      ],
    );
  }
}
